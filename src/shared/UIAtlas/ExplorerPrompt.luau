--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Pinia = require(RepS.HarukaShared.UIAtlas.Pinia.ExplorerPromptPinia)
local Anims = require(RepS.HarukaShared.UIAtlas.Anims.ExplorerPromptAnims)

local PromptBar = require(RepS.HarukaShared.UIAtlas.Components.PromptBar)

local Children = Fusion.Children

local udNew = UDim.new
local fromScale = UDim2.fromScale

return function(plr: Player)
	local self = {}

	self.plr = plr
    self.char = plr.Character or plr.CharacterAdded:Wait()
    self.scope = Fusion.scoped()

	Pinia(self)

	local scope = self.scope :: Fusion.Scope

	local UI; UI = Components.HarukaScreenGui(scope, {
		Name = "ExplorerPrompt",
		DisplayOrder = 2,
		Parent = plr:FindFirstChildOfClass("PlayerGui"),

	}, {
        CenterProps = {
            ZIndex = 2,

            [Children] = {
                Components.Frame(scope, {
                    Name = "Prompts",
                    Position = fromScale(0.65, 0.5),
                    Size = fromScale(1, 0.7),

                    [Children] = {
                        Components.UIListLayout(scope, {
                            Padding = udNew(0.3, 0),
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center
                        }),

                        Fusion.ForPairs(scope, self.promptsList, function(_, scope: Fusion.Scope, index: number, prompt: ObjectValue)
                            return index, PromptBar(scope, {
                                PromptObject = prompt.Value,
                                CurrentPromptIndex = self.currentPromptIndex,
                                LayoutOrder = index
                            })
                        end)
                    },
                }),
            }
        }
    })

	Anims(UI, self)


    --// Clear
	local function _clear()
		Fusion.doCleanup(scope)

		self = nil
	end
	self.char.Humanoid.Died:Once(_clear)
end
