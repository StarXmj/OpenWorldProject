--[ Contrôleur de Combat Client ]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local attackEvent = ReplicatedStorage:WaitForChild("AttackEvent")
local player = Players.LocalPlayer

local lastClientAttack = 0
local punchAnimationTrack = nil -- On va stocker l'animation ici pour ne la charger qu'une fois

-- Fonction pour charger l'animation dans le personnage
local function loadAnimation()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator") -- L'Animator gère toutes les animations
    
    local anim = Instance.new("Animation")
    anim.AnimationId = GameConfig.Combat.PunchAnimId
    
    punchAnimationTrack = animator:LoadAnimation(anim)
end

-- On charge l'animation dès que le joueur apparaît
if player.Character then loadAnimation() end
player.CharacterAdded:Connect(loadAnimation)

-- Écoute du clic souris
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local currentTime = os.clock()
        
        if currentTime - lastClientAttack >= GameConfig.Combat.Cooldown then
            lastClientAttack = currentTime
            
            -- 1. On joue l'animation visuellement pour le joueur
            if punchAnimationTrack then
                punchAnimationTrack:Play()
            end
            
            -- 2. On dit au serveur de calculer les dégâts
            attackEvent:FireServer()
        end
    end
end)