--!nocheck

--// Cmd for my own projects

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local SSS = game:GetService("ServerScriptService")


local HarukaLib = require(RepS.HarukaShared.Shared.HarukaLib)
local Fusion = require(RepS.HarukaShared.Shared.Fusion)
local Promise = require(RepS.HarukaShared.Shared.Promise)


local Events = nil
if RunService:IsClient() then
    Events = require(script.HarukaCMDEvents)
else
    Events = require(script.HarukaCMDServerEvents)
end

local GameEvents = nil
if RunService:IsServer() then
    GameEvents = require(SSS.HarukaServer.Library.ServerEvents)
end

local PlayerLib = nil
if RunService:IsServer() then
    PlayerLib = require(SSS.HarukaServer.Services.PlayerLib)
end


local UIComponent = require(script.UIComponent)

local wait = task.wait


local HarukaCMD = {}
HarukaCMD.__index = HarukaCMD

--// Helper functions

--// Constructor
function HarukaCMD.new(groupId: number)
    local self = setmetatable({}, HarukaCMD)

    if RunService:IsClient() then
        self.scope = Fusion.scoped(Fusion)
        local function Value(val: any) : Fusion.Value
            return Fusion.Value(self.scope, val)
        end


        self.IsShown = Value(false)
        self.CMDInput = Value("")

        self.CMDIntellisense = Value({})
        self.ItemIntellisense = Value({})
        self.Rank = 0

        self.AutoCompletePointer = Value(1)
        self.ItemAutoCompletePointer = Value(1)

        self.ExtraArgs = {}
        for _ = 1, 7 do
            table.insert(self.ExtraArgs, Value(""))
        end
    else

    end

    self.GroupId = groupId
    self.Commands = {}

    self.Add, self.Empty = HarukaLib.Bin()

    return self
end



function HarukaCMD:Init()
    if RunService:IsClient() then
        self.Rank = false

        Promise.new(function()
            self.Rank = Players.LocalPlayer:GetRankInGroup(self.GroupId)
        end):catch(function()
            self.Rank = 0
        end)

        self:_InitUI()
        self:_ListenUITracker()
        self:_ListenInputTracker()

        local commands = Events.RequestCommands.Call().Commands
        repeat wait() until self.Rank

        print("[Haruka CMD] Rank is "..self.Rank)
        for index: number, cmd in commands do
            if cmd.RankReq > self.Rank then
                table.remove(commands, index)
            end
        end

        self.Commands = commands

        self.AutoCompleteFunc = function()
            local suggestedCommands = Fusion.peek(self.CMDIntellisense) :: table
            local nextPointer = Fusion.peek(self.AutoCompletePointer) :: number

            if not suggestedCommands[1] then return end
            if not suggestedCommands[nextPointer] then return end

            local suggestedCommand = suggestedCommands[nextPointer] :: table

            local text = ""
            text ..= suggestedCommand.Alias
            text ..= " "
            for _, _ in suggestedCommand.Args do
                text ..= "<>"
                text ..= " "
            end

            wait()
            self.CMDInput:set(text)
        end
        self.ArgAutoCompleteFunc = function(argProps: {
            Option: string,
            Index: number
        })
            local text = Fusion.peek(self.CMDInput) :: string
            local count = 0

            local result = string.gsub(text, "<([^>]*)>", function(content)
                count += 1

                if count == argProps.Index then
                    return "<"..argProps.Option..">"
                else
                    return "<"..content..">"
                end
            end)

            wait()
            self.CMDInput:set(result)
        end
    else
        self:_InitRequestListenTracker()
        self:_InitCommandExecutionTracker()
    end
end


function HarukaCMD:AddCommand(commandProps: {
    Name: string,
    Alias: string,
    Callback: (T...) -> nil,
    RankReq: number,
    Args: {
        Name: string,
        Type: string
    }
})
    table.insert(self.Commands, commandProps)
end


function HarukaCMD:Destroy()
    if RunService:IsClient() then
        Fusion.doCleanup(self.scope)
    end


    self.Empty()
    self = nil
end


--// Private Methods

function HarukaCMD:_InitUI()
    self.UI = UIComponent(self.scope, {
        IsShownVal = self.IsShown,
        CMDInput = self.CMDInput,
        Intellisense = self.CMDIntellisense,
        IntellisensePointer = self.AutoCompletePointer,
        ItemIntellisense = self.ItemIntellisense,
        ItemIntellisensePointer = self.ItemAutoCompletePointer,
        ExtraArgs = self.ExtraArgs,

        AutoCompleteFunc = self.AutoCompleteFunc,
    }, self)
end


