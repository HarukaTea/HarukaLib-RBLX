--!nocheck

--// Inspired by AGLModule in devforum, modified to fit my needs.

local RepS = game:GetService("ReplicatedStorage")
local TestS = game:GetService("TestService")
local TS = game:GetService("TweenService")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Signal = require(RepS.HarukaShared.Shared.Signal)


local AGL = {}
AGL.__index = AGL

--// Helper functions

local function _scaleToOffset(udim2: UDim2, parent: GuiObject) : Vector2
    local absSize = parent.AbsoluteSize

    local x = udim2.X.Offset + absSize.X * udim2.X.Scale
    local y = udim2.Y.Offset + absSize.Y * udim2.Y.Scale

    return Vector2.new(x, y)
end


--// Constructor
function AGL.new(gridLayout: UIGridLayout | UIListLayout, exProp: {
    StartCorner: Enum.StartCorner?,
    ForceSize: boolean?,

    CellSize: UDim2
}?)

    exProp = exProp or {}

    if gridLayout:IsA("UIListLayout") then
        local tempGridLayout = Instance.new("UIGridLayout")

        local padding = gridLayout.Padding
        tempGridLayout.CellPadding = UDim2.new(padding.Scale, padding.Offset, padding.Scale, padding.Offset)

        tempGridLayout.CellSize = exProp.CellSize
        tempGridLayout:SetAttribute("ForceSize", exProp.ForceSize or true)

        tempGridLayout:SetAttribute("ReversedFillDirection", true)

        tempGridLayout.FillDirection = gridLayout.FillDirection
        tempGridLayout.FillDirectionMaxCells = 1
        tempGridLayout.SortOrder = gridLayout.SortOrder
        tempGridLayout.StartCorner = exProp.StartCorner or Enum.StartCorner.TopLeft

        tempGridLayout.HorizontalAlignment = gridLayout.HorizontalAlignment
        tempGridLayout.VerticalAlignment = gridLayout.VerticalAlignment

        tempGridLayout.Parent = gridLayout.Parent

        gridLayout.Parent = TestS
        gridLayout = tempGridLayout
    else
        gridLayout:SetAttribute("ForceSize", exProp.ForceSize or true)
    end

    local self = setmetatable({
        UIGridLayout = gridLayout,
        Container = gridLayout.Parent :: Frame,

        CellPadding = gridLayout.CellPadding,
        CellSize = gridLayout.CellSize,

        FillDirection = gridLayout.FillDirection,
        FillDirectionMaxCells = gridLayout.FillDirectionMaxCells,
        SortOrder = gridLayout.SortOrder,
        StartCorner = gridLayout.StartCorner,

        HorizontalAlignment = gridLayout.HorizontalAlignment,
        VerticalAlignment = gridLayout.VerticalAlignment,

        GridPositionChanged = Signal.new(),
        GridCellInserted = Signal.new(),

        AbsoluteCellCount = gridLayout.AbsoluteCellCount,
        AbsoluteCellSize = gridLayout.AbsoluteCellSize,
        AbsoluteContentSize = gridLayout.AbsoluteContentSize,


        ForceSize = gridLayout:GetAttribute("ForceSize"),

    }, AGL)

    if gridLayout:GetAttribute("ReversedFillDirection") then
        self.ReversedFillDirection = if self.FillDirection == Enum.FillDirection.Horizontal then
            Enum.FillDirection.Vertical
        else
            Enum.FillDirection.Horizontal
    end

    self.Add, self.Empty = HarukaLib.Bin()

    self.UIGridLayout.Parent = TestS
    self.Inited = false

    local symbol = Instance.new("BoolValue")
    symbol.Name = "AnimatedLayout_Symbol"
    symbol.Parent = self.Container

    self.Symbol = symbol

    self.Add(self.Symbol)
    self.Add(self.GridCellInserted)
    self.Add(self.GridPositionChanged)

    self.Add(self.UIGridLayout.Changed:Connect(function(property: string)
        if property == "Parent" then return end

        self[property] = self.UIGridLayout[property]
        self:Refresh()
    end))
    self.Add(self.Container.ChildAdded:Connect(function()
        self:Refresh()
    end))
    self.Add(self.Container.ChildRemoved:Connect(function()
        self:Refresh()
    end))

    return self
end


