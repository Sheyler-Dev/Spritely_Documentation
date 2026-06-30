local module = {}
function module.createbutton(types, text:string|EditableImage, padre, color:Color3, transparency:number, Position:UDim2,Size:UDim2,bufferImage)
	local label:ImageLabel = Instance.new(types)
	if typeof(text) == "Object" then
		label.Size = Size
		label.Position = Position
		label.BackgroundTransparency = transparency
		label.ImageContent = Content.fromObject(text)
		label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		label.ScaleType = Enum.ScaleType.Fit
		label.ResampleMode = Enum.ResamplerMode.Pixelated
	else
		if label:IsA("TextButton") or label:IsA("TextBox") or label:IsA("TextLabel") then
			label.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
			label.Size = Size
			label.Position = Position
			label.Text = text
			label.BackgroundTransparency = transparency
			label.TextColor3 = color
			label.TextScaled = true
			if label:IsA("TextBox") then
				label.ClearTextOnFocus = false
			end
		elseif label:IsA("ImageLabel") or label:IsA("ImageButton") then
			label.Size = Size
			label.Position = Position
			label.BackgroundTransparency = transparency
			label.Image = "rbxassetid://"..text
			label.BackgroundColor3 = color
			label.ScaleType = Enum.ScaleType.Crop
			label.ResampleMode = Enum.ResamplerMode.Pixelated
		end
	end
	local bordes = Instance.new("UICorner", label)
	label.Parent = padre
	label.Visible = true
	return label
end
return module