
opt client_output = "../src/shared/Env/HarukaCMD/HarukaCMDEvents.luau"
opt server_output = "../src/shared/Env/HarukaCMD/HarukaCMDServerEvents.luau"
opt remote_scope = "HARUKA_CMD"



funct RequestCommands = {
    call: Async,
    rets: struct {
        Commands: map {
            [string]: unknown
        }[]
    },
}

event ExecuteCommand = {
    from: Client,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        Command: string
    }
}
