--!nocheck

local HttpService = game:GetService("HttpService")
local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Promise = require(RepS.HarukaShared.Shared.Promise)


local GlobalTimer = {}

local timers = {}

--// Init once only
local function _doTasks(callbackT: table, scheduleTime: string)
    for uniqueId: string, callback: () -> nil in callbackT do
        Promise.try(callback)

        callbackT[uniqueId] = nil
    end

    timers[scheduleTime] = nil
end


HarukaLib:Hydrate(workspace, {
    ["Attr-ServerClock"] = function(newClocking: number)
        for scheduleTime: string, callbackT: table in timers do
            if newClocking >= tonumber(scheduleTime) then
                _doTasks(callbackT, scheduleTime)
            end
        end
    end
})


GlobalTimer.AddTask = function(endClock: number, callback: () -> nil) : string
    if endClock == nil then
        warn("Invalid endClock value for global timer")
        return
    end

    local scheduleTime = tostring(endClock)

    if timers[scheduleTime] == nil then timers[scheduleTime] = {} end

    local uniqueId = HttpService:GenerateGUID(false)

    timers[scheduleTime][uniqueId] = callback

    return uniqueId
end


GlobalTimer.DoTaskImmediately = function(uniqueId: string)

    local found = false
    for _, callbackT: table in timers do
        if found then break end

        for thatUniqueId: string, callback: () -> nil in callbackT do
            if thatUniqueId ~= uniqueId then continue end

            Promise.try(callback)
            callbackT[thatUniqueId] = nil

            found = true

            break
        end
    end
end


return GlobalTimer
