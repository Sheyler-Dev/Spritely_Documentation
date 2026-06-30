local module={}
module.Imagenes	= {15411602267, 3571913912, 1157324427,7219006787,16947199413,3769877321}
function module.Ramdom()
	local ramdom = math.random(1,#module.Imagenes)
	return module.Imagenes[ramdom]
end
return module
