--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local HarukaListLayout = require(RepS.HarukaShared.Shared.HarukaListLayout)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local wait = task.wait

return function (UI: ScreenGui, self: table)
    local scope = self.scope :: Fusion.Scope


    --// hints AGL
    local animatedLayoutObj = HarukaListLayout.new(UI.Top.Notifications.UIListLayout)
    animatedLayoutObj:Enable()


    table.insert(scope, animatedLayoutObj)
end
