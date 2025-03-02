--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)


return function (scope: Fusion.Scope, props: {
    LoadingText: string
})
    return Components.HarukaScreenGui(scope, {
        Name = "LoadScreen",
        DisplayOrder = 999,
        Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"),

    }, {
        FullProps = {
            ZIndex = 0,
            BackgroundTransparency = 0,
        },

        BottomProps = {
            [Fusion.Children] = {
                Components.TextLabel(scope, {
                    Name = "LoadingText",
                    Position = UDim2.fromScale(0, -0.3),
                    Size = UDim2.fromScale(1, 0.5),
                    Text = props.LoadingText,
                })
            }
        }
    })
end
