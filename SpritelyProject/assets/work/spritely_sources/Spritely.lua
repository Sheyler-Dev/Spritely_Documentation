local InsertService = game:GetService("InsertService")
local run = game:GetService("RunService")
if run:IsRunning() then return end
local toolbar = plugin:CreateToolbar("Spritely")
local ChangeX = require(script.ChangeX)
local HTTP = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Settings = {}

local NumericalTxT = require(script.Textbox)
local Selection = game:GetService("Selection")
local Spritely = game.ReplicatedStorage:FindFirstChild("Spritely")
local LoaderPreview = game.StarterPlayer.StarterPlayerScripts:FindFirstChild("Spritely_Loader")
local VersionID = "3.5.2"
local SpriteOptions = script.SpriteOptions
local CollectionService = game:GetService("CollectionService")

local AllEditables = {}

local CollisionTypes = {
	["Box"] = {"Relative"},
	["Radial"] = {},
	["Precise"] = {"Resolution"},
	["Convex"] = {},
	["Custom"] = {"Custom"}
}

local existinCollide = {
	"Box",
	"Radial",
	"Precise",
	"Convex",
	"Custom"
}

local DebugGamePlay = workspace:GetAttribute("Debug_Collision_Spritely")

if DebugGamePlay == nil then
	workspace:SetAttribute("Debug_Collision_Spritely", false)
end

script.Spritely:SetAttribute("Version", VersionID)
local TableOfConnections = {}
if not Spritely or (Spritely and Spritely:GetAttribute("Version") ~= VersionID) then
	if Spritely then
		Spritely:Destroy() 
	end
	Spritely = script.Spritely:Clone()
	task.spawn(function()
		while true do
			local Can, Error = pcall(function()
				Spritely.Parent = game.ReplicatedStorage
			end)
			if Can then
				break
			else
				task.wait(1)
			end
		end
	end)
end

local CoreGui = game:GetService("CoreGui")


local Theme = {
	Background = Color3.fromRGB(35, 35, 35),
	CardBG = Color3.fromRGB(45, 45, 45),
	Hover = Color3.fromRGB(0, 39, 184),
	HoverOn = Color3.fromRGB(0, 29, 136),
	CardHover = Color3.fromRGB(52, 52, 52),
	Stroke = Color3.fromRGB(75, 75, 75),
	Text = Color3.fromRGB(240, 240, 240),
	Placeholder = Color3.fromRGB(160, 160, 160),
	TextBoxBG = Color3.fromRGB(30, 30, 30),
	TextBoxFocus = Color3.fromRGB(0, 120, 215),
	ButtonImport = Color3.fromRGB(40, 40, 40),
	ButtonImportHover = Color3.fromRGB(0, 110, 200),
	ButtonDelete = Color3.fromRGB(40, 40, 40),
	ButtonDeleteHover = Color3.fromRGB(200, 60, 60),
	DarkBG = Color3.fromRGB(45, 45, 45),
	HoverBG = Color3.fromRGB(55, 55, 55),
	Accent = Color3.fromRGB(0, 120, 215),
	AccentHover = Color3.fromRGB(0, 80, 150),
	Button = Color3.fromRGB(0, 180, 0),
	ButtonHover = Color3.fromRGB(0, 150, 0),
	ButtonUI = Color3.fromRGB(50,50,50),
	ButtonUIHover = Color3.fromRGB(0, 55, 255),
	Idle = Color3.fromRGB(45, 45, 45),
}

script.Spritely_Loader:SetAttribute("Version",VersionID)
if not LoaderPreview or (LoaderPreview and LoaderPreview:GetAttribute("Version") ~=VersionID) then
	if LoaderPreview then
		LoaderPreview:Destroy()
	end	
	LoaderPreview = script.Spritely_Loader:Clone()
	task.spawn(function()
		while true do
			local Can, Error = pcall(function()
				LoaderPreview.Parent = game.StarterPlayer.StarterPlayerScripts
			end)
			if Can then
				LoaderPreview.Enabled = true
				break
			else
				task.wait(1)
			end
		end
	end)
end
local HistoryService = game:GetService("ChangeHistoryService")

local PixelSize = 1
local anteriorSize = 1

local s = require(script.Mover)
local n = require(script.ImageGenerator)

local button = toolbar:CreateButton("Spritely Editor","Open/Close","rbxassetid://105848972105995")

local REDO_UNDO = require(script:WaitForChild("Redo"))
local inputService = game:GetService("UserInputService")
local createRamdom = require(script:WaitForChild("CreateRamdomIcon"))
local AssetService = game:GetService("AssetService")
local mouse = plugin:GetMouse()
local save = require(script.SaveSprites)
local Select1 = require(script.Select)
local Copy_Paste = require(script.Copy_Paste)
local twenService = game:GetService("TweenService")
local ReSize = require(script.Size)
local SpriteFolder = game.ReplicatedStorage:FindFirstChild("SpriteFolder") or Instance.new("Folder",game.ReplicatedStorage)
local types = "Pen"
local LastType = types
SpriteFolder.Name = "SpriteFolder"
local drawing = false
local editor = true
local CanClick = true
local ColorPick = nil
local LastColor =  Color3.new(0,0,0)

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	false,
	false,
	300,
	200,
	150,
	100
)

local FolderEscenes = {}

local tweenInf = TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local dockWidget:DockWidgetPluginGui = plugin:CreateDockWidgetPluginGuiAsync("MiVentana", widgetInfo)
dockWidget.Title = "Spritely"
dockWidget.Enabled = false
dockWidget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local SIZE = Vector2.new(337,337)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, .98, 0)
frame.AnchorPoint = Vector2.new(.5,.5)
frame.Position = UDim2.new(.5,0,.5,0)
frame.BackgroundColor3 = Color3.fromRGB(25, 26, 31)
frame.Parent = dockWidget
frame.Visible = true
frame.Name = "BaseButtons"
local list = Instance.new("UIListLayout", frame)
list.Padding = UDim.new(0,2)
list.ItemLineAlignment = Enum.ItemLineAlignment.Start

local model = script.UIEditor:Clone()
model.Name = "UIEditor"

local OtherCoreGui = CoreGui:FindFirstChild("UIEditor")
if OtherCoreGui then
	OtherCoreGui:Destroy()
end

while model.Parent ~= CoreGui do 
	pcall(function()
		model.Parent = CoreGui
		model.Enabled = false
	end)
	wait(1)
end

local frameSprite = Instance.new("Frame",dockWidget)
frameSprite.Size = UDim2.new(1, 0, 1, 0)
frameSprite.BackgroundTransparency = 1
frameSprite.Visible = false
frameSprite.Name = "Editor"

function applyHoverEffect(guiObject, defaultColor, hoverColor,CanUse)
	local MouseEnter = false
	if CanUse then
		local old = defaultColor
		local old2 = hoverColor
		if script.Value.Value == guiObject then
			defaultColor = Theme.Hover
			hoverColor = Theme.HoverOn
		end
		script.Value.Changed:Connect(function(obj)
			if obj == guiObject then
				defaultColor = Theme.Hover
				hoverColor = Theme.HoverOn
				if MouseEnter then 
					TweenService:Create(guiObject, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = hoverColor}):Play()
				end
			else
				defaultColor = old
				hoverColor = old2
				if not MouseEnter then 
					TweenService:Create(guiObject, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = defaultColor}):Play()
				end
			end
		end)
	end
	guiObject.MouseEnter:Connect(function()
		MouseEnter = true
		TweenService:Create(guiObject, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = hoverColor}):Play()
	end)
	guiObject.MouseLeave:Connect(function()
		MouseEnter = false
		TweenService:Create(guiObject, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = defaultColor}):Play()
	end)
end

local Insert = model.Insert

local Check = Insert.CheckSize.Check

Check.MouseButton1Click:Connect(function()
	Check.Value.Value = not Check.Value.Value
end)


local selects = model.Frame.Editor.ImageLabel.Select

local textEdit = ChangeX.MoveOnX(model.Frame.Scale.Handle.TextButton,model.Frame.Scale.Size,Vector2.new(1,100))
ChangeX.MoveOnX(model.Frame.Brightness.Handle.TextButton,model.Frame.Brightness.Brillo,Vector2.new(0,100))
ChangeX.MoveOnX(model.Frame.Alpha.Handle.TextButton,model.Frame.Alpha.Alpha,Vector2.new(0,100))
ChangeX.MoveOnX(model.Frame.ToolEditors.Paint.Handle.TextButton,model.Frame.ToolEditors.Paint.Tolerance,Vector2.new(0,100))

Check.Value.Changed:Connect(function(val)
	if val then
		Check.BackgroundColor3 = Check:GetAttribute("On")
		Check.Frame:TweenPosition(UDim2.fromScale(0.5,0.5),Enum.EasingDirection.In,Enum.EasingStyle.Linear,.2,true)
	else
		Check.BackgroundColor3 = Check:GetAttribute("Off")
		Check.Frame:TweenPosition(UDim2.fromScale(0,0.5),Enum.EasingDirection.In,Enum.EasingStyle.Linear,.2,true)
	end
end)

local Escenes = Instance.new("Frame")
Escenes.Size = UDim2.new(1, 0, 1, 0)
Escenes.BackgroundColor3 = Color3.fromRGB(25, 26, 31)
Escenes.Parent = dockWidget
Escenes.Visible = false
Escenes.Name = "Escenes"

local ResizeSystem = require(script.ResizeBuffer)

local FrameMovement = Instance.new("ScrollingFrame",frameSprite)
FrameMovement.Position = UDim2.new(0, 0, 0, 55)
FrameMovement.Size = UDim2.new(1, 0, 1, -55)
FrameMovement.BackgroundColor3 = Color3.fromRGB(25, 26, 31)
FrameMovement.AutomaticCanvasSize = Enum.AutomaticSize.Y
FrameMovement.ScrollingEnabled = true
FrameMovement.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
FrameMovement.CanvasSize = UDim2.new(0, 0, 0, 0)
FrameMovement.ScrollBarThickness = 12

local UIPadding = Instance.new("UIPadding",FrameMovement)
UIPadding.PaddingTop = UDim.new(0,1)

local list2 = Instance.new("UIListLayout", FrameMovement)
list2.Padding = UDim.new(0,5)
list2.HorizontalAlignment = Enum.HorizontalAlignment.Center
list2.VerticalAlignment = Enum.VerticalAlignment.Top
list2.SortOrder = Enum.SortOrder.LayoutOrder
list2.ItemLineAlignment = Enum.ItemLineAlignment.Start
function checkScrollbar()
	if list2.AbsoluteContentSize.Y > FrameMovement.AbsoluteSize.Y then
		UIPadding.PaddingRight = UDim.new(0,12)
	else
		UIPadding.PaddingRight = UDim.new(0,0)
	end
end

list2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(checkScrollbar)
FrameMovement:GetPropertyChangedSignal("AbsoluteSize"):Connect(checkScrollbar)


