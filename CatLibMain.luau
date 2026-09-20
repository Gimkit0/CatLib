local CatLib = {}

-- UNC Functions
local gethui = get_hui or gethui
local getgenv = getgenv or function() return _G end
local rbxnumber = function(num) return `rbxassetid://{num}` end

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HapticsService = game:GetService("HapticService")
local Players = game:GetService("Players")
local CoreGui = RunService:IsStudio() and Players.LocalPlayer:WaitForChild("PlayerGui") or gethui and gethui() or game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

getgenv()._existingCatLibWindows = {}

-- Other functions
local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end
local function validateConfig(defaults, options)
	defaults = defaults or {}
	options = options or {}
	for option, value in next, options do
		defaults[option] = value
	end
	return defaults
end
local function tween(obj, info, goal)
	local tween = TweenService:Create(obj, info, goal)
	tween:Play()
	return tween
end
local function onHover(obj, enter, leave)
	obj.MouseEnter:Connect(enter)
	obj.MouseLeave:Connect(leave)
end
local function onClick(obj, func)
	obj.Activated:Connect(func)
end

-- Modules
local function BulkFadeModule()
	--[[
	/ Bulk Fade / 
	
	About: 
		This module was created to make bulk tweening much easier.
		Bulk tweening is when you tween all the elements together for a better transition.

	Version:
		- 1.6
		- 9/11/2022

	Author(s):
		kingerman88
		xxkeithx
]]

	-- / Types / --
	type ArrayList<T> = {[number]:T};
	type IndexArray<I,V> = {[I]:V};

	-- / Services / --
	local TweenService = game:GetService("TweenService");

	-- / Variables / --
	local DefaultTweenConfiguration = TweenInfo.new(1, Enum.EasingStyle.Cubic)

	-- Class Definitions
	local ImageElements = {
		["ImageButton"] = true,
		["ImageLabel"] = true,
	}
	local TextElements = {
		["TextLabel"] = true,
		["TextButton"] = true,
		["TextBox"] = true,
	}
	local ScrollingElements = {
		["ScrollingFrame"] = true
	}

	-- / Functions / --
	local function getAttributesAtValue(attributes: IndexArray<string, number>, val)
		local temp = {};
		for i in pairs(attributes) do
			temp[i] = val;
		end
		return temp;
	end

	local function addElement(self, element: Instance, tweenConfig: TweenInfo|nil)

		local attributes = {};

		-- Specialized UI stroke elements
		if element:IsA("UIStroke") then
			attributes["Transparency"] = element.Transparency;
			table.insert(self.UiElements, element);
			self.AppearTweens[element] = TweenService:Create(element, tweenConfig or DefaultTweenConfiguration, attributes);
			self.DisappearTweens[element] = TweenService:Create(element, tweenConfig or DefaultTweenConfiguration, {Transparency = 1});
			return;
		elseif not element:IsA("GuiObject") then
			return;
		end

		attributes["BackgroundTransparency"] = element.BackgroundTransparency;
		if ImageElements[element.ClassName] then
			attributes["ImageTransparency"] = element.ImageTransparency;
		end if TextElements[element.ClassName] then
			attributes["TextTransparency"] = element.TextTransparency;
			attributes["TextStrokeTransparency"] = element.TextStrokeTransparency;
		end if ScrollingElements[element.ClassName] then
			attributes["ScrollBarImageTransparency"] = element.ScrollBarImageTransparency;
		end
		table.insert(self.UiElements, element);
		self.AppearTweens[element] = TweenService:Create(element, tweenConfig or DefaultTweenConfiguration, attributes);
		self.DisappearTweens[element] = TweenService:Create(element, tweenConfig or DefaultTweenConfiguration, getAttributesAtValue(attributes, 1));
	end

	local function removeElement(self, element)
		table.remove(self.UiElements, element);
		self.AppearTweens[element] = nil;
		self.DisappearTweens[element] = nil;
	end

	-- / BulkFade.lua / --
	local BulkFade = {}
	BulkFade.__index = BulkFade;

	BulkFade.TweenIn = BulkFade.FadeIn;
	BulkFade.TweenOut = BulkFade.FadeOut;

	-- Creates a new tween group
	-- @param elements:ArrayList<Instance> - An arraylist of instances (not nessesarily UI objects)
	-- @param tweenConfig:TweenInfo:optional - a custom tweenInfo that will override the default tweenInfoConfig
	-- @return BulkFadeGroup
	function BulkFade.CreateGroup(elements:ArrayList<Instance>, tweenConfig:TweenInfo?)
		local self = {};
		self.Faded = false;
		self.UiElements = {};
		self.AppearTweens = {};
		self.DisappearTweens = {};

		for _, element in ipairs(elements) do
			addElement(self, element, tweenConfig);
		end

		return setmetatable(self, BulkFade);
	end

	-- Calls all the tweens (in)
	function BulkFade:FadeIn()
		self.Faded = true;
		for element, tween in pairs(self.AppearTweens) do
			tween:Play();
		end
	end

	-- Calls all the tweens (out)
	function BulkFade:FadeOut()
		self.Faded = false;
		for element, tween in pairs(self.DisappearTweens) do
			tween:Play();
		end
	end

	function BulkFade:Fade()
		if self.Faded then
			self:FadeOut();
		else
			self:FadeIn();
		end
	end

	-- Simply returns all the elements in the tweengroup
	-- @return ArrayList<GuiObject> - A table of UI elements
	function BulkFade:GetElements()
		return self.UiElements;
	end

	return BulkFade
end
local function PickerModule(parentFrame)
	--[[

Basic Color Picker
Author: @Viperdune

Intended to be embedded and edited into any UI without complications

Requirements to function:
	ModuleScript is siblings with other elements such as color picker and slider
	
	Image/container titled 'Picker'
		Contains child button titled 'Button' (Z-Index above other elements)
		Contains child titled 'Selection'

	Container titled 'Slider'
		Contains child button titled 'Button'
		Contains child titled 'Selection'
		Contains UIGradient titled 'Gradient'

Optional:
	Frame titled 'ColorPreview'

----------------------------------------------------------------------------

Basic functionality:

local PickerModule = require(...)
PickerModule.Init()
PickerModule.SetColor(Color3.fromHSV(...))

PickerModule.ColorChanged:Connect(function(color: Color3)
	...
end)

--]]

	local UserInputService = game:GetService("UserInputService")
	local GuiService = game:GetService("GuiService")

	-- Mouse/Input Movement
	local MouseMovement = {}
	MouseMovement.__index = MouseMovement

	function MouseMovement.new(callback)
		local self = setmetatable({},MouseMovement)
		self.CallbackFunc = callback
		self.Connected = false

		return self
	end

	function MouseMovement:Connect(...)
		if self.Connected then return end
		self.Connected = true

		local args = {...}
		self.CallbackFunc(...)

		self._mouseMovement = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				self.CallbackFunc(table.unpack(args))
			end
		end)

		self._mouseUp = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if self.DisconnectCallback then
					self.DisconnectCallback()
				end

				self:Disconnect()
			end
		end)
	end

	function MouseMovement:Disconnect()
		self.Connected = false
		if self._mouseMovement then
			self._mouseMovement:Disconnect()
			self._mouseMovement = nil
		end

		if self._mouseUp then
			self._mouseUp:Disconnect()
			self._mouseUp = nil
		end
	end

	function MouseMovement:OnDisconnect(func)
		self.DisconnectCallback = func
	end

	function MouseMovement:Destroy()
		self:Disconnect()
		self = nil
	end

	-- Picker Module
	local PickerModule: PickerModule = {}

	local pickerContainer = parentFrame:WaitForChild("Picker")
	local pickerButton = pickerContainer:WaitForChild("Button")
	local pickerSelection = pickerContainer:WaitForChild("Selection")

	local sliderContainer = parentFrame:WaitForChild("Slider")
	local sliderButton = sliderContainer:WaitForChild("Button")
	local sliderSelection = sliderContainer:WaitForChild("Selection")
	local sliderGradient = sliderContainer:WaitForChild("Gradient")

	local colorChangedEvent = Instance.new("BindableEvent")
	PickerModule.ColorChanged = colorChangedEvent.Event

	local currentColor = {
		Hue = 0,
		Saturation = 0,
		Value = 0
	}

	local function getMousePos()
		local topbarHeight = GuiService.TopbarInset.Height
		return UserInputService:GetMouseLocation() - Vector2.new(0, topbarHeight)
	end

	function PickerModule.SetColor(color: Color3)
		PickerModule.SetHSV(color:ToHSV())
	end

	function PickerModule.SetHSV(h: number, s: number, v: number)
		currentColor.Hue = h
		currentColor.Saturation = s
		currentColor.Value = v

		PickerModule._updateVisual()
		colorChangedEvent:Fire(PickerModule.GetColor())
	end

	function PickerModule.SetRGB(r: number, g: number, b: number)
		PickerModule.SetColor(Color3.new(r, g, b))
	end

	function PickerModule.GetColor(): Color3
		return Color3.fromHSV(currentColor.Hue, currentColor.Saturation, currentColor.Value)
	end

	function PickerModule.GetHSV(): (number, number, number)
		return currentColor.Hue, currentColor.Saturation, currentColor.Value
	end

	function PickerModule.GetRGB(): (number, number, number)
		local color = PickerModule.GetColor()
		return color.R, color.G, color.B
	end

	function PickerModule.Init()
		-- Color picker functionality
		local pickerMouseMovement = MouseMovement.new(function()
			local mousePos = Vector2.new(0.5, 0.5) - (getMousePos() - pickerContainer.AbsolutePosition) / pickerContainer.AbsoluteSize

			local phi,len = math.atan2(mousePos.Y, mousePos.X), mousePos.Magnitude
			local h,s = math.clamp((phi + math.pi) / (2 * math.pi), 0, 1), math.clamp(len * 2, 0, 1)

			PickerModule.SetHSV(h,s,currentColor.Value)
		end)

		pickerButton.MouseButton1Down:Connect(function()
			pickerMouseMovement:Connect()
		end)

		-- Slider functionality
		local sliderMouseMovement = MouseMovement.new(function()
			local newValue = math.clamp((getMousePos().X - sliderContainer.AbsolutePosition.X) / sliderContainer.AbsoluteSize.X, 0, 1)
			PickerModule.SetHSV(currentColor.Hue, currentColor.Saturation, newValue)
		end)

		sliderButton.MouseButton1Down:Connect(function()
			sliderMouseMovement:Connect()
		end)
	end

	function PickerModule._updateVisual()
		local colorPreviewFrame = parentFrame:FindFirstChild("ColorPreview")
		if colorPreviewFrame then
			colorPreviewFrame.BackgroundColor3 = PickerModule.GetColor()
		end

		-- Color picker selection
		local h2 = currentColor.Hue * math.pi * 2
		pickerSelection.Position = UDim2.fromScale(
			0.5 + (math.cos(h2) / 2 * currentColor.Saturation),
			0.5 + (math.sin(h2) / 2 * currentColor.Saturation)
		)

		-- Slider selection
		sliderSelection.Position = UDim2.fromScale(currentColor.Value, 0.5)
		sliderGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,0)),
			ColorSequenceKeypoint.new(1,Color3.fromHSV(currentColor.Hue,currentColor.Saturation,1))
		})
	end

	export type PickerModule = {
		Init: () -> (),
		SetColor: (color: Color3) -> (),
		SetHSV: (h: number, s: number, v: number) -> (),
		SetRGB: (r: number, g: number, b: number) -> (),

		GetColor: () -> (Color3),
		GetHSV: () -> (number, number, number),
		GetRGB: () -> (number, number, number),

		ColorChanged: RBXScriptSignal
	}

	return PickerModule
