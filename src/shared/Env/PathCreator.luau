--!nocheck

local PFS = game:GetService("PathfindingService")
local RepS = game:GetService("ReplicatedStorage")

local Signal = require(RepS.HarukaShared.Shared.Signal)


local PathCreator = {}
PathCreator.__index = PathCreator

--// Helper functions

local function _invokeWaypointReached(self: table)
    local lastWaypoint = self.Waypoints[self.CurWaypoint - 1]
	local nextWaypoint = self.Waypoints[self.CurWaypoint]

	self.Events.WaypointReached:Fire(self.NPC, lastWaypoint, nextWaypoint)
end
local function _disconnectMoveConns(self: table)
    self.moveConn:Disconnect()
	self.moveConn = nil
end
local function _moveNPC(self: table)
	self.Humanoid:MoveTo(self.Waypoints[self.CurWaypoint].Position)
end
local function _moveToFinished(self: table, isReached: boolean)
    if isReached and self.CurWaypoint + 1 <= #self.Waypoints then
        if self.CurWaypoint + 1 < #self.Waypoints then
            _invokeWaypointReached(self)
        end
        self.CurWaypoint += 1

        _moveNPC(self)

    elseif isReached then
        _disconnectMoveConns(self)

        self.Status = "Idle"
        self.Events.Reached:Fire(self.NPC, self.Waypoints[self.CurWaypoint])
    else
        _disconnectMoveConns(self)
        self.Status = "Idle"

        self.Events.Errored:Fire("TargetUnreachable")
    end
end
local function _comparePosition(self: table)
	if self.CurWaypoint == #self.Waypoints then return end

	self.Position.StuckCount = ((self.NPC.PrimaryPart.Position - self.Position.LastPos).Magnitude <= 0.07 and (self.Position.StuckCount + 1)) or 0
	self.Position.LastPos = self.NPC.PrimaryPart.Position

	if self.Position.StuckCount >= self.Settings.ComparisonCheckTimes then
        self.Events.Errored:Fire("AgentStuck")
	end
end


--// Constructor
function PathCreator.new(npc: Model, pfsArgs: table)
    local self = setmetatable({
        Settings = {
            TimeLimit = 0.07,
            ComparisonCheckTimes = 1
        },
        Events = {
            Errored = Signal.new(),
            Reached = Signal.new(),
            WaypointReached = Signal.new(),
            Blocked = Signal.new(),
            Stopped = Signal.new(),
        },

        NPC = npc,
        Humanoid = npc.Humanoid,
        PathObj = PFS:CreatePath(pfsArgs),
        Status = "Idle",
        LastTick = 0,
        Position = {
            LastPos = Vector3.zero,
            StuckCount = 0
        }

    }, PathCreator)

    return self
end

--// Start to let npc follow the path
function PathCreator:Run(targetPos: Vector3, previousAsyncResult: boolean)
    if not targetPos then return end

    --// limit the computation
    if os.clock() - self.LastTick <= self.Settings.TimeLimit and self.Humanoid then
		task.wait(os.clock() - self.LastTick)
		return

	elseif self.Humanoid then
		self.LastTick = os.clock()
	end

    if previousAsyncResult == nil then
        previousAsyncResult = self:IsPathValid(targetPos)
    end
    if previousAsyncResult == false then
        task.wait()
        self.Events.Errored:Fire("ComputationError")
        return
    end


    --// pathfinding starts
    self.Status = (self.Humanoid and "Active") or "Idle"
    self.Target = targetPos

    --// set network owner to server to prevent "hops"
    pcall(function()
        self.NPC.PrimaryPart:SetNetworkOwner(nil)
    end)

    --// add waypoints
    self.Waypoints = self.PathObj:GetWaypoints()
    self.CurWaypoint = 2

    --// in case npc stucks
    if self.Humanoid then _comparePosition(self) end


    self.moveConn = self.Humanoid and (self.moveConn or self.Humanoid.MoveToFinished:Connect(function(...)
        _moveToFinished(self, ...)
    end))

    if self.Humanoid then
        self.Humanoid:MoveTo(self.Waypoints[self.CurWaypoint].Position)

    elseif #self.Waypoints == 2 then
        self.Target = nil
        self.Events.Reached:Fire(self.NPC, self.Waypoints[2])
    end

    return true
end


--// stop the npc from following the path
function PathCreator:Stop()
	if self.Status == "Idle" then return end

	_disconnectMoveConns(self)

	self.Status = "Idle"
	self.Events.Stopped:Fire(self.NPC)
    self.Events.Reached:Fire()
end


--[[
    Help compute whether the path is ok for npcs
]]
function PathCreator:IsPathValid(targetPos: Vector3)
    local pathComputed, _ = pcall(function()
        self.PathObj:ComputeAsync(self.NPC.PrimaryPart.Position, targetPos)
    end)

    --// make sure path computation is successful
    if not pathComputed
        or self.PathObj.Status == Enum.PathStatus.NoPath
        or #self.PathObj:GetWaypoints() < 2
        or (self.Humanoid and self.Humanoid:GetState() == Enum.HumanoidStateType.Freefall) then

        return false
    end

    return true
end


--// Clears the path object
function PathCreator:Destroy()
    for _, event: Signal in self.Events do
        event:Destroy()
    end
    self.PathObj:Destroy()

    self = nil
end

return PathCreator