local ImageMovement = Instance.new("ScrollingFrame",Escenes)
ImageMovement.Size = UDim2.new(1, 0, 1, 0)
ImageMovement.Position = UDim2.new(0,0,0,0)
ImageMovement.BackgroundColor3 = Color3.fromRGB(25, 26, 31)
ImageMovement.AutomaticCanvasSize = Enum.AutomaticSize.Y
ImageMovement.ScrollingEnabled = true
ImageMovement.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
ImageMovement.CanvasSize = UDim2.new(0, 0, 0, 0)

local ListImage = Instance.new("UIGridLayout", ImageMovement)
ListImage.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListImage.CellSize = UDim2.fromScale(.33,.33)
ListImage.SortOrder = Enum.SortOrder.LayoutOrder
ListImage.StartCorner = Enum.StartCorner.TopLeft
ListImage.FillDirection = Enum.FillDirection.Horizontal

Instance.new("UIAspectRatioConstraint",ListImage)

local Paint = require(script.Pintar)

table.insert(FolderEscenes, frame)
table.insert(FolderEscenes, frameSprite)
table.insert(FolderEscenes,Escenes)

local createinstances = require(script.CreateInstance)
local Loop = true
local ButtonBack = createinstances.createbutton("ImageButton", "2598526569", dockWidget, Color3.fromRGB(255, 255, 255),1,UDim2.new(0,20,0,25), UDim2.new(0,30,0,30))
ButtonBack.AnchorPoint = Vector2.new(.5,.5)
ButtonBack.Visible = false
ButtonBack.ZIndex = 100000
ButtonBack.ResampleMode = Enum.ResamplerMode.Default

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, -30, 0, 45)
TopBar.BackgroundTransparency = 1
TopBar.Parent = frameSprite
TopBar.Position = UDim2.fromOffset(30,0)

local barPadding = Instance.new("UIPadding")
barPadding.PaddingLeft = UDim.new(0, 10)
barPadding.PaddingRight = UDim.new(0, 10)
barPadding.PaddingTop = UDim.new(0, 5)
barPadding.Parent = TopBar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = TopBar

local CreateNew:TextButton = createinstances.createbutton(
	"TextButton", 
	"Create Sprite", 
	TopBar, 
	Theme.Button, 
	0, 
	UDim2.new(0, 0, 0, 0),
	UDim2.new(1, -45, 0, 32)
)
CreateNew.LayoutOrder = 1
CreateNew.Font = Enum.Font.GothamBold
CreateNew.TextColor3 = Theme.Text
CreateNew.TextSize = 13
CreateNew.AutoButtonColor = false

applyHoverEffect(CreateNew,Theme.Button,Theme.ButtonHover)

local ImportGenerat = createinstances.createbutton(
	"ImageButton", 
	135034261031452, 
	TopBar, 
	Theme.Accent, 
	0, 
	UDim2.new(0, 0, 0, 0),
	UDim2.new(0, 32, 0, 32)
)
ImportGenerat.LayoutOrder = 2
ImportGenerat.ScaleType = Enum.ScaleType.Fit
ImportGenerat.ResampleMode = Enum.ResamplerMode.Default
applyHoverEffect(ImportGenerat,Theme.Accent,Theme.AccentHover)

local point = model:FindFirstChildWhichIsA("Frame"):FindFirstChild("Editor").ImageLabel.Frame

function requestUserInput(MakeVisible:{},defaultValue,returned)
	model.Frame.Visible = false
	for i,a in pairs(model.Insert:QueryDescendants("TextBox")) do
		if a:HasTag("HasTextBox") or a.Parent.Name == "DataBox" then
			a.Text = defaultValue
		end
	end
	for i,a in pairs(model.Insert:GetChildren()) do
		if a:IsA("Frame") or a:IsA("TextButton") or a:IsA("TextLabel") then
			local CanVisible = a:GetAttribute("Level")
			if not CanVisible then
				a.Visible = true
			else
				if table.find(MakeVisible,CanVisible) then
					a.Visible = true
				else
					a.Visible = false
				end
			end
		end
	end
	Insert.Visible = true
	local response = nil
	local connection
	local cancelConn
	if returned == 1  then
		connection = Insert.TextButton.MouseButton1Click:Connect(function()
			response = Vector2.new(tonumber(Insert.SizeBox.X.Text),tonumber(Insert.SizeBox.Y.Text))
		end)
	elseif returned == 2 then
		connection = Insert.TextButton.MouseButton1Click:Connect(function()
			response = tonumber(Insert.DataBox.TextBox.Text)
		end)
	end
	
	cancelConn = Insert.Frame.TextButton.MouseButton1Click:Connect(function()
		response = false
	end)

	repeat task.wait() until response ~= nil

	connection:Disconnect()
	cancelConn:Disconnect()
	return response
end

function showLoading()
	for i,a in pairs(Insert:GetChildren()) do
		if a:IsA("GuiObject") then
			a.Visible = false
		end
	end
	Insert.Loading.Visible = true
end

function closeLoading()
	for i,a in pairs(Insert:GetChildren()) do
		if a:IsA("GuiObject") then
			a.Visible = true
		end
	end
	Insert.Loading.Visible = false
end

function Visible()
	if frame.Visible == true then
		ButtonBack.Visible = false
	else
		ButtonBack.Visible = true
	end
end

local function toggleWindow()
	dockWidget.Enabled = not dockWidget.Enabled
	if dockWidget.Enabled then
		if frameSprite.Visible == true then
			model.Enabled = true
		end
	end
end

function clickEscene(Escene:string)
	for i, fra in pairs(FolderEscenes) do
		if fra.Name == Escene then
			fra.Visible = true
		else
			fra.Visible = false
		end
	end
	Visible()
	if Escene == "Editor" then
		model.Enabled = true
		local nums = 0
		for i, a in pairs(SpriteFolder:GetChildren()) do
			nums+=1
		end
		if nums ==0 then
			model.Frame.Visible = false
		end
	else
		model.Enabled = false
	end
end

local EditableImage = game:GetService("AssetService"):CreateEditableImage({Size = SIZE})
model.Frame.Editor.ImageLabel.ImageContent = Content.fromObject(EditableImage)

local paperEdit = AssetService:CreateEditableImage({Size = SIZE})
model.Frame.Editor.Paper.ImageContent = Content.fromObject(paperEdit)	

function Effect(val, instance:Instance)
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		if val == true then
			twenService:Create(instance,tweenInf,{ImageColor3 = Color3.fromRGB(150, 150, 150),BackgroundColor3 =Color3.fromRGB(150, 150, 150)}):Play()
		else
			twenService:Create(instance,tweenInf,{ImageColor3 = Color3.fromRGB(255, 255, 255),BackgroundColor3 =Color3.fromRGB(255, 255, 255)}):Play()
		end
	end
end

function getFrameScaleForCells(desiredCells: Vector2): UDim2
	local scaleX = 2 / desiredCells.X
	local scaleY = 2 / desiredCells.Y
	return Vector2.new(scaleX,scaleY)
end

function CreateImageSprite(ImageObject:ImageLabel|ImageButton,Size,FolderName:Folder)
	if ImageObject and (ImageObject:IsA("ImageLabel") or ImageObject:IsA("ImageButton")) then
		local Connections = TableOfConnections[ImageObject]
		if Connections then
			for i,a in pairs(Connections) do
				a:Disconnect()
			end
		end
		local EditableToMe:EditableImage = ImageObject.ImageContent.Object
		if EditableToMe then
			EditableToMe:Destroy()
			ImageObject.ImageContent = Content.none
		end
		local Frame = ImageObject:GetAttribute("Frame")
		if not Frame then
			ImageObject:SetAttribute("Frame",1)
		end
		local IsPlayingAnimation = ImageObject:GetAttribute("IsPlayingAnimation")
		if not (IsPlayingAnimation== false or IsPlayingAnimation == true ) then
			ImageObject:SetAttribute("IsPlayingAnimation",false)
		end
		local MinFrame = ImageObject:GetAttribute("MinFrame")
		if not MinFrame then
			ImageObject:SetAttribute("MinFrame",1)
		end
		local MaxFrame = ImageObject:GetAttribute("MaxFrame")
		if not MaxFrame then
			ImageObject:SetAttribute("MaxFrame",1)
		end
		local FPS = ImageObject:GetAttribute("FPS")
		if not FPS then
			ImageObject:SetAttribute("FPS",12)
		end
		local Loop = ImageObject:GetAttribute("Loop")
		if not (Loop== false or Loop == true ) then
			ImageObject:SetAttribute("Loop",true)
		end
		local a,b,c,d
		local CurrentFrame = FolderName:FindFirstChild(ImageObject:GetAttribute("Frame")) 
		ImageObject:SetAttribute("Frame",1)
		CurrentFrame = FolderName:FindFirstChild(ImageObject:GetAttribute("Frame")) 
		EditableToMe = AssetService:CreateEditableImage({Size = Size })
		ImageObject:SetAttribute("ImageFolder",FolderName.Name)
		local GetBuffer = CurrentFrame:GetAttribute("Image")
		if GetBuffer then
			GetBuffer = buffer.fromstring(GetBuffer)
			EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,GetBuffer)	
			if CurrentFrame then
				a = CurrentFrame:GetAttributeChangedSignal("Image"):Connect(function()
					GetBuffer = CurrentFrame:GetAttribute("Image")
					GetBuffer = buffer.fromstring(GetBuffer)
					EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,GetBuffer)	
				end)	
			else
				ImageObject.ImageContent = Content.none
			end
		end
		b = FolderName.ChildAdded:Connect(function()
			wait()
			CurrentFrame = FolderName:FindFirstChild(ImageObject:GetAttribute("Frame")) 
			if not CurrentFrame then
				ImageObject.ImageContent = Content.none
				return
			end
			ImageObject.ImageContent = Content.fromObject(EditableToMe)
			local GetBuffer = CurrentFrame:GetAttribute("Image")
			GetBuffer = buffer.fromstring(GetBuffer)
			EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,GetBuffer)	
			a = CurrentFrame:GetAttributeChangedSignal("Image"):Connect(function()
				GetBuffer = CurrentFrame:GetAttribute("Image")
				GetBuffer = buffer.fromstring(GetBuffer)
				EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,GetBuffer)	
			end)		
		end)
		c = FolderName.ChildRemoved:Connect(function()
			wait()
			CurrentFrame = FolderName:FindFirstChild(ImageObject:GetAttribute("Frame")) 
			if not CurrentFrame then
				ImageObject.ImageContent = Content.none
				return
			end
			ImageObject.ImageContent = Content.fromObject(EditableToMe)
			local GetBuffer = CurrentFrame:GetAttribute("Image")
			GetBuffer = buffer.fromstring(GetBuffer)
			EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,GetBuffer)	
			a = CurrentFrame:GetAttributeChangedSignal("Image"):Connect(function()
				GetBuffer = CurrentFrame:GetAttribute("Image")
				GetBuffer = buffer.fromstring(GetBuffer)
				EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,GetBuffer)	
			end)
		end)
		d = ImageObject:GetAttributeChangedSignal("Frame"):Connect(function()
			CurrentFrame = FolderName:FindFirstChild(ImageObject:GetAttribute("Frame")) 
			if CurrentFrame then
				ImageObject.ImageContent = Content.fromObject(EditableToMe)
				local GetBuffer = CurrentFrame:GetAttribute("Image")
				GetBuffer = buffer.fromstring(GetBuffer)
				EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,GetBuffer)	
				a = CurrentFrame:GetAttributeChangedSignal("Image"):Connect(function()
					GetBuffer = CurrentFrame:GetAttribute("Image")
					GetBuffer = buffer.fromstring(GetBuffer)
					EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,GetBuffer)	
				end)
			else
				ImageObject.ImageContent = Content.none
			end
		end)
		TableOfConnections[ImageObject] = {a,b,c,d}
		ImageObject.ImageContent = Content.fromObject(EditableToMe)
	end
