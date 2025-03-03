--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children


return function (scope: Fusion.Scope)
    return Components.HarukaScreenGui(scope, {
        Name = "GotHealShade",
        DisplayOrder = 1000,
        Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"),

        [Children] = {
            Components.Frame(scope, {
                Name = "Shade_LR",
                BackgroundTransparency = 0,
                BackgroundColor3 = Color3.fromHex('#7bed9f'),

                [Children] = {
                    Fusion.New(scope, "UIGradient")({
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.5),
                            NumberSequenceKeypoint.new(0.2, 1),
                            NumberSequenceKeypoint.new(0.8, 1),
                            NumberSequenceKeypoint.new(1, 0.5)
                        })
                    })
                }
            }),
            Components.Frame(scope, {
                Name = "Shade_TB",
                BackgroundTransparency = 0,
                BackgroundColor3 = Color3.fromHex('#2ed573'),

                [Children] = {
                    Fusion.New(scope, "UIGradient")({
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.5),
                            NumberSequenceKeypoint.new(0.15, 1),
                            NumberSequenceKeypoint.new(0.85, 1),
                            NumberSequenceKeypoint.new(1, 0.5)
                        }),

                        Rotation = 90
                    })
                }
            })
        }
    })
end