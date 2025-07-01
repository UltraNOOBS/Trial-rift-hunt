-- CONFIGURATION
local PLACE_ID = 85896571713843

-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- FLAGS
local autoHop = false
local autoHatch = false
local targetRiftName = nil
local foundRifts = {}

-- UI SETUP
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "BruhGodUI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 240, 0, 160)
frame.Position = UDim2.new(0, 10, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.1
frame.ClipsDescendants = true
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "💀 Bruh God"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20

local function createToggle(name, yPos, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 220, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.Text = name .. ": OFF"
    btn.TextSize = 16
    btn.BorderSizePixel = 0

    local toggled = false
    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        btn.Text = name .. ": " .. (toggled and "ON" or "OFF")
        btn.BackgroundColor3 = toggled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(35, 35, 35)
        callback(toggled)
    end)

    return btn
end

local function createDropdown(yPos, items, onSelect)
    local dropdown = Instance.new("TextButton", frame)
    dropdown.Size = UDim2.new(0, 220, 0, 28)
    dropdown.Position = UDim2.new(0, 10, 0, yPos)
    dropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.Font = Enum.Font.Gotham
    dropdown.TextSize = 15
    dropdown.Text = "Select Egg Rift"
    dropdown.BorderSizePixel = 0

    local menu = Instance.new("Frame", dropdown)
    menu.Position = UDim2.new(0, 0, 1, 0)
    menu.Size = UDim2.new(1, 0, 0, 0)
    menu.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    menu.Visible = false
    menu.ClipsDescendants = true

    local layout = Instance.new("UIListLayout", menu)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)

    dropdown.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
        menu.Size = UDim2.new(1, 0, 0, #items * 26)
    end)

    for _, name in ipairs(items) do
        local opt = Instance.new("TextButton", menu)
        opt.Size = UDim2.new(1, 0, 0, 24)
        opt.Text = name
        opt.Font = Enum.Font.Gotham
        opt.TextColor3 = Color3.fromRGB(220, 220, 220)
        opt.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        opt.TextSize = 14
        opt.BorderSizePixel = 0

        opt.MouseButton1Click:Connect(function()
            targetRiftName = name
            dropdown.Text = "Target: " .. name
            menu.Visible = false
            onSelect(name)
        end)
    end

    return dropdown
end

local hopToggle = createToggle("Auto Hop", 35, function(state)
    autoHop = state
end)

local hatchToggle = createToggle("Auto Hatch (R)", 70, function(state)
    autoHatch = state
end)

local dropdown -- defined later after scanning

-- EGG RIFT SCANNER
local function findEggRifts()
    foundRifts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        local lowerName = obj.Name:lower()
        if (obj:IsA("Model") or obj:IsA("Part")) and lowerName:find("rift") and lowerName:find("egg") then
            if not table.find(foundRifts, obj.Name) then
                table.insert(foundRifts, obj.Name)
            end
        end
    end
    return foundRifts
end

-- TELEPORT
local function tweenTo(pos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local dist = (root.Position - pos).Magnitude
    local tween = TweenService:Create(root, TweenInfo.new(math.clamp(dist / 40, 0.5, 5), Enum.EasingStyle.Sine), {
        CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    })
    tween:Play()
    tween.Completed:Wait()
end

-- PRESS "R"
local function pressR()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
end

-- MAIN LOOP
task.spawn(function()
    local rifts = findEggRifts()
    dropdown = createDropdown(105, rifts, function() end)

    while true do
        task.wait(1)
        if targetRiftName then
            local rift
            for _, obj in pairs(workspace:GetDescendants()) do
                if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name == targetRiftName then
                    rift = obj
                    break
                end
            end

            if rift then
                local pos = rift:IsA("Model") and rift:GetModelCFrame().Position or rift.Position
                tweenTo(pos)

                if autoHatch then
                    task.spawn(function()
                        while autoHatch and rift and rift.Parent do
                            pressR()
                            task.wait(0.15)
                        end
                    end)
                end
            elseif autoHop then
                warn("Target Rift not found. Hopping...")
                task.wait(2)
                TeleportService:Teleport(PLACE_ID, LocalPlayer)
                break
            end
        end
    end
end)