end

script.Value.Changed:Connect(function(obj:Frame)
	local oldFrame:Frame = script.Old.Value
	if oldFrame then
		TweenService:Create(oldFrame,TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{BackgroundColor3 = Theme.CardBG}):Play()
		oldFrame.BtnDelete.Visible = false
		oldFrame.BtnSize.Visible = true
		oldFrame.BtnImport.Visible = false
		oldFrame.NameInput.Size = UDim2.new(1,-97,0,34)
	end
	if obj~= nil then
		obj.BackgroundColor3 = Color3.fromRGB(0, 39, 184)
		obj.NameInput.Size = UDim2.new(1,-170,0,34)
		obj.BtnDelete.Visible = true
		obj.BtnImport.Visible = true
		obj.BtnSize.Visible = false
		model.Frame.Visible = true
		if EditableImage then
			EditableImage:Destroy()
		end
		if paperEdit then
			paperEdit:Destroy()
		end
		for i, a in pairs(obj.Parent:GetChildren()) do
			if a:IsA("ImageLabel") then
				if obj == a then
					obj.UIStroke.Enabled = true
				else
					a.UIStroke.Enabled = false
				end
			end
		end
		local objE:EditableImage = selects.ImageContent.Object
		if objE then
			objE:Destroy()
			selects.ImageContent = Content.none
		end
		selects.Visible = false
		SIZE = obj.Value.Value:GetAttribute("Size")
		local Min = math.min(SIZE.X,SIZE.Y)
		Min = math.min(Min,100)
		EditableImage = game:GetService("AssetService"):CreateEditableImage({Size = SIZE})
		paperEdit = AssetService:CreateEditableImage({Size = SIZE})
		model.Frame.Editor.Paper.ImageContent = Content.fromObject(paperEdit)	
		model.Frame.Editor.ImageLabel.ImageContent = Content.fromObject(EditableImage)
		local Max = false
		if SIZE.Y>SIZE.X then
			Max = true
		end
		ChangeX.ChangeMaxs(model.Frame.Scale.Handle.TextButton,Vector2.new(1,Min),model.Frame.Scale.Size)
		local sizeX = anteriorSize / SIZE.X
		local sizeY = anteriorSize / SIZE.Y
		if types == "Pen" or types == "Era" then
			point.Size = UDim2.new(sizeX, 0, sizeY, 0)
		else
			local sizeX = 1 / SIZE.X
			local sizeY = 1 / SIZE.Y
			point.Size = UDim2.fromScale(sizeX,sizeY)
		end
		if Max then
			model.Frame.Editor.Paper.Size = UDim2.fromScale(SIZE.X/SIZE.Y,1)
			model.Frame.Editor.ImageLabel.Size = UDim2.fromScale(SIZE.X/SIZE.Y,1)
		else
			model.Frame.Editor.Paper.Size = UDim2.fromScale(1,SIZE.Y/SIZE.X)
			model.Frame.Editor.ImageLabel.Size = UDim2.fromScale(1,SIZE.Y/SIZE.X)
		end
		local Cells = getFrameScaleForCells(SIZE)
		model.Frame.Editor.Grid.Position = UDim2.fromScale(0.5,0.5)
		model.Frame.Editor.Grid.TileSize = UDim2.fromScale(Cells.X*1,Cells.Y*1)
		model.Frame.Editor.Grid.Size = model.Frame.Editor.ImageLabel.Size
		model.Frame.FrameDates.Value = obj.Value.Value
		model.Frame.Editor.Paper.Position = UDim2.fromScale(0.5,0.5)
		model.Frame.Editor.ImageLabel.Position = UDim2.fromScale(0.5,0.5)
	else
		local buttons = model.Frame.SavedSprites:GetChildren()
		for i,a in pairs(buttons) do
			if a:IsA("ImageButton") then
				a.ImageContent.Object:Destroy()
				a:Destroy()
			end
		end
		model.Frame.Visible = false
	end
end)

function SetImageFirst(Folder,EditableToMe)
	if not Folder then return nil end
	local cc
	cc = Folder:GetAttributeChangedSignal("Image"):Connect(function()
		local Image = Folder:GetAttribute("Image")
		if Image then
			EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,buffer.fromstring(Image))
		end
	end)
	local Image = Folder:GetAttribute("Image")
	if Image then
		EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,buffer.fromstring(Image))
	end
	return cc
end


