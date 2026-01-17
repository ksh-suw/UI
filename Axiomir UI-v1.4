--  Axiomir UI-v1.4 test
-- Author: Goody

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer


-- Core
local UI = {}
UI.__index = UI

local FlagRegistry = {}
local ConfigEnabled = true
local ConfigFolder = "MukuroUI"
local ConfigFile = "Default.json"
local Dirty = false


-- Config
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

-- Notification System
local NotifGui = create("ScreenGui", {
    Parent = LocalPlayer:WaitForChild("PlayerGui"),
    ResetOnSpawn = false
})

local NotifHolder = create("Frame", {
    Parent = NotifGui,
    AnchorPoint = Vector2.new(1,0),
    Position = UDim2.fromScale(1,0),
    Size = UDim2.new(0,320,1,0),
    BackgroundTransparency = 1
})

local NotifLayout = Instance.new("UIListLayout", NotifHolder)
NotifLayout.Padding = UDim.new(0,8)
NotifLayout.HorizontalAlignment = Right
NotifLayout.VerticalAlignment = Top

function UI:Notify(title, text, time)
    time = time or 3

    local box = create("Frame", {
        Parent = NotifHolder,
        Size = UDim2.fromOffset(300,60),
        BackgroundColor3 = Color3.fromRGB(35,35,35),
        BackgroundTransparency = 1
    })
    create("UICorner",{Parent=box,CornerRadius=UDim.new(0,8)})

    create("TextLabel",{
        Parent=box,
        Position=UDim2.fromOffset(10,6),
        Size=UDim2.new(1,-20,0,18),
        BackgroundTransparency=1,
        Text=title,
        Font=Enum.Font.GothamBold,
        TextSize=13,
        TextColor3=Color3.new(1,1,1),
        TextXAlignment=Left
    })

    create("TextLabel",{
        Parent=box,
        Position=UDim2.fromOffset(10,26),
        Size=UDim2.new(1,-20,0,28),
        BackgroundTransparency=1,
        Text=text,
        Font=Enum.Font.Gotham,
        TextSize=12,
        TextColor3=Color3.fromRGB(200,200,200),
        TextWrapped=true,
        TextXAlignment=Left
    })

    TweenService:Create(box,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()

    task.delay(time,function()
        TweenService:Create(box,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
        task.wait(0.3)
        box:Destroy()
    end)
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
        Size = opt.Size or UDim2.fromOffset(720,460),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        BackgroundColor3 = Color3.fromRGB(25,25,25),
        BorderSizePixel = 0
    })
    create("UICorner",{Parent=self.Main,CornerRadius=UDim.new(0,10)})

    -- Title Bar
    local TitleBar = create("TextLabel", {
        Parent = self.Main,
        Size = UDim2.new(1,0,0,34),
        BackgroundTransparency = 1,
        Text = opt.Title or "UI",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.new(1,1,1)
    })

    -- Drag
    do
        local dragging, startPos, startInput
        TitleBar.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=true
                startPos=self.Main.Position
                startInput=i.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                local delta=i.Position-startInput
                self.Main.Position=startPos+UDim2.fromOffset(delta.X,delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=false
            end
        end)
    end

    -- RightCtrl toggle
    local visible = true
    UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightControl then
            visible = not visible
            TweenService:Create(self.Main,TweenInfo.new(0.25),{
                BackgroundTransparency = visible and 0 or 1
            }):Play()
            self.Main.Visible = visible
        end
    end)

    self.TabBar = create("Frame", {
        Parent = self.Main,
        Position = UDim2.fromOffset(0,34),
        Size = UDim2.new(1,0,0,32),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BorderSizePixel = 0
    })

    self.Content = create("Frame", {
        Parent = self.Main,
        Position = UDim2.fromOffset(0,66),
        Size = UDim2.new(1,0,1,-66),
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
        FlagRegistry[f].Value=v
        if FlagRegistry[f].Update then
            FlagRegistry[f].Update(v)
        end
        Dirty=true
    end
end

function UI:SetConfigEnabled(v)
    ConfigEnabled=v
end

return UI
