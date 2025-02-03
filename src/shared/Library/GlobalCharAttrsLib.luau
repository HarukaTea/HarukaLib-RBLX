--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)


local Replica = nil
local replicaToken = nil

local replicaObj_Client = {}
local replicaConn_Client = nil

local globalCharAttrsObjPool = {}

if RunService:IsServer() then
    Replica = require(RepS.HarukaShared.Shared.Replica.ReplicaServer)

    replicaToken = Replica.Token("GlobalCharAttrs")
else
    Replica = require(RepS.HarukaShared.Shared.Replica.ReplicaClient)

    --- we already startup the replica in GlobalPlayerAttrsLib.luau
end


local GlobalCharAttrsLib = {}
GlobalCharAttrsLib.__index = GlobalCharAttrsLib


--// Constructor
function GlobalCharAttrsLib.new(uniqueId: string, props: {
    AttrsObjForClient: table?,
    EditAttrsSignalForServer: Signal?,
})
    props = props or {}

    local self = setmetatable({}, GlobalCharAttrsLib)

    self.UniqueId = uniqueId

    if RunService:IsServer() then
        self.AttrsObj = props.AttrsObjForClient
        self.EditAttrsSignal = props.EditAttrsSignalForServer
    end

    self.scope = Fusion.scoped(Fusion)

    self.Add, self.Empty = HarukaLib.Bin()

    self.Add(function()
        Fusion.doCleanup(self.scope)
    end)

    globalCharAttrsObjPool[uniqueId] = self

    return self
end

function GlobalCharAttrsLib:Init()
    self.Replica = Replica
    self.ReplicaToken = replicaToken

    if RunService:IsServer() then
        self.ReplicaObj = self.Replica.New({
            Token = self.ReplicaToken,
            Tags = {
                UniqueId = self.UniqueId
            },
            Data = {
                [tostring(self.UniqueId)] = self.AttrsObj
            }
        })
        self.ReplicaObj:Replicate()

        self.Add(self.ReplicaObj)
    else
        if replicaConn_Client == nil then
            replicaConn_Client = self.Replica.OnNew("GlobalCharAttrs", function(replica)
                replicaObj_Client[tostring(replica.Tags.UniqueId)] = self.new(replica.Tags.UniqueId)
                replicaObj_Client[tostring(replica.Tags.UniqueId)].ReplicaObj = replica

                if replica.Tags.UniqueId == self.UniqueId then
                    self.ReplicaObj = replica

                    workspace:SetAttribute("Haruka_ReplicaObjReady_Char", true)
                end
            end)
        end
    end
end



function GlobalCharAttrsLib:Destroy()
    self.Empty()

    if RunService:IsClient() then
        replicaConn_Client:Destroy()
        replicaConn_Client = nil
    else

    end

    globalCharAttrsObjPool[self.UniqueId] = nil

    self = nil
end



function GlobalCharAttrsLib:GetCharAttrsObjByUniqueId_Server(uniqueId: string) : table?
    return globalCharAttrsObjPool[uniqueId]
end

function GlobalCharAttrsLib:GetCharAttrsObjByUniqueId_Client(uniqueId: string) : table?
    return replicaObj_Client[uniqueId]
end

function GlobalCharAttrsLib:GetGlobalCharAttrsObjPool_Server() : table
    return globalCharAttrsObjPool
end

function GlobalCharAttrsLib:GetAllCharAttrsObjs_Client() : table
    return replicaObj_Client
end


--// Subscribe to attr changes
function GlobalCharAttrsLib:Subscribe(uniqueId: string, attr: string, tracker: (T...) -> nil)
    local stateVal = Fusion.Value(self.scope, nil)


    if RunService:IsClient() then
        local conn = self.ReplicaObj:OnSet({ uniqueId, attr }, function(new: any)
            stateVal:set(new)
        end)
        stateVal:set(self.ReplicaObj.Data[uniqueId][attr])


        self.Add(function()
            conn:Destroy()
        end)
    else
        self.Add(self.EditAttrsSignal:Connect(function(route: { string }, val: any)
            local thatCharUniqueId = route[1]
            local changingAttr = route[2]

            if thatCharUniqueId ~= uniqueId then return end
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


return GlobalCharAttrsLib
