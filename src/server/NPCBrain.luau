--[ Cerveau du PNJ V5 - IA Avancée (Combat, Fuite, Repos) ]--

local NPCBrain = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

function NPCBrain.Attach(npc)
    local humanoid = npc:WaitForChild("Humanoid")
    local root = npc:WaitForChild("HumanoidRootPart")
    
    humanoid.MaxHealth = GameConfig.Entity.MaxHealth
    humanoid.Health = GameConfig.Entity.MaxHealth
    npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
    npc:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
    npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
    
    -- 🌟 INITIALISATION DES STATS POUR LE PNJ
    local stats = {"Athletics", "Strength", "Combat", "Resistance"}
    for _, stat in ipairs(stats) do
        npc:SetAttribute(stat .. "_Level", 1)
        npc:SetAttribute(stat .. "_XP", 0)
    end
    local currentState = "WANDER"
    
    local animator = humanoid:WaitForChild("Animator")
    
    -- Animations
    local walkAnim = Instance.new("Animation")
    walkAnim.AnimationId = GameConfig.NPC.WalkAnimId
    local walkTrack = animator:LoadAnimation(walkAnim)
    walkTrack.Priority = Enum.AnimationPriority.Movement
    
    local grabAnim = Instance.new("Animation")
    grabAnim.AnimationId = GameConfig.NPC.GrabAnimId
    local grabTrack = animator:LoadAnimation(grabAnim)
    grabTrack.Priority = Enum.AnimationPriority.Action

    -- 🥊 NOUVEAU : Animation de Combat (On réutilise celle du joueur)
    local punchAnim = Instance.new("Animation")
    punchAnim.AnimationId = GameConfig.Combat.PunchAnimId
    local punchTrack = animator:LoadAnimation(punchAnim)
    punchTrack.Priority = Enum.AnimationPriority.Action
    
    humanoid.Running:Connect(function(speed)
        if speed > 0.1 then
            if not walkTrack.IsPlaying then walkTrack:Play() end
            walkTrack:AdjustSpeed(speed / GameConfig.Entity.WalkSpeed)
        else
            if walkTrack.IsPlaying then walkTrack:Stop() end
        end
    end)

    local function setThought(text)
        local thoughtGui = root:FindFirstChild("ThoughtGui")
        if thoughtGui and thoughtGui:FindFirstChild("ThoughtText") then thoughtGui.ThoughtText.Text = text end
    end

    local lastWanderTime = 0
    local lastRestTime = 0
    local lastAttackTime = 0

    task.spawn(function()
        while npc and npc.Parent and humanoid.Health > 0 do
            
            local currentHunger = npc:GetAttribute("Hunger")
            local currentThirst = npc:GetAttribute("Thirst")
            
            currentHunger = math.clamp(currentHunger - 0.08, 0, GameConfig.Entity.MaxHunger)
            currentThirst = math.clamp(currentThirst - 0.12, 0, GameConfig.Entity.MaxThirst)
            npc:SetAttribute("Hunger", currentHunger)
            npc:SetAttribute("Thirst", currentThirst)
            
            if currentHunger <= 0 then humanoid.Health -= (GameConfig.Survival.StarvationDamage / 25) end
            if currentThirst <= 0 then humanoid.Health -= (GameConfig.Survival.DehydrationDamage / 25) end
            
            -- 👁️ VÉRIFICATION DE L'AGGRO (Est-ce qu'on m'a frappé récemment ?)
            local aggroName = npc:GetAttribute("AggroTarget")
            local aggroTime = npc:GetAttribute("AggroTime") or 0
            local targetPlayer = nil
            
            -- L'IA garde sa rancune pendant 15 secondes
            if aggroName and os.clock() - aggroTime < 15 then
                local p = Players:FindFirstChild(aggroName)
                if p and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    targetPlayer = p.Character
                end
            end

            -- 🏆 NOUVELLE PYRAMIDE DES PRIORITÉS
            if targetPlayer then
                if humanoid.Health <= (humanoid.MaxHealth * 0.2) then
                    currentState = "FLEE" -- Moins de 20% de vie = Fuite !
                else
                    currentState = "COMBAT" -- Sinon = Bagarre !
                end
            elseif currentThirst <= (GameConfig.Entity.MaxThirst * 0.5) then
                currentState = "SEEK_WATER"
            elseif currentHunger <= (GameConfig.Entity.MaxHunger * 0.5) then
                currentState = "SEEK_FOOD"
            else
                -- Gestion naturelle de la flânerie et du repos
                if currentState == "REST" and os.clock() - lastRestTime < 6 then
                    currentState = "REST" -- Il reste assis/reposé pendant 6 secondes
                else
                    currentState = "WANDER"
                    -- 1 chance sur 20 de faire une pause toutes les 0.2s
                    if math.random(1, 20) == 1 then
                        currentState = "REST"
                        lastRestTime = os.clock()
                    end
                end
            end
            
            -- ⚡ GESTION DES VITESSES ET ENDURANCE
            
            -- ⚡ GESTION DES VITESSES, ENDURANCE ET XP
            local currentStamina = npc:GetAttribute("Stamina")
            local athleticsLvl = npc:GetAttribute("Athletics_Level") or 1
            local speedBonus = (athleticsLvl - 1) * 0.05
            
            if currentState == "WANDER" then
                humanoid.WalkSpeed = 6 + speedBonus
                npc:SetAttribute("Stamina", math.clamp(currentStamina + 1.5, 0, GameConfig.Entity.MaxStamina))
            elseif currentState == "REST" then
                humanoid.WalkSpeed = 0
                npc:SetAttribute("Stamina", math.clamp(currentStamina + 4, 0, GameConfig.Entity.MaxStamina))
            else
                if currentStamina > 0 then
                    humanoid.WalkSpeed = GameConfig.Entity.SprintSpeed + speedBonus
                    npc:SetAttribute("Stamina", math.clamp(currentStamina - 0.8, 0, GameConfig.Entity.MaxStamina))
                    
                    -- 🌟 LE PNJ GAGNE DE L'ATHLÉTISME EN SPRINTANT !
                    local addXpEvent = ReplicatedStorage:FindFirstChild("AddXPEvent")
                    if addXpEvent then addXpEvent:Fire(npc, "Athletics", 0.5) end
                else
                    humanoid.WalkSpeed = GameConfig.Entity.WalkSpeed + speedBonus
                end
            end
            
            -- 🛠️ ACTIONS SELON L'ÉTAT
            if currentState == "COMBAT" then
                local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (targetRoot.Position - root.Position).Magnitude
                    if dist <= GameConfig.Combat.AttackRange then
                        humanoid:MoveTo(root.Position) -- S'arrête pour frapper
                        if os.clock() - lastAttackTime >= GameConfig.Combat.Cooldown then
                            lastAttackTime = os.clock()
                            setThought("😡 Tiens ça !")
                            punchTrack:Play()
                            targetPlayer.Humanoid:TakeDamage(GameConfig.Combat.BaseDamage)
                        end
                    else
                        setThought("🤬 Reviens là !")
                        humanoid:MoveTo(targetRoot.Position)
                    end
                end
                
            elseif currentState == "FLEE" then
                local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    setThought("😱 Laissez-moi !")
                    -- Calcul mathématique pour courir dans la direction strictement OPPOSE au joueur
                    local fleeDir = (root.Position - targetRoot.Position).Unit
                    humanoid:MoveTo(root.Position + fleeDir * 30)
                end

            elseif currentState == "REST" then
                setThought("😌 Petite pause...")
                humanoid:MoveTo(root.Position)

            elseif currentState == "SEEK_WATER" then
                local closestWater = nil
                local minWaterDist = math.huge
                local folder = workspace:FindFirstChild("WaterWaypoints")
                
                if folder then
                    for _, wp in ipairs(folder:GetChildren()) do
                        local dist = (wp.Position - root.Position).Magnitude
                        if dist < minWaterDist then
                            minWaterDist = dist
                            closestWater = wp
                        end
                    end
                end
                
                if closestWater then
                    if minWaterDist <= 6 then
                        humanoid:MoveTo(root.Position)
                        setThought("💧 Glou glou...")
                        grabTrack:Play()
                        task.wait(1)
                        npc:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
                    else
                        setThought("🥵 Soif...")
                        humanoid:MoveTo(closestWater.Position)
                    end
                else
                    setThought("🏜️ Tout est sec...")
                    humanoid:MoveTo(root.Position + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15)))
                end

            elseif currentState == "SEEK_FOOD" then
                local closestFood = nil
                local minDistance = math.huge
                
                for _, object in ipairs(workspace:GetChildren()) do
                    if object.Name == "BerryDrop" then 
                        local distance = (object.Position - root.Position).Magnitude
                        if distance < minDistance then
                            minDistance = distance
                            closestFood = object
                        end
                    end
                end
                
                if closestFood and closestFood.Parent ~= nil then
                    if minDistance <= 4 then
                        closestFood.Parent = nil 
                        closestFood:Destroy()
                        humanoid:MoveTo(root.Position)
                        setThought("🫐 Miam !")
                        grabTrack:Play() 
                        task.wait(0.5)   
                        npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
                    else
                        setThought("👀 Une baie !")
                        humanoid:MoveTo(closestFood.Position)
                    end
                else
                    setThought("🍗 Faim...")
                    humanoid:MoveTo(root.Position + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15)))
                end
                
            elseif currentState == "WANDER" then
                setThought("💭 C'est calme.")
                if os.clock() - lastWanderTime > 4 or humanoid.MoveDirection.Magnitude < 0.1 then
                    lastWanderTime = os.clock()
                    humanoid:MoveTo(root.Position + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15)))
                end
            end
            
            task.wait(0.2) 
        end
    end)
end

return NPCBrain