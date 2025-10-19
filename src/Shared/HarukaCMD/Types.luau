--!nolint LocalUnused
--!nolint LocalShadow
--!nolint SameLineStatement
--!nolint ImplicitReturn

export type CallbackProps = {
    Executor: Player,
    Args: { any },

    ResolveObj: () -> nil
}

export type CommandJSON = {
    Name: string,
    Alias: string,
    Args: { string },
    RankReq: number,

    Callback: (props: CallbackProps) -> nil
}


return nil