--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local AssetBook = require(RepS.HarukaShared.Library.AssetBook)
local Components = require(RepS.HarukaShared.UIAtlas.Vanilla)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local ItemBook = require(RepS.HarukaShared.Library.ItemBook)

local Pinia = require(RepS.HarukaShared.UIAtlas.Pinia.ExplorerStatsPinia)
local UIAnims = require(RepS.HarukaShared.UIAtlas.UIAnims.ExplorerStatsUIAnims)

local ExCategoryOpenBtn = require(RepS.HarukaShared.UIAtlas.Components.ExCategoryOpenBtn)
local PromptBar = require(RepS.HarukaShared.UIAtlas.Components.PromptBar)

local Children, New = Fusion.Children, Fusion.New

local ExplorerStats = {}
ExplorerStats.__index = ExplorerStats

local wait = task.wait
local v2New, udNew = Vector2.new, UDim.new
local fromScale = UDim2.fromScale

return function(plr: Player)
	local self = setmetatable({}, ExplorerStats)

	self.plr = plr
	self.char = plr.Character or plr.CharacterAdded:Wait()

	repeat wait() until plr:GetAttribute("IsLoaded")
	repeat wait() until plr:GetAttribute("PlayerDataLoaded")
	repeat wait() until self.char:GetAttribute("CharDataLoaded")

	Pinia(self)

	local scope = self.scope :: Fusion.Scope

	self.HPGradient = Fusion.New(scope, "UIGradient")({
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.999, 0),
			NumberSequenceKeypoint.new(1, 1),
			NumberSequenceKeypoint.new(1, 1)
		})
	})

	local CenterNotifyBar = function(pos: "Top" | "Bottom") : Frame
		return Fusion.New(scope, "Frame")({
			Name = pos.."Bar",
			Size = fromScale(0.15, 0.1),

			Position = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use)
				local isVisible = if use(self.centerText) ~= "" then true else false

				if isVisible then
					return if pos == "Top" then fromScale(1.2, 0) else fromScale(-0.2, 0.9)
				else
					return if pos == "Top" then fromScale(-0.2, 0) else fromScale(1.2, 0.9)
				end

			end), AssetBook.TweenInfos.one)
		})
	end
	local BottomInfoTextLabel = function(pos: "Left" | "Right", text: string) : TextLabel
		return Components.TextLabel(scope, {
			Name = "Location",
			Position = fromScale(0, 0.5),
			Size = fromScale(1, 0.3),
			FontFace = Font.fromName("Ubuntu", Enum.FontWeight.Bold),
			TextTransparency = 0.3,
			TextXAlignment = Enum.TextXAlignment[pos],
			Text = text,

			[Children] = {
				New(scope, "UIPadding")({
					PaddingRight = udNew(0.01, 0),
					PaddingLeft = udNew(0.01, 0),
				}),
				New(scope, "UITextSizeConstraint")({ MaxTextSize = 14 })
			}
		})
	end
	local UI; UI = Components.ScreenGui(scope, {
		Name = "ExplorerStats",
		DisplayOrder = 2,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		Parent = plr:FindFirstChildOfClass("PlayerGui"),

		[Children] = {
			Components.HarukaFrame(scope, {
				Name = "Bottom",
				AnchorPoint = v2New(0.5, 1),
				Position = fromScale(0.5, 1),
				ZIndex = 2,

				[Children] = {
					Components.Frame(scope, {
						Name = "StatsFrame",

						[Children] = {
							Components.UIListLayout(scope, {
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center
							}),

							Components.ImageLabel(scope, {
								Name = "HPBar",
								Size = fromScale(0.22, 0.42),
								Image = "rbxassetid://97834064886932",
								ImageColor3 = Color3.fromRGB(30, 30, 30),

								[Children] = {
									Components.ImageLabel(scope, {
										Name = "Bar",
										Image = "rbxassetid://97834064886932",

										ImageColor3 = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use)
											local HP, maxHP = use(self.charStatsDict.HP[1]) :: number, use(self.charStatsDict.HP[2]) :: number
											local x = math.clamp(HP / maxHP, 0, 1)
											if x ~= x then x = 0 end

											if x <= 0.66 and x > 0.33 then
												return Color3.fromRGB(216, 169, 85)
											elseif x <= 0.33 then
												return Color3.fromRGB(184, 27, 35)
											else
												return Color3.fromRGB(38, 193, 193)
											end
										end), AssetBook.TweenInfos.onceHalf),

										[Children] = { self.HPGradient }
									}),
									Components.TextLabel(scope, {
										Name = "Stat",
										AnchorPoint = v2New(0, 0.5),
										Position = fromScale(0, 0.5),
										Size = fromScale(1, 1.1),
										FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),

										Text = Fusion.Computed(scope, function(use: Fusion.Use)
											return HarukaLib:ThreeDotNumberify(use(self.charStatsDict.HP[1]))
											 .. " / " ..
											HarukaLib:ThreeDotNumberify(use(self.charStatsDict.HP[2]))
										end),

										[Children] = {
											Components.UIPadding(scope, {
												PaddingBottom = UDim.new(0.1, 0),
												PaddingTop = UDim.new(0.1, 0)
											}),
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

										Text = "1",

										[Children] = {
											Components.RoundUICorner(scope)
										}
									})
								},
							})
						},
					}),
					Components.Frame(scope, {
						Name = "EconomyFrame",
						Position = fromScale(0.5, -0.3),
						Size = fromScale(0.98, 1),

						[Children] = {
							Components.UIListLayout(scope, {
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Left,
								VerticalAlignment = Enum.VerticalAlignment.Bottom
							}),

							Fusion.ForPairs(scope, { "Gold", "RP" }, function(_, localScope: Fusion.Scope, index: number, currency: string)
								return index, Components.Frame(localScope, {
									Name = currency,
									LayoutOrder = index,
									Size = UDim2.fromScale(0.13, 0.7),

									[Children] = {
										Components.UIListLayout(localScope, {
											Padding = UDim.new(0.1, 0),
											FillDirection = Enum.FillDirection.Horizontal,
											HorizontalAlignment = Enum.HorizontalAlignment.Left,
											VerticalAlignment = Enum.VerticalAlignment.Center
										}),

										Components.ImageLabel(localScope, {
											Name = "Icon",
											Image = ItemBook.ItemImagesEx[currency],
											Size = UDim2.fromScale(0.75, 0.75),
											SizeConstraint = Enum.SizeConstraint.RelativeYY,
											BackgroundTransparency = 0,

											[Children] = { Components.RoundUICorner(localScope) }
										}),
										Components.TextLabel(localScope, {
											Name = "Amount",
											Size = UDim2.fromScale(0.65, 0.7),
											TextXAlignment = Enum.TextXAlignment.Left,
											LayoutOrder = 2,

											Text = Fusion.Computed(localScope, function(use: Fusion.Use)
												return HarukaLib:ThreeDotNumberify(use(self.playerData[currency]))
											end),

											[Children] = {
												Components.TextUIStroke(localScope, { Thickness = 2 })
											}
										})
									}
								})
							end)
						}
					}),

					BottomInfoTextLabel("Left", `{workspace:GetAttribute("ServerLocation")} / ASTRA DEMO`),
					BottomInfoTextLabel("Right", `UID: {self.plr.UserId}`)
				},
			}),
			Components.HarukaFrame(scope, {
				Name = "Center",
				ZIndex = 2,

				[Children] = {
					Components.Frame(scope, {
						Name = "PromptsFrame",
						AnchorPoint = v2New(0.5, 0),
						Position = fromScale(0.65, 0),
						Size = fromScale(1, 0.7),

						[Children] = {
							Components.UIListLayout(scope, {
								Padding = udNew(0.3, 0),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center
							}),

							Fusion.ForPairs(scope, self.promptsList, function(_, localScope: Fusion.Scope, index: number, prompt: ProximityPrompt)
								return index, PromptBar(prompt, index, localScope, self)
							end)
						},
					}),

					Components.Frame(scope, {
						Name = "UIFuncs",
						AnchorPoint = v2New(0.5, 0),
						Size = fromScale(0.98, 1),

						[Children] = {
							Components.UIListLayout(scope, {
								Padding = UDim.new(0.15, 0),
								VerticalAlignment = Enum.VerticalAlignment.Center
							}),

							ExCategoryOpenBtn("Statistics", self),
							ExCategoryOpenBtn("Backpack", self)
						},
					}),

					Components.Frame(scope, {
						Name = "WaveShowerFrame",
						Size = fromScale(1, 0.8),
						BackgroundTransparency = 0.15,

						Visible = Fusion.Computed(scope, function(use: Fusion.Use)
							local isVisible = if use(self.centerText) ~= "" then true else false

							if isVisible then HarukaLib:UITween(UI.Center.WaveShowerFrame, "In") end

							return isVisible
						end),

						[Children] = {
							Components.TextLabel(scope, {
								Name = "Wave",
								TextColor3 = Color3.fromRGB(255, 255, 127),

								Text = Fusion.Computed(scope, function(use: Fusion.Use)
									return use(self.centerText)
								end),

								[Children] = { Components.UIPadding(scope, {}) }
							}),

							CenterNotifyBar("Top"), CenterNotifyBar("Bottom")
						}
					})
				}
			}),
			Components.HarukaFrame(scope, {
				Name = "Top",
				AnchorPoint = v2New(0.5, 0),
				Position = fromScale(0.5, 0.05),

				[Children] = {
					Components.Frame(scope, {
						Name = "TimerFrame",

						[Children] = {
							Components.UIListLayout(scope, {
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center
							}),

							Components.ImageLabel(scope, {
								Name = "TimerBG",
								Size = fromScale(0.15, 0.7),
								Image = "rbxassetid://97834064886932",
								ImageColor3 = Color3.fromRGB(),

								Visible = Fusion.Computed(scope, function(use: Fusion.Use)
									return if use(self.countdown) > 0 then true else false
								end),

								[Children] = {
									Components.UIListLayout(scope, {
										FillDirection = Enum.FillDirection.Horizontal,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										VerticalAlignment = Enum.VerticalAlignment.Center
									}),

									Fusion.New(scope, "UIGradient")({
										Transparency = NumberSequence.new({
											NumberSequenceKeypoint.new(0, 1),
											NumberSequenceKeypoint.new(0.15, 0.25),
											NumberSequenceKeypoint.new(0.5, 0),
											NumberSequenceKeypoint.new(0.85, 0.25),
											NumberSequenceKeypoint.new(1, 1)
										})
									}),

									Components.ImageLabel(scope, {
										Name = "Icon",
										Size = fromScale(0.7, 0.7),
										SizeConstraint = Enum.SizeConstraint.RelativeYY,
										Image = "rbxassetid://108568405853683",
										LayoutOrder = 1,
									}),
									Components.TextLabel(scope, {
										Name = "Time",
										AutomaticSize = Enum.AutomaticSize.X,
										Size = fromScale(0, 1),
										LayoutOrder = 2,
										FontFace = Font.fromName("Roboto", Enum.FontWeight.Bold),

										Text = Fusion.Computed(scope, function(use: Fusion.Use)
											return HarukaLib:FromNumberToTime(use(self.countdown))
										end),

										[Children] = {
											Components.UIPadding(scope, {})
										}
									})
								}
							}),
						}
					})
				}
			})
		},
	})

	UIAnims(UI, self)

	--// Clear
	local function _clearGarbage()
		Fusion.doCleanup(scope)

		self = nil
	end
	self.humanoid.Died:Once(_clearGarbage)
end
