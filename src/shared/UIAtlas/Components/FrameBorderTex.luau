
local RepS = game:GetService("ReplicatedStorage")

local UIAtlas = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children

local pattern = {
    TL = {
        AnchorPoint = Vector2.zero,
        Position = UDim2.fromScale(-0.03, -0.03),
        Image = "rbxassetid://116614414788132"
    },
    TR = {
        AnchorPoint = Vector2.xAxis,
        Position = UDim2.fromScale(1.03, -0.03),
        Image = "rbxassetid://105009305814724"
    },
    BL = {
        AnchorPoint = Vector2.yAxis,
        Position = UDim2.fromScale(-0.03, 1.03),
        Image = "rbxassetid://127831933937018"
    },
    BR = {
        AnchorPoint = Vector2.one,
        Position = UDim2.fromScale(1.03, 1.03),
        Image = "rbxassetid://109961452309519"
    }
}

return function(scope: Fusion.Scope)
    return UIAtlas.Frame(scope, {
        ZIndex = 0,
        Name = "FrameBorderTex",

        [Children] = {
            Fusion.ForPairs(scope, pattern, function(_, localScope: Fusion.Scope, id: string, data: table)
                return id, UIAtlas.ImageLabel(localScope, {
                    Name = "Tex_"..id,
                    Size = UDim2.fromScale(0.08, 0.08),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,

                    AnchorPoint = data.AnchorPoint,
                    Position = data.Position,
                    Image = data.Image,
                })
            end)
        }
    })
end
