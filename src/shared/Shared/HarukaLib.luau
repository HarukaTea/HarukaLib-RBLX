--!nocheck

local CAS = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Signal = require(RepS.HarukaShared.Shared.Signal)
local Promise = require(RepS.HarukaShared.Shared.Promise)

local HarukaLib = {}


function HarukaLib:NumberConvert(number: number, type: string) : string
	local prefixes = { "", "K", "M", "B", "T", "Q", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd" }
	local abbrFactor = math.floor(math.floor(math.log10(number)) / 3)

	if abbrFactor > 0 then
		if prefixes[abbrFactor + 1] then
			return string.format(type, number / 10 ^ (abbrFactor * 3)) .. prefixes[abbrFactor + 1]
		end
	end

	return tostring(number)
end


function HarukaLib:GetDevice() : "PC" | "Mobile" | "Console" | "VR"
	local device = "PC"

	if GuiService:IsTenFootInterface() then device = "Console" end
	if UIS.TouchEnabled then device = "Mobile" end
	if UIS.VREnabled then device = "VR" end

	return device
end


function HarukaLib:GetAccurateDevice() : "PC" | "Tablet" | "Phone" | "Xbox" | "PlayStation" | "VR"
	local device = "PC"

	if GuiService:IsTenFootInterface() then
		local key = Enum.KeyCode.ButtonA

		if UIS:GetStringForKeyCode(key) == "ButtonA" then device = "Xbox" end
		if UIS:GetStringForKeyCode(key) == "ButtonCross" then device = "PlayStation" end
	end
	if UIS.TouchEnabled then
		local screenSize = workspace.CurrentCamera.ViewportSize

		if screenSize.X < screenSize.Y then
			if screenSize.X < 600 then device = "Phone" else device = "Tablet" end

		elseif screenSize.X > screenSize.Y then
			if screenSize.Y < 600 then device = "Phone" else device = "Tablet" end
		end
	end
	if UIS.VREnabled then device = "VR" end

	return device
end


function HarukaLib:AddAttr(obj: Instance, attribute: string, val: number)
	if obj:GetAttribute(attribute) == nil then obj:SetAttribute(attribute, 0) end

	obj:SetAttribute(attribute, obj:GetAttribute(attribute) + val)
end


function HarukaLib:ClearAllAttributes(obj: Instance)
	for attribute, _ in obj:GetAttributes() do obj:SetAttribute(attribute, nil) end
end


function HarukaLib:IsInRegion(position: Vector3, regions: table) : BasePart
	local region: BasePart = nil

	for _, child: BasePart in regions do
		if not child:IsA("BasePart") then continue end

		local point = child.CFrame:PointToObjectSpace(position)

		if math.abs(point.X) < child.Size.X / 2
			and math.abs(point.Y) < child.Size.Y / 2
			and math.abs(point.Z) < child.Size.Z / 2 then

			region = child
			break
		end
	end

	return region
end


function HarukaLib:RichTextify(text: string) : string
	if not text then return "" end

	local colorList = {
		["<blue>"] = [[<font color="#70a1ff">]],
		["<purple>"] = [[<font color="#5352ed">]],
		["<red>"] = [[<font color="#ff4757">]],
		["<orange>"] = [[<font color="#ffa502">]],
		["<yellow>"] = [[<font color="#ffda79">]],
		["<green>"] = [[<font color="#7bed9f">]],
	}

	for oriTag: string, rbxColorTag: string in colorList do
		text = string.gsub(text, oriTag, rbxColorTag)
	end

	return text
end


function HarukaLib:Serialize(val: CFrame | Vector3 | Color3) : any
	local valType = typeof(val)

	if valType == "CFrame" then
		return { "CFrame", val:GetComponents() }

	elseif valType == "Vector3" then
		return { "Vector3", math.floor(val.X), math.floor(val.Y), math.floor(val.Z) }

	elseif valType == "Color3" then
		return { "Color3", val.R, val.G, val.B }

	else
		return val --- return default
	end
end
function HarukaLib:Deserialize(val: table) : any
	if typeof(val) ~= "table" then return val end

	local valType = val[1] :: string

	if valType == "CFrame" then
		return CFrame.new(unpack(val, 2, #val))

	elseif valType == "Vector3" then
		return Vector3.new(unpack(val, 2, #val))

	elseif valType == "Color3" then
		return Color3.fromRGB(unpack(val, 2, #val))

	else
		return valType
	end
end


function HarukaLib:Hydrate(obj: Instance, props: table)
	local Add, Empty = HarukaLib.Bin()

	for prop, func in props do
		if string.find(prop, "Attr") then
			local _, endPos = string.find(prop, "Attr")
			local attr = string.sub(prop, endPos + 2)

			func(obj:GetAttribute(attr))

			Add(obj:GetAttributeChangedSignal(attr):Connect(function()
				func(obj:GetAttribute(attr))
			end))

		elseif string.find(prop, "Prop") then
			local _, endPos = string.find(prop, "Prop")
			local propName = string.sub(prop, endPos + 2)

			func(obj[propName])

			Add(obj:GetPropertyChangedSignal(propName):Connect(function()
				func(obj[propName])
			end))
		end
	end

	return Empty
end



function HarukaLib.Bin()
	local bin = {}

	local function doCleanup(item: any)
		if typeof(item) == "Instance" then
			item:Destroy()

		elseif typeof(item) == "RBXScriptConnection" then
			item:Disconnect()

		elseif typeof(item) == "function" then
			task.spawn(item)

		elseif typeof(item) == "thread" then
			if item then task.cancel(item) end

		elseif typeof(item) == "table" then
			if typeof(item.destroy) == "function" then
				item:destroy()

			elseif typeof(item.Destroy) == "function" then
				item:Destroy()

			elseif item[1] ~= nil then
				for index = #item, 1, -1 do
					pcall(doCleanup, item[index])

					item[index] = nil
				end
			end
		end
	end

	return function (item: any)
		table.insert(bin, item)

		return item

	end, function()
		pcall(doCleanup, bin)

		table.clear(bin)
	end
end


function HarukaLib.Clock(tickTime: number, func: () -> ())
	local nowTime = 0
	local dropTime = tickTime * 10

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		nowTime += deltaTime

		if nowTime > dropTime then
			nowTime = 0
			func()

		elseif nowTime > tickTime then
			nowTime -= tickTime

			func()
		end
	end)

	return function ()
		connection:Disconnect()
	end
end


function HarukaLib:Tween(object: Instance, style: TweenInfo, goal: table)
	local properties = {}
	local signal = Signal.new()

	local dataTypes = {
		number = function(a, b, t)
			return a + ((b - a) * t)
		end,

		Vector3 = function(a, b, t)
			return a:Lerp(b, t)
		end
	}
	dataTypes.NumberSequence = function(a, b, t)
		local keyPoints = {}

		for index: number, keypoint: NumberSequenceKeypoint in a.Keypoints do
			local nextKeypoint = b.Keypoints[index] :: NumberSequenceKeypoint

			table.insert(keyPoints, NumberSequenceKeypoint.new(
				dataTypes.number(keypoint.Time, nextKeypoint.Time, t),
				dataTypes.number(keypoint.Value, nextKeypoint.Value, t),
				dataTypes.number(keypoint.Envelope, nextKeypoint.Envelope, t)
			))
		end

		return NumberSequence.new(keyPoints)
	end
	dataTypes.ColorSequence = function(a, b, t)
		local keyPoints = {}

		for index: number, keypoint: ColorSequenceKeypoint in a.KeyPoints do
			local nextKeypoint = b.Keypoints[index] :: ColorSequenceKeypoint

			table.insert(keyPoints, ColorSequenceKeypoint.new(
				dataTypes.number(keypoint.Time, nextKeypoint.Time, t),
				dataTypes.Vector3(keypoint.Value, nextKeypoint.Value, math.clamp(t, 0, 1))
			))
		end

		return ColorSequence.new(keyPoints)
	end
	dataTypes.NumberRange = function(a, b, t)
		return NumberRange.new(
			dataTypes.number(a.Min, b.Min, t),
			dataTypes.number(a.Max, b.Max, t)
		)
	end

	--// fill properties
	for name: string, _: any in goal do
		if name == "Pivot" then
			if not object:IsA("PVInstance") then
				warn(name.." is not allowed for this object! "..object:GetFullName())
				return
			end

			properties[name] = object:GetPivot()
		else
			properties[name] = object[name]
		end
	end

	--- update task
	local startTime = tick()
	task.defer(function()
		local reverse = false
		local repeated = 0

		while true do
			if not object.Parent then break end

			local alpha = (tick() - startTime) / style.Time
			local t = math.min(alpha, 1)

			if style.Reverses then alpha = 1 - t end

			-- Update
			local lerp = TweenService:GetValue(alpha, style.EasingStyle, style.EasingDirection)

			for name: string, val: any in goal do
				local original = properties[name]

				if name == "Pivot" then
					object:PivotTo(dataTypes.Vector3(original, val, lerp))
				else
					object[name] = dataTypes[typeof(val)](original, val, lerp)
				end
			end

			if t == 1 then
				if style.Reverses and not reverse then
					reverse = true
					startTime = tick()

				elseif repeated ~= style.RepeatCount then
					repeated += 1
					reverse = false
					startTime = tick()

				else
					break
				end
			end

			task.wait()
		end

		signal:Fire("Completed")
		signal:Destroy()
	end)

	return signal
end


function HarukaLib:TypeCheck(checkTask: "Integer" | "Min" | "Max" | "MinMax", val: any, extra: number?, extra2: number?) : boolean
	local success = pcall(function()
		if checkTask == "Integer" then
			assert(type(val) == "number")
			assert(val % 1 == 0)

		elseif checkTask == "Min" then
			assert(type(val) == "number")
			assert(val >= extra)

		elseif checkTask == "Max" then
			assert(type(val) == "number")
			assert(val <= extra)

		elseif checkTask == "MinMax" then
			assert(type(val) == "number")
			assert(val > extra)
			assert(val < extra2)
		end
	end)

	return success
end


function HarukaLib:RollLoot(loots: { [string]: number }) : string
	local lootList = {}

	for loot: string, weight: number in loots do
		local info = {
			Name = loot,
			Weight = weight
		}
		lootList[#lootList + 1] = info
	end

	-- simple sort
	table.sort(lootList, function(a, b)
		return a.Weight < b.Weight
	end)

	--- start to roll
	local result = Random.new():NextNumber()
	local aggregate = 0

	for _, loot: table in lootList do
		local chance = loot.Weight :: number

		if result < (chance + aggregate) / 100 then
			lootList = nil --// GC

			return loot.Name
		end

		aggregate += chance
	end
end


function HarukaLib:PlayCutscene(pointsFolder: Folder | Model, duration: number)
	local camera = workspace.CurrentCamera
	local signal = Signal.new()

	--// Private
	local function _getCF(points: table, t: number) : CFrame
		local copy = { unpack(points) }

		local n = #copy
		for j = 1, n - 1 do
			for k = 1, n - j do
				copy[k] = copy[k]:Lerp(copy[k + 1], t)
			end
		end
		return copy[1]
	end

	--- sort points
	local points = {}
	local instances = pointsFolder:GetChildren()

	table.sort(instances, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	for _, point: BasePart in ipairs(instances) do
		table.insert(points, point.CFrame)
	end

	--- play
	camera.CameraType = Enum.CameraType.Scriptable

	local priority = Enum.RenderPriority.Camera.Value + 1
	local start = os.clock()
	local passedTime = 0

	pcall(function()
		RunService:BindToRenderStep("HarukaCutscene", priority, function()
			passedTime = os.clock() - start

			if passedTime <= duration then
				camera.CFrame = _getCF(points, passedTime / duration)
			else
				RunService:UnbindFromRenderStep("HarukaCutscene")

				signal:Fire("Completed")
				signal:Destroy()
			end
		end)
	end)

	return signal
end


function HarukaLib:UIStrokeCalculate(thickness: number) : number
	local VPSize = workspace.CurrentCamera.ViewportSize
	local DesignSize = Vector2.new(1172, 466.4)

	local transformed = thickness * (math.min(VPSize.X, VPSize.Y) / math.min(DesignSize.X, DesignSize.Y))

	return transformed
end


function HarukaLib:FreezePlayerControls(action: "Freeze" | "Unfreeze")
    if action == "Freeze" then
        UIS.ModalEnabled = true

        CAS:BindActionAtPriority("FreezeControl", function()
            return Enum.ContextActionResult.Sink
        end, false, Enum.ContextActionPriority.High.Value, unpack(Enum.PlayerActions:GetEnumItems()))
    else
        UIS.ModalEnabled = false

        CAS:UnbindAction("FreezeControl")
    end
end


function HarukaLib:SetCollisionGroup(object: Instance, group: string)
	if object:IsA("BasePart") or object:IsA("UnionOperation") or object:IsA("CornerWedgePart") then object.CollisionGroup = group end

	for _, child: Instance in object:GetChildren() do HarukaLib:SetCollisionGroup(child, group) end
end


function HarukaLib:CombineRbxId(id: string?)
    if not id then
        warn("[ClientUtil]: Invalid Id")
        return "rbxassetid://0"
    end

    return "rbxassetid://".. id
end


function HarukaLib:BanPlayer(plr: Player, properties: {
	Duration: number,
	DisplayReason: string,
	PrivateReason: string,
	ExcludeAltAccounts: boolean,
})
	local config = {
		UserIds = { plr.UserId },
		Duration = properties.Duration,
		DisplayReason = properties.DisplayReason,
		PrivateReason = properties.PrivateReason,
		ExcludeAltAccounts = properties.ExcludeAltAccounts,
		ApplyToUniverse = true
	}

	Promise.new(function()
		Players:BanAsync(config)

	end):catch(function(err)
		warn(err)
	end)
end


function HarukaLib:UITween(ui: GuiObject, method: string, properties: {
	DelayTime: number?,
	ForceGoal: number?,
	TweenTime: number?
}?)
	properties = properties or {}

	local delaySec = properties.DelayTime or 0
	local forceGoal = properties.ForceGoal or nil
	local tweenTime = TweenInfo.new(properties.TweenTime or 0.2)

	local transparencyProperties = {
		"BackgroundTransparency",
		"TextTransparency",
		"TextStrokeTransparency",
		"Transparency",
		"ImageTransparency",
		"GroupTransparency",
		"ScrollBarImageTransparency"
	}
	local tweenObjs = ui:GetDescendants()
	table.insert(tweenObjs, ui)

	local function _tweenGoal(obj: GuiObject, attr: string, tweenProps: table)
		if not obj then return end
		if attr == "Transparency" and not obj:IsA("UIStroke") then return end

		pcall(function()
			local original = obj[attr]

			if method == "In" then
				obj[attr] = 1
				if original ~= 1 then tweenProps[attr] = forceGoal or original end

			elseif method == "Out" then
				if obj[attr] then tweenProps[attr] = 1 end
			end
		end)
		pcall(function()
			obj.Interactable = false
		end)
	end
	local function _startTween(obj: GuiObject, tweenProps: table)
		if not obj then return end
		if not obj.Parent then return end

		TweenService:Create(obj, tweenTime, tweenProps):Play()

		pcall(function()
			obj.Interactable = true
		end)
	end

	for _, obj in tweenObjs do
		local tweenProps = {}
		for _, attr in transparencyProperties do
			_tweenGoal(obj, attr, tweenProps)
		end

		if delaySec > 0 then
			Promise.delay(delaySec):andThenCall(_startTween, obj, tweenProps)
		else
			_startTween(obj, tweenProps)
		end
	end
end


function HarukaLib:LoadModules(module: ModuleScript | Folder, plr: Player)
	for _, child in module:GetChildren() do
		if child:IsA("ModuleScript") then require(child)(plr) end
	end

	if module:IsA("ModuleScript") then require(module)(plr) end
end


function HarukaLib:CFLookAt(pos1: Vector3, pos2: Vector3) : CFrame
	local finalCFrame = CFrame.identity
	local lookAt = CFrame.lookAt(pos1, pos2)

	if lookAt == lookAt then
		finalCFrame = CFrame.new(pos1) * lookAt.Rotation

		local _, ry, _ = finalCFrame:ToOrientation()
		finalCFrame = CFrame.new(finalCFrame.Position) * CFrame.Angles(0, ry, 0).Rotation
	end

	return finalCFrame
end


function HarukaLib:ThreeDotNumberify(num: number | string) : string
	if not num then return "" end

	num = tostring(num)

	local result = ""
	for i = 1, #num do
		result ..= string.sub(num, i, i)
		if (#num - i) % 3 == 0 and i ~= #num then result ..= "," end
	end

	return result
end


function HarukaLib:FromNumberToTime(seconds: number) : string
	if seconds == nil then return "??:??" end
	if seconds <= 0 then return "00:00" end

	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60

	return string.format("%02d:%02d", minutes, secs)
end

return HarukaLib
