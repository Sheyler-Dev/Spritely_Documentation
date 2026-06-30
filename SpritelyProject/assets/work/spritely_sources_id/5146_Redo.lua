local module = {}
local redo = {}
local redoNum = 1

function module.Change(ScreenFrame:ScreenGui)
	local Editor = ScreenFrame.Editor.ImageLabel.ImageContent
	local PlayEditor = ScreenFrame.Play
	ScreenFrame.Editor.ImageLabel:GetPropertyChangedSignal("ImageContent"):Connect(function()
		local test = ScreenFrame.Editor.ImageLabel.ImageContent
		if test and test.Object then
			Editor = test
		end
	end)
	table.insert(redo,Editor.Object:ReadPixelsBuffer(Vector2.zero, Editor.Object.Size))
	ScreenFrame.NewChange.Event:Connect(function()
		if #redo > redoNum then
			for i = #redo, redoNum + 1, -1 do
				table.remove(redo, i)
			end
		end
		local currentState = Editor.Object:ReadPixelsBuffer(Vector2.zero, Editor.Object.Size)
		table.insert(redo, currentState)
		redoNum = #redo
		if #redo > 40 then
			table.remove(redo, 1)
			redoNum = redoNum - 1
		end
		if #redo == redoNum then
			ScreenFrame.Redo.BackgroundColor3 = Color3.fromRGB(50,50,50)
		else
			ScreenFrame.Redo.BackgroundColor3 = Color3.fromRGB(0, 39, 184)
		end
		if #redo == 1 then
			ScreenFrame.Undo.BackgroundColor3 = Color3.fromRGB(50,50,50)
		else
			ScreenFrame.Undo.BackgroundColor3 = Color3.fromRGB(0, 39, 184)
		end
		ScreenFrame.SaveChanges:Fire()
	end)
	ScreenFrame.Redo.MouseButton1Click:Connect(function()	
		if PlayEditor:GetAttribute("On") == true then
			return
		end
		if redoNum < #redo then
			redoNum = redoNum + 1
			local pixels = redo[redoNum]
			if redoNum == #redo then
				ScreenFrame.Redo.BackgroundColor3 = Color3.fromRGB(50,50,50)
			else
				ScreenFrame.Redo.BackgroundColor3 = Color3.fromRGB(0, 39, 184)
			end
			if redoNum == 1 then
				ScreenFrame.Undo.BackgroundColor3 = Color3.fromRGB(50,50,50)
			else
				ScreenFrame.Undo.BackgroundColor3 = Color3.fromRGB(0, 39, 184)
			end
			if pixels then
				Editor.Object:WritePixelsBuffer(Vector2.zero, Editor.Object.Size, pixels)
				ScreenFrame.SaveChanges:Fire()
			end
		end
	end)
	ScreenFrame.Undo.MouseButton1Click:Connect(function()
		if PlayEditor:GetAttribute("On") == true then
			return
		end
		if redoNum > 1 then
			redoNum = redoNum - 1
			if redoNum == 1 then
				ScreenFrame.Undo.BackgroundColor3 = Color3.fromRGB(50,50,50)
			else
				ScreenFrame.Undo.BackgroundColor3 = Color3.fromRGB(0, 39, 184)
			end
			if redoNum == #redo then
				ScreenFrame.Redo.BackgroundColor3 = Color3.fromRGB(50,50,50)
			else
				ScreenFrame.Redo.BackgroundColor3 = Color3.fromRGB(0, 39, 184)
			end
			local pixels = redo[redoNum]
			if pixels then
				Editor.Object:WritePixelsBuffer(Vector2.zero, Editor.Object.Size, pixels)
				ScreenFrame.SaveChanges:Fire()
			end
		end
	end)
	ScreenFrame.RedoUndo.Event:Connect(function()
		redo = {}
		redoNum = 1
		ScreenFrame.Undo.BackgroundColor3 = Color3.fromRGB(50,50,50)
		ScreenFrame.Redo.BackgroundColor3 = Color3.fromRGB(50,50,50)
		table.insert(redo,Editor.Object:ReadPixelsBuffer(Vector2.zero, Editor.Object.Size))
	end)
end

return module
