--!nocheck

local PFS = game:GetService("PathfindingService")
local RepS = game:GetService("ReplicatedStorage")

local Signal = require(RepS.HarukaShared.Shared.Signal)


local PathCreator = {}
PathCreator.__index = PathCreator

--// Helper functions

local function _setJumpState(humanoid: Humanoid)
    pcall(function()
		if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end
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
    if self.Waypoints[self.CurWaypoint].Action == Enum.PathWaypointAction.Jump then
		_setJumpState(self.Humanoid)
	end
	self.Humanoid:MoveTo(self.Waypoints[self.CurWaypoint].Position)
end
local function _moveToFinished(self: table, isReached: boolean)
    if not getmetatable(self) then return end

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

	if self.Position.StuckCount >= self._settings.COMPARISON_CHECKS then
		if self._settings.JUMP_WHEN_STUCK then
			_setJumpState(self.Humanoid)
		end

        self.Events.Errored:Fire("AgentStuck")
	end
end


--// Constructor
function PathCreator.new(npc: Model, pfsArgs: table)
    if not npc:IsA("Model") or not npc:FindFirstChild("Humanoid") then return end

    local self = setmetatable({
        Settings = {
            TimeLimit = 0.07,
            ComparisonCheckTimes = 1,
            JumpWhenStuck = true
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
        lastTick = 0,
        Position = {
            LastPos = Vector3.zero,
            StuckCount = 0
        }

    }, PathCreator)


    self.PathObj.Blocked:Connect(function(blockedIndex: number)
        if (self.CurWaypoint <= blockedIndex and self.CurWaypoint + 1 >= blockedIndex) and self.Humanoid then
            _setJumpState(self.Humanoid)

            self.Events.Blocked:Fire(self.NPC, self.Waypoints[blockedIndex])
        end
    end)


    return self
end

--// Start to let npc follow the path
function PathCreator:Run(targetPos: Vector3)
    if not targetPos then return end

    --// limit the computation
    if os.clock() - self.LastTick <= self.Settings.TimeLimit and self.Humanoid then
		task.wait(os.clock() - self.LastTick)
		return

	elseif self.Humanoid then
		self.LastTick = os.clock()
	end

    local pathComputed, _ = pcall(function()
        self.PathObj:ComputeAsync(self.NPC.PrimaryPart.Position, targetPos)
    end)

    --// make sure path computation is successful
    if not pathComputed
        or self.PathObj.Status == Enum.PathStatus.NoPath
        or #self.PathObj:GetWaypoints() < 2
        or (self.Humanoid and self.Humanoid:GetState() == Enum.HumanoidStateType.Freefall) then

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
end


--// Clears the path object
function PathCreator:Destroy()
    for _, event: Signal in self.Events do
        event:Destroy()
    end
    self.PathObj:Destroy()

    setmetatable(self, nil)
    for i, _ in self do
        self[i] = nil
    end
end
