--!nocheck

local HttpService = game:GetService("HttpService")
local PPS = game:GetService("ProximityPromptService")
local RepS = game:GetService("ReplicatedStorage")

local Fusion = require(RepS.HarukaShared.Shared.Fusion)

return function (self: table)
	local function Value(val: any)
		return Fusion.Value(self.scope, val)
	end

    self.promptsList = Value({})
	self.currentPromptIndex = Value(1)

	--// Connections

	local scope = self.scope :: Fusion.Scope
	local mouse = self.plr:GetMouse() :: Mouse

	local promptContainer = Instance.new("Folder")
	promptContainer.Name = "HARUKA_PromptContainer"
	promptContainer.Parent = self.char
	table.insert(scope, promptContainer)


	local function _updatePromptList()
		task.wait()
		self.promptsList:set(promptContainer:GetChildren())
	end
	table.insert(scope, promptContainer.ChildAdded:Connect(_updatePromptList))
	table.insert(scope, promptContainer.ChildRemoved:Connect(_updatePromptList))


	local function _addPrompt(prompt: ProximityPrompt)
		self.currentPromptIndex:set(1)

		local uid = HttpService:GenerateGUID(false)
		prompt:SetAttribute("UUID", uid)

		local promptSymbol = Instance.new("ObjectValue")
		promptSymbol.Value = prompt
		promptSymbol.Name = uid
		promptSymbol.Parent = promptContainer
	end
	local function _removePrompt(prompt: ProximityPrompt)
		local totalPrompts = promptContainer:GetChildren()
		local promptIndex = table.find(totalPrompts, prompt)
		local uid = prompt:GetAttribute("UUID") :: string

		if not uid then return end
		if promptIndex then
			if promptIndex == Fusion.peek(self.currentPromptIndex) then
				self.currentPromptIndex:set(1)
			end
		end

		if promptContainer:FindFirstChild(uid) then promptContainer[uid]:Destroy() end
	end
	table.insert(scope, PPS.PromptShown:Connect(_addPrompt))
	table.insert(scope, PPS.PromptHidden:Connect(_removePrompt))


	local function _mouseBackward()
		local index = Fusion.peek(self.currentPromptIndex) :: number
		local nextIndex = index + 1

		if nextIndex > #promptContainer:GetChildren() then nextIndex = 1 end

		self.currentPromptIndex:set(nextIndex)
	end
	local function _mouseForward()
		local index = Fusion.peek(self.currentPromptIndex) :: number
		local nextIndex = index - 1

		if nextIndex <= 0 then nextIndex = #promptContainer:GetChildren() end

		self.currentPromptIndex:set(nextIndex)
	end
	table.insert(scope, mouse.WheelBackward:Connect(_mouseBackward))
	table.insert(scope, mouse.WheelForward:Connect(_mouseForward))
end
