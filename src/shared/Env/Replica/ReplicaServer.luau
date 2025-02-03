--!nocheck

--// Modified by HarukaTea, original code by MadworkStudio

local RepS = game:GetService("ReplicatedStorage")

local Signal = require(RepS.HarukaShared.Shared.Signal)
local Events = require(script.Parent.ReplicaServerEvents)

local isSimilar = require(RepS.HarukaShared.Shared.Fusion.Utility.isSimilar)

----- Private -----

local REPLICATION_ALL = "ALL"

local Players = game:GetService("Players")

local ReadyPlayers: {[Player]: boolean} = {}

local Replicas = {} -- [id] = Replica, ...
local ReplicationAllReplicas = {} -- [Replica] = true, ... -- Replicas that had the method :Replicate() called on them
local SelectiveSubscriptions = {} -- [Player] = {[replica] = true, ...}

local Index = 0


local function IterateGroup(replica, fn) -- fn(replica)
	fn(replica)
	for child in pairs(replica.Children) do
		IterateGroup(child, fn)
	end
end
local function GenerateCreation(replica)
	local replication = {}
	local creation = {}

	local self_creation = replica.self_creation
	self_creation[4] = if replica.Parent == nil then 0 else replica.Parent.Id

	creation[tostring(replica.Id)] = self_creation

	replica.creation = creation
	replica.replication = replication
end

----- Public -----

export type Replica = {
	Tags: {[any]: any},
	Data: {[any]: any},
	Id: number,
	Token: string,

	Set: (self: any, path: {string}, value: any) -> (),
	Replicate: (self: any) -> (),
	Destroy: (self: any) -> (),
}

local Replica = {
	ReadyPlayers = ReadyPlayers,
	NewReadyPlayer = Signal.new(),
	RemovingReadyPlayer = Signal.new(),
}
Replica.__index = Replica

local ReplicaToken = {}
ReplicaToken.__index = ReplicaToken

local LockedReplica = {}
LockedReplica.__index = LockedReplica

function Replica.Token(name: string)
	local self = setmetatable({
		Name = name,
	}, ReplicaToken)

	return self
end

function Replica.New(params: {Token: typeof(ReplicaToken), Tags: {}?, Data: {}?}): Replica
	local token = params.Token
	local tags = params.Tags or {}
	local data = params.Data or {}

	Index += 1

	local self = setmetatable({
		Tags = tags,
		Data = data,
		Id = Index,
		Token = token.Name,

		self_creation = {token.Name, tags, data, 0, params.WriteLib},
		creation = nil, -- ["replica_id"] = {token, tags, data, parent_id, write_lib}, ...
		replication = nil, -- {REPLICATION_ALL = true} or {[Player] = true, ...}

	}, Replica)

	Replicas[Index] = self

	return self

end


function Replica:Set(path: {string}, value: any)
	-- Apply local change:
	local pointer = self.Data
	for i = 1, #path - 1 do
		pointer = pointer[path[i]]
	end

	local old = pointer[path[#path]] :: any
	local new = value
	local isTheSame = isSimilar(old, new)

	pointer[path[#path]] = value

	if isTheSame then return end

	-- Replicate change:
	local self_id = self.Id
	if self.replication ~= nil then
		if self.replication[REPLICATION_ALL] == true then
			for player in pairs(ReadyPlayers) do
				Events.SetData.Fire(player, self_id, path, value)
			end
		end
	end
end



function Replica:Replicate()
	if self.creation == nil then
		GenerateCreation(self)

	elseif self.replication[REPLICATION_ALL] == true then
		return
	end

	local creation = self.creation
	local replication = self.replication


	for player in pairs(ReadyPlayers) do
		if replication[player] == nil then
			Events.CreateData.Fire(player, creation)
		else
			local selective_lookup = SelectiveSubscriptions[player]
			selective_lookup[self] = nil
		end
	end

	table.clear(replication)
	replication[REPLICATION_ALL] = true
	ReplicationAllReplicas[self] = true
end



local function DestroyReplica(replica)
	local id = replica.Id

	-- Clear replica entry:
	Replicas[id] = nil

	-- Remove creation data:
	if replica.creation ~= nil then
		replica.creation[tostring(id)] = nil
	end

	-- Swap metatables:
	setmetatable(replica, LockedReplica)
end

function Replica:Destroy()
	local self_id = self.Id

	if Replicas[self_id] == nil then return end

	-- Destroy replica for all clients who were replicated to:
	if self.replication ~= nil then
		if self.replication[REPLICATION_ALL] == true then
			for player in pairs(ReadyPlayers) do
				Events.DestroyData.Fire(player, self_id)
			end
		end
	end


	-- Clearing hierarchy:
	ReplicationAllReplicas[self] = nil


	-- Recursive destruction:
	DestroyReplica(self)
end

----- Init -----

do -- Destroyed replica metatable:

	local keep_methods = {
		Identify = true,
		Destroy = true,
	}
	for name, fn in pairs(Replica) do
		if name ~= "__index" then
			if keep_methods[name] == true then
				LockedReplica[name] = fn
			else
				LockedReplica[name] = function()
					return
				end
			end
		end
	end
end

-- New player data replication:

Events.RequestData.SetCallback(function(player: Player)
	if ReadyPlayers[player] ~= nil and player:IsDescendantOf(Players) == true then
		return "Failure"
	end

	-- Make the client create all replicas that are initially replicated to the client;
	-- Pack up and send intially replicated replicas:

	local creation = {}

	for replica in pairs(ReplicationAllReplicas) do
		table.insert(creation, replica.creation)
	end
	Events.RequestCreations.Fire(player, creation)

	-- Set player to active:
	ReadyPlayers[player] = true
	SelectiveSubscriptions[player] = {}
	Replica.NewReadyPlayer:Fire(player)

	return "Success"
end)


-- Player leave handling:
Players.PlayerRemoving:Connect(function(player)
	if ReadyPlayers[player] == nil then return end

	-- Remove player from subscription settings:
	for replica in pairs(SelectiveSubscriptions[player]) do
		replica.replication[player] = nil
	end

	-- Remove player from ready players list:
	ReadyPlayers[player] = nil
	SelectiveSubscriptions[player] = nil

	Replica.RemovingReadyPlayer:Fire(player)
end)

return Replica