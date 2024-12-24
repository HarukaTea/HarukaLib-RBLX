--!nocheck

local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Events = require(SSS.HarukaServer.Modules.Library.ServerEvents)
local Signals = require(SSS.HarukaServer.Modules.Library.ServerSignals)
local Promise = require(RepS.HarukaShared.Shared.Promise)

local wait = task.wait


Signals.ReloadCharacter:Connect(function(plr: Player)
	plr.Character = nil

	local r6Char: Model

	Promise.new(function()
		local humanoidDesc = Players:GetHumanoidDescriptionFromUserId(plr.UserId)
		r6Char = Players:CreateHumanoidModelFromDescription(humanoidDesc, Enum.HumanoidRigType.R6)

	end):catch(function()
		warn("Failed to load character for player: "..plr.UserId)

		local humanoidDesc = RepS.HarukaShared.Unloads.DummyHDesc:Clone()
		r6Char = Players:CreateHumanoidModelFromDescription(humanoidDesc, Enum.HumanoidRigType.R6)
	end)

	repeat wait() until r6Char

	r6Char.Name = plr.Name
	r6Char:PivotTo(CFrame.new(Vector3.yAxis * 1599))
	r6Char.Humanoid.DisplayName = plr.DisplayName
	r6Char.Animate:Destroy()

	for _, cScript in StarterPlayer.StarterCharacterScripts:GetChildren() do
		cScript:Clone().Parent = r6Char
	end
	plr.Character = r6Char

	r6Char.Parent = workspace
end)


Events.RequestSpawn.SetCallback(function(plr: Player, _)
	if plr.Character then return end

	Signals.ReloadCharacter:Fire(plr)

	plr:SetAttribute("GameStarted", true)
end)


Events.ForceReset.SetCallback(function(plr: Player, _)
	if not plr.Character then return end

	plr.Character.Humanoid.Health = 0

	task.delay(5, function()
		Signals.ReloadCharacter:Fire(plr)
	end)
end)
