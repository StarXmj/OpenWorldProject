--[ IA Component : Perception (Vaste Campement & Scan) ]--
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

function Perception.ScanRadius(npc, searchType, radius)
    local root = npc:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        local isValid = false
        
        if searchType == "Water" and obj.Name == "WaterWaypoint" then 
            isValid = true
        elseif searchType == "BerryBush" and obj.Name == "BerryBush" and obj:IsA("BasePart") then
            if (obj:GetAttribute("Fruits") or 0) > 0 then isValid = true end
        elseif searchType == "Campfire" and obj.Name == "Campfire" then
            isValid = true
        end
        
        if isValid then
            local targetPos = obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position or obj:GetPivot().Position) or obj.Position
            local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
            
            if dist <= radius then table.insert(found, obj) end
        end
    end
    return found
end

function Perception.FindNearest(npc, searchType, maxDist)
    local results = Perception.ScanRadius(npc, searchType, maxDist or 9999)
    local root = npc:FindFirstChild("HumanoidRootPart")
    if #results == 0 or not root then return nil, math.huge end
    
    local closest, minDist = nil, math.huge
    for _, obj in ipairs(results) do
        local targetPos = obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position or obj:GetPivot().Position) or obj.Position
        local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
        if dist < minDist then
            minDist = dist
            closest = obj
        end
    end
    return closest, minDist
end

function Perception.GetCampSleepPosition(campPosition, npc)
    -- On augmente le nombre de tentatives et l'espace (pour que 20+ PNJ puissent se coucher)
    for attempt = 1, 15 do
        local angle = math.random() * math.pi * 2 
        local distance = math.random(10, 25) -- 🏕️ Grand cercle autour du feu
        local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
        local spot = campPosition + offset
        
        local tooClose = false
        for _, other in ipairs(workspace:GetChildren()) do
            if other:IsA("Model") and other:FindFirstChild("Humanoid") and other ~= npc then
                local otherRoot = other:FindFirstChild("HumanoidRootPart")
                if otherRoot and (Vector3.new(otherRoot.Position.X, 0, otherRoot.Position.Z) - Vector3.new(spot.X, 0, spot.Z)).Magnitude < 4.5 then
                    tooClose = true
                    break
                end
            end
        end
        if not tooClose then return spot end
    end
    
    -- Fallback très espacé s'il n'y a plus de place
    local rAngle = math.random() * math.pi * 2
    local rDist = math.random(26, 35)
    return campPosition + Vector3.new(math.cos(rAngle) * rDist, 0, math.sin(rAngle) * rDist)
end

return Perception