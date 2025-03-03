--!nocheck

local HttpService = game:GetService("HttpService")
local RepS = game:GetService("ReplicatedStorage")

local Bindables = require(RepS.HarukaShared.Library.Bindables)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local Signal = require(RepS.HarukaShared.Shared.Signal)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local HarukaComponents = {}

local color3New, v2New, udNew = Color3.new, Vector2.new, UDim.new
local fromScale = UDim2.fromScale
local fromRGB = Color3.fromRGB
local fontFromName = Font.fromName

local WHITE_COLOR = fromRGB(236, 229, 216)
local BLACK_COLOR = fromRGB(28, 28, 37)

HarukaComponents.BLACK_COLOR = BLACK_COLOR
HarukaComponents.WHITE_COLOR = WHITE_COLOR

--// Init once only
local existingButtonElements = {}

local wait = task.wait

--// Helper functions

local function _trackMouseEnterLeaveEvents(scope: Fusion.Scope, button: GuiObject, hoverFunc: () -> nil, leaveFunc: () -> nil, clickFunc: () -> nil)

	local function _isButtonValid(screenGui: ScreenGui?) : boolean
		if not screenGui then return false end
		if not button.Visible then return false end

		return true
	end

	--local mouseEnter = Signal.new()
	local mouseLeave = Signal.new()
	local screenGui = button:FindFirstAncestorOfClass("ScreenGui")

	existingButtonElements[button:GetAttribute("HarukaUniqueId")] = {
		--MouseEnter = mouseEnter,
		MouseLeave = mouseLeave,
		UIObj = button,
		ScreenGuiObj = screenGui,
	}

	table.insert(scope, task.spawn(function()
		repeat wait() until button:FindFirstAncestorOfClass("ScreenGui")

		screenGui = button:FindFirstAncestorOfClass("ScreenGui")
		existingButtonElements[button:GetAttribute("HarukaUniqueId")].ScreenGuiObj = screenGui

		table.insert(scope, HarukaLib:Hydrate(screenGui, {
			["Prop-Enabled"] = function(state: boolean)
				if state == false then
					mouseLeave:Fire()
				end
			end
		}))
	end))


	mouseLeave:Connect(function()
		if not _isButtonValid(screenGui) then return end

		if leaveFunc then leaveFunc() end
	end)
	button.MouseEnter:Connect(function()
		if not _isButtonValid(screenGui) then return end
		if hoverFunc then hoverFunc() end

		for _, element: table in existingButtonElements do
			local thatButton = element.UIObj :: GuiObject
			if thatButton == button then continue end

			local thatScreenGui = element.ScreenGuiObj :: ScreenGui?
			if not thatScreenGui then continue end

			if thatScreenGui == screenGui then
				element.MouseLeave:Fire()
			end
		end
	end)
	button.MouseLeave:Connect(function()
		if not _isButtonValid(screenGui) then return end

		if leaveFunc then leaveFunc() end
	end)
	button.MouseButton1Click:Connect(function()
		if not screenGui or not screenGui.Enabled then return false end
		if not button.Visible then return false end


		if clickFunc then clickFunc() end
	end)
end
local function _reconcileProps(default: table, props: table)
	for prop: string, val: any in props do
		if prop == Fusion.Children and default[Fusion.Children] then
			table.insert(default[Fusion.Children], val)
			continue
		end

		default[prop] = val
	end
end
local function _createNewCompoent(scope: Fusion.Scope, props: table, uiType: string, default: table) : GuiObject
	_reconcileProps(default, props or {})

	return Fusion.New(scope, uiType)(default)
end

--[[
	Return a `ScreenGui` with haruka-style UI tree, without clips and insets
]]
function HarukaComponents.HarukaScreenGui(scope: Fusion.Scope, guiProps: table?, childProps: {
	TopProps: table?,
	CenterProps: table?,
	BottomProps: table?,
	FullProps: table?
}?) : ScreenGui

	childProps = childProps or {}

	local defaultTopProps = {
		Name = "Top",
		AnchorPoint = v2New(0.5, 0),
		Position = fromScale(0.5, 0),

		[Fusion.Children] = {}
	}
	local defaultCenterProps = {
		Name = "Center",

		[Fusion.Children] = {}
	}
	local defaultBottomProps = {
		Name = "Bottom",
		AnchorPoint = v2New(0.5, 1),
		Position = fromScale(0.5, 1),

		[Fusion.Children] = {}
	}
	local defaultFSProps = {
		Name = "Full",

		[Fusion.Children] = {}
	}
	_reconcileProps(defaultTopProps, childProps.TopProps or {})
	_reconcileProps(defaultCenterProps, childProps.CenterProps or {})
	_reconcileProps(defaultBottomProps, childProps.BottomProps or {})
	_reconcileProps(defaultFSProps, childProps.FullProps or {})


	return _createNewCompoent(scope, guiProps or {}, "ScreenGui", {
		ClipToDeviceSafeArea = false,
		ScreenInsets = Enum.ScreenInsets.None,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = true,

		[Fusion.Children] = {
			HarukaComponents.HarukaFrame(scope, defaultTopProps),
			HarukaComponents.HarukaFrame(scope, defaultCenterProps),
			HarukaComponents.HarukaFrame(scope, defaultBottomProps),
			HarukaComponents.Frame(scope, defaultFSProps)
		}
	})
