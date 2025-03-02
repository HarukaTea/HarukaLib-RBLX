--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)


local Anims = require(RepS.HarukaShared.UIAtlas.Anims.ExplorerNotifyAnims)
local Pinia = require(RepS.HarukaShared.UIAtlas.Pinia.ExplorerNotifyPinia)

local Children = Fusion.Children

local v2New, udNew = Vector2.new, UDim.new
local fromScale = UDim2.fromScale

return function(plr: Player)
	local self = {}

	Pinia(self)

	local scope = self.scope :: Fusion.Scope

	local UI; UI = Components.HarukaScreenGui(scope, {
		Name = "ExplorerNotify",
		DisplayOrder = 1000,
		Parent = plr:FindFirstChildOfClass("PlayerGui"),

	}, {
		TopProps = {
			[Children] = {
				Components.Frame(scope, {
					Name = "Notifications",
					AnchorPoint = v2New(0.5, 0),
					Position = fromScale(0.5, 1.3),

					[Children] = {
						Components.UIListLayout(scope, {
							Padding = udNew(0.2, 0),
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						})
					}
				})
			}
		},
	})

	Anims(UI, self)
end
