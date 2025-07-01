-- CONFIGURATION
local PLACE_ID = 2512643572

-- SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- STATE FLAGS
local autoHop = false
local autoFly = false
local autoHatch = false
local targetEggName = "Bruh Egg"

-- UI SETUP
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "BruhEggUI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 260, 0, 320)
frame.Position = UDim2.new(0, 10, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Egg Finder & Auto Hatch"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20

-- Toggles helper
local function createToggle(name, posY, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Name = name
    btn.Size = UDim2.new(0, 180, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = name .. ": OFF"
    btn.TextSize = 18
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false

    local toggled = false
    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        btn.Text = name .. ": " .. (toggled and "ON" or "OFF")
        btn.BackgroundColor3 = toggled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(30, 30, 30)
        callback(toggled)
    end)
    return btn
end

local autoHopBtn = createToggle("Auto Hop", 40, function(state) autoHop = state end)
local autoFlyBtn = createToggle("Auto Fly", 80, function(state) autoFly = state end)
local autoHatchBtn = createToggle("Auto Hatch", 120, function(state) autoHatch = state end)

-- Search Bar
local searchBox = Instance.new("TextBox", frame)
searchBox.Size = UDim2.new(0, 180, 0, 30)
searchBox.Position = UDim2.new(0, 10, 0, 160)
searchBox.PlaceholderText = "Search egg name..."
searchBox.ClearTextOnFocus = false
searchBox.Text = targetEggName
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 18
searchBox.BorderSizePixel = 0

-- Scroll frame for scanned eggs
local scrollFrame = Instance.new("ScrollingFrame", frame)
scrollFrame.Size = UDim2.new(0, 240, 0, 100)
scrollFrame.Position = UDim2.new(0, 10, 0, 200)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 6
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
scrollFrame.BorderSizePixel = 0
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local uiListLayout = Instance.new("UIListLayout", scrollFrame)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 4)

local scannedEggs = {}

local function clearScrollFrame()
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function addEggToList(eggName)
    local label = Instance.new("TextButton", scrollFrame)
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.Text = eggName
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BorderSizePixel = 0
    label.AutoButtonColor = true

    label.MouseButton1Click:Connect(function()
        targetEggName = eggName
        searchBox.Text = eggName
        print("Selected egg:", eggName)
    end)
end

local function scanEggs()
    scannedEggs = {}
    clearScrollFrame()

    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name:lower():find("egg") then
            if not table.find(scannedEggs, obj.Name) then
                table.insert(scannedEggs, obj.Name)
            end
        end
    end

    table.sort(scannedEggs)

    for _, eggName in ipairs(scannedEggs) do
        addEggToList(eggName)
    end

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #scannedEggs * 28)
end

searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and searchBox.Text ~= "" then
        targetEggName = searchBox.Text
        print("Target egg updated to:", targetEggName)
    end
end)

-- Immediately scan eggs when script loads
scanEggs()

-- LOGIC FUNCTIONS
local function findEggByName(name)
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name:lower() == name:lower() then
            return obj
        end
    end
    return nil
end

local function tweenTo(targetPos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local distance = (hrp.Position - targetPos).Magnitude
    local time = math.clamp(distance / 40, 1, 5)

    local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Sine), {
        CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    })
    tween:Play()
    tween.Completed:Wait()
end

local function pressE()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function getServerList()
    local servers = {}
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=2&limit=100"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    return servers
end

-- MAIN LOOP
task.spawn(function()
    while true do
        wait(1)
        local egg = findEggByName(targetEggName)

        if egg then
            if autoFly then
                local pos
                if egg:IsA("Model") and egg.PrimaryPart then
                    pos = egg.PrimaryPart.Position
                elseif egg:IsA("Part") then
                    pos = egg.Position
                else
                    if egg:IsA("Model") then
                        pos = egg:GetModelCFrame().Position
                    else
                        pos = nil
                    end
                end

                if pos then
                    tweenTo(pos)
                end
            end

            if autoHatch then
                task.spawn(function()
                    while autoHatch and findEggByName(targetEggName) do
                        pressE()
                        wait(0.15)
                    end
                end)
            end
        elseif autoHop then
            warn("Egg '"..targetEggName.."' not found. Hopping...")
            wait(2)
            local servers = getServerList()
            if #servers > 0 then
                TeleportService:TeleportToPlaceInstance(PLACE_ID, servers[1], LocalPlayer)
                break
            end
        end
    end
end)
