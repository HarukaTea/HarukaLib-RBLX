
opt client_output = "../src/shared/Env/Replica/ReplicaEvents.luau"
opt server_output = "../src/shared/Env/Replica/ReplicaServerEvents.luau"
opt remote_scope = "HARUKA_REPLICA"



funct RequestData = {
    call: Async,
    rets: enum { Success, Failure },
}

event SetData = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: (id: u16, path: string[], value: unknown)
}
event CreateData = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: (creation: map {
        [string]: unknown[]
    })
}
event RequestCreations = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: (creation: map {
        [string]: unknown[]
    }[])
}
event DestroyData = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: (id: u16)
}
