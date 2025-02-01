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
function HarukaCMD.new()
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
    else

    end

    self.Commands = {}

    self.Add, self.Empty = HarukaLib.Bin()

    return self
end



function HarukaCMD:Init()
    if RunService:IsClient() then
        self.Rank = false

        Promise.new(function()
            self.Rank = Players.LocalPlayer:GetRankInGroup(16912246)
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
            text ..= string.upper(suggestedCommand.Alias)
            text ..= " "
            for _, _ in suggestedCommand.Args do
                text ..= "<>"
                text ..= " "
            end

            wait()
            self.CMDInput:set(text)
            self.UI.Full.Input.CMD.CursorPosition = #text
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

        nextPointer = math.clamp(nextPointer, 1, totalElements)

        self.AutoCompletePointer:set(nextPointer)
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

        elseif input.KeyCode == Enum.KeyCode.Tab then
            self.AutoCompleteFunc()
        end
    end))

    local panelCommand = Instance.new("TextChatCommand")
    panelCommand.Name = "HarukaCMDCommand"
    panelCommand.Parent = TextChatService:WaitForChild("TextChatCommands")
    panelCommand.PrimaryAlias = "/cmds"
    panelCommand.SecondaryAlias = "/debug"
    panelCommand.AutocompleteVisible = true
    panelCommand.Enabled = true

    panelCommand.Triggered:Connect(function(textSource: TextSource)
        if textSource.UserId == Players.LocalPlayer.UserId then
            self.IsShown:set(not Fusion.peek(self.IsShown))
        end
    end)

    self.Add(panelCommand)
end


function HarukaCMD:_ListenUITracker()
    local cmdOpenObserver = Fusion.Observer(self.scope, self.IsShown)
    cmdOpenObserver:onBind(function()
        if Fusion.peek(self.IsShown) then
            self.UI.Full.Input.CMD:CaptureFocus()

            wait()
            self.CMDInput:set("")

            if GuiService.MenuIsOpen then
                self.IsShown:set(false) --- special case for roblox menu bugs (rarely)
            end
        else
            self.UI.Full.Input.CMD:ReleaseFocus()
        end
    end)


    local cmdInputObserver = Fusion.Observer(self.scope, self.CMDInput)
    cmdInputObserver:onBind(function()
        local input = Fusion.peek(self.CMDInput) :: string
        local realInput = string.upper(input)

        local acceptedCmds = {}
        for _, cmd: table in self.Commands do
            local inputLen, aliasLen = #realInput, #cmd.Alias
            local inputCMD, aliasCMD = realInput, string.upper(cmd.Alias)

            if inputLen > aliasLen then
                inputCMD, aliasCMD = aliasCMD, inputCMD
            end
            if string.find(aliasCMD, inputCMD) then
                table.insert(acceptedCmds, cmd)
            end
        end

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
        if pointer <= 0 or #suggestedCommands <= 0 then
            self.ItemIntellisense:set({})
            return
        end

        local curSuggested = suggestedCommands[pointer] :: table
        self.ItemIntellisense:set(curSuggested.Args)
    end)
end



--// Server Private Methods

function HarukaCMD:_InitRequestListenTracker()
    Events.RequestCommands.SetCallback(function()
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
        local cmd = string.lower(data.Command)
        local cmdWithoutSpace = string.gsub(cmd, " ", "")

        local cmdId = string.match(cmdWithoutSpace, "([^<]+)")
        if cmdId == "" or cmdId == nil then return end

        local cmdArgs = {}
        local cmdArgsStr = string.gmatch(cmdWithoutSpace, "<([^>]+)>")

        for arg in cmdArgsStr or {} do
            table.insert(cmdArgs, arg)
        end

        local realCmd = nil
        for _, cmdProp in self.Commands do
            if cmdProp.Alias == string.lower(cmdId) then
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


        Promise.new(function(resolve)
            realCmd.Callback({
                Executor = plr,
                ExecutorObj = playerObj,
                Args = cmdArgs,

                ResolveObj = resolve
            })
        end):catch(function(err)
            warn(tostring(err))
        end)
    end)
end


return HarukaCMD
