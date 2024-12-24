
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local Add, Empty = HarukaLib.Bin()

local plr = Players.LocalPlayer
local mouse = plr:GetMouse()

local Util = require(script.Util)
local Signal = require(RepS.Shared.Signal)

local module = {}
module.__index = module

local DEFAULT_props = {
	step = 0.01,

	canLeaveFrame = true,
	canFullyLeaveFrame = false,
	moveToMouse = false,

	values = {
		min = 0,
		max = 1
	}
}

function module.new(slider: GuiObject, props: table): table
	props = props or DEFAULT_props

	for i, v in pairs(DEFAULT_props) do
		if props[i] then continue end
		props[i] = v
	end
	props.values.min = math.clamp(props.values.min, -math.huge, props.values.max)
	props.values.max = math.clamp(props.values.max, props.values.min, math.huge)

	props.defaultValue = props.defaultValue or (props.values.max + props.values.min) / 2
	props.defaultValue = math.clamp(props.defaultValue, props.values.min, props.values.max)

	local self = setmetatable({
		slider = slider,

		props = props,
		lastPosition = slider.Position,
		moved = Signal.new(),

		roundPercentage = props.step / (props.values.max - props.values.min),
	}, module)

	self:SetPosition(UDim2.fromScale(
		(props.defaultValue - props.values.min) / props.values.max, 0.5
		), false)

	return self
end

function module:Enable()
	local function getMousePosition(): (number, number)
		local position = Vector2.new(mouse.X, mouse.Y)

		return position.X, position.Y
	end
	local function move()
		if not self.isMouseDown then return end

		local mouseX, _ = getMousePosition()
		local x = (mouseX - self.slider.Parent.AbsolutePosition.X) / self.slider.Parent.AbsoluteSize.X or 0.5
		local y = 0.5

		self:SetPosition(UDim2.fromScale(x, y), false)
	end
	local function isMouseInside(canGoToMouseOnX: boolean, canGoToMouseOnY: boolean): boolean
		local x, y = getMousePosition()
		local _x, _y = self.slider.AbsolutePosition.X, self.slider.AbsolutePosition.Y
		local sizeX, sizeY = self.slider.AbsoluteSize.X, self.slider.AbsoluteSize.Y

		local isClickingAwayFromSliderOnX = x - _x > sizeX or x < _x
		local isClickingAwayFromSliderOnY = y - _y > sizeY or y < _y

		local isClickingAwayFromParentOnX = x - self.slider.Parent.AbsolutePosition.X > self.slider.Parent.AbsoluteSize.X or x < self.slider.Parent.AbsolutePosition.X
		local isClickingAwayFromParentOnY = y - self.slider.Parent.AbsolutePosition.Y > self.slider.Parent.AbsoluteSize.Y or y < self.slider.Parent.AbsolutePosition.Y

		if isClickingAwayFromParentOnX then return end
		if isClickingAwayFromParentOnY then return end
		if isClickingAwayFromSliderOnX and not canGoToMouseOnX then return end
		if isClickingAwayFromSliderOnY and not canGoToMouseOnY then return end

		return true
	end

	Add(mouse.Move:Connect(move))
	Add(UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		if not isMouseInside(true, false) then return end

		self.isMouseDown = true

		move()
	end))
	Add(UIS.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		self.isMouseDown = false
	end))
end

function module:Destroy()
	Empty()
end

function module:Reset()
	self:SetValue(self.props.defaultValue)
end

function module:SetPosition(position: UDim2, forced: boolean, frame: GuiObject?): nil
	frame = frame or self.slider
	position = UDim2.fromScale(
		Util.round(position.X.Scale, self.roundPercentage),
		Util.round(position.Y.Scale, self.roundPercentage)
	)

	local anchorPoint = frame.AnchorPoint
	local _position = frame.Position
	local min, max = Util.getMinimumAndMaximumPosition(frame, self.props, "X")

	position = UDim2.fromScale(
		math.clamp(position.X.Scale, min, max),
		math.clamp(position.Y.Scale, min, max)
	)

	frame.Position = position
	frame.AnchorPoint = Vector2.new(.5, .5)

	if frame == self.slider and self.tween then self.tween:Cancel() end

	self.tween = Util.getPositionTween(_position, frame, frame.Parent, anchorPoint)
	self.tween:Play()

	if frame == self.slider and position ~= self.lastPosition then
		self.tween.Completed:Wait()

		self.lastPosition = position
		self.moved:Fire(forced)
	end
end

function module:GetValue(): number
	local percentage = Util.getPercentageFromPosition(self.slider, self.lastPosition, self.props, "X")
	percentage = Util.round(percentage, self.roundPercentage)

	local value = self.props.values.min + (percentage * (self.props.values.max - self.props.values.min))
	value = math.clamp(value, self.props.values.min, self.props.values.max)

	return value
end

function module:SetValue(value: number)
	local percentage = math.abs(value - self.props.values.min) / math.abs(self.props.values.max - self.props.values.min)

	self:SetPosition(UDim2.fromScale(percentage, 0.5), true)
end

return module