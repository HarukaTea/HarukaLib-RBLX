
export type Haruka3DUIClass = {
    __index: Haruka3DUIClass,

    new: (gui: ScreenGui, distance: number) -> Haruka3DUIClass,
    Destroy: (self: Haruka3DUIClass) -> nil,

    SetRootOffset: (offsetCFrame: CFrame) -> nil,

    GetPart2D: (guiObject: GuiObject) -> Haruka2DUIClass
}


export type Haruka2DUIClass = {
    __index: Haruka2DUIClass,

    new: (element: GuiObject, ancestorModule: Haruka3DUIClass) -> Haruka2DUIClass,
    Destroy: (self: Haruka2DUIClass) -> nil,

    Enable: (self: Haruka2DUIClass) -> nil,
    Disable: (self: Haruka2DUIClass) -> nil,

    SetOffsetY: (self: Haruka2DUIClass, offsetY: number) -> nil,
    GetXYZFromScreenSize: (self: Haruka2DUIClass, size: Vector2) -> Vector3,
    GetWorldCFrame: (self: Haruka2DUIClass) -> CFrame,
    GetScreenSize: (self: Haruka2DUIClass) -> Vector2,
    RecomputeParentElement: (self: Haruka2DUIClass) -> nil,
    Udim2ToCFrame: (self: Haruka2DUIClass, udim2: Vector2) -> CFrame,
    GetPartPivot: (self: Haruka2DUIClass) -> CFrame
}



return nil