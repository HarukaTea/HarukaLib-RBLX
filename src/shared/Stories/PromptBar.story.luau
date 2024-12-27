
local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local UILab = require(RepS.HarukaShared.Shared.UILabs)

local Children = Fusion.Children

local fromScale = UDim2.fromScale
local v2New = Vector2.new

return UILab.CreateFusionStory({
    fusion = Fusion,
    controls = {
        CurrentPromptIndex = UILab.Slider(1, 1, 2, 1),
        ActionText = "Interact",

        Platform = UILab.Choose({ "PC", "Mobile", "Console" })
    },

}, function(props)
    local scope = props.scope

    props.LayoutOrder = 1
    props.PromptObject = Instance.new("ProximityPrompt")

    props.PromptObject.KeyboardKeyCode = Enum.KeyCode.F

    local component = Components.Frame(scope, {
        Name = "Prompt",
        BackgroundTransparency = 0,
        Size = fromScale(0.18, 0.1),
        LayoutOrder = props.controls.LayoutOrder,
        Parent = props.target,

        BackgroundColor3 = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use)
            return if use(props.controls.CurrentPromptIndex) == props.LayoutOrder then Color3.new(1, 1, 1) else Color3.new()
        end), TweenInfo.new(0.2)),

        [Children] = {
            Components.RoundUICorner(scope),

			Fusion.New(scope, "UIGradient")({
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.5, 0.2),
					NumberSequenceKeypoint.new(1, 1)
				})
			}),

            Components.ImageLabel(scope, {
                Name = "Icon",
				Position = UDim2.fromScale(0.05, 0.5),
				Size = UDim2.fromScale(0.7, 0.7),
				AnchorPoint = Vector2.new(0, 0.5),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Image = "rbxassetid://13124035950",

                ImageColor3 = Fusion.Computed(scope, function(use: Fusion.Use)
                    return if use(props.controls.CurrentPromptIndex) == props.LayoutOrder then Color3.new() else Color3.new(1, 1, 1)
                end),
            }),
            Components.TextLabel(scope, {
                Name = "PromptText",
                AnchorPoint = v2New(0, 0.5),
                Position = fromScale(0.19, 0.5),
                Size = fromScale(0.77, 0.7),
                Text = props.controls.ActionText,
		        TextXAlignment = Enum.TextXAlignment.Left,

                TextColor3 = Fusion.Computed(scope, function(use: Fusion.Use)
                    return if use(props.controls.CurrentPromptIndex) == props.LayoutOrder then Color3.new() else Color3.new(1, 1, 1)
                end),
            }),
            Components.HoverImageButton(scope, {
                [Fusion.OnEvent("MouseButton1Click")] = function()
                    props.PromptObject:InputHoldBegin()
                end
            }),

            Components.ImageLabel(scope, {
                Name = "PressIcon",
                Position = UDim2.fromScale(-0.18, 0.5),
                Size = UDim2.fromScale(0.8, 0.8),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                AnchorPoint = Vector2.new(0, 0.5),
                Image = "rbxassetid://118166707173137",

                Visible = Fusion.Computed(scope, function(use: Fusion.Use)
                    return use(props.controls.CurrentPromptIndex) == props.LayoutOrder and use(props.controls.Platform) == "Mobile"
                end),
            }),
            Components.TextLabel(scope, {
                Name = "Key",
                Position = UDim2.fromScale(-0.18, 0.5),
                Size = UDim2.fromScale(0.8, 0.8),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 0,
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                BackgroundColor3 = Color3.new(1, 1, 1),
                TextColor3 = Color3.new(),

                Visible = Fusion.Computed(scope, function(use: Fusion.Use)
                    return use(props.controls.CurrentPromptIndex) == props.LayoutOrder and use(props.controls.Platform) ~= "Mobile"
                end),
                Text = Fusion.Computed(scope, function(use: Fusion.Use)
                    if use(props.controls.Platform) == "PC" then
                        return props.PromptObject.KeyboardKeyCode.Name

                    elseif use(props.controls.Platform) == "Console" then
                        return string.sub(props.PromptObject.GamepadKeyCode.Name, 7)
                    end

                    return ""
                end),

                [Children] = {
                    Components.RoundUICorner(scope),
                    Components.UIPadding(scope, {})
                }
            })
        }
    })
end)
