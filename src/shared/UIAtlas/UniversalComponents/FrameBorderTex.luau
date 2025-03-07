
local RepS = game:GetService("ReplicatedStorage")

local UIAtlas = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children

local offset = 15.99 / 2
local pattern = {
    TL = {
        AnchorPoint = Vector2.zero,
        Position = UDim2.new(0, -offset, 0, -offset),
        InnerPosition = UDim2.new(0, offset, 0, offset),
        Image = "rbxassetid://116614414788132"
    },
    TR = {
        AnchorPoint = Vector2.xAxis,
        Position = UDim2.new(1, offset, 0, -offset),
        InnerPosition = UDim2.new(1, -offset, 0, offset),
        Image = "rbxassetid://105009305814724"
    },
    BL = {
        AnchorPoint = Vector2.yAxis,
        Position = UDim2.new(0, -offset, 1, offset),
        InnerPosition = UDim2.new(0, offset, 1, -offset),
        Image = "rbxassetid://127831933937018"
    },
    BR = {
        AnchorPoint = Vector2.one,
        Position = UDim2.new(1, offset, 1, offset),
        InnerPosition = UDim2.new(1, -offset, 1, -offset),
        Image = "rbxassetid://109961452309519"
    }
}

return function(scope: Fusion.Scope, props: {
    BorderType: "Inner" | "Outer",

    Size: UDim2?
})
    props.Size = props.Size or UDim2.fromScale(0.09, 0.09)

    return UIAtlas.Frame(scope, {
        ZIndex = 0,
        Name = "FrameBorderTex",

        [Children] = {
            Fusion.ForPairs(scope, pattern, function(_, scope: Fusion.Scope, id: string, data: table)
                return id, UIAtlas.ImageLabel(scope, {
                    Name = "Tex_"..id,
                    Size = props.Size,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,

                    AnchorPoint = data.AnchorPoint,
                    Position = if props.BorderType == "Inner" then data.InnerPosition else data.Position,
                    Image = data.Image,
                })
            end)
        }
    })
end
