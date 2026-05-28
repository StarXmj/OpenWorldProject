local StateExecutor = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

-- Remonte 2 dossiers (Core -> Brain) pour atteindre les modules vitaux
local Logger = require(script.Parent.Parent.Parent:WaitForChild("Logger"))
local CombatLogic = require(script.Parent.Parent:WaitForChild("CombatLogic"))
local Perception = require(script.Parent.Parent:WaitForChild("Perception"))

function StateExecutor.Execute(npc, root, humanoid, nav, animMgr, context, stats, GameConfig, now, timeScale)
    local currentState = context.currentState

    if currentState == "SEEK_FOOD" then
        local target = context.memory.Food[1]
        if context.stateDuration > 45 or context.stuckWarnings >= 3 or not target or not target.Parent or (target:GetAttribute("Fruits") or 0) == 0 then
            if target then 
                CoreLogger.ai(npc.Name, "❌ Impossible d'atteindre ce buisson. Blacklist instantanée.")
                context.blacklist[target] = now 
            end
            table.remove(context.memory.Food, 1)
            context.stuckWarnings = 0
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
        local dist = context.wanderTarget and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(context.wanderTarget.X, 0, context.wanderTarget.Z)).Magnitude or math.huge
        if not context.wanderTarget or now - context.lastWanderTime > 25 or context.stuckWarnings >= 2 or dist < 6 then
            context.lastWanderTime = now 
            context.wanderTarget = nav:GetDirectionalWanderTarget(120) 
            context.stuckWarnings = 0
            Logger.log(npc, currentState, "🔍 Survie active ! (Changement de cap)")
        end
        if context.wanderTarget then nav:SmartMoveTo(context.wanderTarget) end

    elseif currentState == "SEEK_WATER" then
        local target = context.memory.Water[1]
        if context.stateDuration > 45 or context.stuckWarnings >= 3 or not target or not target.Parent then
            if target then context.blacklist[target] = now end
            CoreLogger.ai(npc.Name, "❌ Impossible d'atteindre l'eau. Blacklist instantanée.")
            table.remove(context.memory.Water, 1)
            context.stuckWarnings = 0
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
        
        if context.stuckWarnings >= 4 and not context.isActuallySleeping then 
            context.campSleepSpot = root.Position 
            context.stuckWarnings = 0
        end

        if closestCamp then 
            if not context.campSleepSpot then 
                context.campSleepSpot = Perception.GetCampSleepPosition(closestCamp:GetPivot().Position, npc) 
            end
            
            local flatDist = (Vector3.new(context.campSleepSpot.X, 0, context.campSleepSpot.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
            if flatDist <= 5 then
                if not context.isActuallySleeping then
                    context.isActuallySleeping = true
                    nav:LockForSleep()
                    animMgr:PlaySleep() 
                end
                Logger.log(npc, currentState, "💤 Zzz...")
                
                -- 📉 CALCUL EXACT DU SOMMEIL (0 -> 100 de repos en 2/6ème du jour in-game)
                -- Math : 100 de fatigue / (2/6 de jour) = 300 de fatigue récupérée par jour in-game complet.
                local recoveryRate = 300 * stats.inGameDaysPassed
                
                -- On annule le malus du métabolisme du tick actuel pour que les maths soient pures
                local baseInterval = GameConfig.Survival.TickRate or 5
                local timeFactor = (stats.tickRate / baseInterval) * stats.timeScale
                local metabolismDrain = (stats.isNight and 0.4 or -0.1) * timeFactor * 5
                
                local newFatigue = npc:GetAttribute("Fatigue") - recoveryRate - metabolismDrain
                npc:SetAttribute("Fatigue", math.clamp(newFatigue, 0, 100))
            else 
                nav:SmartMoveTo(context.campSleepSpot) 
            end
        else
            if not context.isActuallySleeping then
                context.isActuallySleeping = true
                nav:LockForSleep()
                animMgr:PlaySleep()
            end
            Logger.log(npc, currentState, "🥶 Nuit glaciale...")
            
            -- Sur le sol, on dort moins bien (ex: il faut 3/6ème de jour pour récupérer 100% = 200 par jour)
            local recoveryRate = 200 * stats.inGameDaysPassed
            
            -- Annulation du malus du métabolisme
            local baseInterval = GameConfig.Survival.TickRate or 5
            local timeFactor = (stats.tickRate / baseInterval) * stats.timeScale
            local metabolismDrain = (stats.isNight and 0.4 or -0.1) * timeFactor * 5
            
            local newFatigue = npc:GetAttribute("Fatigue") - recoveryRate - metabolismDrain
            npc:SetAttribute("Fatigue", math.clamp(newFatigue, 0, 100))
        end

    elseif currentState == "COMBAT" then
        if stats.targetPlayer then
            local targetRoot = stats.targetPlayer:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                if (targetRoot.Position - root.Position).Magnitude <= (GameConfig.Combat.AttackRange or 6) then
                    nav:Stop()
                    if now - context.lastAttackTime >= (GameConfig.Combat.Cooldown or 0.8) / timeScale then
                        context.lastAttackTime = now Logger.log(npc, currentState, "😡 Tiens ça !") animMgr:PlayPunch()
                        task.spawn(function()
                            task.wait((GameConfig.Combat.WindUpTime or 0.25) / timeScale)
                            CombatLogic.ExecuteAttack(npc, GameConfig)
                        end)
                    end
                else
                    if nav:HasLineOfSight(stats.targetPlayer, 30) then nav:Stop() humanoid:MoveTo(targetRoot.Position)
                    else nav:SmartMoveTo(targetRoot.Position) end
                end
            end
        end

    elseif currentState == "FLEE" then
        if stats.targetPlayer then
            local targetRoot = stats.targetPlayer:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local fleeDir = (root.Position - targetRoot.Position).Unit
                nav:SmartMoveTo(root.Position + fleeDir * 40)
                Logger.log(npc, currentState, "😱 Fuyez !")
            end
        end

    elseif currentState == "SOCIALIZE" then
        if context.socializeTarget and context.socializeTarget.Parent then
            local targetRoot = context.socializeTarget:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist > 8 then nav:SmartMoveTo(targetRoot.Position)
                else
                    nav:Stop()
                    root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
                    if math.random(1, 10) == 1 then Logger.log(npc, currentState, "💬 Salut.") end
                    if math.random(1, 40) == 1 then context.socializeTarget = nil end
                end
            end
        else context.socializeTarget = nil end

    elseif currentState == "WANDER" then
        local dist = context.wanderTarget and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(context.wanderTarget.X, 0, context.wanderTarget.Z)).Magnitude or math.huge
        if not context.wanderTarget or now - context.lastWanderTime > 40 or context.stuckWarnings >= 2 or dist < 6 then
            context.lastWanderTime = now 
            context.wanderTarget = nav:GetDirectionalWanderTarget(80) 
            context.stuckWarnings = 0
            Logger.log(npc, currentState, "🗺️ En expédition...")
        end
        if context.wanderTarget then nav:SmartMoveTo(context.wanderTarget) end
    end
end

return StateExecutor