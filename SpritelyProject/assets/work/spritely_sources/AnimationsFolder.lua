local module = {}
module.AnimationsFolder = {}
module.Animations = {}
module.PlayingAnimations = {}
local Createds = {}
type AnimationEvents = {
	Stopped: BindableEvent,
	Played: BindableEvent,
	Ended: BindableEvent,
	FrameChanged: BindableEvent
}
function module.GenerateAnimationEvents(ImageObject:ImageLabel|ImageButton):AnimationEvents
	if Createds[ImageObject] then
		return Createds[ImageObject]
	else
		local events = {
			Stopped = Instance.new("BindableEvent"),
			Played = Instance.new("BindableEvent"),
			FrameChanged = Instance.new("BindableEvent"),
			Ended = Instance.new("BindableEvent"),
		}
		Createds[ImageObject] = events
		return events
	end
end

return module