function CreateSprite(name:string, inst:Folder|nil, size:Vector2, another)
	if not CanClick and not another then return end
	local Newbuttons = Instance.new("Frame")
	Newbuttons.Name = "SpriteCard_" .. name
	Newbuttons.Size = UDim2.new(1, -10, 0, 56) 
	Newbuttons.BackgroundColor3 = Theme.CardBG
	Newbuttons.Parent = FrameMovement
	Newbuttons.Active = true
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = Newbuttons

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Theme.Stroke
	cardStroke.Thickness = 1.5
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cardStroke.Parent = Newbuttons

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = Newbuttons

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = Newbuttons

	local Newbuttontext = Instance.new("TextBox")
	Newbuttontext.Name = "NameInput"
	Newbuttontext.ClearTextOnFocus = false
	Newbuttontext.Size = UDim2.new(1, -97, 0, 34) 
	Newbuttontext.BackgroundColor3 = Theme.TextBoxBG
	Newbuttontext.Text = name
	Newbuttontext.TextColor3 = Theme.Text
	Newbuttontext.PlaceholderText = "New Sprite"
	Newbuttontext.PlaceholderColor3 = Theme.Placeholder
	Newbuttontext.Font = Enum.Font.GothamMedium
	Newbuttontext.TextSize = 14
	Newbuttontext.TextXAlignment = Enum.TextXAlignment.Left
	Newbuttontext.ClipsDescendants = true
	Newbuttontext.LayoutOrder = 1
	Newbuttontext.Parent = Newbuttons

	local inputPadding = Instance.new("UIPadding")
	inputPadding.PaddingLeft = UDim.new(0, 10)
	inputPadding.Parent = Newbuttontext

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = Newbuttontext

	local inputStroke = Instance.new("UIStroke")
	inputStroke.Color = Theme.Stroke
	inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	inputStroke.Parent = Newbuttontext

	Newbuttontext.Focused:Connect(function()
		TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Theme.TextBoxFocus}):Play()
	end)
	Newbuttontext.FocusLost:Connect(function()
		TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
	end)
	
	local NewFolder:Folder = inst or Instance.new("Folder")
	local currentCollision = NewFolder:GetAttribute("CollisionType")
	if not currentCollision or not table.find(existinCollide, currentCollision) then
		currentCollision = "Convex"
		NewFolder:SetAttribute("CollisionType", "Convex")	
	end
	local currentResolution = NewFolder:GetAttribute("Resolution")
	if not currentResolution or typeof(currentResolution)~="number" then
		NewFolder:SetAttribute("Resolution", 1)	
		currentResolution = 1
	end
	local canCreate = false
	local currentRelative = NewFolder:GetAttribute("Relative")
	if not currentRelative or typeof(currentRelative)~="boolean" then
		NewFolder:SetAttribute("Relative", false)
		currentRelative = false
	end
	if not NewFolder:GetAttribute("Size") then
		if size then
			NewFolder:SetAttribute("Size",size)
		else
			CanClick = false
			local data:string|boolean = requestUserInput({2,6,5,10},"24",1)
			if not data then
				Insert.Visible = false
				NewFolder:Destroy()
				Newbuttons:Destroy()
				CanClick = true
				return
			end
			Insert.Visible = false
			NewFolder:SetAttribute("Size",data)
			NewFolder.Parent = SpriteFolder
			size = data
			canCreate = true
			CanClick = true
		end
	end

	local myGui = SpriteOptions:Clone()

	local SpriteImport = Instance.new("TextButton")
	SpriteImport.Name = "BtnImport"
	SpriteImport.Size = UDim2.new(0, 75, 0, 34)
	SpriteImport.BackgroundColor3 = Theme.ButtonImport
	SpriteImport.Text = "Import"
	SpriteImport.TextColor3 = Color3.new(1, 1, 1)
	SpriteImport.Font = Enum.Font.GothamBold
	SpriteImport.TextSize = 13
	SpriteImport.LayoutOrder = 2
	SpriteImport.AutoButtonColor = false 
	SpriteImport.Parent = Newbuttons
	SpriteImport.Visible = false
	
	local importCorner = Instance.new("UICorner")
	importCorner.CornerRadius = UDim.new(0, 6)
	importCorner.Parent = SpriteImport

	local importStroke = Instance.new("UIStroke")
	importStroke.Color = Theme.Stroke
	importStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	importStroke.Parent = SpriteImport

	applyHoverEffect(SpriteImport, Theme.ButtonImport, Theme.ButtonImportHover)

	local DeleteButton = Instance.new("TextButton")
	DeleteButton.Name = "BtnDelete"
	DeleteButton.Size = UDim2.new(0, 75, 0, 34)
	DeleteButton.BackgroundColor3 = Theme.ButtonDelete
	DeleteButton.Text = "Delete"
	DeleteButton.TextColor3 = Color3.new(1, 1, 1)
	DeleteButton.Font = Enum.Font.GothamBold
	DeleteButton.TextSize = 13
	DeleteButton.LayoutOrder = 3
	DeleteButton.AutoButtonColor = false
	DeleteButton.Parent = Newbuttons
	DeleteButton.Visible = false
	
	local deleteCorner = Instance.new("UICorner")
	deleteCorner.CornerRadius = UDim.new(0, 6)
	deleteCorner.Parent = DeleteButton

	local deleteStroke = Instance.new("UIStroke")
	deleteStroke.Color = Theme.Stroke
	deleteStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	deleteStroke.Parent = DeleteButton

	applyHoverEffect(DeleteButton, Theme.ButtonDelete, Theme.ButtonDeleteHover)

	local sizeText:TextLabel = Instance.new("TextLabel")
	sizeText.Text = "X: "..size.X.." Y: "..size.Y
	sizeText.Name = "BtnSize"
	sizeText.Size = UDim2.new(0, 75, 0, 34)
	sizeText.BackgroundColor3 = Theme.ButtonDelete
	sizeText.TextColor3 = Color3.new(1, 1, 1)
	sizeText.Font = Enum.Font.GothamBold
	sizeText.TextSize = 13
	sizeText.LayoutOrder = 3
	sizeText.Parent = Newbuttons
	sizeText.Visible = true
	sizeText.Active = false
	
	local deleteCorner = Instance.new("UICorner")
	deleteCorner.CornerRadius = UDim.new(0, 6)
	deleteCorner.Parent = sizeText

	local deleteStroke = Instance.new("UIStroke")
	deleteStroke.Color = Theme.Stroke
	deleteStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	deleteStroke.Parent = sizeText
	
	applyHoverEffect(Newbuttons, Theme.CardBG, Theme.CardHover,true)

	DeleteButton.MouseButton1Click:Connect(function()
		NewFolder.Parent = nil
		HistoryService:SetWaypoint(HTTP:GenerateGUID(false))
	end)

	local FirstImage = nil
	local ImageBuffer = nil
	local newname = name
	local i = 1
	local TableOfBuffers = {}
	while true do
		if SpriteFolder:FindFirstChild(newname) and SpriteFolder:FindFirstChild(newname) == NewFolder then
			break
		end
		if not SpriteFolder:FindFirstChild(newname)  then
			name = newname
			break
		end
		i+=1
		newname = name.."("..i..")"
	end
	NewFolder.Name = name
	Newbuttons.Name = name
	Newbuttontext.Text = name

	for i, a in pairs(NewFolder:GetChildren()) do
		if a:IsA("Folder") then
			if a.Name == "1" then
				FirstImage = a
				ImageBuffer = a:GetAttribute("Image")
			end
		end
	end

	SpriteImport.MouseButton1Click:Connect(function()
		if not CanClick then return end
		CanClick = false
		local ImageId = requestUserInput({3,10},"",2)
		if ImageId then
			showLoading()
			local Can,EditableImageTemp = pcall(function()
				return AssetService:CreateEditableImageAsync(Content.fromAssetId(ImageId))
			end)
			if Can then
				local GridSize:boolean|Vector2 =  requestUserInput({2,4,10},"1",1)
				if not GridSize then
					EditableImageTemp:Destroy()
					warn("Error. Grid Size must be 2 numbers seperated by a comma")
					CanClick = true
					closeLoading()
					Insert.Visible = false
					model.Frame.Visible = true
					return
				end
				local allImageBuffer,RealScale = ResizeSystem.SeparateBuffers(EditableImageTemp,GridSize,Check.Value.Value)
				local Center = (SIZE-RealScale)/2
				if Center.X<0 then
					Center = Vector2.new(0,Center.Y)
				end
				if Center.Y<0 then
					Center = Vector2.new(Center.X,0)
				end
				for i,a in pairs(allImageBuffer) do
					local editable,button = save.create(nil,SIZE,model.Frame.SavedSprites,model.Frame.FrameDates.Value)
					local Can,Error = pcall(function()
						editable:WritePixelsBuffer(Center,RealScale,a.Buffer)
						save.save(model.Frame.SavedSprites,button ,SIZE)
					end)
					if not Can then
						warn(Error)
					end
				end
				CanClick = true
				EditableImageTemp:Destroy()
				closeLoading()
				Insert.Visible = false
				model.Frame.Visible = true
				return
			else
				warn("Error. You do not have permission to use this ID")
				CanClick = true
				closeLoading()
				model.Frame.Visible = true
				Insert.Visible = false
				return
			end
		else
			CanClick = true
			closeLoading()
			model.Frame.Visible = true
			Insert.Visible = false
			return
		end
	end)
	local EditableCollisionUI = script.SpritelyCollisionMap:Clone()
	EditableCollisionUI:AddTag("EDITABLECOLLISIONMAPDELETE")
	local SetUpCollision = require(script.GenerateColliderEditor)
	local newEditable = AssetService:CreateEditableImage({Size = size})
	table.insert(AllEditables,newEditable)
	SetUpCollision.New(EditableCollisionUI.MainFrame,NewFolder,newEditable,myGui.ScrollingFrame.ExtraCollide.Custom)
	EditableCollisionUI.Enabled = false
	EditableCollisionUI.Parent = CoreGui
	local EditableToMe = AssetService:CreateEditableImage({Size = NewFolder:GetAttribute("Size")})
	local SpriteButton:ImageButton = createinstances.createbutton("ImageButton",EditableToMe,ImageMovement,Color3.new(1,1,1),0,UDim2.fromScale(0.5,0),UDim2.fromScale(0.8,0.5))
	SpriteButton.AnchorPoint = Vector2.new(0.5,0)
	SpriteButton.AutoButtonColor = false
	SpriteButton.MouseEnter:Connect(function()
		Effect(true,SpriteButton)
	end)
	local Images = {}
	SpriteButton.MouseLeave:Connect(function()
		Effect(false,SpriteButton)
	end)
	if ImageBuffer then
		EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,buffer.fromstring(ImageBuffer))
	end
	local DetectChange = SetImageFirst(FirstImage,EditableToMe)
	NewFolder.ChildAdded:Connect(function(Child)
		local Childs = #NewFolder:GetChildren()
		myGui.ScrollingFrame.Frames.TextButton.Text = Childs
		wait()
		if Child.Name == "1" then
			if DetectChange then
				DetectChange:Disconnect()
			end
			DetectChange = SetImageFirst(Child,EditableToMe)
		end
	end)
	NewFolder.ChildRemoved:Connect(function(Child)
		if Child == FirstImage then
			if DetectChange then
				DetectChange:Disconnect()
			end
			wait()
			FirstImage = NewFolder:FindFirstChild("1")
			if FirstImage then
				DetectChange = SetImageFirst(FirstImage,EditableToMe)
			else
				ImageBuffer = buffer.create(EditableToMe.Size.X*EditableToMe.Size.Y*4)
				EditableToMe:WritePixelsBuffer(Vector2.zero,EditableToMe.Size,ImageBuffer)
			end
		end
		local Childs = #NewFolder:GetChildren()
		myGui.ScrollingFrame.Frames.TextButton.Text = Childs
	end)	
	SpriteButton.MouseButton1Click:Connect(function()
		if CanClick then
			for i,a in pairs(Escenes.Parent:GetChildren()) do
				if a.Name == SpriteOptions.Name then
					a.Visible = false
				end
			end
			Escenes.Visible = false
			myGui.Visible = true
			local Selecteds = Selection:Get()
			table.clear(Images)
			for i, a in pairs(Selecteds) do
				if a:IsA("ImageButton") or a:IsA("ImageLabel") then
					table.insert(Images,a)
				end
			end
			if #Images>0 then
				myGui.ScrollingFrame.Error.Visible = false
				myGui.ScrollingFrame.ObjectTitle.Visible = false
				myGui.ScrollingFrame.Properties.Visible = false
				local canVisible = false
				for i,a in pairs(Images) do
					if a:GetAttribute("ImageFolder") ~= NewFolder.Name or not a.ImageContent.Object then
						canVisible = true
						break
					end
				end
				myGui.ScrollingFrame.Selector.Visible = canVisible
			else
				myGui.ScrollingFrame.Error.Visible = true
				myGui.ScrollingFrame.Properties.Visible = false
				myGui.ScrollingFrame.Selector.Visible = false
				myGui.ScrollingFrame.ObjectTitle.Visible = false
			end
		end
	end)	
	Instance.new("UIAspectRatioConstraint",SpriteButton)
	local c = nil
	local obj = Instance.new("ObjectValue", Newbuttons)
	obj.Value = NewFolder
	local A,B,C,D,E,F,G
	local a = Newbuttontext.FocusLost:Connect(function()
		name = Newbuttontext.Text
		newname = name
		i = 1
		while true do
			if SpriteFolder:FindFirstChild(newname) and SpriteFolder:FindFirstChild(newname) == NewFolder then
				break
			end
			if not SpriteFolder:FindFirstChild(newname)  then
				name = newname
				break
			end
			i+=1
			newname = name.."("..i..")"
		end
		NewFolder.Name = name
		Newbuttontext.Text = name
		Newbuttons.Name = name
		myGui.TextButton.Text = name
	end)

	C = NewFolder:GetPropertyChangedSignal("Parent"):Connect(function()
		local parent = NewFolder and NewFolder.Parent
		if not parent or not (parent == SpriteFolder) then
			Newbuttons.Visible = false
			SpriteButton.Visible = false
			local detectionum = 0
			for i, a in pairs(SpriteFolder:GetChildren()) do
				if a:IsA("Folder") then
					detectionum+=1
				end
			end
			if detectionum == 0 then
				model.Frame.Visible = false
				script.Value.Value = nil
			else
				local GetButton
				if script.Value.Value ~=Newbuttons then return end 
				for i, a in pairs(FrameMovement:GetChildren()) do
					if a:IsA("Frame") and a.Visible then
						GetButton = a
					end
				end
				script.Value.Value = GetButton
			end
		elseif parent and parent ==  SpriteFolder then
			Newbuttons.Visible = true
			SpriteButton.Visible = true
		end
	end)

	
	myGui:GetPropertyChangedSignal("Visible"):Connect(function()
		if myGui.Visible == false and EditableCollisionUI.Enabled then
			EditableCollisionUI.Enabled = false
		end
	end)
	
	Selection.SelectionChanged:Connect(function()
		if myGui.Visible then
			local Selecteds = Selection:Get()
			table.clear(Images)
			for i, a in pairs(Selecteds) do
				if a:IsA("ImageButton") or a:IsA("ImageLabel") then
					table.insert(Images,a)
				end
			end
			if #Images>0 then
				myGui.ScrollingFrame.Error.Visible = false
				myGui.ScrollingFrame.ObjectTitle.Visible = true
				myGui.ScrollingFrame.Properties.Visible = true
				local canVisible = false
				for i,a in pairs(Images) do
					if a:GetAttribute("ImageFolder") ~= NewFolder.Name then
						canVisible = true
						break
					end
				end
				myGui.ScrollingFrame.Selector.Visible = canVisible
			else
				myGui.ScrollingFrame.Error.Visible = true
				myGui.ScrollingFrame.Properties.Visible = false
				myGui.ScrollingFrame.Selector.Visible = false
				myGui.ScrollingFrame.ObjectTitle.Visible = false
			end
		end
	end)

	myGui.FolderValue.Value = NewFolder
	myGui.ButtonValue.Value = SpriteButton
	myGui.Visible = false
	myGui.Parent = dockWidget
	myGui.TextButton.Text = NewFolder.Name

	myGui.ScrollingFrame.Collision.TextButton.MouseButton1Click:Connect(function()
		if myGui.ScrollingFrame.Collision.TextButton.Selector.Visible then
			myGui.ScrollingFrame.Collision.TextButton.Selector.Visible = false
			myGui.ScrollingFrame.Collision.TextButton.XqZc.Visible = false
		else	
			myGui.ScrollingFrame.Collision.TextButton.Selector.Visible = true
			myGui.ScrollingFrame.Collision.TextButton.XqZc.Visible = true
		end
	end)
	myGui.ScrollingFrame.ExtraCollide.Custom.MouseButton1Click:Connect(function()
		EditableCollisionUI.Enabled = true
	end)
	inputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if myGui.Visible then
				myGui.ScrollingFrame.Collision.TextButton.Selector.Visible = false
				myGui.ScrollingFrame.Collision.TextButton.XqZc.Visible = false
			end	
		end
	end)

	for i,a in pairs(myGui.ScrollingFrame.Collision.TextButton.Selector:GetChildren()) do
		if a:IsA("TextButton") then
			a.MouseButton1Click:Connect(function()
				NewFolder:SetAttribute("CollisionType",a.Text)
				myGui.ScrollingFrame.Collision.TextButton.Selector.Visible = false
				myGui.ScrollingFrame.Collision.TextButton.XqZc.Visible = false
			end)
			if NewFolder:GetAttribute("CollisionType") == a.Text then
				a.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			else
				a.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			end
		end
	end
	myGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			myGui.ScrollingFrame.Collision.TextButton.Selector.Visible = false
			myGui.ScrollingFrame.Collision.TextButton.XqZc.Visible = false
		end
	end)
	myGui.ScrollingFrame.Selector.MouseButton1Click:Connect(function()
		for i, a in pairs(Images) do
			a:AddTag("SpritelyObject")
			CreateImageSprite(a,EditableToMe.Size,NewFolder)
		end
	end)

	NewFolder:GetAttributeChangedSignal("CollisionType"):Connect(function()
		local actualcollision = NewFolder:GetAttribute("CollisionType")
		if not actualcollision or not table.find(existinCollide,actualcollision) then
			NewFolder:SetAttribute("CollisionType","Convex")
			actualcollision = "Convex"
		end
		myGui.ScrollingFrame.ExtraCollide.Visible = true
		for i, a in pairs(myGui.ScrollingFrame.ExtraCollide:GetChildren()) do
			if a:IsA("Frame") or a:IsA("TextButton") then
				local names = {}
				for i,a in pairs(CollisionTypes[actualcollision]) do
					table.insert(names,a)
				end
				if table.find(names,a.Name) then
					a.Visible = true
				else
					a.Visible = false
				end
			end
		end
		for i,a in pairs(myGui.ScrollingFrame.Collision.TextButton.Selector:GetChildren()) do
			if a:IsA("TextButton") then
				if actualcollision == a.Text then
					a.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				else
					a.BackgroundColor3 = Color3.fromRGB(80,80,80)
				end
			end
		end
		myGui.ScrollingFrame.Collision.TextButton.Text = actualcollision
	end)

	myGui.ScrollingFrame.Collision.TextButton.Text = currentCollision
	for i, a in pairs(myGui.ScrollingFrame.ExtraCollide:GetChildren()) do
		if a:IsA("Frame") or a:IsA("TextButton") then
			local names = {}
			for i,a in pairs(CollisionTypes[currentCollision]) do
				table.insert(names,a)
			end
			if table.find(names,a.Name) then
				a.Visible = true
			else
				a.Visible = false
			end
		end
	end

	myGui.ScrollingFrame.ExtraCollide.Resolution.TextButton_Converted.Text = currentResolution
	myGui.ScrollingFrame.ExtraCollide.Relative.Check.MouseButton1Click:Connect(function()
		myGui.ScrollingFrame.ExtraCollide.Relative.Check.Value.Value = not myGui.ScrollingFrame.ExtraCollide.Relative.Check.Value.Value
		NewFolder:SetAttribute("Relative",myGui.ScrollingFrame.ExtraCollide.Relative.Check.Value.Value)	
	end)

	NewFolder:GetAttributeChangedSignal("Relative"):Connect(function()
		local Relative = NewFolder:GetAttribute("Relative")
		if Relative == nil then
			NewFolder:SetAttribute("Relative",false)
			Relative = false
		end
		myGui.ScrollingFrame.ExtraCollide.Relative.Check.Value.Value = Relative
	end)

	myGui.ScrollingFrame.ExtraCollide.Relative.Check.Value.Changed:Connect(function(val)
		local position = UDim2.fromScale(0.05,0.5)
		local color = Color3.fromRGB(152, 152, 152)
		if val then
			position = UDim2.fromScale(.6,0.5)
			color = Color3.fromRGB(48, 114, 255)
		end
		twenService:Create(myGui.ScrollingFrame.ExtraCollide.Relative.Check.Frame,TweenInfo.new(.2,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out),{Position = position}):Play()
		twenService:Create(myGui.ScrollingFrame.ExtraCollide.Relative.Check,TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.In),{BackgroundColor3 = color}):Play()	
	end)

	myGui.ScrollingFrame.ExtraCollide.Relative.Check.Value.Value = currentRelative
	NewFolder:GetAttributeChangedSignal("Resolution"):Connect(function()
		local actualresolution = NewFolder:GetAttribute("Resolution")
		if not actualresolution then
			NewFolder:SetAttribute("Resolution",1)
			myGui.ScrollingFrame.ExtraCollide.Resolution.TextButton_Converted.Text = "1"
			return
		end
		myGui.ScrollingFrame.ExtraCollide.Resolution.TextButton_Converted.Text = actualresolution
	end)
	B = Newbuttons.Destroying:Connect(function()
		B:Disconnect()
		C:Disconnect()
		SpriteButton.ImageContent.Object:Destroy()
		SpriteButton:Destroy()
		EditableToMe:Destroy()	
	end)

	script.Old.Value = script.Value.Value
	
	script.Value.Value = Newbuttons

	Newbuttons.InputBegan:Connect(function(input)
		if not CanClick then return end 
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not (script.Value.Value == Newbuttons) then
				model.Frame.Play:SetAttribute("On",false)
				task.wait()
				script.Old.Value = script.Value.Value
				script.Value.Value = Newbuttons
			end	
		end
	end)

	NewFolder:GetPropertyChangedSignal("Name"):Connect(function()
		name = NewFolder.Name
		newname = name
		i = 1
		while true do
			if SpriteFolder:FindFirstChild(newname) and SpriteFolder:FindFirstChild(newname) == NewFolder then
				break
			end
			if not SpriteFolder:FindFirstChild(newname)  then
				name = newname
				break
			end
			i+=1
			newname = name.."("..i..")"
		end
	end)
	myGui.ScrollingFrame.Frames.TextButton.Text = #NewFolder:GetChildren()
	NewFolder.Parent = SpriteFolder
	model.Frame.FrameDates.Value = NewFolder
	wait()
	if canCreate then
		save.create(nil,NewFolder:GetAttribute("Size"),model.Frame.SavedSprites,NewFolder)
	end
