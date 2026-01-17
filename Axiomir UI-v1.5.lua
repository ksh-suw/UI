-- Axiomir UI Library v1.5
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
local ConfigFolder = "AxiomirUI"
local ConfigFile = "Default.json"
local Dirty = false



-- Config System
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

local function registerFlag(flag, default)
    if not FlagRegistry[flag] then
        FlagRegistry[flag] = {
            Value = default,
            Default = default,
            Save = true
        }
    end
    return FlagRegistry[flag]
end


-- Notification
local NotifyGui = create("ScreenGui", {
    Parent = LocalPlayer:WaitForChild("PlayerGui"),
    ResetOnSpawn = false
})

local notifyHolder = create("Frame", {
    Parent = NotifyGui,
    Size = UDim2.fromScale(1,1),
    BackgroundTransparency = 1
})

local notifyLayout = Instance.new("UIListLayout", notifyHolder)
notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifyLayout.Padding = UDim.new(0,8)

function UI:Notify(title, content, time)
    time = time or 3

    local box = create("Frame", {
        Parent = notifyHolder,
        Size = UDim2.fromOffset(320, 70),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BackgroundTransparency = 1
    })
    create("UICorner",{Parent=box,CornerRadius=UDim.new(0,8)})

    create("TextLabel",{
        Parent=box,
        Position=UDim2.fromOffset(12,8),
        Size=UDim2.new(1,-24,0,18),
        BackgroundTransparency=1,
        Text=title,
        Font=Enum.Font.GothamBold,
        TextSize=13,
        TextColor3=Color3.new(1,1,1),
        TextXAlignment=Left
    })

    create("TextLabel",{
        Parent=box,
        Position=UDim2.fromOffset(12,28),
        Size=UDim2.new(1,-24,0,34),
        BackgroundTransparency=1,
        Text=content,
        Font=Enum.Font.Gotham,
        TextSize=12,
        TextWrapped=true,
        TextColor3=Color3.fromRGB(200,200,200),
        TextXAlignment=Left,
        TextYAlignment=Top
    })

    TweenService:Create(box, TweenInfo.new(0.3), {BackgroundTransparency=0}):Play()

    task.delay(time, function()
        local t = TweenService:Create(box, TweenInfo.new(0.3), {BackgroundTransparency=1})
        t:Play()
        t.Completed:Once(function()
            box:Destroy()
        end)
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
        Parent = LocalPlayer.PlayerGui,
        ResetOnSpawn = false
    })

    self.Main = create("Frame", {
        Parent = self.Gui,
        Size = UDim2.fromOffset(760,480),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        BackgroundColor3 = Color3.fromRGB(22,22,22)
    })
    create("UICorner",{Parent=self.Main,CornerRadius=UDim.new(0,10)})

    local header = create("TextLabel",{
        Parent=self.Main,
        Size=UDim2.new(1,0,0,36),
        BackgroundTransparency=1,
        Text=opt.Title or "Axiomir UI",
        Font=Enum.Font.GothamBold,
        TextSize=15,
        TextColor3=Color3.new(1,1,1)
    })

    -- Drag (fixed, safe)
    do
        local dragging = false
        local startPos, startMouse

        header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                startMouse = UserInputService:GetMouseLocation()
                startPos = self.Main.Position
            end
        end)

        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        RunService.RenderStepped:Connect(function()
            if dragging then
                local delta = UserInputService:GetMouseLocation() - startMouse
                self.Main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
            end
        end)
    end

    -- Toggle UI (RightCtrl)
    local visible = true
    UserInputService.InputBegan:Connect(function(i,gp)
        if not gp and i.KeyCode == Enum.KeyCode.RightControl then
            visible = not visible
            TweenService:Create(self.Main, TweenInfo.new(0.25), {
                BackgroundTransparency = visible and 0 or 1
            }):Play()
            self.Main.Visible = visible
        end
    end)

    self.TabBar = create("Frame",{
        Parent=self.Main,
        Position=UDim2.fromOffset(0,36),
        Size=UDim2.new(1,0,0,34),
        BackgroundTransparency=1
    })

    local tabLayout = Instance.new("UIListLayout", self.TabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0,6)

    self.Content = create("Frame",{
        Parent=self.Main,
        Position=UDim2.fromOffset(0,70),
        Size=UDim2.new(1,0,1,-70),
        BackgroundTransparency=1
    })

    self.Tabs = {}
    loadConfig()
    return self
