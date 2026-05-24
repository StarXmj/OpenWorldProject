--[ Gestionnaire de Combat Serveur ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- 1. PONT DE COMMUNICATION
local attackEvent = Instance.new("RemoteEvent")
attackEvent.Name = "AttackEvent"
attackEvent.Parent = ReplicatedStorage

-- 2. SYSTÈME ANTI-SPAM (Cooldown)
local lastAttackTimes = {} -- Mémorise quand le joueur a frappé pour la dernière fois

attackEvent.OnServerEvent:Connect(function(player)
    local currentTime = os.clock()
    local lastAttack = lastAttackTimes[player] or 0
    
    -- Si le joueur frappe trop vite, on annule l'attaque (Anti-triche)
    if currentTime - lastAttack < GameConfig.Combat.Cooldown then return end
    lastAttackTimes[player] = currentTime

    -- 3. VÉRIFICATION DE L'ATTAQUE
    local char = player.Character
    if not char then return end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- On cherche qui frapper dans le monde (Zone d'Effet)
    for _, object in ipairs(workspace:GetChildren()) do
        -- On ignore le joueur lui-même
        if object ~= char and object:FindFirstChild("Humanoid") then
            local targetRoot = object:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = object:FindFirstChild("Humanoid")
            
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                
                -- Calcul de la distance
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                
                if distance <= GameConfig.Combat.AttackRange then
                    
                    -- Mathématiques avancées : Vérifier si l'ennemi est DEVANT le joueur (et pas dans son dos)
                    local directionToTarget = (targetRoot.Position - rootPart.Position).Unit
                    local lookVector = rootPart.CFrame.LookVector
                    local angle = directionToTarget:Dot(lookVector) -- Produit scalaire
                    
                    if angle > 0.4 then -- 0.4 correspond à un large cône devant le joueur
                        -- COUP AU BUT !
                        targetHumanoid:TakeDamage(GameConfig.Combat.BaseDamage)
                        print(player.Name .. " a frappé " .. object.Name .. " pour " .. GameConfig.Combat.BaseDamage .. " dégâts !")
                        
                        -- On pourrait rajouter un effet de sang ou un son ici plus tard
                    end
                end
            end
        end
    end
end)