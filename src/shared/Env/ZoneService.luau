--!nocheck

--// Inspired by ZonePlus, but it's super simplified to fit my project

local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Signal = require(RepS.HarukaShared.Shared.Signal)
local CharLib = require(SSS.HarukaServer.Services.CharLib)


local ZoneService = {}
ZoneService.__index = ZoneService

local wait = task.wait



--// Constructor
function ZoneService.new()
    local self = setmetatable({}, ZoneService)

    self.Zones = {}

    self.ZoneEntered = Signal.new()
    self.ZoneLeft = Signal.new()

    self.Add, self.Empty = HarukaLib.Bin()

    self.Add(self.ZoneEntered)
    self.Add(self.ZoneLeft)


    return self
end



function ZoneService:Init()
    self.Add(task.spawn(function()
        while wait(0.15) do
            for _, charObj: table in CharLib:GetCharPool() do
                if not charObj.Char then continue end
                if not charObj.Char.PrimaryPart then continue end

                local regionIn = HarukaLib:IsInRegion(charObj.Char.PrimaryPart.Position, self.Zones)

                if regionIn then
                    if charObj:GetRegionIn() == regionIn.Name then continue end

                    charObj:SetRegionIn(regionIn.Name)
                else
                    charObj:SetRegionIn("None")
                end
            end
        end
    end))
end


function ZoneService:AddZone(zone: BasePart)
    table.insert(self.Zones, zone)
end
function ZoneService:RemoveZone(zone: BasePart)
    local index = table.find(self.Zones, zone)
    if index then
        table.remove(self.Zones, index)
    end
end


function ZoneService:Destroy()
    self.Empty()

    self = nil
end

return ZoneService