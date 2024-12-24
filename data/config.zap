
opt client_output = "../src/shared/Library/Events.luau"
opt server_output = "../src/server/Modules/Library/ServerEvents.luau"
opt remote_scope = "HARUKA"


event ForceReset = {
    from: Client,
    type: Reliable,
    call: SingleAsync,
    data: struct {}
}
event RequestSpawn = {
    from: Client,
    type: Reliable,
    call: SingleAsync,
    data: struct {}
}

event CreateHint = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        Hint: string
    }
}
event CreateFullScreenHint = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        Hint: string,
        State: boolean
    }
}
event CreateTimer = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        Countdown: u8,
    }
}
event CreateCenterNotify = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        Hint: string
    }
}