--!nocheck

local Debris = game:GetService("Debris")
local RepS = game:GetService("ReplicatedStorage")

local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local wait = task.wait

return function (UI: ScreenGui, self: table)
    local scope = self.scope :: Fusion.Scope

    --// Hints
    local top = UI.Top :: Frame

    table.insert(scope, top.Notifications.ChildRemoved:Connect(function(hint: Frame)
        if not hint:IsA("Frame") then return end
        if hint:HasTag("TweenProjectile") then return end

        local tweenHint = hint:Clone()
        tweenHint:AddTag("TweenProjectile")
        tweenHint.Parent = top.Notifications
        Debris:AddItem(tweenHint, 0.25)

        wait()
        HarukaLib:UITween(tweenHint, "Out")
    end))
end
