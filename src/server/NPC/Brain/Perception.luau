--[ IA Component : Perception (Vision corrigée pour Dossiers & ADN) ]--
local Perception = {}
local Players = game:GetService("Players")

function Perception.GetAggroTarget(npc)
    local aggroName = npc:GetAttribute("AggroTarget")
    if aggroName and os.clock() - (npc:GetAttribute("AggroTime") or 0) < 15 then
        local p = Players:FindFirstChild(aggroName)
        if p and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            return p.Character
        end
    end
    return nil
end

function Perception.FindNearest(npc, searchType, maxDist)
    local root = npc:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end

    local closest, minDist = nil, maxDist or math.huge
    
    -- 📁 1. SÉLECTION DU BON DOSSIER
    local folder = workspace
    if searchType == "Water" then
        folder = workspace:FindFirstChild("WaterWaypoints")
    elseif searchType == "BerryBush" then
        folder = workspace:FindFirstChild("Flora") -- ⬅️ CORRECTION : Il regarde dans le dossier Flora !
    end

    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            local isValid = false
            
            -- 🔍 2. FILTRAGE INTELLIGENT
            if searchType == "Water" then
                isValid = true
            elseif searchType == "BerryBush" and obj.Name == "BerryBush" then
                -- On ignore les buissons vides
                if (obj:GetAttribute("Fruits") or 0) > 0 then
                    isValid = true
                end
            elseif searchType == "Campfire" and obj.Name == "Campfire" then
                isValid = true
            elseif searchType == "Vagabond" then
                -- CORRECTION SOCIALE : On reconnait un autre PNJ grâce à son ADN (Personality)
                if obj:GetAttribute("Personality") ~= nil and obj ~= npc then
                    isValid = true
                end
            end
            
            -- 📏 3. CALCUL DE LA DISTANCE
            if isValid then
                local targetPos = nil
                
                -- Si c'est un PNJ, on vise son torse, sinon on vise le bloc
                if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
                    targetPos = obj.HumanoidRootPart.Position
                elseif obj:IsA("BasePart") then
                    targetPos = obj.Position
                end
                
                if targetPos then
                    local dist = (targetPos - root.Position).Magnitude
                    if dist < minDist then 
                        minDist = dist 
                        closest = obj 
                    end
                end
            end
        end
    end
    return closest, minDist
end

-- 🏕️ Positionnement autour du feu
function Perception.GetCampSleepPosition(campPosition)
    local angle = math.random() * math.pi * 2 
    local distance = math.random(5, 12) 
    local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
    return campPosition + offset
end

return Perception