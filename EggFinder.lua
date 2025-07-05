-- Advanced Egg Hatcher with Multi-Select and Persistent Config
-- GitHub Loadstring Compatible Version
-- Paste this content in a GitHub gist or raw file

local EggHatcher = {}

function EggHatcher.new()
    local self = setmetatable({}, {__index = EggHatcher})
    
    -- Services
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer
    self.TeleportService = game:GetService("TeleportService")
    self.VirtualInput = game:GetService("VirtualInputManager")
    self.CoreGui = game:GetService("CoreGui")
    self.HttpService = game:GetService("HttpService")
    self.UserInputService = game:GetService("UserInputService")

    -- Config system
    self.config = {
        selectedEggs = {},
        lastPosition = {x = 0.5, y = 0.5}
    }

    -- UI References
    self.ScreenGui = nil
    self.running = false
    self.allPossibleEggs = {}

    -- Initialize
    self:loadConfig()
    self:createGUI()
    self:findAllPossibleEggs()
    self:populateDropdown()

    return self
end

function EggHatcher:loadConfig()
    pcall(function()
        if readfile and writefile then
            if isfile("EggHatcherConfig.json") then
                self.config = self.HttpService:JSONDecode(readfile("EggHatcherConfig.json"))
            end
        end
    end)
end

function EggHatcher:saveConfig()
    pcall(function()
        if writefile then
            writefile("EggHatcherConfig.json", self.HttpService:JSONEncode(self.config))
        end
    end)
end

function EggHatcher:createGUI()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "EggHatcherGUI_"..self.HttpService:GenerateGUID(false)
    self.ScreenGui.Parent = self.CoreGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 350, 0, 300)
    Frame.Position = UDim2.new(self.config.lastPosition.x, -175, self.config.lastPosition.y, -150)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BorderSizePixel = 0
    Frame.Parent = self.ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Text = "Auto Egg Hatcher"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Frame

    self.Toggle = Instance.new("TextButton")
    self.Toggle.Text = "START"
    self.Toggle.Size = UDim2.new(0.9, 0, 0, 30)
    self.Toggle.Position = UDim2.new(0.05, 0, 0.15, 0)
    self.Toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    self.Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.Toggle.Font = Enum.Font.Gotham
    self.Toggle.Parent = Frame

    local Dropdown = Instance.new("Frame")
    Dropdown.Size = UDim2.new(0.9, 0, 0, 30)
    Dropdown.Position = UDim2.new(0.05, 0, 0.3, 0)
    Dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Dropdown.Parent = Frame

    self.DropdownText = Instance.new("TextLabel")
    self.DropdownText.Text = "Select Eggs ("..self:countSelectedEggs().." selected)"
    self.DropdownText.Size = UDim2.new(0.8, 0, 1, 0)
    self.DropdownText.BackgroundTransparency = 1
    self.DropdownText.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.DropdownText.Font = Enum.Font.Gotham
    self.DropdownText.TextXAlignment = Enum.TextXAlignment.Left
    self.DropdownText.Parent = Dropdown

    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Text = "▼"
    DropdownButton.Size = UDim2.new(0.2, 0, 1, 0)
    DropdownButton.Position = UDim2.new(0.8, 0, 0, 0)
    DropdownButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    DropdownButton.Font = Enum.Font.Gotham
    DropdownButton.Parent = Dropdown

    self.DropdownOptions = Instance.new("ScrollingFrame")
    self.DropdownOptions.Size = UDim2.new(0.9, 0, 0, 150)
    self.DropdownOptions.Position = UDim2.new(0.05, 0, 0.45, 0)
    self.DropdownOptions.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    self.DropdownOptions.Visible = false
    self.DropdownOptions.Parent = Frame

    self.SelectAllButton = Instance.new("TextButton")
    self.SelectAllButton.Text = "Toggle All"
    self.SelectAllButton.Size = UDim2.new(0.9, 0, 0, 25)
    self.SelectAllButton.Position = UDim2.new(0.05, 0, 0.4, 0)
    self.SelectAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    self.SelectAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.SelectAllButton.Font = Enum.Font.Gotham
    self.SelectAllButton.Visible = false
    self.SelectAllButton.Parent = Frame

    self.StatusLabel = Instance.new("TextLabel")
    self.StatusLabel.Text = "Status: Ready"
    self.StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
    self.StatusLabel.Position = UDim2.new(0.05, 0, 0.85, 0)
    self.StatusLabel.BackgroundTransparency = 1
    self.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.StatusLabel.Font = Enum.Font.Gotham
    self.StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.StatusLabel.Parent = Frame

    self.RescanButton = Instance.new("TextButton")
    self.RescanButton.Text = "Rescan Eggs"
    self.RescanButton.Size = UDim2.new(0.9, 0, 0, 25)
    self.RescanButton.Position = UDim2.new(0.05, 0, 0.9, 0)
    self.RescanButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    self.RescanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.RescanButton.Font = Enum.Font.Gotham
    self.RescanButton.Parent = Frame

    -- Connect events
    self.Toggle.MouseButton1Click:Connect(function()
        self:toggleScript()
    end)

    DropdownButton.MouseButton1Click:Connect(function()
        self.DropdownOptions.Visible = not self.DropdownOptions.Visible
        self.SelectAllButton.Visible = self.DropdownOptions.Visible
        if self.DropdownOptions.Visible then
            self:populateDropdown()
        end
    end)

    self.SelectAllButton.MouseButton1Click:Connect(function()
        self:toggleAllEggs()
    end)

    self.RescanButton.MouseButton1Click:Connect(function()
        self:findAllPossibleEggs()
        self:populateDropdown()
        self.StatusLabel.Text = "Status: Rescanned ("..#self.allPossibleEggs.." egg types)"
    end)

    -- Make draggable
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function updatePosition()
        local pos = Frame.AbsolutePosition
        local size = Frame.AbsoluteSize
        self.config.lastPosition = {
            x = pos.X/size.X + 0.5,
            y = pos.Y/size.Y + 0.5
        }
        self:saveConfig()
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

    self.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function EggHatcher:countSelectedEggs()
    local count = 0
    for _ in pairs(self.config.selectedEggs) do
        count = count + 1
    end
    return count
