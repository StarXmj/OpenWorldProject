--[ IA Component : Navigator (Lissage Trajectoire, Anti-Spam & Sleep Lock) ]--
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreLogger = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CoreLogger"))

local Navigator = {}
Navigator.__index = Navigator

function Navigator.new(npc)
    local self = setmetatable({}, Navigator)
    self.npc = npc
    self.humanoid = npc:WaitForChild("Humanoid")
    self.root = npc:WaitForChild("HumanoidRootPart")
    
    self.pathParams = { 
        AgentRadius = 1.5, 
        AgentHeight = 5, 
        AgentCanJump = true, 
        WaypointSpacing = 4 
    }
    self.path = PathfindingService:CreatePath(self.pathParams)
    
    self.waypoints = {}
    self.currentWaypointIndex = 1
    self.lastPathTarget = nil
    self.pathComputeCooldown = 0
    self.lastJumpTime = 0
    
    self.exploreAngle = math.random() * math.pi * 2 
    self.isLockedForSleep = false
    
    self.losParams = RaycastParams.new()
    self.losParams.FilterType = Enum.RaycastFilterType.Exclude
    self.losParams.FilterDescendantsInstances = {npc}
    
    return self
end

function Navigator:GetDirectionalWanderTarget(distance)
    if math.random(1, 100) <= 15 then
        self.exploreAngle = self.exploreAngle + math.rad(math.random(90, 270))
    else
        self.exploreAngle = self.exploreAngle + math.rad(math.random(-20, 20))
    end
    
    local dirX = math.cos(self.exploreAngle)
    local dirZ = math.sin(self.exploreAngle)
    local dir = Vector3.new(dirX, 0, dirZ)
    
    for i = 1, 5 do
        local target = self.root.Position + (dir * distance) + Vector3.new(0, 150, 0)
        local ray = workspace:Raycast(target, Vector3.new(0, -300, 0), self.losParams)
        
        if ray and ray.Material ~= Enum.Material.Water then 
            return ray.Position 
        end
        
        self.exploreAngle = self.exploreAngle + (math.pi / 2)
        dirX = math.cos(self.exploreAngle)
        dirZ = math.sin(self.exploreAngle)
        dir = Vector3.new(dirX, 0, dirZ)
    end
    
    return self.root.Position
end

function Navigator:SmartMoveTo(targetPos)
    if self.isLockedForSleep then return end
    
    local now = os.clock()
    
    -- 🦘 RÉFLEXE D'ESCALADE ADOUCI (Empêche de spammer le saut)
    if now - self.lastJumpTime > 1.5 then
        local rayPos = self.root.Position + Vector3.new(0, -1.5, 0)
        local fwdRay = workspace:Raycast(rayPos, self.root.CFrame.LookVector * 2.5, self.losParams)
        if fwdRay and fwdRay.Instance.CanCollide and fwdRay.Material ~= Enum.Material.Water then
            self.humanoid.Jump = true
            self.lastJumpTime = now
        end
    end

    -- 🧭 RECALCUL INTELLIGENT (Pas de spam de Pathfinding)
    if not self.lastPathTarget or (self.lastPathTarget - targetPos).Magnitude > 5 or now > self.pathComputeCooldown then
        local success, _ = pcall(function() self.path:ComputeAsync(self.root.Position, targetPos) end)
        if success and self.path.Status == Enum.PathStatus.Success then
            self.waypoints = self.path:GetWaypoints()
            self.currentWaypointIndex = 2
            
            -- 🚶‍♂️ LISSAGE : On ignore les waypoints trop proches pour éviter les pirouettes
            while self.waypoints[self.currentWaypointIndex] do
                local wpPos = self.waypoints[self.currentWaypointIndex].Position
                local dist = (Vector3.new(wpPos.X, 0, wpPos.Z) - Vector3.new(self.root.Position.X, 0, self.root.Position.Z)).Magnitude
                if dist < 3.5 then
                    self.currentWaypointIndex += 1
                else
                    break
                end
            end
            
            self.lastPathTarget = targetPos
            self.pathComputeCooldown = now + 1.5
            CoreLogger.ai(self.npc.Name, "Path generated successfully. Movement smoothing active.")
        else
            CoreLogger.ai(self.npc.Name, "Path blocked → Recalculating fallback logic")
            self.humanoid:MoveTo(targetPos)
            self.pathComputeCooldown = now + 2
            return
        end
    end

    if self.waypoints and self.currentWaypointIndex <= #self.waypoints then
        local wp = self.waypoints[self.currentWaypointIndex]
        local flatRoot = Vector3.new(self.root.Position.X, 0, self.root.Position.Z)
        local flatWp = Vector3.new(wp.Position.X, 0, wp.Position.Z)
        
        if (flatRoot - flatWp).Magnitude < 3 then
            self.currentWaypointIndex += 1
            if self.currentWaypointIndex <= #self.waypoints then wp = self.waypoints[self.currentWaypointIndex] else return end
        end

        if wp.Action == Enum.PathWaypointAction.Jump and now - self.lastJumpTime > 1.5 then 
            self.humanoid.Jump = true 
            self.lastJumpTime = now
        end
        self.humanoid:MoveTo(wp.Position)
    else
        self.humanoid:MoveTo(targetPos)
    end
end

function Navigator:Stop()
    self.waypoints = {} self.lastPathTarget = nil
    if not self.isLockedForSleep then
        self.humanoid:MoveTo(self.root.Position)
    end
end

-- 💤 NOUVEAU : VERROUILLAGE PHYSIQUE TOTAL
function Navigator:LockForSleep()
    if self.isLockedForSleep then return end
    self.isLockedForSleep = true
    self:Stop()
    self.root.Anchored = true
    self.humanoid.AutoRotate = false
    CoreLogger.ai(self.npc.Name, "Navigation disabled during sleep. Humanoid jump disabled.")
end

function Navigator:UnlockFromSleep()
    if not self.isLockedForSleep then return end
    self.isLockedForSleep = false
    self.root.Anchored = false
    self.humanoid.AutoRotate = true
    CoreLogger.ai(self.npc.Name, "Waking up. Physics and navigation restored.")
end

function Navigator:HasLineOfSight(targetPlayer, distance)
    local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    
    local ray = workspace:Raycast(self.root.Position, (targetRoot.Position - self.root.Position).Unit * distance, self.losParams)
    return not ray or (ray.Instance and ray.Instance:IsDescendantOf(targetPlayer))
end

return Navigator