--[ IA Component : Metabolism (Survie & Stats synchronisées au Temps) ]--
local Metabolism = {}

function Metabolism.Update(npc, config, isNight, tickRate, timeScale)
    -- Le métabolisme est multiplié par le temps qui passe !
    local hungerDrain = (config.Survival.HungerDecay * tickRate * timeScale)
    local thirstDrain = (config.Survival.ThirstDecay * tickRate * timeScale)
    
    -- La fatigue monte (ou descend la nuit) en fonction du temps
    local fatigueDrain = (isNight and 0.4 or -0.1) * tickRate * timeScale

    local hunger = npc:GetAttribute("Hunger") - hungerDrain
    local thirst = npc:GetAttribute("Thirst") - thirstDrain
    local fatigue = npc:GetAttribute("Fatigue") + fatigueDrain

    hunger = math.clamp(hunger, 0, config.Entity.MaxHunger)
    thirst = math.clamp(thirst, 0, config.Entity.MaxThirst)
    fatigue = math.clamp(fatigue, 0, config.Entity.MaxFatigue or 100)

    npc:SetAttribute("Hunger", hunger)
    npc:SetAttribute("Thirst", thirst)
    npc:SetAttribute("Fatigue", fatigue)

    local hum = npc:FindFirstChild("Humanoid")
    if hum then
        -- Les dégâts de faim/soif scalent aussi avec le temps !
        if hunger <= 0 then hum.Health -= (config.Survival.StarvationDamage * tickRate * timeScale) end
        if thirst <= 0 then hum.Health -= (config.Survival.DehydrationDamage * tickRate * timeScale) end
    end
    
    return hunger, thirst, fatigue
end

return Metabolism