end

function styleNavButton(btn)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Stroke
	stroke.Thickness = 1.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Hover}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Idle}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
	end)
end

local FramePixel = model.Frame.ToolEditors.Pen
button.Click:Connect(toggleWindow)
local AnteriorBuffer = EditableImage:ReadPixelsBuffer(Vector2.zero,SIZE)
local NavContainer = Instance.new("Frame")
NavContainer.Name = "NavContainer"
NavContainer.Size = UDim2.new(1, 0, 0, 120)
NavContainer.BackgroundTransparency = 1
NavContainer.Parent = frame

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 8)
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.Parent = NavContainer

local TextSprite = createinstances.createbutton("TextButton", "Custom Sprites", NavContainer, Theme.Idle, 0, UDim2.new(0,0,0,0), UDim2.new(0.9, 0, 0, 35))
TextSprite.Font = Enum.Font.GothamBold
TextSprite.TextColor3 = Theme.Text
TextSprite.TextSize = 14
TextSprite.AutoButtonColor = false
TextSprite.TextScaled = false
TextSprite.BackgroundColor3 = Theme.Idle
styleNavButton(TextSprite)

local AddSprite = createinstances.createbutton("TextButton", "Sprites Properties", NavContainer, Theme.Idle, 0, UDim2.new(0,0,0,0), UDim2.new(0.9, 0, 0, 35))
AddSprite.Font = Enum.Font.GothamBold
AddSprite.TextColor3 = Theme.Text
AddSprite.TextSize = 14
AddSprite.AutoButtonColor = false
AddSprite.TextScaled = false
AddSprite.BackgroundColor3 = Theme.Idle
styleNavButton(AddSprite)

local SettingsBtn:TextButton = createinstances.createbutton("TextButton", "Plugin Settings (Developing)", NavContainer, Theme.Idle, 0, UDim2.new(0,0,0,0), UDim2.new(0.9, 0, 0, 35))
SettingsBtn.Font = Enum.Font.GothamBold
SettingsBtn.TextColor3 = Theme.Text
SettingsBtn.TextSize = 14
SettingsBtn.AutoButtonColor = false
SettingsBtn.TextScaled = false
SettingsBtn.BackgroundColor3 = Theme.Idle

local ScenesButton = createinstances.createbutton("TextButton", "Scenes (Developing)", NavContainer, Theme.Idle, 0, UDim2.new(0,0,0,0), UDim2.new(0.9, 0, 0, 35))
ScenesButton.Font = Enum.Font.GothamBold
ScenesButton.TextColor3 = Theme.Text
ScenesButton.TextSize = 14
ScenesButton.BackgroundColor3 = Theme.Idle
ScenesButton.TextScaled = false
ScenesButton.AutoButtonColor = false

local OpenValues = {["Pen"] = "Pen",["Era"] = "Pen",["Paint"] = "Paint"}

model.Frame.Tool.Changed:Connect(function(newTool)
	for i,a in pairs(model.Frame.ToolEditors:GetChildren()) do
		if a:IsA("Frame") then
			a.Visible = false
		end
	end
	local Open = OpenValues[newTool]
	if not Open then return end
	local setvisible = model.Frame.ToolEditors:FindFirstChild(Open)
	if setvisible then
		setvisible.Visible = true
	end
end)

local function isInside(SIZE, RealScale, Center)
	return Center.X >= 0 and
		Center.Y >= 0 and
		(Center.X + RealScale.X) <= SIZE.X and
		(Center.Y + RealScale.Y) <= SIZE.Y
end

ImportGenerat.MouseButton1Click:Connect(function()
	if not CanClick then return end
	CanClick = false
	local ImageId = requestUserInput({3,10},"",2)
	if ImageId then
		showLoading()
		local Can,EditableImageTemp = pcall(function()
			return AssetService:CreateEditableImageAsync(Content.fromAssetId(ImageId))
		end)
		if Can then
			local GridSize:boolean|Vector2 =  requestUserInput({2,4,10},"1",1)
			if not GridSize then
				warn("Canceled.")
				EditableImageTemp:Destroy()
				closeLoading()
				Insert.Visible = false
				model.Frame.Visible = true
				CanClick = true
				return
			end
			local allImageBuffer,RealScale = ResizeSystem.SeparateBuffers(EditableImageTemp,GridSize,Insert.CheckSize.Check.Value.Value)
			local Center = Vector2.zero
			local AssetName = game:GetService("MarketplaceService"):GetProductInfoAsync(ImageId,Enum.InfoType.Asset)
			CreateSprite((AssetName.Name or "Import Sprite"),nil,RealScale,true)
			wait()
			for i,a in pairs(allImageBuffer) do
				local editable,button = save.create(false,RealScale,model.Frame.SavedSprites,model.Frame.FrameDates.Value)
				local Can,Error = pcall(function()
					editable:WritePixelsBuffer(Center,RealScale,a.Buffer)
					save.save(model.Frame.SavedSprites,button ,RealScale)
					save.SetAttribute(button,model.Frame.SavedSprites,RealScale,true)
				end)
				if not Can then
					warn(Error)
				end
			end
			CanClick = true
			EditableImageTemp:Destroy()
			Insert.Visible = false
			model.Frame.Visible = true
			return
		else
			EditableImageTemp:Destroy()
			warn("Error. Grid Size must be 2 numbers seperated by a comma")
			CanClick = true
			closeLoading()
			Insert.Visible = false
			model.Frame.Visible = true
			return
		end
	else
		closeLoading()
		CanClick = true
		model.Frame.Visible = true
		Insert.Visible = false
		return
	end
end)

