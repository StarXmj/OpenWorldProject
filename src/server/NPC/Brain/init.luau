--[ IA Component : Cerveau Déterministe V11 (Architecture AAA Modulaire) ]--
local Brain = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

-- Composants basiques
local Navigator = require(script.Parent:WaitForChild("Navigator"))
local Animator = require(script:WaitForChild("Animator"))
local Metabolism = require(script:WaitForChild("Metabolism"))
local Perception = require(script:WaitForChild("Perception"))
local Identity = require(script:WaitForChild("Identity"))

-- 🧠 Cœur Logique (Sous-modules)
local Memory = require(script:WaitForChild("Core"):WaitForChild("Memory"))
local StuckDetector = require(script:WaitForChild("Core"):WaitForChild("StuckDetector"))
local DecisionEngine = require(script:WaitForChild("Core"):WaitForChild("DecisionEngine"))
local StateExecutor = require(script:WaitForChild("Core"):WaitForChild("StateExecutor"))

function Brain.Attach(npc)
    Identity.Generate(npc)
    
    local humanoid = npc:WaitForChild("Humanoid")
    local root = npc:WaitForChild("HumanoidRootPart")
    local nav = Navigator.new(npc) 
    local animMgr = Animator.new(humanoid, GameConfig)
  
    humanoid.MaxHealth = GameConfig.Entity.MaxHealth humanoid.Health = GameConfig.Entity.MaxHealth
    npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger) npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
    npc:SetAttribute("Fatigue", 0) npc:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
    npc:SetAttribute("StateStartTime", os.clock())

    -- 📦 CONTEXTE : Stocke la mémoire et l'état sans polluer le script
    local context = {
        currentState = "WANDER", oldState = "WANDER",
        wanderTarget = nil, campSleepSpot = nil, socializeTarget = nil,
        lastWanderTime = 0, lastAttackTime = 0,
        memory = { Food = {}, Water = {} }, blacklist = {},
        lastStuckCheckPos = root.Position, lastStuckCheckTime = os.clock(),
        stuckWarnings = 0, isActuallySleeping = false,
        stateDuration = 0
    }

    local globalTick = ReplicatedStorage:WaitForChild("GlobalTickEvent")
    local brainConnection
    
    brainConnection = globalTick.Event:Connect(function(tickRate, inGameDaysPassed, timeScale)
        if not npc or not npc.Parent or humanoid.Health <= 0 then
            brainConnection:Disconnect() return
        end
        
        local now = os.clock()
        local isNight = Lighting.ClockTime < 6 or Lighting.ClockTime > 19
        local hunger, thirst, fatigue = Metabolism.Update(npc, GameConfig, isNight, tickRate, timeScale, inGameDaysPassed, context.currentState)
        
        -- Empaquettage des stats pour les moteurs
        local stats = {
            hunger = hunger, thirst = thirst, fatigue = fatigue,
            health = humanoid.Health, maxHealth = humanoid.MaxHealth,
            targetPlayer = Perception.GetAggroTarget(npc), trait = npc:GetAttribute("Personality"), 
            isNight = isNight,
            inGameDaysPassed = inGameDaysPassed, -- 🕒 On passe la fraction de jour exact
            tickRate = tickRate,
            timeScale = timeScale
        }

        -- 1. Scan Physique (Paralysie)
        StuckDetector.Check(npc, root, humanoid, context, now)

        -- 2. Mise à jour de la Mémoire
        Memory.Update(npc, context, root.Position, now)

        -- 3. Évaluation Décisionnelle (Hystérésis & Priorité)
        local newState = DecisionEngine.Evaluate(npc, context, stats, GameConfig)

        -- 4. Gestion des Transitions d'États
        context.stateDuration = now - (npc:GetAttribute("StateStartTime") or now)
        if newState ~= context.oldState then
            local isSeekingFood = (newState == "SEEK_FOOD" or newState == "URGENT_FOOD")
            if (context.oldState == "WANDER" and isSeekingFood) or (isSeekingFood and context.oldState == "WANDER") then
                CoreLogger.ai(npc.Name, "Ignoring rapid target switch. Hysteresis locking objective.")
            end
            
            npc:SetAttribute("StateStartTime", now)
            context.stateDuration = 0
            context.oldState = newState
        end

        context.currentState = newState
        npc:SetAttribute("Debug_State", context.currentState)

        -- 5. Gestion des Verrous de Sommeil
        if context.currentState ~= "SEEK_CAMP" then 
            context.campSleepSpot = nil 
            context.isActuallySleeping = false
            nav:UnlockFromSleep()
            animMgr:StopSleep() 
        end
        
        -- 6. Dynamisme de la Vitesse
        local baseSpeed = GameConfig.Entity.WalkSpeed
        if context.currentState == "SEEK_CAMP" then 
            if isNight then
                baseSpeed = GameConfig.Entity.SprintSpeed -- 🚨 PANIQUE : Il fait nuit, on court au camp !
            else
                baseSpeed = GameConfig.Entity.WalkSpeed * 0.8 -- Il fait jour, on rentre tranquillement
            end
        elseif context.currentState == "URGENT_FOOD" or context.currentState == "URGENT_WATER" then 
            baseSpeed = GameConfig.Entity.WalkSpeed * 1.3
        elseif context.currentState == "COMBAT" or context.currentState == "FLEE" then 
            baseSpeed = GameConfig.Entity.SprintSpeed 
        end
        humanoid.WalkSpeed = baseSpeed

        -- 7. Exécution des Actions Physiques
        StateExecutor.Execute(npc, root, humanoid, nav, animMgr, context, stats, GameConfig, now, timeScale)
    end)
end

return Brain