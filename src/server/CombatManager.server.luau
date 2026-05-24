--[ Gestionnaire de Combat et XP Martiale ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local attackEvent = ReplicatedStorage:FindFirstChild("AttackEvent") or Instance.new("RemoteEvent")
attackEvent.Name = "AttackEvent"
attackEvent.Parent = ReplicatedStorage

local lastAttackTimes = {}

attackEvent.OnServerEvent:Connect(function(player)
    local currentTime = os.clock()
    local lastAttack = lastAttackTimes[player] or 0
    
    if currentTime - lastAttack < GameConfig.Combat.Cooldown then return end
    lastAttackTimes[player] = currentTime

    local char = player.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- On récupère notre moteur d'XP
    local addXpEvent = ReplicatedStorage:WaitForChild("AddXPEvent")

    for _, object in ipairs(workspace:GetChildren()) do
        if object ~= char and object:FindFirstChild("Humanoid") then
            
            local targetRoot = object:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = object:FindFirstChild("Humanoid")
            
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                
                if distance <= GameConfig.Combat.AttackRange then
                    local directionToTarget = (targetRoot.Position - rootPart.Position).Unit
                    local lookVector = rootPart.CFrame.LookVector
                    local angle = directionToTarget:Dot(lookVector)
                    
                    if angle > 0.4 then 
                        
                        -- 🌟 CALCUL DES DÉGÂTS DYNAMIQUES
                        local attackerCombatLvl = char:GetAttribute("Combat_Level") or 1
                        local targetResistLvl = object:GetAttribute("Resistance_Level") or 1
                        
                        -- Le combat augmente les dégâts, la résistance les réduit
                        local rawDamage = GameConfig.Combat.BaseDamage + (attackerCombatLvl * 0.5)
                        local damageReduction = (targetResistLvl * 0.3)
                        local finalDamage = math.max(1, rawDamage - damageReduction) -- Minimum 1 dégat
                        
                        targetHumanoid:TakeDamage(finalDamage)
                        
                        -- 🌟 GAIN D'XP POUR LES DEUX !
                        addXpEvent:Fire(char, "Combat", 15)       -- Taper rend plus fort
                        addXpEvent:Fire(object, "Resistance", 20) -- Se faire taper rend plus dur
                        
                        object:SetAttribute("AggroTarget", player.Name)
                        object:SetAttribute("AggroTime", os.clock())
                    end
                end
            end
        end
    end
end)