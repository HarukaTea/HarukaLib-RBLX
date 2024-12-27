--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Anims = require(RepS.HarukaShared.UIAtlas.Anims.ExplorerNotifyAnims)
local Pinia = require(RepS.HarukaShared.UIAtlas.Pinia.ExplorerNotifyPinia)

local Children, New, Computed = Fusion.Children, Fusion.New, Fusion.Computed

local v2New, udNew = Vector2.new, UDim.new
local fromScale = UDim2.fromScale

return function(plr: Player)
	local self = {}

	self.char = plr.Character or plr.CharacterAdded:Wait()

	Pinia(self)

	local scope = self.scope :: Fusion.Scope
	local UI; UI = Components.HarukaScreenGui(scope, {
		Name = "ExplorerNotify",
		DisplayOrder = 1000,
		Parent = plr:FindFirstChildOfClass("PlayerGui"),

	}, {
		TopProps = {
			Position = fromScale(0.5, 0.2),

			[Children] = {
				Components.Frame(scope, {
					Name = "Notifications",

					[Children] = {
						Components.UIListLayout(scope, {
							Padding = udNew(0.2, 0),
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						}),

						Fusion.ForValues(scope, self.hintsList, function(_, localScope: Fusion.Scope, stringVal: StringValue)
							return Components.Frame(localScope, {
								Name = "Hint",
								Size = UDim2.fromScale(0.6, 0.55),
								BackgroundColor3 = Color3.new(),
								BackgroundTransparency = 0,
								LayoutOrder = self.displayOrder,

								[Children] = {
									Fusion.New(localScope, "UIGradient")({
										Transparency = NumberSequence.new({
											NumberSequenceKeypoint.new(0, 1),
											NumberSequenceKeypoint.new(0.5, 0),
											NumberSequenceKeypoint.new(1, 1),
										}),
									}),

									Components.TextLabel(localScope, {
										Name = "Tip",
										Text = stringVal.Value,
										RichText = true,

										[Children] = {
											Components.UIPadding(localScope, {
												PaddingLeft = UDim.new(0, 12),
												PaddingRight = UDim.new(0, 12),
											})
										},
									}),
								},
							})
						end)
					}
				})
			}
		},

		FullProps = {
			[Children] = {
				Components.Frame(scope, {
					Name = "FS_Hint_BG",
					BackgroundColor3 = Color3.new(1, 1, 1),

					BackgroundTransparency = Fusion.Tween(scope, Computed(scope, function(use: Fusion.Use)
						return use(self.fullScreenTrans)

					end), TweenInfo.new(0.2)),

					[Children] = {
						Components.HarukaFrame(scope, {
							Name = "Center",

							[Children] = {
								Components.TextLabel(scope, {
									Name = "Hint",
									AnchorPoint = v2New(0.5, 0.5),
									Position = fromScale(0.5, 0.5),
									Size = fromScale(1, 0.6),
									TextColor3 = Color3.new(),

									Text = Computed(scope, function(use: Fusion.Use)
										return use(self.fullScreenText)
									end),
									TextTransparency = Fusion.Tween(scope, Computed(scope, function(use: Fusion.Use)
										return use(self.fullScreenTrans)

									end), TweenInfo.new(0.2)),

									[Children] = {
										New(scope, "UITextSizeConstraint")({ MaxTextSize = 36 }),
									},
								}),
							}
						})
					}
				})
			}
		},

		CenterProps = {
			Components.Frame(scope, {
				Name = "CenterNotify",
				Size = fromScale(1, 0.8),
				BackgroundTransparency = 0.15,

				Visible = Fusion.Computed(scope, function(use: Fusion.Use)
					local isVisible = if use(self.centerText) ~= "" then true else false

					return isVisible
				end),

				[Children] = {
					Components.TextLabel(scope, {
						Name = "CenterText",

						Text = Fusion.Computed(scope, function(use: Fusion.Use)
							return use(self.centerText)
						end),

						[Children] = { Components.UIPadding(scope, {}) }
					}),
				}
			})
		}
	})

	Anims(UI, self)

	--// Clear

	local function _onDead()
		Fusion.doCleanup(scope)

		self = nil
	end
	self.char.Humanoid.Died:Once(_onDead)
end
