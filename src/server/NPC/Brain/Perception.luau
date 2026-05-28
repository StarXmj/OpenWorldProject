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

-- 🏕️ SYSTÈME DE SLOTS DE CAMPEMENT
function Perception.GetAssignedCampSlot(camp, npc)
    local maxSlots = 8
    local slotDistance = 8
    local assignedSlot = npc:GetAttribute("CampSlot")
    
    -- Si le PNJ n'a pas encore de place attribuée, on lui en trouve une libre
    if not assignedSlot then
        local usedSlots = {}
        for _, otherNpc in ipairs(workspace:GetChildren()) do
            if otherNpc:GetAttribute("Personality") and otherNpc:GetAttribute("CampSlot") then
                usedSlots[otherNpc:GetAttribute("CampSlot")] = true
            end
        end
        
        for i = 1, maxSlots do
            if not usedSlots[i] then
                assignedSlot = i
                npc:SetAttribute("CampSlot", i)
                break
            end
        end
        
        if not assignedSlot then assignedSlot = math.random(1, maxSlots) end -- Fallback
    end
    
    local angle = (assignedSlot / maxSlots) * math.pi * 2
    local campPos = camp:IsA("Model") and camp:GetPivot().Position or camp.Position
    local offset = Vector3.new(math.cos(angle) * slotDistance, 0, math.sin(angle) * slotDistance)
    
    return campPos + offset
end

-- 💧 SÉCURITÉ EAU : Trouver la rive la plus proche sans nager
function Perception.GetSafeShoreTarget(npcPos, waterPos)
    local dir = (npcPos - waterPos).Unit
    local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
    
    -- On recule la cible de 15 studs en direction du PNJ (vers la terre ferme)
    local shorePos = waterPos + (flatDir * 15)
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.Terrain}
    
    -- Vérification : Est-ce bien de la terre/sable et pas de l'eau profonde ?
    local ray = workspace:Raycast(shorePos + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), params)
    if ray and ray.Material ~= Enum.Material.Water then
        return ray.Position
    end
    
    -- Sécurité supplémentaire : on recule encore plus
    return waterPos + (flatDir * 25)
end

return Perception