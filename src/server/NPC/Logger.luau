--[ IA Component : Logger (Bulles de pensée uniques) ]--
local Logger = {}

function Logger.log(npc, state, thought)
    -- On l'attache à la Tête (ou au Torse si pas de tête)
    local attachmentPart = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
    if not attachmentPart then return end
    
    -- Si la bulle n'existe pas encore pour ce PNJ, le script la crée !
    local gui = attachmentPart:FindFirstChild("ThoughtGui")
    if not gui then
        gui = Instance.new("BillboardGui")
        gui.Name = "ThoughtGui"
        gui.Size = UDim2.new(0, 150, 0, 40)
        gui.StudsOffset = Vector3.new(0, 2, 0) -- Flotte à 2 studs au-dessus de la tête
        gui.AlwaysOnTop = true
        gui.MaxDistance = 80 -- Disparaît si on est à plus de 80 mètres
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "ThoughtText"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0.2 -- Contour noir pour bien lire
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Parent = gui
        
        gui.Parent = attachmentPart
    end
    
    -- Met à jour le texte unique du PNJ
    gui.ThoughtText.Text = thought
    
    -- J'ai retiré le `print()` de la console F9. Fini le spam !
end

return Logger