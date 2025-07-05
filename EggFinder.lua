-- Bubble Gum Simulator Infinity - Precision Rift Egg Hatcher
local EggHatcher = {}

function EggHatcher.new()
    local self = setmetatable({}, {__index = EggHatcher})
    
    -- Services
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer
    self.TeleportService = game:GetService("TeleportService")
    self.VirtualInput = game:GetService("VirtualInputManager")
    self.CoreGui = game:GetService("CoreGui")

    -- Config
    self.config = {
        selectedEggs = {},
        lastPosition = {x = 0.5, y = 0.5},
        serverHopDelay = 15, -- Faster server hopping
        riftPrefix = "-egg"
    }

    -- UI Setup
    self:createGUI()
    self:scanRifts()
    return self
end

-- Finds all rift eggs ending with "-egg"
function EggHatcher:scanRifts()
    local riftsFolder = game:GetService("Workspace"):FindFirstChild("Rendered")
    if not riftsFolder then return {} end
    riftsFolder = riftsFolder:FindFirstChild("Rifts")
    if not riftsFolder then return {} end

    local riftEggs = {}
    for _, egg in pairs(riftsFolder:GetChildren()) do
        if egg.Name:match(self.config.riftPrefix .. "$") then
            table.insert(riftEggs, egg.Name)
        end
    end
    table.sort(riftEggs)
    self.allPossibleEggs = riftEggs
    return riftEggs
end

-- Teleports DIRECTLY onto the egg
function EggHatcher:teleportToEgg(egg)
    local Character = self.LocalPlayer.Character
    if not Character then return end
    
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end
    
    -- Position directly on top of the egg
    local eggPosition = egg:GetPivot().Position
    HumanoidRootPart.CFrame = CFrame.new(eggPosition + Vector3.new(0, 0.5, 0)) -- 0.5 studs above
end

-- Spams R with perfect timing
function EggHatcher:spamR()
    for i = 1, 15 do -- More efficient spamming
        self.VirtualInput:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.03)
        self.VirtualInput:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        task.wait(0.07)
    end
end

-- Main loop with precision positioning
function EggHatcher:startHatching()
    while self.running do
        local egg = self:findSelectedEgg()
        if egg then
            self:teleportToEgg(egg) -- Directly on egg
            self:spamR()
            task.wait(0.5) -- Shorter delay between hatches
        else
            task.wait(self.config.serverHopDelay)
            self.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
            break
        end
    end
end

-- [Include your existing UI code here]
-- Initialize and run:
local hatcher = EggHatcher.new()
hatcher:startHatching()
