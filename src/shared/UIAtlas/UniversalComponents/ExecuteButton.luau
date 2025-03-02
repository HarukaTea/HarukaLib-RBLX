--!nocheck

local RepS = game:GetService("ReplicatedStorage")

local UIAtlas = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local Children = Fusion.Children

return function(scope: Fusion.Scope, props: {
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    Position: UDim2?,
    Size: UDim2?,
    ButtonText: string?,
    ButtonClickFunc: () -> nil,
    ButtonType: "Confirm" | "Cancel"
})
    local isSelected = Fusion.Value(scope, false)


    props.AnchorPoint = props.AnchorPoint or Vector2.new()
    props.LayoutOrder = props.LayoutOrder or 1
    props.Position = props.Position or UDim2.fromScale(0, 0)
    props.Size = props.Size or UDim2.fromScale(1, 1)
    props.ButtonType = props.ButtonType or "Confirm"
    props.ButtonText = props.ButtonText or "Execute"
    props.ButtonClickFunc = props.ButtonClickFunc or function () end


	return UIAtlas.TextButton(scope, {
        Name = "ExecuteButton",
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(236, 229, 216),

        AnchorPoint = props.AnchorPoint,
        LayoutOrder = props.LayoutOrder,
        Position = props.Position,
        Size = props.Size,

        [Fusion.OnEvent("MouseEnter")] = function()
            isSelected:set(true)
        end,
        [Fusion.OnEvent("MouseLeave")] = function()
            isSelected:set(false)
        end,
        [Fusion.OnEvent("MouseButton1Click")] = props.ButtonClickFunc,

        [Children] = {
            UIAtlas.RoundUICorner(scope),
            UIAtlas.UIStroke(scope, {
                Thickness = 2.5,

                Transparency = Fusion.Tween(scope, Fusion.Computed(scope, function(use: Fusion.Use, _)
                    return if use(isSelected) then 0 else 1
                end), TweenInfo.new(0.2))
            }),

            UIAtlas.UIListLayout(scope, {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0.05, 0),
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),
            UIAtlas.UIPadding(scope, {}),

            UIAtlas.Frame(scope, {
                Name = "Icon",
                LayoutOrder = 1,

                Size = UDim2.fromScale(0.95, 0.95),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                ZIndex = 0,
                BackgroundTransparency = 0,

                [Children] = {
                    UIAtlas.RoundUICorner(scope),
                    UIAtlas.ImageLabel(scope, {
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,

                        Position = Fusion.Computed(scope, function()
                            if props.ButtonType == "Confirm" then
                                return UDim2.fromScale(0.05, 0)
                            else
                                return UDim2.fromScale(0, 0)
                            end
                        end),
                        Image = Fusion.Computed(scope, function()
                            if props.ButtonType == "Confirm" then
                                return "rbxassetid://118880093672405"
                            else
                                return "rbxassetid://103065634382876"
                            end
                        end),
                        ImageColor3 = Fusion.Computed(scope, function()
                            if props.ButtonType == "Confirm" then
                                return Color3.fromRGB(255, 255, 255)
                            else
                                return Color3.fromRGB(255, 85, 0)
                            end
                        end),


                        [Children] = {
                            UIAtlas.RoundUICorner(scope)
                        }
                    })
                }
            }),
            UIAtlas.TextLabel(scope, {
                Name = "ButtonText",
                LayoutOrder = 2,
                Size = UDim2.fromScale(0.8, 0.9),
                TextColor3 = Color3.fromRGB(44, 49, 62),

                Text = props.ButtonText,

                [Children] = {
                    Fusion.New(scope, "UIPadding")({
                        PaddingRight = UDim.new(0.1, 0)
                    })
                }
            })
        }
    })
end
