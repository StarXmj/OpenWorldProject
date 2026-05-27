--[ IA Component : Cerveau Déterministe (Utility AI & Survie) ]--
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
    
    -- 🛡️ CORRECTION SYNTAXE : Lignes bien séparées pour l'initialisation !
    humanoid.MaxHealth = GameConfig.Entity.MaxHealth 
    humanoid.Health = GameConfig.Entity.MaxHealth
    
    npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger) 
    npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
    npc:SetAttribute("Fatigue", 0) 
    npc:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
    npc:SetAttribute("Combat_Level", 1) 
    npc:SetAttribute("Resistance_Level", 1)

    -- Timers de secours
    npc:SetAttribute("WaterDespair", 0)
    npc:SetAttribute("FoodDespair", 0)

    local currentState = "WANDER"
    local wanderTarget, campSleepSpot, socializeTarget = nil, nil, nil
    local lastWanderTime, lastRestTime, lastAttackTime = 0, 0, 0

    local globalTick = ReplicatedStorage:WaitForChild("GlobalTickEvent")
    local brainConnection
    
    brainConnection = globalTick.Event:Connect(function(tickRate, timeScale)
        if not npc or not npc.Parent or humanoid.Health <= 0 then
            brainConnection:Disconnect() 
            return
        end
        
        local isNight = Lighting.ClockTime < 6 or Lighting.ClockTime > 19
        local hunger, thirst, fatigue = Metabolism.Update(npc, GameConfig, isNight, tickRate, timeScale)
        local targetPlayer = Perception.GetAggroTarget(npc)
        
        local trait = npc:GetAttribute("Personality")
        local fleeThreshold = (trait == "Coward") and 0.5 or ((trait == "Aggressive") and 0.05 or 0.2)
        
        local healthPct = humanoid.Health / humanoid.MaxHealth
        local hungerPct = hunger / GameConfig.Entity.MaxHunger
        local thirstPct = thirst / GameConfig.Entity.MaxThirst

        local now = os.clock()
        local ignoreWater = (now - npc:GetAttribute("WaterDespair")) < 15
        local ignoreFood = (now - npc:GetAttribute("FoodDespair")) < 15

        local oldState = currentState
        
        -- ⚖️ SYSTÈME DE PRIORITÉS
        if healthPct <= fleeThreshold and targetPlayer then currentState = "FLEE"
        elseif thirstPct <= 0.25 and not ignoreWater then currentState = "SEEK_WATER"
        elseif hungerPct <= 0.25 and not ignoreFood then currentState = "SEEK_FOOD"
        elseif targetPlayer then currentState = "COMBAT"
        elseif thirstPct <= 0.5 and not ignoreWater then currentState = "SEEK_WATER"
        elseif hungerPct <= 0.5 and not ignoreFood then currentState = "SEEK_FOOD"
        elseif fatigue >= 80 or isNight then currentState = "SEEK_CAMP"
        else
            if currentState == "REST" and now - lastRestTime < (6 / timeScale) then currentState = "REST"
            elseif currentState == "SOCIALIZE" and socializeTarget and socializeTarget.Parent then currentState = "SOCIALIZE"
            else
                currentState = "WANDER"
                if math.random(1, 30) == 1 then currentState = "REST" lastRestTime = now
                elseif math.random(1, 30) == 2 and trait ~= "Aggressive" then
                    local friend = Perception.FindNearest(npc, "Vagabond", 40)
                    if friend and friend ~= npc then socializeTarget = friend currentState = "SOCIALIZE" end
                end
            end
        end

        npc:SetAttribute("Debug_State", currentState)
        if currentState ~= "SEEK_CAMP" then campSleepSpot = nil animMgr:StopSleep() end
        
        local baseSpeed = 6
        if currentState == "REST" or currentState == "SEEK_CAMP" then baseSpeed = 4 
        elseif currentState == "COMBAT" or currentState == "FLEE" then baseSpeed = GameConfig.Entity.SprintSpeed end
        humanoid.WalkSpeed = baseSpeed * timeScale

        -- 🏃‍♂️ EXÉCUTION
        if currentState == "COMBAT" then
            local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
            if (targetRoot.Position - root.Position).Magnitude <= (GameConfig.Combat.AttackRange or 6) then
                nav:Stop()
                if now - lastAttackTime >= (GameConfig.Combat.Cooldown or 0.8) / timeScale then
                    lastAttackTime = now Logger.log(npc, currentState, "😡 Tiens ça !") animMgr:PlayPunch()
                    task.spawn(function()
                        task.wait((GameConfig.Combat.WindUpTime or 0.25) / timeScale)
                        CombatLogic.ExecuteAttack(npc, GameConfig)
                    end)
                end
            else
                if nav:HasLineOfSight(targetPlayer, 30) then nav:Stop() humanoid:MoveTo(targetRoot.Position)
                else nav:SmartMoveTo(targetRoot.Position) end
            end

        elseif currentState == "FLEE" then
            local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local fleeDir = (root.Position - targetRoot.Position).Unit
                nav:SmartMoveTo(root.Position + fleeDir * 40)
                Logger.log(npc, currentState, "😱 Fuyez !")
            end

        elseif currentState == "SEEK_WATER" then
            local closestWater, minDist = Perception.FindNearest(npc, "Water")
            if closestWater then
                if minDist <= 15 then 
                    nav:Stop() Logger.log(npc, currentState, "💧 Glou glou...") animMgr:PlayGrab() 
                    npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
                    npc:SetAttribute("WaterDespair", 0) 
                else nav:SmartMoveTo(closestWater.Position) end
            else 
                Logger.log(npc, currentState, "🏜️ Pas d'eau...")
                npc:SetAttribute("WaterDespair", now) 
                currentState = "WANDER" 
            end

        elseif currentState == "SEEK_FOOD" then
            local closestFood, minDist = Perception.FindNearest(npc, "BerryBush")
            if closestFood then
                if minDist <= 10 then 
                    nav:Stop() Logger.log(npc, currentState, "🫐 Récolte...") animMgr:PlayGrab() 
                    
                    local hasEaten = false
                    for _, berry in ipairs(closestFood:GetChildren()) do
                        if string.sub(berry.Name, 1, 6) == "Berry_" and berry:GetAttribute("IsGrown") == true then
                            berry:SetAttribute("IsGrown", false)
                            berry:SetAttribute("RegrowthProgress", 0)
                            berry.Size = Vector3.zero
                            local prompt = berry:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then prompt.Enabled = false end
                            
                            local current = closestFood:GetAttribute("Fruits") or 1
                            closestFood:SetAttribute("Fruits", math.max(0, current - 1))
                            hasEaten = true
                            break 
                        end
                    end
                    
                    if hasEaten then
                        npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
                        npc:SetAttribute("FoodDespair", 0)
                    else
                        npc:SetAttribute("FoodDespair", now)
                    end
                    task.wait(1)
                else nav:SmartMoveTo(closestFood.Position) end
            else 
                Logger.log(npc, currentState, "🍖 Pas de baies...")
                npc:SetAttribute("FoodDespair", now) 
                currentState = "WANDER" 
            end

        elseif currentState == "SEEK_CAMP" then
            local closestCamp, minCampDist = Perception.FindNearest(npc, "Campfire", 800)
            if closestCamp then 
                if not campSleepSpot then campSleepSpot = Perception.GetCampSleepPosition(closestCamp:GetPivot().Position) end
                local flatDist = (Vector3.new(campSleepSpot.X, 0, campSleepSpot.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
                if flatDist <= 4 then
                    nav:Stop() animMgr:PlaySleep() Logger.log(npc, currentState, "💤 Zzz...")
                    npc:SetAttribute("Fatigue", math.clamp(fatigue - (1 * tickRate * timeScale), 0, 100))
                else nav:SmartMoveTo(campSleepSpot) end
            else
                nav:Stop() animMgr:PlaySleep() Logger.log(npc, currentState, "🥶 Nuit glaciale...")
                npc:SetAttribute("Fatigue", math.clamp(fatigue - (0.5 * tickRate * timeScale), 0, 100))
            end

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

        elseif currentState == "WANDER" then
            if not wanderTarget or now - lastWanderTime > (6 / timeScale) or humanoid.MoveDirection.Magnitude < 0.1 then
                lastWanderTime = now wanderTarget = nav:GetSafeWanderTarget() Logger.log(npc, currentState, "💭 J'explore...")
            end
            if wanderTarget then nav:SmartMoveTo(wanderTarget) end
        end
    end)
end

return Brain