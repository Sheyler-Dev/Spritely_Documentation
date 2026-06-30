local module = {}
local Copia= nil
local AssetService = game:GetService("AssetService")
local ExtraSelect = require(script.Parent.Select)

function UpdateSizeAreaToCut(selects: ImageLabel, canvasSize: Vector2, sourceSize: Vector2)

	local scaleX = sourceSize.X / canvasSize.X
	local scaleY = sourceSize.Y / canvasSize.Y

	local diffX = canvasSize.X - sourceSize.X
	local diffY = canvasSize.Y - sourceSize.Y

	local pixelPosX = math.floor(diffX / 2)
	local pixelPosY = math.floor(diffY / 2)

	local posX = pixelPosX / canvasSize.X
	local posY = pixelPosY / canvasSize.Y

	selects.Size = UDim2.fromScale(scaleX, scaleY)
	selects.Position = UDim2.fromScale(posX, posY)
end

function module.Copy(model)
	local Editor:ImageLabel = model.Frame.Editor.ImageLabel
	local PlayButton = model.Frame.Play
	local selects:ImageLabel = Editor.Select
	local Size = Editor.ImageContent.Object.Size
	local OldSize = Size
	local CopySIze = Size
	local CopiaType = nil
	Editor:GetPropertyChangedSignal("ImageContent"):Connect(function()
		if Editor.ImageContent.Object then
			OldSize = Size
			Size = Editor.ImageContent.Object.Size
		end
	end)
	
	model.Frame.Copy.MouseButton1Click:Connect(function()
		if PlayButton:GetAttribute("On") then
			return
		end
		if selects.Visible then
			CopiaType = 1
			local nEd:EditableImage = selects.ImageContent.Object
			if nEd then
				Copia = nEd:ReadPixelsBuffer(Vector2.zero,nEd.Size)
				CopySIze = nEd.Size
				model.Frame.Paste.BackgroundColor3 = Color3.fromRGB(0,0,255)
			end	
		else
			CopiaType = 0
			Copia = Editor.ImageContent.Object:ReadPixelsBuffer(Vector2.zero,Size)
			CopySIze = Size
			model.Frame.Paste.BackgroundColor3 = Color3.fromRGB(0,0,255)
		end
	end)
	
	model.Frame.Paste.MouseButton1Click:Connect(function()
		if PlayButton:GetAttribute("On") then
			return
		end
		if Copia then
			ExtraSelect.ExtraSelect(model,"Han",true)
			task.wait()
			UpdateSizeAreaToCut(selects,Size,CopySIze)
			local oldEditable = selects.ImageContent.Object
			if oldEditable then
				oldEditable:Destroy()
			end
			local newEditable = AssetService:CreateEditableImage({Size = CopySIze})
			newEditable:WritePixelsBuffer(Vector2.zero,CopySIze,Copia)
			selects.ImageContent = Content.fromObject(newEditable)
			selects.Visible = true
		else
			model.Frame.Paste.BackgroundColor3 = Color3.fromRGB(50,50,50)
		end
	end)
end
return module