end
local function RippleModule()
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")

	local Ripple = {}
	Ripple.__index = Ripple

	Ripple.DefaultColor = Color3.fromRGB(25, 118, 210)
	Ripple.DefaultTransparency = 0.85
	Ripple.DefaultSpeed = 0.5

	-- Utility
	local function CalculateDistance(pointA, pointB)
		return (pointB - pointA).Magnitude
	end

	local function CreateCircle(color, transparency, zIndex)
		local circle = Instance.new("Frame")
		circle.BackgroundColor3 = color
		circle.BackgroundTransparency = transparency
		circle.AnchorPoint = Vector2.new(0.5, 0.5)
		circle.Size = UDim2.new(0, 0, 0, 0)
		circle.ZIndex = zIndex or 1

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = circle

		return circle
	end

	function Ripple:PopRipple(guiElement, options)
		local player = Players.LocalPlayer
		local mouse = player:GetMouse()

		local color = options and options.Color or self.DefaultColor
		local transparency = options and options.Transparency or self.DefaultTransparency
		local speed = options and options.Speed or self.DefaultSpeed

		local mousePos = Vector2.new(mouse.X, mouse.Y)
		local absPos = guiElement.AbsolutePosition
		local absSize = guiElement.AbsoluteSize
		local relativePos = mousePos - absPos

		local circle = CreateCircle(color, transparency, guiElement.ZIndex + 1)
		circle.Position = UDim2.new(0, relativePos.X, 0, relativePos.Y)
		circle.Parent = guiElement

		local topLeft = CalculateDistance(relativePos, Vector2.new(0, 0))
		local topRight = CalculateDistance(relativePos, Vector2.new(absSize.X, 0))
		local bottomRight = CalculateDistance(relativePos, absSize)
		local bottomLeft = CalculateDistance(relativePos, Vector2.new(0, absSize.Y))
		local maxDist = math.max(topLeft, topRight, bottomRight, bottomLeft) * 2

		local tweenOut = TweenService:Create(circle, TweenInfo.new(speed), {
			Size = UDim2.new(0, maxDist, 0, maxDist)
		})
		local fadeOut = TweenService:Create(circle, TweenInfo.new(speed * 2), {
			BackgroundTransparency = 1,
		})
		tweenOut:Play()
		fadeOut:Play()

		tweenOut.Completed:Connect(function()
			task.wait(speed)
			circle:Destroy()
		end)
	end

	return Ripple
end

local function DragModule()
	--[[
	@Author: Spynaz
	@Description: Enables dragging on GuiObjects. Supports both mouse and touch.
	
	For instructions on how to use this module, go to this link:
	https://devforum.roblox.com/t/simple-module-for-creating-draggable-gui-elements/230678
--]]

	local UDim2_new = UDim2.new

	local UserInputService = game:GetService("UserInputService")

	local DraggableObject 		= {}
	DraggableObject.__index 	= DraggableObject

	-- Sets up a new draggable object
	function DraggableObject.new(Object)
		local self 			= {}
		self.Object			= Object
		self.DragStarted	= nil
		self.DragEnded		= nil
		self.Dragged		= nil
		self.Dragging		= false

		setmetatable(self, DraggableObject)

		return self
	end

	-- Enables dragging
	function DraggableObject:Enable()
		local object			= self.Object
		local dragInput			= nil
		local dragStart			= nil
		local startPos			= nil
		local preparingToDrag	= false

		-- Updates the element
		local function update(input)
			local delta 		= input.Position - dragStart
			local newPosition	= UDim2_new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			object.Position 	= newPosition

			return newPosition
		end

		self.InputBegan = object.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				preparingToDrag = true
			--[[if self.DragStarted then
				self.DragStarted()
			end
			
			dragging	 	= true
			dragStart 		= input.Position
			startPos 		= Element.Position
			--]]

				local connection 
				connection = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End and (self.Dragging or preparingToDrag) then
						self.Dragging = false
						connection:Disconnect()

						if self.DragEnded and not preparingToDrag then
							self.DragEnded()
						end

						preparingToDrag = false
					end
				end)
			end
		end)

		self.InputChanged = object.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		self.InputChanged2 = UserInputService.InputChanged:Connect(function(input)
			if object.Parent == nil then
				self:Disable()
				return
			end

			if preparingToDrag then
				preparingToDrag = false

				if self.DragStarted then
					self.DragStarted()
				end

				self.Dragging	= true
				dragStart 		= input.Position
				startPos 		= object.Position
			end

			if input == dragInput and self.Dragging then
				local newPosition = update(input)

				if self.Dragged then
					self.Dragged(newPosition)
				end
			end
		end)
	end

	-- Disables dragging
	function DraggableObject:Disable()
		self.InputBegan:Disconnect()
		self.InputChanged:Disconnect()
		self.InputChanged2:Disconnect()

		if self.Dragging then
			self.Dragging = false

			if self.DragEnded then
				self.DragEnded()
			end
		end
	end

	return DraggableObject
end

