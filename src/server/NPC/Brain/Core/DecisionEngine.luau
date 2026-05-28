local DecisionEngine = {}
local Perception = require(script.Parent.Parent:WaitForChild("Perception"))

function DecisionEngine.Evaluate(npc, context, stats, GameConfig)
    local currentState = context.currentState
    local isSeekingFood = (currentState == "SEEK_FOOD" or currentState == "URGENT_FOOD")
    local isSeekingWater = (currentState == "SEEK_WATER" or currentState == "URGENT_WATER")
    
    -- Hystérésis
    local foodThreshold = isSeekingFood and 0.80 or 0.50
    local waterThreshold = isSeekingWater and 0.80 or 0.50
    
    local wantsToSleep = false
    if currentState == "SEEK_CAMP" then
        if stats.fatigue > 5 and (stats.isNight or stats.fatigue > 20) then wantsToSleep = true end
    else
        if stats.fatigue >= 80 or (stats.isNight and stats.fatigue >= 50) then wantsToSleep = true end
    end
    
    local newState = currentState
    local healthPct = stats.health / stats.maxHealth
    local thirstPct = stats.thirst / GameConfig.Entity.MaxThirst
    local hungerPct = stats.hunger / GameConfig.Entity.MaxHunger
    local hasWater = #context.memory.Water > 0
    local hasFood = #context.memory.Food > 0

    if healthPct <= 0.2 and stats.targetPlayer then newState = "FLEE"
    elseif thirstPct <= 0.25 then newState = hasWater and "SEEK_WATER" or "URGENT_WATER"
    elseif hungerPct <= 0.25 then newState = hasFood and "SEEK_FOOD" or "URGENT_FOOD"
    elseif stats.targetPlayer then newState = "COMBAT"
    elseif thirstPct <= waterThreshold then newState = hasWater and "SEEK_WATER" or "URGENT_WATER"
    elseif hungerPct <= foodThreshold then newState = hasFood and "SEEK_FOOD" or "URGENT_FOOD"
    elseif wantsToSleep then newState = "SEEK_CAMP"
    else
        if currentState == "SOCIALIZE" and context.socializeTarget and context.socializeTarget.Parent then 
            newState = "SOCIALIZE"
        else
            newState = "WANDER"
            if math.random(1, 50) == 1 and stats.trait ~= "Aggressive" then
                local friend = Perception.FindNearest(npc, "Vagabond", 40)
                if friend and friend ~= npc then 
                    context.socializeTarget = friend 
                    newState = "SOCIALIZE" 
                end
            end
        end
    end
    
    return newState
end

return DecisionEngine