local PathEditorModule = require(script.Parent.PathEditorModule)
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local main = script.Parent
local canvas = main:WaitForChild("Canvas")
local tools = main:WaitForChild("Tools")

local editor = PathEditorModule.new(canvas, Vector2.new(5, 5))

function CanClick()
	return main.CanClick.Value
end

editor:Render()

local previewVertex = main.Canvas:WaitForChild("Frame")

UserInputService.InputChanged:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local cursorPosition = editor:UpdatePreview(
			UserInputService:GetMouseLocation(), 
			GuiService:GetGuiInset()
		)
		previewVertex.Position = cursorPosition
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if not CanClick() or main.Parent.Enabled == false then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		editor:AddPoint(UserInputService:GetMouseLocation(), GuiService:GetGuiInset())
	end
end)

tools.NewPoint.MouseButton1Click:Connect(function()
	if not CanClick() or main.Parent.Enabled == false then return end
	editor:StartNewShape()
end)

tools.UndoBtn.MouseButton1Click:Connect(function()
	if not CanClick() or main.Parent.Enabled == false then return end
	local mousePos = UserInputService:GetMouseLocation()
	local guiInset = GuiService:GetGuiInset()
	editor:UpdatePreview(mousePos, guiInset)
	editor:Undo()
end)

tools.RedoBtn.MouseButton1Click:Connect(function()
	if not CanClick() or main.Parent.Enabled == false then return end
	editor:Redo()
	local mousePos = UserInputService:GetMouseLocation()
	local guiInset = GuiService:GetGuiInset()
	editor:UpdatePreview(mousePos, guiInset)
end)

tools.SaveChange.MouseButton1Click:Connect(function()
	if not CanClick() or main.Parent.Enabled == false then return end
	local json = editor:GenerateJSON()
	local Folder = main.Tools.FolderValue.Value
	if Folder then
		if Folder.Parent then
			Folder:SetAttribute("VertexData", json)
		end
	end
end)