-- DebrisGobbler
-- by verret001

local DebrisGobbler: DebrisGobbler = {}
local ExpiryReferences: ExpiryReferences = {}
local InstanceReferences: InstanceReferences = {}

local BinaryHeap = require(script.BinaryHeap)

local DebrisHeap = BinaryHeap.new(function(a, b)
	return (a < b)
end)

local pairs, clock, ceil, setmetatable = pairs, os.clock, math.ceil, setmetatable

--[=[
	This flag determines if a instance is destroyed before it's expiration
	This makes insertions slower as we need to form a connection to Destroying.
	This is only useful if you have *very* long expiration times
]=]
DebrisGobbler.EARLY_DESTRUCTION_CLEARING = false

--[=[
	This flag determines the maximum accuracy where nodes should be combined.
	In normal scenarios this should be 60, unless you are running this on a client with an FPS unlocker
	where you need the exact frame accuracy.
]=]
DebrisGobbler.MAX_FPS = 20

--[=[
    Initializes DebrisGobbler, ensure this is run on a script that will not be destroyed.

    @return nil
]=]

function DebrisGobbler:Init()
	if self.Connection then
		self.Connection:Disconnect()
	end
	self.Connection = game:GetService("RunService").Heartbeat:Connect(function()
		local Node: Node | nil, Value: number = DebrisHeap:peek()
		local currentTime: number = clock() + (1 / self.MAX_FPS)

		if Node and Value < currentTime then
			ExpiryReferences[Value] = nil
			DebrisHeap:pop()

			for Item: Instance, _ in pairs(Node["Instances"]) do
				-- mmm trash, I love trash
				Item:Destroy()
				if self.EARLY_DESTRUCTION_CLEARING then
					local Item = Node["Instances"][Item]
					if typeof(Item) == "RBXScriptConnection" then
						Item:Disconnect()
					end
				end
				Node["Instances"][Item] = nil
				InstanceReferences[Item] = nil
			end
		end
	end)
end

--[=[
    Adds an item to be destroyed in a specific amount of time.

    @param Item Instance -- The instance to destroy
    @param Time number -- The delta time to destruction Default: 7
    @return number -- Returns the CPU time of destruction
]=]
function DebrisGobbler:AddItem(Item: Instance, Time: number?): number
	assert(typeof(Item) == "Instance", "Invalid argument #1, expected type Instance")
	assert(typeof(Time) == "number" or Time == nil, "Invalid argument #2, expected type number?")
	if not self.Connection or self.Connection.Connected == false then
		warn(
			"DebrisGobbler.Connection disconnected due to likely script destruction. Ensure DebrisGobbler:Init() is on a persistent script."
		)
		self:Init()
	end

	-- We're locked to 60fps, so we can save on # of nodes by rounding to the next nearest frame.
	local ExpiryTime: number = ceil((clock() + (Time or 7)) * self.MAX_FPS) / self.MAX_FPS

	if InstanceReferences[Item] then
		local Node: Node = InstanceReferences[Item] :: Node
		if Node['ExpiryTime'] < ExpiryTime then
			return Node['ExpiryTime']
		end
		self:RemoveItem(Item)
	end

	local Node: Node = ExpiryReferences[ExpiryTime] :: Node

	if Node == nil then
		Node = { ["ExpiryTime"] = ExpiryTime, ["n"] = 0, ["Instances"] = {} } :: Node
		ExpiryReferences[ExpiryTime] = Node
		DebrisHeap:insert(ExpiryTime, Node)
	end

	if self.EARLY_DESTRUCTION_CLEARING then
		Node["Instances"][Item] = Item.Destroying:Connect(function()
			self:RemoveItem(Item)
		end)
	else
		Node["Instances"][Item] = true
	end

	InstanceReferences[Item] = Node
	Node["n"] += 1

	return ExpiryTime
end

--[=[
    Removes an item from any destruction queues.

    @param Item Instance -- The instance to remove from the destruction queue
    @return boolean -- Returns if the item was removed from the queue
]=]
function DebrisGobbler:RemoveItem(Item: Instance): boolean
	assert(typeof(Item) == "Instance", "Invalid argument #1, expected type Instance")
	local Node: Node = InstanceReferences[Item]
	if Node then
		if self.EARLY_DESTRUCTION_CLEARING then
			local Item = Node["Instances"][Item]
			if typeof(Item) == "RBXScriptConnection" then
				Item:Disconnect()
			end
		end

		Node["Instances"][Item] = nil
		InstanceReferences[Item] = nil

		Node["n"] -= 1
		if Node["n"] == 0 then
			DebrisHeap:removeNode(Node)
			ExpiryReferences[Node] = nil
		end
	end

	return not not Node
end

type Node = { ["Instances"]: { [Instance]: boolean | RBXScriptConnection }, ["n"]: number, ["ExpiryTime"]: number }
type ExpiryReferences = { [number]: Node }
type InstanceReferences = { [Instance]: Node }
type DebrisGobbler = typeof(DebrisGobbler)

return DebrisGobbler :: DebrisGobbler