-- Fixed Bubble Gum Simulator Infinity Rift Egg Hatcher
local EggHatcher = {}

function EggHatcher.new()
    local self = setmetatable({}, {__index = EggHatcher})
    
    -- Services
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer or self.Players:GetPropertyChangedSignal("Character"):Wait()
    self.TeleportService = game:GetService("TeleportService")
    self.VirtualInput = game:GetService("VirtualInputManager")
    self.CoreGui = game:GetService("CoreGui")

    -- Config
    self.config = {
        selectedEggs = {},
        lastPosition = {x = 0.5, y = 0.5},
        serverHopDelay = 15,
        riftPrefix = "-egg"
    }

    -- State
    self.running = false
    self.allPossibleEggs = {}

    -- Initialize
    self:setupGUI() -- Renamed from createGUI to avoid errors
    self:scanRifts()
    return self
end

-- Fixed GUI setup (renamed from createGUI)
function EggHatcher:setupGUI()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "RiftEggHatcher_"..tostring(math.random(10000,99999))
    self.ScreenGui.Parent = self.CoreGui

    -- [Add your existing UI elements here but ensure:]
    -- 1. All variables are properly declared
    -- 2. No nil references
    -- 3. Proper parent-child relationships
end

-- Error-protected rift scanning
function EggHatcher:scanRifts()
    local success, err = pcall(function()
        self.allPossibleEggs = {}
        local rifts = game:GetService("Workspace"):FindFirstChild("Rendered")
        if not rifts then return end
        rifts = rifts:FindFirstChild("Rifts")
        if not rifts then return end

        for _, egg in pairs(rifts:GetChildren()) do
            if egg.Name:match(self.config.riftPrefix.."$") then
                table.insert(self.allPossibleEggs, egg.Name)
            end
        end
        table.sort(self.allPossibleEggs)
    end)
    
    if not success then
        warn("Rift scan failed:", err)
        return {}
    end
    return self.allPossibleEggs
end

-- Safe teleport function
function EggHatcher:teleportToEgg(egg)
    local success, err = pcall(function()
        local character = self.LocalPlayer.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        humanoidRootPart.CFrame = CFrame.new(egg.Position + Vector3.new(0, 0.5, 0))
    end)
    
    if not success then
        warn("Teleport failed:", err)
    end
end

-- Main loop with error handling
function EggHatcher:startHatching()
    while self.running do
        local success, err = pcall(function()
            local egg = self:findSelectedEgg()
            if egg then
                self:teleportToEgg(egg)
                self:spamR()
                task.wait(0.5)
            else
                task.wait(self.config.serverHopDelay)
                self.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
            end
        end)
        
        if not success then
            warn("Hatching error:", err)
            task.wait(1)
        end
    end
end

-- Initialize with error protection
local success, err = pcall(function()
    local hatcher = EggHatcher.new()
    hatcher:startHatching()
end)

if not success then
    warn("Initialization failed:", err)
end
