--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local AssetBook = require(RepS.HarukaShared.Library.AssetBook)
local Components = require(RepS.HarukaShared.UIAtlas.Vanilla)
local ClientUtil = require(RepS.HarukaShared.Utils.ClientUtil)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children

local fromScale = UDim2.fromScale
local fromRGB = Color3.fromRGB

local function ExCategoryTabFrame(id: string, self: table): Frame
	local scope = self.scope :: Fusion.Scope

	local plr = self.plr :: Player
	local isSelecting = Fusion.Value(scope, false)

	return Components.Frame(scope, {
		Name = "TabUI",
		Size = fromScale(0.97, 1),

		[Children] = {
			Components.UIListLayout(scope, {
				Padding = UDim.new(0.01, 0),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			Components.TextLabel(scope, {
				Name = "Key",
				Size = fromScale(0.55, 0.55),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
				TextColor3 = Color3.new(),
				FontFace = Font.fromName("RobotoMono", Enum.FontWeight.Bold),
				Text = if id == "Statistics" then "C" else "B",
				Visible = if id == "Statistics" or id == "Backpack" then true else false,
				LayoutOrder = 1,

				[Children] = { Components.RoundUICorner(scope) }
			}),
			Components.HoverImageButton(scope, {
				Name = "Close",
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = fromScale(0.948, 0.5),
				Image = "rbxassetid://103065634382876",
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				LayoutOrder = 2,

				ImageColor3 = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use)
					return if use(isSelecting) then fromRGB(255, 0, 0) else fromRGB(255, 251, 196)
				end), AssetBook.TweenInfos.twiceHalf),

				[Fusion.OnEvent("MouseEnter")] = function()
					isSelecting:set(true)
				end,
				[Fusion.OnEvent("MouseLeave")] = function()
					isSelecting:set(false)
				end,
				[Fusion.OnEvent("MouseButton1Click")] = function()
					if id == "Shop" then self.items:set({}) end

					ClientUtil:OpenUIEx(plr, id)
				end
			})
		},
	})
end

return ExCategoryTabFrame
