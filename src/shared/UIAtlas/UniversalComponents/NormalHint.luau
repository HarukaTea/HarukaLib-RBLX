--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children


return function (scope: Fusion.Scope, props: {
    Text: string,
    LayoutOrder: number,
})
    return Components.Frame(scope, {
        Name = "Hint",
        Size = UDim2.fromScale(0.6, 0.55),
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 0,
        LayoutOrder = props.LayoutOrder,
        Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui").ExplorerNotify.Top.Notifications,


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
                Text = props.Text,
                RichText = true,

                [Children] = {
                    Components.UIPadding(scope, {
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                    })
                },
            }),
        },
    })
end