local function createWindow()
	local G2L = {};

	-- StarterGui.ScreenGui
	G2L["1"] = Instance.new("ScreenGui", CoreGui);
	G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;


	-- StarterGui.ScreenGui.Holder
	G2L["2"] = Instance.new("Frame", G2L["1"]);
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["2"]["Size"] = UDim2.new(0, 550, 0, 350);
	G2L["2"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Name"] = [[Holder]];
	G2L["2"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame
	G2L["3"] = Instance.new("Frame", G2L["2"]);
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3"]["Name"] = [[MainFrame]];
	G2L["3"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Top
	G2L["4"] = Instance.new("Frame", G2L["3"]);
	G2L["4"]["ZIndex"] = 100;
	G2L["4"]["BorderSizePixel"] = 0;
	G2L["4"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["4"]["Size"] = UDim2.new(1, 0, 0, 45);
	G2L["4"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["4"]["Name"] = [[Top]];
	G2L["4"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.UpperLine
	G2L["5"] = Instance.new("Frame", G2L["4"]);
	G2L["5"]["BorderSizePixel"] = 0;
	G2L["5"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["5"]["Size"] = UDim2.new(1, 0, 0, 3);
	G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5"]["Name"] = [[UpperLine]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Container
	G2L["6"] = Instance.new("Frame", G2L["4"]);
	G2L["6"]["BorderSizePixel"] = 0;
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["6"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["6"]["Size"] = UDim2.new(1, 0, 1, -3);
	G2L["6"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["6"]["Name"] = [[Container]];
	G2L["6"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Container.Padding
	G2L["7"] = Instance.new("UIPadding", G2L["6"]);
	G2L["7"]["PaddingTop"] = UDim.new(0, 5);
	G2L["7"]["PaddingRight"] = UDim.new(0, 10);
	G2L["7"]["Name"] = [[Padding]];
	G2L["7"]["PaddingLeft"] = UDim.new(0, 10);
	G2L["7"]["PaddingBottom"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Container.WindowIcon
	G2L["8"] = Instance.new("ImageLabel", G2L["6"]);
	G2L["8"]["BorderSizePixel"] = 0;
	G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["8"]["ImageColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["8"]["AnchorPoint"] = Vector2.new(0, 0.5);
	G2L["8"]["Image"] = [[rbxassetid://6523858394]];
	G2L["8"]["Size"] = UDim2.new(0, 25, 0, 25);
	G2L["8"]["Visible"] = false;
	G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["8"]["BackgroundTransparency"] = 1;
	G2L["8"]["Name"] = [[WindowIcon]];
	G2L["8"]["Position"] = UDim2.new(0, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Container.WindowTitle
	G2L["9"] = Instance.new("TextLabel", G2L["6"]);
	G2L["9"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["9"]["BorderSizePixel"] = 0;
	G2L["9"]["TextSize"] = 18;
	G2L["9"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["9"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["9"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["9"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["9"]["BackgroundTransparency"] = 1;
	G2L["9"]["Size"] = UDim2.new(0, 145, 1, 0);
	G2L["9"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["9"]["Text"] = [[Crazen Hub]];
	G2L["9"]["Name"] = [[WindowTitle]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Container.WindowTitle.Padding
	G2L["a"] = Instance.new("UIPadding", G2L["9"]);
	G2L["a"]["Name"] = [[Padding]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Container.WindowVersion
	G2L["b"] = Instance.new("TextLabel", G2L["6"]);
	G2L["b"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["b"]["BorderSizePixel"] = 0;
	G2L["b"]["TextSize"] = 12;
	G2L["b"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["b"]["TextYAlignment"] = Enum.TextYAlignment.Bottom;
	G2L["b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["b"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["b"]["TextColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["b"]["BackgroundTransparency"] = 1;
	G2L["b"]["Size"] = UDim2.new(0, 145, 1, 0);
	G2L["b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["b"]["Text"] = [[V1.0]];
	G2L["b"]["Name"] = [[WindowVersion]];
	G2L["b"]["Position"] = UDim2.new(0, 0, 0, 5);


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Container.WindowVersion.Padding
	G2L["c"] = Instance.new("UIPadding", G2L["b"]);
	G2L["c"]["Name"] = [[Padding]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Buttons
	G2L["d"] = Instance.new("Frame", G2L["4"]);
	G2L["d"]["BorderSizePixel"] = 0;
	G2L["d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["d"]["AnchorPoint"] = Vector2.new(1, 0);
	G2L["d"]["Size"] = UDim2.new(0, 84, 1, 0);
	G2L["d"]["Position"] = UDim2.new(1, 0, 0, 0);
	G2L["d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["d"]["Name"] = [[Buttons]];
	G2L["d"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Buttons.Padding
	G2L["e"] = Instance.new("UIPadding", G2L["d"]);
	G2L["e"]["PaddingTop"] = UDim.new(0, 3);
	G2L["e"]["Name"] = [[Padding]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Buttons.Close
	G2L["f"] = Instance.new("ImageButton", G2L["d"]);
	G2L["f"]["BorderSizePixel"] = 0;
	G2L["f"]["ImageTransparency"] = 1;
	G2L["f"]["BackgroundTransparency"] = 1;
	G2L["f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["f"]["AnchorPoint"] = Vector2.new(1, 0);
	G2L["f"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["f"]["Size"] = UDim2.new(0, 42, 1, 0);
	G2L["f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["f"]["Name"] = [[Close]];
	G2L["f"]["Position"] = UDim2.new(1, 0, 0, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Buttons.Close.Icon
	G2L["10"] = Instance.new("ImageLabel", G2L["f"]);
	G2L["10"]["BorderSizePixel"] = 0;
	G2L["10"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["10"]["ImageColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["10"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["10"]["Image"] = [[rbxassetid://10152135063]];
	G2L["10"]["Size"] = UDim2.new(0, 20, 0, 20);
	G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["10"]["BackgroundTransparency"] = 1;
	G2L["10"]["Name"] = [[Icon]];
	G2L["10"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Buttons.Minimize
	G2L["11"] = Instance.new("ImageButton", G2L["d"]);
	G2L["11"]["BorderSizePixel"] = 0;
	G2L["11"]["ImageTransparency"] = 1;
	G2L["11"]["BackgroundTransparency"] = 1;
	G2L["11"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["11"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["11"]["Size"] = UDim2.new(0, 42, 1, 0);
	G2L["11"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["11"]["Name"] = [[Minimize]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Top.Buttons.Minimize.Icon
	G2L["12"] = Instance.new("ImageLabel", G2L["11"]);
	G2L["12"]["BorderSizePixel"] = 0;
	G2L["12"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["12"]["ImageColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["12"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["12"]["Image"] = [[rbxassetid://17601421663]];
	G2L["12"]["Size"] = UDim2.new(0, 20, 0, 20);
	G2L["12"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["12"]["BackgroundTransparency"] = 1;
	G2L["12"]["Name"] = [[Icon]];
	G2L["12"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation
	G2L["13"] = Instance.new("Frame", G2L["3"]);
	G2L["13"]["ZIndex"] = 5;
	G2L["13"]["BorderSizePixel"] = 0;
	G2L["13"]["BackgroundColor3"] = Color3.fromRGB(31, 33, 49);
	G2L["13"]["Size"] = UDim2.new(0, 150, 1, 0);
	G2L["13"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["13"]["Name"] = [[Navigation]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Shadow
	G2L["14"] = Instance.new("UIShadow", G2L["13"]);
	G2L["14"]["Offset"] = UDim2.new(0, 5, 0, 0);
	G2L["14"]["BlurRadius"] = UDim.new(0, 10);
	G2L["14"]["Spread"] = UDim2.new(0, -5, 0, -10);
	G2L["14"]["Transparency"] = 0.5;
	G2L["14"]["Name"] = [[Shadow]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container
	G2L["15"] = Instance.new("Frame", G2L["13"]);
	G2L["15"]["BorderSizePixel"] = 0;
	G2L["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["15"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["15"]["Size"] = UDim2.new(1, 0, 1, -65);
	G2L["15"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["15"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["15"]["Name"] = [[Container]];
	G2L["15"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo
	G2L["16"] = Instance.new("Frame", G2L["15"]);
	G2L["16"]["BorderSizePixel"] = 0;
	G2L["16"]["BackgroundColor3"] = Color3.fromRGB(12, 11, 14);
	G2L["16"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["16"]["Size"] = UDim2.new(1, 0, 0, 55);
	G2L["16"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["16"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["16"]["Name"] = [[UserInfo]];
	G2L["16"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.UpperLine
	G2L["17"] = Instance.new("Frame", G2L["16"]);
	G2L["17"]["BorderSizePixel"] = 0;
	G2L["17"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["17"]["Size"] = UDim2.new(1, 0, 0, 3);
	G2L["17"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["17"]["Name"] = [[UpperLine]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container
	G2L["18"] = Instance.new("Frame", G2L["16"]);
	G2L["18"]["BorderSizePixel"] = 0;
	G2L["18"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["18"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["18"]["Size"] = UDim2.new(1, 0, 1, -3);
	G2L["18"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["18"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["18"]["Name"] = [[Container]];
	G2L["18"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.Padding
	G2L["19"] = Instance.new("UIPadding", G2L["18"]);
	G2L["19"]["PaddingTop"] = UDim.new(0, 10);
	G2L["19"]["PaddingRight"] = UDim.new(0, 10);
	G2L["19"]["Name"] = [[Padding]];
	G2L["19"]["PaddingLeft"] = UDim.new(0, 10);
	G2L["19"]["PaddingBottom"] = UDim.new(0, 10);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.Profile
	G2L["1a"] = Instance.new("ImageLabel", G2L["18"]);
	G2L["1a"]["BorderSizePixel"] = 0;
	G2L["1a"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["1a"]["AnchorPoint"] = Vector2.new(0, 0.5);
	G2L["1a"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["1a"]["Size"] = UDim2.new(0, 30, 0, 30);
	G2L["1a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1a"]["BackgroundTransparency"] = 0.75;
	G2L["1a"]["Name"] = [[Profile]];
	G2L["1a"]["Position"] = UDim2.new(0, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.Profile.Radius
	G2L["1b"] = Instance.new("UICorner", G2L["1a"]);
	G2L["1b"]["BottomRightRadius"] = UDim.new(1, 0);
	G2L["1b"]["BottomLeftRadius"] = UDim.new(1, 0);
	G2L["1b"]["TopRightRadius"] = UDim.new(1, 0);
	G2L["1b"]["Name"] = [[Radius]];
	G2L["1b"]["TopLeftRadius"] = UDim.new(1, 0);
	G2L["1b"]["CornerRadius"] = UDim.new(1, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.Settings
	G2L["1c"] = Instance.new("ImageButton", G2L["18"]);
	G2L["1c"]["Active"] = false;
	G2L["1c"]["BorderSizePixel"] = 0;
	G2L["1c"]["ImageTransparency"] = 1;
	G2L["1c"]["BackgroundTransparency"] = 0.75;
	G2L["1c"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["1c"]["Selectable"] = false;
	G2L["1c"]["AnchorPoint"] = Vector2.new(1, 0.5);
	G2L["1c"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["1c"]["Size"] = UDim2.new(0, 30, 0, 30);
	G2L["1c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1c"]["Name"] = [[Settings]];
	G2L["1c"]["Position"] = UDim2.new(1, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.Settings.Radius
	G2L["1d"] = Instance.new("UICorner", G2L["1c"]);
	G2L["1d"]["BottomRightRadius"] = UDim.new(1, 0);
	G2L["1d"]["BottomLeftRadius"] = UDim.new(1, 0);
	G2L["1d"]["TopRightRadius"] = UDim.new(1, 0);
	G2L["1d"]["Name"] = [[Radius]];
	G2L["1d"]["TopLeftRadius"] = UDim.new(1, 0);
	G2L["1d"]["CornerRadius"] = UDim.new(1, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.Settings.Icon
	G2L["1e"] = Instance.new("ImageLabel", G2L["1c"]);
	G2L["1e"]["BorderSizePixel"] = 0;
	G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1e"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["1e"]["Image"] = [[rbxassetid://9405931578]];
	G2L["1e"]["Size"] = UDim2.new(0.75, 0, 0.75, 0);
	G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1e"]["BackgroundTransparency"] = 1;
	G2L["1e"]["Name"] = [[Icon]];
	G2L["1e"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.About
	G2L["1f"] = Instance.new("ImageButton", G2L["18"]);
	G2L["1f"]["Active"] = false;
	G2L["1f"]["BorderSizePixel"] = 0;
	G2L["1f"]["ImageTransparency"] = 1;
	G2L["1f"]["BackgroundTransparency"] = 0.75;
	G2L["1f"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["1f"]["Selectable"] = false;
	G2L["1f"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["1f"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["1f"]["Size"] = UDim2.new(0, 30, 0, 30);
	G2L["1f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1f"]["Name"] = [[About]];
	G2L["1f"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.About.Radius
	G2L["20"] = Instance.new("UICorner", G2L["1f"]);
	G2L["20"]["BottomRightRadius"] = UDim.new(1, 0);
	G2L["20"]["BottomLeftRadius"] = UDim.new(1, 0);
	G2L["20"]["TopRightRadius"] = UDim.new(1, 0);
	G2L["20"]["Name"] = [[Radius]];
	G2L["20"]["TopLeftRadius"] = UDim.new(1, 0);
	G2L["20"]["CornerRadius"] = UDim.new(1, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Container.About.Icon
	G2L["21"] = Instance.new("ImageLabel", G2L["1f"]);
	G2L["21"]["BorderSizePixel"] = 0;
	G2L["21"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["21"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["21"]["Image"] = [[rbxassetid://115042623343490]];
	G2L["21"]["Size"] = UDim2.new(0.75, 0, 0.75, 0);
	G2L["21"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["21"]["BackgroundTransparency"] = 1;
	G2L["21"]["Name"] = [[Icon]];
	G2L["21"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Extras
	G2L["22"] = Instance.new("Frame", G2L["16"]);
	G2L["22"]["BorderSizePixel"] = 0;
	G2L["22"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["22"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["22"]["Position"] = UDim2.new(0, 0, 0, -25);
	G2L["22"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["22"]["Name"] = [[Extras]];
	G2L["22"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Extras.Decoration0
	G2L["23"] = Instance.new("ImageLabel", G2L["22"]);
	G2L["23"]["BorderSizePixel"] = 0;
	G2L["23"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["23"]["Image"] = [[rbxassetid://12140499119]];
	G2L["23"]["Size"] = UDim2.new(0, 30, 0, 30);
	G2L["23"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["23"]["BackgroundTransparency"] = 1;
	G2L["23"]["Name"] = [[Decoration0]];
	G2L["23"]["Position"] = UDim2.new(0, 5, 0, 15);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.UserInfo.Extras.Padding
	G2L["24"] = Instance.new("UIPadding", G2L["22"]);
	G2L["24"]["PaddingRight"] = UDim.new(0, 5);
	G2L["24"]["Name"] = [[Padding]];
	G2L["24"]["PaddingLeft"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.Tabs
	G2L["25"] = Instance.new("ScrollingFrame", G2L["15"]);
	G2L["25"]["BorderSizePixel"] = 0;
	G2L["25"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
	G2L["25"]["Name"] = [[Tabs]];
	G2L["25"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["25"]["Selectable"] = false;
	G2L["25"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
	G2L["25"]["ClipsDescendants"] = false;
	G2L["25"]["Size"] = UDim2.new(1, 0, 1, -55);
	G2L["25"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["25"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.Tabs.Content
	G2L["26"] = Instance.new("Frame", G2L["25"]);
	G2L["26"]["BorderSizePixel"] = 0;
	G2L["26"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["26"]["AnchorPoint"] = Vector2.new(0.5, 0);
	G2L["26"]["AutomaticSize"] = Enum.AutomaticSize.Y;
	G2L["26"]["Size"] = UDim2.new(1, -20, 0, 0);
	G2L["26"]["Position"] = UDim2.new(0.5, 0, 0, 0);
	G2L["26"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["26"]["Name"] = [[Content]];
	G2L["26"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.Tabs.Content.List
	G2L["27"] = Instance.new("UIListLayout", G2L["26"]);
	G2L["27"]["Padding"] = UDim.new(0, 10);
	G2L["27"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["27"]["Name"] = [[List]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Navigation.Container.Tabs.Content.Padding
	G2L["28"] = Instance.new("UIPadding", G2L["26"]);
	G2L["28"]["Name"] = [[Padding]];
	G2L["28"]["PaddingBottom"] = UDim.new(0, 30);


	-- StarterGui.ScreenGui.Holder.MainFrame.Background
	G2L["29"] = Instance.new("CanvasGroup", G2L["3"]);
	G2L["29"]["ZIndex"] = -10;
	G2L["29"]["BorderSizePixel"] = 0;
	G2L["29"]["BackgroundColor3"] = Color3.fromRGB(37, 40, 59);
	G2L["29"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["29"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["29"]["Name"] = [[Background]];
	G2L["29"]["BackgroundTransparency"] = 0.05;


	-- StarterGui.ScreenGui.Holder.MainFrame.Background.Shadow
	G2L["2a"] = Instance.new("UIShadow", G2L["29"]);
	G2L["2a"]["Offset"] = UDim2.new(0, 0, 0, 20);
	G2L["2a"]["BlurRadius"] = UDim.new(0, 50);
	G2L["2a"]["Transparency"] = 0.5;
	G2L["2a"]["Name"] = [[Shadow]];


	-- StarterGui.ScreenGui.Holder.MainFrame.Background.Decoration1
	G2L["2b"] = Instance.new("Frame", G2L["29"]);
	G2L["2b"]["BorderSizePixel"] = 0;
	G2L["2b"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["2b"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["2b"]["Size"] = UDim2.new(0, 35, 1, 0);
	G2L["2b"]["Position"] = UDim2.new(1, 0, 1.25, 0);
	G2L["2b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2b"]["Name"] = [[Decoration1]];
	G2L["2b"]["Rotation"] = 45;
	G2L["2b"]["BackgroundTransparency"] = 0.8;


	-- StarterGui.ScreenGui.Holder.MainFrame.Background.Decoration0
	G2L["2c"] = Instance.new("Frame", G2L["29"]);
	G2L["2c"]["BorderSizePixel"] = 0;
	G2L["2c"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["2c"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["2c"]["Size"] = UDim2.new(0, 35, 1, 0);
	G2L["2c"]["Position"] = UDim2.new(1, 0, 1.5, 0);
	G2L["2c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2c"]["Name"] = [[Decoration0]];
	G2L["2c"]["Rotation"] = 45;
	G2L["2c"]["BackgroundTransparency"] = 0.9;


	-- StarterGui.ScreenGui.Holder.MainFrame.Background.Decoration2
	G2L["2d"] = Instance.new("Frame", G2L["29"]);
	G2L["2d"]["BorderSizePixel"] = 0;
	G2L["2d"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["2d"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["2d"]["Size"] = UDim2.new(0, 35, 1, 0);
	G2L["2d"]["Position"] = UDim2.new(0.85, 0, 1.25, 0);
	G2L["2d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2d"]["Name"] = [[Decoration2]];
	G2L["2d"]["Rotation"] = 45;
	G2L["2d"]["BackgroundTransparency"] = 0.9;


	-- StarterGui.ScreenGui.Holder.MainFrame.Background.ImageBackground
	G2L["2e"] = Instance.new("ImageLabel", G2L["29"]);
	G2L["2e"]["BorderSizePixel"] = 0;
	G2L["2e"]["ScaleType"] = Enum.ScaleType.Fit;
	G2L["2e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2e"]["ImageTransparency"] = 0.9;
	G2L["2e"]["AnchorPoint"] = Vector2.new(0, 0.5);
	G2L["2e"]["Image"] = [[rbxassetid://100834100892964]];
	G2L["2e"]["Size"] = UDim2.new(0.75, 0, 0.5, 0);
	G2L["2e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2e"]["BackgroundTransparency"] = 1;
	G2L["2e"]["Name"] = [[ImageBackground]];
	G2L["2e"]["Position"] = UDim2.new(0, 150, 0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.Background.Decoration3
	G2L["2f"] = Instance.new("ImageLabel", G2L["29"]);
	G2L["2f"]["ZIndex"] = -10;
	G2L["2f"]["BorderSizePixel"] = 0;
	G2L["2f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2f"]["ImageTransparency"] = 0.9;
	G2L["2f"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["2f"]["Image"] = [[rbxassetid://134778882606176]];
	G2L["2f"]["Size"] = UDim2.new(0, 35, 0, 35);
	G2L["2f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2f"]["BackgroundTransparency"] = 1;
	G2L["2f"]["Name"] = [[Decoration3]];
	G2L["2f"]["Position"] = UDim2.new(1, 0, 1, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent
	G2L["30"] = Instance.new("Frame", G2L["3"]);
	G2L["30"]["BorderSizePixel"] = 0;
	G2L["30"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["30"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["30"]["Size"] = UDim2.new(1, -150, 1, 0);
	G2L["30"]["Position"] = UDim2.new(1, 0, 1, 0);
	G2L["30"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["30"]["Name"] = [[TabContent]];
	G2L["30"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.TopContent
	G2L["31"] = Instance.new("Frame", G2L["30"]);
	G2L["31"]["BorderSizePixel"] = 0;
	G2L["31"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["31"]["Size"] = UDim2.new(0.65, 0, 0, 60);
	G2L["31"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["31"]["Name"] = [[TopContent]];
	G2L["31"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.TopContent.Padding
	G2L["32"] = Instance.new("UIPadding", G2L["31"]);
	G2L["32"]["PaddingTop"] = UDim.new(0, 5);
	G2L["32"]["PaddingRight"] = UDim.new(0, 10);
	G2L["32"]["Name"] = [[Padding]];
	G2L["32"]["PaddingLeft"] = UDim.new(0, 10);
	G2L["32"]["PaddingBottom"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.TopContent.TabTitle
	G2L["33"] = Instance.new("TextLabel", G2L["31"]);
	G2L["33"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["33"]["BorderSizePixel"] = 0;
	G2L["33"]["TextSize"] = 18;
	G2L["33"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["33"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["33"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["33"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["33"]["BackgroundTransparency"] = 1;
	G2L["33"]["Size"] = UDim2.new(1, 0, 0, 35);
	G2L["33"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["33"]["Text"] = [[Visual]];
	G2L["33"]["Name"] = [[TabTitle]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.TopContent.TabTitle.Padding
	G2L["34"] = Instance.new("UIPadding", G2L["33"]);
	G2L["34"]["Name"] = [[Padding]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.TopContent.TabDescription
	G2L["35"] = Instance.new("TextLabel", G2L["31"]);
	G2L["35"]["TextWrapped"] = true;
	G2L["35"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["35"]["BorderSizePixel"] = 0;
	G2L["35"]["TextSize"] = 12;
	G2L["35"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["35"]["TextYAlignment"] = Enum.TextYAlignment.Top;
	G2L["35"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["35"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["35"]["TextColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["35"]["BackgroundTransparency"] = 1;
	G2L["35"]["Size"] = UDim2.new(1, 0, 0, 60);
	G2L["35"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["35"]["Text"] = [[This section is about showing visual exploits]];
	G2L["35"]["Name"] = [[TabDescription]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.TopContent.TabDescription.Padding
	G2L["36"] = Instance.new("UIPadding", G2L["35"]);
	G2L["36"]["PaddingTop"] = UDim.new(0, 30);
	G2L["36"]["Name"] = [[Padding]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.TopContent.TabIcon
	G2L["37"] = Instance.new("ImageLabel", G2L["31"]);
	G2L["37"]["ZIndex"] = -10;
	G2L["37"]["BorderSizePixel"] = 0;
	G2L["37"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["37"]["ImageTransparency"] = 0.9;
	G2L["37"]["Image"] = [[rbxassetid://7035631382]];
	G2L["37"]["Size"] = UDim2.new(0, 35, 0, 35);
	G2L["37"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["37"]["BackgroundTransparency"] = 1;
	G2L["37"]["Name"] = [[TabIcon]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Container
	G2L["38"] = Instance.new("Frame", G2L["30"]);
	G2L["38"]["ZIndex"] = -5;
	G2L["38"]["BorderSizePixel"] = 0;
	G2L["38"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["38"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["38"]["Size"] = UDim2.new(1, 0, 1, -70);
	G2L["38"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["38"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["38"]["Name"] = [[Container]];
	G2L["38"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Container.Page
	G2L["39"] = Instance.new("ScrollingFrame", G2L["38"]);
	G2L["39"]["Active"] = true;
	G2L["39"]["BorderSizePixel"] = 0;
	G2L["39"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
	G2L["39"]["Name"] = [[Page]];
	G2L["39"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["39"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
	G2L["39"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["39"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["39"]["ScrollBarThickness"] = 6;
	G2L["39"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Container.Page.Content
	G2L["3a"] = Instance.new("Frame", G2L["39"]);
	G2L["3a"]["BorderSizePixel"] = 0;
	G2L["3a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3a"]["AnchorPoint"] = Vector2.new(0.5, 0);
	G2L["3a"]["AutomaticSize"] = Enum.AutomaticSize.Y;
	G2L["3a"]["Size"] = UDim2.new(1, -20, 0, 0);
	G2L["3a"]["Position"] = UDim2.new(0.5, 0, 0, 0);
	G2L["3a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3a"]["Name"] = [[Content]];
	G2L["3a"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Container.Page.Content.Padding
	G2L["3b"] = Instance.new("UIPadding", G2L["3a"]);
	G2L["3b"]["PaddingRight"] = UDim.new(0, 5);
	G2L["3b"]["Name"] = [[Padding]];
	G2L["3b"]["PaddingLeft"] = UDim.new(0, 5);
	G2L["3b"]["PaddingBottom"] = UDim.new(0, 30);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Container.Page.Content.List
	G2L["3c"] = Instance.new("UIListLayout", G2L["3a"]);
	G2L["3c"]["Padding"] = UDim.new(0, 10);
	G2L["3c"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["3c"]["Name"] = [[List]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.BottomContent
	G2L["3d"] = Instance.new("Frame", G2L["30"]);
	G2L["3d"]["ZIndex"] = 3;
	G2L["3d"]["BorderSizePixel"] = 0;
	G2L["3d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3d"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["3d"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["3d"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["3d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3d"]["Name"] = [[BottomContent]];
	G2L["3d"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.BottomContent.Padding
	G2L["3e"] = Instance.new("UIPadding", G2L["3d"]);
	G2L["3e"]["PaddingTop"] = UDim.new(0, 10);
	G2L["3e"]["PaddingRight"] = UDim.new(0, 10);
	G2L["3e"]["Name"] = [[Padding]];
	G2L["3e"]["PaddingLeft"] = UDim.new(0, 10);
	G2L["3e"]["PaddingBottom"] = UDim.new(0, 10);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.BottomContent.ObjectInfo
	G2L["3f"] = Instance.new("TextLabel", G2L["3d"]);
	G2L["3f"]["TextWrapped"] = true;
	G2L["3f"]["BorderSizePixel"] = 0;
	G2L["3f"]["TextSize"] = 16;
	G2L["3f"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["3f"]["BackgroundColor3"] = Color3.fromRGB(31, 33, 49);
	G2L["3f"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["3f"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3f"]["BackgroundTransparency"] = 0.25;
	G2L["3f"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["3f"]["Size"] = UDim2.new(1, 0, 0, 0);
	G2L["3f"]["Visible"] = false;
	G2L["3f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3f"]["Text"] = [[GUYSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS SSSSSSSSSS]];
	G2L["3f"]["AutomaticSize"] = Enum.AutomaticSize.Y;
	G2L["3f"]["Name"] = [[ObjectInfo]];
	G2L["3f"]["Position"] = UDim2.new(0, 0, 1, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.BottomContent.ObjectInfo.Shadow
	G2L["40"] = Instance.new("UIShadow", G2L["3f"]);
	G2L["40"]["BlurRadius"] = UDim.new(0, 10);
	G2L["40"]["Transparency"] = 0.5;
	G2L["40"]["Name"] = [[Shadow]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.BottomContent.ObjectInfo.Radius
	G2L["41"] = Instance.new("UICorner", G2L["3f"]);
	G2L["41"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["41"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["41"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["41"]["Name"] = [[Radius]];
	G2L["41"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["41"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.BottomContent.ObjectInfo.Padding
	G2L["42"] = Instance.new("UIPadding", G2L["3f"]);
	G2L["42"]["PaddingTop"] = UDim.new(0, 10);
	G2L["42"]["PaddingRight"] = UDim.new(0, 10);
	G2L["42"]["Name"] = [[Padding]];
	G2L["42"]["PaddingLeft"] = UDim.new(0, 10);
	G2L["42"]["PaddingBottom"] = UDim.new(0, 10);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Vignette
	G2L["43"] = Instance.new("ImageButton", G2L["30"]);
	G2L["43"]["BorderSizePixel"] = 0;
	G2L["43"]["AutoButtonColor"] = false;
	G2L["43"]["Visible"] = false;
	G2L["43"]["ImageTransparency"] = 1;
	G2L["43"]["BackgroundTransparency"] = 0.25;
	G2L["43"]["BackgroundColor3"] = Color3.fromRGB(37, 40, 59);
	G2L["43"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["43"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["43"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["43"]["Name"] = [[Vignette]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts
	G2L["44"] = Instance.new("Frame", G2L["30"]);
	G2L["44"]["ZIndex"] = 5;
	G2L["44"]["BorderSizePixel"] = 0;
	G2L["44"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["44"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["44"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["44"]["Name"] = [[Prompts]];
	G2L["44"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker
	G2L["45"] = Instance.new("Frame", G2L["44"]);
	G2L["45"]["Visible"] = false;
	G2L["45"]["BorderSizePixel"] = 0;
	G2L["45"]["BackgroundColor3"] = Color3.fromRGB(31, 33, 49);
	G2L["45"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["45"]["Size"] = UDim2.new(0.65, 0, 0.65, 0);
	G2L["45"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["45"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["45"]["Name"] = [[Picker]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Picker
	G2L["46"] = Instance.new("ImageLabel", G2L["45"]);
	G2L["46"]["BorderSizePixel"] = 0;
	G2L["46"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["46"]["Image"] = [[rbxassetid://91671058647239]];
	G2L["46"]["Size"] = UDim2.new(0.9, 0, 0.9, 0);
	G2L["46"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["46"]["BackgroundTransparency"] = 1;
	G2L["46"]["Name"] = [[Picker]];
	G2L["46"]["Position"] = UDim2.new(0.05, 0, 0.05, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Picker.Aspect
	G2L["47"] = Instance.new("UIAspectRatioConstraint", G2L["46"]);
	G2L["47"]["Name"] = [[Aspect]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Picker.Selection
	G2L["48"] = Instance.new("Frame", G2L["46"]);
	G2L["48"]["BorderSizePixel"] = 0;
	G2L["48"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["48"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["48"]["Size"] = UDim2.new(0.06, 0, 0.06, 0);
	G2L["48"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["48"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["48"]["Name"] = [[Selection]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Picker.Selection.Radius
	G2L["49"] = Instance.new("UICorner", G2L["48"]);
	G2L["49"]["BottomRightRadius"] = UDim.new(0.5, 0);
	G2L["49"]["BottomLeftRadius"] = UDim.new(0.5, 0);
	G2L["49"]["TopRightRadius"] = UDim.new(0.5, 0);
	G2L["49"]["Name"] = [[Radius]];
	G2L["49"]["TopLeftRadius"] = UDim.new(0.5, 0);
	G2L["49"]["CornerRadius"] = UDim.new(0.5, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Picker.Selection.Stroke
	G2L["4a"] = Instance.new("UIStroke", G2L["48"]);
	G2L["4a"]["Transparency"] = 0.5;
	G2L["4a"]["Thickness"] = 0.3;
	G2L["4a"]["StrokeSizingMode"] = Enum.StrokeSizingMode.ScaledSize;
	G2L["4a"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
	G2L["4a"]["Name"] = [[Stroke]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Picker.Button
	G2L["4b"] = Instance.new("TextButton", G2L["46"]);
	G2L["4b"]["BorderSizePixel"] = 0;
	G2L["4b"]["TextSize"] = 14;
	G2L["4b"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["4b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["4b"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["4b"]["ZIndex"] = 2;
	G2L["4b"]["BackgroundTransparency"] = 1;
	G2L["4b"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["4b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["4b"]["Text"] = [[]];
	G2L["4b"]["Name"] = [[Button]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Slider
	G2L["4c"] = Instance.new("Frame", G2L["45"]);
	G2L["4c"]["BorderSizePixel"] = 0;
	G2L["4c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["4c"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["4c"]["Size"] = UDim2.new(0.9, 0, 0.1, 0);
	G2L["4c"]["Position"] = UDim2.new(0.5, 0, 0.9, 0);
	G2L["4c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["4c"]["Name"] = [[Slider]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Slider.Gradient
	G2L["4d"] = Instance.new("UIGradient", G2L["4c"]);
	G2L["4d"]["Name"] = [[Gradient]];
	G2L["4d"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255))};


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Slider.Selection
	G2L["4e"] = Instance.new("Frame", G2L["4c"]);
	G2L["4e"]["BorderSizePixel"] = 0;
	G2L["4e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["4e"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["4e"]["Size"] = UDim2.new(0.04, 0, 1.4, 0);
	G2L["4e"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["4e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["4e"]["Name"] = [[Selection]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Slider.Selection.Radius
	G2L["4f"] = Instance.new("UICorner", G2L["4e"]);
	G2L["4f"]["BottomRightRadius"] = UDim.new(1, 0);
	G2L["4f"]["BottomLeftRadius"] = UDim.new(1, 0);
	G2L["4f"]["TopRightRadius"] = UDim.new(1, 0);
	G2L["4f"]["Name"] = [[Radius]];
	G2L["4f"]["TopLeftRadius"] = UDim.new(1, 0);
	G2L["4f"]["CornerRadius"] = UDim.new(1, 0);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Slider.Button
	G2L["50"] = Instance.new("TextButton", G2L["4c"]);
	G2L["50"]["BorderSizePixel"] = 0;
	G2L["50"]["TextSize"] = 14;
	G2L["50"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["50"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["50"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["50"]["ZIndex"] = 2;
	G2L["50"]["BackgroundTransparency"] = 1;
	G2L["50"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["50"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["50"]["Text"] = [[]];
	G2L["50"]["Name"] = [[Button]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.ColorPreview
	G2L["51"] = Instance.new("Frame", G2L["45"]);
	G2L["51"]["BorderSizePixel"] = 0;
	G2L["51"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["51"]["Size"] = UDim2.new(0.1, 0, 0.1, 0);
	G2L["51"]["Position"] = UDim2.new(0.05, 0, 0.05, 0);
	G2L["51"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["51"]["Name"] = [[ColorPreview]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.ColorPreview.Aspect
	G2L["52"] = Instance.new("UIAspectRatioConstraint", G2L["51"]);
	G2L["52"]["Name"] = [[Aspect]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.ColorPreview.Radius
	G2L["53"] = Instance.new("UICorner", G2L["51"]);
	G2L["53"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["53"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["53"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["53"]["Name"] = [[Radius]];
	G2L["53"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["53"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Aspect
	G2L["54"] = Instance.new("UIAspectRatioConstraint", G2L["45"]);
	G2L["54"]["AspectRatio"] = 0.82;
	G2L["54"]["Name"] = [[Aspect]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Shadow
	G2L["55"] = Instance.new("UIShadow", G2L["45"]);
	G2L["55"]["Offset"] = UDim2.new(0, 0, 0, 20);
	G2L["55"]["BlurRadius"] = UDim.new(0, 40);
	G2L["55"]["Transparency"] = 0.5;
	G2L["55"]["Name"] = [[Shadow]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Scale
	G2L["56"] = Instance.new("UIScale", G2L["45"]);
	G2L["56"]["Name"] = [[Scale]];
	G2L["56"]["Scale"] = 1.25;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Picker.Radius
	G2L["57"] = Instance.new("UICorner", G2L["45"]);
	G2L["57"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["57"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["57"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["57"]["Name"] = [[Radius]];
	G2L["57"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["57"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown
	G2L["58"] = Instance.new("Frame", G2L["44"]);
	G2L["58"]["Visible"] = false;
	G2L["58"]["BorderSizePixel"] = 0;
	G2L["58"]["BackgroundColor3"] = Color3.fromRGB(31, 33, 49);
	G2L["58"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["58"]["Size"] = UDim2.new(0.65, 0, 0.65, 0);
	G2L["58"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["58"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["58"]["Name"] = [[Dropdown]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.Aspect
	G2L["59"] = Instance.new("UIAspectRatioConstraint", G2L["58"]);
	G2L["59"]["AspectRatio"] = 0.82;
	G2L["59"]["Name"] = [[Aspect]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.Radius
	G2L["5a"] = Instance.new("UICorner", G2L["58"]);
	G2L["5a"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["5a"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["5a"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["5a"]["Name"] = [[Radius]];
	G2L["5a"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["5a"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.Shadow
	G2L["5b"] = Instance.new("UIShadow", G2L["58"]);
	G2L["5b"]["Offset"] = UDim2.new(0, 0, 0, 20);
	G2L["5b"]["BlurRadius"] = UDim.new(0, 40);
	G2L["5b"]["Transparency"] = 0.5;
	G2L["5b"]["Name"] = [[Shadow]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.Container
	G2L["5c"] = Instance.new("ScrollingFrame", G2L["58"]);
	G2L["5c"]["Active"] = true;
	G2L["5c"]["BorderSizePixel"] = 0;
	G2L["5c"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
	G2L["5c"]["Name"] = [[Container]];
	G2L["5c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["5c"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["5c"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
	G2L["5c"]["Size"] = UDim2.new(1, 0, 1, -45);
	G2L["5c"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["5c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5c"]["ScrollBarThickness"] = 6;
	G2L["5c"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.Container.List
	G2L["5d"] = Instance.new("UIListLayout", G2L["5c"]);
	G2L["5d"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["5d"]["Name"] = [[List]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.Padding
	G2L["5e"] = Instance.new("UIPadding", G2L["58"]);
	G2L["5e"]["PaddingTop"] = UDim.new(0, 10);
	G2L["5e"]["PaddingRight"] = UDim.new(0, 10);
	G2L["5e"]["Name"] = [[Padding]];
	G2L["5e"]["PaddingLeft"] = UDim.new(0, 10);
	G2L["5e"]["PaddingBottom"] = UDim.new(0, 10);


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.TopContent
	G2L["5f"] = Instance.new("Frame", G2L["58"]);
	G2L["5f"]["BorderSizePixel"] = 0;
	G2L["5f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["5f"]["Size"] = UDim2.new(1, 0, 0, 45);
	G2L["5f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5f"]["Name"] = [[TopContent]];
	G2L["5f"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.TopContent.TabTitle
	G2L["60"] = Instance.new("TextLabel", G2L["5f"]);
	G2L["60"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["60"]["BorderSizePixel"] = 0;
	G2L["60"]["TextSize"] = 18;
	G2L["60"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["60"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["60"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["60"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["60"]["BackgroundTransparency"] = 1;
	G2L["60"]["Size"] = UDim2.new(1, 0, 0, 35);
	G2L["60"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["60"]["Text"] = [[Dropdown]];
	G2L["60"]["Name"] = [[TabTitle]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.TopContent.TabTitle.Padding
	G2L["61"] = Instance.new("UIPadding", G2L["60"]);
	G2L["61"]["Name"] = [[Padding]];


	-- StarterGui.ScreenGui.Holder.MainFrame.TabContent.Prompts.Dropdown.Scale
	G2L["62"] = Instance.new("UIScale", G2L["58"]);
	G2L["62"]["Name"] = [[Scale]];
	G2L["62"]["Scale"] = 1.25;


	-- StarterGui.ScreenGui.Holder.MainFrame.Drag
	G2L["63"] = Instance.new("UIDragDetector", G2L["3"]);
	G2L["63"]["Name"] = [[Drag]];
	return G2L["1"]
end
local function createPage()
	local G2L = {};


	-- StarterGui.ScreenGui.Tab
	G2L["2"] = Instance.new("ImageButton");
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["BackgroundTransparency"] = 1;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2"]["Size"] = UDim2.new(1, 0, 0, 35);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Name"] = [[Tab]];


	-- StarterGui.ScreenGui.Tab.Background
	G2L["3"] = Instance.new("CanvasGroup", G2L["2"]);
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3"]["GroupColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["3"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3"]["Name"] = [[Background]];
	G2L["3"]["BackgroundTransparency"] = 0.75;


	-- StarterGui.ScreenGui.Tab.Background.Radius
	G2L["4"] = Instance.new("UICorner", G2L["3"]);
	G2L["4"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["4"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["4"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["4"]["Name"] = [[Radius]];
	G2L["4"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["4"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Tab.Background.Decoration0
	G2L["5"] = Instance.new("Frame", G2L["3"]);
	G2L["5"]["BorderSizePixel"] = 0;
	G2L["5"]["BackgroundColor3"] = Color3.fromRGB(37, 40, 59);
	G2L["5"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["5"]["Size"] = UDim2.new(0, 35, 2, 0);
	G2L["5"]["Position"] = UDim2.new(1, 0, 1.75, 0);
	G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5"]["Name"] = [[Decoration0]];
	G2L["5"]["Rotation"] = 45;
	G2L["5"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Tab.Background.Decoration1
	G2L["6"] = Instance.new("Frame", G2L["3"]);
	G2L["6"]["BorderSizePixel"] = 0;
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(37, 40, 59);
	G2L["6"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["6"]["Size"] = UDim2.new(0, 35, 3, 0);
	G2L["6"]["Position"] = UDim2.new(0.5, 0, 1.75, 0);
	G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["6"]["Name"] = [[Decoration1]];
	G2L["6"]["Rotation"] = 45;
	G2L["6"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Tab.Background.Shadow
	G2L["7"] = Instance.new("UIShadow", G2L["3"]);
	G2L["7"]["BlurRadius"] = UDim.new(0, 40);
	G2L["7"]["Name"] = [[Shadow]];


	-- StarterGui.ScreenGui.Tab.TextContainer
	G2L["8"] = Instance.new("Frame", G2L["2"]);
	G2L["8"]["BorderSizePixel"] = 0;
	G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["8"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["8"]["Name"] = [[TextContainer]];
	G2L["8"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Tab.TextContainer.Padding
	G2L["9"] = Instance.new("UIPadding", G2L["8"]);
	G2L["9"]["PaddingTop"] = UDim.new(0, 5);
	G2L["9"]["PaddingRight"] = UDim.new(0, 5);
	G2L["9"]["Name"] = [[Padding]];
	G2L["9"]["PaddingLeft"] = UDim.new(0, 5);
	G2L["9"]["PaddingBottom"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Tab.TextContainer.TabTitle
	G2L["a"] = Instance.new("TextLabel", G2L["8"]);
	G2L["a"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["a"]["BorderSizePixel"] = 0;
	G2L["a"]["TextSize"] = 16;
	G2L["a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["a"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["a"]["BackgroundTransparency"] = 1;
	G2L["a"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["a"]["Text"] = [[Visual]];
	G2L["a"]["Name"] = [[TabTitle]];


	-- StarterGui.ScreenGui.Tab.TextContainer.TabTitle.Padding
	G2L["b"] = Instance.new("UIPadding", G2L["a"]);
	G2L["b"]["Name"] = [[Padding]];
	G2L["b"]["PaddingLeft"] = UDim.new(0, 35);


	-- StarterGui.ScreenGui.Tab.TextContainer.TabIcon
	G2L["c"] = Instance.new("Frame", G2L["8"]);
	G2L["c"]["BorderSizePixel"] = 0;
	G2L["c"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["c"]["AnchorPoint"] = Vector2.new(0, 0.5);
	G2L["c"]["Size"] = UDim2.new(0, 25, 0, 25);
	G2L["c"]["Position"] = UDim2.new(0, 0, 0.5, 0);
	G2L["c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["c"]["Name"] = [[TabIcon]];
	G2L["c"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Tab.TextContainer.TabIcon.Icon
	G2L["d"] = Instance.new("ImageLabel", G2L["c"]);
	G2L["d"]["BorderSizePixel"] = 0;
	G2L["d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["d"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["d"]["Image"] = [[rbxassetid://7035631382]];
	G2L["d"]["Size"] = UDim2.new(0.75, 0, 0.75, 0);
	G2L["d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["d"]["BackgroundTransparency"] = 1;
	G2L["d"]["Name"] = [[Icon]];
	G2L["d"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.ScreenGui.Tab.TextContainer.TabIcon.Radius
	G2L["e"] = Instance.new("UICorner", G2L["c"]);
	G2L["e"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["e"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["e"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["e"]["Name"] = [[Radius]];
	G2L["e"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["e"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Page
	G2L["f"] = Instance.new("ScrollingFrame");
	G2L["f"]["Active"] = true;
	G2L["f"]["BorderSizePixel"] = 0;
	G2L["f"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
	G2L["f"]["Name"] = [[Page]];
	G2L["f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["f"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
	G2L["f"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["f"]["ScrollBarThickness"] = 6;
	G2L["f"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Page.Content
	G2L["10"] = Instance.new("Frame", G2L["f"]);
	G2L["10"]["BorderSizePixel"] = 0;
	G2L["10"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["10"]["AnchorPoint"] = Vector2.new(0.5, 0);
	G2L["10"]["AutomaticSize"] = Enum.AutomaticSize.Y;
	G2L["10"]["Size"] = UDim2.new(1, -20, 0, 0);
	G2L["10"]["Position"] = UDim2.new(0.5, 0, 0, 0);
	G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["10"]["Name"] = [[Content]];
	G2L["10"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Page.Content.Padding
	G2L["11"] = Instance.new("UIPadding", G2L["10"]);
	G2L["11"]["PaddingRight"] = UDim.new(0, 5);
	G2L["11"]["Name"] = [[Padding]];
	G2L["11"]["PaddingLeft"] = UDim.new(0, 5);
	G2L["11"]["PaddingBottom"] = UDim.new(0, 30);


	-- StarterGui.ScreenGui.Page.Content.List
	G2L["12"] = Instance.new("UIListLayout", G2L["10"]);
	G2L["12"]["Padding"] = UDim.new(0, 10);
	G2L["12"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["12"]["Name"] = [[List]];



	return {
		Tab = G2L["2"],
		Page = G2L["f"]
	}
end

local function createButton()
	local G2L = {};
	-- StarterGui.ScreenGui.Button
	G2L["2"] = Instance.new("ImageButton");
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["ImageTransparency"] = 1;
	G2L["2"]["BackgroundTransparency"] = 1;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["2"]["Size"] = UDim2.new(1, 0, 0, 35);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Name"] = [[Button]];


	-- StarterGui.ScreenGui.Button.Background
	G2L["3"] = Instance.new("CanvasGroup", G2L["2"]);
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3"]["ClipsDescendants"] = false;
	G2L["3"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3"]["Name"] = [[Background]];
	G2L["3"]["BackgroundTransparency"] = 0.9;


	-- StarterGui.ScreenGui.Button.Background.Radius
	G2L["4"] = Instance.new("UICorner", G2L["3"]);
	G2L["4"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["4"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["4"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["4"]["Name"] = [[Radius]];
	G2L["4"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["4"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Button.Background.Underline
	G2L["5"] = Instance.new("Frame", G2L["3"]);
	G2L["5"]["ZIndex"] = 2;
	G2L["5"]["BorderSizePixel"] = 0;
	G2L["5"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["5"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["5"]["Size"] = UDim2.new(1, 0, 0, 2);
	G2L["5"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5"]["Name"] = [[Underline]];


	-- StarterGui.ScreenGui.Button.Background.Decoration0
	G2L["6"] = Instance.new("Frame", G2L["3"]);
	G2L["6"]["BorderSizePixel"] = 0;
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(37, 40, 59);
	G2L["6"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["6"]["Size"] = UDim2.new(0, 35, 2, 0);
	G2L["6"]["Position"] = UDim2.new(1, 0, 1.75, 0);
	G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["6"]["Name"] = [[Decoration0]];
	G2L["6"]["Rotation"] = 45;
	G2L["6"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Button.Background.Decoration1
	G2L["7"] = Instance.new("Frame", G2L["3"]);
	G2L["7"]["BorderSizePixel"] = 0;
	G2L["7"]["BackgroundColor3"] = Color3.fromRGB(37, 40, 59);
	G2L["7"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["7"]["Size"] = UDim2.new(0, 35, 3, 0);
	G2L["7"]["Position"] = UDim2.new(0.5, 0, 1.75, 0);
	G2L["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["7"]["Name"] = [[Decoration1]];
	G2L["7"]["Rotation"] = 45;
	G2L["7"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Button.TextContainer
	G2L["8"] = Instance.new("Frame", G2L["2"]);
	G2L["8"]["BorderSizePixel"] = 0;
	G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["8"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["8"]["Name"] = [[TextContainer]];
	G2L["8"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Button.TextContainer.Padding
	G2L["9"] = Instance.new("UIPadding", G2L["8"]);
	G2L["9"]["PaddingTop"] = UDim.new(0, 5);
	G2L["9"]["PaddingRight"] = UDim.new(0, 5);
	G2L["9"]["Name"] = [[Padding]];
	G2L["9"]["PaddingLeft"] = UDim.new(0, 5);
	G2L["9"]["PaddingBottom"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Button.TextContainer.ButtonTitle
	G2L["a"] = Instance.new("TextLabel", G2L["8"]);
	G2L["a"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["a"]["BorderSizePixel"] = 0;
	G2L["a"]["TextSize"] = 16;
	G2L["a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["a"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["a"]["BackgroundTransparency"] = 1;
	G2L["a"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["a"]["Text"] = [[Show Loot]];
	G2L["a"]["Name"] = [[ButtonTitle]];


	-- StarterGui.ScreenGui.Button.TextContainer.ButtonTitle.Padding
	G2L["b"] = Instance.new("UIPadding", G2L["a"]);
	G2L["b"]["Name"] = [[Padding]];
	G2L["b"]["PaddingLeft"] = UDim.new(0, 35);


	-- StarterGui.ScreenGui.Button.TextContainer.ButtonIcon
	G2L["c"] = Instance.new("Frame", G2L["8"]);
	G2L["c"]["BorderSizePixel"] = 0;
	G2L["c"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["c"]["AnchorPoint"] = Vector2.new(0, 0.5);
	G2L["c"]["Size"] = UDim2.new(0, 25, 0, 25);
	G2L["c"]["Position"] = UDim2.new(0, 0, 0.5, 0);
	G2L["c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["c"]["Name"] = [[ButtonIcon]];
	G2L["c"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Button.TextContainer.ButtonIcon.Icon
	G2L["d"] = Instance.new("ImageLabel", G2L["c"]);
	G2L["d"]["BorderSizePixel"] = 0;
	G2L["d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["d"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["d"]["Image"] = [[rbxassetid://18985225104]];
	G2L["d"]["Size"] = UDim2.new(0.75, 0, 0.75, 0);
	G2L["d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["d"]["BackgroundTransparency"] = 1;
	G2L["d"]["Name"] = [[Icon]];
	G2L["d"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["e"] = Instance.new("UICorner", G2L["c"]);
	G2L["e"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["e"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["e"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["e"]["Name"] = [[Radius]];
	G2L["e"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["e"]["CornerRadius"] = UDim.new(0, 5);
	return G2L["2"]
end

local function createBoolean()
	local G2L = {};
	-- StarterGui.ScreenGui.Boolean
	G2L["2"] = Instance.new("ImageButton");
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["ImageTransparency"] = 1;
	G2L["2"]["BackgroundTransparency"] = 1;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["2"]["Size"] = UDim2.new(1, 0, 0, 35);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Name"] = [[Boolean]];


	-- StarterGui.ScreenGui.Boolean.Background
	G2L["3"] = Instance.new("CanvasGroup", G2L["2"]);
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3"]["ClipsDescendants"] = false;
	G2L["3"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3"]["Name"] = [[Background]];
	G2L["3"]["BackgroundTransparency"] = 0.9;


	-- StarterGui.ScreenGui.Boolean.Background.Radius
	G2L["4"] = Instance.new("UICorner", G2L["3"]);
	G2L["4"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["4"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["4"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["4"]["Name"] = [[Radius]];
	G2L["4"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["4"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Boolean.Background.Underline
	G2L["5"] = Instance.new("Frame", G2L["3"]);
	G2L["5"]["ZIndex"] = 2;
	G2L["5"]["BorderSizePixel"] = 0;
	G2L["5"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["5"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["5"]["Size"] = UDim2.new(1, 0, 0, 2);
	G2L["5"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5"]["Name"] = [[Underline]];


	-- StarterGui.ScreenGui.Boolean.Background.Decoration0
	G2L["6"] = Instance.new("Frame", G2L["3"]);
	G2L["6"]["BorderSizePixel"] = 0;
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(37, 40, 59);
	G2L["6"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["6"]["Size"] = UDim2.new(0, 35, 2, 0);
	G2L["6"]["Position"] = UDim2.new(1, 0, 1.75, 0);
	G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["6"]["Name"] = [[Decoration0]];
	G2L["6"]["Rotation"] = 45;
	G2L["6"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Boolean.Background.Decoration1
	G2L["7"] = Instance.new("Frame", G2L["3"]);
	G2L["7"]["BorderSizePixel"] = 0;
	G2L["7"]["BackgroundColor3"] = Color3.fromRGB(37, 40, 59);
	G2L["7"]["AnchorPoint"] = Vector2.new(1, 1);
	G2L["7"]["Size"] = UDim2.new(0, 35, 3, 0);
	G2L["7"]["Position"] = UDim2.new(0.5, 0, 1.75, 0);
	G2L["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["7"]["Name"] = [[Decoration1]];
	G2L["7"]["Rotation"] = 45;
	G2L["7"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Boolean.TextContainer
	G2L["8"] = Instance.new("Frame", G2L["2"]);
	G2L["8"]["BorderSizePixel"] = 0;
	G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["8"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["8"]["Name"] = [[TextContainer]];
	G2L["8"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Boolean.TextContainer.Padding
	G2L["9"] = Instance.new("UIPadding", G2L["8"]);
	G2L["9"]["PaddingTop"] = UDim.new(0, 5);
	G2L["9"]["PaddingRight"] = UDim.new(0, 5);
	G2L["9"]["Name"] = [[Padding]];
	G2L["9"]["PaddingLeft"] = UDim.new(0, 5);
	G2L["9"]["PaddingBottom"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanTitle
	G2L["a"] = Instance.new("TextLabel", G2L["8"]);
	G2L["a"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["a"]["BorderSizePixel"] = 0;
	G2L["a"]["TextSize"] = 16;
	G2L["a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["a"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["a"]["BackgroundTransparency"] = 1;
	G2L["a"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["a"]["Text"] = [[Toggle]];
	G2L["a"]["Name"] = [[BooleanTitle]];


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanTitle.Padding
	G2L["b"] = Instance.new("UIPadding", G2L["a"]);
	G2L["b"]["Name"] = [[Padding]];
	G2L["b"]["PaddingLeft"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanStatus
	G2L["c"] = Instance.new("Frame", G2L["8"]);
	G2L["c"]["BorderSizePixel"] = 0;
	G2L["c"]["BackgroundColor3"] = Color3.fromRGB(111, 116, 142);
	G2L["c"]["AnchorPoint"] = Vector2.new(1, 0.5);
	G2L["c"]["Size"] = UDim2.new(0, 50, 0, 25);
	G2L["c"]["Position"] = UDim2.new(1, 0, 0.5, 0);
	G2L["c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["c"]["Name"] = [[BooleanStatus]];
	G2L["c"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanStatus.Radius
	G2L["d"] = Instance.new("UICorner", G2L["c"]);
	G2L["d"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["d"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["d"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["d"]["Name"] = [[Radius]];
	G2L["d"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["d"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanStatus.Fill
	G2L["e"] = Instance.new("Frame", G2L["c"]);
	G2L["e"]["BorderSizePixel"] = 0;
	G2L["e"]["BackgroundColor3"] = Color3.fromRGB(167, 228, 162);
	G2L["e"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["e"]["Name"] = [[Fill]];
	G2L["e"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanStatus.Fill.Radius
	G2L["f"] = Instance.new("UICorner", G2L["e"]);
	G2L["f"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["f"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["f"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["f"]["Name"] = [[Radius]];
	G2L["f"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["f"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanStatus.Bar
	G2L["10"] = Instance.new("Frame", G2L["c"]);
	G2L["10"]["BorderSizePixel"] = 0;
	G2L["10"]["BackgroundColor3"] = Color3.fromRGB(167, 228, 162);
	G2L["10"]["AnchorPoint"] = Vector2.new(1, 0);
	G2L["10"]["Size"] = UDim2.new(0, 25, 1, 0);
	G2L["10"]["Position"] = UDim2.new(1, 0, 0, 0);
	G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["10"]["Name"] = [[Bar]];


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanStatus.Bar.Radius
	G2L["11"] = Instance.new("UICorner", G2L["10"]);
	G2L["11"]["BottomRightRadius"] = UDim.new(0, 5);
	G2L["11"]["BottomLeftRadius"] = UDim.new(0, 5);
	G2L["11"]["TopRightRadius"] = UDim.new(0, 5);
	G2L["11"]["Name"] = [[Radius]];
	G2L["11"]["TopLeftRadius"] = UDim.new(0, 5);
	G2L["11"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.ScreenGui.Boolean.TextContainer.BooleanStatus.Bar.UIShadow
	G2L["12"] = Instance.new("UIShadow", G2L["10"]);
	G2L["12"]["BlurRadius"] = UDim.new(0, 10);
	G2L["12"]["Transparency"] = 0.5;
	return G2L["2"]
end
local function createSectionLabel()
	local G2L = {};
	-- StarterGui.ScreenGui.SectionLabel
	G2L["2"] = Instance.new("TextLabel");
	G2L["2"]["TextWrapped"] = true;
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["TextSize"] = 14;
	G2L["2"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["2"]["TextYAlignment"] = Enum.TextYAlignment.Top;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
	G2L["2"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2"]["BackgroundTransparency"] = 1;
	G2L["2"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Text"] = [[Section Label]];
	G2L["2"]["AutomaticSize"] = Enum.AutomaticSize.Y;
	G2L["2"]["Name"] = [[SectionLabel]];


	-- StarterGui.ScreenGui.SectionLabel.Description
	G2L["3"] = Instance.new("TextLabel", G2L["2"]);
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["TextSize"] = 14;
	G2L["3"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["3"]["TextYAlignment"] = Enum.TextYAlignment.Top;
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["3"]["TextColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["3"]["BackgroundTransparency"] = 1;
	G2L["3"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3"]["Text"] = [[This part of the page does something really good!]];
	G2L["3"]["Name"] = [[Description]];
	G2L["3"]["Position"] = UDim2.new(0, 0, 1, 0);
	return G2L["2"]
end

function CatLib:Window(windowConfig)
	local self = {}
	local windowElement = createWindow()
	
	local selectedTab = nil
	local pages = {}
	
	local BulkFade = BulkFadeModule()
	local Ripple = RippleModule()
	local Drag = DragModule()
	
	windowConfig = validateConfig({
		Title = "CatLib Demo",
		Icon = 134778882606176,
		Version = 1.0,
		
		DefaultTheme = "Frappe"
	}, windowConfig)
	
	-- Fast functions
	local function onButtonHover(obj: Instance)
		onHover(obj, function()
			tween(obj.Background, TweenInfo.new(0.15), {BackgroundTransparency = 0.75})
			tween(obj.Background.Decoration0, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 2, 0)})
			tween(obj.Background.Decoration1, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 3, 0)})
		end, function()
			tween(obj.Background, TweenInfo.new(0.15), {BackgroundTransparency = 0.9})
			tween(obj.Background.Decoration0, TweenInfo.new(0.15), {Size = UDim2.new(0, 35, 2, 0)})
			tween(obj.Background.Decoration1, TweenInfo.new(0.15), {Size = UDim2.new(0, 35, 3, 0)})
		end)
	end
	
	-- Title functions
	function self:SetTitle(title: string, version: string | number, icon: number)
		windowElement.Holder.MainFrame.Top.Container.WindowTitle.Text = title
		windowElement.Holder.MainFrame.Top.Container.WindowIcon.Image = rbxnumber(icon)
		windowElement.Holder.MainFrame.Top.Container.WindowVersion.Text = `V{version}`
		windowElement.Holder.MainFrame.Background.ImageBackground.Image = rbxnumber(icon)
	end
	function self:DisableTitleIcon(boolean: boolean)
		windowElement.Holder.MainFrame.Top.Container.WindowIcon.Visible = not boolean
	end
	
	-- Window functions
	function self:Minimize()
		
	end
	function self:Destroy()
		windowElement:Destroy()
		self = nil
	end
	function self:Close() self:Destroy() end
	
	-- Element functions
	function self:Page(pageConfig)
		local self = {}
		local pageElements = createPage()
		
		pageConfig = validateConfig({
			Title = "Page",
			Description = "This is an example page.",
			
			Icon = 134778882606176,
		},  pageConfig)
		
		windowElement.Holder.MainFrame.TabContent.Container.ClipsDescendants = true
		pageElements.Tab.Parent = windowElement.Holder.MainFrame.Navigation.Container.Tabs.Content
		pageElements.Page.Parent = windowElement.Holder.MainFrame.TabContent.Container
		pageElements.Page.Visible = false
		
		function self:SetTitle(title: string, description: string, icon: number)
			if selectedTab == self then
				windowElement.Holder.MainFrame.TabContent.TopContent.TabTitle.Text = title
				windowElement.Holder.MainFrame.TabContent.TopContent.TabDescription.Text = description
				windowElement.Holder.MainFrame.TabContent.TopContent.TabIcon.Image = icon and rbxnumber(icon) or nil
			end
			if pageElements.Tab then
				pageElements.Tab.TextContainer.TabTitle.Text = title
				pageElements.Tab.TextContainer.TabIcon.Icon.Image = rbxnumber(icon)
			end
		end
		
		function self:Select()
			if selectedTab == self then return end
			if selectedTab then selectedTab:Deselect() end
			
			selectedTab = self
			
			tween(pageElements.Tab.Background.Decoration0, TweenInfo.new(0.15), {Size = UDim2.new(0, 35, 2, 0)})
			tween(pageElements.Tab.Background.Decoration1, TweenInfo.new(0.15), {Size = UDim2.new(0, 35, 3, 0)})
			tween(pageElements.Tab.Background.Shadow, TweenInfo.new(0.15), {Transparency = 0})
			tween(pageElements.Tab.Background, TweenInfo.new(0.15), {BackgroundTransparency = 0.75})
			
			pageElements.Page.Position = UDim2.new(0, 0, -1, 0)
			pageElements.Page.Visible = true
			
			tween(pageElements.Page, TweenInfo.new(0.25), {Position = UDim2.new(0, 0, 0, 0)})
			
			self:SetTitle(pageConfig.Title, pageConfig.Description, pageConfig.Icon)
		end
		function self:Deselect()
			tween(pageElements.Tab.Background.Decoration0, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 2, 0)})
			tween(pageElements.Tab.Background.Decoration1, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 3, 0)})
			tween(pageElements.Tab.Background.Shadow, TweenInfo.new(0.15), {Transparency = 1})
			tween(pageElements.Tab.Background, TweenInfo.new(0.15), {BackgroundTransparency = 1})
			tween(pageElements.Page, TweenInfo.new(0.25), {Position = UDim2.new(0, 0, 1, 0)})
			task.spawn(function()
				task.wait(0.25)
				if selectedTab == self then return end
				pageElements.Page.Visible = false
			end)
		end
		
		function self:Destroy()
			pageElements.Page:Destroy()
			pageElements.Tab:Destroy()
			selectedTab = pages[1]
			if selectedTab then
				selectedTab:Select()
			else
				self:SetTitle("", "", nil)
			end
		end
		
		function self:Button(buttonConfig)
			local self = {}
			
			buttonConfig = validateConfig({
				Title = "Example Button",
				Description = "This is an example button.",
				
				Callback = function()
					print("Clicked button!")
				end,
			}, buttonConfig)
			
			local buttonElement = createButton()
			
			onButtonHover(buttonElement)
			onClick(buttonElement, function()
				Ripple:PopRipple(buttonElement, {
					Color = Color3.fromRGB(110, 115, 141),
					Speed = 0.5
				})
				buttonConfig.Callback()
			end)
			
			buttonElement.Parent = pageElements.Page.Content
			
			function self:SetTitle(title) buttonElement.TextContainer.ButtonTitle.Text = title end
			function self:SetCallback(callback) buttonConfig.Callback = callback end
			function self:Destroy() buttonElement:Destroy() end
			
			
			self:SetTitle(buttonConfig.Title)
			return self
		end
		function self:SectionLabel(labelConfig)
			local self = {}
			
			labelConfig = validateConfig({
				Title = "Example Label",
				Description = "This is an example label.",
			}, labelConfig)
			
			local labelElement = createSectionLabel()
			labelElement.Parent = pageElements.Page.Content
			
			function self:SetTitle(title)
				labelElement.Text = title
			end
			function self:SetDescription(description)
				if description == false then
					labelElement.Description.Visible = false
				else
					labelElement.Description.Visible = true
					labelElement.Description.Text = description
				end
			end
			
			self:SetTitle(labelConfig.Title)
			self:SetDescription(labelConfig.Description)
			return self
		end
		function self:Boolean(booleanConfig)
			local self = {}
			
			booleanConfig = validateConfig({
				Title = "Example Boolean",
				Description = "This is an example boolean.",
				
				Value = false,
				CallbackOnStart = false,
				
				Callback = function(value)
					print(value)
				end,
			}, booleanConfig)
			
			local booleanElement = createBoolean()
			local isStart = true
			
			function self:SetTitle(title) booleanElement.TextContainer.BooleanTitle.Text = title end
			function self:SetValue(value)
				booleanConfig.Value = value
				if value then
					tween(booleanElement.TextContainer.BooleanStatus.Fill, TweenInfo.new(0.25), {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(166, 227, 161)
					})
					tween(booleanElement.TextContainer.BooleanStatus.Bar, TweenInfo.new(0.25), {
						Position = UDim2.new(1, 0, 0, 0),
						AnchorPoint = Vector2.new(1, 0),
						BackgroundColor3 = Color3.fromRGB(166, 227, 161)
					})
				else
					tween(booleanElement.TextContainer.BooleanStatus.Fill, TweenInfo.new(0.25), {
						Size = UDim2.new(0, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(243, 139, 168),
					})
					tween(booleanElement.TextContainer.BooleanStatus.Bar, TweenInfo.new(0.25), {
						Position = UDim2.new(0, 0, 0, 0),
						AnchorPoint = Vector2.new(0, 0),
						BackgroundColor3 = Color3.fromRGB(243, 139, 168)
					})
				end
				
				if isStart and booleanConfig.CallbackOnStart then
					booleanConfig.Callback(booleanConfig.Value)
				elseif not isStart then
					booleanConfig.Callback(booleanConfig.Value)
				end
				isStart = false
			end
			function self:Destroy() booleanElement:Destroy() end
			
			onButtonHover(booleanElement)
			onClick(booleanElement, function()
				Ripple:PopRipple(booleanElement, {
					Color = Color3.fromRGB(110, 115, 141),
					Speed = 0.5
				})
				self:SetValue(not booleanConfig.Value)
			end)
			
			booleanElement.Parent = pageElements.Page.Content
			
			self:SetTitle(booleanConfig.Title)
			self:SetValue(booleanConfig.Value)
			return self
		end
		
		if not selectedTab then
			self:Select() else self:Deselect()
		end
		
		onHover(pageElements.Tab, function()
			if selectedTab == self then return end
			tween(pageElements.Tab.Background, TweenInfo.new(0.15), {BackgroundTransparency = 0.75})
		end, function()
			if selectedTab == self then return end
			tween(pageElements.Tab.Background, TweenInfo.new(0.15), {BackgroundTransparency = 1})
		end)
		onClick(pageElements.Tab, function() self:Select() end)
		
		windowElement.Holder.MainFrame.Navigation.Container.UserInfo.Container.Profile.Image =
			Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		
		self:SetTitle(pageConfig.Title, pageConfig.Description, pageConfig.Icon)
		table.insert(pages, self)
		return self
	end
	
	-- End stuff
	self.Element = windowElement
	
	self:SetTitle(windowConfig.Title, windowConfig.Version, windowConfig.Icon)
	table.insert(getgenv()._existingCatLibWindows, self)
	Drag.new(windowElement.Holder.MainFrame):Enable()
	return self
end

function CatLib:GetExistingWindows()
	return getgenv()._existingCatLibWindows
end

function CatLib:GetCoreGui()
	return CoreGui
end

return CatLib