function HarukaCMD:_ListenInputTracker()
    local function _handleOpen(gpe: boolean)
        if GuiService.MenuIsOpen then
            self.IsShown:set(false)
            return
        end
        if gpe and not Fusion.peek(self.IsShown) then return end


        self.IsShown:set(not Fusion.peek(self.IsShown))
    end
    local function _handlePointer(nextPointer: number)
        local totalElements = #Fusion.peek(self.CMDIntellisense) :: number
        if totalElements <= 0 then totalElements = 1 end

        nextPointer = math.clamp(nextPointer, 1, totalElements)

        self.AutoCompletePointer:set(nextPointer)
    end
    local function _handleItemPointer(nextPointer: number)
        local totalElements = #Fusion.peek(self.ItemIntellisense) :: number
        if totalElements <= 0 then totalElements = 1 end

        nextPointer = math.clamp(nextPointer, 1, totalElements)

        self.ItemAutoCompletePointer:set(nextPointer)
    end
    self.Add(UserInputService.InputBegan:Connect(function(input, gpe)
        if input.KeyCode == Enum.KeyCode.Quote then
            _handleOpen(gpe)

        elseif input.KeyCode == Enum.KeyCode.Return then
            self.IsShown:set(false)

            Events.ExecuteCommand.Fire({
                Command = Fusion.peek(self.CMDInput)
            })

        elseif input.KeyCode == Enum.KeyCode.Down then
            _handlePointer(Fusion.peek(self.AutoCompletePointer) + 1)

        elseif input.KeyCode == Enum.KeyCode.Up then
            _handlePointer(Fusion.peek(self.AutoCompletePointer) - 1)

        elseif input.KeyCode == Enum.KeyCode.Right then
            _handleItemPointer(Fusion.peek(self.ItemAutoCompletePointer) + 1)

        elseif input.KeyCode == Enum.KeyCode.Left then
            _handleItemPointer(Fusion.peek(self.ItemAutoCompletePointer) - 1)

        elseif input.KeyCode == Enum.KeyCode.Tab then
            self.AutoCompleteFunc()
        end
    end))

    local panelCommand = Instance.new("TextChatCommand")
    panelCommand.Name = "HarukaCMDCommand"
    panelCommand.Parent = TextChatService:WaitForChild("TextChatCommands")
    panelCommand.PrimaryAlias = "/cmds"
    panelCommand.SecondaryAlias = "!cmds"
    panelCommand.AutocompleteVisible = true
    panelCommand.Enabled = true

    panelCommand.Triggered:Connect(function(textSource: TextSource)
        if textSource.UserId == Players.LocalPlayer.UserId then
            self.IsShown:set(not Fusion.peek(self.IsShown))
        end
    end)

    self.Add(panelCommand)
    self.Add(GuiService.MenuOpened:Connect(_handleOpen))
end


