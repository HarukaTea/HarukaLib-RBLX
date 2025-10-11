--!nocheck
--!nolint LocalUnused
--!nolint LocalShadow
--!nolint SameLineStatement
--!nolint ImplicitReturn

--// Inspired by Screen3D module in devforum, modified to fit my needs.




local Part2D = require(script.Part2D)

local Types = require(script.Types)

type Haruka3DUIClass = Types.Haruka3DUIClass


local Screen3D = {}
Screen3D.__index = Screen3D


--// Init once
local part2DComponents = {}


function Screen3D.new(gui: ScreenGui, distance: number) : Haruka3DUIClass
    local self = setmetatable({}, Screen3D)

    part2DComponents[gui] = {}

    self.RootGui = gui
    self.Distance = distance
    self.RootOffsetCFrame = CFrame.identity

    return self
end


--[[
    Set the root offset of all Part2D components.

    **Example:**
    ```lua
    Screen3D:SetRootOffset(CFrame.Angles(0, math.rad(10), 0))
    ```
]]
function Screen3D:SetRootOffset(offsetCFrame: CFrame)
    self.RootOffsetCFrame = offsetCFrame
end


--[[
    Cleanup all Part2D components.
]]
function Screen3D:Destroy()
    for _, part2d in part2DComponents[self.RootGui] do
        if part2d and part2d.Destroy then
            part2d:Destroy()
        end
    end
end


--// Private

function Screen3D:GetPart2D(guiObject: GuiObject) : Types.Haruka2DUIClass
    if guiObject == nil then return nil end
    if self.RootGui == nil then return nil end


    if not part2DComponents[self.RootGui][guiObject] then
        part2DComponents[self.RootGui][guiObject] = Part2D.new(guiObject, self)
    end

    return part2DComponents[self.RootGui][guiObject]
end

return Screen3D :: Haruka3DUIClass