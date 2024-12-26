--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Promise = require(RepS.HarukaShared.Shared.Promise)

local plr = Players.LocalPlayer

local function setup()
	for _, module: ModuleScript in RepS.HarukaShared.UIAtlas:GetChildren() do
		if not module:IsA("ModuleScript") then continue end
		if module.Name == "HarukaComponents" then continue end

		Promise.defer(function()
			require(module)(plr)

		end):catch(function(err)
			warn(err)
		end)
	end

	workspace:SetAttribute("Haruka_UILoaded", true)
end
setup()
