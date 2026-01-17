-- Axiomir UI Library 1.4
-- Author: Goody


--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer


-- Core State
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
    for k, v in pairs(FlagRegistry) do
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
    for k, v in pairs(data) do
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
    for k, v in pairs(props or {}) do
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
    Name = "Axiomir_Notification",
    Parent = LocalPlayer:WaitForChild("PlayerGui"),
    ResetOnSpawn = false
})

local NotifHolder = create("Frame", {
    Parent = NotifGui,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.fromScale(0.98, 0.95),
    Size = UDim2.fromOffset(320, 400),
    BackgroundTransparency = 1
})

local notifLayout = Instance.new("UIListLayout", NotifHolder)
notifLayout.Padding = UDim.new(0, 8)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

function UI:Notify(title, text, duration)
    duration = duration or 4

    local frame = create("Frame", {
        Parent = NotifHolder,
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

    create("TextLabel", {
        Parent = frame,
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -20, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(120, 170, 255),
        TextXAlignment = Left
    })

    create("TextLabel", {
        Parent = frame,
        Position = UDim2.fromOffset(10, 26),
        Size = UDim2.new(1, -20, 0, 40),
        BackgroundTransparency = 1,
        TextWrapped = true,
        TextYAlignment = Top,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Left
    })

    TweenService:Create(frame, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()

    task.delay(duration, function()
        local tw = TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
        tw:Play()
        tw.Completed:Wait()
        frame:Destroy()
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
        Size = opt.Size or UDim2.fromOffset(720, 460),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(24, 24, 24),
        BorderSizePixel = 0
    })

    create("UICorner", { Parent = self.Main, CornerRadius = UDim.new(0, 10) })

    local header = create("TextLabel", {
        Parent = self.Main,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Text = opt.Title or "Axiomir UI",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1)
    })

    -- Drag
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            local startPos = UserInputService:GetMouseLocation()
            local startFrame = self.Main.Position

            local move; move = RunService.RenderStepped:Connect(function()
                local delta = UserInputService:GetMouseLocation() - startPos
                self.Main.Position = startFrame + UDim2.fromOffset(delta.X, delta.Y)
            end)

            UserInputService.InputEnded:Once(function(e)
                if e.UserInputType == Enum.UserInputType.MouseButton1 then
                    move:Disconnect()
                end
            end)
        end
    end)

    self.TabBar = create("Frame", {
        Parent = self.Main,
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0
    })

    local tabLayout = Instance.new("UIListLayout", self.TabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal

    self.Content = create("Frame", {
        Parent = self.Main,
        Position = UDim2.fromOffset(0, 66),
        Size = UDim2.new(1, 0, 1, -66),
        BackgroundTransparency = 1
    })

    self.Tabs = {}

    -- RightCtrl minimize
    local visible = true
    UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.RightControl then
            visible = not visible
            TweenService:Create(self.Main, TweenInfo.new(0.25), {
                BackgroundTransparency = visible and 0 or 1
            }):Play()
            self.Main.Visible = visible
        end
    end)

    loadConfig()
    return self
end


-- Public API
function UI:GetFlag(f)
    return FlagRegistry[f] and FlagRegistry[f].Value
end

function UI:SetFlag(f, v)
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
