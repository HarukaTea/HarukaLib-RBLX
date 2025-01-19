--!nocheck

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local RepS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")


local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Signal = require(RepS.HarukaShared.Shared.Signal)

local Slider = {}
Slider.__index = Slider

export type Props = {
    Step: number,
    CanLeaveFrame: boolean,
    MoveToMouse: boolean,

    MinVal: number,
    MaxVal: number
}


--// Helper functions

local function _map(val: number, inMin: number, inMax: number, outMin: number, outMax: number) : number
    return (val - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function _round(n: number, places: number): number
    if places == 0 then return n end

    return math.round(n / places) * places
end

local function _getMinAndMaxPos(sliderElement: GuiObject, props: Props): (number, number)
    local scale = sliderElement.AbsoluteSize.X / sliderElement.Parent.AbsoluteSize.X

    local minPos1 = if props.CanLeaveFrame then 0 else scale / 2
    local maxPos1 = if props.CanLeaveFrame then 1 else 1 - scale / 2

    return minPos1, maxPos1
end

local function _getDecentTween(oldPos: UDim2, sliderElement: GuiObject, sliderElementParent: GuiObject, desiredAnchor: Vector2)
    local parentSize, parentPos = sliderElementParent.AbsoluteSize, sliderElementParent.AbsolutePosition
    local sliderSize, sliderPos = sliderElement.AbsoluteSize, sliderElement.AbsolutePosition - parentPos

    local correctOffsetX, correctOffsetY = sliderSize.X * desiredAnchor.X, sliderSize.Y * desiredAnchor.Y
    local correctPos = UDim2.fromScale(
        (sliderPos.X + correctOffsetX) / parentSize.X,
        (sliderPos.Y + correctOffsetY) / parentSize.Y
    )

    sliderElement.AnchorPoint = desiredAnchor
    sliderElement.Position = oldPos

    return TS:Create(sliderElement, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = correctPos
    })
end

local function _getPercentageFromPos(sliderElement: GuiObject, pos: UDim2, props: Props): (number, number)
    local minPos, maxPos = _getMinAndMaxPos(sliderElement, props)

    return _map(pos.X.Scale, minPos, maxPos, 0, 1)
end


function Slider.new(element: GuiObject, props: Props?) : table

    props = props or {}

    local finalProps = {
        Step = props.Step or 0.01,
        CanLeaveFrame = props.CanLeaveFrame or true,
        MoveToMouse = props.MoveToMouse or false,

        MinVal = props.MinVal or 0,
        MaxVal = props.MaxVal or 1,
    }
    finalProps.DefaultVal = props.DefaultVal or (finalProps.MaxVal + finalProps.MinVal) / 2

    local self = setmetatable({
        SliderElement = element,
        Props = finalProps,

        RoundPercentage = finalProps.Step / (finalProps.MaxVal - finalProps.MinVal),
        SliderMoved = Signal.new()


    }, Slider)

    self.Add, self.Empty = HarukaLib.Bin()
    self.Add(self.SliderMoved)

    self:SetVal(finalProps.DefaultVal)

    return self
end


--[[
    Enable the slider and track the movement.
]]
function Slider:Enable()
    local mouse = Players.LocalPlayer:GetMouse()

    local function __getMousePos() : (number, number)
        local pos = Vector2.new(mouse.X, mouse.Y)

        return pos.X, pos.Y
    end
    local function _move()
        if not self.IsMouseDown then return end

        local mouseX, mouseY = __getMousePos()
        local X = (mouseX - self.SliderElement.Parent.AbsolutePosition.X) / self.SliderElement.Parent.AbsoluteSize.X or 0.5
        local Y = 0.5

        self:SetPosition(UDim2.fromScale(X, Y), false)
    end
    local function _isMouseInsideSlider() : boolean
        local mouseX, mouseY = __getMousePos()

        local sliderParentX, sliderParentY = self.SliderElement.Parent.AbsolutePosition.X, self.SliderElement.Parent.AbsolutePosition.Y
        local sliderParentSizeX, sliderParentSizeY = self.SliderElement.Parent.AbsoluteSize.X, self.SliderElement.Parent.AbsoluteSize.Y

        local isClickingOnSliderParentX = mouseX - sliderParentX > sliderParentSizeX or mouseX < sliderParentX
        local isClickingOnSliderParentY = mouseY - sliderParentY > sliderParentSizeY or mouseY < sliderParentY

        if isClickingOnSliderParentX then return end
        if isClickingOnSliderParentY then return end

        return true
    end

    self.Add(mouse.Move:Connect(_move))
    self.Add(UIS.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        if not _isMouseInsideSlider() then return end

        self.IsMouseDown = true

        _move()
    end))
    self.Add(UIS.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        self.IsMouseDown = false
    end))
end


--[[
    Disable the slider and stop tracking the movement.
]]
function Slider:Destroy()
    self.Empty()
end


--[[
    Get current value of the slider.
]]
function Slider:GetVal() : number
    local percentage = _getPercentageFromPos(self.SliderElement, self.LastPos, self.Props)
    percentage = _round(percentage, self.RoundPercentage)

    local val = self.Props.MinVal + (percentage * (self.Props.MaxVal - self.Props.MinVal))
    val = math.clamp(val, self.Props.MinVal, self.Props.MaxVal)

    return val
end


--[[
    Set the value of the slider.
]]
function Slider:SetVal(val: number)
    local percentage = math.abs(val - self.Props.MinVal) / math.abs(self.Props.MaxVal - self.Props.MinVal)

    self:SetPosition(UDim2.fromScale(percentage, 0.5), true)
end


--// Private functions

function Slider:SetPosition(pos: UDim2, isForced: boolean, element: GuiObject?)
    element = element or self.SliderElement

    pos = UDim2.fromScale(_round(pos.X.Scale, self.RoundPercentage), _round(pos.Y.Scale, self.RoundPercentage))

    local elementAnchor, elementPos = element.AnchorPoint, element.Position
    local minPos, maxPos = _getMinAndMaxPos(element, self.Props)

    pos = UDim2.fromScale(math.clamp(pos.X.Scale, minPos, maxPos), math.clamp(pos.Y.Scale, minPos, maxPos))

    element.Position = pos
    element.AnchorPoint = Vector2.new(0.5, 0.5)


    if element == self.SliderElement and self.TweenObject then self.TweenObject:Cancel() end

    self.TweenObject = _getDecentTween(elementPos, element, element.Parent, elementAnchor)
    self.TweenObject:Play()

    if element == self.SliderElement and pos ~= self.LastPos then
        self.TweenObject.Completed:Wait()

        self.LastPos = pos
        self.SliderMoved:Fire(isForced)
    end
end



return Slider