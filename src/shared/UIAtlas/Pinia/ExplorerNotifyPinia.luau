--!nocheck

local Debris = game:GetService("Debris")
local RepS = game:GetService("ReplicatedStorage")

local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local Bindables = RepS.HarukaShared.UIAtlas.Bindables
local Events = RepS.HarukaShared.UIAtlas.Events

return function (self: table)
	self.scope = Fusion.scoped({})

    local function Value(val: any) : any
        return Fusion.Value(self.scope, val)
    end

	self.displayOrder = 1
    self.hintsList = Value({})

    self.fullScreenText = Value("")
    self.fullScreenTrans = Value(1)

	--// Connections
	local scope = self.scope

	---
	local hintFolder = Instance.new("Folder")
	hintFolder.Name = "HARUKA_UINotify"
	hintFolder.Parent = self.char
	table.insert(self.scope, hintFolder)

	local function updateHints()
		task.wait()
		self.hintsList:set(hintFolder:GetChildren())
	end
	table.insert(scope, hintFolder.ChildAdded:Connect(updateHints))
	table.insert(scope, hintFolder.ChildRemoved:Connect(updateHints))


	local function _createHint(text: string)
		self.displayOrder += 1
		if self.displayOrder > 999 then self.displayOrder = 1 end

		local hint = Instance.new("StringValue")
		hint.Name = "Hint_"..HarukaLib:GenerateUUID()
		hint.Value = HarukaLib:RichTextify(text)
		hint.Parent = hintFolder
		Debris:AddItem(hint, 3)
	end
	local function _createFSHint(text: string, state: boolean)
		self.fullScreenTrans:set(if state then 0 else 1)
		self.fullScreenText:set(text)
	end
	table.insert(scope, Events.CreateNotify.OnClientEvent:Connect(_createHint))
	table.insert(scope, Events.CreateFSNotify.OnClientEvent(_createFSHint))
	table.insert(scope, Bindables.CreateNotify.Event:Connect(_createHint))
	table.insert(scope, Bindables.CreateFSNotify.Event:Connect(_createFSHint))
end
