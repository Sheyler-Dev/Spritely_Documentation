local SoundService = {}
SoundService.Sounds = {}
local Camera = workspace.CurrentCamera

local Z_OFFSET = 2

function SetSoundPosition(normalizedPosition: Vector2,soundAttachment)
	local viewportSize = Camera.ViewportSize
	local pixelX = normalizedPosition.X * viewportSize.X
	local pixelY = normalizedPosition.Y * viewportSize.Y
	local ray = Camera:ScreenPointToRay(pixelX, pixelY)
	soundAttachment.WorldPosition = ray.Origin + ray.Direction * Z_OFFSET
end

function SoundService.CreateSound(SoundID:number|string,ImageObject:ImageLabel|ImageButton)
	local NewSound = Instance.new("Sound")
	NewSound.SoundId = typeof(SoundID) == "string" and SoundID or "rbxassetid://"..SoundID
	local Att = Instance.new("Attachment",Camera)
	if ImageObject then
		ImageObject:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			local NormalizedPosition = (ImageObject.AbsolutePosition+ImageObject.AbsoluteSize/2)/Camera.ViewportSize
			SetSoundPosition(NormalizedPosition,Att)
		end)
	end
	if not SoundService.Sounds[ImageObject] then
		SoundService.Sounds[ImageObject] = {}
	end
	ImageObject.AncestryChanged:Connect(function()
		if not ImageObject:IsDescendantOf(game) then
			for i,v in pairs(SoundService.Sounds[ImageObject]) do
				v:Destroy()
			end
			SoundService.Sounds[ImageObject] = nil
		end
	end)
	table.insert(SoundService.Sounds[ImageObject],Att)
	NewSound.Parent = Att
	return NewSound	
end

return SoundService
