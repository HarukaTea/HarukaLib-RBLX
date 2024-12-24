--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local AssetBook = require(RepS.HarukaShared.Library.AssetBook)
local Components = require(RepS.HarukaShared.UIAtlas.Vanilla)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Pinia = require(RepS.HarukaShared.UIAtlas.Pinia.ExplorerNotifyPinia)

local Children, New, Computed = Fusion.Children, Fusion.New, Fusion.Computed

local ExplorerNotify = {}
ExplorerNotify.__index = ExplorerNotify

local v2New, udNew = Vector2.new, UDim.new
local fromScale = UDim2.fromScale
local wait = task.wait

return function(plr: Player)
	local self = setmetatable({}, ExplorerNotify)

	repeat wait() until plr:GetAttribute("IsLoaded")
	repeat wait() until plr:GetAttribute("PlayerDataLoaded")

	self.char = plr.Character or plr.CharacterAdded:Wait()
	self.displayOrder = 1

	repeat wait() until self.char:GetAttribute("CharDataLoaded")

	Pinia(self)

	local scope = self.scope :: Fusion.Scope
	Components.ScreenGui(scope, {
		Name = "ExplorerNotify",
		DisplayOrder = 1000,
		Parent = plr:FindFirstChildOfClass("PlayerGui"),

		[Children] = {
			Components.HarukaFrame(scope, {
				Name = "Top",
				AnchorPoint = v2New(0.5, 0),
				Position = fromScale(0.5, 0.2),

				[Children] = {
					Components.Frame(scope, {
						Name = "ExplorerNotify",

						[Children] = {
							Components.UIListLayout(scope, {
								Padding = udNew(0.2, 0),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
							}),

							Fusion.ForValues(scope, self.hintsList, function(_, localScope: Fusion.Scope, stringVal: StringValue)
								local overallTrans = Fusion.Value(localScope, 0)
								task.delay(2.78, function()
									overallTrans:set(1)
								end)

								return Components.Frame(scope, {
									Name = "Hint",
									Size = UDim2.fromScale(0.6, 0.55),
									BackgroundColor3 = Color3.new(),
									BackgroundTransparency = 0,
									LayoutOrder = self.displayOrder,

									[Children] = {
										Fusion.New(scope, "UIGradient")({
											Transparency = NumberSequence.new({
												NumberSequenceKeypoint.new(0, 1),
												NumberSequenceKeypoint.new(0.5, 0),
												NumberSequenceKeypoint.new(1, 1),
											}),
										}),

										Components.TextLabel(scope, {
											Name = "Tip",
											Text = stringVal.Value,
											RichText = true,

											[Children] = {
												Fusion.New(scope, "UIPadding")({
													PaddingBottom = UDim.new(0.1, 0),
													PaddingTop = UDim.new(0.1, 0),
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
			}),
			Components.Frame(scope, {
				Name = "FullScreenHintBG",
				BackgroundColor3 = Color3.new(1, 1, 1),

				BackgroundTransparency = Fusion.Tween(scope, Computed(scope, function(use: Fusion.Use)
					return use(self.fullScreenTrans)
				end), AssetBook.TweenInfos.twiceHalf),

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
								end), AssetBook.TweenInfos.twiceHalf),

								[Children] = {
									New(scope, "UITextSizeConstraint")({ MaxTextSize = 36 }),
								},
							}),
						}
					})
				}
			})
		},
	})

	--// Clear
	local function _onDead()
		Fusion.doCleanup(scope)

		self = nil
	end
	self.char.Humanoid.Died:Once(_onDead)
end