local FrameFps = 30
local FrameRate = model.Frame.FrameRateBox

FrameRate:GetPropertyChangedSignal("Text"):Connect(function()
	local text = FrameRate.Text:gsub("[^%d+]", "")
	local NewText = tonumber(text) 
	if NewText then
		if NewText <=0 then
			NewText = 1
		elseif NewText > 120 then
			NewText = 120
		end
		FrameRate.Text = tostring(NewText)
		FrameFps = NewText
	else
		FrameRate.Text = ""
	end
end)

function IsValid(folder)
	for i,a in pairs(FrameMovement:GetChildren()) do
		if a:IsA("Frame") then
			if a.Value.Value == folder then
				return true
			end
		end
	end
	return false
end

SpriteFolder.ChildAdded:Connect(function(child)
	if child:IsA("Folder") then
		if not IsValid(child) and child:GetAttribute("Size") then
			CreateSprite(child.Name,child,child:GetAttribute("Size"))
		end
	end
end)

FrameRate.FocusLost:Connect(function()
	local frames = tonumber(FrameRate.Text)
	if not frames then
		FrameRate.Text = "30"
		FrameFps = 30
	else
		FrameFps = math.clamp(frames,1,120)
		FrameRate.Text = FrameFps
	end
end)

ButtonBack.MouseButton1Click:Connect(function()
	if not CanClick then return end
	for i,a in pairs(dockWidget:GetChildren()) do
		if a.Name == SpriteOptions.Name then
			if a.Visible then
				a.Visible = false
				clickEscene("Escenes")
				return
			end
		end
	end
	clickEscene("BaseButtons")
end)

ButtonBack.MouseEnter:Connect(function()
	Effect(true,ButtonBack)
end)

ButtonBack.MouseLeave:Connect(function()
	Effect(false,ButtonBack)
end)

TextSprite.MouseButton1Click:Connect(function()
	clickEscene("Editor")
end)

AddSprite.MouseButton1Click:Connect(function()
	clickEscene("Escenes")
end)
CreateNew.MouseButton1Click:Connect(function()
	CreateSprite("New Sprite",nil)
end)

local runfps = nil

local pointSize = Vector2.one

function changeSize(SizeNew)
	pointSize = Vector2.new(SizeNew, SizeNew)
end

local PixelPosition:Vector2 = Vector2.zero

runfps = run.RenderStepped:Connect(function()
	local parent = point.Parent
	local parentAbsPos = parent.AbsolutePosition
	local parentAbsSize = parent.AbsoluteSize

	local cellWidth = parentAbsSize.X / SIZE.X
	local cellHeight = parentAbsSize.Y / SIZE.Y

	local localX = mouse.X - parentAbsPos.X
	local localY = mouse.Y - parentAbsPos.Y

	local maxCellX = SIZE.X - PixelSize/2
	local maxCellY = SIZE.Y - PixelSize/2

	local cellX = math.clamp(math.floor(localX / cellWidth), 0, maxCellX)
	local cellY = math.clamp(math.floor(localY / cellHeight), 0, maxCellY)

	local cornerX = (cellX * cellWidth)
	local cornerY = (cellY * cellHeight)

	local finalX = cornerX / parentAbsSize.X
	local finalY = cornerY / parentAbsSize.Y

	if PixelSize % 2 == 1 then
		finalX += (cellWidth / 2) / parentAbsSize.X
		finalY += (cellHeight / 2) / parentAbsSize.Y
	end
	
	local pixelWidthNormalized = (PixelSize * cellWidth) / parentAbsSize.X
	local pixelHeightNormalized = (PixelSize * cellHeight) / parentAbsSize.Y

	local halfPixelWidth = pixelWidthNormalized / 2
	local halfPixelHeight = pixelHeightNormalized / 2

	finalX = math.clamp(finalX, halfPixelWidth, 1 - halfPixelWidth)
	finalY = math.clamp(finalY, halfPixelHeight, 1 - halfPixelHeight)

	point.Position = UDim2.new(finalX, 0, finalY, 0)
	local px = finalX * parentAbsSize.X
	local py = finalY * parentAbsSize.Y

	local correctedCellX = math.floor(px / cellWidth)
	local correctedCellY = math.floor(py / cellHeight)

	PixelPosition = Vector2.new(correctedCellX, correctedCellY)
end)

script.Event.Event:Connect(function(str,can)
	LastType = types
	types = str
	model.Frame.Tool.Value = str
	if types == "Pen" or types == "Era" then
		if LastType == "Han" or LastType == "Sel"  then
			selectArea(selects.AbsolutePosition, true,false) 
			PixelSize = anteriorSize
		elseif LastType == "Pic" or LastType == "Paint" then
			PixelSize = anteriorSize
		end
		selects.Visible = false
		local sizeX = PixelSize / SIZE.X
		local sizeY = PixelSize / SIZE.Y
		point.Size = UDim2.fromScale(sizeX,sizeY)
	elseif types == "Han" or types == "Sel" then
		if selects.ImageContent.Object then
			selects.Visible = true
		else
			selects.Visible = false
		end
		anteriorSize = PixelSize
		PixelSize = 1
		local sizeX = PixelSize / SIZE.X
		local sizeY = PixelSize / SIZE.Y
		point.Size = UDim2.fromScale(sizeX,sizeY)
		if can then
			selectArea(selects.AbsolutePosition, true,false) 
		end
	elseif types == "Paint" then
		if LastType == "Han" or LastType == "Sel"  then
			selectArea(selects.AbsolutePosition, true,false) 
		end
		anteriorSize = PixelSize
		PixelSize = 1
		local sizeX = PixelSize / SIZE.X
		local sizeY = PixelSize / SIZE.Y
		point.Size = UDim2.fromScale(sizeX,sizeY)
	elseif types == "Pic" then
		if LastType == "Han" or LastType == "Sel" then
			selectArea(selects.AbsolutePosition, true,false) 
		end
		ColorPick = nil
		selects.Visible = false
		anteriorSize = PixelSize
		PixelSize = 1
		local sizeX = PixelSize / SIZE.X
		local sizeY = PixelSize / SIZE.Y
		point.Size = UDim2.fromScale(sizeX,sizeY)
	else
		selectArea(selects.AbsolutePosition, true,false)
		selects.Visible = false
	end
	if LastType == "Pic" then
		if not ColorPick then return end
		local r,g,b = ColorPick.R*255,ColorPick.G*255,ColorPick.B*255
		ColorPick = nil
	end
end)


local pixelColor = Color3.new(0, 0, 0)
local BrigthNess = 1
local alpha = 0

model.Frame.Onion:GetAttributeChangedSignal("On"):Connect(function()
	if model.Frame.Onion:GetAttribute("On") == true then
		model.Frame.Onion.BackgroundColor3 = Theme.ButtonUIHover
		model.Frame.Editor.Paper.Visible = not model.Frame.IsPlaying.Value
	else
		model.Frame.Onion.BackgroundColor3 = Theme.ButtonUI
		model.Frame.Editor.Paper.Visible = false
	end
end)
model.Frame.IsPlaying.Changed:Connect(function(VIsible)
	if VIsible == true then
		model.Frame.Editor.Paper.Visible = false
	else
		model.Frame.Editor.Paper.Visible = model.Frame.Onion:GetAttribute("On")
	end
end)
model.Frame.Onion.MouseButton1Click:Connect(function()
	model.Frame.Onion:SetAttribute("On",not model.Frame.Onion:GetAttribute("On"))
end)

local runmouse

local lastPosition = nil

local drawing = nil

local parentFrame = model.Frame.Editor.ImageLabel

function clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

function GetFramePosition(Frame:Frame)
	local AbsolutePos = parentFrame.Parent.AbsolutePosition - (parentFrame.Parent.AbsoluteSize / 2)

	local ObjFrame = nil
	local closestDistance = math.huge
	
	for _, child in pairs(Frame:GetChildren()) do
		if child:IsA("Frame") then
			local childPos = child.AbsolutePosition
			local distance = (AbsolutePos - childPos).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				ObjFrame = child
			end
			child.BackgroundColor3 = Color3.new(1, 1, 1)
		end
	end

	ObjFrame.BackgroundColor3 = Color3.new(1, 0, 0)

	local closestFramePos = ObjFrame.AbsolutePosition - parentFrame.Parent.AbsolutePosition + (parentFrame.Parent.AbsoluteSize / 2)
	local relativePos = (closestFramePos / parentFrame.Parent.AbsoluteSize)-Vector2.new(.5,.5)
	relativePos = Vector2.new(math.clamp(relativePos.X,0,1),math.clamp(relativePos.Y,0,1))
	
	return relativePos
end

local anterior = model.Enabled

dockWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not dockWidget.Enabled then
		anterior = model.Enabled
		for i,a in pairs(CollectionService:GetTagged("EDITABLECOLLISIONMAPDELETE")) do
			a.Enabled = false
		end
		model.Enabled = false
	else
		model.Enabled = anterior
	end
end)

function createPos(pos,size)
	if size.X<0 then 
		local newSize = math.abs(size.X)
		pos = Vector2.new(pos.X-newSize,pos.Y)
	end
	if size.Y<0 then
		local newSize = math.abs(size.Y)
		pos = Vector2.new(pos.X,pos.Y-newSize)
	end
	return pos
end

local epsilon = 1e-9
local function safeRound(num)
	return math.floor(num + epsilon + 0.5)
end

local function normalizePixelRectClipping(posPx, sizePx, imageSizePx)
	posPx = Vector2.new(safeRound(posPx.X), safeRound(posPx.Y))
	sizePx = Vector2.new(safeRound(sizePx.X), safeRound(sizePx.Y))

	local originalPos = posPx

	if posPx.X < 0 then
		sizePx = Vector2.new(sizePx.X + posPx.X, sizePx.Y)
	end
	if posPx.Y < 0 then
		sizePx = Vector2.new(sizePx.X, sizePx.Y + posPx.Y)
	end

	if posPx.X + sizePx.X > imageSizePx.X then
		sizePx = Vector2.new(imageSizePx.X - posPx.X, sizePx.Y)
	end
	if posPx.Y + sizePx.Y > imageSizePx.Y then
		sizePx = Vector2.new(sizePx.X, imageSizePx.Y - posPx.Y)
	end

	if sizePx.X <= 0 then sizePx = Vector2.new(1, sizePx.Y) end
	if sizePx.Y <= 0 then sizePx = Vector2.new(sizePx.X, 1) end

	return posPx, sizePx
