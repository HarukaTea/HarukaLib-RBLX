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

    --// Prompt
    local center = UI.Center :: Frame

    table.insert(scope, center.PromptsFrame.ChildAdded:Connect(function(child)
        if not child:IsA("Frame") then return end

        HarukaLib:UITween(child, "In")
    end))
    table.insert(scope, PPS.PromptHidden:Connect(function(prompt: ProximityPrompt)
        local bar = PromptBar(prompt, 999, scope, self)
        if not bar then return end
        if center.PromptsFrame:FindFirstChild("Prompt_TweenProjectile") then return end


        local tweenUI = bar
        tweenUI.LayoutOrder = 999
        tweenUI.Name = "Prompt_TweenProjectile"
        tweenUI:AddTag("TweenProjectile")
        tweenUI.Parent = center.PromptsFrame
        Debris:AddItem(tweenUI, 0.15)

        wait()
        HarukaLib:UITween(tweenUI, "Out")
    end))
end
