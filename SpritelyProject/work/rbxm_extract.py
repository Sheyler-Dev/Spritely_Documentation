from __future__ import annotations

import argparse
import json
import re
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Any


def read_u8(data: bytes, offset: int) -> tuple[int, int]:
    return data[offset], offset + 1


def read_u32(data: bytes, offset: int) -> tuple[int, int]:
    return struct.unpack_from("<I", data, offset)[0], offset + 4


def read_i32(data: bytes, offset: int) -> tuple[int, int]:
    return struct.unpack_from("<i", data, offset)[0], offset + 4


def read_string(data: bytes, offset: int) -> tuple[str, int]:
    length, offset = read_u32(data, offset)
    raw = data[offset : offset + length]
    return raw.decode("utf-8", errors="replace"), offset + length


def lz4_decompress_block(data: bytes, expected_size: int) -> bytes:
    out = bytearray()
    pos = 0

    while pos < len(data):
        token = data[pos]
        pos += 1

        literal_length = token >> 4
        if literal_length == 15:
            while True:
                value = data[pos]
                pos += 1
                literal_length += value
                if value != 255:
                    break

        out.extend(data[pos : pos + literal_length])
        pos += literal_length

        if pos >= len(data):
            break

        match_offset = data[pos] | (data[pos + 1] << 8)
        pos += 2

        match_length = token & 0x0F
        if match_length == 15:
            while True:
                value = data[pos]
                pos += 1
                match_length += value
                if value != 255:
                    break
        match_length += 4

        if match_offset == 0:
            raise ValueError("Invalid LZ4 match offset 0")

        start = len(out) - match_offset
        for index in range(match_length):
            out.append(out[start + index])

    if len(out) != expected_size:
        raise ValueError(f"LZ4 size mismatch: got {len(out)}, expected {expected_size}")
    return bytes(out)


