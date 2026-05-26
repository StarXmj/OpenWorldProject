--[ IA Component : Cerveau (Machine d'États) ]--
local Brain = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Navigator = require(script.Parent:WaitForChild("Navigator"))
local Logger = require(script.Parent:WaitForChild("Logger"))
-- Les 4 Sous-Modules du Cerveau
local Animator = require(script:WaitForChild("Animator"))
local Metabolism = require(script:WaitForChild("Metabolism"))
local Perception = require(script:WaitForChild("Perception"))
local CombatLogic = require(script:WaitForChild("CombatLogic"))

function Brain.Attach(npc)
    npc.Name = "Vagabond_" .. math.random(100, 999)
    
    local humanoid = npc:WaitForChild("Humanoid")
    local root = npc:WaitForChild("HumanoidRootPart")
    
    local nav = Navigator.new(npc) 
    local animMgr = Animator.new(humanoid, GameConfig)
    
    -- Init Stats
    humanoid.MaxHealth = GameConfig.Entity.MaxHealth humanoid.Health = GameConfig.Entity.MaxHealth
    npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger) npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
    npc:SetAttribute("Fatigue", GameConfig.Entity.MaxFatigue or 100) npc:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
    npc:SetAttribute("Combat_Level", 1) npc:SetAttribute("Resistance_Level", 1)

    local currentState = "WANDER"
    local wanderTarget, campSleepSpot = nil, nil
    local lastWanderTime, lastRestTime, lastAttackTime = 0, 0, 0

    task.spawn(function()
        while npc and npc.Parent and humanoid.Health > 0 do
            
            -- 1. SURVIE & SENS
            local isNight = Lighting.ClockTime < 6 or Lighting.ClockTime > 19
            local hunger, thirst, fatigue = Metabolism.Update(npc, GameConfig, isNight)
            local targetPlayer = Perception.GetAggroTarget(npc)

            -- 2. DÉCISION DE L'ÉTAT (Priorités)
            local oldState = currentState
            if targetPlayer then currentState = humanoid.Health <= (humanoid.MaxHealth * 0.2) and "FLEE" or "COMBAT"
            elseif thirst <= (GameConfig.Entity.MaxThirst * 0.4) then currentState = "SEEK_WATER"
            elseif hunger <= (GameConfig.Entity.MaxHunger * 0.4) then currentState = "SEEK_FOOD"
            elseif fatigue <= 20 or isNight then currentState = "SEEK_CAMP"
            else
                if currentState == "REST" and os.clock() - lastRestTime < 6 then currentState = "REST"
                else
                    currentState = "WANDER"
                    if math.random(1, 30) == 1 then currentState = "REST" lastRestTime = os.clock() end
                end
            end

            -- Si on quitte le camp, on libère notre place pour dormir
            if currentState ~= "SEEK_CAMP" then campSleepSpot = nil animMgr:StopSleep() end
            
            -- Vitesses
            if currentState == "WANDER" then humanoid.WalkSpeed = 6
            elseif currentState == "REST" or currentState == "SEEK_CAMP" then humanoid.WalkSpeed = 4 
            else humanoid.WalkSpeed = GameConfig.Entity.SprintSpeed end

            -- 3. EXÉCUTION
            if currentState == "COMBAT" then
                local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist <= (GameConfig.Combat.AttackRange or 6) then
                    nav:Stop()
                    if os.clock() - lastAttackTime >= (GameConfig.Combat.Cooldown or 0.8) then
                        lastAttackTime = os.clock()
                        Logger.log(npc, currentState, "😡 Tiens ça !")
                        animMgr:PlayPunch()
                        task.spawn(function()
                            task.wait(GameConfig.Combat.WindUpTime or 0.25)
                            CombatLogic.ExecuteAttack(npc, GameConfig)
                        end)
                    end
                else
                    if dist <= 30 and nav:HasLineOfSight(targetPlayer, dist) then
                        Logger.log(npc, currentState, "🤬 Je te charge !")
                        nav:Stop() humanoid:MoveTo(targetRoot.Position)
                    else
                        Logger.log(npc, currentState, "🤬 Reviens là !") nav:SmartMoveTo(targetRoot.Position)
                    end
                end

            elseif currentState == "SEEK_CAMP" then
                local closestCamp, minCampDist = Perception.FindNearest(npc, "Campfire", 800)
                if closestCamp then 
                    -- Attribue une place unique autour du feu
                    if not campSleepSpot then campSleepSpot = Perception.GetCampSleepPosition(closestCamp.Position) end
                    
                    if (campSleepSpot - root.Position).Magnitude <= 4 then
                        nav:Stop()
                        animMgr:PlaySleep()
                        Logger.log(npc, currentState, "💤 Zzz...")
                        npc:SetAttribute("Fatigue", math.clamp(fatigue + 0.5, 0, 100))
                    else
                        if oldState ~= currentState then Logger.log(npc, currentState, "⛺ Retour au camp...") end
                        nav:SmartMoveTo(campSleepSpot)
                    end
                else
                    nav:Stop() animMgr:PlaySleep()
                    if oldState ~= currentState then Logger.log(npc, currentState, "🥶 Nuit glaciale...") end
                    npc:SetAttribute("Fatigue", math.clamp(fatigue + 0.2, 0, 100))
                end

            elseif currentState == "SEEK_WATER" then
                local closestWater, minDist = Perception.FindNearest(npc, "Water")
                if closestWater then
                    if minDist <= 6 then
                        nav:Stop() Logger.log(npc, currentState, "💧 Glou glou...") animMgr:PlayGrab() task.wait(1)
                        npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
                    else
                        nav:SmartMoveTo(closestWater.Position)
                    end
                else currentState = "WANDER" end

            elseif currentState == "SEEK_FOOD" then
                local closestFood, minDist = Perception.FindNearest(npc, "BerryBush")
                if closestFood then
                    if minDist <= 5 then
                        nav:Stop() Logger.log(npc, currentState, "🫐 Récolte...") animMgr:PlayGrab() task.wait(1)
                        closestFood:SetAttribute("Fruits", (closestFood:GetAttribute("Fruits") or 0) - 1)
                        npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
                    else
                        if oldState ~= currentState then Logger.log(npc, currentState, "👀 Un buisson !") end
                        nav:SmartMoveTo(closestFood.Position)
                    end
                else currentState = "WANDER" end

            elseif currentState == "WANDER" then
                if not wanderTarget or os.clock() - lastWanderTime > 6 or humanoid.MoveDirection.Magnitude < 0.1 then
                    lastWanderTime = os.clock() wanderTarget = nav:GetSafeWanderTarget()
                    Logger.log(npc, currentState, "💭 J'explore...")
                end
                if wanderTarget then nav:SmartMoveTo(wanderTarget) end
            end
            
            task.wait(0.2) 
        end
    end)
end

return Brain