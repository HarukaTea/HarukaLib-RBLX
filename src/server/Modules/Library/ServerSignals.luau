--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Signal = require(RepS.HarukaShared.Shared.Signal).new

return {
    ReloadCharacter = Signal(),
}
