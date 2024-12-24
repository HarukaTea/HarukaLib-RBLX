--!nocheck

local Debris = game:GetService("Debris")
local RepS = game:GetService("ReplicatedStorage")

local Events = require(RepS.HarukaShared.Library.Events)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Signals = require(RepS.HarukaShared.Library.Signals)

local function HintsPinia(self: table)
    self.scope = Fusion.scoped({})

    local function Value(val: any) : any
        return Fusion.Value(self.scope, val)
    end

    self.hintsList = Value({})

    self.fullScreenText = Value("")
    self.fullScreenTrans = Value(1)

	--// Connections
	local scope = self.scope

	---
	local hintFolder = Instance.new("Folder")
	hintFolder.Name = "HARUKA_Hints"
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
		if self.displayOrder == math.huge - 1 then self.displayOrder = 1 end

		local hint = Instance.new("StringValue")
		hint.Name = "Hint"
		hint.Value = HarukaLib:RichTextify(text)
		hint.Parent = hintFolder
		Debris:AddItem(hint, 3)
	end
	local function _createFSHint(text: string, state: boolean)
		self.fullScreenTrans:set(if state then 0 else 1)
		self.fullScreenText:set(text)
	end
	table.insert(scope, Events.CreateHint.On(function(data)
		_createHint(data.Hint)
	end))
	table.insert(scope, Events.CreateFullScreenHint.On(function(data)
		_createFSHint(data.Hint, data.State)
	end))
	table.insert(scope, Signals.CreateHint:Connect(_createHint))
	table.insert(scope, Signals.CreateFullScreenHint:Connect(_createFSHint))
end

return HintsPinia
