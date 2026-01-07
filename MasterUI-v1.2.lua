-- Mukuro UI Library Core-1.2
-- Author: Goody

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Core
local UI = {}
UI.__index = UI

local FlagRegistry = {}
local ConfigEnabled = true
local ConfigFolder = "MukuroUI"
local ConfigFile = "Default.json"
local Dirty = false

local function cfgPath()
    return ConfigFolder .. "/" .. ConfigFile
end

local function ensureFolder()
    if not isfolder(ConfigFolder) then
        makefolder(ConfigFolder)
    end
end

local function saveConfig()
    if not ConfigEnabled then return end
    ensureFolder()

    local data = {}
    for k,v in pairs(FlagRegistry) do
        if v.Save then
            data[k] = v.Value
        end
    end
    writefile(cfgPath(), HttpService:JSONEncode(data))
end

local function loadConfig()
    if not ConfigEnabled then return end
    if not isfile(cfgPath()) then return end

    local data = HttpService:JSONDecode(readfile(cfgPath()))
    for k,v in pairs(data) do
        if FlagRegistry[k] then
            FlagRegistry[k].Value = v
            if FlagRegistry[k].Update then
                FlagRegistry[k].Update(v)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if Dirty then
            Dirty = false
            saveConfig()
        end
    end
end)

-- Helpers
local function create(class, props)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do
        o[k] = v
    end
    return o
end

local function registerFlag(flag, default, save)
    if not FlagRegistry[flag] then
        FlagRegistry[flag] = {
            Value = default,
            Default = default,
            Save = save ~= false
        }
    end
    return FlagRegistry[flag]
end

-- Window
local Window = {}
Window.__index = Window

function UI:CreateWindow(opt)
    opt = opt or {}

    ConfigEnabled = opt.Config and opt.Config.Enabled ~= false
    ConfigFolder = opt.Config and opt.Config.Folder or ConfigFolder
    ConfigFile = opt.Config and opt.Config.File or ConfigFile

    local self = setmetatable({}, Window)

    self.Gui = create("ScreenGui", {
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false
    })

    self.Main = create("Frame", {
        Parent = self.Gui,
        Size = opt.Size or UDim2.fromOffset(650, 400),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        BackgroundColor3 = Color3.fromRGB(25,25,25),
        BorderSizePixel = 0
    })

    create("UICorner",{Parent=self.Main,CornerRadius=UDim.new(0,8)})

    create("TextLabel", {
        Parent = self.Main,
        Size = UDim2.new(1,0,0,32),
        BackgroundTransparency = 1,
        Text = opt.Title or "Mukuro UI",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.new(1,1,1)
    })

    self.TabBar = create("Frame", {
        Parent = self.Main,
        Position = UDim2.fromOffset(0,32),
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BorderSizePixel = 0
    })

    self.Content = create("Frame", {
        Parent = self.Main,
        Position = UDim2.fromOffset(0,62),
        Size = UDim2.new(1,0,1,-62),
        BackgroundTransparency = 1
    })

    self.Tabs = {}
    loadConfig()

    return self
end

-- Public API
function UI:GetFlag(f)
    return FlagRegistry[f] and FlagRegistry[f].Value
end

function UI:SetFlag(f,v)
    if FlagRegistry[f] then
        FlagRegistry[f].Value = v
        if FlagRegistry[f].Update then
            FlagRegistry[f].Update(v)
        end
        Dirty = true
    end
end

function UI:SetConfigEnabled(v)
    ConfigEnabled = v
end

return UI
