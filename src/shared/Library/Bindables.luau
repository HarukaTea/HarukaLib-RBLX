
local RepS = game:GetService("ReplicatedStorage")

local Signal = require(RepS.HarukaShared.Shared.Signal)

return {
    CreateNotify = Signal.new(),
    CreateFSNotify = Signal.new(),
    CreateConfirmPrompt = Signal.new(),
    CreateCenterNotify = Signal.new(),

    ConfirmPromptChosen = Signal.new(),
}