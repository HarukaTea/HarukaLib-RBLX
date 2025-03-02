--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children

local fromScale = UDim2.fromScale

return function (scope: Fusion.Scope, props: {
    Text: string
})
    return Components.Frame(scope, {
        Name = "FS_Hint_BG",
        BackgroundColor3 = Color3.new(28, 28, 37),
        BackgroundTransparency = 0,
        Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui").ExplorerNotify.Full,

        [Children] = {
            Components.HarukaFrame(scope, {
                Name = "Center",

                [Children] = {
                    Components.TextLabel(scope, {
                        Name = "Hint",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = fromScale(0.5, 0.5),
                        Size = fromScale(1, 0.6),

                        Text = props.Text,

                        [Children] = {
                            Fusion.New(scope, "UITextSizeConstraint")({ MaxTextSize = 36 }),
                        },
                    }),
                }
            })
        }
    })
end