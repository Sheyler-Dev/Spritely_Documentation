local CollectionService = game:GetService("CollectionService")
local Spritely = require(game:GetService("ReplicatedStorage"):WaitForChild("Spritely"))
local Childs = CollectionService:GetTagged("SpritelyObject")
local StarterGUI = game:GetService("StarterGui")
CollectionService:GetInstanceAddedSignal("SpritelyObject"):Connect(function(a)
	if a:IsDescendantOf(StarterGUI) then
		return
	end
	local Frame = a:GetAttribute("Frame")
	if not Frame then
		return
	end
	local IsPlaying = a:GetAttribute("IsPlayingAnimation")
	local FPS = a:GetAttribute("FPS")
	local ImageFolder = a:GetAttribute("ImageFolder")
	local Loop = a:GetAttribute("Loop")
	if not ImageFolder then
		return
	end
	local Min,Max = a:GetAttribute("MinFrame"),a:GetAttribute("MaxFrame")
	Spritely:CreateObject(a,ImageFolder,Frame)
	if IsPlaying then
		Spritely:PlayAnimation(a,FPS,Loop,Min,Max)
	end
end)

for i, a in pairs(Childs) do
	if a:IsDescendantOf(StarterGUI) then
		continue
	end
	local Frame = a:GetAttribute("Frame")
	if not Frame then
		continue
	end
	local IsPlaying = a:GetAttribute("IsPlayingAnimation")
	local FPS = a:GetAttribute("FPS")
	local ImageFolder = a:GetAttribute("ImageFolder")
	local Loop = a:GetAttribute("Loop")
	if not ImageFolder then
		continue
	end
	local Min,Max = a:GetAttribute("MinFrame"),a:GetAttribute("MaxFrame")
	Spritely:CreateObject(a,ImageFolder,Frame)
	if IsPlaying then
		Spritely:PlayAnimation(a,FPS,Loop,Min,Max)
	end
end
