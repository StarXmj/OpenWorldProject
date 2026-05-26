--[ IA Component : Animator (Mouvements & Sommeil) ]--
local Animator = {}
Animator.__index = Animator

function Animator.new(humanoid, gameConfig)
    local self = setmetatable({}, Animator)
    local animator = humanoid:WaitForChild("Animator")

    local function loadAnim(id, priority)
        local a = Instance.new("Animation") a.AnimationId = id
        local t = animator:LoadAnimation(a) t.Priority = priority
        return t
    end

    self.walk = loadAnim(gameConfig.NPC.WalkAnimId, Enum.AnimationPriority.Movement)
    self.grab = loadAnim(gameConfig.NPC.GrabAnimId, Enum.AnimationPriority.Action)
    self.punch = loadAnim(gameConfig.Combat.PunchAnimId, Enum.AnimationPriority.Action)
    
    -- 💤 Nouvelles Animations de Sommeil
    self.sleepAnims = {
        loadAnim("rbxassetid://137946006827250", Enum.AnimationPriority.Action),
        loadAnim("rbxassetid://97984033726444", Enum.AnimationPriority.Action)
    }
    self.currentSleep = nil

    humanoid.Running:Connect(function(speed)
        if speed > 0.1 then
            self:StopSleep() -- Auto-réveil si le PNJ est forcé de fuir !
            if not self.walk.IsPlaying then self.walk:Play() end
            self.walk:AdjustSpeed(speed / gameConfig.Entity.WalkSpeed)
        else
            if self.walk.IsPlaying then self.walk:Stop() end
        end
    end)

    return self
end

function Animator:PlaySleep()
    if self.currentSleep then return end
    self.currentSleep = self.sleepAnims[math.random(1, #self.sleepAnims)]
    self.currentSleep.Looped = true
    self.currentSleep:Play()
end

function Animator:StopSleep()
    if self.currentSleep then
        self.currentSleep:Stop()
        self.currentSleep = nil
    end
end

function Animator:PlayPunch() self.punch:Play() end
function Animator:PlayGrab() self.grab:Play() end

return Animator