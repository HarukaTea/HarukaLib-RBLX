--!nocheck

local Debris = game:GetService("Debris")
local RepS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")

local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local PromptBar = require(RepS.HarukaShared.UIAtlas.Components.PromptBar)

local wait = task.wait

return function (UI: ScreenGui, self: table)
    local scope = self.scope :: Fusion.Scope
    local center = UI.Center :: Frame

    table.insert(scope, center.Prompts.ChildAdded:Connect(function(child: Frame)
        if not child:IsA("Frame") then return end

        HarukaLib:UITween(child, "In", { TweenTime = 0.35 })
    end))
    table.insert(scope, center.Prompts.ChildRemoved:Connect(function(child: Frame)
        local bar = nil

        if not bar then return end
        if bar:HasTag("TweenProjectile") then return end

        local tweenUI = bar
        tweenUI.LayoutOrder = 999
        tweenUI.Name = "Prompt_TweenProjectile"
        tweenUI:AddTag("TweenProjectile")
        tweenUI.Parent = center.Prompts
        Debris:AddItem(tweenUI, 0.15)

        wait()
        HarukaLib:UITween(tweenUI, "Out")
    end))
end
