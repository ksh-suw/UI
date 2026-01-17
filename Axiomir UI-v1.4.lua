-- Axiomir UI-v1.4
-- Author: Goody


--// Services
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
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        BackgroundColor3 = Color3.fromRGB(25,25,25),
        BorderSizePixel = 0
    })

    create("UICorner",{Parent=self.Main,CornerRadius=UDim.new(0,8)})

    local title = create("TextLabel", {
        Parent = self.Main,
        Size = UDim2.new(1,0,0,32),
        BackgroundTransparency = 1,
        Text = opt.Title or "Axiomir UI",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.new(1,1,1)
    })

    -- Drag
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            local start = UserInputService:GetMouseLocation()
            local startPos = self.Main.Position

            local move; move = RunService.RenderStepped:Connect(function()
                local delta = UserInputService:GetMouseLocation() - start
                self.Main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
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
        Position = UDim2.fromOffset(0,32),
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BorderSizePixel = 0
    })

    local tabLayout = Instance.new("UIListLayout", self.TabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal

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

-- Tab/Column/Section
function Window:AddTab(name)
    local Tab = {}
    Tab.Columns = {}

    local btn = create("TextButton", {
        Parent = self.TabBar,
        Size = UDim2.fromOffset(120,30),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.new(1,1,1)
    })

    local page = create("Frame", {
        Parent = self.Content,
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Visible = false
    })

    function Tab:AddColumn(_, opt)
        opt = opt or {}
        local col = {}

        local frame = create("Frame", {
            Parent = page,
            Size = UDim2.new(opt.Width or 0.5,0,1,0),
            BackgroundTransparency = 1
        })

        local list = Instance.new("UIListLayout", frame)
        list.Padding = UDim.new(0,8)

        function col:AddSection(title, callback)
            local sec = {}

            local box = create("Frame", {
                Parent = frame,
                Size = UDim2.new(1,-8,0,30),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(35,35,35),
                BorderSizePixel = 0
            })

            create("UICorner",{Parent=box,CornerRadius=UDim.new(0,6)})

            create("TextLabel",{
                Parent=box,
                Size=UDim2.new(1,-10,0,24),
                Position=UDim2.fromOffset(5,4),
                BackgroundTransparency=1,
                Text=title,
                Font=Enum.Font.GothamBold,
                TextSize=12,
                TextColor3=Color3.new(1,1,1),
                TextXAlignment=Left
            })

            local body = create("Frame",{
                Parent=box,
                Position=UDim2.fromOffset(0,28),
                Size=UDim2.new(1,0,0,0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1
            })

            local layout = Instance.new("UIListLayout", body)
            layout.Padding = UDim.new(0,6)

            -- Toggle
            function sec:AddToggle(text,opt)
                opt = opt or {}
                local data = registerFlag(opt.Flag or text, opt.Default or false, true)

                local b = create("TextButton",{
                    Parent = body,
                    Size = UDim2.new(1,-10,0,24),
                    BackgroundColor3 = Color3.fromRGB(45,45,45),
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Color3.new(1,1,1)
                })

                local function update(v)
                    b.BackgroundColor3 = v and Color3.fromRGB(90,120,255) or Color3.fromRGB(45,45,45)
                end

                data.Update = update
                update(data.Value)

                b.MouseButton1Click:Connect(function()
                    data.Value = not data.Value
                    update(data.Value)
                    Dirty = true
                    if opt.Callback then opt.Callback(data.Value) end
                end)
            end

            if callback then callback(sec) end
        end

        return col
    end

    btn.MouseButton1Click:Connect(function()
        for _,t in pairs(self.Tabs) do
            t.Page.Visible = false
        end
        page.Visible = true
    end)

    Tab.Page = page
    table.insert(self.Tabs, Tab)

    if #self.Tabs == 1 then
        page.Visible = true
    end

    return Tab
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

return UI
