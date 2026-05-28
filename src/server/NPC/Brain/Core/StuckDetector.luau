local StuckDetector = {}
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

function StuckDetector.Check(npc, root, humanoid, context, now)
    if context.isActuallySleeping then return end

    if now - context.lastStuckCheckTime >= 2.5 then
        local movedDist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(context.lastStuckCheckPos.X, 0, context.lastStuckCheckPos.Z)).Magnitude
        
        if humanoid.MoveDirection.Magnitude > 0.1 and movedDist < 1.5 then
            context.stuckWarnings += 1
            if context.stuckWarnings == 2 then 
                CoreLogger.ai(npc.Name, "⚠️ Bloqué physiquement ! Tentative d'escalade...") 
            end
        else
            context.stuckWarnings = 0
        end
        
        context.lastStuckCheckPos = root.Position
        context.lastStuckCheckTime = now
    end
end

return StuckDetector