end

function UpdateSizeAreaToCut(newSize: Vector2, oldSize: Vector2)
	if not selects.Visible then return end

	local currentScalePos = Vector2.new(selects.Position.X.Scale, selects.Position.Y.Scale)
	local currentScaleSize = Vector2.new(selects.Size.X.Scale, selects.Size.Y.Scale)

	local pixelPos = Vector2.new(
		math.round(currentScalePos.X * oldSize.X),
		math.round(currentScalePos.Y * oldSize.Y)
	)
	local pixelSize = Vector2.new(
		math.round(currentScaleSize.X * oldSize.X),
		math.round(currentScaleSize.Y * oldSize.Y)
	)

	local newScalePos = pixelPos / newSize
	local newScaleSize = pixelSize / newSize

	selects.Position = UDim2.new(newScalePos.X, 0, newScalePos.Y, 0)
	selects.Size = UDim2.new(newScaleSize.X, 0, newScaleSize.Y, 0)
end

function CreateAreaToCut(posPx, newsizePx)
	posPx, newsizePx = normalizePixelRectClipping(posPx, newsizePx, SIZE)

	local createSize = Vector2.new(
		math.max(1, newsizePx.X),
		math.max(1, newsizePx.Y)
	)

	local SelectEditor = AssetService:CreateEditableImage({ Size = createSize })
	local imageC = selects.ImageContent.Object 
	if imageC then
		imageC:Destroy()
	end

	SelectEditor:DrawImageTransformed(
		Vector2.zero,
		Vector2.one,
		0,
		EditableImage,
		{
			PivotPoint = posPx,
			SamplingMode = Enum.ResamplerMode.Pixelated
		}
	)

	selects.ImageContent = Content.fromObject(SelectEditor)

	local NewEraserPixelBuffer = buffer.create(createSize.X * createSize.Y * 4)
	EditableImage:WritePixelsBuffer(posPx, createSize, NewEraserPixelBuffer)
end

local function clampRectangle(position, size, imageSize)
	local x = math.round(position.X)
	local y = math.round(position.Y)
	x = math.clamp(x, 0, imageSize.X - size.X)
	y = math.clamp(y, 0, imageSize.Y - size.Y)
	return Vector2.new(x, y)
end

function drawHardCircle(center, size, color, alpha, combineType)
	local width, height = SIZE.X, SIZE.Y
	if size == 1 then
		local x = math.round(center.X)
		local y = math.round(center.Y)

		if x >= 0 and y >= 0 and x < width and y < height then
			EditableImage:DrawRectangle(
				Vector2.new(x, y),
				Vector2.one,
				color,
				alpha,
				combineType
			)
		end
		return
	end
	if size == 2 then
		local x = math.floor(center.X - 0.5)
		local y = math.floor(center.Y - 0.5)
		local left = math.clamp(x, 0, width - 1)
		local top = math.clamp(y, 0, height - 1)
		local right = math.clamp(x + 1, 0, width - 1)
		local bottom = math.clamp(y + 1, 0, height - 1)

		local drawWidth = right - left + 1
		local drawHeight = bottom - top + 1

		if drawWidth > 0 and drawHeight > 0 then
			EditableImage:DrawRectangle(
				Vector2.new(left, top), 
				Vector2.new(drawWidth, drawHeight),
				color,
				alpha,
				combineType
			)
		end
		return
	end
	
	local effectiveSize = size
	
	if size % 2 == 0 then
		effectiveSize = size - 1
	end
	
	local radius = (effectiveSize - 1) / 2
	local cx = math.round(center.X)
	local cy = math.round(center.Y)
	local r2 = (radius + 0.25) * (radius + 0.25)
	for y = -math.round(radius), math.round(radius) do
		local py = cy + y
		if py >= 0 and py < height then
			local xSpan = math.floor(math.sqrt(math.max(0, r2 - (y * y))))
			local x1 = cx - xSpan
			local x2 = cx + xSpan
			local left = math.max(0, x1)
			local right = math.min(width - 1, x2)
			local rowWidth = (right - left) + 1
			if rowWidth > 0 then
				EditableImage:DrawRectangle(
					Vector2.new(left, py),
					Vector2.new(rowWidth, 1),
					color,
					alpha,
					combineType
				)
			end
		end
	end
end

local function clampCircleCenter(position, radius, imageSize)
	local x = math.clamp(position.X, radius, imageSize.X - radius)
	local y = math.clamp(position.Y, radius, imageSize.Y - radius)
	return Vector2.new(x, y)
end

function drawLines(globalPosition, tipe)
	local currentPosition = PixelPosition
	if lastPosition then
		local distance = (currentPosition - lastPosition).Magnitude
		local steps = math.ceil(distance)
		for i = 0, steps do
			local t = i / steps
			local position = lastPosition:Lerp(currentPosition, t)

			if isValidPosition(position, SIZE) then
				if tipe == "Pen" or tipe == "Era" then
					local imgSize = SIZE
					if FramePixel:GetAttribute("Type") then	
						drawHardCircle(
							position, 
							PixelSize, 
							pixelColor, 
							(tipe == "Pen" and alpha) or 1, 
							(tipe == "Pen" and Enum.ImageCombineType.BlendSourceOver) or Enum.ImageCombineType.Overwrite
						)
					else
						local offset = Vector2.new(math.floor(pointSize.X / 2), math.floor(pointSize.Y / 2))
						local pos = clampRectangle(position - offset, pointSize, imgSize)
						EditableImage:DrawRectangle(
							pos, 
							pointSize, 
							pixelColor, 
							(tipe == "Pen" and alpha) or 1, 
							(tipe == "Pen" and Enum.ImageCombineType.BlendSourceOver) or Enum.ImageCombineType.Overwrite
						)
					end
				end
			end
		end
	else
		if isValidPosition(currentPosition, SIZE) then
			local size = pointSize
			local imgSize = SIZE
			if tipe == "Pen" or tipe == "Era" then
				if FramePixel:GetAttribute("Type") then	
					local pos = clampCircleCenter(currentPosition, PixelSize/2, imgSize)
					local finalPos = pos
					drawHardCircle(
						currentPosition, 
						PixelSize, 
						pixelColor, 
						(tipe == "Pen" and alpha) or 1, 
						(tipe == "Pen" and Enum.ImageCombineType.BlendSourceOver) or Enum.ImageCombineType.Overwrite
					)
				else
					local offset = Vector2.new(math.floor(pointSize.X / 2), math.floor(pointSize.Y / 2))
					local pos = clampRectangle(currentPosition - offset, pointSize, imgSize)
					EditableImage:DrawRectangle(
						pos, 
						pointSize, 
						pixelColor, 
						(tipe == "Pen" and alpha) or 1, 
						(tipe == "Pen" and Enum.ImageCombineType.BlendSourceOver) or Enum.ImageCombineType.Overwrite
					)
				end
			end
		end
	end
	lastPosition = currentPosition
end

local dragging, dragStart, frameStartPos, oldInput

selects.InputBegan:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and types == "Han" then
		oldInput = input
		dragStart = inputService:GetMouseLocation()
		frameStartPos = selects.Position
		dragging = true
	end
end)

inputService.InputChanged:Connect(function(input: InputObject)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
	if dragging and types == "Han" then
		local mousePos = inputService:GetMouseLocation()
		local delta = mousePos - dragStart
		local parentSize = parentFrame.AbsoluteSize
		local deltaScale = Vector2.new(delta.X / parentSize.X, delta.Y / parentSize.Y)

		local rawX = frameStartPos.X.Scale + deltaScale.X
		local rawY = frameStartPos.Y.Scale + deltaScale.Y

		local stepX = 1 / SIZE.X
		local stepY = 1 / SIZE.Y

		local snappedX = math.floor(rawX / stepX + 0.5) * stepX
		local snappedY = math.floor(rawY / stepY + 0.5) * stepY

		local newPos = UDim2.new(
			snappedX,
			0,
			snappedY,
			0
		)
		selects.Position = newPos
	end
end)


inputService.InputEnded:Connect(function(input: InputObject)
	if input == oldInput then
		dragging = false
		oldInput = nil
		frameStartPos = nil
	end
end)
function isValidPosition(position, SIZE)
	return position.X >= 0 and position.Y >= 0 and position.X < SIZE.X and position.Y < SIZE.Y
end

local function topLeftAndSize(gui)
	local pos = Vector2.new(gui.Position.X.Scale, gui.Position.Y.Scale)
	local size = Vector2.new(gui.Size.X.Scale, gui.Size.Y.Scale)
	local anchor = gui.AnchorPoint
	return pos - Vector2.new(anchor.X * size.X, anchor.Y * size.Y), size
end

local runselect

function PasteSelection()
	local srcImage = selects.ImageContent.Object
	if not srcImage then return end

	local rawPosPx = Vector2.new(selects.Position.X.Scale * SIZE.X, selects.Position.Y.Scale * SIZE.Y)
	local sizePx = Vector2.new(selects.Size.X.Scale * SIZE.X, selects.Size.Y.Scale * SIZE.Y)

	local posPx, sizePxClipped = normalizePixelRectClipping(rawPosPx, sizePx, SIZE)

	local destPos = Vector2.new(
		math.max(posPx.X, 0),
		math.max(posPx.Y, 0)
	)

	local pivotX = 0
	local pivotY = 0

	if rawPosPx.X < 0 then
		pivotX = -rawPosPx.X
	end
	if rawPosPx.Y < 0 then
		pivotY = -rawPosPx.Y
	end

	EditableImage:DrawImageTransformed(
		destPos,
		Vector2.new(1, 1),
		0,
		srcImage,
		{ PivotPoint = Vector2.new(pivotX, pivotY) }
	)
end

function selectArea(positions:Vector2, val:boolean,ExtraBoolean)
	local posit = Vector2.new(point.Position.X.Scale,point.Position.Y.Scale)
	if runselect then
		runselect:Disconnect()
	end
	local startTopLeft, startSize = topLeftAndSize(point)
	if val then
		local selecimage = selects.ImageContent.Object
		if selecimage then
			PasteSelection()
			selecimage:Destroy()
			selects.ImageContent = Content.none
			local NewBuffer = EditableImage:ReadPixelsBuffer(Vector2.zero,SIZE)
			if buffer.tostring(AnteriorBuffer) ~= buffer.tostring(NewBuffer) then
				AnteriorBuffer = NewBuffer
				model.Frame.NewChange:Fire()
			end
		end
		if ExtraBoolean then 
			selects.Visible = true
			selects.Position = UDim2.new(startTopLeft.X, 0, startTopLeft.Y, 0)
			selects.Size = UDim2.new(startSize.X, 0, startSize.Y, 0)

			runselect = run.RenderStepped:Connect(function()
				local currentTopLeft, currentSize = topLeftAndSize(point)

				local startBottomRight = startTopLeft + startSize
				local currentBottomRight = currentTopLeft + currentSize

				local rectTL = Vector2.new(
					math.min(startTopLeft.X, currentTopLeft.X),
					math.min(startTopLeft.Y, currentTopLeft.Y)
				)
				local rectBR = Vector2.new(
					math.max(startBottomRight.X, currentBottomRight.X),
					math.max(startBottomRight.Y, currentBottomRight.Y)
				)

				local size = rectBR - rectTL
				
				selects.Position = UDim2.new(rectTL.X, 0, rectTL.Y, 0)
				selects.Size = UDim2.new(size.X, 0, size.Y, 0)
			end)
		end
	else
		AnteriorBuffer = EditableImage:ReadPixelsBuffer(Vector2.zero,SIZE)
		CreateAreaToCut(Vector2.new(selects.Position.X.Scale,selects.Position.Y.Scale)*SIZE,Vector2.new(selects.Size.X.Scale,selects.Size.Y.Scale)*SIZE)
	end