end

-- Tabs / Columns / Sections (with Toggle Switch)
function Window:AddTab(name)
    local Tab = {}

    local btn = create("TextButton",{
        Parent=self.TabBar,
        Size=UDim2.fromOffset(130,28),
        BackgroundColor3=Color3.fromRGB(32,32,32),
        Text=name,
        Font=Enum.Font.Gotham,
        TextSize=12,
        TextColor3=Color3.new(1,1,1)
    })
    create("UICorner",{Parent=btn,CornerRadius=UDim.new(0,6)})

    local page = create("Frame",{
        Parent=self.Content,
        Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,
        Visible=false
    })

    btn.MouseButton1Click:Connect(function()
        for _,t in pairs(self.Tabs) do t.Page.Visible=false end
        page.Visible=true
    end)

    Tab.Page = page
    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then page.Visible = true end

    function Tab:AddColumn(_, opt)
        opt = opt or {}
        local col = {}

        local frame = create("Frame",{
            Parent=page,
            Size=UDim2.new(opt.Width or 1,0,1,0),
            BackgroundTransparency=1
        })

        local layout = Instance.new("UIListLayout", frame)
        layout.Padding = UDim.new(0,10)

        function col:AddSection(title, callback)
            local sec = {}

            local box = create("Frame",{
                Parent=frame,
                Size=UDim2.new(1,-12,0,0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=Color3.fromRGB(30,30,30)
            })
            create("UICorner",{Parent=box,CornerRadius=UDim.new(0,8)})

            create("TextLabel",{
                Parent=box,
                Size=UDim2.new(1,-16,0,24),
                Position=UDim2.fromOffset(8,6),
                BackgroundTransparency=1,
                Text=title,
                Font=Enum.Font.GothamBold,
                TextSize=13,
                TextColor3=Color3.new(1,1,1),
                TextXAlignment=Left
            })

            local body = create("Frame",{
                Parent=box,
                Position=UDim2.fromOffset(8,32),
                Size=UDim2.new(1,-16,0,0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1
            })

            local bodyLayout = Instance.new("UIListLayout", body)
            bodyLayout.Padding = UDim.new(0,6)

            -- Toggle (switch)
            function sec:AddToggle(text,opt)
                opt = opt or {}
                local data = registerFlag(opt.Flag or text, opt.Default or false)

                local row = create("Frame",{Parent=body,Size=UDim2.new(1,0,0,28),BackgroundTransparency=1})
                create("TextLabel",{Parent=row,Size=UDim2.new(1,-50,1,0),BackgroundTransparency=1,Text=text,Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.new(1,1,1),TextXAlignment=Left})

                local sw = create("Frame",{Parent=row,Size=UDim2.fromOffset(36,18),Position=UDim2.fromScale(1,-0.5)+UDim2.fromOffset(-36,14),BackgroundColor3=Color3.fromRGB(60,60,60)})
                create("UICorner",{Parent=sw,CornerRadius=UDim.new(1,0)})

                local knob = create("Frame",{Parent=sw,Size=UDim2.fromOffset(14,14),Position=UDim2.fromOffset(2,2),BackgroundColor3=Color3.new(1,1,1)})
                create("UICorner",{Parent=knob,CornerRadius=UDim.new(1,0)})

                local function update(v)
                    TweenService:Create(knob,TweenInfo.new(0.2),{
                        Position = v and UDim2.fromOffset(20,2) or UDim2.fromOffset(2,2)
                    }):Play()
                    sw.BackgroundColor3 = v and Color3.fromRGB(90,120,255) or Color3.fromRGB(60,60,60)
                end

                data.Update = update
                update(data.Value)

                sw.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        data.Value = not data.Value
                        Dirty = true
                        update(data.Value)
                        if opt.Callback then opt.Callback(data.Value) end
                    end
                end)
            end

            if callback then callback(sec) end
        end

        return col
    end

    return Tab
end


-- Public API
function UI:GetFlag(f)
    return FlagRegistry[f] and FlagRegistry[f].Value
end

return UI
