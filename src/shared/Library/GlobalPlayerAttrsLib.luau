--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)


local Replica = nil
local replicaToken = nil

local replicaObj_Client = {}
local replicaConn_Server = nil
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


    self.Trackers = {}
    self.SubscribeFusionVals = {}

    self.scope = Fusion.scoped(Fusion)

    self.Add, self.Empty = HarukaLib.Bin()

    self.Add(function()
        Fusion.doCleanup(self.scope)
    end)
    self.Add(self.ReplicaObjReady)

    globalPlayerAttrsObjPool[tostring(userId)] = self

    return self
end

function GlobalPlayerAttrsLib:Init()
    self.Replica = Replica
    self.ReplicaToken = replicaToken

    if RunService:IsServer() then
        if replicaConn_Server == nil then
            replicaConn_Server = Replica.New({
                Token = self.ReplicaToken,
                Tags = {
                    UserId = self.PlayerUserId
                },
                Data = {
                    [tostring(self.PlayerUserId)] = self.AttrsObj
                }
            })

            replicaConn_Server:Replicate()
        end

        self.ReplicaObj = replicaConn_Server
    else
        if replicaConn_Client == nil then
            replicaConn_Client = Replica.OnNew("GlobalPlayerAttrs", function(replica)
                replicaObj_Client[tostring(replica.Tags.UserId)] = replica

                if replica.Tags.UserId == self.PlayerUserId then
                    self.ReplicaObj = replica

                    workspace:SetAttribute("Haruka_ReplicaObjReady_Player", true)
                end
            end)
        end
    end
end



function GlobalPlayerAttrsLib:GetAttrsObjByUserId(userId: number) : table?
    return globalPlayerAttrsObjPool[tostring(userId)]
end


function GlobalPlayerAttrsLib:Destroy()
    self.Empty()

    if RunService:IsClient() then
        replicaConn_Client:Destroy()
        replicaConn_Client = nil
    else
        replicaConn_Server:Destroy()
        replicaConn_Server = nil
    end

    globalPlayerAttrsObjPool[tostring(self.PlayerUserId)] = nil

    self = nil
end




function GlobalPlayerAttrsLib:GetAllAttrs() : table
    return replicaObj_Client
end

function GlobalPlayerAttrsLib:GetAttrsByPlayer(player: Player) : table?
    local userId = tostring(player.UserId)

    return replicaObj_Client[userId].Data[userId]
end

function GlobalPlayerAttrsLib:GetLocalAttrs() : table?
    return self:GetAttrsByPlayer(Players.LocalPlayer)
end


--// Subscribe to attr changes
function GlobalPlayerAttrsLib:Subscribe(player: Player, attr: string, tracker: (T...) -> nil)
    local stateVal = Fusion.Value(self.scope, nil)
    local playerUserId = tostring(player.UserId)

    if not self.SubscribeFusionVals[playerUserId] then self.SubscribeFusionVals[playerUserId] = {} end
    self.SubscribeFusionVals[playerUserId][attr] = stateVal

    if not self.Trackers[playerUserId] then self.Trackers[playerUserId] = {} end
    if not self.Trackers[playerUserId][attr] then self.Trackers[playerUserId][attr] = {} end

    table.insert(self.Trackers[playerUserId][attr], tracker)


    if RunService:IsClient() then
        local conn = self.ReplicaObj:OnSet({ tostring(player.UserId), attr }, function(new: any)
            stateVal:set(new)
        end)

        self.Add(function()
            conn:Disconnect()
        end)
    else
        self.Add(self.EditAttrsSignal:Connect(function(route: { string }, val: any)
            local thatPlrUserId = route[1]
            local changingAttr = route[2]

            if not self.SubscribeFusionVals[thatPlrUserId] then return end
            if not self.SubscribeFusionVals[thatPlrUserId][changingAttr] then return end

            self.SubscribeFusionVals[thatPlrUserId][changingAttr]:set(val)
        end))
    end

    local observer = Fusion.Observer(self.scope, stateVal)
    local disconnectFunc = observer:onChange(function()
        for _, func in self.Trackers[playerUserId][attr] do
            func(Fusion.peek(stateVal))
        end
    end)

    return disconnectFunc
end


return GlobalPlayerAttrsLib
