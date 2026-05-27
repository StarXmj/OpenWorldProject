--[ IA Component : Cerveau Déterministe V10 (Hystérésis, Camps Fiables & Lock Sommeil) ]--
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

local function cleanAndSortMemory(memList, currentPos, searchType, now, blacklist)
    local valid = {}
    for _, obj in ipairs(memList) do
        if obj and obj.Parent then
            if searchType == "BerryBush" and (obj:GetAttribute("Fruits") or 0) <= 0 then continue end
            if blacklist[obj] and now - blacklist[obj] < 120 then continue end
            table.insert(valid, obj)
        end
    end
    table.sort(valid, function(a, b)
        local posA = a:IsA("Model") and a:GetPivot().Position or a.Position
        local posB = b:IsA("Model") and b:GetPivot().Position or b.Position
        local flatA = Vector3.new(posA.X, 0, posA.Z)
        local flatB = Vector3.new(posB.X, 0, posB.Z)
        local flatCur = Vector3.new(currentPos.X, 0, currentPos.Z)
        return (flatA - flatCur).Magnitude < (flatB - flatCur).Magnitude
    end)
    return valid
end

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

    local currentState = "WANDER"
    local oldState = "WANDER"
    local wanderTarget, campSleepSpot, socializeTarget = nil, nil, nil
    local lastWanderTime, lastAttackTime = 0, 0
    
    local memory = { Food = {}, Water = {} }
    local blacklist = {}
    
    local lastStuckCheckPos = root.Position
    local lastStuckCheckTime = os.clock()
    local stuckWarnings = 0
    local isActuallySleeping = false -- 💤 Le flag crucial pour l'immobilité

    local globalTick = ReplicatedStorage:WaitForChild("GlobalTickEvent")
    local brainConnection
    
    brainConnection = globalTick.Event:Connect(function(tickRate, inGameDaysPassed, timeScale)
        if not npc or not npc.Parent or humanoid.Health <= 0 then
            brainConnection:Disconnect() 
            return
        end
        
        local now = os.clock()
        local isNight = Lighting.ClockTime < 6 or Lighting.ClockTime > 19
        local hunger, thirst, fatigue = Metabolism.Update(npc, GameConfig, isNight, tickRate, timeScale, inGameDaysPassed, currentState)
        local targetPlayer = Perception.GetAggroTarget(npc)
        local trait = npc:GetAttribute("Personality")
        
        -- 🛑 DÉTECTION DE PARALYSIE (Ignorée si le PNJ dort !)
        if not isActuallySleeping and now - lastStuckCheckTime >= 2.5 then
            local movedDist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(lastStuckCheckPos.X, 0, lastStuckCheckPos.Z)).Magnitude
            if humanoid.MoveDirection.Magnitude > 0.1 and movedDist < 1.5 then
                stuckWarnings += 1
                if stuckWarnings == 2 then CoreLogger.ai(npc.Name, "⚠️ Bloqué physiquement ! Tentative d'escalade...") end
            else
                stuckWarnings = 0
            end
            lastStuckCheckPos = root.Position
            lastStuckCheckTime = now
        end

        local nearbyFood = Perception.ScanRadius(npc, "BerryBush", 80)
        for _, f in ipairs(nearbyFood) do if not table.find(memory.Food, f) then table.insert(memory.Food, f) end end
        local nearbyWater = Perception.ScanRadius(npc, "Water", 80)
        for _, w in ipairs(nearbyWater) do if not table.find(memory.Water, w) then table.insert(memory.Water, w) end end
        
        memory.Food = cleanAndSortMemory(memory.Food, root.Position, "BerryBush", now, blacklist)
        memory.Water = cleanAndSortMemory(memory.Water, root.Position, "Water", now, blacklist)

        local foodText = "Aucune"
        if #memory.Food > 0 then foodText = string.format("%d (Plus proche: %dm)", #memory.Food, math.floor((memory.Food[1].Position - root.Position).Magnitude)) end
        local waterText = "Aucune"
        if #memory.Water > 0 then waterText = string.format("%d (Plus proche: %dm)", #memory.Water, math.floor((memory.Water[1].Position - root.Position).Magnitude)) end
        npc:SetAttribute("Debug_Memory", string.format("🍖 Nourriture : %s\n💧 Eau : %s", foodText, waterText))

        -- ⚖️ HYSTÉRÉSIS (Logique de Priorité Anti-Oscillation)
        local isSeekingFood = (currentState == "SEEK_FOOD" or currentState == "URGENT_FOOD")
        local isSeekingWater = (currentState == "SEEK_WATER" or currentState == "URGENT_WATER")
        
        -- Si on cherche déjà à manger, on n'arrête pas avant d'être quasiment plein (0.80)
        local foodThreshold = isSeekingFood and 0.80 or 0.50
        local waterThreshold = isSeekingWater and 0.80 or 0.50
        
        local wantsToSleep = false
        if currentState == "SEEK_CAMP" then
            if fatigue > 5 and (isNight or fatigue > 20) then wantsToSleep = true end
        else
            if fatigue >= 80 or (isNight and fatigue >= 50) then wantsToSleep = true end
        end
        
        if (humanoid.Health / humanoid.MaxHealth) <= 0.2 and targetPlayer then currentState = "FLEE"
        elseif thirst / GameConfig.Entity.MaxThirst <= 0.25 then currentState = (#memory.Water > 0) and "SEEK_WATER" or "URGENT_WATER"
        elseif hunger / GameConfig.Entity.MaxHunger <= 0.25 then currentState = (#memory.Food > 0) and "SEEK_FOOD" or "URGENT_FOOD"
        elseif targetPlayer then currentState = "COMBAT"
        elseif thirst / GameConfig.Entity.MaxThirst <= waterThreshold then currentState = (#memory.Water > 0) and "SEEK_WATER" or "URGENT_WATER"
        elseif hunger / GameConfig.Entity.MaxHunger <= foodThreshold then currentState = (#memory.Food > 0) and "SEEK_FOOD" or "URGENT_FOOD"
        elseif wantsToSleep then currentState = "SEEK_CAMP"
        else
            if currentState == "SOCIALIZE" and socializeTarget and socializeTarget.Parent then currentState = "SOCIALIZE"
            else
                currentState = "WANDER"
                if math.random(1, 50) == 1 and trait ~= "Aggressive" then
                    local friend = Perception.FindNearest(npc, "Vagabond", 40)
                    if friend and friend ~= npc then socializeTarget = friend currentState = "SOCIALIZE" end
                end
            end
        end

        local stateDuration = now - (npc:GetAttribute("StateStartTime") or now)
        if currentState ~= oldState then
            -- 🛑 Si on changeait trop vite de cible, on log l'hystérésis
            if (oldState == "WANDER" and isSeekingFood) or (isSeekingFood and oldState == "WANDER") then
                CoreLogger.ai(npc.Name, "Ignoring rapid target switch. Hysteresis locking objective.")
            end
            
            npc:SetAttribute("StateStartTime", now)
            stateDuration = 0
            if currentState == "SEEK_FOOD" then CoreLogger.ai(npc.Name, "Hunger low → Searching nearest known food source") end
            if currentState == "URGENT_FOOD" then CoreLogger.ai(npc.Name, "No known food → Entering urgent exploration mode") end
            if currentState == "SEEK_CAMP" and isNight then CoreLogger.ai(npc.Name, "Night detected → Returning to camp") end
            oldState = currentState
        end

        npc:SetAttribute("Debug_State", currentState)

        -- 🔓 DÉVERROUILLAGE SI ON SE RÉVEILLE
        if currentState ~= "SEEK_CAMP" then 
            campSleepSpot = nil 
            isActuallySleeping = false
            nav:UnlockFromSleep()
            animMgr:StopSleep() 
        end
        
        local baseSpeed = GameConfig.Entity.WalkSpeed
        if currentState == "SEEK_CAMP" then baseSpeed = GameConfig.Entity.WalkSpeed * 0.8 
        elseif currentState == "URGENT_FOOD" or currentState == "URGENT_WATER" then baseSpeed = GameConfig.Entity.WalkSpeed * 1.3
        elseif currentState == "COMBAT" or currentState == "FLEE" then baseSpeed = GameConfig.Entity.SprintSpeed end
        humanoid.WalkSpeed = baseSpeed 

        -- ⚙️ EXÉCUTION
        if currentState == "SEEK_FOOD" then
            local target = memory.Food[1]
            if stateDuration > 45 or stuckWarnings >= 3 or not target or not target.Parent or (target:GetAttribute("Fruits") or 0) == 0 then
                if target then 
                    CoreLogger.ai(npc.Name, "❌ Impossible d'atteindre ce buisson. Blacklist instantanée.")
                    blacklist[target] = now 
                end
                table.remove(memory.Food, 1)
                stuckWarnings = 0
                npc:SetAttribute("StateStartTime", now)
            else
                local flatTarget = Vector3.new(target.Position.X, 0, target.Position.Z)
                local flatRoot = Vector3.new(root.Position.X, 0, root.Position.Z)
                if (flatTarget - flatRoot).Magnitude <= 12 then 
                    nav:Stop() Logger.log(npc, currentState, "🫐 Miam !") animMgr:PlayGrab() 
                    local hasEaten = false
                    for _, berry in ipairs(target:GetChildren()) do
                        if string.sub(berry.Name, 1, 6) == "Berry_" and berry:GetAttribute("IsGrown") then
                            berry:SetAttribute("IsGrown", false) berry:SetAttribute("RegrowthProgress", 0) berry.Size = Vector3.new(0.05,0.05,0.05) berry.Transparency = 1
                            if berry:FindFirstChildOfClass("ProximityPrompt") then berry:FindFirstChildOfClass("ProximityPrompt").Enabled = false end
                            local c = target:GetAttribute("Fruits") or 1 target:SetAttribute("Fruits", math.max(0, c - 1))
                            hasEaten = true break 
                        end
                    end
                    if hasEaten then npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger) end
                    task.wait(1.5)
                else 
                    nav:SmartMoveTo(target.Position) 
                end
            end

        elseif currentState == "URGENT_FOOD" or currentState == "URGENT_WATER" then
            local dist = wanderTarget and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(wanderTarget.X, 0, wanderTarget.Z)).Magnitude or math.huge
            if not wanderTarget or now - lastWanderTime > 25 or stuckWarnings >= 2 or dist < 6 then
                lastWanderTime = now 
                wanderTarget = nav:GetDirectionalWanderTarget(120) 
                stuckWarnings = 0
                Logger.log(npc, currentState, "🔍 Survie active ! (Changement de cap)")
            end
            if wanderTarget then nav:SmartMoveTo(wanderTarget) end

        elseif currentState == "SEEK_WATER" then
            local target = memory.Water[1]
            if stateDuration > 45 or stuckWarnings >= 3 or not target or not target.Parent then
                if target then blacklist[target] = now end
                CoreLogger.ai(npc.Name, "❌ Impossible d'atteindre l'eau. Blacklist instantanée.")
                table.remove(memory.Water, 1)
                stuckWarnings = 0
                npc:SetAttribute("StateStartTime", now)
            else
                local flatTarget = Vector3.new(target.Position.X, 0, target.Position.Z)
                local flatRoot = Vector3.new(root.Position.X, 0, root.Position.Z)
                if (flatTarget - flatRoot).Magnitude <= 15 then 
                    nav:Stop() Logger.log(npc, currentState, "💧 Glou glou...") animMgr:PlayGrab() 
                    npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
                    task.wait(1.5)
                else 
                    nav:SmartMoveTo(target.Position) 
                end
            end

        elseif currentState == "SEEK_CAMP" then
            local closestCamp, _ = Perception.FindNearest(npc, "Campfire", 800)
            
            -- Si on est coincé depuis longtemps, on s'endort par terre en mode survie
            if stuckWarnings >= 4 and not isActuallySleeping then 
                campSleepSpot = root.Position 
                stuckWarnings = 0
            end

            if closestCamp then 
                if not campSleepSpot then 
                    campSleepSpot = Perception.GetCampSleepPosition(closestCamp:GetPivot().Position, npc) 
                    local distToCamp = math.floor((campSleepSpot - root.Position).Magnitude)
                    CoreLogger.ai(npc.Name, "Camp detected at distance " .. distToCamp)
                end
                
                local flatDist = (Vector3.new(campSleepSpot.X, 0, campSleepSpot.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
                
                if flatDist <= 5 then
                    if not isActuallySleeping then
                        isActuallySleeping = true
                        nav:LockForSleep()
                        CoreLogger.ai(npc.Name, "Sleep state entered.")
                        local playedId = animMgr:PlaySleep() 
                    end
                    Logger.log(npc, currentState, "💤 Zzz...")
                else 
                    nav:SmartMoveTo(campSleepSpot) 
                end
            else
                -- Nuit sans camp trouvé
                if not isActuallySleeping then
                    isActuallySleeping = true
                    nav:LockForSleep()
                    CoreLogger.ai(npc.Name, "Sleep state entered. No camp found.")
                    animMgr:PlaySleep()
                end
                Logger.log(npc, currentState, "🥶 Nuit glaciale...")
            end

        elseif currentState == "COMBAT" then
            if targetPlayer then
                local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
                if targetRoot then
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
                end
            end

        elseif currentState == "FLEE" then
            if targetPlayer then
                local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local fleeDir = (root.Position - targetRoot.Position).Unit
                    nav:SmartMoveTo(root.Position + fleeDir * 40)
                    Logger.log(npc, currentState, "😱 Fuyez !")
                end
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
            local dist = wanderTarget and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(wanderTarget.X, 0, wanderTarget.Z)).Magnitude or math.huge
            if not wanderTarget or now - lastWanderTime > 40 or stuckWarnings >= 2 or dist < 6 then
                lastWanderTime = now 
                wanderTarget = nav:GetDirectionalWanderTarget(80) 
                stuckWarnings = 0
                Logger.log(npc, currentState, "🗺️ En expédition...")
            end
            if wanderTarget then nav:SmartMoveTo(wanderTarget) end
        end
    end)
end

return Brain