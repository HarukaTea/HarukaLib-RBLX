
local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local UILab = require(RepS.HarukaShared.Shared.UILabs)

local Children = Fusion.Children

local fromScale = UDim2.fromScale
local v2New = Vector2.new

return UILab.CreateFusionStory({
    fusion = Fusion,
    controls = {
        HP = UILab.Slider(500, 0, 1000, 10),
		EXP = UILab.Slider(500, 0, 1000, 10),

		MaxHP = UILab.Slider(1000, 1000, 10000, 100),
		MaxEXP = UILab.Slider(1000, 1000, 10000, 100),

		Level = 1
    },

}, function(props)
    local scope = props.scope
	local self = {}

	self.HPBar = Components.ImageLabel(scope, {
		Name = "HPBar",
		Size = fromScale(0.22, 0.42),
		Image = "rbxassetid://97834064886932",
		ImageColor3 = Color3.fromRGB(28, 28, 37),

		Parent = props.target,

		[Children] = {
			Components.ImageLabel(scope, {
				Name = "Bar",
				Image = "rbxassetid://97834064886932",

				ImageColor3 = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use)
					local HP, maxHP = use(props.controls.HP) :: number, use(props.controls.MaxHP) :: number
					local x = math.clamp(HP / maxHP, 0, 1)

					if x ~= x then x = 0 end

					if x <= 0.66 and x > 0.33 then
						return Color3.fromRGB(216, 169, 85)
					elseif x <= 0.33 then
						return Color3.fromRGB(184, 27, 35)
					else
						return Color3.fromRGB(38, 193, 193)
					end
				end), TweenInfo.new(0.2)),

				[Children] = {
					Fusion.New(scope, "UIGradient")({
						Transparency = Fusion.Computed(scope, function(use: Fusion.Use)
							local HP, maxHP = use(props.controls.HP) :: number, use(props.controls.MaxHP) :: number
							local x = math.clamp(HP / maxHP, 0, 0.999)

							if x ~= x then x = 0 end

							return NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0),
								NumberSequenceKeypoint.new(x, 0),
								NumberSequenceKeypoint.new(x + 0.001, 1),
								NumberSequenceKeypoint.new(1, 1)
							})
						end)
					})
				}
			}),
			Components.TextLabel(scope, {
				Name = "Stat",
				AnchorPoint = v2New(0, 0.5),
				Position = fromScale(0, 0.5),
				Size = fromScale(1, 1.1),
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),

				Text = Fusion.Computed(scope, function(use: Fusion.Use)
					return
					HarukaLib:CommaifyNumber(use(props.controls.HP))
					 .. " / " ..
					HarukaLib:CommaifyNumber(use(props.controls.MaxHP))
				end),

				[Children] = {
					Components.UIPadding(scope, {}),
					Components.TextUIStroke(scope, {})
				}
			}),

			Components.TextLabel(scope, {
				Name = "Level",
				AnchorPoint = v2New(0, 0.5),
				BackgroundTransparency = 0,
				Position = fromScale(-0.138, 0.5),
				Size = fromScale(1.5, 1.5),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				FontFace = Font.fromName("TitilliumWeb", Enum.FontWeight.Bold),

				Text = Fusion.Computed(scope, function(use: Fusion.Use)
					return use(props.controls.Level)
				end),

				[Children] = {
					Components.RoundUICorner(scope),
					Components.UIPadding(scope, {
						PaddingBottom = UDim.new(0.05, 0),
						PaddingTop = UDim.new(0.05, 0),
						PaddingLeft = UDim.new(0.05, 0),
						PaddingRight = UDim.new(0.05, 0)
					}),

					Components.UIStroke(scope, {
						Thickness = 2.5,
						Color = Color3.fromHex('#81ecec'),

						[Children] = {
							Fusion.New(scope, "UIGradient")({
								Transparency = Fusion.Computed(scope, function(use: Fusion.Use)
									local EXP, maxEXP = use(props.controls.EXP) :: number, use(props.controls.MaxEXP) :: number
									local x = math.clamp(EXP / maxEXP, 0, 0.999)

									if x ~= x then x = 0 end

									return NumberSequence.new({
										NumberSequenceKeypoint.new(0, 0),
										NumberSequenceKeypoint.new(x, 0),
										NumberSequenceKeypoint.new(x + 0.001, 1),
										NumberSequenceKeypoint.new(1, 1)
									})
								end)
							})
						}
					})
				}
			})
		},
	})


	local component = Components.HarukaFrame(scope, {
		Parent = props.target,


		[Children] = { self.HPBar }
	})
end)
