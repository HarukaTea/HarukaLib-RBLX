--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)


local Replica = nil
local replicaToken = nil

local replicaObj_Client = {}
local replicaConn_Client = nil

local globalPlayerAttrsObjPool = {}

if RunService:IsServer() then
    Replica = require(RepS.HarukaShared.Shared.Replica.ReplicaServer)

    replicaToken = Replica.Token("GlobalPlayerAttrs")
else
    Replica = require(RepS.HarukaShared.Shared.Replica.ReplicaClient)

    Replica.RequestData()
end


local GlobalPlayerAttrsLib = {}
GlobalPlayerAttrsLib.__index = GlobalPlayerAttrsLib


--// Constructor
function GlobalPlayerAttrsLib.new(userId: number, props: {
    AttrsObjForClient: table?,
    EditAttrsSignalForServer: Signal?,
})
    props = props or {}

    local self = setmetatable({}, GlobalPlayerAttrsLib)

    self.PlayerUserId = userId

    if RunService:IsServer() then
        self.AttrsObj = props.AttrsObjForClient
        self.EditAttrsSignal = props.EditAttrsSignalForServer
    end


    self.scope = Fusion.scoped(Fusion)

    self.Add, self.Empty = HarukaLib.Bin()

    self.Add(function()
        Fusion.doCleanup(self.scope)
    end)

    globalPlayerAttrsObjPool[tostring(userId)] = self

    return self
end

function GlobalPlayerAttrsLib:Init()
    self.Replica = Replica
    self.ReplicaToken = replicaToken

    if RunService:IsServer() then
        self.ReplicaObj = self.Replica.New({
            Token = self.ReplicaToken,
            Tags = {
                UserId = self.PlayerUserId
            },
            Data = {
                [tostring(self.PlayerUserId)] = self.AttrsObj
            }
        })
        self.ReplicaObj:Replicate()

        self.Add(self.ReplicaObj)
    else
        if replicaConn_Client == nil then
            replicaConn_Client = self.Replica.OnNew("GlobalPlayerAttrs", function(replica)
                replicaObj_Client[tostring(replica.Tags.UserId)] = self.new(replica.Tags.UserId)
                replicaObj_Client[tostring(replica.Tags.UserId)].ReplicaObj = replica

                if replica.Tags.UserId == self.PlayerUserId then
                    self.ReplicaObj = replica

                    workspace:SetAttribute("Haruka_ReplicaObjReady_Player", true)
                end
            end)
        end
    end
end


function GlobalPlayerAttrsLib:Destroy()
    self.Empty()

    if RunService:IsClient() then
        replicaConn_Client:Destroy()
        replicaConn_Client = nil
    else

    end

    globalPlayerAttrsObjPool[tostring(self.PlayerUserId)] = nil

    self = nil
end


function GlobalPlayerAttrsLib:GetPlayerAttrsObjByUserId_Server(userId: number) : table?
    return globalPlayerAttrsObjPool[tostring(userId)]
end

function GlobalPlayerAttrsLib:GetPlayerAttrsObjByPlayer_Server(player: Player) : table?
    return self:GetPlayerAttrsObjByUserId_Server(player.UserId)
end

function GlobalPlayerAttrsLib:GetPlayerAttrsObjByUserId_Client(userId: number) : table?
    return replicaObj_Client[tostring(userId)]
end

function GlobalPlayerAttrsLib:GetPlayerAttrsObjByPlayer_Client(player: Player) : table?
    return self:GetPlayerAttrsObjByUserId_Client(player.UserId)
end

function GlobalPlayerAttrsLib:GetPlayerAttrsObjPool_Server() : table
    return globalPlayerAttrsObjPool
end

function GlobalPlayerAttrsLib:GetAllPlayerAttrsObjs_Client() : table
    return replicaObj_Client
end


--// Subscribe to attr changes
function GlobalPlayerAttrsLib:Subscribe(player: Player, attr: string, tracker: (T...) -> nil)
    local stateVal = Fusion.Value(self.scope, nil)
    local playerUserId = tostring(player.UserId)


    if RunService:IsClient() then
        local conn = self.ReplicaObj:OnSet({ tostring(player.UserId), attr }, function(new: any)
            stateVal:set(new)
        end)
        stateVal:set(self.ReplicaObj.Data[playerUserId][attr])


        self.Add(function()
            conn:Destroy()
        end)
    else
        self.Add(self.EditAttrsSignal:Connect(function(route: { string }, val: any)
            local thatPlrUserId = route[1]
            local changingAttr = route[2]

            if thatPlrUserId ~= playerUserId then return end
            if changingAttr ~= attr then return end

            stateVal:set(val)
        end))
    end

    local observer = Fusion.Observer(self.scope, stateVal)
    local disconnectFunc = observer:onBind(function()
        tracker(Fusion.peek(stateVal))
    end)

    return disconnectFunc
end


return GlobalPlayerAttrsLib
