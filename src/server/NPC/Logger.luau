--[ IA Component : Logger (Bulles 3D & Attributs Debug) ]--
local Logger = {}

function Logger.log(npc, state, thought)
    local attachmentPart = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
    if not attachmentPart then return end
    
    local gui = attachmentPart:FindFirstChild("ThoughtGui")
    if not gui then
        gui = Instance.new("BillboardGui")
        gui.Name = "ThoughtGui"
        gui.Size = UDim2.new(0, 150, 0, 40)
        gui.StudsOffset = Vector3.new(0, 2, 0) 
        gui.AlwaysOnTop = true
        gui.MaxDistance = 80 
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "ThoughtText"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0.2 
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Parent = gui
        
        gui.Parent = attachmentPart
    end
    
    gui.ThoughtText.Text = thought
    
    -- ⚙️ On stocke l'action immédiate pour le Panel Admin
    npc:SetAttribute("Debug_Action", thought)
end

return Logger