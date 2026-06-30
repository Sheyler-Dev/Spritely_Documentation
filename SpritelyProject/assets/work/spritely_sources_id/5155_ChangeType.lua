local module = {}

function module.ChangeType(Frame:Frame,Point,textedit)
	for i, a:Frame in pairs(Frame:GetChildren()) do
		if not a:IsA("Frame") then continue end
		a.InputBegan:Connect(function(click)
			if click.UserInputType == Enum.UserInputType.MouseButton1 then
				Frame:SetAttribute("Type",a:GetAttribute("Type"))
			end
		end)
	end
	Frame:GetAttributeChangedSignal("Type"):Connect(function()
		for i, a:Frame in pairs(Frame:GetChildren()) do
			if not a:IsA("Frame") then continue end
			if a:GetAttribute("Type") == Frame:GetAttribute("Type") then
				a.UIStroke.Enabled = true
			else
				a.UIStroke.Enabled = false
			end
		end
		if Frame:GetAttribute("Type") then
			Point.UICorner.CornerRadius = UDim.new(1,0)
			textedit.allowEven = false
		else
			Point.UICorner.CornerRadius = UDim.new(0,0)
			textedit.allowEven = true
		end
	end)
end

return module
