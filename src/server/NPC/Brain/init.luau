--[ IA Component : Cerveau Déterministe (Synchronisé au Master Tick) ]--
local Brain = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

local Navigator = require(script.Parent:WaitForChild("Navigator"))
local Logger = require(script.Parent:WaitForChild("Logger"))

local Animator = require(script:WaitForChild("Animator"))
local Metabolism = require(script:WaitForChild("Metabolism"))
local Perception = require(script:WaitForChild("Perception"))
local CombatLogic = require(script:WaitForChild("CombatLogic"))
local Identity = require(script:WaitForChild("Identity"))

function Brain.Attach(npc)
    local dnaLog = Identity.Generate(npc)
    
    local humanoid = npc:WaitForChild("Humanoid")
    local root = npc:WaitForChild("HumanoidRootPart")
    
    local nav = Navigator.new(npc) 
    local animMgr = Animator.new(humanoid, GameConfig)
    
    humanoid.MaxHealth = GameConfig.Entity.MaxHealth humanoid.Health = GameConfig.Entity.MaxHealth
    npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger) npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
    npc:SetAttribute("Fatigue", 0) npc:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
    npc:SetAttribute("Combat_Level", 1) npc:SetAttribute("Resistance_Level", 1)

    local currentState = "WANDER"
    local wanderTarget, campSleepSpot, socializeTarget = nil, nil, nil
    local lastWanderTime, lastRestTime, lastAttackTime = 0, 0, 0

    -- 🌟 CONNEXION AU MASTER TICK (LE MOTEUR DÉTERMINISTE)
    local globalTick = ReplicatedStorage:WaitForChild("GlobalTickEvent")
    local brainConnection
    
    brainConnection = globalTick.Event:Connect(function(tickRate, timeScale)
        -- Si le PNJ meurt ou est détruit, on coupe instantanément le Cerveau
        if not npc or not npc.Parent or humanoid.Health <= 0 then
            brainConnection:Disconnect()
            return
        end
        
        -- 1. SURVIE & SENS (Basé sur le temps universel)
        local isNight = Lighting.ClockTime < 6 or Lighting.ClockTime > 19
        local hunger, thirst, fatigue = Metabolism.Update(npc, GameConfig, isNight, tickRate, timeScale)
        local targetPlayer = Perception.GetAggroTarget(npc)
        
        local trait = npc:GetAttribute("Personality")
        local fleeThreshold = 0.2 
        if trait == "Coward" then fleeThreshold = 0.5 end 
        if trait == "Aggressive" then fleeThreshold = 0.05 end

        -- 2. DÉCISION
        local oldState = currentState
        if targetPlayer then currentState = humanoid.Health <= (humanoid.MaxHealth * fleeThreshold) and "FLEE" or "COMBAT"
        elseif thirst <= (GameConfig.Entity.MaxThirst * 0.4) then currentState = "SEEK_WATER"
        elseif hunger <= (GameConfig.Entity.MaxHunger * 0.4) then currentState = "SEEK_FOOD"
        elseif fatigue >= 80 or isNight then currentState = "SEEK_CAMP"
        else
            if currentState == "REST" and os.clock() - lastRestTime < (6 / timeScale) then currentState = "REST"
            elseif currentState == "SOCIALIZE" and socializeTarget and socializeTarget.Parent then currentState = "SOCIALIZE"
            else
                currentState = "WANDER"
                local rng = math.random(1, 30)
                if rng == 1 then 
                    currentState = "REST" lastRestTime = os.clock() 
                elseif rng == 2 and trait ~= "Aggressive" then
                    local friend, dist = Perception.FindNearest(npc, "Vagabond", 40)
                    if friend and friend ~= npc then socializeTarget = friend currentState = "SOCIALIZE" end
                end
            end
        end

        if currentState ~= "SEEK_CAMP" then campSleepSpot = nil animMgr:StopSleep() end
        
        -- 🚀 3. VITESSE MULTIPLIÉE PAR L'ÉCHELLE DE TEMPS
        local baseSpeed = 6
        if currentState == "REST" or currentState == "SEEK_CAMP" then baseSpeed = 4 
        elseif currentState == "COMBAT" or currentState == "FLEE" then baseSpeed = GameConfig.Entity.SprintSpeed end
        
        -- La vitesse physique s'accélère si la journée est plus courte !
        humanoid.WalkSpeed = baseSpeed * timeScale

        -- 4. EXÉCUTION
        if currentState == "COMBAT" then
            local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
            local dist = (targetRoot.Position - root.Position).Magnitude
            if dist <= (GameConfig.Combat.AttackRange or 6) then
                nav:Stop()
                
                -- Le Cooldown de frappe est divisé par le TimeScale (il frappe plus vite si le temps s'accélère)
                local dynamicCooldown = (GameConfig.Combat.Cooldown or 0.8) / timeScale
                
                if os.clock() - lastAttackTime >= dynamicCooldown then
                    lastAttackTime = os.clock()
                    Logger.log(npc, currentState, "😡 Tiens ça !")
                    animMgr:PlayPunch()
                    task.spawn(function()
                        task.wait((GameConfig.Combat.WindUpTime or 0.25) / timeScale)
                        CombatLogic.ExecuteAttack(npc, GameConfig)
                    end)
                end
            else
                if dist <= 30 and nav:HasLineOfSight(targetPlayer, dist) then
                    nav:Stop() humanoid:MoveTo(targetRoot.Position)
                else
                    nav:SmartMoveTo(targetRoot.Position)
                end
            end

        -- (Reste des États : WANDER, SOCIALIZE, SEEK_CAMP, etc... identique à avant)
        elseif currentState == "SOCIALIZE" then
            if socializeTarget and socializeTarget.Parent then
                local targetRoot = socializeTarget:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (targetRoot.Position - root.Position).Magnitude
                    if dist > 8 then nav:SmartMoveTo(targetRoot.Position)
                    else
                        nav:Stop()
                        root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
                        if math.random(1, 10) == 1 then Logger.log(npc, currentState, "💬 Salut.") end
                        if math.random(1, 40) == 1 then socializeTarget = nil end
                    end
                end
            else socializeTarget = nil end

        elseif currentState == "SEEK_CAMP" then
            local closestCamp, minCampDist = Perception.FindNearest(npc, "Campfire", 800)
            if closestCamp then 
                if not campSleepSpot then campSleepSpot = Perception.GetCampSleepPosition(closestCamp.Position) end
                if (campSleepSpot - root.Position).Magnitude <= 4 then
                    nav:Stop() animMgr:PlaySleep() Logger.log(npc, currentState, "💤 Zzz...")
                    -- Récupération modifiée par le temps
                    npc:SetAttribute("Fatigue", math.clamp(fatigue - (1 * tickRate * timeScale), 0, 100))
                else nav:SmartMoveTo(campSleepSpot) end
            else
                nav:Stop() animMgr:PlaySleep()
                npc:SetAttribute("Fatigue", math.clamp(fatigue - (0.5 * tickRate * timeScale), 0, 100))
            end

        elseif currentState == "SEEK_WATER" then
            local closestWater, minDist = Perception.FindNearest(npc, "Water")
            if closestWater then
                if minDist <= 6 then nav:Stop() Logger.log(npc, currentState, "💧 Glou glou...") animMgr:PlayGrab() npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
                else nav:SmartMoveTo(closestWater.Position) end
            else currentState = "WANDER" end

        elseif currentState == "SEEK_FOOD" then
            local closestFood, minDist = Perception.FindNearest(npc, "BerryBush")
            if closestFood then
                if minDist <= 5 then nav:Stop() Logger.log(npc, currentState, "🫐 Récolte...") animMgr:PlayGrab() closestFood:SetAttribute("Fruits", (closestFood:GetAttribute("Fruits") or 0) - 1) npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
                else nav:SmartMoveTo(closestFood.Position) end
            else currentState = "WANDER" end

        elseif currentState == "WANDER" then
            if not wanderTarget or os.clock() - lastWanderTime > (6 / timeScale) or humanoid.MoveDirection.Magnitude < 0.1 then
                lastWanderTime = os.clock() wanderTarget = nav:GetSafeWanderTarget() Logger.log(npc, currentState, "💭 J'explore...")
            end
            if wanderTarget then nav:SmartMoveTo(wanderTarget) end
        end
    end)
end

return Brain