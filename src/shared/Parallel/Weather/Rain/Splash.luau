--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local CollisionBook = require(RepS.HarukaShared.Library.CollisionBook)

--// Variables

local params = RaycastParams.new()
params.CollisionGroup = CollisionBook.Group.NoCollision

local rainSplashContainer = Instance.new("Folder")
rainSplashContainer.Name = "RainSplash_Projectile"
rainSplashContainer.Parent = workspace

local rainSplash = RepS.Packages.Unloads.RainSplash:Clone() :: BasePart
rainSplash.Parent = rainSplashContainer

local splashCache = HarukaLib.CreatePartPool(rainSplash, 70)

local rate = 10
local stacked = 0
local random = Random.new()

--// Helper functions

local function _planeLookVector(cframe: CFrame) : Vector3
    return Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z).Unit
end
local function _createSplash()
	local camCF =  workspace.CurrentCamera.CFrame
	local camPos = camCF.Position
		+ (_planeLookVector(camCF) * 50)
	local pos = camPos + Vector3.new(random:NextInteger(-50, 50), 0, random:NextInteger(-50, 50))

	local rayResult = workspace:Raycast(pos + Vector3.new(0,50,0), Vector3.new(0, -499, 0), params)

	--// Serial: Create splash
	task.synchronize()
	local part = splashCache:Get() :: BasePart

	if rayResult then
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
	end
	task.delay(5, function()
		splashCache:Return(part)
	end)
end

--// Init
RS.Heartbeat:ConnectParallel(function(dt: number)
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
