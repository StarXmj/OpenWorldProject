--[ IA Component : Metabolism (Survie & Stats) ]--
local Metabolism = {}

function Metabolism.Update(npc, config, isNight)
    local hunger = npc:GetAttribute("Hunger") - 0.08
    local thirst = npc:GetAttribute("Thirst") - 0.12
    local fatigue = npc:GetAttribute("Fatigue") - (isNight and 0.2 or 0.05)

    hunger = math.clamp(hunger, 0, config.Entity.MaxHunger)
    thirst = math.clamp(thirst, 0, config.Entity.MaxThirst)
    fatigue = math.clamp(fatigue, 0, config.Entity.MaxFatigue or 100)

    npc:SetAttribute("Hunger", hunger)
    npc:SetAttribute("Thirst", thirst)
    npc:SetAttribute("Fatigue", fatigue)

    local hum = npc:FindFirstChild("Humanoid")
    if hum then
        if hunger <= 0 then hum.Health -= (config.Survival.StarvationDamage / 25) end
        if thirst <= 0 then hum.Health -= (config.Survival.DehydrationDamage / 25) end
    end
    
    return hunger, thirst, fatigue
end

return Metabolism