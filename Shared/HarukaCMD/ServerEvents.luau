--!native
--!optimize 2
--!nocheck
--!nolint
--#selene: allow(unused_variable, global_usage)
-- Server generated by Zap v0.6.25 (https://github.com/red-blox/zap)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local outgoing_buff: buffer
local outgoing_used: number
local outgoing_size: number
local outgoing_inst: { Instance }
local outgoing_apos: number
local outgoing_ids: { number }

local incoming_buff: buffer
local incoming_read: number
local incoming_inst: { Instance }
local incoming_ipos: number
local incoming_ids: { number }

-- thanks to https://dom.rojo.space/binary.html#cframe
local CFrameSpecialCases = {
	CFrame.Angles(0, 0, 0),
	CFrame.Angles(math.rad(90), 0, 0),
	CFrame.Angles(0, math.rad(180), math.rad(180)),
	CFrame.Angles(math.rad(-90), 0, 0),
	CFrame.Angles(0, math.rad(180), math.rad(90)),
	CFrame.Angles(0, math.rad(90), math.rad(90)),
	CFrame.Angles(0, 0, math.rad(90)),
	CFrame.Angles(0, math.rad(-90), math.rad(90)),
	CFrame.Angles(math.rad(-90), math.rad(-90), 0),
	CFrame.Angles(0, math.rad(-90), 0),
	CFrame.Angles(math.rad(90), math.rad(-90), 0),
	CFrame.Angles(0, math.rad(90), math.rad(180)),
	CFrame.Angles(0, math.rad(-90), math.rad(180)),
	CFrame.Angles(0, math.rad(180), math.rad(0)),
	CFrame.Angles(math.rad(-90), math.rad(-180), math.rad(0)),
	CFrame.Angles(0, math.rad(0), math.rad(180)),
	CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
	CFrame.Angles(0, math.rad(0), math.rad(-90)),
	CFrame.Angles(0, math.rad(-90), math.rad(-90)),
	CFrame.Angles(0, math.rad(-180), math.rad(-90)),
	CFrame.Angles(0, math.rad(90), math.rad(-90)),
	CFrame.Angles(math.rad(90), math.rad(90), 0),
	CFrame.Angles(0, math.rad(90), 0),
	CFrame.Angles(math.rad(-90), math.rad(90), 0),
}

local function alloc(len: number)
	if outgoing_used + len > outgoing_size then
		while outgoing_used + len > outgoing_size do
			outgoing_size = outgoing_size * 2
		end

		local new_buff = buffer.create(outgoing_size)
		buffer.copy(new_buff, 0, outgoing_buff, 0, outgoing_used)

		outgoing_buff = new_buff
	end

	outgoing_apos = outgoing_used
	outgoing_used = outgoing_used + len

	return outgoing_apos
end

local function read(len: number)
	local pos = incoming_read
	incoming_read = incoming_read + len

	return pos
end

local function save()
	return {
		buff = outgoing_buff,
		used = outgoing_used,
		size = outgoing_size,
		inst = outgoing_inst,
		outgoing_ids = outgoing_ids,
		incoming_ids = incoming_ids,
	}
end

local function load(data: {
	buff: buffer,
	used: number,
	size: number,
	inst: { Instance },
	outgoing_ids: { number },
	incoming_ids: { number },
})
	outgoing_buff = data.buff
	outgoing_used = data.used
	outgoing_size = data.size
	outgoing_inst = data.inst
	outgoing_ids = data.outgoing_ids
	incoming_ids = data.incoming_ids
end

local function load_empty()
	outgoing_buff = buffer.create(64)
	outgoing_used = 0
	outgoing_size = 64
	outgoing_inst = {}
	outgoing_ids = {}
	incoming_ids = {}
end

load_empty()

local types = {}

local polling_queues_reliable = {}
local polling_queues_unreliable = {}
if not RunService:IsRunning() then
	local noop = function() end
	return table.freeze({
		SendEvents = noop,
		RequestToExecuteCommand = table.freeze({
			SetCallback = noop
		}),
		RequestCommands_Response = table.freeze({
			Fire = noop,
			FireExcept = noop,
			FireList = noop,
			FireSet = noop
		}),
		RequestCommands_Request = table.freeze({
			SetCallback = noop
		}),
	}) :: Events
end
local Players = game:GetService("Players")

if RunService:IsClient() then
	error("Cannot use the server module on the client!")
end

local remotes = ReplicatedStorage:FindFirstChild("Ark")
if remotes == nil then
	remotes = Instance.new("Folder")
	remotes.Name = "Ark"
	remotes.Parent = ReplicatedStorage
end

local reliable = remotes:FindFirstChild("Kaltsit_RELIABLE")
if reliable == nil then
	reliable = Instance.new("RemoteEvent")
	reliable.Name = "Kaltsit_RELIABLE"
	reliable.Parent = remotes
end

local player_map = {}

local function load_player(player: Player)
	if player_map[player] then
		load(player_map[player])
	else
		load_empty()
	end
end

Players.PlayerRemoving:Connect(function(player)
	player_map[player] = nil
end)

local function SendEvents()
	for player, outgoing in player_map do
		if outgoing.used > 0 then
			local buff = buffer.create(outgoing.used)
			buffer.copy(buff, 0, outgoing.buff, 0, outgoing.used)

			reliable:FireClient(player, buff, outgoing.inst)

			outgoing.buff = buffer.create(64)
			outgoing.used = 0
			outgoing.size = 64
			table.clear(outgoing.inst)
		end
	end
end

RunService.Heartbeat:Connect(SendEvents)

local reliable_events = table.create(2)
reliable.OnServerEvent:Connect(function(player, buff, inst)
	incoming_buff = buff
	incoming_inst = inst
	incoming_read = 0
	incoming_ipos = 0
	local len = buffer.len(buff)
	while incoming_read < len do
		local id = buffer.readu8(buff, read(1))
		if id == 1 then
			local value
			local bool_1 = buffer.readu8(incoming_buff, read(1))
			value = {  }
			if bit32.btest(bool_1, 0b0000000000000001) then
				local len_1 = buffer.readu16(incoming_buff, read(2))
				value["Command"] = buffer.readstring(incoming_buff, read(len_1), len_1)
			else
				value["Command"] = nil
			end
			if reliable_events[1] then
				task.spawn(reliable_events[1], player, value)
			end
		elseif id == 0 then
			local value
			if reliable_events[0] then
				task.spawn(reliable_events[0], player, value)
			end
		else
			error("Unknown event id")
		end
	end
end)
table.freeze(polling_queues_reliable)
table.freeze(polling_queues_unreliable)

local returns = {
	SendEvents = SendEvents,
	RequestToExecuteCommand = {
		SetCallback = function(Callback: (Player: Player, Value: ({
			["Command"]: ((string)?),
		})) -> ()): () -> ()
			reliable_events[1] = Callback
			return function()
				reliable_events[1] = nil
			end
		end,
	},
	RequestCommands_Response = {
		Fire = function(Player: Player, Value: ({
			["Commands"]: ({ ({
				["Name"]: (string),
				["Alias"]: (string),
				["RankReq"]: (number),
				["Args"]: ({ ({
					["Name"]: (string),
					["Type"]: (string),
					["EnumItems"]: (({ (string) })?),
					["ShouldBeInteger"]: ((boolean)?),
					["RangeMin"]: ((number)?),
					["RangeMax"]: ((number)?),
				}) }),
			}) }),
		}))
			load_player(Player)
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 0)
			local len_2 = #Value["Commands"]
			alloc(2)
			buffer.writeu16(outgoing_buff, outgoing_apos, len_2)
			for i_1 = 1, len_2 do
				local val_1 = Value["Commands"][i_1]
				local len_3 = #val_1["Name"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_3)
				alloc(len_3)
				buffer.writestring(outgoing_buff, outgoing_apos, val_1["Name"], len_3)
				local len_4 = #val_1["Alias"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_4)
				alloc(len_4)
				buffer.writestring(outgoing_buff, outgoing_apos, val_1["Alias"], len_4)
				alloc(1)
				buffer.writeu8(outgoing_buff, outgoing_apos, val_1["RankReq"])
				local len_5 = #val_1["Args"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_5)
				for i_2 = 1, len_5 do
					local bool_2 = 0
					local bool_2_pos_1 = alloc(1)
					local val_2 = val_1["Args"][i_2]
					local len_6 = #val_2["Name"]
					alloc(2)
					buffer.writeu16(outgoing_buff, outgoing_apos, len_6)
					alloc(len_6)
					buffer.writestring(outgoing_buff, outgoing_apos, val_2["Name"], len_6)
					local len_7 = #val_2["Type"]
					alloc(2)
					buffer.writeu16(outgoing_buff, outgoing_apos, len_7)
					alloc(len_7)
					buffer.writestring(outgoing_buff, outgoing_apos, val_2["Type"], len_7)
					if val_2["EnumItems"] ~= nil then
						bool_2 = bit32.bor(bool_2, 0b0000000000000001)
						local len_8 = #val_2["EnumItems"]
						alloc(2)
						buffer.writeu16(outgoing_buff, outgoing_apos, len_8)
						for i_3 = 1, len_8 do
							local val_3 = val_2["EnumItems"][i_3]
							local len_9 = #val_3
							alloc(2)
							buffer.writeu16(outgoing_buff, outgoing_apos, len_9)
							alloc(len_9)
							buffer.writestring(outgoing_buff, outgoing_apos, val_3, len_9)
						end
					end
					if val_2["ShouldBeInteger"] ~= nil then
						bool_2 = bit32.bor(bool_2, 0b0000000000000010)
						if val_2["ShouldBeInteger"] then
							bool_2 = bit32.bor(bool_2, 0b0000000000000100)
						end
					end
					if val_2["RangeMin"] ~= nil then
						bool_2 = bit32.bor(bool_2, 0b0000000000001000)
						alloc(2)
						buffer.writei16(outgoing_buff, outgoing_apos, val_2["RangeMin"])
					end
					if val_2["RangeMax"] ~= nil then
						bool_2 = bit32.bor(bool_2, 0b0000000000010000)
						alloc(2)
						buffer.writei16(outgoing_buff, outgoing_apos, val_2["RangeMax"])
					end
					buffer.writeu8(outgoing_buff, bool_2_pos_1, bool_2)
				end
			end
			player_map[Player] = save()
		end,
		FireExcept = function(Except: Player, Value: ({
			["Commands"]: ({ ({
				["Name"]: (string),
				["Alias"]: (string),
				["RankReq"]: (number),
				["Args"]: ({ ({
					["Name"]: (string),
					["Type"]: (string),
					["EnumItems"]: (({ (string) })?),
					["ShouldBeInteger"]: ((boolean)?),
					["RangeMin"]: ((number)?),
					["RangeMax"]: ((number)?),
				}) }),
			}) }),
		}))
			load_empty()
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 0)
			local len_10 = #Value["Commands"]
			alloc(2)
			buffer.writeu16(outgoing_buff, outgoing_apos, len_10)
			for i_4 = 1, len_10 do
				local val_4 = Value["Commands"][i_4]
				local len_11 = #val_4["Name"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_11)
				alloc(len_11)
				buffer.writestring(outgoing_buff, outgoing_apos, val_4["Name"], len_11)
				local len_12 = #val_4["Alias"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_12)
				alloc(len_12)
				buffer.writestring(outgoing_buff, outgoing_apos, val_4["Alias"], len_12)
				alloc(1)
				buffer.writeu8(outgoing_buff, outgoing_apos, val_4["RankReq"])
				local len_13 = #val_4["Args"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_13)
				for i_5 = 1, len_13 do
					local bool_3 = 0
					local bool_3_pos_1 = alloc(1)
					local val_5 = val_4["Args"][i_5]
					local len_14 = #val_5["Name"]
					alloc(2)
					buffer.writeu16(outgoing_buff, outgoing_apos, len_14)
					alloc(len_14)
					buffer.writestring(outgoing_buff, outgoing_apos, val_5["Name"], len_14)
					local len_15 = #val_5["Type"]
					alloc(2)
					buffer.writeu16(outgoing_buff, outgoing_apos, len_15)
					alloc(len_15)
					buffer.writestring(outgoing_buff, outgoing_apos, val_5["Type"], len_15)
					if val_5["EnumItems"] ~= nil then
						bool_3 = bit32.bor(bool_3, 0b0000000000000001)
						local len_16 = #val_5["EnumItems"]
						alloc(2)
						buffer.writeu16(outgoing_buff, outgoing_apos, len_16)
						for i_6 = 1, len_16 do
							local val_6 = val_5["EnumItems"][i_6]
							local len_17 = #val_6
							alloc(2)
							buffer.writeu16(outgoing_buff, outgoing_apos, len_17)
							alloc(len_17)
							buffer.writestring(outgoing_buff, outgoing_apos, val_6, len_17)
						end
					end
					if val_5["ShouldBeInteger"] ~= nil then
						bool_3 = bit32.bor(bool_3, 0b0000000000000010)
						if val_5["ShouldBeInteger"] then
							bool_3 = bit32.bor(bool_3, 0b0000000000000100)
						end
					end
					if val_5["RangeMin"] ~= nil then
						bool_3 = bit32.bor(bool_3, 0b0000000000001000)
						alloc(2)
						buffer.writei16(outgoing_buff, outgoing_apos, val_5["RangeMin"])
					end
					if val_5["RangeMax"] ~= nil then
						bool_3 = bit32.bor(bool_3, 0b0000000000010000)
						alloc(2)
						buffer.writei16(outgoing_buff, outgoing_apos, val_5["RangeMax"])
					end
					buffer.writeu8(outgoing_buff, bool_3_pos_1, bool_3)
				end
			end
			local buff, used, inst = outgoing_buff, outgoing_used, outgoing_inst
			for _, player in Players:GetPlayers() do
				if player ~= Except then
					load_player(player)
					alloc(used)
					buffer.copy(outgoing_buff, outgoing_apos, buff, 0, used)
					table.move(inst, 1, #inst, #outgoing_inst + 1, outgoing_inst)
					player_map[player] = save()
				end
			end
		end,
		FireList = function(List: { [unknown]: Player }, Value: ({
			["Commands"]: ({ ({
				["Name"]: (string),
				["Alias"]: (string),
				["RankReq"]: (number),
				["Args"]: ({ ({
					["Name"]: (string),
					["Type"]: (string),
					["EnumItems"]: (({ (string) })?),
					["ShouldBeInteger"]: ((boolean)?),
					["RangeMin"]: ((number)?),
					["RangeMax"]: ((number)?),
				}) }),
			}) }),
		}))
			load_empty()
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 0)
			local len_18 = #Value["Commands"]
			alloc(2)
			buffer.writeu16(outgoing_buff, outgoing_apos, len_18)
			for i_7 = 1, len_18 do
				local val_7 = Value["Commands"][i_7]
				local len_19 = #val_7["Name"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_19)
				alloc(len_19)
				buffer.writestring(outgoing_buff, outgoing_apos, val_7["Name"], len_19)
				local len_20 = #val_7["Alias"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_20)
				alloc(len_20)
				buffer.writestring(outgoing_buff, outgoing_apos, val_7["Alias"], len_20)
				alloc(1)
				buffer.writeu8(outgoing_buff, outgoing_apos, val_7["RankReq"])
				local len_21 = #val_7["Args"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_21)
				for i_8 = 1, len_21 do
					local bool_4 = 0
					local bool_4_pos_1 = alloc(1)
					local val_8 = val_7["Args"][i_8]
					local len_22 = #val_8["Name"]
					alloc(2)
					buffer.writeu16(outgoing_buff, outgoing_apos, len_22)
					alloc(len_22)
					buffer.writestring(outgoing_buff, outgoing_apos, val_8["Name"], len_22)
					local len_23 = #val_8["Type"]
					alloc(2)
					buffer.writeu16(outgoing_buff, outgoing_apos, len_23)
					alloc(len_23)
					buffer.writestring(outgoing_buff, outgoing_apos, val_8["Type"], len_23)
					if val_8["EnumItems"] ~= nil then
						bool_4 = bit32.bor(bool_4, 0b0000000000000001)
						local len_24 = #val_8["EnumItems"]
						alloc(2)
						buffer.writeu16(outgoing_buff, outgoing_apos, len_24)
						for i_9 = 1, len_24 do
							local val_9 = val_8["EnumItems"][i_9]
							local len_25 = #val_9
							alloc(2)
							buffer.writeu16(outgoing_buff, outgoing_apos, len_25)
							alloc(len_25)
							buffer.writestring(outgoing_buff, outgoing_apos, val_9, len_25)
						end
					end
					if val_8["ShouldBeInteger"] ~= nil then
						bool_4 = bit32.bor(bool_4, 0b0000000000000010)
						if val_8["ShouldBeInteger"] then
							bool_4 = bit32.bor(bool_4, 0b0000000000000100)
						end
					end
					if val_8["RangeMin"] ~= nil then
						bool_4 = bit32.bor(bool_4, 0b0000000000001000)
						alloc(2)
						buffer.writei16(outgoing_buff, outgoing_apos, val_8["RangeMin"])
					end
					if val_8["RangeMax"] ~= nil then
						bool_4 = bit32.bor(bool_4, 0b0000000000010000)
						alloc(2)
						buffer.writei16(outgoing_buff, outgoing_apos, val_8["RangeMax"])
					end
					buffer.writeu8(outgoing_buff, bool_4_pos_1, bool_4)
				end
			end
			local buff, used, inst = outgoing_buff, outgoing_used, outgoing_inst
			for _, player in List do
				load_player(player)
				alloc(used)
				buffer.copy(outgoing_buff, outgoing_apos, buff, 0, used)
				table.move(inst, 1, #inst, #outgoing_inst + 1, outgoing_inst)
				player_map[player] = save()
			end
		end,
		FireSet = function(Set: { [Player]: any }, Value: ({
			["Commands"]: ({ ({
				["Name"]: (string),
				["Alias"]: (string),
				["RankReq"]: (number),
				["Args"]: ({ ({
					["Name"]: (string),
					["Type"]: (string),
					["EnumItems"]: (({ (string) })?),
					["ShouldBeInteger"]: ((boolean)?),
					["RangeMin"]: ((number)?),
					["RangeMax"]: ((number)?),
				}) }),
			}) }),
		}))
			load_empty()
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 0)
			local len_26 = #Value["Commands"]
			alloc(2)
			buffer.writeu16(outgoing_buff, outgoing_apos, len_26)
			for i_10 = 1, len_26 do
				local val_10 = Value["Commands"][i_10]
				local len_27 = #val_10["Name"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_27)
				alloc(len_27)
				buffer.writestring(outgoing_buff, outgoing_apos, val_10["Name"], len_27)
				local len_28 = #val_10["Alias"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_28)
				alloc(len_28)
				buffer.writestring(outgoing_buff, outgoing_apos, val_10["Alias"], len_28)
				alloc(1)
				buffer.writeu8(outgoing_buff, outgoing_apos, val_10["RankReq"])
				local len_29 = #val_10["Args"]
				alloc(2)
				buffer.writeu16(outgoing_buff, outgoing_apos, len_29)
				for i_11 = 1, len_29 do
					local bool_5 = 0
					local bool_5_pos_1 = alloc(1)
					local val_11 = val_10["Args"][i_11]
					local len_30 = #val_11["Name"]
					alloc(2)
					buffer.writeu16(outgoing_buff, outgoing_apos, len_30)
					alloc(len_30)
					buffer.writestring(outgoing_buff, outgoing_apos, val_11["Name"], len_30)
					local len_31 = #val_11["Type"]
					alloc(2)
					buffer.writeu16(outgoing_buff, outgoing_apos, len_31)
					alloc(len_31)
					buffer.writestring(outgoing_buff, outgoing_apos, val_11["Type"], len_31)
					if val_11["EnumItems"] ~= nil then
						bool_5 = bit32.bor(bool_5, 0b0000000000000001)
						local len_32 = #val_11["EnumItems"]
						alloc(2)
						buffer.writeu16(outgoing_buff, outgoing_apos, len_32)
						for i_12 = 1, len_32 do
							local val_12 = val_11["EnumItems"][i_12]
							local len_33 = #val_12
							alloc(2)
							buffer.writeu16(outgoing_buff, outgoing_apos, len_33)
							alloc(len_33)
							buffer.writestring(outgoing_buff, outgoing_apos, val_12, len_33)
						end
					end
					if val_11["ShouldBeInteger"] ~= nil then
						bool_5 = bit32.bor(bool_5, 0b0000000000000010)
						if val_11["ShouldBeInteger"] then
							bool_5 = bit32.bor(bool_5, 0b0000000000000100)
						end
					end
					if val_11["RangeMin"] ~= nil then
						bool_5 = bit32.bor(bool_5, 0b0000000000001000)
						alloc(2)
						buffer.writei16(outgoing_buff, outgoing_apos, val_11["RangeMin"])
					end
					if val_11["RangeMax"] ~= nil then
						bool_5 = bit32.bor(bool_5, 0b0000000000010000)
						alloc(2)
						buffer.writei16(outgoing_buff, outgoing_apos, val_11["RangeMax"])
					end
					buffer.writeu8(outgoing_buff, bool_5_pos_1, bool_5)
				end
			end
			local buff, used, inst = outgoing_buff, outgoing_used, outgoing_inst
			for player in Set do
				load_player(player)
				alloc(used)
				buffer.copy(outgoing_buff, outgoing_apos, buff, 0, used)
				table.move(inst, 1, #inst, #outgoing_inst + 1, outgoing_inst)
				player_map[player] = save()
			end
		end,
	},
	RequestCommands_Request = {
		SetCallback = function(Callback: (Player: Player) -> ()): () -> ()
			reliable_events[0] = Callback
			return function()
				reliable_events[0] = nil
			end
		end,
	},
}
type Events = typeof(returns)
return returns
