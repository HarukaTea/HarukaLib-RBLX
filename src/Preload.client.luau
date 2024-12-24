
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SG = game:GetService("StarterGui")
local RS = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer

local wait = task.wait


local function coreUIInit()
    SG:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    SG:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
end
coreUIInit()


local function preloadInit()
    local holderGui = Instance.new("ScreenGui")
    holderGui.Name = "Temp_LoadScreen"
    holderGui.ScreenInsets = Enum.ScreenInsets.None
    holderGui.ClipToDeviceSafeArea = false
    holderGui.Parent = plr.PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "Temp_LoadScreen_Frame"
    frame.Size = UDim2.fromScale(1, 1)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    frame.Parent = holderGui

    repeat task.wait() until RepS:WaitForChild("HarukaShared", 999)
    repeat task.wait() until workspace:GetAttribute("Haruka_ServerInited")

    local AssetBook = require(RepS.HarukaShared.Library.AssetBook)
    local Components = require(RepS.HarukaShared.UIAtlas.Vanilla)
    local Fusion = require(RepS.HarukaShared.Shared.Fusion)
    local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

    local Children = Fusion.Children

    local scope = Fusion.scoped({})
    local UI; UI = Components.ScreenGui(scope, {
        Name = "LoadScreen",
        DisplayOrder = 999,
        Parent = plr.PlayerGui,

        [Children] = {
            Components.Frame(scope, {
                Name = "Background",
                BackgroundColor3 = Color3.fromRGB(28, 28, 34),
                BackgroundTransparency = 0,

                [Children] = {
                    Components.HarukaFrame(scope, {
                        Name = "Bottom",
                        AnchorPoint = Vector2.new(0.5, 1),
                        Position = UDim2.fromScale(0.5, 1),

                        [Children] = {
                            Components.TextLabel(scope, {
                                Name = "LoadingText",
                                Position = UDim2.fromScale(0, -0.3),
                                Size = UDim2.fromScale(1, 0.5),
                                Text = "TRAVELLING TO ASTRA WORLD..."
                            })
                        }
                    }),
                    Components.HarukaFrame(scope, {
                        Name = "Center",

                        [Children] = {
                            Components.HoverImageButton(scope, {
                                Active = false,
                                Name = "Logo",
                                Position = UDim2.fromScale(0.5, 0),
                                Size = UDim2.fromScale(2, 2),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                Image = "rbxassetid://124498265529910",
                                ImageTransparency = 0.7
                            })
                        }
                    })
                }
            })
        }
    })
    holderGui:Destroy()

    wait(2)
    repeat wait() until plr:GetAttribute("PlayerDataLoaded")

    local function _tweenOutUI()
        local tweenOutUI = UI:Clone()
        tweenOutUI.Parent = plr.PlayerGui
        Debris:AddItem(tweenOutUI, 1)

        Fusion.doCleanup(scope)
        HarukaLib:UITween(tweenOutUI, "Out")
    end
    _tweenOutUI()


    --// Lock camera
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = workspace:WaitForChild("Components", 999).Titlescreen_Cam.CFrame

    scope = Fusion.scoped({})

    local function Value(val: any)
        return Fusion.Value(scope, val)
    end
    local bottomFramePos = Value(UDim2.fromScale(0.5, 1.5))
    local clickTipVisible = Value(true)

	UI = Components.ScreenGui(scope, {
		Name = "Titlescreen",
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		Parent = plr.PlayerGui,

		[Children] = {
			Components.HarukaFrame(scope, {
				Name = "Bottom",
                AnchorPoint = Vector2.new(0.5, 1),

				Position = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use)
						return use(bottomFramePos)
				end), AssetBook.TweenInfos.oneHalf),

				[Children] = {
					Components.Frame(scope, {
						Name = "TipBG",
						Position = UDim2.fromScale(0.5, 0),
						Size = UDim2.fromScale(0.5, 0.5),
						BackgroundTransparency = 0,

						[Children] = {
							Fusion.New(scope, "UIGradient")({
								Color = ColorSequence.new(Color3.new()),

								Transparency = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use)
									return if use(clickTipVisible) then
										NumberSequence.new({
											NumberSequenceKeypoint.new(0, 1),
											NumberSequenceKeypoint.new(0.5, 0),
											NumberSequenceKeypoint.new(1, 1),
										})
									else NumberSequence.new(1, 1)
								end), AssetBook.TweenInfos.twiceHalf),
							}),

							Components.TextLabel(scope, {
								Name = "Tip",
								FontFace = Font.new(
									"rbxasset://fonts/families/GothamSSm.json",
									Enum.FontWeight.Bold,
									Enum.FontStyle.Normal
								),
								Text = "Click anywhere to continue...",

								TextTransparency = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use)
									return if use(clickTipVisible) then 0 else 1
								end), AssetBook.TweenInfos.twiceHalf),

								[Children] = {
									Fusion.New(scope, "UIPadding")({
										PaddingBottom = UDim.new(0.15, 0),
										PaddingTop = UDim.new(0.15, 0),
									})
								},
							}),
						},
					}),
				},
			})
		},
	})
	bottomFramePos:set(UDim2.fromScale(0.5, 1))


    wait(1)
	local check = false
	local clickDetect = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			check = true
		end
	end)
	repeat RS.RenderStepped:Wait() until check

	if clickDetect then clickDetect:Disconnect() end
    _tweenOutUI()


    --// class selection
    scope = Fusion.scoped({})

    local ExecuteButton = require(RepS.HarukaShared.UIAtlas.Components.ExecuteButton)
    local GArrowTexBG = require(RepS.HarukaShared.UIAtlas.Components.GArrowTexBG)
    local classsFinished = false

    local currentPanelSelected = Value("View")
    local absPanelSize = Value(Vector2.zero)

	UI = Components.ScreenGui(scope, {
		Name = "ClassSelection_Intro",
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		Parent = plr.PlayerGui,

		[Children] = {
			Components.HarukaFrame(scope, {
                Name = "Bottom",
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.fromScale(0.5, 0.96),

                [Children] = {
                    ExecuteButton(scope, {
                        Position = UDim2.fromScale(0.43, 0),
                        Size = UDim2.fromScale(0.17, 0.7),
                        ButtonText = "READY",
                        ButtonClickFunc = function()
                            classsFinished = true
                        end
                    })
                }
            }),
            Components.Frame(scope, {
                Name = "CenterLeft",
                BackgroundTransparency = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0.03, 0.5),
                Size = UDim2.fromScale(0.28, 0.7),

                [Children] = {
                    Components.UIAspectRatioConstraint(scope, 1.009),
                    Components.UIStroke(scope, {
                        Thickness = 4,
                        Color = Color3.new()
                    }),

                    GArrowTexBG(scope),

                    Components.Frame(scope, {
                        Name = "CenterSquare",
                        Size = UDim2.fromScale(0.9, 0.9),

                        [Fusion.Out("AbsoluteSize")] = absPanelSize,

                        [Children] = {
                            Components.UIListLayout(scope, {
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                Padding = UDim.new(0.05, 0),
                            }),

                            Components.Frame(scope, {
                                LayoutOrder = 1,
                                Name = "Classes",
                                Size = UDim2.fromScale(1, 0.15),

                                [Children] = {
                                    Components.UIListLayout(scope, {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        Padding = UDim.new(0.01, 0),
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                    }),

                                    Fusion.ForValues(scope, { "Warrior", "Executor", "Wizard" }, function(_, localScope: Fusion.Scope, classId: string)
                                        return Components.ImageLabel(localScope, {
                                            Name = classId,
                                            BackgroundTransparency = 0,
                                            Image = "rbxassetid://114332372182764",
                                            SizeConstraint = Enum.SizeConstraint.RelativeYY,

                                            [Children] = {
                                                Components.RoundUICorner(localScope)
                                            }
                                        })
                                    end)
                                }
                            }),

                            Components.TextLabel(scope, {
                                Name = "Class",
                                LayoutOrder = 2,
                                Size = UDim2.fromScale(1, 0.08),
                                RichText = true,

                                Text = "<u>Commander</u>",
                                TextColor3 = Color3.fromRGB(255, 255, 0),
                            }),

                            Components.Frame(scope, {
                                Name = "Panels",
                                LayoutOrder = 3,
                                Size = UDim2.fromScale(1, 0.1),

                                [Children] = {
                                    Components.UIListLayout(scope, {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        Padding = UDim.new(0.03, 0),
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                    }),

                                    Fusion.ForValues(scope, { "View", "Skills", "Items" }, function(_, localScope: Fusion.Scope, panelId: string)
                                        return Components.TextButton(localScope, {
                                            Name = panelId,
                                            Text = panelId,
                                            Size = UDim2.fromScale(0.3, 1),

                                            TextColor3 = Fusion.Computed(localScope, function(use: Fusion.Use)
                                                return if use(currentPanelSelected) == panelId then
                                                    Color3.new() else Color3.new(1, 1, 1)
                                            end),
                                            BackgroundColor3 = Fusion.Computed(localScope, function(use: Fusion.Use)
                                                return if use(currentPanelSelected) == panelId then
                                                    Color3.new(1, 1, 1) else Color3.new()
                                            end),

                                            [Fusion.OnEvent("MouseButton1Click")] = function()
                                                currentPanelSelected:set(panelId)
                                            end,


                                            [Children] = {
                                                Components.RoundUICorner(localScope),
                                                Components.UIPadding(localScope, {})
                                            }
                                        })
                                    end)
                                }
                            }),

                            Components.ScrollingFrame(scope, {
                                Name = "PanelInfo",
                                LayoutOrder = 4,
                                Size = UDim2.fromScale(1, 0.5),
                                ScrollingDirection = Enum.ScrollingDirection.Y,

                                [Children] = {
                                    Components.TextLabel(scope, {
                                        Name = "Info",
                                        RichText = true,
                                        AutomaticSize = Enum.AutomaticSize.Y,
                                        Size = UDim2.fromScale(1, 0),

                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextYAlignment = Enum.TextYAlignment.Top,
                                        TextScaled = false,
                                        TextWrapped = true,

                                        TextSize = Fusion.Computed(scope, function(use: Fusion.Use)
                                            return use(absPanelSize).X / (294 / 20)
                                        end),

                                        Text = [[Commander is a great character for all beginners to use. <br/><br/>Mainly because jky developed this game and it's blah blah]]
                                    })
                                }

                            }, {
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            })
                        }
                    })
                }
            }),
            Components.Frame(scope, {
                Name = "CenterRight",
                BackgroundTransparency = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0.77, 0.5),
                Size = UDim2.fromScale(0.2, 0.7),

                [Children] = {
                    Components.UIAspectRatioConstraint(scope, 0.721),
                    Components.UIStroke(scope, {
                        Thickness = 4,
                        Color = Color3.new()
                    }),

                    GArrowTexBG(scope),

                    Components.Frame(scope, {
                        Name = "CenterSquare",
                        Size = UDim2.fromScale(0.9, 0.9),

                        [Children] = {
                            Components.UIListLayout(scope, {
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                Padding = UDim.new(0.05, 0),
                            }),

                            Components.TextLabel(scope, {
                                Name = "Difficulty",
                                LayoutOrder = 1,
                                Size = UDim2.fromScale(1, 0.07),
                                RichText = true,

                                Text = "<u>DIFFICULTY</u>",
                                TextColor3 = Color3.fromRGB(170, 255, 255),
                            }),

                            Components.Frame(scope, {
                                LayoutOrder = 2,
                                Name = "Difficulties",
                                Size = UDim2.fromScale(1, 0.15),

                                [Children] = {
                                    Components.UIListLayout(scope, {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        Padding = UDim.new(0.01, 0),
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                    }),

                                    Fusion.ForValues(scope, { "Easy", "Normal", "Hard" }, function(_, localScope: Fusion.Scope, difficultyId: string)
                                        return Components.ImageLabel(localScope, {
                                            Name = difficultyId,
                                            BackgroundTransparency = 0,
                                            Image = "rbxassetid://114332372182764",
                                            SizeConstraint = Enum.SizeConstraint.RelativeYY,

                                            [Children] = {
                                                Components.RoundUICorner(localScope)
                                            }
                                        })
                                    end)
                                }
                            }),

                            Components.TextLabel(scope, {
                                Name = "DifficultyLabel",
                                LayoutOrder = 3,
                                Size = UDim2.fromScale(1, 0.1),

                                Text = "EASY",
                                TextColor3 = Color3.fromRGB(85, 255, 0),
                            }),

                            Components.ScrollingFrame(scope, {
                                Name = "DifficultyInfo",
                                LayoutOrder = 4,
                                Size = UDim2.fromScale(1, 0.5),
                                ScrollingDirection = Enum.ScrollingDirection.Y,

                                [Children] = {
                                    Components.TextLabel(scope, {
                                        Name = "Info",
                                        RichText = true,
                                        AutomaticSize = Enum.AutomaticSize.Y,
                                        Size = UDim2.fromScale(1, 0),

                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextYAlignment = Enum.TextYAlignment.Top,
                                        TextScaled = false,
                                        TextWrapped = true,

                                        TextSize = Fusion.Computed(scope, function(use: Fusion.Use)
                                            return use(absPanelSize).Y / (292 / 19)
                                        end),

                                        Text = [[Easy is the most easy difficulty, if you can't beat it. then... <br/><br/>you may need practice]]
                                    })
                                }

                            }, {
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            })
                        }
                    })
                }
            })
		},
	})
    HarukaLib:UITween(UI, "In", { TweenTime = 1 })


    repeat wait() until classsFinished
    _tweenOutUI()

    camera.CameraType = Enum.CameraType.Custom

    local Events = require(RepS.HarukaShared.Library.Events)
    Events.RequestSpawn.Fire({})


    plr:SetAttribute("IsLoaded", true)
end
preloadInit()