end

function EggHatcher:findAllPossibleEggs()
    local eggTypes = {}
    
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
    
    local sortedEggs = {}
    for eggName in pairs(eggTypes) do
        table.insert(sortedEggs, eggName)
    end
    table.sort(sortedEggs)
    
    self.allPossibleEggs = sortedEggs
    return sortedEggs
end

function EggHatcher:populateDropdown()
    for _, option in pairs(self.DropdownOptions:GetChildren()) do
        if option:IsA("Frame") then
            option:Destroy()
        end
    end
    
    if #self.allPossibleEggs == 0 then
        local noEggsFrame = Instance.new("Frame")
        noEggsFrame.Size = UDim2.new(1, 0, 0, 25)
        noEggsFrame.BackgroundTransparency = 1
        noEggsFrame.Parent = self.DropdownOptions
        
        local noEggsLabel = Instance.new("TextLabel")
        noEggsLabel.Text = "No egg types found!"
        noEggsLabel.Size = UDim2.new(1, 0, 1, 0)
        noEggsLabel.BackgroundTransparency = 1
        noEggsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        noEggsLabel.Font = Enum.Font.Gotham
        noEggsLabel.Parent = noEggsFrame
        return
    end
    
    for i, egg in pairs(self.allPossibleEggs) do
        local optionFrame = Instance.new("Frame")
        optionFrame.Size = UDim2.new(1, 0, 0, 25)
        optionFrame.Position = UDim2.new(0, 0, 0, (i-1)*25)
        optionFrame.BackgroundTransparency = 1
        optionFrame.Parent = self.DropdownOptions
        
        local checkbox = Instance.new("TextButton")
        checkbox.Text = self.config.selectedEggs[egg] and "✓" or ""
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
            self.config.selectedEggs[egg] = not self.config.selectedEggs[egg]
            checkbox.Text = self.config.selectedEggs[egg] and "✓" or ""
            self.DropdownText.Text = "Select Eggs ("..self:countSelectedEggs().." selected)"
            self:saveConfig()
        end)
        
        eggLabel.MouseButton1Click:Connect(function()
            self.config.selectedEggs[egg] = not self.config.selectedEggs[egg]
            checkbox.Text = self.config.selectedEggs[egg] and "✓" or ""
            self.DropdownText.Text = "Select Eggs ("..self:countSelectedEggs().." selected)"
            self:saveConfig()
        end)
    end
end

function EggHatcher:toggleAllEggs()
    local anySelected = next(self.config.selectedEggs) ~= nil
    for _, egg in pairs(self.allPossibleEggs) do
        self.config.selectedEggs[egg] = not anySelected
    end
    self:populateDropdown()
    self.DropdownText.Text = "Select Eggs ("..self:countSelectedEggs().." selected)"
    self:saveConfig()
end

function EggHatcher:toggleScript()
    self.running = not self.running
    if self.running then
        if self:countSelectedEggs() == 0 then
            self.StatusLabel.Text = "Status: Please select at least one egg"
            self.running = false
            return
        end
        self.Toggle.Text = "STOP"
        self.Toggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        self.StatusLabel.Text = "Status: Running ("..self:countSelectedEggs().." selected)"
        self:startHatching()
    else
        self.Toggle.Text = "START"
        self.Toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        self.StatusLabel.Text = "Status: Stopped"
    end
end

function EggHatcher:findSelectedEgg()
    local riftsFolder = game:GetService("Workspace"):FindFirstChild("Rendered")
    if riftsFolder then
        local rifts = riftsFolder:FindFirstChild("Rifts")
        if rifts then
            for eggName in pairs(self.config.selectedEggs) do
                local egg = rifts:FindFirstChild(eggName)
                if egg then
                    return egg
                end
            end
        end
    end
    return nil
end

function EggHatcher:teleportToEgg(egg)
    local Character = self.LocalPlayer.Character or self.LocalPlayer.CharacterAdded:Wait()
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    local eggPosition = egg:GetPivot().Position
    HumanoidRootPart.CFrame = CFrame.new(eggPosition + Vector3.new(0, 3, 0))
end

function EggHatcher:spamR()
    for i = 1, 20 do
        self.VirtualInput:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        self.VirtualInput:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        task.wait(0.05)
    end
end

function EggHatcher:rejoin()
    self.StatusLabel.Text = "Status: Rejoining..."
    self.TeleportService:Teleport(game.PlaceId)
end

function EggHatcher:startHatching()
    coroutine.wrap(function()
        while self.running do
            local egg = self:findSelectedEgg()
            
            if egg then
                self.StatusLabel.Text = "Status: Found "..egg.Name
                self:teleportToEgg(egg)
                self:spamR()
                task.wait(3)
            else
                self.StatusLabel.Text = "Status: No selected eggs found, rejoining..."
                task.wait(5)
                self:rejoin()
            end
            task.wait()
        end
    end)()
end

-- Initialize the script
local hatcher = EggHatcher.new()

return EggHatcher
