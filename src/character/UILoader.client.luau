--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer

local function setup()
	for _, module: ModuleScript in RepS.HarukaShared.UIAtlas:GetChildren() do
		if not module:IsA("ModuleScript") then continue end
		if module.Name == "Vanilla" then continue end

		task.spawn(function() require(module)(plr) end)
	end

	workspace:SetAttribute("Haruka_UILoaded", true)
end
setup()