function HarukaCMD:_ListenUITracker()
    local cmdOpenObserver = Fusion.Observer(self.scope, self.IsShown)
    cmdOpenObserver:onBind(function()
        if Fusion.peek(self.IsShown) then
            self.CMDInput:set("/")

            if GuiService.MenuIsOpen then
                self.IsShown:set(false) --- special case for roblox menu bugs (rarely)
            end

            for _, argVal: Fusion.Value in self.ExtraArgs do
                argVal:set("")
            end
        end
    end)


    local cmdInputObserver = Fusion.Observer(self.scope, self.CMDInput)
    cmdInputObserver:onBind(function()
        local input = Fusion.peek(self.CMDInput) :: string
        local realInput = string.gsub(input, " ", "")

        local acceptedCmds = {}
        pcall(function()
            for _, cmd: table in self.Commands do
                local inputLen, aliasLen = #realInput, #cmd.Alias
                local inputCMD, aliasCMD = realInput, cmd.Alias

                if inputLen > aliasLen then
                    inputCMD, aliasCMD = aliasCMD, inputCMD
                end
                if string.find(aliasCMD, inputCMD) then
                    table.insert(acceptedCmds, cmd)
                end
            end
        end)

        self.CMDIntellisense:set(acceptedCmds)

        if #acceptedCmds <= 0 then return end

        local totalElements = #acceptedCmds
        local nextPointer = math.clamp(Fusion.peek(self.AutoCompletePointer), 1, totalElements)

        self.AutoCompletePointer:set(nextPointer)
    end)


    local pointerObserver = Fusion.Observer(self.scope, self.AutoCompletePointer)
    pointerObserver:onBind(function()
        local pointer = Fusion.peek(self.AutoCompletePointer) :: number
        local suggestedCommands = Fusion.peek(self.CMDIntellisense) :: table
        if #suggestedCommands <= 0 then
            self.ItemIntellisense:set({})
            return
        end

        pointer = math.clamp(pointer, 1, #suggestedCommands)

        local curSuggested = suggestedCommands[pointer] :: table
        self.ItemIntellisense:set(curSuggested.Args)

        for _, argVal: Fusion.Value in self.ExtraArgs do
            argVal:set("")
        end
    end)


    local cmdIntellisenseObserver = Fusion.Observer(self.scope, self.CMDIntellisense)
    cmdIntellisenseObserver:onBind(function()
        local suggestedCommands = Fusion.peek(self.CMDIntellisense) :: table
        if #suggestedCommands <= 0 then
            self.ItemIntellisense:set({})
            return
        end

        local pointer = Fusion.peek(self.AutoCompletePointer) :: number

        pointer = math.clamp(pointer, 1, #suggestedCommands)
        self.AutoCompletePointer:set(pointer)

        local curSuggested = suggestedCommands[pointer] :: table
        self.ItemIntellisense:set(curSuggested.Args)

        for _, argVal: Fusion.Value in self.ExtraArgs do
            argVal:set("")
        end
    end)


    local itemIntellisenseObserver = Fusion.Observer(self.scope, self.ItemIntellisense)
    itemIntellisenseObserver:onBind(function()
        self.ItemAutoCompletePointer:set(1)
    end)
end



--// Server Private Methods

function HarukaCMD:_InitRequestListenTracker()
    Events.RequestCommands.SetCallback(function(plr: Player)
        local transformedCommands = {}

        for _, cmd in self.Commands do
            table.insert(transformedCommands, HarukaLib:CopyTableExcept(cmd, { "Callback" }))
        end

        return {
            Commands = transformedCommands
        }
    end)
end


function HarukaCMD:_InitCommandExecutionTracker()
    Events.ExecuteCommand.SetCallback(function(plr: Player, data)
        local command = data.Command
        local cmdId = string.match(command, "^(/%S+)")
        if cmdId == "" or cmdId == nil then return end

        local cmdArgs = {}
        local cmdArgsStr = string.gmatch(command, "<([^>]+)>")
        for arg in cmdArgsStr or {} do
            table.insert(cmdArgs, arg)
        end

        local realCmd = nil
        for _, cmdProp in self.Commands do
            if cmdProp.Alias == cmdId then
                realCmd = cmdProp
                break
            end
        end
        if realCmd == nil then return end


        --// Check if the player has the required rank
        local playerObj = PlayerLib:GetPlayerObjByPlayer(plr)
        if playerObj.Attrs.Rank < realCmd.RankReq then
            GameEvents.CreateNotify.Fire(plr, "You do not have the required rank to execute this command!")
            return
        end


        --// return true args
        local check, validatedArgs = self:_ValidateCmd(realCmd, cmdArgs)
        if not check then
            GameEvents.CreateNotify.Fire(plr, "Invalid arguments for command!")
            return
        end


        Promise.new(function(resolve)
            realCmd.Callback({
                Executor = plr,
                ExecutorObj = playerObj,
                Args = validatedArgs,

                ResolveObj = resolve
            })
        end):catch(function(err)
            warn(tostring(err))

            GameEvents.CreateNotify.Fire(plr, "An error occurred while executing the command!")
        end)
    end)
end


function HarukaCMD:_ValidateCmd(realCMD: table, cmdArgs: { string }) : (boolean, table)
    local realCMDArgs = table.clone(cmdArgs)

    local args = realCMD.Args :: table
    local check = true
    for index: number, arg: string in realCMDArgs do
        if not args[index] then
            check = false
            break
        end

        local argType = args[index].Type
        if argType == "number" then
            if not tonumber(arg) then
                check = false
                break
            end

            realCMDArgs[index] = tonumber(arg)

        elseif argType == "player" then
            local hasPlayer = false
            for _, thatPlayerObj: table in PlayerLib:GetPlayerPool() do
                if string.lower(thatPlayerObj.Player.Name) == string.lower(arg) then
                    realCMDArgs[index] = thatPlayerObj.Player
                    hasPlayer = true
                    break
                end
            end

            if not hasPlayer then
                check = false
                break
            end

        elseif argType == "players" then
            local hasPlayer = false

            if arg ~= "All" then
                for _, thatPlayerObj: table in PlayerLib:GetPlayerPool() do
                    if string.lower(thatPlayerObj.Player.Name) == string.lower(arg) then
                        realCMDArgs[index] = { thatPlayerObj.Player }
                        hasPlayer = true
                        break
                    end
                end

                if not hasPlayer then
                    check = false
                    break
                end
            else
                local totalPlayers = {}
                for _, thatPlayerObj: table in PlayerLib:GetPlayerPool() do
                    table.insert(totalPlayers, thatPlayerObj.Player)
                end

                realCMDArgs[index] = totalPlayers
            end
        end
    end
    if not check then
        return false, {}
    end

    return true, realCMDArgs
end


return HarukaCMD
