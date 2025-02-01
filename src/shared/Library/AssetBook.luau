--!nocheck

local fromRGB, fromHex = Color3.fromRGB, Color3.fromHex
local newTweenInfo = TweenInfo.new

local AssetBook = {}

AssetBook.TweenInfos = {
	fourHalf = newTweenInfo(0.05),
	threeHalf = newTweenInfo(0.15),
	twiceHalf = newTweenInfo(0.2),
	onceHalf = newTweenInfo(0.3),
	half = newTweenInfo(0.5),
	halfBack = newTweenInfo(0.5, Enum.EasingStyle.Back),
	twiceHalfOne = newTweenInfo(0.75),
	threeHalfOne = newTweenInfo(0.9),
	one = newTweenInfo(1),
	oneHalf = newTweenInfo(1.5),
	two = newTweenInfo(2),
	four = newTweenInfo(4),
	six = newTweenInfo(6),
	fifteen = newTweenInfo(15, Enum.EasingStyle.Linear)
}

AssetBook.ExtraIcons = {
	Null = "rbxassetid://1637592633",
	Unknown = "rbxassetid://114332372182764",
	Marked = "rbxassetid://94557907177407"
}

return AssetBook
