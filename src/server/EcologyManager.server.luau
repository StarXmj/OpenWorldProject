--[ Gestionnaire d'Écologie (Nature Organique) ]--
-- Ce script rend la flore vivante. Les buissons s'épuisent et repoussent au fil des jours.

local CollectionService = game:GetService("CollectionService")

local RECOVERY_TIME = 120 -- Temps en secondes pour qu'un buisson repousse
local MAX_FRUITS = 3

-- Fonction pour initialiser un buisson
local function initBush(bush)
    bush:SetAttribute("Fruits", MAX_FRUITS)
    bush:SetAttribute("RegrowthTimer", 0)
    
    -- Optionnel : Changer la couleur selon l'état
    if bush:IsA("BasePart") then
        bush.Color = Color3.fromRGB(34, 139, 34) -- Vert forêt vif
    end
end

-- On cherche tous les buissons de la map
local folder = workspace:FindFirstChild("Flora") or workspace
for _, object in ipairs(folder:GetChildren()) do
    if object.Name == "BerryBush" then
        initBush(object)
    end
end

-- La boucle de la Nature
task.spawn(function()
    while true do
        task.wait(5) -- La nature prend son temps (vérification toutes les 5 secondes)
        
        for _, object in ipairs(folder:GetChildren()) do
            if object.Name == "BerryBush" then
                local fruits = object:GetAttribute("Fruits") or 0
                
                -- Si le buisson est vide, la nature commence son travail
                if fruits < MAX_FRUITS then
                    local timer = (object:GetAttribute("RegrowthTimer") or 0) + 5
                    
                    if timer >= RECOVERY_TIME then
                        -- Le buisson a repoussé !
                        object:SetAttribute("Fruits", MAX_FRUITS)
                        object:SetAttribute("RegrowthTimer", 0)
                        if object:IsA("BasePart") then object.Color = Color3.fromRGB(34, 139, 34) end
                    else
                        object:SetAttribute("RegrowthTimer", timer)
                        if object:IsA("BasePart") then object.Color = Color3.fromRGB(107, 142, 35) end -- Vert terne/épuisé
                    end
                end
            end
        end
    end
end)