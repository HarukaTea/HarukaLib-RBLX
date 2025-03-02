--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local cfNew = CFrame.new
local v2New = Vector2.new
local fromScale = UDim2.fromScale


return function(plr: Player)
	if HarukaLib:GetDevice() ~= "Mobile" then return end

	local scope = Fusion.scoped()

	local camera = workspace.CurrentCamera
	local char = plr.Character or plr.CharacterAdded:Wait()

	local HRP = char.PrimaryPart

	local rsConnection, enabled = nil, false
	local ON_ICON, OFF_ICON = "rbxasset://textures/ui/mouseLock_on@2x.png", "rbxasset://textures/ui/mouseLock_off@2x.png"

	local icon = Fusion.Value(scope, OFF_ICON)

	--// Helper functions

	local function _enableShiftLock()
		rsConnection = RS.Heartbeat:Connect(function()
			if not char then return end
			if not HRP then return end

			char.Humanoid.AutoRotate = false

			if not char.Humanoid.Sit then
				local lookVector = camera.CFrame.LookVector

				HRP.CFrame = cfNew(HRP.Position, Vector3.new(
					lookVector.X * 159940,
					HRP.Position.Y,
					lookVector.Z * 159940
				))
			end
		end)
	end
	local function _setLockState(state: "On" | "Off")
		if state == "On" then
			enabled = true

			if rsConnection then rsConnection:Disconnect() end

			icon:set(ON_ICON)
			camera.CFrame *= cfNew(1.7, 0, 0)

			_enableShiftLock()
		else
			enabled = false

			if rsConnection then rsConnection:Disconnect() end

			icon:set(OFF_ICON)
			camera.CFrame *= cfNew(-1.7, 0, 0)

			char.Humanoid.AutoRotate = true
		end
	end


	Components.HarukaScreenGui(scope, {
		Name = "MobileShiftLock",
		DisplayOrder = 10,
		Parent = plr:FindFirstChildOfClass("PlayerGui"),

		[Fusion.Children] = {
			Components.Frame(scope, {
				AnchorPoint = v2New(1, 0.5),
				ZIndex = 999,
				Position = fromScale(0.984, 0.6),
				Size = fromScale(0.035, 0.085),

				[Fusion.Children] = {
					Components.UIAspectRatioConstraint(scope, 1.007),

					Components.HoverImageButton(scope, {
						Image = Fusion.Computed(scope, function(use: Fusion.Use)
							return use(icon)
						end),

						[Fusion.OnEvent("MouseButton1Click")] = function()
							if char:FindFirstChild("Humanoid") and char.PrimaryPart then
								_setLockState(if enabled then "Off" else "On")
							end
						end,
					}),
				},
			}),
		},
	})

	---// Clear

	local function clearGarbage()
		_setLockState("Off")

		Fusion.doCleanup(scope)
	end
	char.Humanoid.Died:Once(clearGarbage)
end
