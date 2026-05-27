--[ IA Component : Metabolism (Survie & Sommeil Réaliste) ]--
local Metabolism = {}

function Metabolism.Update(npc, config, isNight, tickRate, timeScale, inGameDaysPassed, currentState)
    local hungerDrain = (100 / config.Survival.DaysToStarve) * inGameDaysPassed
    local thirstDrain = (100 / config.Survival.DaysToDehydrate) * inGameDaysPassed
    
    local isSleeping = (currentState == "SEEK_CAMP")
    local fatigueDrain = 0
    
    if isSleeping then
        -- 😴 Pendant le sommeil : restauration de la fatigue ET réduction forte de la faim/soif
        fatigueDrain = -(100 / (1/3)) * inGameDaysPassed
        hungerDrain = hungerDrain * 0.3 
        thirstDrain = thirstDrain * 0.3
    else
        fatigueDrain = (100 / (2/3)) * inGameDaysPassed
    end

    if isNight and not isSleeping then
        fatigueDrain = fatigueDrain * 1.5
    end

    local hunger = (npc:GetAttribute("Hunger") or config.Entity.MaxHunger) - hungerDrain
    local thirst = (npc:GetAttribute("Thirst") or config.Entity.MaxThirst) - thirstDrain
    local fatigue = (npc:GetAttribute("Fatigue") or 0) + fatigueDrain

    hunger = math.clamp(hunger, 0, config.Entity.MaxHunger)
    thirst = math.clamp(thirst, 0, config.Entity.MaxThirst)
    fatigue = math.clamp(fatigue, 0, config.Entity.MaxFatigue or 100)

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