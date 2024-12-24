--!nocheck

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local RS = game:GetService("RunService")

local Promise = require(RepS.HarukaShared.Shared.Promise)


local function setup()
	Players.CharacterAutoLoads = false

	StarterPlayer.CharacterUseJumpPower = true

    RepS.HarukaShared.Sounds.Parent = workspace

    workspace:SetAttribute("Haruka_ServerInited", true)
end
task.spawn(setup)


local function serverLocationTest()
    workspace:SetAttribute("ServerLocation", "Unknown")

    if RS:IsStudio() then return end

    Promise.new(function()
        local serverInfo = HttpService:GetAsync("https://ipconfig.io/json", false)

        if serverInfo then
            local realInfo = HttpService:JSONDecode(serverInfo) :: table
            local serverLocation = realInfo["country_iso"] :: string

            if serverLocation then
                workspace:SetAttribute("ServerLocation", serverLocation)

                print("Server Location: "..serverLocation)
            end
        end

    end):catch(function()
        warn("Failed to fetch Server Location.")
    end)
end
task.spawn(serverLocationTest)
