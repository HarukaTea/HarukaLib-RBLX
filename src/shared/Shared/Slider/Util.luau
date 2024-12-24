
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")

local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local module = {}

local function map(value: number, inMin: number, inMax: number, outMin: number, outMax: number): number
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

function module.round(n: number, places: number): number
	if places == 0 then return n end

	return math.round(n / places) * places
end

function module.roundToDecimalPlaces(n: number, places: number): number
	places = places or 2

	local factor = places * 100

	return math.round(n * factor) / factor
end

function module.getPositionTween(oldPosition: UDim2, gui: GuiObject, parent: GuiObject, desiredAnchor: Vector2): nil
	local parentSize = parent.AbsoluteSize
	local parentPosition = parent.AbsolutePosition
	local childSize = gui.AbsoluteSize
	local childPosition = gui.AbsolutePosition - parentPosition

	local correctionOffsetX = childSize.X * desiredAnchor.X
	local correctionOffsetY = childSize.Y * desiredAnchor.Y
	local correctedUDim2 = UDim2.fromScale(
		(childPosition.X + correctionOffsetX) / parentSize.X,
		(childPosition.Y + correctionOffsetY) / parentSize.Y
	)

	gui.AnchorPoint = desiredAnchor
	gui.Position = oldPosition

	return tweenService:Create(gui, tweenInfo, {Position = correctedUDim2})
end

function module.getMinimumAndMaximumPosition(slider: GuiObject, props: table): (number, number)
	local scale = (slider.AbsoluteSize.X) / (slider.Parent.AbsoluteSize.X)

	local minPosition_1 = props.canLeaveFrame and 0 or scale / 2
	local minPosition_2 = props.canFullyLeaveFrame and -scale / 2 or minPosition_1
	local maxPosition_1 = props.canLeaveFrame and 1 or 1 - scale / 2
	local maxPosition_2 = props.canFullyLeaveFrame and 1 + scale / 2 or maxPosition_1

	return minPosition_2, maxPosition_2
end

function module.getPercentageFromPosition(slider: GuiObject, position: UDim2, props: table): (number, number)
	local min, max = module.getMinimumAndMaximumPosition(slider, props)

	return map(position.X.Scale, min, max, 0, 1)
end

function module.getPlatform(): (string, string?)
	if (userInputService.TouchEnabled and not userInputService.MouseEnabled) then
		return "mobile", workspace.CurrentCamera.ViewportSize.Y > 600 and "tablet" or "phone"
	end

	return "desktop"
end

return module
