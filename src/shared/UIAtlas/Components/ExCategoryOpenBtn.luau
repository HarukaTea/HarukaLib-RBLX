--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.Vanilla)
local ClientUtil = require(RepS.HarukaShared.Utils.ClientUtil)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local ItemBook = require(RepS.HarukaShared.Library.ItemBook)
local Signals = require(RepS.HarukaShared.Library.Signals)

local OnEvent, Children, Computed = Fusion.OnEvent, Fusion.Children, Fusion.Computed

local color3New = Color3.new
local fromScale = UDim2.fromScale

local function ExCategoryOpenBtn(id: string, self: table): Frame
	local scope = self.scope :: Fusion.Scope
	local isSelecting = Fusion.Value(scope, false)

	local function exCategoryOpened()
		isSelecting:set(false)
	end
	table.insert(scope, Signals.ExCategoryOpened:Connect(exCategoryOpened))

	return Components.Frame(scope, {
		Name = id,
		BackgroundColor3 = color3New(),
		BackgroundTransparency = 0,
		Size = fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,

		[Children] = {
			Components.RoundUICorner(scope),

			Components.ImageLabel(scope, {
				Name = "Shade",
				Size = UDim2.fromScale(2, 2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				ZIndex = 0,
				Image = "rbxassetid://92352500600210",
				ImageTransparency = 0.5,

				Visible = Computed(scope, function(use: Fusion.Use)
					return if use(isSelecting) then true else false
				end),

				[Children] = { Components.RoundUICorner(scope) }
			}),
			Components.ImageLabel(scope, {
				Name = "Icon",
				Size = UDim2.fromScale(1, 1),
				Image = ItemBook.ItemImagesEx[id],
			}),

			Components.HoverImageButton(scope, {
				ZIndex = 3,

				[OnEvent("MouseEnter")] = function()
					isSelecting:set(true)
				end,
				[OnEvent("MouseLeave")] = function()
					isSelecting:set(false)
				end,
				[OnEvent("MouseButton1Click")] = function()
					ClientUtil:OpenUIEx(self.plr, id)
				end,
			}),
			Components.TextLabel(scope, {
				Name = "Key",
				Position = fromScale(-0.15, -0.12),
				Size = fromScale(0.55, 0.55),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 4,
				Text = if id == "Statistics" then "C" else "B",

				[Children] = { Components.TextUIStroke(scope, { Thickness = 2.5 }) },
			})
		},
	})
end

return ExCategoryOpenBtn
