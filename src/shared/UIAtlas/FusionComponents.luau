--!nocheck

local CollectionService = game:GetService("CollectionService")
local RepS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local FusionComponents = {}

local wait = task.wait


FusionComponents.useTagged = function(scope: Fusion.Scope, tag: string) : Fusion.Value
    local val = Fusion.Value(scope, CollectionService:GetTagged(tag))

    local function _getChildren()
        wait()
        val:set(CollectionService:GetTagged(tag))
    end
    table.insert(scope, CollectionService:GetInstanceAddedSignal(tag):Connect(_getChildren))
    table.insert(scope, CollectionService:GetInstanceRemovedSignal(tag):Connect(_getChildren))

    return val
end


FusionComponents.useMouse = function(scope: Fusion.Scope) : Fusion.Value
    local val = Fusion.Value(scope, UserInputService:GetMouseLocation())

    table.insert(scope, UserInputService.InputBegan:Connect(function(inputObj)
        local mouseMoved = if inputObj.UserInputType == Enum.UserInputType.MouseMovement then true else false
        local touched = if inputObj.UserInputType == Enum.UserInputType.Touch then true else false

        if mouseMoved or touched then
            val:set(UserInputService:GetMouseLocation())
        end
    end))

    return val
end


FusionComponents.useFolder = function(scope: Fusion.Scope, folder: Folder) : Fusion.Value
    local val = Fusion.Value(scope, folder:GetChildren())

    local function _getChildren()
        wait()
        val:set(folder:GetChildren())
    end
    table.insert(scope, folder.ChildAdded:Connect(_getChildren))
    table.insert(scope, folder.ChildRemoved:Connect(_getChildren))

    return val
end




return FusionComponents
