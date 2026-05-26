--[ IA Component : Perception (Recherche cibles & Campements) ]--
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

function Perception.FindNearest(npc, name, maxDist)
    local root = npc:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end

    local closest, minDist = nil, maxDist or math.huge
    local folder = (name == "Water") and workspace:FindFirstChild("WaterWaypoints") or workspace

    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            if (name == "Water" or obj.Name == name) then
                if name == "BerryBush" and (obj:GetAttribute("Fruits") or 0) <= 0 then continue end
                local dist = (obj.Position - root.Position).Magnitude
                if dist < minDist then minDist = dist closest = obj end
            end
        end
    end
    return closest, minDist
end

-- 🏕️ CALCULE UNE PLACE UNIQUE AUTOUR DU FEU POUR NE PAS S'EMPILER
function Perception.GetCampSleepPosition(campPosition)
    local angle = math.random() * math.pi * 2 -- Angle aléatoire sur 360 degrés
    local distance = math.random(5, 20) -- Entre 5 et 12 studs du feu
    local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
    return campPosition + offset
end

return Perception