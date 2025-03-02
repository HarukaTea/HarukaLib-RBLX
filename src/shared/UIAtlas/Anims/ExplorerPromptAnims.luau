--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Screen3D = require(RepS.HarukaShared.Shared.Screen3D)
local HarukaListLayout = require(RepS.HarukaShared.Shared.HarukaListLayout)

local wait = task.wait


return function (UI: ScreenGui, self: table)
    local scope = self.scope :: Fusion.Scope
    local center = UI.Center :: Frame

    --// screen 3d-ify
    local screen3DObj = Screen3D.new(UI, 5)
    table.insert(scope, screen3DObj)

    local part2D_center = screen3DObj:GetPart2D(center)

    part2D_center:SetOffset(CFrame.Angles(0, math.rad(-8), 0))
    part2D_center:Enable()


    --// prompt AGL
    local animatedLayoutObj = HarukaListLayout.new(center.Prompts.UIListLayout)
    animatedLayoutObj:Enable()

    table.insert(scope, animatedLayoutObj)


    --// prompt animation
    table.insert(scope, center.Prompts.ChildAdded:Connect(function(child: Frame)
        if not child:IsA("Frame") then return end

        HarukaLib:UITween(child, "In", { TweenTime = 0.3 })
    end))
end