--[[
    Recalculate all the cells in the grid
]]
function AGL:Refresh()
    local elements = self.Container:GetChildren()
    for i = #elements, 1, -1 do
        if not elements[i]:IsA("GuiObject") or elements[i].Parent ~= self.Container then
            table.remove(elements, i)
        end
    end

    local absCellPadding = _scaleToOffset(self.CellPadding, self.Container)
    local absCellSize = _scaleToOffset(self.CellSize, self.Container)
    local absCellTotalSize = absCellSize + absCellPadding
    local absContentPosition = Vector2.zero

    local maxPrimaryAxisCellCount = 0
    local maxSecondaryAxisCellCount = 0
    local absCellCount = Vector2.zero
    local absContentSize = Vector2.zero

    --// Super complex algorithm???
    local finalDirection = self.ReversedFillDirection or self.FillDirection
    if self.FillDirection == Enum.FillDirection.Horizontal then
        if self.Container.AbsoluteSize.X % absCellTotalSize.X >= absCellSize.X then
            maxPrimaryAxisCellCount = math.max(1, math.ceil(self.Container.AbsoluteSize.X / absCellTotalSize.X))
        else
            maxPrimaryAxisCellCount = math.max(1, math.floor(self.Container.AbsoluteSize.X / absCellTotalSize.X))
        end

    elseif self.FillDirection == Enum.FillDirection.Vertical then
        if self.Container.AbsoluteSize.Y % absCellTotalSize.Y >= absCellSize.Y then
            maxPrimaryAxisCellCount = math.max(1, math.ceil(self.Container.AbsoluteSize.Y / absCellTotalSize.Y))
        else
            maxPrimaryAxisCellCount = math.max(1, math.floor(self.Container.AbsoluteSize.Y / absCellTotalSize.Y))
        end
    end

    if self.FillDirectionMaxCells > 0 then
        maxPrimaryAxisCellCount = math.clamp(self.FillDirectionMaxCells, 1, maxPrimaryAxisCellCount)
        maxSecondaryAxisCellCount = math.ceil(#elements / maxPrimaryAxisCellCount)
    end

    if finalDirection == Enum.FillDirection.Horizontal then
        absCellCount = Vector2.new(maxPrimaryAxisCellCount, maxSecondaryAxisCellCount)
        absContentSize = Vector2.new(
            maxPrimaryAxisCellCount * absCellTotalSize.X - absCellPadding.X,
            maxSecondaryAxisCellCount * absCellTotalSize.Y - absCellPadding.Y
        )

    elseif finalDirection == Enum.FillDirection.Vertical then
        absCellCount = Vector2.new(maxSecondaryAxisCellCount, maxPrimaryAxisCellCount)
        absContentSize = Vector2.new(
            maxSecondaryAxisCellCount * absCellTotalSize.X - absCellPadding.X,
            maxPrimaryAxisCellCount * absCellTotalSize.Y - absCellPadding.Y
        )
    end


    if self.HorizontalAlignment == Enum.HorizontalAlignment.Left then
        absContentPosition = Vector2.new(0, absContentPosition.Y)

    elseif self.HorizontalAlignment == Enum.HorizontalAlignment.Right then
        absContentPosition = Vector2.new(self.Container.AbsoluteSize.X - absContentSize.X, absContentPosition.Y)

    elseif self.HorizontalAlignment == Enum.HorizontalAlignment.Center then
        if absCellCount.X % 2 == 0 then
            absContentPosition = Vector2.new(
                math.floor( (self.Container.AbsoluteSize.X - absContentSize.X) / 2 ),
                absContentPosition.Y
            )
        else
            absContentPosition = Vector2.new(
                math.ceil( (self.Container.AbsoluteSize.X - absContentSize.X) / 2 ),
                absContentPosition.Y
            )
        end
    end


    if self.VerticalAlignment == Enum.VerticalAlignment.Top then
        absContentPosition = Vector2.new(absContentPosition.X, 0)

    elseif self.VerticalAlignment == Enum.VerticalAlignment.Bottom then
        absContentPosition = Vector2.new(absContentPosition.X, self.Container.AbsoluteSize.Y - absContentSize.Y)

    elseif self.VerticalAlignment == Enum.VerticalAlignment.Center then
        if absCellCount.Y % 2 == 0 then
            absContentPosition = Vector2.new(
                absContentPosition.X,
                math.ceil( (self.Container.AbsoluteSize.Y - absContentSize.Y) / 2 )
            )
        else
            absContentPosition = Vector2.new(
                absContentPosition.X,
                math.floor( (self.Container.AbsoluteSize.Y - absContentSize.Y) / 2 )
            )
        end
    end


    if self.SortOrder == Enum.SortOrder.LayoutOrder then
        table.sort(elements, function(a, b)
            return a.LayoutOrder < b.LayoutOrder
        end)
    else
        table.sort(elements, function(a, b)
            return a.Name < b.Name
        end)
    end


    --// Applying calculated properties to the grid layout
    if self.ForceSize then
        for _, element: GuiObject in elements do
            element.Size = self.CellSize
        end
    end

    local elementPos = {}
    for i = 0, #elements - 1 do
        local element = elements[i + 1] :: GuiObject

        local offset = UDim2.fromOffset(0, 0)

        if element.AbsoluteSize.X % 2 == 0 then
            offset = UDim2.fromOffset(
                math.ceil(element.AnchorPoint.X * absCellSize.X), 0
            )
        else
            offset = UDim2.fromOffset(
                math.floor(element.AnchorPoint.X * absCellSize.X), 0
            )
        end
        if element.AbsoluteSize.Y % 2 == 0 then
            offset = UDim2.fromOffset(offset.X.Offset, math.floor(element.AnchorPoint.Y * absCellSize.Y))
        else
            offset = UDim2.fromOffset(offset.X.Offset, math.ceil(element.AnchorPoint.Y * absCellSize.Y))
        end


        local X, Y = 0, 0
        if self.StartCorner == Enum.StartCorner.TopLeft then
			if finalDirection == Enum.FillDirection.Horizontal then
				X = absContentPosition.X + i % maxPrimaryAxisCellCount * absCellTotalSize.X
				Y = absContentPosition.Y + math.floor(i / maxPrimaryAxisCellCount) * absCellTotalSize.Y

			elseif finalDirection == Enum.FillDirection.Vertical then
				X = absContentPosition.X + math.floor(i / maxPrimaryAxisCellCount) * absCellTotalSize.X
				Y = absContentPosition.Y + i % maxPrimaryAxisCellCount * absCellTotalSize.Y
			end

		elseif self.StartCorner == Enum.StartCorner.BottomLeft then
			if finalDirection == Enum.FillDirection.Horizontal then
				X = absContentPosition.X + i % maxPrimaryAxisCellCount * absCellTotalSize.X
				Y = absContentPosition.Y + absContentSize.Y - absCellSize.Y - math.floor(i / maxPrimaryAxisCellCount) * absCellTotalSize.Y

            elseif finalDirection == Enum.FillDirection.Vertical then
				X = absContentPosition.X + math.floor(i / maxPrimaryAxisCellCount) * absCellTotalSize.X
				Y = absContentPosition.Y + absContentSize.Y - absCellSize.Y - i % maxPrimaryAxisCellCount * absCellTotalSize.Y
			end

		elseif self.StartCorner == Enum.StartCorner.TopRight then
			if finalDirection == Enum.FillDirection.Horizontal then
				X = absContentPosition.X + absContentSize.X - absCellSize.X - i % maxPrimaryAxisCellCount * absCellTotalSize.X
				Y = absContentPosition.Y + math.floor(i / maxPrimaryAxisCellCount) * absCellTotalSize.Y

            elseif finalDirection == Enum.FillDirection.Vertical then
				X = absContentPosition.X + absContentSize.X - absCellSize.X - math.floor(i / maxPrimaryAxisCellCount) * absCellTotalSize.X
				Y = absContentPosition.Y + i % maxPrimaryAxisCellCount * absCellTotalSize.Y
			end

		elseif self.StartCorner == Enum.StartCorner.BottomRight then
			if finalDirection == Enum.FillDirection.Horizontal then
				X = absContentPosition.X + absContentSize.X - absCellSize.X - i % maxPrimaryAxisCellCount * absCellTotalSize.X
				Y = absContentPosition.Y + absContentSize.Y - absCellSize.X - math.floor(i / maxPrimaryAxisCellCount) * absCellTotalSize.Y

            elseif finalDirection == Enum.FillDirection.Vertical then
				X = absContentPosition.X + absContentSize.X - absCellSize.X - math.floor(i / maxPrimaryAxisCellCount) * absCellTotalSize.X
				Y = absContentPosition.Y + absContentSize.Y - absCellSize.Y - i % maxPrimaryAxisCellCount * absCellTotalSize.Y
			end
		end

        local finalPosition = UDim2.fromOffset(X, Y) + offset
        local quickTween = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

        local function __createTween()
            if #elements > 1 then
                TS:Create(element, quickTween, { Position = finalPosition }):Play()
            else
                element.Position = finalPosition
            end
        end
        if self.PreviousData then
            if not self.PreviousData.ElementPos[element] then
                self.GridCellInserted:Fire(element, finalPosition)
            end

            __createTween()
        else
            __createTween()
        end

        elementPos[element] = finalPosition
    end

    if not self.Inited then
        self.Inited = true
    end

    self.PreviousData = {
        ElementPos = elementPos,
    }

    self.AbsoluteCellCount = absCellCount
    self.AbsoluteCellSize = _scaleToOffset(self.CellSize, self.Container)
    self.AbsoluteContentSize = absContentSize
end


--[[
    Clear the AGL module, and return to its initial state.
]]
function AGL:Destroy()
    if self.UIGridLayout then
        self.UIGridLayout.Parent = self.Container
    end
    self.Empty()

    self = nil
end


return table.freeze(AGL)
