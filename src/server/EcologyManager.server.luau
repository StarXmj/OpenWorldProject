--[ Gestionnaire d'Écologie (ADN, Interaction Multiples & Éclosion Physique) ]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

local FULL_SIZE = Vector3.new(0.7, 0.7, 0.7)
local HIDDEN_SIZE = Vector3.new(0.05, 0.05, 0.05) -- Évite les bugs de scale à 0
local initializedBushes = {} 

workspace:GetAttributeChangedSignal("PropsGenerated"):Connect(function()
    if workspace:GetAttribute("PropsGenerated") == true then
        CoreLogger.info("Écologie", "Système de nature vivante activé.")
    end
end)

-- 🧬 FONCTION D'INITIALISATION D'UN BUISSON
local function initBush(bush)
    if initializedBushes[bush] then return end
    initializedBushes[bush] = true

    local capacityRoll = math.random()
    local maxFruits = 1
    if capacityRoll <= GameConfig.Generation.BerryQuantityChances.Four then maxFruits = 4
    elseif capacityRoll <= GameConfig.Generation.BerryQuantityChances.Three then maxFruits = 3
    elseif capacityRoll <= GameConfig.Generation.BerryQuantityChances.Two then maxFruits = 2
    end
    
    bush:SetAttribute("MaxFruits", maxFruits)
    bush:SetAttribute("Fruits", maxFruits)
    
    -- 🍓 GÉNÉRATION ORGANIQUE SANS LÉVITATION
    for i = 1, maxFruits do
        local berry = Instance.new("Part")
        berry.Name = "Berry_" .. i
        berry.Size = FULL_SIZE
        berry.Color = Color3.fromRGB(180, 10, 50)
        berry.Material = Enum.Material.SmoothPlastic
        berry.Shape = Enum.PartType.Ball
        berry.Anchored = true 
        berry.CanCollide = false
        
        -- 📐 Mathématiques d'Ellipsoïde (Épouse la forme du buisson et s'encastre légèrement)
        local u = (i / maxFruits) * math.pi * 2 + math.random(-0.4, 0.4) -- Répartition autour
        local v = math.random(20, 70) * (math.pi / 180) -- Hauteur (20° à 70° = sur le dessus et les côtés)
        
        local a = (bush.Size.X / 2) - 0.35 -- Rayon X avec encastrement
        local b = (bush.Size.Y / 2) - 0.35 -- Rayon Y avec encastrement
        local c = (bush.Size.Z / 2) - 0.35 -- Rayon Z avec encastrement
        
        local offsetX = a * math.cos(u) * math.sin(v)
        local heightY = b * math.cos(v)
        local offsetZ = c * math.sin(u) * math.sin(v)
        
        berry.Position = bush.CFrame:PointToWorldSpace(Vector3.new(offsetX, heightY, offsetZ))
        berry.Parent = bush
        
        berry:SetAttribute("IsGrown", true)
        berry:SetAttribute("RegrowthProgress", 0)
        
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Cueillir"
        prompt.ObjectText = "Baie Sauvage"
        prompt.HoldDuration = 0.2
        -- 🛡️ CORRECTIONS CRITIQUES POUR POUVOIR TOUT RAMASSER
        prompt.RequiresLineOfSight = false -- Empêche le buisson de bloquer le clic
        prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow -- Affiche tous les boutons proches
        prompt.MaxActivationDistance = 8
        prompt.Parent = berry
        
        prompt.Triggered:Connect(function(player)
            if berry:GetAttribute("IsGrown") then
                berry:SetAttribute("IsGrown", false)
                berry:SetAttribute("RegrowthProgress", 0)
                
                -- On cache la baie proprement
                berry.Size = HIDDEN_SIZE 
                berry.Transparency = 1 
                prompt.Enabled = false
                
                local count = 0
                for _, b in ipairs(bush:GetChildren()) do
                    if string.sub(b.Name, 1, 6) == "Berry_" and b:GetAttribute("IsGrown") then
                        count += 1
                    end
                end
                bush:SetAttribute("Fruits", count)
                
                local giveItemEvent = ReplicatedStorage:FindFirstChild("GiveItemEvent")
                if giveItemEvent then giveItemEvent:Fire(player, "Berry", 1) end
            end
        end)
    end
end

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == "BerryBush" and obj:IsA("BasePart") then initBush(obj) end
end
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "BerryBush" and obj:IsA("BasePart") then
        task.wait(0.1) initBush(obj) 
    end
end)

-- 📈 BOUCLE DE CROISSANCE INDIVIDUELLE
local globalTick = ReplicatedStorage:WaitForChild("GlobalTickEvent")
globalTick.Event:Connect(function(deltaTime, inGameDaysPassed, timeScale)
    local daysToRegrow = GameConfig.Ecology.DaysToRegrow or 0.1
    
    for bush, _ in pairs(initializedBushes) do
        if not bush or not bush.Parent then
            initializedBushes[bush] = nil
            continue
        end

        local fruitsAvailable = 0
        
        for _, child in ipairs(bush:GetChildren()) do
            if string.sub(child.Name, 1, 6) == "Berry_" then
                if child:GetAttribute("IsGrown") == true then
                    fruitsAvailable += 1
                else
                    local progress = child:GetAttribute("RegrowthProgress") or 0
                    local newProgress = progress + inGameDaysPassed
                    
                    if newProgress >= daysToRegrow then
                        child:SetAttribute("IsGrown", true)
                        child:SetAttribute("RegrowthProgress", 0)
                        child.Size = FULL_SIZE
                        child.Transparency = 0
                        
                        local prompt = child:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then prompt.Enabled = true end
                        fruitsAvailable += 1
                    else
                        child:SetAttribute("RegrowthProgress", newProgress)
                        local scale = newProgress / daysToRegrow
                        local smoothScale = 1 - (1 - scale) * (1 - scale) 
                        
                        -- L'éclosion est fluide et sort du buisson
                        local sizeCalc = math.max(0.05, 0.7 * smoothScale)
                        child.Size = Vector3.new(sizeCalc, sizeCalc, sizeCalc)
                        child.Transparency = 0
                    end
                end
            end
        end
        
        bush:SetAttribute("Fruits", fruitsAvailable)
    end
end)