end

--[[
	Return a transparent `Frame`, with a center anchor point, and max size
]]
function HarukaComponents.Frame(scope: Fusion.Scope, props: table) : Frame
	return _createNewCompoent(scope, props, "Frame", {
		AnchorPoint = v2New(0.5, 0.5),
		Position = fromScale(0.5, 0.5),
		Size = fromScale(1, 1),
		BackgroundColor3 = BLACK_COLOR,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
end

--[[
	Return a transparent `ScrollingFrame`, with max size, and `ClipsDescendants = true`
]]
function HarukaComponents.ScrollingFrame(scope: Fusion.Scope, props: table, listProps: table) : ScrollingFrame
	local absSize = Fusion.Value(scope, Vector2.zero)
	local absContentSize = Fusion.Value(scope, Vector2.zero)

	listProps = listProps or {
		Padding = UDim.new()
	}

	if listProps.Padding ~= nil then --- UIListLayout
		listProps[Fusion.Out("AbsoluteContentSize")] = absContentSize

		table.insert(props[Fusion.Children], 1, HarukaComponents.UIListLayout(scope, listProps))

	elseif listProps.CellPadding ~= nil then --- UIGridLayout
		listProps[Fusion.Out("AbsoluteContentSize")] = absContentSize

		table.insert(props[Fusion.Children], 1, HarukaComponents.UIGridLayout(scope, listProps))
	end

	return _createNewCompoent(scope, props, "ScrollingFrame", {
		BackgroundColor3 = BLACK_COLOR,
		BackgroundTransparency = 1,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = color3New(1, 1, 1),
		BorderSizePixel = 0,
		Size = fromScale(1, 1),

		CanvasSize = Fusion.Computed(scope, function(use: Fusion.Use, _)
			return if use(absContentSize).Y > use(absSize).Y then UDim2.fromOffset(0, use(absContentSize).Y + 15.99) else UDim2.fromOffset(0, 0)
		end),
		ScrollingEnabled = Fusion.Computed(scope, function(use: Fusion.Use, _)
			return if use(absContentSize).Y > use(absSize).Y then true else false
		end),

		[Fusion.Out("AbsoluteSize")] = absSize,
		[Fusion.Children] = {}
	})
end

--[[
	Return a transparent `TextLabel`, with SourceSansPro bold font, white color
]]
function HarukaComponents.TextLabel(scope: Fusion.Scope, props: table) : TextLabel
	return _createNewCompoent(scope, props, "TextLabel", {
		BackgroundColor3 = BLACK_COLOR,
		BackgroundTransparency = 1,
		FontFace = Font.fromName("SourceSansPro", Enum.FontWeight.Bold),
		TextScaled = true,
		TextColor3 = WHITE_COLOR,
		TextStrokeColor3 = color3New(),
		TextStrokeTransparency = 1,
		BorderSizePixel = 0,
		Size = fromScale(1, 1),
	})
end

--[[
	Return a `TextBox`, with SourceSansPro bold font, white color
]]
function HarukaComponents.TextBox(scope: Fusion.Scope, props: table) : TextBox
	return _createNewCompoent(scope, props, "TextBox", {
		BackgroundColor3 = BLACK_COLOR,
		ClearTextOnFocus = false,
		FontFace = fontFromName("SourceSansPro", Enum.FontWeight.Bold),
		PlaceholderText = "",
		PlaceholderColor3 = fromRGB(159, 159, 159),
		Text = "",
		TextColor3 = WHITE_COLOR,
		TextScaled = true,
		BorderSizePixel = 0,
		Size = fromScale(1, 1),
	})
end

--[[
	Return an empty transparent `ImageLabel`, with full size
]]
function HarukaComponents.ImageLabel(scope: Fusion.Scope, props: table) : ImageLabel
	return _createNewCompoent(scope, props, "ImageLabel", {
		BackgroundColor3 = color3New(),
		BackgroundTransparency = 1,
		Image = "",
		BorderSizePixel = 0,
		Size = fromScale(1, 1),
	})
end

--[[
	A quick component to create a `Icon` for critical style
]]
function HarukaComponents.IconImageLabel(scope: Fusion.Scope, props: table) : ImageLabel
	local defaultProps = {
		Name = "Icon",
		BackgroundTransparency = 0,
		Image = "",
		SizeConstraint = Enum.SizeConstraint.RelativeYY,

		[Fusion.Children] = {
			HarukaComponents.RoundUICorner(scope)
		}
	}
	_reconcileProps(defaultProps, props or {})


	return HarukaComponents.ImageLabel(scope, defaultProps)
end

--[[
	Return a clickable empty transparent `ImageButton`, but with center anchor and full size
]]
function HarukaComponents.HoverImageButton(scope: Fusion.Scope, props: table) : ImageButton
	local hoverFunc, leaveFunc, clickFunc =
		props[Fusion.OnEvent("MouseEnter")], props[Fusion.OnEvent("MouseLeave")], props[Fusion.OnEvent("MouseButton1Click")]


	props[Fusion.OnEvent("MouseButton1Click")] = nil
	props[Fusion.OnEvent("MouseEnter")] = nil
	props[Fusion.OnEvent("MouseLeave")] = nil


	local uniqueId = HttpService:GenerateGUID(false)
	local button = _createNewCompoent(scope, props, "ImageButton", {
		Name = "Hover",
		BackgroundColor3 = color3New(),
		BackgroundTransparency = 1,
		AnchorPoint = v2New(0.5, 0.5),
		Position = fromScale(0.5, 0.5),
		Size = fromScale(1, 1),
		Image = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,

		[Fusion.Attribute("HarukaUniqueId")] = uniqueId
	})

	_trackMouseEnterLeaveEvents(scope, button, hoverFunc, leaveFunc, clickFunc)

	table.insert(scope, existingButtonElements[uniqueId])
	table.insert(scope, function()
		existingButtonElements[uniqueId] = nil
	end)

	return button
end

--[[
	Return a clickable `TextButton`, with SourceSansPro bold font, and black background
]]
function HarukaComponents.TextButton(scope: Fusion.Scope, props: table) : TextButton
	local hoverFunc, leaveFunc, clickFunc =
		props[Fusion.OnEvent("MouseEnter")], props[Fusion.OnEvent("MouseLeave")], props[Fusion.OnEvent("MouseButton1Click")]


	props[Fusion.OnEvent("MouseButton1Click")] = nil
	props[Fusion.OnEvent("MouseEnter")] = nil
	props[Fusion.OnEvent("MouseLeave")] = nil

	local uniqueId = HttpService:GenerateGUID(false)
	local button = _createNewCompoent(scope, props, "TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = BLACK_COLOR,
		FontFace = Font.fromName("SourceSansPro", Enum.FontWeight.Bold),
		TextColor3 = WHITE_COLOR,
		TextScaled = true,
		BorderSizePixel = 0,
		TextStrokeColor3 = BLACK_COLOR,
		TextStrokeTransparency = 1,
		Size = fromScale(1, 1),

		[Fusion.Attribute("HarukaUniqueId")] = uniqueId
	})

	_trackMouseEnterLeaveEvents(scope, button, hoverFunc, leaveFunc, clickFunc)

	table.insert(scope, existingButtonElements[uniqueId])
	table.insert(scope, function()
		existingButtonElements[uniqueId] = nil
	end)

	return button
end

--[[
	Return a border `UIStroke`, with white color
]]
function HarukaComponents.UIStroke(scope: Fusion.Scope, props: table) : UIStroke
	return _createNewCompoent(scope, props, "UIStroke", {
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = WHITE_COLOR,
		Transparency = 0
	})
end

--[[
	Same as `HarukaComponents.UIStroke`, but it's black and usually used for text
]]
function HarukaComponents.TextUIStroke(scope: Fusion.Scope, props: table) : UIStroke
	return _createNewCompoent(scope, props, "UIStroke", {
		Thickness = 1,
		Transparency = 0,
	})
end

--[[
	Return a roundify `UICorner`
]]
function HarukaComponents.RoundUICorner(scope: Fusion.Scope) : UICorner
	return Fusion.New(scope, "UICorner")({ CornerRadius = udNew(0.5, 0) })
end

--[[
	Return a `UIPadding` with 0.1 scale of every direction
]]
function HarukaComponents.UIPadding(scope: Fusion.Scope, props: table) : UIPadding
	return _createNewCompoent(scope, props, "UIPadding", {
		PaddingTop = udNew(0.1, 0),
		PaddingBottom = udNew(0.1, 0),
		PaddingLeft = udNew(0.1, 0),
		PaddingRight = udNew(0.1, 0)
	})
end

--[[
	A quick shortcut to `UIAspectRatioConstraint`
]]
function HarukaComponents.UIAspectRatioConstraint(scope: Fusion.Scope, aspect: number?) : UIAspectRatioConstraint
	return _createNewCompoent(scope, { AspectRatio = aspect or 25.627 }, "UIAspectRatioConstraint", {
		AspectRatio = 25.627
	})
end

--[[
	Return a `UIListLayout` with `LayoutOrder` sort style
]]
function HarukaComponents.UIListLayout(scope: Fusion.Scope, props: table) : UIListLayout
	return _createNewCompoent(scope, props, "UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = udNew(0, 0)
	})
