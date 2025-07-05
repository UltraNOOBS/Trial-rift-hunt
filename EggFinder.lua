-- Advanced Egg Hatcher with Multi-Select and Persistent Config
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local VirtualInput = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Config system
local config = {
    selectedEggs = {},
    lastPosition = {x = 0.5, y = 0.5}
}

-- Try to load saved config
pcall(function()
    if readfile and writefile then
        if isfile("EggHatcherConfig.json") then
            config = HttpService:JSONDecode(readfile("EggHatcherConfig.json"))
        end
    end
end)

local function saveConfig()
    pcall(function()
        if writefile then
            writefile("EggHatcherConfig.json", HttpService:JSONEncode(config))
        end
    end)
end

-- Create the main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggHatcherGUI_"..HttpService:GenerateGUID(false)
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 350, 0, 300)
Frame.Position = UDim2.new(config.lastPosition.x, -175, config.lastPosition.y, -150)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "Auto Egg Hatcher"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local Toggle = Instance.new("TextButton")
Toggle.Text = "START"
Toggle.Size = UDim2.new(0.9, 0, 0, 30)
Toggle.Position = UDim2.new(0.05, 0, 0.15, 0)
Toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.Font = Enum.Font.Gotham
Toggle.Parent = Frame

local Dropdown = Instance.new("Frame")
Dropdown.Size = UDim2.new(0.9, 0, 0, 30)
Dropdown.Position = UDim2.new(0.05, 0, 0.3, 0)
Dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Dropdown.Parent = Frame

local DropdownText = Instance.new("TextLabel")
DropdownText.Text = "Select Eggs ("..#config.selectedEggs.." selected)"
DropdownText.Size = UDim2.new(0.8, 0, 1, 0)
DropdownText.BackgroundTransparency = 1
DropdownText.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownText.Font = Enum.Font.Gotham
DropdownText.TextXAlignment = Enum.TextXAlignment.Left
DropdownText.Parent = Dropdown

local DropdownButton = Instance.new("TextButton")
DropdownButton.Text = "▼"
DropdownButton.Size = UDim2.new(0.2, 0, 1, 0)
DropdownButton.Position = UDim2.new(0.8, 0, 0, 0)
DropdownButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownButton.Font = Enum.Font.Gotham
DropdownButton.Parent = Dropdown

local DropdownOptions = Instance.new("ScrollingFrame")
DropdownOptions.Size = UDim2.new(0.9, 0, 0, 150)
DropdownOptions.Position = UDim2.new(0.05, 0, 0.45, 0)
DropdownOptions.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DropdownOptions.Visible = false
DropdownOptions.Parent = Frame

