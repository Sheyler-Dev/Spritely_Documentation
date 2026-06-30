--!native
--!optimize 2
local Actor = script:GetActor()

local StartX = script.Parent:GetAttribute("StartX")
local StartY = script.Parent:GetAttribute("StartY")
local EndX = script.Parent:GetAttribute("EndX")
local EndY = script.Parent:GetAttribute("EndY")
local ImageWidth = script.Parent:GetAttribute("ImageWidth")
local SizeX = EndX - StartX
local SizeY = EndY - StartY

local OutputBuffer = buffer.create(SizeX * SizeY * 4)

local TO_FLOAT = 1/255
local TO_NORMAL = 1/127.5

local bit32 = bit32
local band = bit32.band
local rshift = bit32.rshift
local lshift = bit32.lshift
local bor = bit32.bor
local readu32 = buffer.readu32
local writeu32 = buffer.writeu32
local sqrt = math.sqrt
local min = math.min
local max = math.max
local floor = math.floor
local clamp = math.clamp

Actor:BindToMessageParallel("UpdateRender", function(EditableImage, BufColor, BufNormal, LightData, NormDir, DepthEffect)
	local outBuf = OutputBuffer
	local inColor = BufColor
	local inNormal = BufNormal

	local normDirX = NormDir.X
	local normDirY = NormDir.Y
	local normDirZ = NormDir.Z
	
	local width = ImageWidth
	
	for y = StartY, EndY - 1 do
		local rowOffsetGlobal = y * width

		for x = StartX, EndX - 1 do
			local globalOffset = (rowOffsetGlobal + x) * 4

			local packedColor = readu32(inColor, globalOffset)
			local r = band(packedColor, 0xFF)
			local g = band(rshift(packedColor, 8), 0xFF)
			local b = band(rshift(packedColor, 16), 0xFF)
			local a = band(rshift(packedColor, 24), 0xFF)

			if a > 0 then
				local packedNormal = readu32(inNormal, globalOffset)
				local nx = (band(packedNormal, 0xFF) * 0.007843) - 1 
				local ny = (band(rshift(packedNormal, 8), 0xFF) * 0.007843) - 1
				local nz = (band(rshift(packedNormal, 16), 0xFF) * 0.007843) - 1

				local uvX, uvY = x / EditableImage.Size.X, y / EditableImage.Size.Y

				local accR = 0
				local accG = 0
				local accB = 0
				for i = 1, #LightData, 7 do
					local lx = LightData[i]
					local ly = LightData[i+1]
					local lRange = LightData[i+2]
					local lBright = LightData[i+3]
					local lColR = LightData[i+4]
					local lColG = LightData[i+5]
					local lColB = LightData[i+6]

					local dx = uvX - lx
					local dy = uvY - ly
					local dist = sqrt(dx*dx + dy*dy)

					if dist <= lRange then
						local lDirX = (lx - uvX) * normDirX
						local lDirY = (ly - uvY) * normDirY
						local lDirZ = normDirZ
						local lenL = sqrt(lDirX*lDirX + lDirY*lDirY + 1)

						local dot = max((nx * (lDirX/lenL)) + (ny * (lDirY/lenL)) + (nz * (1/lenL)), 0)

						local att = max(1 - (dist / lRange), 0)
						local depthFactor = min(att ^ DepthEffect, 1)

						local intensity = dot * DepthEffect * lBright * depthFactor

						accR += intensity * lColR
						accG += intensity * lColG
						accB += intensity * lColB
					end
				end

				local depthDarkness = clamp((1 - nz) * DepthEffect, 0, 1)
				local invDark = 1 - depthDarkness

				local finalR = (r * invDark) + (accR * 255)
				local finalG = (g * invDark) + (accG * 255)
				local finalB = (b * invDark) + (accB * 255)

				finalR = if finalR > 255 then 255 elseif finalR < 0 then 0 else finalR
				finalG = if finalG > 255 then 255 elseif finalG < 0 then 0 else finalG
				finalB = if finalB > 255 then 255 elseif finalB < 0 then 0 else finalB

				local finalColor = bor(
					floor(finalR),
					lshift(floor(finalG), 8),
					lshift(floor(finalB), 16),
					lshift(a, 24)
				)

				local localOffset = ((y - StartY) * SizeX + (x - StartX)) * 4
				writeu32(outBuf, localOffset, finalColor)
			else
				local localOffset = ((y - StartY) * SizeX + (x - StartX)) * 4
				writeu32(outBuf, localOffset, 0)
			end
		end
	end
	task.synchronize()
	EditableImage:WritePixelsBuffer(Vector2.new(StartX, StartY), Vector2.new(SizeX, SizeY), outBuf)
end)