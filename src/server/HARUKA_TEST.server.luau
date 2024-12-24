--!nocheck

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")

local Events = require(SSS.HarukaServer.Modules.Library.ServerEvents)


repeat task.wait() until Players:FindFirstChildOfClass("Player")


local plr = Players:FindFirstChildWhichIsA("Player")

repeat task.wait() until plr:GetAttribute("PlayerDataLoaded")


task.wait(8)
Events.CreateTimer.FireAll({
    Countdown = 159
})

while task.wait(4) do
    Events.CreateHint.FireAll({
        Hint = "Test hint _ "..HttpService:GenerateGUID(false)
    })

    if math.random(1, 5) == 1 then
        Events.CreateCenterNotify.FireAll({
            Hint = "LEVEL CLEARED!"
        })
    end
end