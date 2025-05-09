--!nocheck

local CAS = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Signal = require(RepS.HarukaShared.Shared.Signal)
local Promise = require(RepS.HarukaShared.Shared.Promise)

local wait = task.wait

local HarukaLib = {}

--[[
	Helper function to convert a number to a string with a suffix.

    **Example:**
    ``````lua
    HarukaLib:NumberConvert(1000, 2) --- 1.00K
    ``````
]]
function HarukaLib:NumberConvert(number: number, decimalPlaces: number) : string
	local prefixes = { "", "K", "M", "B", "T", "Q", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd" }
	local abbrFactor = math.floor(math.floor(math.log10(number)) / 3)

	decimalPlaces = decimalPlaces or 2
    local outputType = "%.".. tostring(decimalPlaces).. "f"

	if abbrFactor > 0 then
		if prefixes[abbrFactor + 1] then
			return string.format(outputType, number / 10 ^ (abbrFactor * 3)) .. prefixes[abbrFactor + 1]
		end
	end

	return tostring(number)
end


--[[
    Get the device type
]]
function HarukaLib:GetDevice() : "PC" | "Mobile" | "Console" | "VR"
	local device = "PC"

	if GuiService:IsTenFootInterface() then device = "Console" end
	if UIS.TouchEnabled then device = "Mobile" end
	if UIS.VREnabled then device = "VR" end

	return device
end


--[[
    Get the accurate device type
]]
function HarukaLib:GetAccurateDevice() : "PC" | "Xbox" | "PlayStation" | "Phone" | "Tablet" | "VR"
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


--[[
	Increase attribute value for an instance.
	It will not work if attribute is not a number.

	But it will create a default value (0) if attribute is not exist.

	**Example:**
	``````lua
	obj.Health = 0
	HarukaLib:AddAttr(obj, "Health", 10) --- obj.Health = 10
	``````
]]
function HarukaLib:AddAttr(obj: Instance, attribute: string, val: number)
	if obj:GetAttribute(attribute) == nil then
		obj:SetAttribute(attribute, 0)
	end
	if typeof(obj:GetAttribute(attribute) ~= "number") then
		return
	end

	obj:SetAttribute(attribute, obj:GetAttribute(attribute) + val)
end


--[[
	The same as `obj:ClearAllChildren()`, but it applies for attributes
]]
function HarukaLib:ClearAllAttributes(obj: Instance)
	for attribute, _ in obj:GetAttributes() do obj:SetAttribute(attribute, nil) end
end


--[[
	Detect if the given position is inside any of the given regions.
]]
function HarukaLib:IsInRegion(position: Vector3, regions: { any }) : BasePart?
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


--[[
	Transform a plain text to rich text, it will only work when `RichText = true`

	**Example:**
	``````lua
	HarukaLib:RichTextify("<blue>Hello</font>,<red>World</font>!")
	``````
]]
function HarukaLib:RichTextify(text: string) : string
	if not text then return "" end

	local colorList = {
		["<blue>"] = [[<font color="#74b9ff">]],
		["<purple>"] = [[<font color="#a29bfe">]],
		["<red>"] = [[<font color="#ff6b81">]],
		["<orange>"] = [[<font color="#f9ca24">]],
		["<yellow>"] = [[<font color="#f1c40f">]],
		["<green>"] = [[<font color="#7bed9f">]],
		["<cyan>"] = [[<font color="#81ecec">]],
		["<white>"] = [[<font color="#ffffff">]],
		["<black>"] = [[<font color="#2d3436">]],
		["<pink>"] = [[<font color="#ff9ff3">]],
		["<gray>"] = [[<font color="#747d8c">]],
	}
	colorList["<grey>"] = colorList["<gray>"]

	for oriTag: string, rbxColorTag: string in colorList do
		text = string.gsub(text, oriTag, rbxColorTag)
	end

	return text
end


--[[
	Serialize and deserialize roblox types to a table.
	It only supports `CFrame`, `Vector3`, and `Color3`.
]]
function HarukaLib:Serialize(method: "Pack" | "Unpack", val: any) : any
	local valType = typeof(val)

	if method == "Pack" then
		if valType == "CFrame" then
			return { "CFrame", val:GetComponents() }

		elseif valType == "Vector3" then
			return { "Vector3", math.floor(val.X), math.floor(val.Y), math.floor(val.Z) }

		elseif valType == "Color3" then
			return { "Color3", val.R, val.G, val.B }
		else
			return val
		end

	elseif method == "Unpack" then
		if valType ~= "table" then return val end
		valType = val[1] :: string

		if valType == "CFrame" then
			return CFrame.new(unpack(val, 2, #val))

		elseif valType == "Vector3" then
			return Vector3.new(unpack(val, 2, #val))

		elseif valType == "Color3" then
			return Color3.fromRGB(unpack(val, 2, #val))
		else
			return val
		end
	end

	return val
end


--[[
	Inspired by `Fusion.Hydrate`, it will add a tracker to the given props/attrs,
	and call it funcs when the value of the prop/attr is changed.

	Return a function to destroy the tracker.
]]
function HarukaLib:Hydrate(obj: Instance, props: table)
	local Add, Empty = HarukaLib.Bin()

	for prop: string, func in props do
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


--[[
	Inspired by `Maid`, and `Fusion.doCleanup`, you can add anything to the bin.

	Return a function to destroy the items inside the bin, bin can reused.
]]
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

			elseif typeof(item.Cancel) == "function" then
				item:Cancel()

			elseif typeof(item.cancel) == "function" then
				item:cancel()

			--- cancel any exist promises
			elseif getmetatable(item) then
				if item.prototype then item:cancel() end

			elseif item[1] ~= nil then
				for index = #item, 1, -1 do
					doCleanup(item[index])

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


--[[
	Inspired by `Timer`, just like `window.setInterval` in javascript
]]
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


--[[
	Inspired by `AdvancedTweenV2`, it can tween any property of any instance.

	Return a signal class, it will fire when the tween is completed.
]]
function HarukaLib:Tween(object: Instance, style: TweenInfo, goal: table)
	local properties = {}
	local tweenSignal = Signal.new()

	local dataTypes = {
		number = function(a, b, t)
			return a + ((b - a) * t)
		end,

		V3 = function(a, b, t)
			return a:Lerp(b, t)
		end
	}
	local function fastBubbleSort(arr)
		local n = #arr
		while n > 1 do
			local newN = 0
			for i = 1, n - 1 do
				if arr[i].Time > arr[i + 1].Time then
					arr[i], arr[i + 1] = arr[i + 1], arr[i]
					newN = i
				end
			end
			n = newN
		end
	end
	dataTypes.NumberSequence = function(a, b, t)
		local keyPoints = {}

		for index: number, keypoint: NumberSequenceKeypoint in a.Keypoints do
			local nextKeypoint = b.Keypoints[index] :: NumberSequenceKeypoint

			table.insert(keyPoints, NumberSequenceKeypoint.new(
				math.clamp(dataTypes.number(keypoint.Time, nextKeypoint.Time, t), 0, 1),
				dataTypes.number(keypoint.Value, nextKeypoint.Value, t),
				dataTypes.number(keypoint.Envelope, nextKeypoint.Envelope, t)
			))
		end
		fastBubbleSort(keyPoints)

		return NumberSequence.new(keyPoints)
	end
	dataTypes.ColorSequence = function(a, b, t)
		local keyPoints = {}

		for index: number, keypoint: ColorSequenceKeypoint in a.KeyPoints do
			local nextKeypoint = b.Keypoints[index] :: ColorSequenceKeypoint

			table.insert(keyPoints, ColorSequenceKeypoint.new(
				math.clamp(dataTypes.number(keypoint.Time, nextKeypoint.Time, t), 0, 1),
				dataTypes.V3(keypoint.Value, nextKeypoint.Value, math.clamp(t, 0, 1))
			))
		end
		fastBubbleSort(keyPoints)


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
				continue
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
					object:PivotTo(dataTypes.V3(original, val, lerp))
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

			wait()
		end

		tweenSignal:Fire("Completed")
		tweenSignal:Destroy()
	end)

	return tweenSignal
end


--[[
	Inspired by `t`, it can typecheck any value in runtime
]]
function HarukaLib:TypeCheck(checkList: "Integer" | "Min" | "Max" | "MinMax", val: any, extra: {
	Min: number?,
	Max: number?
}) : boolean

	local success = pcall(function()
		if checkList == "Integer" then
			assert(type(val) == "number")
			assert(val % 1 == 0)

		elseif checkList == "Min" then
			assert(type(val) == "number")
			assert(val > extra.Min)

		elseif checkList == "Max" then
			assert(type(val) == "number")
			assert(val < extra.Max)

		elseif checkList == "MinMax" then
			assert(type(val) == "number")
			assert(val > extra.Min)
			assert(val < extra.Max)
		end
	end)

	return success
end


--[[
	Inspired by `Sol's RNG`, basically it will roll a thing depends on the weight you give

	**Example:**
	``````lua
	HarukaLib:RollLoot({
		["Gold"] = 50,
		["Diamond"] = 30,
		["Silver"] = 20
	})
	``````
]]
function HarukaLib:RollLoot(loots: { [string]: number }) : string
	local lootList = {}

	for loot: string, weight: number in loots do
		local info = {
			Name = loot,
			Weight = weight
		}
		table.insert(lootList, info)
	end

	table.sort(lootList, function(a, b)
		return a.Weight < b.Weight
	end)

	local result = Random.new(DateTime.now().UnixTimestamp):NextNumber()
	local aggregate = 0

	for _, loot: table in lootList do
		local chance = loot.Weight :: number

		if result < (chance + aggregate) / 100 then
			return loot.Name
		end

		aggregate += chance
	end
end


--[[
	Inspired by `CutsceneService`, it will fire the signal class when the cutscene is completed.
]]
function HarukaLib:PlayCutscene(pointsFolder: Folder, duration: number)
	local camera = workspace.CurrentCamera
	local cutsceneSignal = Signal.new()

	--// Helper funcs
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
	for _, point: BasePart in instances do
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

				cutsceneSignal:Fire("Completed")
				cutsceneSignal:Destroy()
			end
		end)
	end)

	return cutsceneSignal
end


--[[
	This is the util for `UIStrokeAdjustor`, return accurate thickness based on viewport size
]]
function HarukaLib:CalculateStrokeThickness(thickness: number) : number
	local VPSize = workspace.CurrentCamera.ViewportSize
	local DESIGN_SIZE = Vector2.new(1172, 466.4)

	local transformed = thickness * (math.min(VPSize.X, VPSize.Y) / math.min(DESIGN_SIZE.X, DESIGN_SIZE.Y))

	return transformed
end


--[[
	It will freeze/unfreeze player controls
]]
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


--[[
	Helper function to set the collision group of an object and its children
]]
function HarukaLib:SetCollisionGroup(obj: Instance, group: string)
	if HarukaLib:IsBasePartType(obj) then obj.CollisionGroup = group end

	for _, child: Instance in obj:GetChildren() do HarukaLib:SetCollisionGroup(child, group) end
end


--[[
	Helper function to combine id with the prefix `"rbxassetid://"`
]]
function HarukaLib:CombineRbxId(id: string | number)
    if not id then
		warn("Invalid ID")
        return "rbxassetid://0"
    end

    return "rbxassetid://".. id
end


--[[
	Helper function to ban a player, Server-Side ONLY
]]
function HarukaLib:BanPlayerByUserId(userId: number, properties: {
	Duration: number,
	DisplayReason: string,
	PrivateReason: string,
	ExcludeAltAccounts: boolean,
})
	local config = {
		UserIds = { userId },
		Duration = properties.Duration,
		DisplayReason = properties.DisplayReason,
		PrivateReason = properties.PrivateReason,
		ExcludeAltAccounts = properties.ExcludeAltAccounts,
		ApplyToUniverse = true
	}

	Promise.new(function()
		Players:BanAsync(config)

	end):catch(function(err)
		warn(tostring(err))
	end)
end


--[[
	Helper function to ban a player, Server-Side ONLY
]]
function HarukaLib:BanPlayer(plr: Player, properties: {
	Duration: number,
	DisplayReason: string,
	PrivateReason: string,
	ExcludeAltAccounts: boolean,
})
	HarukaLib:BanPlayerByUserId(plr.UserId, properties)
end


--[[
	Helper function to unban a player, Server-Side ONLY
]]
function HarukaLib:UnbanPlayerByUserId(userId: number)
	local config = {
		UserIds = { userId },
		ApplyToUniverse = true
	}

	Promise.new(function()
		Players:UnbanAsync(config)

	end):catch(function(err)
		warn(tostring(err))
	end)
end


--[[
	Helper function to tween the transparency of a UI element
]]
function HarukaLib:UITween(ui: GuiObject, style: "In" | "Out", props: {
	DelayTime: number?,
	TweenTime: number?,

	SetOriPropsWhenOut: boolean?,
	FollowOriPropsWhenIn: boolean?,
	TweenCallback: (clonedTweenOutUI: GuiObject) -> nil?,

	PosTweenStyle: "FromB2T" | "FromT2B" | "FromL2R" | "FromR2L"?,
	PosTweenBaseElement: GuiObject?,
	PosTweenOffset: number?
}?)
	props = props or {}


	if props.TweenCallback and style == "Out" then
		local clonedTweenOutUI = ui:Clone()
		clonedTweenOutUI.Parent = ui.Parent
		Debris:AddItem(clonedTweenOutUI, 1)

		ui = clonedTweenOutUI

		Promise.try(props.TweenCallback, clonedTweenOutUI)

	elseif props.TweenCallback and style == "In" then
		Promise.try(props.TweenCallback, ui)
	end

	props.DelayTime = props.DelayTime or 0
	props.TweenTime = props.TweenTime or 0.2

	local tweenInfo = TweenInfo.new(props.TweenTime,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.Out
	)
	local tweenObjs = ui:GetDescendants()
	table.insert(tweenObjs, ui)

	local function _tweenGoal(obj: GuiObject, attr: string, tweenProps: table)
		if not obj then return end
		if not obj.Parent then return end

		pcall(function()
			local original = obj[attr] :: number?
			local attrOriginal = obj:GetAttribute("HarukaUITween_Ori_"..attr) :: number?

			if style == "In" then
				obj[attr] = 1

				if original ~= 1 then tweenProps[attr] = original end
				if props.FollowOriPropsWhenIn and attrOriginal and attrOriginal ~= 1 then
					tweenProps[attr] = attrOriginal
				end

			elseif style == "Out" then
				if obj[attr] then
					tweenProps[attr] = 1

					if props.SetOriPropsWhenOut and obj:GetAttribute("HarukaUITween_Ori_"..attr) == nil then
						obj:SetAttribute("HarukaUITween_Ori_"..attr, original)
					end
				end
			end
		end)
		pcall(function()
			obj.Interactable = false
		end)
	end
	local function _startTween(obj: GuiObject, tweenProps: table)
		if not obj then return end
		if not obj.Parent then return end

		pcall(function()
			TweenService:Create(obj, tweenInfo, tweenProps):Play()
		end)
		pcall(function()
			obj.Interactable = true
		end)
	end


	for _, obj: Instance in tweenObjs do
		local tweenProps = {}

		if not obj then continue end
		if not obj.Parent then continue end

		if obj:IsA("Frame") then
			_tweenGoal(obj, "BackgroundTransparency", tweenProps)

		elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
			_tweenGoal(obj, "BackgroundTransparency", tweenProps)
			_tweenGoal(obj, "TextTransparency", tweenProps)
			_tweenGoal(obj, "TextStrokeTransparency", tweenProps)

		elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			_tweenGoal(obj, "ImageTransparency", tweenProps)
			_tweenGoal(obj, "BackgroundTransparency", tweenProps)

		elseif obj:IsA("ScrollingFrame") then
			_tweenGoal(obj, "BackgroundTransparency", tweenProps)
			_tweenGoal(obj, "ScrollBarImageTransparency", tweenProps)

		elseif obj:IsA("CanvasGroup") then
			_tweenGoal(obj, "GroupTransparency", tweenProps)

		elseif obj:IsA("UIStroke") then
			_tweenGoal(obj, "Transparency", tweenProps)
		else
			continue
		end

		if props.DelayTime > 0 then
			Promise.delay(props.DelayTime):andThenCall(_startTween, obj, tweenProps)
		else
			_startTween(obj, tweenProps)
		end
	end

	if props.PosTweenStyle and props.PosTweenBaseElement then
		local nowPos = props.PosTweenBaseElement.Position
		local goalPos = nowPos

		local offset = props.PosTweenOffset or 15.99 / 2
		local fixFactor = if style == "In" then 1 else -1

		if props.PosTweenStyle == "FromB2T" then
			goalPos = UDim2.new(nowPos.X.Scale, nowPos.X.Offset, nowPos.Y.Scale, nowPos.Y.Offset + offset * fixFactor)

		elseif props.PosTweenStyle == "FromT2B" then
			goalPos = UDim2.new(nowPos.X.Scale, nowPos.X.Offset, nowPos.Y.Scale, nowPos.Y.Offset - offset * fixFactor)

		elseif props.PosTweenStyle == "FromL2R" then
			goalPos = UDim2.new(nowPos.X.Scale, nowPos.X.Offset - offset * fixFactor, nowPos.Y.Scale, nowPos.Y.Offset)

		elseif props.PosTweenStyle == "FromR2L" then
			goalPos = UDim2.new(nowPos.X.Scale, nowPos.X.Offset + offset * fixFactor, nowPos.Y.Scale, nowPos.Y.Offset)
		end

		if style == "Out" then
			goalPos, nowPos = nowPos, goalPos
		end

		local function _tweenPosition()
			props.PosTweenBaseElement.Position = goalPos

			local tween = TweenService:Create(props.PosTweenBaseElement, tweenInfo, {
				Position = nowPos
			})
			tween:Play()
			tween.Completed:Wait()
			tween:Destroy()

			props.PosTweenBaseElement.Position = if style == "In" then nowPos else goalPos
		end

		if props.DelayTime > 0 then
			Promise.delay(props.DelayTime):andThenCall(_tweenPosition)
		else
			_tweenPosition()
		end
	end
end


--[[
	Helper function to fix the correct result of `CFrame.lookAt` in RPG series
]]
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


--[[
	Helper function to format a number with comma separator

	**Example:**
	``````lua
	HarukaLib:CommaifyNumber(123456789) -- "123,456,789"
	``````
]]
function HarukaLib:CommaifyNumber(num: number | string) : string
	if not num then return "" end

	num = tostring(num)

	local result = ""
	for i = 1, #num do
		result ..= string.sub(num, i, i)
		if (#num - i) % 3 == 0 and i ~= #num then result ..= "," end
	end

	return result
end


--[[
	Helper function to format a number of seconds into a string of time format

	**Example:**
	``````lua
	HarukaLib:TimeifyNumber(123) -- "02:03"
	``````
]]
function HarukaLib:TimeifyNumber(seconds: number, shouldScaleToMs: boolean?) : string
	if seconds == nil then return "??:??" end
	if seconds <= 0 then return "00:00" end

	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60

	if not shouldScaleToMs then
		return string.format("%02d:%02d", minutes, secs)
	else
		local ms = seconds * 1000
		minutes = math.floor(ms / 60000)

		ms %= 60000
		seconds = math.floor(ms / 1000)

		ms %= 1000

		return string.format("%d:%02d.%03d", minutes, seconds, ms)
	end
end


--[[
	A quick shortcut to `string.sub(UUID, 1, 8)`

	Example Output: `123e4567-e89b-12d3-a456-426655440000`
]]
function HarukaLib:GenerateUUID() : string
	return string.sub(HttpService:GenerateGUID(false), 1, 8)
end


--[[
	Similar with `PartCache`, but a lot simpler and faster.

	Returns:
	```lua
	local pool = HarukaLib:CreatePartPool(obj, initialAmount)

	pool:Get()
	pool:Return(obj)
	```
]]
function HarukaLib:CreatePartPool(obj: Instance, initialAmount: number?, container: Folder?)
	container = container or Instance.new("Folder")
	container.Name = "PartPool_"..obj.Name.."_"..HarukaLib:GenerateUUID()
	container.Parent = workspace


	local DISTANT_CF = CFrame.new(Vector3.one * 1599 * 40)

	initialAmount = initialAmount or 1
	initialAmount = math.ceil(initialAmount)

	obj = obj:Clone()
	obj.Parent = container

	local pool = {
		Object = obj,
		Available = {},
	}
	for _ = 1, initialAmount do
		local clone = pool.Object:Clone()
		clone.Parent = container

		table.insert(pool.Available, clone)
	end

	function pool:Get()
		local i = #pool.Available
		local finalObj = pool.Available[i]
		if finalObj then
			finalObj = table.remove(pool.Available, i)
			return finalObj
		else
			local newObj = pool.Object:Clone()
			newObj.Parent = container

			return newObj
		end
	end
	function pool:Return(object: Instance)
		object.CFrame = DISTANT_CF

		table.insert(pool.Available, object)
	end
	function pool:Destroy()
		container:Destroy()
	end

	return pool
end


--[[
	A simple function of Queue
]]
function HarukaLib.Queue()
	local Queue = {}
	Queue.__index = Queue

	function Queue.new()
		local self = setmetatable({
			First = 0,
			Last = -1,
			Queue = {},
			Locked = false,

			ElementAdded = Signal.new(),

		}, Queue)

		return self
	end


	function Queue:IsEmpty() : boolean
		return self.First > self.Last
	end
	function Queue:GetItemsInQueue() : number
		return #self.Queue
	end

	function Queue:SetLockState(state: boolean)
		self.Locked = state
	end
	function Queue:IsLocked() : boolean
		return self.Locked
	end


	function Queue:Push(value: any)
		local last = self.Last + 1
		self.Last = last
		self.Queue[last] = value

		if not self.Locked then
			self.ElementAdded:Fire()
		end
	end
	function Queue:Pop() : any?
		if self:IsEmpty() then
			return nil
		end

		local first = self.First
		local value = self.Queue[first]
		self.Queue[first] = nil
		self.First = first + 1

		return value
	end

	function Queue:Destroy()
		self.ElementAdded:Destroy()

		self = nil
	end

	return Queue.new()
end


--[[
	A list of helper functions to manipulate table
]]
function HarukaLib.TableUtils()
	local tableUtils = {}

	tableUtils.Keys = function(tbl: table) : { string }
		local keys = table.create(#tbl)

		for key: string in tbl do
			table.insert(keys, key)
		end

		return keys
	end
	tableUtils.Values = function(tbl: table) : { any }
		local values = table.create(#tbl)

		for _, value in tbl do
			table.insert(values, value)
		end

		return values
	end
	tableUtils.IsEmpty = function(tbl: table) : boolean
		return next(tbl) == nil
	end
	tableUtils.Filter = function(tbl: table, predicate: (val: any, key: any, tbl: { table }) -> boolean) : table
		local newT = table.create(#tbl)

		if #tbl > 0 then
			local n = 0
			for i, v in tbl do
				if predicate(v, i, tbl) then
					n += 1
					newT[n] = v
				end
			end
		else
			for k, v in tbl do
				if predicate(v, k, tbl) then
					newT[k] = v
				end
			end
		end

		return newT
	end
	tableUtils.Cut = function(tbl: table, len: number) : table
		local n = #tbl
		len = math.clamp(len, 1, n)

		return if len == n then table.clone(tbl) else table.move(tbl, 1, len, 1, table.create(len))
	end
	tableUtils.CheckForSome = function(tbl: table, callback: (val: any, key: any, tbl: { table }) -> boolean) : boolean
		for k, v in tbl do
			if callback(v, k, tbl) then
				return true
			end
		end

		return false
	end
	tableUtils.CheckForEvery = function(tbl: table, callback: (val: any, key: any, tbl: { table }) -> boolean) : boolean
		for k, v in tbl do
			if not callback(v, k, tbl) then
				return false
			end
		end

		return true
	end
	tableUtils.Find = function(tbl: table, callback: (val: any, key: any, tbl: { table }) -> boolean) : (Value?, Key?)
		for k, v in tbl do
			if callback(v, k, tbl) then
				return v, k
			end
		end

		return nil, nil
	end
	tableUtils.Map = function(tbl: table, callback: (val: any, key: any, tbl: { table }) -> any) : table
		local newT = table.create(#tbl)

		for k, v in tbl do
			newT[k] = callback(v, k, tbl)
		end

		return newT
	end
	tableUtils.Merge = function(tbl1: table, tbl2: table)
		local newT = table.clone(tbl1)

		for _, v in tbl2 do
			table.insert(newT, v)
		end

		return newT
	end
	tableUtils.CountDictLength = function(dict: { [any]: any }) : number
		local count = 0

		for _, _ in dict do
			count += 1
		end

		return count
	end
	tableUtils.MakePackage = function(t: table, whiteList: { string }) : table
		local newT = {}

		for key: string, val: any in table.clone(t) do
			if table.find(whiteList, key) then
				newT[key] = val
			end
		end

		return newT
	end
	tableUtils.CopyTableExcept = function(t: table, except: { string }, shouldIncludeFunc: boolean?) : table
		local newT = {}

		for key: string, val: any in t do
			if not shouldIncludeFunc then
				if typeof(val) == "function" then continue end
			end
			if table.find(except, key) then continue end

			newT[key] = val
		end

		return newT
	end
	tableUtils.Clone = function(tbl: table) : table
		return tableUtils.CopyTableExcept(tbl, {}, false)
	end

	return tableUtils
end


--[[
	A quick helper function to emit particles
]]
function HarukaLib:EmitParticles(obj: Instance)
	for _, child: ParticleEmitter in obj:GetDescendants() do
		if not child:IsA("ParticleEmitter") then continue end

		child:Emit(child:GetAttribute("EmitCount") or 0)
	end
end


--[[
	Quickly judge if it's a part
]]
function HarukaLib:IsBasePartType(obj: Instance) : boolean
	return obj:IsA("BasePart") or obj:IsA("UnionOperation") or obj:IsA("CornerWedgePart")
end


--[[
	Quickly return an empty part for mocking
]]
function HarukaLib:CreateMockPart() : BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.Name = "MockPart"
	part.Size = Vector3.one
	part.Transparency = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.CanQuery = false
	part.Massless = true
	part.CollisionGroup = "NoCollision"

	return part
end


--[[
	Quickly set all particles of an object to a state
]]
function HarukaLib:SetParticleState(obj: Instance, state: boolean)
	for _, child: ParticleEmitter in obj:GetDescendants() do
		if not child:IsA("ParticleEmitter") then continue end

		child.Enabled = state
	end
end


return HarukaLib
