--!nocheck

local fromRGB = Color3.fromRGB

local ItemBook = {}

ItemBook.Items = {
	{
		["ItemId"] = "MeleeAttack",
		["Name"] = "Melee Attack",
		["Type"] = "Card",
		["Tier"] = 1,
		["Desc"] = "A scroll that used by great magicians",
		["Stat"] = "The cost of this card can not be changed. <yellow>When used: </font>give you a random card.",
		["CardAction"] = "Attack(1-3)[],Attack(2-4)[]",
		["Icon"] = "118993098486486",
		["CardType"] = "SpecialMelee"
	},
	{
		["ItemId"] = "RangeAttack",
		["Name"] = "Range Attack",
		["Type"] = "Card",
		["Tier"] = 2,
		["Desc"] = "A scroll that used by great magicians",
		["Stat"] = "The cost of this card can not be changed. <yellow>When used: </font>give you a random card.",
		["CardAction"] = "Attack(1-3)[],Attack(2-4)[]",
		["Icon"] = "118993098486486",
		["CardType"] = "SpecialMelee"
	},
}

ItemBook.ItemImagesEx = {
    Unknown = "rbxassetid://114332372182764",

    Gold = "rbxassetid://18421784947",
    RP = "rbxassetid://138216203892626",
    Score = "rbxassetid://114332372182764",
    Statistics = "rbxassetid://97344315886689",
    Backpack = "rbxassetid://87334829671948",

    MaxHP = "rbxassetid://12027131895",
    Damage = "rbxassetid://73146024586376",
    CriChance = "rbxassetid://116250072122117",
    Defense = "rbxassetid://118638433713167",
    ChestPoint = "rbxassetid://135005742436792",
    Salary = "rbxassetid://18421784947"
}

--[[
    Find a item through the list
]]
function ItemBook:IsItemExist(item: string) : boolean
	local check = false

	for _, itemTable: table in ItemBook.Items do
		if itemTable.ItemId == item then check = true break end
	end

	return check
end

--[[
    Find a item, and then return it
]]
function ItemBook:FindItem(item: string)
	local itemInfo = {}

	for _, itemTable: table in ItemBook.Items do
		if itemTable.ItemId == item then itemInfo = itemTable break end
	end

	return itemInfo :: {
		ItemId: string,
		Name: string,
		Type: string,
		Tier: string,
		Desc: string,
		Stat: string,
		CardAction: string,
		Icon: number,
		CardType: string
	}
end

return ItemBook
