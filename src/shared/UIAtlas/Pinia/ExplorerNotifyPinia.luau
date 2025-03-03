--!nocheck

local Debris = game:GetService("Debris")
local RepS = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Bindables = require(RepS.HarukaShared.Library.Bindables)
local Events = require(RepS.HarukaShared.Library.Events)
local Signal = require(RepS.HarukaShared.Shared.Signal)

local NormalHint = require(RepS.HarukaShared.UIAtlas.UniversalComponents.NormalHint)
local ConfirmPrompt = require(RepS.HarukaShared.UIAtlas.UniversalComponents.ConfirmPrompt)
local CenterNotifyBar = require(RepS.HarukaShared.UIAtlas.UniversalComponents.CenterNotifyBar)
local FullNotify = require(RepS.HarukaShared.UIAtlas.UniversalComponents.FullNotify)

local wait = task.wait

return function (self: table)
	self.scope = Fusion.scoped()

    local function Value(val: any) : Fusion.Value
        return Fusion.Value(self.scope, val)
    end
	local scope = self.scope :: Fusion.Scope


	self.fsHintsQueue = HarukaLib.Queue()
	self.centerHintsQueue = HarukaLib.Queue()
	self.confirmPromptsQueue = HarukaLib.Queue()
	table.insert(scope, self.fsHintsQueue)
	table.insert(scope, self.centerHintsQueue)
	table.insert(scope, self.confirmPromptsQueue)



	--// receive hint requests
	local order = 1
	local function _createHint(text: string)
		order += 1
		if order > 999 then order = 1 end


		local normalHint = NormalHint(scope, {
			Text = HarukaLib:RichTextify(text),
			LayoutOrder = order,
		})
		Debris:AddItem(normalHint, 3.5)


		HarukaLib:UITween(normalHint, "In", { TweenTime = 0.5 })
		HarukaLib:UITween(normalHint, "Out", { TweenTime = 0.5, DelayTime = 2.5 })
	end
	table.insert(scope, Events.CreateNotify.On(_createHint))
	table.insert(scope, Bindables.CreateNotify:Connect(_createHint))



	--// receive fs hint requests
	local function _createFSHint(text: string, duration: number)
		self.fsHintsQueue:Push({
			Text = text, Duration = duration
		})
	end
	local function _onFSHintAdded()
		if self.fsHintsQueue:IsBusy() then return end

		local nextHint = self.fsHintsQueue:Pop() :: {
			Text: string, Duration: number
		}

		self.fsHintsQueue:SetBusyState(true)

		local fullNotify = FullNotify(scope, {
			Text = nextHint.Text,
		})
		Debris:AddItem(fullNotify, nextHint.Duration + 1)


		HarukaLib:UITween(fullNotify, "In", { TweenTime = 0.5 })


		task.wait(nextHint.Duration)
		do
			self.fsHintsQueue:SetBusyState(false)

			HarukaLib:UITween(fullNotify, "Out")

			if not self.fsHintsQueue:IsEmpty() then
				_onFSHintAdded()
			end
		end
	end
	table.insert(scope, Events.CreateFSNotify.On(_createFSHint))
	table.insert(scope, Bindables.CreateFSNotify:Connect(_createFSHint))
	table.insert(scope, self.fsHintsQueue.ElementAdded:Connect(_onFSHintAdded))


	--// receive center hint requests
	local function _createCenterNotify(text: string, showBar: boolean)
		self.centerHintsQueue:Push({
			Text = text, ShowBar = showBar
		})
	end
	local function _onCenterHintAdded()
		if self.centerHintsQueue:IsBusy() then return end

		local nextHint = self.centerHintsQueue:Pop() :: {
			Text: string, ShowBar: boolean
		}

		self.centerHintsQueue:SetBusyState(true)

		local notifyBar = CenterNotifyBar(scope, {
			Text = nextHint.Text,
			ShowBar = nextHint.ShowBar
		})
		Debris:AddItem(notifyBar, 2)


		HarukaLib:UITween(notifyBar, "In", { TweenTime = 0.5 })
		HarukaLib:UITween(notifyBar, "Out", { TweenTime = 0.5, DelayTime = 1.4 - 0.5 })
		wait(1.5)
		do
			self.centerHintsQueue:SetBusyState(false)

			if not self.centerHintsQueue:IsEmpty() then
				_onCenterHintAdded()
			end
		end
	end
	table.insert(scope, Events.CreateCenterNotify.On(_createCenterNotify))
	table.insert(scope, Bindables.CreateCenterNotify:Connect(_createCenterNotify))
	table.insert(scope, self.centerHintsQueue.ElementAdded:Connect(_onCenterHintAdded))


	--// receive confirm prompt requests
	local function _createConfirmPrompt(data: {
		Hint: string,
		ConfirmText: string,
		CancelText: string,

		ConfirmUniqueId: string
	})
		self.confirmPromptsQueue:Push(data)
	end
	local function _onConfirmPromptAdded()
		if self.confirmPromptsQueue:IsBusy() then return end

		local nextPrompt = self.confirmPromptsQueue:Pop() :: {
			Hint: string,
			ConfirmText: string,
			CancelText: string,
			ConfirmUniqueId: string
		}

		self.confirmPromptsQueue:SetBusyState(true)

		local confirmScope = Fusion.scoped()
		local resultSignal = Signal.new()
		table.insert(confirmScope, resultSignal)

		local UI = ConfirmPrompt(confirmScope, {
			Hint = nextPrompt.Hint,
			ConfirmText = nextPrompt.ConfirmText,
			CancelText = nextPrompt.CancelText,

			ResultSignal = resultSignal,
		})

		local finalResult = resultSignal:Wait()

		Bindables.ConfirmPromptChosen:Fire(nextPrompt.ConfirmUniqueId, finalResult)

		HarukaLib:UITween(UI, "Out", {
			TweenCallback = function(tweenOutUI: GuiObject)
				Fusion.doCleanup(confirmScope)

				tweenOutUI.Full:Destroy()

				HarukaLib:UITween(tweenOutUI, "Out", {
					PosTweenStyle = "FromT2B",
					PosTweenBaseElement = tweenOutUI.Center.ConfirmPrompt,
				})
			end
		})

		--// process next prompt
		do
			self.confirmPromptsQueue:SetBusyState(false)

			if not self.confirmPromptsQueue:IsEmpty() then
				_onConfirmPromptAdded()
			end
		end
	end
	table.insert(scope, Bindables.CreateConfirmPrompt:Connect(_createConfirmPrompt))
	table.insert(scope, self.confirmPromptsQueue.ElementAdded:Connect(_onConfirmPromptAdded))



	--// system message display
	local function _displaySystemMessage(text: string)
		TextChatService.TextChannels.RBXSystem:DisplaySystemMessage(text)
	end
	table.insert(scope, Events.CreateSystemNotify.On(_displaySystemMessage))
	table.insert(scope, Bindables.CreateSystemNotify:Connect(_displaySystemMessage))
end