def uninterleave_u32(data: bytes, count: int, offset: int) -> tuple[list[int], int]:
    raw = data[offset : offset + count * 4]
    offset += count * 4
    values: list[int] = []
    for index in range(count):
        b0 = raw[index]
        b1 = raw[index + count]
        b2 = raw[index + count * 2]
        b3 = raw[index + count * 3]
        values.append((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
    return values, offset


def decode_zigzag(value: int) -> int:
    return (value >> 1) ^ -(value & 1)


def decode_interleaved_i32(data: bytes, count: int, offset: int) -> tuple[list[int], int]:
    values, offset = uninterleave_u32(data, count, offset)
    return [decode_zigzag(value) for value in values], offset


def decode_interleaved_u32(data: bytes, count: int, offset: int) -> tuple[list[int], int]:
    return uninterleave_u32(data, count, offset)


@dataclass
class Chunk:
    name: str
    compressed_size: int
    decompressed_size: int
    body: bytes


def read_chunks(file_bytes: bytes) -> tuple[int, int, list[Chunk]]:
    magic = file_bytes[:16]
    if magic != b"<roblox!\x89\xff\r\n\x1a\n\x00\x00":
        raise ValueError(f"Unsupported RBXM magic: {magic!r}")

    class_count, instance_count = struct.unpack_from("<II", file_bytes, 16)
    offset = 32
    chunks: list[Chunk] = []

    while offset < len(file_bytes):
        name = file_bytes[offset : offset + 4].decode("ascii", errors="replace")
        compressed_size, decompressed_size, _reserved = struct.unpack_from("<III", file_bytes, offset + 4)
        offset += 16

        size = compressed_size or decompressed_size
        payload = file_bytes[offset : offset + size]
        offset += size

        body = payload if compressed_size == 0 else lz4_decompress_block(payload, decompressed_size)
        chunks.append(Chunk(name, compressed_size, decompressed_size, body))
        if name == "END\0":
            break

    return class_count, instance_count, chunks


def extract_ascii_strings(data: bytes, min_length: int = 4) -> list[str]:
    strings: list[str] = []
    current = bytearray()
    for byte in data:
        if 32 <= byte <= 126 or byte in (9, 10, 13):
            current.append(byte)
        else:
            if len(current) >= min_length:
                strings.append(current.decode("utf-8", errors="replace"))
            current.clear()
    if len(current) >= min_length:
        strings.append(current.decode("utf-8", errors="replace"))
    return strings


def class_counts_from_inst(chunks: list[Chunk]) -> dict[int, tuple[str, int]]:
    classes: dict[int, tuple[str, int]] = {}
    for chunk in chunks:
        if chunk.name != "INST":
            continue
        offset = 0
        class_id, offset = read_i32(chunk.body, offset)
        class_name, offset = read_string(chunk.body, offset)
        _is_service, offset = read_u8(chunk.body, offset)
        count, offset = read_u32(chunk.body, offset)
        classes[class_id] = (class_name, count)
    return classes


def decode_prop_values(prop_type: int, body: bytes, offset: int, count: int, sstrings: list[str]) -> tuple[list[Any], int]:
    # Roblox binary property type IDs are intentionally handled only for the
    # types needed by documentation extraction. Unknown types are skipped by
    # returning a compact marker and letting string scans fill any gaps.
    if prop_type in (0x01, 0x1B):  # String / BinaryString / ProtectedString in older files.
        values = []
        for _ in range(count):
            value, offset = read_string(body, offset)
            values.append(value)
        return values, offset

    if prop_type == 0x02:  # Bool
        values = [bool(body[offset + index]) for index in range(count)]
        return values, offset + count

    if prop_type in (0x03, 0x10):  # Int32 / Enum
        values, offset = decode_interleaved_i32(body, count, offset)
        return values, offset

    if prop_type in (0x04,):  # Float32, stored as raw interleaved u32.
        raw, offset = decode_interleaved_u32(body, count, offset)
        values = [struct.unpack(">f", value.to_bytes(4, "big"))[0] for value in raw]
        return values, offset

    if prop_type == 0x11:  # Instance reference.
        values, offset = decode_interleaved_i32(body, count, offset)
        return values, offset

    if prop_type == 0x1A:  # SharedString references.
        indexes, offset = decode_interleaved_i32(body, count, offset)
        values = [sstrings[index] if 0 <= index < len(sstrings) else f"<shared:{index}>" for index in indexes]
        return values, offset

    if prop_type == 0x19:  # Int64.
        # Stored as high and low interleaved words in practice; not needed for docs.
        return [f"<int64:{index}>" for index in range(count)], offset + count * 8

    raise ValueError(f"Unsupported property type 0x{prop_type:02X}")


def parse_sstr(chunks: list[Chunk]) -> list[str]:
    values: list[str] = []
    for chunk in chunks:
        if chunk.name != "SSTR":
            continue
        offset = 0
        version, offset = read_u32(chunk.body, offset)
        count, offset = read_u32(chunk.body, offset)
        for _ in range(count):
            # Shared strings include a 16-byte hash followed by a length-prefixed payload.
            offset += 16
            value, offset = read_string(chunk.body, offset)
            values.append(value)
    return values


def parse_model(chunks: list[Chunk]) -> dict[str, Any]:
    shared_strings = parse_sstr(chunks)
    classes = class_counts_from_inst(chunks)
    instances: dict[int, dict[str, Any]] = {}
    type_ranges: dict[int, list[int]] = {}
    next_instance_id = 0

    for chunk in chunks:
        if chunk.name != "INST":
            continue
        offset = 0
        class_id, offset = read_i32(chunk.body, offset)
        class_name, offset = read_string(chunk.body, offset)
        is_service, offset = read_u8(chunk.body, offset)
        count, offset = read_u32(chunk.body, offset)
        ids, offset = decode_interleaved_i32(chunk.body, count, offset)

        # Instance IDs are stored as deltas.
        absolute_ids: list[int] = []
        current = next_instance_id
        for delta in ids:
            current += delta
            absolute_ids.append(current)
        if absolute_ids:
            next_instance_id = max(next_instance_id, max(absolute_ids) + 1)

        type_ranges[class_id] = absolute_ids
        for instance_id in absolute_ids:
            instances[instance_id] = {
                "id": instance_id,
                "className": class_name,
                "isService": bool(is_service),
                "properties": {},
                "children": [],
                "parent": None,
            }

    for chunk in chunks:
        if chunk.name != "PROP":
            continue
        offset = 0
        class_id, offset = read_i32(chunk.body, offset)
        property_name, offset = read_string(chunk.body, offset)
        prop_type, offset = read_u8(chunk.body, offset)
        ids = type_ranges.get(class_id, [])
        count = len(ids)

        try:
            values, offset = decode_prop_values(prop_type, chunk.body, offset, count, shared_strings)
        except Exception as exc:
            continue

        for instance_id, value in zip(ids, values):
            if instance_id in instances:
                instances[instance_id]["properties"][property_name] = value

    for chunk in chunks:
        if chunk.name != "PRNT":
            continue
        offset = 0
        _version, offset = read_u8(chunk.body, offset)
        count, offset = read_u32(chunk.body, offset)
        children, offset = decode_interleaved_i32(chunk.body, count, offset)
        parents, offset = decode_interleaved_i32(chunk.body, count, offset)
        for child_id, parent_id in zip(children, parents):
            if child_id not in instances:
                continue
            instances[child_id]["parent"] = parent_id if parent_id >= 0 else None
            if parent_id in instances:
                instances[parent_id]["children"].append(child_id)

    return {
        "sharedStrings": shared_strings,
        "classes": classes,
        "instances": instances,
    }


def instance_path(instances: dict[int, dict[str, Any]], instance_id: int) -> str:
    parts: list[str] = []
    current: int | None = instance_id
    seen: set[int] = set()
    while current is not None and current in instances and current not in seen:
        seen.add(current)
        instance = instances[current]
        parts.append(instance["properties"].get("Name") or instance["className"])
        current = instance.get("parent")
    return ".".join(reversed(parts))


def summarize_scripts(model: dict[str, Any]) -> list[dict[str, Any]]:
    instances: dict[int, dict[str, Any]] = model["instances"]
    scripts: list[dict[str, Any]] = []
    for instance_id, instance in sorted(instances.items()):
        class_name = instance["className"]
        if class_name not in {"ModuleScript", "Script", "LocalScript"}:
            continue
        props = instance["properties"]
        source = props.get("Source") or ""
        scripts.append(
            {
                "id": instance_id,
                "name": props.get("Name") or class_name,
                "className": class_name,
                "path": instance_path(instances, instance_id),
                "source": source,
                "lineCount": source.count("\n") + 1 if source else 0,
            }
        )
    return scripts


def find_lua_symbols(source: str) -> dict[str, list[str]]:
    patterns = {
        "functions": [
            r"function\s+([A-Za-z_][\w\.:]*)\s*\(",
            r"([A-Za-z_][\w]*)\s*=\s*function\s*\(",
            r"([A-Za-z_][\w]*)\s*=\s*function\s+[A-Za-z_][\w]*\s*\(",
        ],
        "methods": [
            r"function\s+[A-Za-z_][\w]*[:.]([A-Za-z_][\w]*)\s*\(",
            r"([A-Za-z_][\w]*)\s*=\s*function\s*\([^)]*self",
        ],
        "requires": [
            r"require\s*\(([^)]+)\)",
        ],
    }
    found: dict[str, list[str]] = {}
    for key, pats in patterns.items():
        values: list[str] = []
        for pat in pats:
            values.extend(re.findall(pat, source))
        found[key] = sorted(set(value.strip() for value in values if value.strip()))
    return found


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--dump-sources", type=Path)
    args = parser.parse_args()

    file_bytes = args.input.read_bytes()
    class_count, instance_count, chunks = read_chunks(file_bytes)
    model = parse_model(chunks)
    scripts = summarize_scripts(model)

    for script in scripts:
        script["symbols"] = find_lua_symbols(script["source"])

    result = {
        "classCountHeader": class_count,
        "instanceCountHeader": instance_count,
        "chunks": [
            {
                "name": chunk.name,
                "compressedSize": chunk.compressed_size,
                "decompressedSize": chunk.decompressed_size,
            }
            for chunk in chunks
        ],
        "classCounts": [
            {"classId": class_id, "className": name, "count": count}
            for class_id, (name, count) in sorted(model["classes"].items())
        ],
        "scripts": scripts,
    }

    if args.dump_sources:
        args.dump_sources.mkdir(parents=True, exist_ok=True)
        for script in scripts:
            safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", script["path"]).strip("_")
            (args.dump_sources / f"{script['id']}_{safe}.lua").write_text(script["source"], encoding="utf-8")

    output = json.dumps(result, ensure_ascii=False, indent=2)
    if args.out:
        args.out.write_text(output, encoding="utf-8")
    else:
        print(output)


if __name__ == "__main__":
    main()
