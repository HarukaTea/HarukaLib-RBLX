
local RepS = game:GetService("ReplicatedStorage")

local UIAtlas = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)

local UILab = require(RepS.HarukaShared.Shared.UILabs)

local Children = Fusion.Children

return UILab.CreateFusionStory({
    fusion = Fusion,
    controls = {
        CenterText = "Hello, world!",
    },

}, function(props)
    local scope = props.scope

	local component = UIAtlas.HarukaFrame(scope, {
        Name = "Center",
        Parent = props.target,

        [Children] = {
            UIAtlas.Frame(scope, {
				Name = "CenterNotify",
				Size = UDim2.fromScale(1, 0.8),
				BackgroundTransparency = 0,

				Visible = Fusion.Computed(scope, function(use: Fusion.Use)
					return use(props.controls.CenterText) ~= ""
				end),

				[Children] = {
					UIAtlas.TextLabel(scope, {
						Name = "CenterText",
                        FontFace = Font.fromName("Roboto", Enum.FontWeight.Bold),

						Text = Fusion.Computed(scope, function(use: Fusion.Use)
							return use(props.controls.CenterText)
						end),

						[Children] = { UIAtlas.UIPadding(scope, {
                            PaddingTop = UDim.new(0.2, 0),
                            PaddingBottom = UDim.new(0.2, 0),
                        }) }
					}),
				}
			})
        }
    })
end)
