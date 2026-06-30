local module = {}
local redo = {}
local redoNum = 1
local HistoryService = game:GetService("ChangeHistoryService")
local MyFirts

local UserInputService = game:GetService("UserInputService")

function module.Change(ScreenFrame)
	local Editor = ScreenFrame.Editor.ImageLabel.ImageContent
	ScreenFrame.Editor.ImageLabel:GetPropertyChangedSignal("ImageContent"):Connect(function()
		if ScreenFrame.Editor.ImageLabel.ImageContent then
			if Editor.Object then
				Editor = ScreenFrame.Editor.ImageLabel.ImageContent
			end
		end
	end)
	table.insert(redo,Editor.Object:ReadPixelsBuffer(Vector2.zero, Editor.Object.Size))
	ScreenFrame.NewChange.Event:Connect(function()
		HistoryService:SetWaypoint("Spritely"..redoNum)
		if #redo > redoNum then
			for i = #redo, redoNum + 1, -1 do
				table.remove(redo, i)
			end
		end
		local currentState = Editor.Object:ReadPixelsBuffer(Vector2.zero, Editor.Object.Size)
		table.insert(redo, currentState)
		
		redoNum = #redo
		ScreenFrame.SaveChanges:Fire()
	end)
	HistoryService.OnUndo:Connect(function(waypoint)
		local tonum = tonumber(string.sub(waypoint, #"Spritely" + 1))
		if not tonum then return end
		redoNum = tonum
		local pixels = redo[redoNum]
		if pixels then
			Editor.Object:WritePixelsBuffer(Vector2.zero, Editor.Object.Size, pixels)
			ScreenFrame.SaveChanges:Fire()
		end
	end)
	HistoryService.OnRedo:Connect(function(waypoint)
		local tonum = tonumber(string.sub(waypoint, #"Spritely" + 1))
		if not tonum then return end
		redoNum = tonum
		local pixels = redo[redoNum]
		if pixels then
			Editor.Object:WritePixelsBuffer(Vector2.zero, Editor.Object.Size, pixels)
			ScreenFrame.SaveChanges:Fire()
		end
	end)
	ScreenFrame.RedoUndo.Event:Connect(function()
		HistoryService:ResetWaypoints()
		redo = {}
		redoNum = 1
		local pixels = Editor.Object:ReadPixelsBuffer(Vector2.zero, Editor.Object.Size)
		table.insert(redo, pixels)
	end)
	UserInputService.InputBegan:Connect(function(button)
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and button.KeyCode == Enum.KeyCode.Z then
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				if redoNum == #redo then
					local pixels = redo[#redo+1]
					if pixels then
						Editor.Object:WritePixelsBuffer(Vector2.zero, Editor.Object.Size, pixels)
						ScreenFrame.SaveChanges:Fire()
					end
				end
			else	
				if redoNum == 2 then
					local pixels = redo[1]
					if pixels then
						Editor.Object:WritePixelsBuffer(Vector2.zero, Editor.Object.Size, pixels)
						ScreenFrame.SaveChanges:Fire()
					end
				end
			end
		end
	end)
end

return module
