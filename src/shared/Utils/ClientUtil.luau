--!nocheck

local CAS = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local RepS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Signals = require(RepS.HarukaShared.Library.Signals)

local ClientUtil = {}


function ClientUtil:FreezePlayerControls(action: "Freeze" | "Unfreeze")
    if action == "Freeze" then
        UIS.ModalEnabled = true

        CAS:BindActionAtPriority("FreezeControl", function()
            return Enum.ContextActionResult.Sink
        end, false, Enum.ContextActionPriority.High.Value, unpack(Enum.PlayerActions:GetEnumItems()))
    else
        UIS.ModalEnabled = false

        CAS:UnbindAction("FreezeControl")
    end
end


function ClientUtil:SetAllPromptsState(state: boolean)
    for _, everyPrompt: Instance in workspace:GetDescendants() do
        if everyPrompt:IsA("ProximityPrompt") and everyPrompt.Name ~= "Chest" then everyPrompt.Enabled = state end
    end
end


function ClientUtil:OpenUIEx(plr: Player, targetUI: string)
    if not plr:GetAttribute("CurrentMenu") then plr:SetAttribute("CurrentMenu", "None") end

    if plr:GetAttribute("CurrentMenu") ~= "None" and plr:GetAttribute("CurrentMenu") ~= targetUI then
        Signals.CreateHint:Fire("You have to close other UIs first!")
        return
    end
    if plr:FindFirstChild("OpenUICD") then return end

    local openUICD = Instance.new("BoolValue")
    openUICD.Name = "OpenUICD"
    openUICD.Value = true
    openUICD.Parent = plr
    Debris:AddItem(openUICD, 0.22)

    local plrGui = plr.PlayerGui
    local function _setExVisibleState(ui: ScreenGui, state: boolean)
		ui.BG.Visible = state
		if ui:FindFirstChild("Shadow") then ui.Shadow.Visible = state end

        if Lighting:FindFirstChild("UIBlur") then Lighting.UIBlur:Destroy() end
        if state then if ui:FindFirstChild("UIBlur") then ui.UIBlur:Clone().Parent = Lighting end end
	end
	local function _setOthersVisibleState(state: boolean)
		plrGui.ExplorerStats.Enabled = state
	end
    local function _setVisible(curUI: string, ui: ScreenGui)
        ClientUtil:SetAllPromptsState(if curUI ~= "None" then false else true)

		plr:SetAttribute("CurrentMenu", curUI)

        pcall(_setExVisibleState, ui, if curUI == "None" then false else true)
        pcall(_setOthersVisibleState, if curUI == "None" then true else false)

		Signals.ExCategoryOpened:Fire()
	end

    --// NOTE: This script is fine but testers just found some other bugs, which is so random
    --// So I have to use pcall

    local targetGui = plrGui[targetUI] :: ScreenGui

    if plr:GetAttribute("CurrentMenu") == "None" then
        pcall(_setVisible, targetUI, targetGui)

        HarukaLib:UITween(targetGui, "In")

    elseif plr:GetAttribute("CurrentMenu") == targetUI then
        pcall(_setVisible, "None", targetGui)

        HarukaLib:UITween(plrGui.ExplorerStats, "In")

    else
        plr:SetAttribute("CurrentMenu", targetUI)

        pcall(_setVisible, targetUI, targetGui)

        local closeList = { "Statistics", "Backpack", "Shop" }
        for _, closeUI: string in closeList do
            if closeUI == targetUI then continue end

            pcall(_setExVisibleState, plrGui[closeUI], false)
        end
    end
end

return ClientUtil
