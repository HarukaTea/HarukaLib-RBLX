--!nocheck

--// Inspired by Screen3D module in devforum, modified to fit my needs.

local Screen3D = {}
Screen3D.__index = Screen3D

local Part2D = require(script.Part2D)


function Screen3D.new(gui: ScreenGui, distance: number)
    local part2dComponents = {}

    local self = setmetatable({
        Part2DComponents = part2dComponents,
        Distance = distance,
        RootOffsetCFrame = CFrame.identity

    }, Screen3D)

    --// bind
    for _, element: Instance in gui:GetDescendants() do
        if not element:IsA("GuiObject") then continue end

        part2dComponents[element] = Part2D.new(element, self)
    end
    gui.DescendantAdded:Connect(function(added: Instance)
        if added:IsA("GuiObject") then
            part2dComponents[added] = Part2D.new(added, self)
        end

        for _, element: GuiObject in added:GetDescendants() do
            if element:IsA("GuiObject") and not part2dComponents[element] then
                part2dComponents[element] = Part2D.new(element, self)
            end
        end
    end)

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
    for _, part2d in self.Part2DComponents do
        if part2d and part2d.Destroy then
            part2d:Destroy()
        end
    end
end


--// Private

function Screen3D:GetPart2D(guiObject: GuiObject)
    return self.Part2DComponents[guiObject]
end

return Screen3D
