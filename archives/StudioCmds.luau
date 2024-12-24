
local UI = script:FindFirstAncestorOfClass("ScreenGui")
local desc = UI.CenterLeft.CardDesc.ItemDesc :: Frame

return function()
	local function _cal()
		local absSize = desc.AbsoluteSize.Y
		local absContentSize = desc.UIListLayout.AbsoluteContentSize.Y
		local absTextSize = desc.Parent.ItemName.ItemName.AbsoluteSize.Y

		desc.CanvasSize = if absContentSize > absSize then UDim2.fromOffset(0, absContentSize + 26) else UDim2.fromOffset(0, 0)
		desc.ScrollingEnabled = if absContentSize > absSize then true else false
		desc.Stats.TextSize = math.clamp(absTextSize / 1.1, 1, 33)

		script.Parent.Parent.CardDesc.DiceActionEffect.TextSize = math.clamp(absTextSize / 1.1, 1, 33)
		for _, effectLabel in desc:GetChildren() do
			if effectLabel.Name == "DiceActionEffect" then effectLabel.TextSize = math.clamp(absTextSize / 1.1, 1, 33) end
		end
	end
	_cal()

	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(_cal)
	desc.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(_cal)
end