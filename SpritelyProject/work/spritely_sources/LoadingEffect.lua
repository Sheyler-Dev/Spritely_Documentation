local module = {}
local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

function module.Play(ImageLabel:ImageLabel)
	while true do
		ImageLabel.Rotation = 0
		local tw = TweenService:Create(ImageLabel, tweenInfo, {Rotation = 360})
		tw:Play()
		tw.Completed:Wait()
		tw:Destroy()
		ImageLabel.Rotation = 0
	end
end

return module
