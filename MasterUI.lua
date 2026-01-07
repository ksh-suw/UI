-- Mukuro UI Library  Core Skeleton
-- Author: Goody


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer


local UI = {}
UI.__index = UI


-- Flag & Config System
local FlagRegistry = {}
local ConfigEnabled = true
local ConfigFolder = "MukuroUI"
local ConfigFile = "Default.json"
local ConfigDirty = false

local function getConfigPath()
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
    for flag, info in pairs(FlagRegistry) do
        if info.Save then
            data[flag] = info.Value
        end
    end

    writefile(getConfigPath(), HttpService:JSONEncode(data))
end

local function loadConfig()
    if not ConfigEnabled then return end
    if not isfile(getConfigPath()) then return end

    local raw = readfile(getConfigPath())
    local decoded = HttpService:JSONDecode(raw)

    for flag, value in pairs(decoded) do
        if FlagRegistry[flag] then
            FlagRegistry[flag].Value = value
        end
    end
end

-- Auto save loop
task.spawn(function()
    while true do
        task.wait(1)
        if ConfigDirty then
            ConfigDirty = false
            saveConfig()
        end
    end
end)


-- Base Object Helper
local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
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
        Name = "MukuroUI",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false
    })

    self.Main = create("Frame", {
        Parent = self.Gui,
        Size = opt.Size or UDim2.fromOffset(640, 380),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0
    })

    self.Title = create("TextLabel", {
        Parent = self.Main,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = opt.Title or "Window",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })

    self.TabBar = create("Frame", {
        Parent = self.Main,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BorderSizePixel = 0
    })

    self.Content = create("Frame", {
        Parent = self.Main,
        Position = UDim2.fromOffset(0, 60),
        Size = UDim2.new(1, 0, 1, -60),
        BackgroundTransparency = 1
    })

    self.Tabs = {}
    loadConfig()

    return self
end

function Window:AddTab(name)
    local Tab = {}
    Tab.__index = Tab

    local button = create("TextButton", {
        Parent = self.TabBar,
        Size = UDim2.fromOffset(100, 30),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.Gotham,
        TextSize = 12
    })

    local page = create("Frame", {
        Parent = self.Content,
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Visible = false
    })

    Tab.Page = page
    Tab.Columns = {}

    function Tab:AddColumn(_, opt)
        opt = opt or {}
        local Column = {}
        Column.__index = Column

        local frame = create("Frame", {
            Parent = page,
            Size = UDim2.new(opt.Width or 0.5, 0, 1, 0),
            BackgroundTransparency = 1
        })

        local layout = Instance.new("UIListLayout", frame)
        layout.Padding = UDim.new(0, 6)

        Column.Frame = frame

        function Column:AddSection(title, callback)
            local secFrame = create("Frame", {
                Parent = frame,
                Size = UDim2.new(1, -10, 0, 30),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(35,35,35),
                BorderSizePixel = 0
            })

            local label = create("TextLabel", {
                Parent = secFrame,
                Size = UDim2.new(1, -10, 0, 24),
                Position = UDim2.fromOffset(5,5),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Color3.new(1,1,1),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Left
            })

            local body = create("Frame", {
                Parent = secFrame,
                Position = UDim2.fromOffset(0, 30),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            })

            local list = Instance.new("UIListLayout", body)
            list.Padding = UDim.new(0, 4)

            local Section = {}

            function Section:AddToggle(text, opt)
                opt = opt or {}
                local flag = opt.Flag or text
                if not FlagRegistry[flag] then
                    FlagRegistry[flag] = {
                        Type = "Toggle",
                        Value = opt.Default or false,
                        Default = opt.Default or false,
                        Save = true
                    }
                end

                local btn = create("TextButton", {
                    Parent = body,
                    Size = UDim2.new(1, -10, 0, 24),
                    BackgroundColor3 = Color3.fromRGB(45,45,45),
                    Text = text,
                    TextColor3 = Color3.new(1,1,1),
                    Font = Enum.Font.Gotham,
                    TextSize = 12
                })

                btn.MouseButton1Click:Connect(function()
                    local v = not FlagRegistry[flag].Value
                    FlagRegistry[flag].Value = v
                    ConfigDirty = true
                    if opt.Callback then opt.Callback(v) end
                end)
            end

            function Section:AddStats(title)
                local container = {}
                container.Values = {}

                function container:Set(name, value)
                    container.Values[name] = value
                end

                return container
            end

            if callback then
                callback(Section)
            end
        end

        return Column
    end

    button.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do
            t.Page.Visible = false
        end
        page.Visible = true
    end)

    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then
        page.Visible = true
    end

    return Tab
end


-- Global API
function UI:SetFlag(flag, value)
    if FlagRegistry[flag] then
        FlagRegistry[flag].Value = value
        ConfigDirty = true
    end
end

function UI:GetFlag(flag)
    return FlagRegistry[flag] and FlagRegistry[flag].Value
end

function UI:SetConfigEnabled(v)
    ConfigEnabled = v
end

return UI
