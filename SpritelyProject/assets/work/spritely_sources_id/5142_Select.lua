local module = {}
function module.selec(Screen:ScreenGui)
	for i, Buttons in pairs(Screen:FindFirstChild("Frame"):FindFirstChild("Keys"):FindFirstChild("Scroll"):GetChildren()) do
		if Buttons:IsA("ImageButton") then
			Buttons.MouseButton1Click:Connect(function()
				Buttons:SetAttribute("On", true)
				for i, buttonscolor in pairs(Buttons.Parent:GetChildren()) do
					if buttonscolor:IsA("ImageButton") and not (buttonscolor == Buttons) then
						buttonscolor:SetAttribute("On",false)
					end
				end
			end)
			Buttons:GetAttributeChangedSignal("On"):Connect(function()
				if Buttons:GetAttribute("On") == true then
					script.Parent.Event:Fire(Buttons.Name)
					Buttons.BackgroundColor3 = Color3.fromRGB(0, 55, 255)
					Buttons.ImageTransparency = 0
				else
					Buttons.ImageTransparency = .5
					Buttons.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				end
			end)
		end
	end
end

function module.ExtraSelect(screen:Instance, ButtonName,can)
	local Button = screen:FindFirstChild("Frame"):FindFirstChild("Keys"):FindFirstChild("Scroll"):FindFirstChild(ButtonName)
	if Button then
		Button:SetAttribute("On", true)
		script.Parent.Event:Fire(Button.Name,can)
		for i, buttonscolor in pairs(Button.Parent:GetChildren()) do
			if buttonscolor:IsA("ImageButton") and not (buttonscolor == Button) then
				buttonscolor:SetAttribute("On",false)
			end
		end
	end
end

return module
