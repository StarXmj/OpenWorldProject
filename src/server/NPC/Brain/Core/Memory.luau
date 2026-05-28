local Memory = {}
local Perception = require(script.Parent.Parent:WaitForChild("Perception"))

function Memory.CleanAndSort(memList, currentPos, searchType, now, blacklist)
    local valid = {}
    for _, obj in ipairs(memList) do
        if obj and obj.Parent then
            if searchType == "BerryBush" and (obj:GetAttribute("Fruits") or 0) <= 0 then continue end
            if blacklist[obj] and now - blacklist[obj] < 120 then continue end
            table.insert(valid, obj)
        end
    end
    table.sort(valid, function(a, b)
        local posA = a:IsA("Model") and a:GetPivot().Position or a.Position
        local posB = b:IsA("Model") and b:GetPivot().Position or b.Position
        local flatA = Vector3.new(posA.X, 0, posA.Z)
        local flatB = Vector3.new(posB.X, 0, posB.Z)
        local flatCur = Vector3.new(currentPos.X, 0, currentPos.Z)
        return (flatA - flatCur).Magnitude < (flatB - flatCur).Magnitude
    end)
    return valid
end

function Memory.Update(npc, context, rootPos, now)
    local nearbyFood = Perception.ScanRadius(npc, "BerryBush", 80)
    for _, f in ipairs(nearbyFood) do if not table.find(context.memory.Food, f) then table.insert(context.memory.Food, f) end end
    
    local nearbyWater = Perception.ScanRadius(npc, "Water", 80)
    for _, w in ipairs(nearbyWater) do if not table.find(context.memory.Water, w) then table.insert(context.memory.Water, w) end end
    
    context.memory.Food = Memory.CleanAndSort(context.memory.Food, rootPos, "BerryBush", now, context.blacklist)
    context.memory.Water = Memory.CleanAndSort(context.memory.Water, rootPos, "Water", now, context.blacklist)

    local foodText = "Aucune"
    if #context.memory.Food > 0 then foodText = string.format("%d (Plus proche: %dm)", #context.memory.Food, math.floor((context.memory.Food[1].Position - rootPos).Magnitude)) end
    
    local waterText = "Aucune"
    if #context.memory.Water > 0 then waterText = string.format("%d (Plus proche: %dm)", #context.memory.Water, math.floor((context.memory.Water[1].Position - rootPos).Magnitude)) end
    
    npc:SetAttribute("Debug_Memory", string.format("🍖 Nourriture : %s\n💧 Eau : %s", foodText, waterText))
end

return Memory