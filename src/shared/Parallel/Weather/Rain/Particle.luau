--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")

local CollisionBook = require(RepS.HarukaShared.Library.CollisionBook)

--// Variables

local params = RaycastParams.new()
params.CollisionGroup = CollisionBook.Group.NoCollision

local rainCastContainer = Instance.new("Folder")
rainCastContainer.Name = "RainCast_Projectile"
rainCastContainer.Parent = workspace

local rainCastPart = RepS.Packages.Unloads.RainCast:Clone() :: BasePart
rainCastPart.Size = Vector3.new(45, 1, 45)

local rainParts = {
	[1] = rainCastPart:Clone(),
	[2] = rainCastPart:Clone(),
	[3] = rainCastPart:Clone(),
	[4] = rainCastPart:Clone(),
}
for _, part: BasePart in rainParts do
	part.Parent = script
end

--// Helper functions

local function _replicatePos(cameraCFrame: CFrame)
	local CF = cameraCFrame + Vector3.yAxis * 50

	task.synchronize()
	rainParts[1].CFrame = CF
	rainParts[2].CFrame = CF + (CF.RightVector * 45)
	rainParts[3].CFrame = CF - (CF.RightVector * 45)
	rainParts[4].CFrame = CF + (CF.LookVector * 45)
end
local function _rayCast(pos: Position)
	--// Parallel: raycast
	task.desynchronize()
	local rayResult = workspace:Raycast(pos, Vector3.yAxis * -50)
	local check = true

	if rayResult then
		if rayResult.Position.Y - (pos - Vector3.yAxis * 50).Y < 5 then
			check = true
		end
		check = false
	end

	--// Synchronize: check
	task.synchronize()
	return check
end

--// Listeners

RS.RenderStepped:ConnectParallel(function()
	local camCF = workspace.CurrentCamera.CFrame
	local _, ry, _ = camCF:ToOrientation()
	local CF = CFrame.new(camCF.Position) * CFrame.Angles(0, ry, 0).Rotation

	_replicatePos(CF)
end)


--// Init

task.defer(function()
	while task.wait(0.2) do
		for _, part: BasePart in rainParts do
			if _rayCast(part.Position) then
				if part.Parent ~= rainCastContainer then
					part.Parent = rainCastContainer
				end
			else
				if part.Parent ~= script then
					part.Parent = script
				end
			end
		end
	end
end)


return rainParts
