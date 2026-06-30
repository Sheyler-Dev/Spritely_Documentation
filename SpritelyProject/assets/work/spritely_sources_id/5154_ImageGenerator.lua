local module = {}

local AssetService = game:GetService("AssetService")

local width, height = 512, 512

local colorStops = {
	Color3.fromRGB(255, 0, 4),
	Color3.fromRGB(255, 0, 255),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(255, 0, 0),
}

local function lerpColor(c1, c2, alpha)
	return Color3.new(
		c1.R + (c2.R - c1.R) * alpha,
		c1.G + (c2.G - c1.G) * alpha,
		c1.B + (c2.B - c1.B) * alpha
	)
end

local function getColorFromX(x)
	local t = x / (width - 1)
	local n = #colorStops - 1
	local index = t * n
	local i = math.floor(index)
	local alpha = index - i

	local c1 = colorStops[i + 1]
	local c2 = colorStops[math.min(i + 2, #colorStops)]

	return lerpColor(c1, c2, alpha)
end

local pixelBuffer: buffer = buffer.create(width * height * 4)

for y = 0, height - 1 do
	local whiteness = y / (height - 1)
	for x = 0, width - 1 do
		local baseColor = getColorFromX(x)

		local color = lerpColor(baseColor, Color3.new(1, 1, 1), whiteness)

		local i = (y * width + x) * 4
		buffer.writeu8(pixelBuffer, i,     math.floor(color.R * 255))
		buffer.writeu8(pixelBuffer, i + 1, math.floor(color.G * 255))
		buffer.writeu8(pixelBuffer, i + 2, math.floor(color.B * 255))
		buffer.writeu8(pixelBuffer, i + 3, 255)
	end
end

local EditableImage = AssetService:CreateEditableImage({
	Size = Vector2.new(width, height)
})

function module.GetVector2FromColor(targetColor: Color3): Vector2
	local h, s, v = targetColor:ToHSV()
	local x = 1 - h 
	local y = 1 - s 
	return Vector2.new(x, y), v
end


function module.CreateImage(Image:ImageLabel)
	EditableImage:WritePixelsBuffer(Vector2.zero, Vector2.new(width, height), pixelBuffer)
	Image.ImageContent = Content.fromObject(EditableImage)
end


return module
