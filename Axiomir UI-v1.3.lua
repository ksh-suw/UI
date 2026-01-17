-- Axiomir UI Library test
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
        Size = opt.Size or UDim2.fromOffset(700, 450),
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

-- Tab Column Section
function Window:AddTab(name)
    local Tab = { Columns = {} }

    local btn = create("TextButton", {
        Parent = self.TabBar,
        Size = UDim2.fromOffset(100,30),
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
        list.Padding = UDim.new(0,6)

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

            local layout = Instance.new("UIListLayout",body)
            layout.Padding = UDim.new(0,4)

            --==============================
            -- Elements
            --==============================

            function sec:AddToggle(text,opt)
                opt=opt or {}
                local flag=opt.Flag or text
                local data=registerFlag(flag,opt.Default or false,true)

                local b=create("TextButton",{
                    Parent=body,
                    Size=UDim2.new(1,-10,0,24),
                    BackgroundColor3=Color3.fromRGB(45,45,45),
                    Text=text,
                    Font=Enum.Font.Gotham,
                    TextSize=12,
                    TextColor3=Color3.new(1,1,1)
                })

                local function update(v)
                    b.BackgroundColor3 = v and Color3.fromRGB(90,120,255) or Color3.fromRGB(45,45,45)
                end

                data.Update = update
                update(data.Value)

                b.MouseButton1Click:Connect(function()
                    data.Value = not data.Value
                    update(data.Value)
                    Dirty=true
                    if opt.Callback then opt.Callback(data.Value) end
                end)
            end

            function sec:AddSlider(text,opt)
                opt=opt or {}
                local flag=opt.Flag or text
                local data=registerFlag(flag,opt.Default or opt.Min,true)

                local holder=create("Frame",{Parent=body,Size=UDim2.new(1,-10,0,38),BackgroundTransparency=1})
                create("TextLabel",{Parent=holder,Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text=text,Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.new(1,1,1)})

                local bar=create("Frame",{Parent=holder,Position=UDim2.fromOffset(0,20),Size=UDim2.new(1,0,0,6),BackgroundColor3=Color3.fromRGB(50,50,50)})
                local fill=create("Frame",{Parent=bar,Size=UDim2.new(0,0,1,0),BackgroundColor3=Color3.fromRGB(90,120,255)})

                local function set(v)
                    v=math.clamp(v,opt.Min,opt.Max)
                    data.Value=v
                    fill.Size=UDim2.new((v-opt.Min)/(opt.Max-opt.Min),0,1,0)
                    Dirty=true
                    if opt.Callback then opt.Callback(v) end
                end

                data.Update=set
                set(data.Value)

                bar.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        local move,up
                        move=RunService.RenderStepped:Connect(function()
                            local x=(UserInputService:GetMouseLocation().X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X
                            set(opt.Min+x*(opt.Max-opt.Min))
                        end)
                        up=UserInputService.InputEnded:Connect(function(e)
                            if e.UserInputType==Enum.UserInputType.MouseButton1 then
                                move:Disconnect()
                                up:Disconnect()
                            end
                        end)
                    end
                end)
            end

            function sec:AddDropdown(text,opt)
                opt=opt or {}
                local flag=opt.Flag or text
                local data=registerFlag(flag,opt.Default,true)

                local b=create("TextButton",{Parent=body,Size=UDim2.new(1,-10,0,24),BackgroundColor3=Color3.fromRGB(45,45,45),Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.new(1,1,1)})

                local function update(v)
                    b.Text=text..": "..tostring(v)
                end

                data.Update=update
                update(data.Value)

                b.MouseButton1Click:Connect(function()
                    local i=table.find(opt.Options,data.Value) or 0
                    i=i%#opt.Options+1
                    data.Value=opt.Options[i]
                    update(data.Value)
                    Dirty=true
                    if opt.Callback then opt.Callback(data.Value) end
                end)
            end

            function sec:AddButton(text,opt)
                opt=opt or {}
                local b=create("TextButton",{Parent=body,Size=UDim2.new(1,-10,0,24),BackgroundColor3=Color3.fromRGB(60,60,60),Text=text,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1)})
                b.MouseButton1Click:Connect(function()
                    if opt.Callback then opt.Callback() end
                end)
            end

            function sec:AddLabel(text)
                create("TextLabel",{Parent=body,Size=UDim2.new(1,-10,0,20),BackgroundTransparency=1,Text=text,Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.new(1,1,1),TextWrapped=true})
            end

            function sec:AddParagraph(title,text)
                sec:AddLabel(title)
                sec:AddLabel(text)
            end

            function sec:AddStats(title)
                local stats={}
                local holder=create("Frame",{Parent=body,Size=UDim2.new(1,-10,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1})
                local l=Instance.new("UIListLayout",holder)

                function stats:Set(name,value)
                    create("TextLabel",{Parent=holder,Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=name..": "..value,Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.new(1,1,1)})
                end

                return stats
            end

            if callback then callback(sec) end
        end

        return col
    end

    btn.MouseButton1Click:Connect(function()
        for _,t in pairs(self.Tabs) do t.Page.Visible=false end
        page.Visible=true
    end)

    Tab.Page=page
    table.insert(self.Tabs,Tab)
    if #self.Tabs==1 then page.Visible=true end
    return Tab
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
