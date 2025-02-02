--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children

return function (scope: Fusion.Scope, props: {
    IsShownVal: Fusion.Value,
    CMDInput: Fusion.Value,
    Intellisense: Fusion.Value,
    IntellisensePointer: Fusion.Value,
    ItemIntellisensePointer: Fusion.Value,
    ExtraArgs: { Fusion.Value },

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
                        Components.TextLabel(scope, {
                            Name = "CMD",
                            AutoLocalize = false,
                            RichText = true,

                            TextXAlignment = Enum.TextXAlignment.Left,
                            BackgroundTransparency = 0,
                            BackgroundColor3 = Color3.fromRGB(),

                            [Fusion.Out("Text")] = props.CMDInput,

                            Text = Fusion.Computed(scope, function(use: Fusion.Use, _)
                                local text = use(props.CMDInput) :: string

                                local count = 0
                                local extraArgsText = string.gsub(text, "<([^>]*)>", function(content)
                                    count += 1
                                    if use(props.ExtraArgs[count]) == "" then
                                        return "<"..content..">"
                                    end

                                    return "<"..use(props.ExtraArgs[count])..">"
                                end)

                                return extraArgsText
                            end),
                            TextColor3 = Fusion.Computed(scope, function(use: Fusion.Use, _)
                                return if #use(props.Intellisense) <= 0 then Color3.new(1, 0, 0) else Color3.fromHex('#81ecec')
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
                                    return if use(props.IntellisensePointer) == index then Color3.new() else Color3.new(1, 1, 1)
                                end),

                                Text = Fusion.Computed(localScope, function()
                                    local alias = cmd.Alias
                                    local totalArgs = ""
                                    for _, arg in cmd.Args do
                                        totalArgs..= "<"..arg.Name..">"
                                    end

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

                                    elseif argType == "player" or argType == "players" then
                                        local function __getPlayers()
                                            local players = {}
                                            for _, player: Player in Players:GetPlayers() do
                                                table.insert(players, player.Name)
                                            end

                                            if argType == "players" then
                                                table.insert(players, "All")
                                            end

                                            intellisenseItems:set(players)
                                        end
                                        __getPlayers()
                                        table.insert(localScope, Players.PlayerAdded:Connect(__getPlayers))
                                        table.insert(localScope, Players.PlayerRemoving:Connect(__getPlayers))
                                    else
                                        local extraArgVal = props.ExtraArgs[index]

                                        return index, Components.TextBox(localScope, {
                                            Name = arg.Name,
                                            LayoutOrder = index,
                                            Size = UDim2.fromScale(0.23, 1),
                                            TextXAlignment = Enum.TextXAlignment.Left,
                                            BackgroundTransparency = 0,
                                            BackgroundColor3 = Color3.fromRGB(28, 28, 37),

                                            [Fusion.Out("Text")] = extraArgVal,

                                            PlaceholderText = "Type here",
                                            PlaceholderColor3 = Color3.fromRGB(127, 127, 127),

                                            [Children] = {
                                                Components.UIPadding(localScope, {
                                                    PaddingTop = UDim.new(0.15, 0),
                                                    PaddingLeft = UDim.new(0.03, 0),
                                                    PaddingRight = UDim.new(0.03, 0),
                                                    PaddingBottom = UDim.new(0.15, 0)
                                                })
                                            }
                                        })
                                    end

                                    local pointer = Fusion.Value(localScope, 1)
                                    local function _handlePointer(nextPointer: number)
                                        if #Fusion.peek(props.Intellisense) > 1 then return end
                                        if Fusion.peek(props.ItemIntellisensePointer) ~= index then return end

                                        local totalElements = #Fusion.peek(intellisenseItems)
                                        if totalElements <= 0 then return end

                                        nextPointer = math.clamp(nextPointer, 1, #Fusion.peek(intellisenseItems))

                                        pointer:set(nextPointer)
                                    end

                                    table.insert(localScope, UserInputService.InputBegan:Connect(function(input, gpe)
                                        if gpe then return end

                                        if input.KeyCode == Enum.KeyCode.Down then
                                            _handlePointer(Fusion.peek(pointer) + 1)

                                        elseif input.KeyCode == Enum.KeyCode.Up then
                                            _handlePointer(Fusion.peek(pointer) - 1)
                                        end
                                    end))

                                    return index, Components.Frame(localScope, {
                                        Name = arg.Name,
                                        LayoutOrder = index,
                                        Size = UDim2.fromScale(0.23, 1),

                                        [Children] = {
                                            Components.UIListLayout(localScope, {
                                                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                            }),


                                            Fusion.ForPairs(localScope, intellisenseItems, function(_, llScope: Fusion.Scope, iindex: number, option: string)
                                                return iindex, Components.TextButton(llScope, {
                                                    Name = option,
                                                    AutoLocalize = false,
                                                    AutoButtonColor = false,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    BackgroundTransparency = 0,
                                                    LayoutOrder = iindex + 1,

                                                    BackgroundColor3 = Fusion.Computed(llScope, function(use: Fusion.Use, _)
                                                        return if use(props.ItemIntellisensePointer) == index and use(pointer) == iindex then Color3.new(1, 1, 1) else Color3.fromRGB(28, 28, 37)
                                                    end),
                                                    TextColor3 = Fusion.Computed(llScope, function(use: Fusion.Use, _)
                                                        return if use(props.ItemIntellisensePointer) == index and use(pointer) == iindex then Color3.new() else Color3.new(1, 1, 1)
                                                    end),

                                                    Text = option,

                                                    [Fusion.OnEvent("MouseEnter")] = function()
                                                        props.ItemIntellisensePointer:set(index)
                                                        pointer:set(iindex)
                                                    end,
                                                    [Fusion.OnEvent("MouseButton1Click")] = function()
                                                        self.ArgAutoCompleteFunc({
                                                            Option = option,
                                                            Index = index
                                                        })
                                                    end,

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