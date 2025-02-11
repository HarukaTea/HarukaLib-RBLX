--!nocheck

local HttpService = game:GetService("HttpService")
local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")


local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local Signal = require(RepS.HarukaShared.Shared.Signal)

local isSimilar = require(RepS.HarukaShared.Shared.Fusion.Utility.isSimilar)


local Events = nil
if RunService:IsServer() then
    Events = require(SSS.HarukaServer.Library.ServerEvents)
else
    Events = require(RepS.HarukaShared.Library.Events)
end

local SetAttrSignal = Signal.new()


local GlobalAttrsLib = {}
GlobalAttrsLib.__index = GlobalAttrsLib


local allGlobalAttrsObjPool = {}


local wait = task.wait



--// Init in server
if RunService:IsServer() then
    Events.GlobalAttrsLibRequest.SetCallback(function(_, uniqueId: string)
        local obj
        repeat wait() obj = allGlobalAttrsObjPool[uniqueId] until obj

        return obj.AttrsObj
    end)
else
    Events.GlobalAttrsLibSetAttr.On(function(data)
        local uniqueId, route, val = data.UniqueId, data.Route, data.Value

        SetAttrSignal:Fire(uniqueId, route, val)
    end)
end





--// Constructor
function GlobalAttrsLib.new(uniqueId: string, serverOnlyProps: {
    Attrs: table
}?)
    local self = setmetatable({}, GlobalAttrsLib)

    self.UniqueId = uniqueId

    if RunService:IsServer() then
        self.AttrsObj = serverOnlyProps.Attrs

    else
        self.AttrsObj = Events.GlobalAttrsLibRequest.Call(self.UniqueId)

        repeat wait() until self.AttrsObj
    end

    self.scope = Fusion.scoped()
    self.Add, self.Empty = HarukaLib.Bin()

    self.OnSetSignal = Signal.new()
    self.Add(self.OnSetSignal)


    allGlobalAttrsObjPool[uniqueId] = self

    return self
end



function GlobalAttrsLib:Init()
    self.Add(SetAttrSignal:Connect(function(uniqueId: string, route: { string }, value: any)
        if uniqueId ~= self.UniqueId then return end

        self:SetAttr(route, value)
    end))
end


function GlobalAttrsLib:Destroy()
    allGlobalAttrsObjPool[self.UniqueId] = nil

    Fusion.doCleanup(self.scope)
    self.Empty()

    self = nil
end


--// Public Methods

function GlobalAttrsLib:GetAttrObjPool()
    return allGlobalAttrsObjPool
end

function GlobalAttrsLib:GetAttrObjByUniqueId(uniqueId: string)
    return allGlobalAttrsObjPool[uniqueId]
end


function GlobalAttrsLib:SetAttr(route: { string }, value: any)
    --- set them internally
    local pointer = self.AttrsObj
    for i = 1, #route - 1 do
        pointer = pointer[route[i]]
    end

    local old = pointer[route[#route]] :: any
    local new = value
    local isTheSame = isSimilar(old, new)

    pointer[route[#route]] = value

    if isTheSame then return end


    --- fire the signal to the trackers
    self.OnSetSignal:Fire(route, value)

    if RunService:IsServer() then
        Events.GlobalAttrsLibSetAttr.FireAll({
            UniqueId = self.UniqueId,
            Route = route,
            Value = value
        })
    end
end


function GlobalAttrsLib:Subscribe(attr: string, tracker: (T...) -> nil) : () -> nil
    local stateVal = Fusion.Value(self.scope, self.AttrsObj[attr])


    self.Add(self.OnSetSignal:Connect(function(thatRoute: { string }, thatVal: any)
        if thatRoute[1] ~= attr then return end

        stateVal:set(thatVal)
    end))


    local observer = Fusion.Observer(self.scope, stateVal)
    local disconnectFunc = observer:onBind(function()
        tracker(Fusion.peek(stateVal))
    end)

    return disconnectFunc
end




return GlobalAttrsLib
