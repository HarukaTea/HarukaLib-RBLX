--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

--// Constants

local DEFAULT = {
	Rate = 5,
	Size = 0.08,
	Tint = Color3.fromRGB(226, 244, 255),
	Fade = 1.5,
	UpdateFreq = 1 / 45,
}
local UNIT_VEC = Vector3.new(1, 1, 1)
local EMPTY_VEC = Vector3.new(0, 0, 0)

--// Variables

local camera = workspace.CurrentCamera
local gameSettings = UserSettings().GameSettings
local glassGraphics = gameSettings.SavedQualityLevel.Value >= 8

local screenDroplets = Instance.new("Folder")
screenDroplets.Name = "ScreenDroplets"
screenDroplets.Parent = camera

local animations = {}
local offsets = {}
local cameraCF = workspace.CurrentCamera.CFrame
local dropletCount = (DEFAULT.Rate * DEFAULT.Fade) * 3


local dropletPool = nil
local dropletPrefab = Instance.new("Part")
dropletPrefab.Name = "Droplet"
dropletPrefab.Material = Enum.Material.Glass
dropletPrefab.CastShadow = false
dropletPrefab.CanCollide = false
dropletPrefab.CanQuery = false
dropletPrefab.CanTouch = false
dropletPrefab.Anchored = true
dropletPrefab.Transparency = 0.5
dropletPrefab.Color = DEFAULT.Tint
dropletPrefab.Size = UNIT_VEC

local meshPrefab = Instance.new("SpecialMesh")
meshPrefab.Name = "Mesh"
meshPrefab.MeshType = Enum.MeshType.Sphere
meshPrefab.Parent = dropletPrefab

dropletPool = HarukaLib.CreatePartPool(dropletPrefab, (DEFAULT.Rate * DEFAULT.Fade) * 3)


--// Helper functions

local function _moveDroplets()
	cameraCF = workspace.CurrentCamera.CFrame

	local droplets = table.create(dropletCount)
	local dropletCF = table.create(dropletCount)

	local i = 0
	for droplet, offset in offsets do
		i += 1
		dropletCF[i] = cameraCF * offset
		droplets[i] = droplet
	end
	dropletCount = i

	workspace:BulkMoveTo(droplets, dropletCF, Enum.BulkMoveMode.FireCFrameChanged)
end
local function _createDroplet()
	local scale = DEFAULT.Size + (math.random((DEFAULT.Size / 3) * -10, (DEFAULT.Size / 3) * 10) / 10)

	local dropletMain = dropletPool:Get()
	dropletMain.Mesh.Scale = Vector3.one * scale
	dropletMain.Mesh.Offset = EMPTY_VEC
	dropletMain.Color = DEFAULT.Tint
	dropletMain.Transparency = 0.7

	local dropletOffset = CFrame.new(math.random(-120, 120) / 100, math.random(-100, 100) / 100, -0.75)
	offsets[dropletMain] = dropletOffset

	animations[dropletMain] = {
		startClock = os.clock(),
		scale = scale,
		stretch = (math.random(5, 10) / 10) * scale,
		mesh = dropletMain.Mesh,
	}

	dropletMain.Parent = screenDroplets

	--Create droplet extrusions
	for _ = 1, math.random(4) do
		local extrusionScale = (scale / 1.5) + (math.random((scale / 3) * -100, (scale / 3) * 100) / 100)

		local extrusion = dropletPool:Get()
		extrusion.Mesh.Scale = Vector3.one * extrusionScale
		extrusion.Mesh.Offset = EMPTY_VEC
		extrusion.Color = DEFAULT.Tint
		extrusion.Transparency = 0.7

		local e2 = extrusionScale * 60
		local extrusionOffset = dropletOffset * CFrame.new(math.random(-e2, e2) / 100, math.random(-e2, e2) / 100, 0)
		offsets[extrusion] = extrusionOffset

		animations[extrusion] = {
			startClock = os.clock(),
			scale = extrusionScale,
			stretch = (math.random(5, 10) / 10) * extrusionScale,
			mesh = extrusion.Mesh,
		}

		extrusion.Parent = screenDroplets
	end
end
local function _cleanUp(obj: Instance)
	animations[obj] = nil
	offsets[obj] = nil
	dropletPool:Return(obj)
end


--// Listeners

HarukaLib:Hydrate(gameSettings, {
	["Prop-SavedQualityLevel"] = function()
		glassGraphics = gameSettings.SavedQualityLevel.Value >= 8 or gameSettings.SavedQualityLevel.Value == 0
	end
})
RS.RenderStepped:Connect(_moveDroplets)


--// Modules Main

local ScreenRain = {
	Enabled = false,
	_activeUpdater = false,
}

function ScreenRain:Enable(template: {
	Rate: number,
	Size: number,
	Tint: Color3,
	Fade: number,
	UpdateFreq: number,
})
	self.Enabled = true
	self:Configure(template)

	if self._activeUpdater then
		return
	end
	self._activeUpdater = true

	-- Droplet spawn/animation loop
	local accumulatedChance = 0
	task.defer(function()
		local lastCheck = os.clock()

		while task.wait(DEFAULT.UpdateFreq) do
			if (not self.Enabled) and (not next(animations)) then
				self._activeUpdater = false
				break
			end

			local now = os.clock()
			for Droplet, Data in pairs(animations) do
				local startClock = Data.startClock

				local elapsed = now - startClock
				if elapsed >= DEFAULT.Fade then
					_cleanUp(Droplet)
					continue
				end

				local mesh, scale, stretch = Data.mesh, Data.scale, Data.stretch
				local alpha = (elapsed / DEFAULT.Fade)
				local quint = alpha * alpha * alpha * alpha
				local y = scale + (stretch * quint)

				Droplet.Transparency = 0.7 + (0.3 * (alpha*alpha))
				mesh.Scale = Vector3.new(scale, y, scale)
				mesh.Offset = Vector3.new(0, y / -2, 0)
			end
			if self.Enabled and glassGraphics and cameraCF.LookVector.Y > -0.4 then
				accumulatedChance += (now - lastCheck) * DEFAULT.Rate

				for _ = 1, math.floor(accumulatedChance) do
					_createDroplet()
				end
				accumulatedChance %= 1
			else
				accumulatedChance %= 1
			end

			lastCheck = now
		end
	end)
end

function ScreenRain:Disable()
	self.Enabled = false
end

function ScreenRain:Configure(template: {
	Rate: number,
	Size: number,
	Tint: Color3,
	Fade: number,
	UpdateFreq: number,
})
	if type(template) == "table" then
		for k, v in template do
			DEFAULT[k] = v
		end
	end
end

return ScreenRain
