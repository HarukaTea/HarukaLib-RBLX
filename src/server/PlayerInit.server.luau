--!nocheck

local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")

local Signals = require(SSS.HarukaServer.Modules.Library.ServerSignals)

--// Private

repeat task.wait() until workspace:GetAttribute("Haruka_ServerInited")

local function setup(plr: Player)
    plr:SetAttribute("Gold", 0)
    plr:SetAttribute("RP", 0)

    plr:SetAttribute("PlayerDataLoaded", true)
end

for _, plr in Players:GetPlayers() do
	task.spawn(setup, plr)
end
Players.PlayerAdded:Connect(setup)
