--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)


--// Variables

local splashCache = HarukaLib.CreatePartPool(RepS.Packages.Unloads.RainSplash, 15 * 2)


local rate = 10
local stacked = 0
local random = Random.new()


--// Helper functions

local function _planeLookVector(cframe: CFrame) : Vector3
    return Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z).Unit
end
local function _createSplash()
	local camCF = workspace.CurrentCamera.CFrame
	local camPos = camCF.Position
		+ (_planeLookVector(camCF) * 50)
	local pos = camPos + Vector3.new(random:NextInteger(-50, 50), 0, random:NextInteger(-50, 50))

	local rayResult = workspace:Raycast(pos + Vector3.new(0,50,0), Vector3.new(0, -499, 0))

	if rayResult then
		local part = splashCache:Get() :: BasePart

		part.Position = rayResult.Position + Vector3.new(0, 0.1, 0)

		for _, v: Instance in part:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				if v.Name == "Wind" then
					local randomRate = math.floor( 50 / ( (0.35 * rate) + 1) )
					if randomRate >= 1 then
						if math.random(1, randomRate) == 1 then v:Emit(1) end
					else
						v:Emit(1)
					end
				else
					v:Emit(3)
				end
			end
		end

		task.delay(2, function()
			splashCache:Return(part)
		end)
	end
end

--// Init
RS.Heartbeat:Connect(function(dt: number)
    local d = rate * dt
	stacked += d

	if stacked >= 1 then
		stacked = 0
		_createSplash()
	end
end)

--// Module Main

local SplashController = {}

function SplashController:SetRate(newRate: number)
	rate = newRate
end

return SplashController
