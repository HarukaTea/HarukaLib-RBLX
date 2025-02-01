--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children

return function (scope: Fusion.Scope, props: {
    IsShownVal: Fusion.Value,
    CMDInput: Fusion.Value,
    Intellisense: Fusion.Value,
    IntellisensePointer: Fusion.Value,

    ItemIntellisense: Fusion.Value,

}, self: table)
    return Components.HarukaScreenGui(scope, {
        Name = "HarukaCMD",
        DisplayOrder = 1000,
        Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"),

        Enabled = Fusion.Computed(scope, function(use: Fusion.Use, _)
            return use(props.IsShownVal)
        end)

    }, {
        FullProps = {
            [Children] = {
                Components.Frame(scope, {
                    Name = "Input",
                    Size = UDim2.new(1, 0, 0, 31),
                    Position = UDim2.fromScale(0.5, 1),
                    AnchorPoint = Vector2.new(0.5, 1),

                    [Children] = {
                        Components.TextBox(scope, {
                            Name = "CMD",
                            AutoLocalize = false,

                            TextXAlignment = Enum.TextXAlignment.Left,
                            BackgroundTransparency = 0,
                            BackgroundColor3 = Color3.fromRGB(),
                            PlaceholderText = "???",
                            PlaceholderColor3 = Color3.fromRGB(178, 178, 178),

                            [Fusion.Out("Text")] = props.CMDInput,

                            Text = Fusion.Computed(scope, function(use: Fusion.Use, _)
                                return string.upper(use(props.CMDInput))
                            end),

                            [Children] = {
                                Components.UIPadding(scope, {
                                    PaddingTop = UDim.new(0.15, 0),
                                    PaddingLeft = UDim.new(0.01, 0),
                                    PaddingRight = UDim.new(0.01, 0),
                                    PaddingBottom = UDim.new(0.15, 0)
                                })
                            }
                        })
                    }
                }),
                Components.Frame(scope, {
                    Name = "CMDIntellisense",
                    Size = UDim2.new(1, 0, 0, 23),
                    Position = UDim2.new(0.5, 0, 1, -31),
                    AnchorPoint = Vector2.new(0.5, 1),

                    [Children] = {
                        Components.UIListLayout(scope, {
                            VerticalAlignment = Enum.VerticalAlignment.Bottom,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        }),


                        Fusion.ForPairs(scope, props.Intellisense, function(_, localScope: Fusion.Scope, index: number, cmd: table)
                            return index, Components.TextButton(localScope, {
                                Name = cmd.Name,
                                AutoLocalize = false,
                                AutoButtonColor = false,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                BackgroundTransparency = 0,
                                LayoutOrder = index + 1,

                                BackgroundColor3 = Fusion.Computed(localScope, function(use: Fusion.Use, _)
                                    return if use(props.IntellisensePointer) == index then Color3.new(1, 1, 1) else Color3.fromRGB(28, 28, 37)
                                end),
                                TextColor3 = Fusion.Computed(localScope, function(use: Fusion.Use, _)
                                    return if use(props.IntellisensePointer) == index then Color3.new() else Color3.fromHex('#81ecec')
                                end),

                                Text = Fusion.Computed(localScope, function()
                                    local alias = string.upper(cmd.Alias)
                                    local totalArgs = ""
                                    for _, arg in cmd.Args do
                                        totalArgs..= "<"..arg.Name..">"
                                    end

                                    totalArgs = string.upper(totalArgs)

                                    return string.format("%s %s", alias, totalArgs)
                                end),

                                [Fusion.OnEvent("MouseEnter")] = function()
                                    props.IntellisensePointer:set(index)
                                end,
                                [Fusion.OnEvent("MouseButton1Click")] = function()
                                    self.AutoCompleteFunc()
                                end,

                                [Children] = {
                                    Components.UIPadding(localScope, {
                                        PaddingTop = UDim.new(0.15, 0),
                                        PaddingLeft = UDim.new(0.01, 0),
                                        PaddingRight = UDim.new(0.01, 0),
                                        PaddingBottom = UDim.new(0.15, 0)
                                    })
                                }
                            })
                        end),


                        Components.Frame(scope, {
                            Name = "Padding",
                            Size = UDim2.fromScale(1, 1),
                            LayoutOrder = 1
                        }),

                        Components.Frame(scope, {
                            Name = "ItemIntellisense",
                            Size = UDim2.fromScale(1, 1),
                            LayoutOrder = 0,

                            [Children] = {
                                Components.UIListLayout(scope, {
                                    Padding = UDim.new(0.02, 0),
                                    FillDirection = Enum.FillDirection.Horizontal,
                                    VerticalAlignment = Enum.VerticalAlignment.Bottom,
                                }),

                                Components.PaddingFrame(scope, "AAA"),

                                Fusion.ForPairs(scope, props.ItemIntellisense, function(_, localScope: Fusion.Scope, index: number, arg: table)
                                    local argType = arg.Type :: string

                                    local intellisenseItems = Fusion.Value(localScope, {})

                                    if argType == "enum" then
                                        intellisenseItems:set(arg.EnumItems)

                                    elseif argType == "player" then
                                        local function __getPlayers()
                                            local players = {}
                                            for _, player: Player in Players:GetPlayers() do
                                                table.insert(players, player.Name)
                                            end
                                            intellisenseItems:set(players)
                                        end
                                        __getPlayers()
                                        table.insert(localScope, Players.PlayerAdded:Connect(__getPlayers))
                                        table.insert(localScope, Players.PlayerRemoving:Connect(__getPlayers))
                                    else
                                        return index, nil
                                    end

                                    return index, Components.Frame(localScope, {
                                        Name = arg.Name,
                                        LayoutOrder = index,
                                        Size = UDim2.fromScale(0.23, 1),

                                        [Children] = {
                                            Components.UIListLayout(scope, {
                                                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                            }),


                                            Fusion.ForPairs(scope, intellisenseItems, function(_, llScope: Fusion.Scope, iindex: number, option: string)
                                                return iindex, Components.TextLabel(llScope, {
                                                    Name = option,
                                                    AutoLocalize = false,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    BackgroundTransparency = 0,
                                                    LayoutOrder = iindex + 1,
                                                    TextColor3 = Color3.fromHex('#81ecec'),

                                                    Text = string.upper(option),

                                                    [Children] = {
                                                        Components.UIPadding(llScope, {
                                                            PaddingTop = UDim.new(0.15, 0),
                                                            PaddingLeft = UDim.new(0.03, 0),
                                                            PaddingRight = UDim.new(0.03, 0),
                                                            PaddingBottom = UDim.new(0.15, 0)
                                                        })
                                                    }
                                                })
                                            end),
                                        }
                                    })
                                end)
                            }
                        }),
                    }
                })
            }
        }
    })
end