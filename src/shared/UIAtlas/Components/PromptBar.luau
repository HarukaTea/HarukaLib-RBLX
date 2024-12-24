--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.Vanilla)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local isMobile = HarukaLib:GetDevice() == "Mobile"

local v2New = Vector2.new
local fromScale = UDim2.fromScale

local function PromptBar(prompt: ProximityPrompt, index: number, scope: Fusion.Scope, self: table) : Frame
    if prompt:GetAttribute("CanAutoPickup") then return nil end


    return Components.Frame(scope, {
        Name = "Prompt",
        AnchorPoint = v2New(0.5, 0),
        BackgroundTransparency = 0,
        Size = fromScale(0.18, 1),
        LayoutOrder = prompt:GetAttribute("Order") or 1,

        BackgroundColor3 = Fusion.Computed(scope, function(use: Fusion.Use)
            return if use(self.currentPromptIndex) == index then Color3.new(1, 1, 1) else Color3.new()
        end),

        [Fusion.Children] = {
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
                    return if use(self.currentPromptIndex) == index then Color3.new() else Color3.new(1, 1, 1)
                end),
            }),
            Components.TextLabel(scope, {
                Name = "PromptText",
                AnchorPoint = v2New(0, 0.5),
                Position = fromScale(0.19, 0.5),
                Size = fromScale(0.77, 0.7),
                Text = prompt.ActionText,
		        TextXAlignment = Enum.TextXAlignment.Left,

                TextColor3 = Fusion.Computed(scope, function(use: Fusion.Use)
                    return if use(self.currentPromptIndex) == index then Color3.new() else Color3.new(1, 1, 1)
                end),
            }),
            Components.TextLabel(scope, {
				Name = "Key",
				Position = UDim2.fromScale(-0.18, 0.5),
				Size = UDim2.fromScale(0.8, 0.8),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				AnchorPoint = Vector2.new(0, 0.5),
				Text = prompt.KeyboardKeyCode.Name,
				BackgroundTransparency = 0,

				BackgroundColor3 = Fusion.Computed(scope, function(use: Fusion.Use)
					return if use(self.currentPromptIndex) == index then Color3.new(1, 1, 1) else Color3.new()
				end),
				Visible = Fusion.Computed(scope, function(use: Fusion.Use)
					return if use(self.currentPromptIndex) == index and (not isMobile) then true else false
				end),
				TextColor3 = Fusion.Computed(scope, function(use: Fusion.Use)
					return if use(self.currentPromptIndex) == index then Color3.new() else Color3.new(1, 1, 1)
				end),

				[Fusion.Children] = {
					Components.RoundUICorner(scope),
					Components.UIPadding(scope, {})
				}
			}),
            Components.HoverImageButton(scope, {
                [Fusion.OnEvent("MouseButton1Click")] = function()
                    prompt:InputHoldBegin()
                end
            })
        }
    })
end

return PromptBar
