--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local UIAtlas = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children

return function(scope: Fusion.Scope)
    return UIAtlas.Frame(scope, {
        Name = "CircleFX",
        Size = UDim2.fromScale(0, 0),

        [Children] = {
            UIAtlas.RoundUICorner(scope),
            UIAtlas.UIStroke(scope, { Thickness = 2.5 })
        }
    })
end
