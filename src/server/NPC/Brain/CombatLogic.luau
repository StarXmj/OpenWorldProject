--[ IA Component : Combat (Hitboxes) ]--
local CombatLogic = {}

function CombatLogic.ExecuteAttack(npc, gameConfig)
    local root = npc:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local lookDir = root.CFrame.LookVector
    local flatLookDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
    local params = OverlapParams.new() 
    params.FilterType = Enum.RaycastFilterType.Exclude 
    params.FilterDescendantsInstances = {npc, workspace.Terrain}
    
    local hitboxPos = root.Position + (flatLookDir * 3.5)
    local hits = workspace:GetPartBoundsInBox(CFrame.new(hitboxPos, hitboxPos + flatLookDir), gameConfig.Combat.HitboxSize or Vector3.new(5,5,5), params)
    
    for _, part in ipairs(hits) do
        local tModel = part:FindFirstAncestorOfClass("Model")
        if tModel and tModel ~= npc and not tModel:IsDescendantOf(npc) then
            local tHum = tModel:FindFirstChild("Humanoid")
            if tHum then 
                local dmg = math.max(1, ((gameConfig.Combat.BaseDamage or 15) + ((npc:GetAttribute("Combat_Level") or 1) * 0.5)) - ((tModel:GetAttribute("Resistance_Level") or 1) * 0.3))
                tHum:TakeDamage(dmg) 
            end
        end
    end
end

return CombatLogic