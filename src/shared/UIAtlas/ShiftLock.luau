--!nocheck

local RepS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")

local Components = require(RepS.HarukaShared.UIAtlas.Vanilla)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local isMobile = HarukaLib:GetDevice() == "Mobile"

local MobileShiftLock = {}
MobileShiftLock.__index = MobileShiftLock

local cfNew = CFrame.new
local v2New = Vector2.new
local fromScale = UDim2.fromScale


function MobileShiftLock:SetLockState(state: string)
	if state == "On" then
		self.enabled = true
		self.icon:set(self.ON_ICON)

		self.camera.CFrame *= cfNew(1.7, 0, 0)
	else
		self.enabled = false
		self.icon:set(self.OFF_ICON)

		self.camera.CFrame *= cfNew(-1.7, 0, 0)
	end
end

function MobileShiftLock:EnableShiftLock()
	if self.enabled then
		--- store variables to reduce index time spent in RenderStepped
		self.rsConnection = RS.RenderStepped:Connect(function()
			if not self.char then return end
			if not self.char.PrimaryPart then return end

			self.char.Humanoid.AutoRotate = not self.enabled

			if self.enabled and not self.char.Humanoid.Sit then
				self.char.PrimaryPart.CFrame = cfNew(self.char.PrimaryPart.Position, Vector3.new(
					self.camera.CFrame.LookVector.X * 159940,
					self.char.PrimaryPart.Position.Y,
					self.camera.CFrame.LookVector.Z * 159940
				))
			end
			if not self.enabled then
				if self.rsConnection then self.rsConnection:Disconnect() end
			end
		end)
	end
end

return function(plr: Player)
	if not isMobile then return end

	local self = setmetatable({}, MobileShiftLock)
	local scope = Fusion.scoped({})

	self.camera = workspace.CurrentCamera
	self.char = plr.Character or plr.CharacterAdded:Wait()

	self.rsConnection, self.enabled = nil, false
	self.ON_ICON, self.OFF_ICON = "rbxasset://textures/ui/mouseLock_on.png", "rbxasset://textures/ui/mouseLock_off.png"

	self.icon = Fusion.Value(scope, self.OFF_ICON)

	Components.ScreenGui(scope, {
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
							return use(self.icon)
						end),

						[Fusion.OnEvent("MouseButton1Click")] = function()
							if self.char:FindFirstChild("Humanoid") and self.char.PrimaryPart then
								self:SetLockState(if self.enabled then "Off" else "On")
								self:EnableShiftLock()
							end
						end,
					}),
				},
			}),
		},
	})

	---// Clear

	local function clearGarbage()
		self:SetLockState("Off")

		Fusion.doCleanup(scope)

		self = nil
	end
	self.char.Humanoid.Died:Once(clearGarbage)
end