local SelectAllButton = Instance.new("TextButton")
SelectAllButton.Text = "Toggle All"
SelectAllButton.Size = UDim2.new(0.9, 0, 0, 25)
SelectAllButton.Position = UDim2.new(0.05, 0, 0.4, 0)
SelectAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SelectAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectAllButton.Font = Enum.Font.Gotham
SelectAllButton.Visible = false
SelectAllButton.Parent = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = "Status: Ready"
StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
StatusLabel.Position = UDim2.new(0.05, 0, 0.85, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

local RescanButton = Instance.new("TextButton")
RescanButton.Text = "Rescan Eggs"
RescanButton.Size = UDim2.new(0.9, 0, 0, 25)
RescanButton.Position = UDim2.new(0.05, 0, 0.9, 0)
RescanButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
RescanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RescanButton.Font = Enum.Font.Gotham
RescanButton.Parent = Frame

-- Function to find ALL possible eggs in the game's structure
local allPossibleEggs = {}
local function findAllPossibleEggs()
    local eggTypes = {}
    
    -- Check various locations for egg definitions
    local locationsToCheck = {
        game:GetService("Workspace"),
        game:GetService("ReplicatedStorage"),
        game:GetService("ServerStorage")
    }
    
    for _, location in pairs(locationsToCheck) do
        pcall(function()
            if location:FindFirstChild("Eggs") then
                for _, egg in pairs(location.Eggs:GetChildren()) do
                    eggTypes[egg.Name] = true
                end
            end
            if location:FindFirstChild("Rifts") then
                for _, egg in pairs(location.Rifts:GetChildren()) do
                    if egg.Name:match("%-egg$") then
                        eggTypes[egg.Name] = true
                    end
                end
            end
        end)
    end
    
    -- Convert to sorted array
    local sortedEggs = {}
    for eggName in pairs(eggTypes) do
        table.insert(sortedEggs, eggName)
    end
    table.sort(sortedEggs)
    
    allPossibleEggs = sortedEggs
    return sortedEggs
end

-- Modified populateDropdown function with checkboxes
local function populateDropdown()
    for _, option in pairs(DropdownOptions:GetChildren()) do
        if option:IsA("Frame") then
            option:Destroy()
        end
    end
    
    local eggs = findAllPossibleEggs()
    
    if #eggs == 0 then
        local noEggsFrame = Instance.new("Frame")
        noEggsFrame.Size = UDim2.new(1, 0, 0, 25)
        noEggsFrame.BackgroundTransparency = 1
        noEggsFrame.Parent = DropdownOptions
        
        local noEggsLabel = Instance.new("TextLabel")
        noEggsLabel.Text = "No egg types found!"
        noEggsLabel.Size = UDim2.new(1, 0, 1, 0)
        noEggsLabel.BackgroundTransparency = 1
        noEggsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        noEggsLabel.Font = Enum.Font.Gotham
        noEggsLabel.Parent = noEggsFrame
        return
    end
    
    for i, egg in pairs(eggs) do
        local optionFrame = Instance.new("Frame")
        optionFrame.Size = UDim2.new(1, 0, 0, 25)
        optionFrame.Position = UDim2.new(0, 0, 0, (i-1)*25)
        optionFrame.BackgroundTransparency = 1
        optionFrame.Parent = DropdownOptions
        
        local checkbox = Instance.new("TextButton")
        checkbox.Text = config.selectedEggs[egg] and "✓" or ""
        checkbox.Size = UDim2.new(0, 25, 0, 25)
        checkbox.Position = UDim2.new(0, 0, 0, 0)
        checkbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        checkbox.TextColor3 = Color3.fromRGB(0, 255, 0)
        checkbox.Font = Enum.Font.GothamBold
        checkbox.Parent = optionFrame
        
        local eggLabel = Instance.new("TextLabel")
        eggLabel.Text = egg
        eggLabel.Size = UDim2.new(1, -30, 1, 0)
        eggLabel.Position = UDim2.new(0, 30, 0, 0)
        eggLabel.BackgroundTransparency = 1
        eggLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        eggLabel.Font = Enum.Font.Gotham
        eggLabel.TextXAlignment = Enum.TextXAlignment.Left
        eggLabel.Parent = optionFrame
        
        checkbox.MouseButton1Click:Connect(function()
            config.selectedEggs[egg] = not config.selectedEggs[egg]
            checkbox.Text = config.selectedEggs[egg] and "✓" or ""
            DropdownText.Text = "Select Eggs ("..table.count(config.selectedEggs).." selected)"
            saveConfig()
        end)
        
        eggLabel.MouseButton1Click:function()
            config.selectedEggs[egg] = not config.selectedEggs[egg]
            checkbox.Text = config.selectedEggs[egg] and "✓" or ""
            DropdownText.Text = "Select Eggs ("..table.count(config.selectedEggs).." selected)"
            saveConfig()
        end
    end
end

-- Toggle all eggs
SelectAllButton.MouseButton1Click:Connect(function()
    local anySelected = next(config.selectedEggs) ~= nil
    for _, egg in pairs(allPossibleEggs) do
        config.selectedEggs[egg] = not anySelected
    end
    populateDropdown()
    DropdownText.Text = "Select Eggs ("..table.count(config.selectedEggs).." selected)"
    saveConfig()
end)

DropdownButton.MouseButton1Click:Connect(function()
    DropdownOptions.Visible = not DropdownOptions.Visible
    SelectAllButton.Visible = DropdownOptions.Visible
    if DropdownOptions.Visible then
        populateDropdown()
    end
end)

RescanButton.MouseButton1Click:Connect(function()
    findAllPossibleEggs()
    populateDropdown()
    StatusLabel.Text = "Status: Rescanned ("..#allPossibleEggs.." egg types)"
end)

-- Main functionality
local running = false
Toggle.MouseButton1Click:Connect(function()
    running = not running
    if running then
        if table.count(config.selectedEggs) == 0 then
            StatusLabel.Text = "Status: Please select at least one egg"
            running = false
            return
        end
        Toggle.Text = "STOP"
        Toggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        StatusLabel.Text = "Status: Running ("..table.count(config.selectedEggs).." selected)"
    else
        Toggle.Text = "START"
        Toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        StatusLabel.Text = "Status: Stopped"
    end
end)

local function findSelectedEgg()
    local riftsFolder = game:GetService("Workspace"):FindFirstChild("Rendered")
    if riftsFolder then
        local rifts = riftsFolder:FindFirstChild("Rifts")
        if rifts then
            for eggName in pairs(config.selectedEggs) do
                local egg = rifts:FindFirstChild(eggName)
                if egg then
                    return egg
                end
            end
        end
    end
    return nil
end

local function teleportToEgg(egg)
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    local eggPosition = egg:GetPivot().Position
    HumanoidRootPart.CFrame = CFrame.new(eggPosition + Vector3.new(0, 3, 0))
end

local function spamR()
    for i = 1, 20 do
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        task.wait(0.05)
    end
end

local function rejoin()
    StatusLabel.Text = "Status: Rejoining..."
    TeleportService:Teleport(game.PlaceId)
end

coroutine.wrap(function()
    while true do
        if running then
            local egg = findSelectedEgg()
            
            if egg then
                StatusLabel.Text = "Status: Found "..egg.Name
                teleportToEgg(egg)
                spamR()
                task.wait(3)
            else
                StatusLabel.Text = "Status: No selected eggs found, rejoining..."
                task.wait(5)
                rejoin()
            end
        end
        task.wait()
    end
end)()

-- Make the GUI draggable and save position
local dragging
local dragInput
local dragStart
local startPos

local function updatePosition()
    local pos = Frame.AbsolutePosition
    local size = Frame.AbsoluteSize
    config.lastPosition = {
        x = pos.X/size.X + 0.5,
        y = pos.Y/size.Y + 0.5
    }
    saveConfig()
end

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                updatePosition()
            end
        end)
    end
end)

Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Initial setup
coroutine.wrap(function()
    task.wait(2)
    findAllPossibleEggs()
    populateDropdown()
    StatusLabel.Text = "Status: Ready ("..#allPossibleEggs.." egg types)"
end)()
