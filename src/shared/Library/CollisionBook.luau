--!nocheck

local PS = game:GetService("PhysicsService")
local RS = game:GetService("RunService")

local Book = {
	Group = {
		HitboxParams = "HitboxParams",
		Hitbox = "Hitbox",
		PrimaryPart = "PrimaryPart",
		PlayerBodyPart = "PlayerBodyPart",
		NoCollision = "NoCollision",

		Border = "Border"
	},

	Params = {
		Hitbox = OverlapParams.new()
	},
}


if RS:IsServer() then
	PS:RegisterCollisionGroup(Book.Group.HitboxParams)
	PS:RegisterCollisionGroup(Book.Group.Hitbox)
	PS:RegisterCollisionGroup(Book.Group.PrimaryPart)
	PS:RegisterCollisionGroup(Book.Group.PlayerBodyPart)
	PS:RegisterCollisionGroup(Book.Group.NoCollision)
	PS:RegisterCollisionGroup(Book.Group.Border)


	PS:CollisionGroupSetCollidable(Book.Group.HitboxParams,"Default", false)
	PS:CollisionGroupSetCollidable(Book.Group.HitboxParams, Book.Group.HitboxParams, false)
	PS:CollisionGroupSetCollidable(Book.Group.HitboxParams, Book.Group.Hitbox, true)
	PS:CollisionGroupSetCollidable(Book.Group.HitboxParams, Book.Group.PrimaryPart, false)
	PS:CollisionGroupSetCollidable(Book.Group.HitboxParams, Book.Group.PlayerBodyPart, true)
	PS:CollisionGroupSetCollidable(Book.Group.HitboxParams, Book.Group.NoCollision, false)
	PS:CollisionGroupSetCollidable(Book.Group.HitboxParams, Book.Group.Border, false)


	PS:CollisionGroupSetCollidable(Book.Group.Hitbox,"Default", false)
	PS:CollisionGroupSetCollidable(Book.Group.Hitbox, Book.Group.Hitbox, false)
	PS:CollisionGroupSetCollidable(Book.Group.Hitbox, Book.Group.PrimaryPart, false)
	PS:CollisionGroupSetCollidable(Book.Group.Hitbox, Book.Group.PlayerBodyPart, false)
	PS:CollisionGroupSetCollidable(Book.Group.Hitbox, Book.Group.NoCollision, false)
	PS:CollisionGroupSetCollidable(Book.Group.Hitbox, Book.Group.Border, false)


	PS:CollisionGroupSetCollidable(Book.Group.PrimaryPart,"Default", true)
	PS:CollisionGroupSetCollidable(Book.Group.PrimaryPart, Book.Group.PrimaryPart, false)
	PS:CollisionGroupSetCollidable(Book.Group.PrimaryPart, Book.Group.PlayerBodyPart, false)
	PS:CollisionGroupSetCollidable(Book.Group.PrimaryPart, Book.Group.NoCollision, false)
	PS:CollisionGroupSetCollidable(Book.Group.PrimaryPart, Book.Group.Border, false)


	PS:CollisionGroupSetCollidable(Book.Group.PlayerBodyPart,"Default", true)
	PS:CollisionGroupSetCollidable(Book.Group.PlayerBodyPart, Book.Group.PlayerBodyPart, false)
	PS:CollisionGroupSetCollidable(Book.Group.PlayerBodyPart, Book.Group.NoCollision, false)
	PS:CollisionGroupSetCollidable(Book.Group.PlayerBodyPart, Book.Group.Border, true)


	PS:CollisionGroupSetCollidable(Book.Group.NoCollision,"Default", true)
	PS:CollisionGroupSetCollidable(Book.Group.NoCollision, Book.Group.NoCollision, false)
end
Book.Params.Hitbox.CollisionGroup = Book.Group.HitboxParams


return Book
