return function()
    -- Fix for table.count if missing
    if not table.count then
        function table.count(t)
            local count = 0
            for _ in pairs(t) do count += 1 end
            return count
        end
    end

    -- Services
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local CoreGui = game:GetService("CoreGui")
    local HttpService = game:GetService("HttpService")

    -- Config system
    local config = {
        selectedEggs = {},
        lastPosition = {x = 0.5, y = 0.5}
    }

    -- Load config
    pcall(function()
        if readfile and writefile and isfile then
            if isfile("EggHatcherConfig.json") then
                config = HttpService:JSONDecode(readfile("EggHatcherConfig.json"))
            end
        end
    end)

    -- GUI Creation (same as before)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "EggHatcherGUI"
    ScreenGui.Parent = CoreGui

    -- ... (Rest of your GUI code) ...

    -- Main loop
    while task.wait() do
        if running then
            local egg = findSelectedEgg()
            if egg then
                teleportToEgg(egg)
                spamR()
            else
                TeleportService:Teleport(game.PlaceId)
            end
        end
    end
end
