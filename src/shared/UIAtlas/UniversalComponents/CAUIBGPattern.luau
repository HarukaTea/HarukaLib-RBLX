--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)


return function (scope: Fusion.Scope, props: {
    Size: UDim2?,
    TileSize: UDim2?,
})
    props.Size = props.Size or UDim2.fromScale(1, 1)
    props.TileSize = props.TileSize or UDim2.fromScale(0.15, 0.15)

    return Components.ImageLabel(scope, {
        Name = "CAUIBGPattern",
        Size = props.Size,

        Image = "rbxassetid://91666280221875",
        ImageColor3 = Components.WHITE_COLOR,
        ImageTransparency = 0.975,

        ScaleType = Enum.ScaleType.Tile,
        TileSize = props.TileSize
    })
end
