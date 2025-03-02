--!nocheck

local HttpService = game:GetService("HttpService")
local PPS = game:GetService("ProximityPromptService")
local RepS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Bindables = require(RepS.HarukaShared.Library.Bindables)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local FusionComponents = require(RepS.HarukaShared.UIAtlas.FusionComponents)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local wait = task.wait


return function (self: table)
	local function Value(val: any)
		return Fusion.Value(self.scope, val)
	end

	self.currentPromptIndex = Value(1)


	--// Connections

	local scope = self.scope :: Fusion.Scope
	local mouse = self.plr:GetMouse() :: Mouse


	local promptSymbolContainer = Instance.new("Folder")
	promptSymbolContainer.Name = "HARUKA_PromptSymbols"
	promptSymbolContainer.Parent = workspace
	table.insert(scope, promptSymbolContainer)

	self.promptsList = FusionComponents.useFolder(scope, promptSymbolContainer)


	--// track prompts
	local mapComponents = workspace:WaitForChild("MapComponents", 999) :: Folder

	local function _updatePrompt(prompt: ProximityPrompt)
		if not prompt:IsA("ProximityPrompt") then return end


		local part = prompt.Parent :: BasePart
		if not part:IsA("BasePart") then
			warn("Invalid prompt parent object")
			return
		end

		prompt:SetAttribute("HarukaUniqueId", HttpService:GenerateGUID(false))
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.KeyboardKeyCode = Enum.KeyCode.Home
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 15.99 * 1.599
	end
	for _, child: Instance in mapComponents:GetDescendants() do
		_updatePrompt(child)
	end
	mapComponents.DescendantAdded:Connect(_updatePrompt)


	table.insert(scope, PPS.PromptTriggered:Connect(function(thatPrompt: ProximityPrompt, thatPlayer: Player)
		if thatPlayer ~= self.plr then return end

		SoundService.SFXs.ChatNext:Play()

		Bindables.RequestToChangePromptState:Fire(thatPrompt)
	end))
	table.insert(scope, PPS.PromptShown:Connect(function(prompt: ProximityPrompt)
		local uniqueId = prompt:GetAttribute("HarukaUniqueId") :: string

		if promptSymbolContainer:FindFirstChild(uniqueId) then return end

		local symbol = Instance.new("ObjectValue")
		symbol.Value = prompt
		symbol.Name = uniqueId
		symbol.Parent = promptSymbolContainer
	end))
	table.insert(scope, PPS.PromptHidden:Connect(function(prompt: ProximityPrompt)
		local uniqueId = prompt:GetAttribute("HarukaUniqueId") :: string

		if promptSymbolContainer:FindFirstChild(uniqueId) then
			promptSymbolContainer[uniqueId]:Destroy()
		end
	end))


	local promptListObserver = Fusion.Observer(scope, self.promptsList)
	promptListObserver:onBind(function()
		local totalPrompts = #Fusion.peek(self.promptsList)
		local validIndex = Fusion.peek(self.currentPromptIndex)

		if totalPrompts > 0 and validIndex == 0 then
			validIndex = 1
		end
		validIndex = math.clamp(validIndex, 0, totalPrompts)

		self.currentPromptIndex:set(validIndex)
	end)


	--// track index
	local function _setIndex(nextIndex: number)
		nextIndex = math.clamp(nextIndex, 0, #Fusion.peek(self.promptsList))

		self.currentPromptIndex:set(nextIndex)
	end
	table.insert(scope, mouse.WheelBackward:Connect(function()
		_setIndex(Fusion.peek(self.currentPromptIndex) + 1)
	end))
	table.insert(scope, mouse.WheelForward:Connect(function()
		_setIndex(Fusion.peek(self.currentPromptIndex) - 1)
	end))


	--// activate
	table.insert(scope, UserInputService.InputBegan:Connect(function(inputObj, gpe)
		if gpe then return end

		if inputObj.KeyCode == Enum.KeyCode.F then
			if #Fusion.peek(self.promptsList) <= 0 then return end

			local currentPromptIndex = Fusion.peek(self.currentPromptIndex) :: number
			local currentPrompt = Fusion.peek(self.promptsList)[currentPromptIndex].Value :: ProximityPrompt

			currentPrompt:InputHoldBegin()
		end
	end))
end
