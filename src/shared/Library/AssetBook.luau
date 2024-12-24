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

AssetBook.TierColor = {
	fromHex('#626771'),
	fromHex('#52836f'),
	fromHex('#57789c'),
	fromHex('#6f639f'),
	fromHex('#ac712c'),
}

AssetBook.StatBarColors = {
	HP = fromRGB(48, 121, 36),
	HPMid = fromRGB(148, 148, 0),
	HPLow = fromRGB(203, 0, 0),
}

AssetBook.ExtraIcons = {
	Null = "rbxassetid://1637592633",
	Unknown = "rbxassetid://114332372182764",
	Marked = "rbxassetid://94557907177407"
}

AssetBook.ActionIcons = {
	Attack = "rbxassetid://73146024586376",
	Defend = "rbxassetid://111674872900181",
	Ranged = "rbxassetid://137105999719771",
	AoERanged = "rbxassetid://72060862434537",
}
AssetBook.ActionColors = {
	Attack = fromRGB(255, 100, 100),
	Defend = fromRGB(255, 255, 50)
}

AssetBook.CardTypeIcons = {
	Melee = "rbxassetid://73146024586376",
	SpecialMelee = "rbxassetid://116250072122117",
	Ranged = "rbxassetid://137105999719771",
	AoERanged = "rbxassetid://72060862434537",
	Equipment = "rbxassetid://12236618949"
}
AssetBook.CardTypeExplain = {
	Melee = "Melee",
	SpecialMelee = "Special",
	Ranged = "Ranged",
	AoERanged = "AoE",
	Equipment = "Equipment"
}

return AssetBook
