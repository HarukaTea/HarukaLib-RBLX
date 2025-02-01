--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)


local Replica = nil
local replicaToken = nil

local replicaObj_Client = {}
local replicaConn_Server = nil
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

    self.AttrsObj = props.AttrsObjForClient
    self.EditAttrsSignal = props.EditAttrsSignalForServer

    self.Trackers = {}
    self.SubscribeFusionVals = {}

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
        if replicaConn_Server == nil then
            replicaConn_Server = Replica.New({
                Token = self.ReplicaToken,
                Tags = {
                    UniqueId = self.UniqueId
                },
                Data = {
                    [tostring(self.UniqueId)] = self.AttrsObj
                }
            })
        end

        self.ReplicaObj = replicaConn_Server
        self.ReplicaObj:Replicate()
    else
        if replicaConn_Client == nil then
            replicaConn_Client = Replica.OnNew("GlobalCharAttrs", function(replica)
                replicaObj_Client[tostring(replica.Tags.UniqueId)] = replica

                if replica.Tags.UniqueId == self.UniqueId then
                    self.ReplicaObj = replica

                    workspace:SetAttribute("Haruka_ReplicaObjReady_Char", true)
                end
            end)
        end
    end
end


function GlobalCharAttrsLib:GetAttrsObjByUniqueId(uniqueId: string) : table?
    return globalCharAttrsObjPool[uniqueId]
end


function GlobalCharAttrsLib:Destroy()
    self.Empty()

    if RunService:IsClient() then
        replicaConn_Client:Destroy()
        replicaConn_Client = nil
    else
        replicaConn_Server:Destroy()
        replicaConn_Server = nil
    end

    globalCharAttrsObjPool[self.UniqueId] = nil

    self = nil
end




function GlobalCharAttrsLib:GetAllAttrs() : table
    return replicaObj_Client
end

function GlobalCharAttrsLib:GetAttrsByUniqueId(uniqueId: string) : table?
    return replicaObj_Client[uniqueId].Data[uniqueId]
end

function GlobalCharAttrsLib:GetLocalAttrs() : table?
    return self:GetAttrsByUniqueId(self.UniqueId)
end


--// Subscribe to attr changes
function GlobalCharAttrsLib:Subscribe(uniqueId: string, attr: string, tracker: (T...) -> nil)
    local stateVal = Fusion.Value(self.scope, nil)

    if not self.SubscribeFusionVals[uniqueId] then self.SubscribeFusionVals[uniqueId] = {} end
    self.SubscribeFusionVals[uniqueId][attr] = stateVal

    if not self.Trackers[uniqueId] then self.Trackers[uniqueId] = {} end
    if not self.Trackers[uniqueId][attr] then self.Trackers[uniqueId][attr] = {} end

    table.insert(self.Trackers[uniqueId][attr], tracker)


    if RunService:IsClient() then
        local conn = self.ReplicaObj:OnSet({ uniqueId, attr }, function(new: any)
            stateVal:set(new)
        end)

        self.Add(function()
            conn:Destroy()
        end)
    else
        self.Add(self.EditAttrsSignal:Connect(function(route: { string }, val: any)
            local thatCharUniqueId = route[1]
            local changingAttr = route[2]

            if not self.SubscribeFusionVals[thatCharUniqueId] then return end
            if not self.SubscribeFusionVals[thatCharUniqueId][changingAttr] then return end

            self.SubscribeFusionVals[thatCharUniqueId][changingAttr]:set(val)
        end))
    end

    local observer = Fusion.Observer(self.scope, stateVal)
    local disconnectFunc = observer:onChange(function()
        for _, func in self.Trackers[uniqueId][attr] do
            func(Fusion.peek(stateVal))
        end
    end)

    return disconnectFunc
end


return GlobalCharAttrsLib