end

--[[
	Return a `UIGridLayout` with `SortOrder` sort style
]]
function HarukaComponents.UIGridLayout(scope: Fusion.Scope, props: table) : UIGridLayout
	return _createNewCompoent(scope, props, "UIGridLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		StartCorner = Enum.StartCorner.TopLeft,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})
end


--[[
	Return a padding frame for scrolling frame, usually used for `HarukaUI`
]]
function HarukaComponents.PaddingFrame(scope: Fusion.Scope, name: string) : Frame
	return HarukaComponents.Frame(scope, {
		Name = name,
		Size = UDim2.fromOffset(1, 1),
		LayoutOrder = if name == "AAA" then 0 else 9999
	})
end

--[[
	Return a `Haruka-style Frame`, usually used for `HarukaUI`
]]
function HarukaComponents.HarukaFrame(scope: Fusion.Scope, props: table) : Frame
	table.insert(props[Fusion.Children], 1, HarukaComponents.UIAspectRatioConstraint(scope))

	props.Size = UDim2.fromScale(1, 0.1)

	return HarukaComponents.Frame(scope, props)
end

--[[
	Return a default `BillboardGui`, with no light influence, and no clipping, always on top
]]
function HarukaComponents.BillboardGui(scope: Fusion.Scope, props: table) : BillboardGui
	return _createNewCompoent(scope, props, "BillboardGui", {
		LightInfluence = 0,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ClipsDescendants = false,
		AlwaysOnTop = true,
		ResetOnSpawn = false,
		Active = true
	})
end

--[[
	Return a `BlurEffect` for UIFXs only
]]
function HarukaComponents.BlurFS(scope: Fusion.Scope, props: table) : BlurEffect
	return _createNewCompoent(scope, props, "BlurEffect", {
		Enabled = true,
		Name = "UIBlur"
	})
end


--[[
	Return a default `ViewportFrame` with haruka style in it
]]
function HarukaComponents.ViewportFrame(scope: Fusion.Scope, props: table) : ViewportFrame
	return _createNewCompoent(scope, props, "ViewportFrame", {
		Ambient = WHITE_COLOR,
		LightColor = WHITE_COLOR,
		LightDirection = Vector3.xAxis * -1,
		BackgroundColor3 = BLACK_COLOR,
		BackgroundTransparency = 1,
	})
end


--[[
	Create a confirm prompt temporary UI
]]
function HarukaComponents:CreateConfirmPrompt(data: {
	Hint: string,
	ConfirmText: string,
	CancelText: string,

	ConfirmUniqueId: stringcon
})
	local scope = {}
	local waitSignal = Signal.new()
	table.insert(scope, waitSignal)

	table.insert(scope, Bindables.ConfirmPromptChosen:Connect(function(uniqueId: string, result: "YES" | "NO")
		if uniqueId ~= data.ConfirmUniqueId then return end

		waitSignal:Fire(result)

		Fusion.doCleanup(scope)
	end))

	Bindables.CreateConfirmPrompt:Fire(data)

	return waitSignal
end


--[[
	For internal use only
]]
function HarukaComponents:_GetAllExistingButtonElements() : {
	[string]: {
		MouseLeave: RBXScriptSignal,
		UIObj: GuiObject,
		ScreenGuiObj: ScreenGui,
	}
}
	return existingButtonElements
end




return table.freeze(HarukaComponents)
