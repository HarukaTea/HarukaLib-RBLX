--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)


local HarukaListLayout = {}
HarukaListLayout.__index = HarukaListLayout



--// Constructor
function HarukaListLayout.new(listLayout: UIListLayout, props: {

})
    local self = setmetatable({}, HarukaListLayout)

    self.Add, self.Empty = HarukaLib.Bin()

    self.Layout = listLayout
    self.Container = self.Layout.Parent :: GuiObject

    self.Enabled = false

    return self
end


function HarukaListLayout:Enable()
    if self.Enabled then return end

    self.Enabled = true
    self.Layout.Parent = ServerStorage

    local symbol = Instance.new("BoolValue")
    symbol.Name = "HarukaListLayoutEnabled"
    symbol.Value = true
    symbol.Parent = self.Container

    self.Add(symbol)

    self.Add(self.Layout.Changed:Connect(function(property: string)
        if property == "Parent" then return end

        self:_Refresh()
    end))
    self.Add(self.Container.ChildAdded:Connect(function(child: GuiObject)
        self:_Refresh()

        child:GetPropertyChangedSignal("Visible"):Connect(function()
            self:_Refresh()
        end)
    end))
    self.Add(self.Container.ChildRemoved:Connect(function()
        self:_Refresh()
    end))

    self:_Refresh()
end


function HarukaListLayout:Disable()
    self.Layout.Parent = self.Container
    self.Empty()

    self.Enabled = false
end


function HarukaListLayout:Destroy()
    self:Disable()
    self = nil
end



--// Private Methods


function HarukaListLayout:_Refresh()
    local listLayout = self.Layout :: UIListLayout
    local container = self.Container :: GuiObject


    local elements = {}
    for _, element: GuiObject in container:GetChildren() do
        if element:IsA("GuiObject") then table.insert(elements, element) end
    end


    --- sort order
    if listLayout.SortOrder == Enum.SortOrder.LayoutOrder then
        table.sort(elements, function(a, b)
            return a.LayoutOrder < b.LayoutOrder
        end)
    elseif listLayout.SortOrder == Enum.SortOrder.Name then
        table.sort(elements, function(a, b)
            return a.Name < b.Name
        end)
    end


    --- apply anchor point
    local anchor = Vector2.zero
    if listLayout.HorizontalAlignment == Enum.HorizontalAlignment.Left then
        anchor = Vector2.new(0, anchor.Y)

    elseif listLayout.HorizontalAlignment == Enum.HorizontalAlignment.Center then
        anchor = Vector2.new(0.5, anchor.Y)

    elseif listLayout.HorizontalAlignment == Enum.HorizontalAlignment.Right then
        anchor = Vector2.new(1, anchor.Y)
    end
    if listLayout.VerticalAlignment == Enum.VerticalAlignment.Top then
        anchor = Vector2.new(anchor.X, 0)

    elseif listLayout.VerticalAlignment == Enum.VerticalAlignment.Center then
        anchor = Vector2.new(anchor.X, 0.5)

    elseif listLayout.VerticalAlignment == Enum.VerticalAlignment.Bottom then
        anchor = Vector2.new(anchor.X, 1)
    end

    for _, element: GuiObject in elements do
        element.AnchorPoint = anchor
    end


    --- remove non-visible elements
    for index: number, element: GuiObject in elements do
        if not element.Visible then table.remove(elements, index) end
    end


    --- apply position
    local X, Y = anchor.X, anchor.Y
    local offsetX, offsetY = 0, 0

    local containerAbsSize = container.AbsoluteSize
    local padding = listLayout.Padding
    local paddingX, paddingY = containerAbsSize.X * padding.Scale + padding.Offset, containerAbsSize.Y * padding.Scale + padding.Offset

    local quickTween = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    for i = 1, #elements do
        local element = elements[i] :: GuiObject
        local absSize = element.AbsoluteSize

        if listLayout.HorizontalAlignment == Enum.HorizontalAlignment.Center and listLayout.FillDirection == Enum.FillDirection.Horizontal then
            offsetX = ( (i - 1) - (#elements - 1) / 2 ) * (paddingX + absSize.X)
        end
        if listLayout.VerticalAlignment == Enum.VerticalAlignment.Center and listLayout.FillDirection == Enum.FillDirection.Vertical then
            offsetY = ( (i - 1) - (#elements - 1) / 2 ) * (paddingY + absSize.Y)
        end

        if element:GetAttribute("OldElement") then
            TS:Create(element, quickTween, { Position = UDim2.new(X, offsetX, Y, offsetY) }):Play()
        else
            element.Position = UDim2.fromScale(X, Y)
            element:SetAttribute("OldElement", true)

            TS:Create(element, quickTween, { Position = UDim2.new(X, offsetX, Y, offsetY) }):Play()
        end

        if listLayout.FillDirection == Enum.FillDirection.Horizontal then
            if listLayout.HorizontalAlignment == Enum.HorizontalAlignment.Center then
                continue
            end

            offsetX += absSize.X + paddingX

        elseif listLayout.FillDirection == Enum.FillDirection.Vertical then
            if listLayout.VerticalAlignment == Enum.VerticalAlignment.Center then
                continue
            end

            offsetY += absSize.Y + paddingY
        end
    end
end


return HarukaListLayout
