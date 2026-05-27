--[ IA Component : Metabolism (Survie & Stats synchronisées et Normalisées) ]--
local Metabolism = {}

function Metabolism.Update(npc, config, isNight, tickRate, timeScale)
    -- 📐 CORRECTION CRITIQUE : Normalisation mathématique
    -- tickRate vaut 0.2s. config.Survival.TickRate vaut 5s.
    -- On divise pour éviter qu'ils ne meurent 25x plus vite que prévu !
    local baseInterval = config.Survival.TickRate or 5
    local timeFactor = (tickRate / baseInterval) * timeScale

    local hungerDrain = (config.Survival.HungerDecay * timeFactor)
    local thirstDrain = (config.Survival.ThirstDecay * timeFactor)
    local fatigueDrain = (isNight and 0.4 or -0.1) * timeFactor * 5

    local hunger = (npc:GetAttribute("Hunger") or 100) - hungerDrain
    local thirst = (npc:GetAttribute("Thirst") or 100) - thirstDrain
    local fatigue = (npc:GetAttribute("Fatigue") or 0) + fatigueDrain

    hunger = math.clamp(hunger, 0, config.Entity.MaxHunger)
    thirst = math.clamp(thirst, 0, config.Entity.MaxThirst)
    fatigue = math.clamp(fatigue, 0, config.Entity.MaxFatigue or 100)

    npc:SetAttribute("Hunger", hunger)
    npc:SetAttribute("Thirst", thirst)
    npc:SetAttribute("Fatigue", fatigue)

    local hum = npc:FindFirstChild("Humanoid")
    if hum then
        -- Les dégâts mortels sont aussi normalisés pour ne pas les "One-Shot"
        if hunger <= 0 then hum:TakeDamage(config.Survival.StarvationDamage * timeFactor) end
        if thirst <= 0 then hum:TakeDamage(config.Survival.DehydrationDamage * timeFactor) end
    end
    
    return hunger, thirst, fatigue
end

return Metabolism