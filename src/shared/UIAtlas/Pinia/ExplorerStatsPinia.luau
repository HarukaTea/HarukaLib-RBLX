--!nocheck

local PPS = game:GetService("ProximityPromptService")
local RepS = game:GetService("ReplicatedStorage")

local AssetBook = require(RepS.HarukaShared.Library.AssetBook)
local Events = require(RepS.HarukaShared.Library.Events)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local wait = task.wait

local function AdventurerStatsPinia(self: table)
    local plr = self.plr :: Player
    local char = self.char :: Model

	self.scope = Fusion.scoped({})
	local function Value(val: any)
		return Fusion.Value(self.scope, val)
	end

	self.charData = char:WaitForChild("CharStats", 999)
	self.humanoid = char.Humanoid

	self.playerData = {
		Gold = Value(0),
		RP = Value(0),
	}
	self.charStatsDict = {
		HP = { Value(char.Humanoid.Health), Value(char.Humanoid.MaxHealth) },
	}

    self.promptsList = Value({})
	self.currentPromptIndex = Value(1)

	self.countdown = Value(0)

	self.synergyFrameAbsSize = Value(Vector2.new())
	self.synergies = Value({})

	self.centerText = Value("")

	--// Connections
	local scope = self.scope

	local playerData = self.playerData
	table.insert(scope, HarukaLib:Hydrate(plr, {
		["Attr-Gold"] = function(gold: number)
			playerData.Gold:set(HarukaLib:ThreeDotNumberify(gold))
		end,
		["Attr-RP"] = function(rp: number)
			playerData.RP:set(HarukaLib:ThreeDotNumberify(rp))
		end
	}))

	local charStatsDict = self.charStatsDict
	table.insert(scope, HarukaLib:Hydrate(self.humanoid, {
		["Prop-Health"] = function(health: number)
			charStatsDict.HP[1]:set(health)
		end,
		["Prop-MaxHealth"] = function(health: number)
			charStatsDict.HP[2]:set(health)
		end
	}))

	local function hpOnChange()
		if self.HPGradient == nil then return end

		local x = math.clamp(Fusion.peek(self.charStatsDict.HP[1]) / Fusion.peek(self.charStatsDict.HP[2]), 0.001, 0.999)

		if x ~= x then x = 0.001 end
		local result = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(x - 0.001, 0),
			NumberSequenceKeypoint.new(x, 1),
			NumberSequenceKeypoint.new(1, 1)
		})

		HarukaLib:Tween(self.HPGradient, AssetBook.TweenInfos.twiceHalf, { Transparency = result })
	end
	local hpObserver = Fusion.Observer(scope, charStatsDict.HP[1])
	local maxHPObserver = Fusion.Observer(scope, charStatsDict.HP[2])

	hpObserver:onBind(hpOnChange)
	maxHPObserver:onBind(hpOnChange)

	---
	local mouse = plr:GetMouse()

	local function _addPrompt(prompt: ProximityPrompt)
		local nowPrompts = Fusion.peek(self.promptsList)

		table.insert(nowPrompts, prompt)
		self.promptsList:set(nowPrompts)
		self.currentPromptIndex:set(1)
	end
	local function _removePrompt(prompt: ProximityPrompt)
		local afterPrompts = Fusion.peek(self.promptsList)

		table.remove(afterPrompts, table.find(afterPrompts, prompt))
		self.promptsList:set(afterPrompts)
	end
	local function _triggerPrompt(prompt: ProximityPrompt)
		prompt.Enabled = false
	end
	table.insert(scope, mouse.WheelBackward:Connect(function()
		local index = Fusion.peek(self.currentPromptIndex) :: number

		self.currentPromptIndex:set(index + 1)
		if index + 1 > #Fusion.peek(self.promptsList) then self.currentPromptIndex:set(1) end
	end))
	table.insert(scope, mouse.WheelForward:Connect(function()
		local index = Fusion.peek(self.currentPromptIndex) :: number

		self.currentPromptIndex:set(index - 1)
		if index - 1 <= 0 then self.currentPromptIndex:set(#Fusion.peek(self.promptsList)) end
	end))
	table.insert(scope, PPS.PromptShown:Connect(_addPrompt))
	table.insert(scope, PPS.PromptHidden:Connect(_removePrompt))
	table.insert(scope, PPS.PromptTriggered:Connect(_triggerPrompt))


	---
	local countdownAdd, countdownEmpty = HarukaLib.Bin()
	table.insert(scope, Events.CreateTimer.On(function(data)
		countdownEmpty()

		countdownAdd(task.spawn(function()
			for i = data.Countdown, 0, -1 do
				self.countdown:set(i)
				wait(1)
			end
		end))
	end))


	---
	table.insert(scope, Events.CreateCenterNotify.On(function(data)
		self.centerText:set(data.Hint)

		wait(1.2)
		self.centerText:set("")
	end))
end

return AdventurerStatsPinia
