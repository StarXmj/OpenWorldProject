--[ Cerveau du PNJ V2 - Fluide et intelligent ]--

local NPCBrain = {}
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

function NPCBrain.Attach(npc)
    local humanoid = npc:WaitForChild("Humanoid")
    local root = npc:WaitForChild("HumanoidRootPart")
    
    npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
    npc:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
    local currentState = "WANDER"
    
    local animator = humanoid:WaitForChild("Animator")
    
    local walkAnim = Instance.new("Animation")
    walkAnim.AnimationId = GameConfig.NPC.WalkAnimId
    local walkTrack = animator:LoadAnimation(walkAnim)
    walkTrack.Priority = Enum.AnimationPriority.Movement
    
    local grabAnim = Instance.new("Animation")
    grabAnim.AnimationId = GameConfig.NPC.GrabAnimId
    local grabTrack = animator:LoadAnimation(grabAnim)
    grabTrack.Priority = Enum.AnimationPriority.Action
    
    humanoid.Running:Connect(function(speed)
        if speed > 0.1 then
            if not walkTrack.IsPlaying then walkTrack:Play() end
        else
            if walkTrack.IsPlaying then walkTrack:Stop() end
        end
    end)

    local function setThought(text)
        local thoughtGui = root:FindFirstChild("ThoughtGui")
        if thoughtGui and thoughtGui:FindFirstChild("ThoughtText") then
            thoughtGui.ThoughtText.Text = text
        end
    end

    local lastWanderTime = 0 -- Pour éviter qu'ils changent de direction en permanence

    task.spawn(function()
        -- NOUVEAU : La boucle tourne à 0.2s pour des mouvements hyper fluides
        while npc and npc.Parent and humanoid.Health > 0 do
            
            local currentHunger = npc:GetAttribute("Hunger")
            -- On baisse la faim de 0.4 (car ça tourne 5x par seconde, ce qui fait 2 par seconde)
            currentHunger = math.clamp(currentHunger - 0.4, 0, GameConfig.Entity.MaxHunger)
            npc:SetAttribute("Hunger", currentHunger)
            
            if currentHunger <= (GameConfig.Entity.MaxHunger * 0.5) then
                currentState = "SEEK_FOOD"
            else
                currentState = "WANDER"
            end
            
            if currentState == "SEEK_FOOD" then
                local closestFood = nil
                local minDistance = math.huge
                
                for _, object in ipairs(workspace:GetChildren()) do
                    if object.Name == "TestFood" then
                        local distance = (object.Position - root.Position).Magnitude
                        if distance < minDistance then
                            minDistance = distance
                            closestFood = object
                        end
                    end
                end
                
                if closestFood then
                    -- CORRECTION DU BLOCAGE : La pomme a-t-elle été mangée par un autre PNJ ?
                    if closestFood.Parent == nil then
                        -- Oui, elle a été volée. On abandonne et on cherchera une autre pomme au prochain tour.
                        closestFood = nil
                    else
                        if minDistance <= 4 then
                            closestFood.Parent = nil 
                            closestFood:Destroy()
                            
                            humanoid:MoveTo(root.Position) 
                            setThought("🍎 Miam !")
                            grabTrack:Play() 
                            task.wait(0.5)   
                            
                            npc:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
                        else
                            setThought("👀 Une pomme là-bas !")
                            local path = PathfindingService:CreatePath({AgentCanJump = true})
                            path:ComputeAsync(root.Position, closestFood.Position)
                            
                            if path.Status == Enum.PathStatus.Success then
                                local waypoints = path:GetWaypoints()
                                if #waypoints >= 2 then 
                                    humanoid:MoveTo(waypoints[2].Position) 
                                end
                            else
                                -- S'il n'y a pas d'obstacles complexes, il y va en ligne droite (évite les saccades)
                                humanoid:MoveTo(closestFood.Position)
                            end
                        end
                    end
                else
                    setThought("🍗 J'ai tellement faim...")
                    -- Il marche aléatoirement pour chercher à manger
                    if os.clock() - lastWanderTime > 3 or humanoid.MoveDirection.Magnitude < 0.1 then
                        lastWanderTime = os.clock()
                        humanoid:MoveTo(root.Position + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15)))
                    end
                end
                
            elseif currentState == "WANDER" then
                setThought("💭 C'est calme ici.")
                -- Ne change de direction que toutes les 4 secondes, pour marcher droit et fluidement
                if os.clock() - lastWanderTime > 4 or humanoid.MoveDirection.Magnitude < 0.1 then
                    lastWanderTime = os.clock()
                    local randomTarget = root.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
                    humanoid:MoveTo(randomTarget)
                end
            end
            
            task.wait(0.2) 
        end
    end)
end

return NPCBrain