end

local runPos
local InputId

function paintFill(startPosition)
	local pos = PixelPosition
	local Newcolor = buffer.fromstring(string.pack("BBBB", pixelColor.R * 255, pixelColor.G * 255, pixelColor.B * 255, (1 - alpha) * 255))
	local tolerance = model.Frame.ToolEditors.Paint.Tolerance.Value/100
	Paint.paint(EditableImage, pos, Newcolor,model,SIZE,tolerance)
end

local can = true

model.Frame.Editor.MouseEnter:Connect(function()
	can = false
end)

model.Frame.Editor.MouseLeave:Connect(function()
	can = true
end)

function createAnimation()
	local Frames = {} 
	local buttonsindex = {}
	model.Frame.IsPlaying.Value = true
	local Size = SIZE
	for i, images in pairs(model.Frame.SavedSprites:GetChildren()) do
		if images:IsA("ImageButton") then
			table.insert(buttonsindex,images)
		end
	end
	table.sort(buttonsindex,function(a,b)
		return a:GetAttribute("Num")<b:GetAttribute("Num")
	end)
	
	for i,a in pairs(buttonsindex) do
		Frames[i]=a.ImageContent.Object:ReadPixelsBuffer(Vector2.zero, SIZE)
	end
	
	local Max = #Frames
	local actual = 1
	local rateDelta = 1/FrameFps
	local runing
	local deltaTime = 0
	if Max>0 then
		runing = run.RenderStepped:Connect(function(deltatime)
			rateDelta = 1/FrameFps
			if not editor then
				local can = pcall(function()
					EditableImage:WritePixelsBuffer(Vector2.zero, Size, Frames[actual])
				end)
				if not can then
					runing:Disconnect()
					model.Frame.Play:SetAttribute("On",false)
					model.Frame.IsPlaying.Value = false
				end
				deltaTime +=deltatime
				if deltaTime >= rateDelta then
					deltaTime = 0
					actual+=1
					if actual > Max then
						actual = 1
						if not Loop then
							runing:Disconnect()
							model.Frame.Play:SetAttribute("On",false)
							model.Frame.IsPlaying.Value = false
						end
					end
				end
			else
				runing:Disconnect()
				model.Frame.Play:SetAttribute("On",false)
				model.Frame.IsPlaying.Value = false
			end
		end)
	else
		model.Frame.Play:SetAttribute("On",true)
		model.Frame.IsPlaying.Value = false
	end
end

local LastInput = nil
point.Parent.InputBegan:Connect(function(input)
	if editor == true then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			LastInput = input
			if types == "Pen" or types == "Era" then
				runmouse = run.RenderStepped:Connect(function()
					drawLines(point.AbsolutePosition, types)
					drawing = true
				end)
			elseif types == "Sel" then
				selectArea(point.AbsolutePosition, true,true)	
			elseif types == "Paint" then
				paintFill(Vector2.new(point.Position.X.Scale,point.Position.Y.Scale))
			end
		end
	end
end)
point.Parent.Parent.InputBegan:Connect(function(click)
	
	if click.UserInputType == Enum.UserInputType.MouseButton1 then
		
		if types == "Pic" then
			local pixelClick = Vector2.new(click.Position.X,click.Position.Y)
			local pos = point.Parent.Parent.AbsolutePosition
			local size = point.Parent.Parent.AbsoluteSize
		
			if pixelClick.X >= pos.X and pixelClick.X <= pos.X + size.X
				and pixelClick.Y >= pos.Y and pixelClick.Y <= pos.Y + size.Y then
				local COLOR = EditableImage:ReadPixelsBuffer(PixelPosition,Vector2.one)
				local R,G,B,A = buffer.readu8(COLOR,0),buffer.readu8(COLOR,1),buffer.readu8(COLOR,2),buffer.readu8(COLOR,3)
				local color = Color3.fromRGB(R,G,B)
				local myalpha = 100-((A/255)*100)
				model.Frame.Alpha.Alpha.Value = math.round(myalpha)
				local zeroToOneColor = Color3.new(R/255,G/255,B/255)
				local pos,brillonew = n.GetVector2FromColor(color)
				local H, S, V = color:ToHSV()
				model.Frame.Brightness.RGB.Value = Color3.fromHSV(H, S, 1)
				model.Frame.Brightness.Brillo.Value = math.round(brillonew*100)
				model.Frame.Brightness.Pallet.Frame.Position = UDim2.fromScale(pos.X,pos.Y)
			end
		end
	end
end)
inputService.InputEnded:Connect(function(input, val)
	if LastInput == input then
		if runmouse then
			runmouse:Disconnect()
			if drawing then
				lastPosition = nil
				model.Frame.NewChange:Fire()
				drawing = false
			end
		end
		if types == "Sel" then 
			wait()
			selectArea(point.AbsolutePosition, false,false)
		end
		LastInput = nil 
	end
end)
local old
model.Frame.Play:GetAttributeChangedSignal("On"):Connect(function()
	if model.Frame.Play:GetAttribute("On") == true then
		editor = false
		for i, button:ImageButton in pairs(model.Frame.SavedSprites:GetChildren()) do
			if button:GetAttribute("On") == true then
				old = button
			end
		end
		if old then
			old:SetAttribute("On", false)
		end
		model.Frame.Play.Image = model.Frame.Play:GetAttribute("Stop")
		model.Frame.Play.BackgroundColor3 = Theme.ButtonUIHover
		local nEd:EditableImage? = selects.ImageContent.Object
		if nEd then
			nEd:Destroy()
			selects.ImageContent = Content.none
		end
		createAnimation()
	else
		editor = true
		model.Frame.Play.Image = model.Frame.Play:GetAttribute("Play")
		model.Frame.Play.BackgroundColor3 = Theme.ButtonUI
		if old and old.Parent then
			save.SetAttribute(old,old.Parent,old.ImageContent.Object.Size,false)
		end
	end
end)

model.Frame.Play.MouseButton1Click:Connect(function()
	model.Frame.Play:SetAttribute("On", not model.Frame.Play:GetAttribute("On"))
end)

model.Frame.Loop:GetAttributeChangedSignal("On"):Connect(function()
	if model.Frame.Loop:GetAttribute("On") == true then
		Loop = true
		model.Frame.Loop.BackgroundColor3 = Theme.ButtonUIHover
	else
		model.Frame.Loop.BackgroundColor3 = Theme.ButtonUI
		Loop = false
	end
end)

model.Frame.Loop.MouseButton1Click:Connect(function()
	model.Frame.Loop:SetAttribute("On", not model.Frame.Loop:GetAttribute("On"))
end)

save.saveSprite(model)
Select1.selec(model)
ReSize.Size(point.Parent,mouse)
REDO_UNDO.Change(model.Frame)

n.CreateImage(model.Frame.Brightness.Pallet)
s.UInput(model.Frame.Brightness.Pallet.Frame)
Copy_Paste.Copy(model)

model.Frame.Alpha.Alpha.Changed:Connect(function(value)
	alpha = value/100
	point.BackgroundTransparency = alpha
end)

model.Frame.Brightness.RGB.Changed:Connect(function(value)
	pixelColor = Color3.new(value.R*(model.Frame.Brightness.Brillo.Value/100),value.G*(model.Frame.Brightness.Brillo.Value/100),value.B*(model.Frame.Brightness.Brillo.Value/100))
	point.BackgroundColor3 = pixelColor
	model.Frame.Brightness.Handle.UIGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(1,value)
	}
end)
local Ns = require(script.ChangeType)
Ns.ChangeType(FramePixel,point,textEdit)

model.Frame.Brightness.Brillo.Changed:Connect(function(value)
	pixelColor = Color3.new(model.Frame.Brightness.RGB.Value.R*(value/100),model.Frame.Brightness.RGB.Value.G*(value/100),model.Frame.Brightness.RGB.Value.B*(value/100))
	point.BackgroundColor3 = pixelColor
end)

model.Frame.Scale.Size.Changed:Connect(function(value)
	anteriorSize = math.max(value,1)	
	local sizeX = anteriorSize / SIZE.X
	local sizeY = anteriorSize / SIZE.Y
	if types == "Pen" or types == "Era" then
		PixelSize = anteriorSize
		point.Size = UDim2.new(sizeX, 0, sizeY, 0)
	else
		point.Size = UDim2.new(1/SIZE.X, 0, 1/SIZE.Y, 0)
	end
	changeSize(value)	
end)

script.UpdateFrame.Event:Connect(function()
	local nEd = selects.ImageContent.Object
	if nEd then
		nEd:Destroy()
		selects.ImageContent = Content.none
		selects.Visible = false
	end
end)

for i,a in pairs(model.Insert:QueryDescendants("TextBox")) do
	if a:HasTag("HasTextBox") then
		local newTxt = NumericalTxT.new(a,{MinNumber = a:GetAttribute("Min"),MaxNumber = a:GetAttribute("Max")})
		newTxt:_init()
	end
end

plugin.Deactivation:Connect(function()
	for i,a in pairs(CollectionService:GetTagged("EDITABLECOLLISIONMAPDELETE")) do
		a:Destroy()
	end
	for i,a in pairs(AllEditables) do
		a:Destroy()
	end
	runfps:Disconnect()
end)

plugin.Unloading:Connect(function()
	for i,a in pairs(CollectionService:GetTagged("EDITABLECOLLISIONMAPDELETE")) do
		a:Destroy()
	end
	for i,a in pairs(AllEditables) do
		a:Destroy()
	end
	runfps:Disconnect()
end)

local ChacheChilds = CollectionService:GetTagged("SpritelyObject")

for i, e in pairs(SpriteFolder:GetChildren()) do
	if e:IsA("Folder") then
		CreateSprite(e.Name,e,e:GetAttribute("Size"))
	end
end

for i, a in pairs(ChacheChilds) do
	if a:IsA("ImageLabel") or a:IsA("ImageButton") then
		local FindForder = SpriteFolder:FindFirstChild(a:GetAttribute("ImageFolder"))
		if FindForder and FindForder:GetAttribute("Size") then
			CreateImageSprite(a,FindForder:GetAttribute("Size"),FindForder)
		end	
	end
end
task.spawn(function()
	local loading = require(script:WaitForChild("LoadingEffect"))
	loading.Play(Insert.Loading.ImageLabel)
end)
