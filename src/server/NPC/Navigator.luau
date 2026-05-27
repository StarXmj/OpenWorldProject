--[ IA Component : Navigator (Déplacement & Pathfinding AAA) ]--
local PathfindingService = game:GetService("PathfindingService")

local Navigator = {}
Navigator.__index = Navigator

function Navigator.new(npc)
    local self = setmetatable({}, Navigator)
    self.npc = npc
    self.humanoid = npc:WaitForChild("Humanoid")
    self.root = npc:WaitForChild("HumanoidRootPart")
    
    -- 🛑 CORRECTION EAU : Le coût de l'eau passe à 100 000 ! L'IA refusera catégoriquement d'y entrer.
    self.pathParams = { 
        AgentRadius = 2, 
        AgentHeight = 5, 
        AgentCanJump = true, 
        WaypointSpacing = 4, 
        Costs = { Water = 100000 } 
    }
    self.path = PathfindingService:CreatePath(self.pathParams)
    
    self.waypoints = {}
    self.currentWaypointIndex = 1
    self.lastPathTarget = nil
    self.pathComputeCooldown = 0
    
    self.losParams = RaycastParams.new()
    self.losParams.FilterType = Enum.RaycastFilterType.Exclude
    self.losParams.FilterDescendantsInstances = {npc}
    
    return self
end

function Navigator:GetSafeWanderTarget()
    for i = 1, 3 do 
        local rx, rz = math.random(-25, 25), math.random(-25, 25)
        local target = self.root.Position + Vector3.new(rx, 50, rz) 
        local ray = workspace:Raycast(target, Vector3.new(0, -100, 0), self.losParams)
        -- Vérifie qu'il ne choisit pas une destination dans l'eau
        if ray and ray.Material ~= Enum.Material.Water then return ray.Position end
    end
    return self.root.Position 
end

function Navigator:SmartMoveTo(targetPos)
    local now = os.clock()
    if not self.lastPathTarget or (self.lastPathTarget - targetPos).Magnitude > 5 or now > self.pathComputeCooldown then
        local success, _ = pcall(function() self.path:ComputeAsync(self.root.Position, targetPos) end)
        if success and self.path.Status == Enum.PathStatus.Success then
            self.waypoints = self.path:GetWaypoints()
            self.currentWaypointIndex = 2
            self.lastPathTarget = targetPos
            self.pathComputeCooldown = now + 1
        else
            self.humanoid:MoveTo(targetPos) return
        end
    end

    if self.waypoints and self.currentWaypointIndex <= #self.waypoints then
        local wp = self.waypoints[self.currentWaypointIndex]
        local flatRoot = Vector3.new(self.root.Position.X, 0, self.root.Position.Z)
        local flatWp = Vector3.new(wp.Position.X, 0, wp.Position.Z)
        
        if (flatRoot - flatWp).Magnitude < 4 then
            self.currentWaypointIndex += 1
            if self.currentWaypointIndex <= #self.waypoints then wp = self.waypoints[self.currentWaypointIndex] else return end
        end

        if wp.Action == Enum.PathWaypointAction.Jump then self.humanoid.Jump = true end
        self.humanoid:MoveTo(wp.Position)
    else
        self.humanoid:MoveTo(targetPos)
    end
end

function Navigator:Stop()
    self.waypoints = {} self.lastPathTarget = nil
    self.humanoid:MoveTo(self.root.Position)
end

function Navigator:HasLineOfSight(targetPlayer, distance)
    local targetRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    
    local ray = workspace:Raycast(self.root.Position, (targetRoot.Position - self.root.Position).Unit * distance, self.losParams)
    return not ray or (ray.Instance and ray.Instance:IsDescendantOf(targetPlayer))
end

return Navigator