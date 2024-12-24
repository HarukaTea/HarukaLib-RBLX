--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local Signal = require(RepS.HarukaShared.Shared.Signal).new

return {
	CreateHint = Signal(),
	CreateFullScreenHint = Signal(),
	ExCategoryOpened = Signal()
}
