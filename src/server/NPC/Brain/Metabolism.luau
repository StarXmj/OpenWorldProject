--[ IA Component : Metabolism (Basé sur les Jours In-Game + Aléatoire) ]--
local Metabolism = {}

function Metabolism.Update(npc, config, isNight, inGameDaysPassed)
    -- 🎲 Facteur de réalisme : Le métabolisme varie entre 85% et 115% de la normale
    local randomFactor = math.random(85, 115) / 100

    -- Perte de faim/soif basée sur la durée exacte de la journée
    local hungerDrain = (100 / config.Survival.DaysToStarve) * inGameDaysPassed * randomFactor
    local thirstDrain = (100 / config.Survival.DaysToDehydrate) * inGameDaysPassed * randomFactor
    
    -- La fatigue monte le jour (+150/jour) et descend la nuit (-200/jour pour bien dormir)
    local fatigueChange = (isNight and -200 or 150) * inGameDaysPassed * randomFactor

    local hunger = math.clamp((npc:GetAttribute("Hunger") or 100) - hungerDrain, 0, config.Entity.MaxHunger)
    local thirst = math.clamp((npc:GetAttribute("Thirst") or 100) - thirstDrain, 0, config.Entity.MaxThirst)
    local fatigue = math.clamp((npc:GetAttribute("Fatigue") or 0) + fatigueChange, 0, config.Entity.MaxFatigue or 100)

    npc:SetAttribute("Hunger", hunger)
    npc:SetAttribute("Thirst", thirst)
    npc:SetAttribute("Fatigue", fatigue)

    local hum = npc:FindFirstChild("Humanoid")
    if hum then
        if hunger <= 0 then hum:TakeDamage(config.Survival.StarveDamagePerDay * inGameDaysPassed) end
        if thirst <= 0 then hum:TakeDamage(config.Survival.DehydDamagePerDay * inGameDaysPassed) end
    end
    
    return hunger, thirst, fatigue
end

return Metabolism