--!nocheck

local RepS = game:GetService("ReplicatedStorage")


local function setup()
    for _, actor: Actor in RepS.HarukaShared.Actor:GetChildren() do
        if not actor:IsA("Actor") then continue end

        require(actor:FindFirstChildOfClass("ModuleScript"))
    end

    workspace:SetAttribute("Haruka_ParallelInited", true)
end
setup()
