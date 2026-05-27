--[ Gestionnaire d'Écologie (Croissance Animée Individuelle) ]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

local folder = workspace:FindFirstChild("Flora") or workspace
local FULL_SIZE = Vector3.new(0.7, 0.7, 0.7)

workspace:GetAttributeChangedSignal("PropsGenerated"):Connect(function()
    if workspace:GetAttribute("PropsGenerated") == true then
        CoreLogger.info("Écologie", "Système de croissance individuelle activé.")
    end
end)

local globalTick = ReplicatedStorage:WaitForChild("GlobalTickEvent")
globalTick.Event:Connect(function(deltaTime, inGameDaysPassed, timeScale)
    local daysToRegrow = GameConfig.Ecology.DaysToRegrow or 0.1
    
    for _, bush in ipairs(folder:GetChildren()) do
        if bush.Name == "BerryBush" then
            local fruitsAvailable = 0
            
            -- On analyse chaque baie du buisson indépendamment
            for _, child in ipairs(bush:GetChildren()) do
                if string.sub(child.Name, 1, 6) == "Berry_" then
                    
                    if child:GetAttribute("IsGrown") == true then
                        fruitsAvailable += 1
                    else
                        -- La baie est en train de pousser
                        local progress = child:GetAttribute("RegrowthProgress") or 0
                        local newProgress = progress + inGameDaysPassed
                        
                        if newProgress >= daysToRegrow then
                            -- 🌿 FIN DE LA CROISSANCE
                            child:SetAttribute("IsGrown", true)
                            child:SetAttribute("RegrowthProgress", 0)
                            child.Size = FULL_SIZE
                            
                            local prompt = child:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then prompt.Enabled = true end
                            
                            fruitsAvailable += 1
                        else
                            -- 📈 ANIMATION DE CROISSANCE PROGRESSIVE
                            child:SetAttribute("RegrowthProgress", newProgress)
                            
                            -- Calcul mathématique pour une animation fluide (Easing)
                            local scale = newProgress / daysToRegrow
                            local smoothScale = 1 - (1 - scale) * (1 - scale) -- OutQuad Easing
                            
                            child.Size = FULL_SIZE * smoothScale
                        end
                    end
                end
            end
            
            -- Synchronisation absolue de la variable du buisson pour le Panel et l'IA
            bush:SetAttribute("Fruits", fruitsAvailable)
        end
    end
end)