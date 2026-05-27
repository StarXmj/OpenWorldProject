--[ IA Component : Perception (Vision 2D & Dossiers ciblés) ]--
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
    
    -- 📁 1. CIBLAGE DU BON DOSSIER
    local folder = workspace
    if searchType == "Water" then
        folder = workspace:FindFirstChild("WaterWaypoints")
    elseif searchType == "BerryBush" then
        folder = workspace:FindFirstChild("Flora") -- 🌿 L'IA regarde enfin dans la forêt !
    end

    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            local isValid = false
            
            -- 🔍 2. FILTRAGE
            if searchType == "Water" then
                isValid = true
            elseif searchType == "BerryBush" and obj.Name == "BerryBush" then
                if (obj:GetAttribute("Fruits") or 0) > 0 then isValid = true end
            elseif searchType == "Campfire" and obj.Name == "Campfire" then
                isValid = true
            elseif searchType == "Vagabond" then
                if obj:GetAttribute("Personality") ~= nil and obj ~= npc then isValid = true end
            end
            
            if isValid then
                local targetPos = nil
                
                -- 🏕️ 3. RÉCUPÉRATION DU CENTRE EXACT (Même sans HumanoidRootPart)
                if obj:IsA("Model") then
                    targetPos = obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position or obj:GetPivot().Position
                elseif obj:IsA("BasePart") then
                    targetPos = obj.Position
                end
                
                if targetPos then
                    -- 📏 4. DISTANCE 2D (Ignore la hauteur Y pour éviter les blocages)
                    local flatRoot = Vector3.new(root.Position.X, 0, root.Position.Z)
                    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
                    local dist = (flatRoot - flatTarget).Magnitude
                    
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

function Perception.GetCampSleepPosition(campPosition)
    local angle = math.random() * math.pi * 2 
    local distance = math.random(5, 12) 
    local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
    return campPosition + offset
end

return Perception