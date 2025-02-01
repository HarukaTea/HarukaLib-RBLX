--!nocheck

--// Modified by HarukaTea, original code by MadworkStudio

local RepS = game:GetService("ReplicatedStorage")

local Signal = require(RepS.HarukaShared.Shared.Signal)
local Events = require(script.Parent.ReplicaEvents)


local REQUEST_DATA_REPEAT = 2

local DataRequestStarted = false

local TokenReplicas = {} -- [token] = {[replica] = true, ...}
local Replicas = {} -- [id] = Replica, ...
local BindReplicas = {} -- [id] = Replica, ... -- Unannounced Replicas waiting for their binds to stream in

local NewReplicaListeners = {} -- [token] = {[connection] = true, ...}

----- Public -----

export type Replica = {
	Tags: {[any]: any},
	Data: {[any]: any},
	Id: number,
	Token: string,

	OnSet: (self: any, path: {}, listener: () -> ()) -> (Signal),
}

local Replica = {
	IsReady = false
}
Replica.__index = Replica

local function ReplicaNew(id: number, self_creation: {}) -- self_creation = {token, tags, data, parent_id, write_module}
	local token = self_creation[1]

	local self = setmetatable({
		Tags = self_creation[2],
		Data = self_creation[3],
		Id = id,
		Token = token,

		self_creation = self_creation,
		set_listeners = {}, -- [key] = {[connection] = true, ...}, ...

	}, Replica)

	return self
end

function Replica.RequestData()
	if DataRequestStarted == true then return end

	DataRequestStarted = true

	task.spawn(function()
		local status = Events.RequestData.Call()
		while task.wait(REQUEST_DATA_REPEAT) do
			if status == "Success" then
				Replica.IsReady = true

				print(`[ReplicaClient]: Initial data received`)
				break
			else
				status = Events.RequestData.Call()
			end
		end
	end)
end

function Replica.OnNew(token: string, listener: (replica: Replica) -> ()): Signal
	local listeners = NewReplicaListeners[token]

	if listeners == nil then
		listeners = {}
		NewReplicaListeners[token] = listeners
	end

	local existing_replicas = TokenReplicas[token]
	local onNewSignal = Signal.new()
	listeners[onNewSignal] = true

	onNewSignal:Connect(listener)

	if existing_replicas ~= nil then
		for replica in pairs(existing_replicas) do
			onNewSignal:Fire(replica)
		end
	end

	return onNewSignal
end


function Replica:OnSet(path: {}, listener: () -> ()): Signal
	local path_key = table.concat(path, ".")
	local listeners = self.set_listeners[path_key]

	if listeners == nil then
		listeners = {}
		self.set_listeners[path_key] = listeners
	end

	local onSetSignal = Signal.new()
	listeners[onSetSignal] = true

	onSetSignal:Connect(listener)

	return onSetSignal
end



function Replica:Set(path: {string}, value: any)
	-- Apply local change:
	local pointer = self.Data
	for i = 1, #path - 1 do
		pointer = pointer[path[i]]
	end
	local last_key = path[#path]
	local old_value = pointer[last_key]
	pointer[last_key] = value


	-- Firing signals:
	if next(self.set_listeners) ~= nil then
		local listeners = self.set_listeners[table.concat(path, ".")]
		if listeners ~= nil then
			for signal: Signal in pairs(listeners) do
				signal:Fire(value, old_value)
			end
		end
	end
end

local function DestroyReplica(replica)
	local id = replica.Id

	-- Clear replica references:
	local token_replicas = TokenReplicas[replica.Token]
	if token_replicas ~= nil then
		token_replicas[replica] = nil
	end
	if Replicas[id] == replica then
		Replicas[id] = nil
	end
end


local function CreationScan(nested_creation, iterator, parent_id)
	local entries = nested_creation[parent_id]
	if entries ~= nil then

		table.sort(entries, function(a, b)
			return a.Id < b.Id
		end)

		for _, entry in ipairs(entries) do
			iterator(entry.Id, entry.SelfCreation)
			CreationScan(nested_creation, iterator, entry.Id)
		end

	end
end

local function BreadthCreationSort(creation: {}, root_id: number?, iterator: (Id: number, SelfCreation: table) -> ())

	-- self_creation = {token, tags, data, parent_id, write_module}
	local top_creation = {} -- {Id = id, SelfCreation = self_creation}, ...
	local nested_creation = {} -- [parent_id] = {{Id = id, SelfCreation = self_creation}, ...}, ...
	local error_creation = {} -- {Id = id, SelfCreation = self_creation}, ... -- Missing parents

	for string_id, self_creation in pairs(creation) do
		local entry = {Id = tonumber(string_id), SelfCreation = self_creation}
		local parent_id = self_creation[4]
		if parent_id == 0 or entry.Id == root_id then
			table.insert(top_creation, entry)
		elseif creation[tostring(parent_id)] ~= nil then
			local entries = nested_creation[parent_id]
			if entries == nil then
				entries = {}
				nested_creation[parent_id] = entries
			end
			table.insert(entries, entry)
		else
			table.insert(error_creation, entry)
		end
	end

	table.sort(top_creation, function(a, b)
		return a.Id < b.Id
	end)

	local result = {}

	for _, entry in ipairs(top_creation) do
		iterator(entry.Id, entry.SelfCreation)
		CreationScan(nested_creation, iterator, entry.Id)
	end

	return result

end

local function GetInternalReplica(id)
	local replica = Replicas[id] or BindReplicas[id]
	if replica == nil then
		return nil
	end
	return replica
end

----- Init -----

Events.SetData.On(function(id: number, path: {}, value: any)
	local replica = GetInternalReplica(id)

	replica:Set(path, value)
end)

Events.CreateData.On(function(creation: {}, root_id: number?) -- (creation) or ({creation, ...})
	local announce_buffer = {} -- {replica, ...} -- Announce these

	BreadthCreationSort(creation, root_id, function(id: number, self_creation: {}) -- self_creation = {token, tags, data, parent_id, write_module}
		local parent_id = self_creation[4]
		local replica = ReplicaNew(id, self_creation)
		local is_bind_buffered = false

		if parent_id == 0 then -- Top replica

		elseif BindReplicas[parent_id] ~= nil then
			is_bind_buffered = true
		end

		if is_bind_buffered == true then
			BindReplicas[id] = replica
		else

			local token = replica.Token
			local token_replicas = TokenReplicas[token]

			if token_replicas == nil then
				token_replicas = {}
				TokenReplicas[token] = token_replicas
			end

			token_replicas[replica] = true
			Replicas[id] = replica

			table.insert(announce_buffer, replica)
		end
	end)

	for _, replica in ipairs(announce_buffer) do
		local listeners = NewReplicaListeners[replica.Token]
		if listeners ~= nil then
			for signal: Signal in pairs(listeners) do
				signal:Fire(replica)
			end
		end
	end
end)

Events.DestroyData.On(function(id: number)
	local replica = GetInternalReplica(id)

	DestroyReplica(replica)
end)


return Replica
