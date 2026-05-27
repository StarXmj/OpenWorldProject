--[ Gestionnaire d'Écologie Déterministe (Flore Connectée) ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

local RECOVERY_TIME = 120 -- Temps de base pour la repousse (2 minutes réelles)
local MAX_FRUITS = 3

local folder = workspace:FindFirstChild("Flora") or workspace

local function initBush(bush)
    bush:SetAttribute("Fruits", MAX_FRUITS)
    bush:SetAttribute("RegrowthTimer", 0)
    if bush:IsA("BasePart") then bush.Color = Color3.fromRGB(34, 139, 34) end
end

-- On attend que le PropGenerator ait fini de scanner la carte avant d'armer la flore
workspace:GetAttributeChangedSignal("PropsGenerated"):Connect(function()
    if workspace:GetAttribute("PropsGenerated") == true then
        for _, object in ipairs(folder:GetChildren()) do
            if object.Name == "BerryBush" then initBush(object) end
        end
        CoreLogger.info("Écologie", "Flore synchronisée au Master Tick avec succès.")
    end
end)

-- 🌟 LE LIEN UNIVERSEL : La nature pousse selon les jours in-game
local globalTick = ReplicatedStorage:WaitForChild("GlobalTickEvent")
globalTick.Event:Connect(function(deltaTime, inGameDaysPassed, timeScale)
    for _, object in ipairs(folder:GetChildren()) do
        if object.Name == "BerryBush" then
            local fruits = object:GetAttribute("Fruits") or 0
            
            if fruits < MAX_FRUITS then
                local currentProgress = object:GetAttribute("RegrowthProgress") or 0
                -- La repousse avance selon la fraction de jour écoulée
                local newProgress = currentProgress + inGameDaysPassed
                
                if newProgress >= GameConfig.Ecology.DaysToRegrow then
                    object:SetAttribute("Fruits", MAX_FRUITS)
                    object:SetAttribute("RegrowthProgress", 0)
                    if object:IsA("BasePart") then object.Color = Color3.fromRGB(34, 139, 34) end
                    
                    local berry = object:FindFirstChild("BerryDrop")
                    if berry then
                        berry.Transparency = 0
                        local prompt = berry:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then prompt.Enabled = true end
                    end
                else
                    object:SetAttribute("RegrowthProgress", newProgress)
                end
            end
        end
    end
end)