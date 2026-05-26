--[ Contrôleur de Combat Client V2 (Poids et Animations) ]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local attackEvent = ReplicatedStorage:WaitForChild("AttackEvent")
local player = Players.LocalPlayer

local lastClientAttack = 0
local punchAnimationTrack = nil

local function loadAnimation()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    
    local anim = Instance.new("Animation")
    anim.AnimationId = GameConfig.Combat.PunchAnimId
    punchAnimationTrack = animator:LoadAnimation(anim)
end

if player.Character then loadAnimation() end
player.CharacterAdded:Connect(loadAnimation)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local currentTime = os.clock()
        
        -- Sécurité locale pour éviter le spam réseau
        if currentTime - lastClientAttack >= GameConfig.Combat.Cooldown then
            lastClientAttack = currentTime
            
            -- 1. Visuel : On joue l'animation
            if punchAnimationTrack then
                punchAnimationTrack:Play()
            end
            
            -- 2. Gameplay Kenshi : Lourdeur de l'attaque (Commitment)
            -- Le joueur est fortement ralenti pendant l'action pour donner du poids au coup
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                local baseWalkSpeed = hum.WalkSpeed
                
                -- On le ralentit de 70% pendant l'attaque
                hum.WalkSpeed = baseWalkSpeed * 0.3
                
                -- On lui rend sa vitesse à la fin de l'attaque
                task.delay(GameConfig.Combat.Cooldown, function()
                    if hum and hum.Parent and hum.Health > 0 then
                        -- S'il ne sprint pas, on réinitialise à la vitesse normale
                        if not char:GetAttribute("Stamina") or char:GetAttribute("Stamina") > 0 then
                            hum.WalkSpeed = GameConfig.Entity.WalkSpeed + (((char:GetAttribute("Athletics_Level") or 1) - 1) * 0.05)
                        end
                    end
                end)
            end
            
            -- 3. Réseau : On prévient le serveur que le Wind-Up commence !
            attackEvent:FireServer()
        end
    end
end)