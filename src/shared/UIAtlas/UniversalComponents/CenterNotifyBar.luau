--!nocheck

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AssetBook = require(RepS.HarukaShared.Library.AssetBook)
local Components = require(RepS.HarukaShared.UIAtlas.HarukaComponents)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)

local Children = Fusion.Children

local fromScale = UDim2.fromScale

return function (scope: Fusion.Scope, props: {
    Text: string,
    ShowBar: boolean
})

    local CenterNotifyBar = function(pos: "Top" | "Bottom") : Frame
		return Fusion.New(scope, "Frame")({
			Name = pos.."Bar",
			Size = fromScale(0.15, 0.1),
            Position = if pos == "Top" then fromScale(-0.2, 0) else fromScale(1.2, 0.9),

            Visible = props.ShowBar,
		})
	end

    local bar1, bar2 = CenterNotifyBar("Top"), CenterNotifyBar("Bottom")
    TweenService:Create(bar1, AssetBook.TweenInfos.one, {
        Position = fromScale(1.2, 0)
    }):Play()
    TweenService:Create(bar2, AssetBook.TweenInfos.one, {
        Position = fromScale(-0.2, 0.9)
    }):Play()

    return Components.Frame(scope, {
        Name = "CenterNotify",
        Size = UDim2.fromScale(1, 0.8),
        BackgroundTransparency = 0,
        Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui").ExplorerNotify.Center,

        [Children] = {
            Components.TextLabel(scope, {
                Name = "CenterText",
                RichText = true,

                Text = HarukaLib:RichTextify(props.Text),

                [Children] = {
                    Components.UIPadding(scope, {
                        PaddingTop = UDim.new(0.2, 0),
                        PaddingBottom = UDim.new(0.2, 0),
                    })
                }
            }),

            bar1, bar2
        }
    })
end