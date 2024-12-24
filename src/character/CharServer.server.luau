--!nocheck

local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")

local char = script:FindFirstAncestorOfClass("Model") :: Model
local plr = Players:GetPlayerFromCharacter(char)

local wait = task.wait

repeat wait() until plr:GetAttribute("PlayerDataLoaded")


local function setup()
    char.PrimaryPart = char.Humanoid.RootPart

    local statsFolder = Instance.new("Folder")
    statsFolder.Name = "CharStats"
    statsFolder.Parent = char


    char:SetAttribute("CharDataLoaded", true)
end
setup()
