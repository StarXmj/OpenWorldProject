--[ Gestionnaire de Combat et Hitboxes Spatiales V2 (Debug Actif) ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local attackEvent = ReplicatedStorage:FindFirstChild("AttackEvent") or Instance.new("RemoteEvent")
attackEvent.Name = "AttackEvent"
attackEvent.Parent = ReplicatedStorage

local lastAttackTimes = {}

-- 🛡️ Crée un filtre pour que la Hitbox ignore l'attaquant lui-même ET le Terrain !
local function createHitboxParams(attackerChar)
    local params = OverlapParams.new()
    -- On ignore le joueur qui attaque et la map (le terrain)
    params.FilterDescendantsInstances = {attackerChar, workspace.Terrain}
    params.FilterType = Enum.RaycastFilterType.Exclude
    return params
end

-- 🛠️ FONCTION DE DEBUG VISUEL (Très utile pour le Game Design)
local function drawDebugHitbox(cframe, size)
    local part = Instance.new("Part")
    part.Name = "HitboxDebug"
    part.Anchored = true 
    part.CanCollide = false 
    part.Transparency = 0.6
    part.Color = Color3.fromRGB(255, 30, 30) 
    part.Material = Enum.Material.Neon
    part.Size = size 
    part.CFrame = cframe
    part.Parent = workspace
    
    -- La hitbox rouge disparaît après 0.3 secondes
    task.delay(0.3, function() part:Destroy() end)
end

attackEvent.OnServerEvent:Connect(function(player)
    local currentTime = os.clock()
    local lastAttack = lastAttackTimes[player] or 0
    
    -- 1. Anti-Spam
    local cooldown = GameConfig.Combat.Cooldown or 0.8
    if currentTime - lastAttack < cooldown then return end
    lastAttackTimes[player] = currentTime

    local char = player.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid or humanoid.Health <= 0 then return end

    -- ⏳ 2. PHASE DE WIND-UP (On utilise "or 0.25" au cas où GameConfig n'est pas à jour)
    task.wait(GameConfig.Combat.WindUpTime or 0.25)

    if not char.Parent or humanoid.Health <= 0 then return end

    -- 📦 3. GÉNÉRATION DE LA HITBOX SPATIALE (Correction de l'inclinaison)
    local lookDir = rootPart.CFrame.LookVector
    -- On écrase l'axe Y pour forcer la direction à être parfaitement plate au ras du sol
    local flatLookDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit 
    
    -- On place la Hitbox 3.5 studs devant le joueur
    local hitboxPos = rootPart.Position + (flatLookDir * 3.5)
    -- On l'oriente dans la direction où le joueur regarde
    local hitboxCFrame = CFrame.new(hitboxPos, hitboxPos + flatLookDir)
    
    -- On sécurise la taille (L=5, H=5, P=5 pour être généreux au corps à corps)
    local hitboxSize = GameConfig.Combat.HitboxSize or Vector3.new(5, 5, 5)
    local overlapParams = createHitboxParams(char)
    
    -- 🔴 APPARITION DE LA HITBOX VISUELLE (Tu vas voir le cube rouge en jeu !)
    drawDebugHitbox(hitboxCFrame, hitboxSize)
    
    local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams)
    local hitTargets = {} 
    local addXpEvent = ReplicatedStorage:WaitForChild("AddXPEvent")

    -- ⚔️ 4. ANALYSE DES IMPACTS
    for _, part in ipairs(partsInBox) do
        local targetModel = part:FindFirstAncestorOfClass("Model")
        
        if targetModel and not hitTargets[targetModel] and targetModel ~= char then
            local targetHumanoid = targetModel:FindFirstChild("Humanoid")
            
            if targetHumanoid and targetHumanoid.Health > 0 then
                hitTargets[targetModel] = true 
                
                print("💥 IMPACT VALIDÉ SUR :", targetModel.Name) -- LOG SERVEUR
                
                local attackerCombatLvl = char:GetAttribute("Combat_Level") or 1
                local targetResistLvl = targetModel:GetAttribute("Resistance_Level") or 1
                
                local rawDamage = (GameConfig.Combat.BaseDamage or 15) + (attackerCombatLvl * 0.5)
                local damageReduction = (targetResistLvl * 0.3)
                local finalDamage = math.max(1, rawDamage - damageReduction)
                
                targetHumanoid:TakeDamage(finalDamage)
                
                addXpEvent:Fire(char, "Combat", 15)
                addXpEvent:Fire(targetModel, "Resistance", 20)
                
                -- 🧠 ALERTE IA : Provoque la colère du PNJ
                if targetModel:GetAttribute("Hunger") then 
                    targetModel:SetAttribute("AggroTarget", player.Name)
                    targetModel:SetAttribute("AggroTime", os.clock())
                end
            end
        end
    end
end)