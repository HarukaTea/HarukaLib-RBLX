--!nocheck

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TS = game:GetService("TweenService")
local RepS = game:GetService("ReplicatedStorage")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local particles = require(script.Parent.Particle)
local droplet = require(script.Parent.Droplet)
local splash = require(script.Parent.Splash)

--// Variables

local rainSound = SoundService.Environment.RainSound :: Sound
rainSound.Volume = 0
rainSound:Play()

--// Private functions

local function _adjustRain(rainLevel: number)
	--// Adjust the rate of the rain particles
    for _, part: BasePart in particles do
		for _, j in part:GetChildren() do
			if j:IsA("ParticleEmitter") then
				j.Rate = rainLevel * 15
			end
		end
	end


	droplet:Disable()
	droplet:Configure({
		Rate = rainLevel
	})
	if rainLevel > 0 then droplet:Enable() end


	splash:SetRate(if rainLevel == 0 then 0 else rainLevel * 5 + 5)


	--// Adjust the volume of the rain sound
	TS:Create(rainSound, TweenInfo.new(0.5), {
		Volume = math.clamp(rainLevel * 0.25, 0, 1.15)
	}):Play()
end

--// Listeners

HarukaLib:Hydrate(Lighting, {
	["Attr-RainLevel"] = function(newLevel: number)
		if not newLevel then return end

		_adjustRain(newLevel)
	end
})


--// Init

Lighting:SetAttribute("RainLevel", 0)

--// Module Main

local WeatherController = {}


function WeatherController:SetRainLevel(rainLevel: number)
	Lighting:SetAttribute("RainLevel", rainLevel)
end

return WeatherController
