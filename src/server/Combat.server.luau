local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Weapons = require(RS.Shared.Weapons)
local Rules = require(RS.Shared.Rules)
local remotes = Instance.new("Folder")
remotes.Name = "Combat"
local function remote(name)
    local e = Instance.new("RemoteEvent")
    e.Name, e.Parent = name, remotes
    return e
end
local action, stateEvent, effect, matchEvent, notice = remote("Action"), remote("State"), remote("Effect"), remote("Match"), remote("Notice")
remotes.Parent = RS
local teams = {}
for name, color in {Rose = BrickColor.new("Hot pink"), Aqua = BrickColor.new("Cyan")} do
    local team = Instance.new("Team")
    team.Name, team.TeamColor, team.AutoAssignable = name, color, false
    team.Parent = Teams
    teams[name] = team
end
local palettes = {Color3.fromRGB(255, 110, 195), Color3.fromRGB(110, 230, 255), Color3.fromRGB(210, 160, 255), Color3.fromRGB(255, 215, 100)}
local states = {}
local random = Random.new()
local match = {phase = "WARMUP", seconds = 10, rose = 0, aqua = 0, owner = "Neutral", progress = 0, status = "EMPTY", winner = ""}
local function sync(player, hit)
    local s = states[player]
    if not s then return end
    stateEvent:FireClient(player, {weapon = s.weapon, ammo = s.ammo[s.weapon], reloading = s.reloading, shield = s.shield, dash = math.max(0, s.lastDash + 3 - os.clock()), pulse = math.max(0, s.lastPulse + 12 - os.clock()), palette = s.palette, hit = hit})
end
local function alive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    return h and h.Health > 0 and r ~= nil, c, h, r
end
local function style(player)
    local s, c = states[player], player.Character
    if not s or not c then return end
    local highlight = c:FindFirstChild("PrismStyle") or Instance.new("Highlight")
    highlight.Name, highlight.Adornee = "PrismStyle", c
    highlight.FillTransparency, highlight.OutlineTransparency = 1, 0.35
    highlight.OutlineColor, highlight.Parent = palettes[s.palette], c
end
local function setup(player)
    local countRose, countAqua = #teams.Rose:GetPlayers(), #teams.Aqua:GetPlayers()
    player.Team = countRose <= countAqua and teams.Rose or teams.Aqua
    player:SetAttribute("Palette", 1)
    local stats = Instance.new("Folder")
    stats.Name, stats.Parent = "leaderstats", player
    for _, name in {"Eliminations", "StylePoints"} do
        local v = Instance.new("IntValue")
        v.Name, v.Parent = name, stats
    end
    local function spawn(character)
        local humanoid = character:WaitForChild("Humanoid")
        local root = character:WaitForChild("HumanoidRootPart")
        if player.Character ~= character then return end
        local s = {weapon = "Bloom", ammo = {}, reloading = false, lastShot = -10, lastDash = -10, lastPulse = -20, tokens = 12, lastToken = os.clock(), shield = 50, lastDamage = os.clock(), palette = player:GetAttribute("Palette") or 1}
        for _, name in Weapons.Order do s.ammo[name] = Weapons[name].magazine end
        states[player] = s
        humanoid.WalkSpeed = 20
        root.CFrame = CFrame.new(random:NextNumber(-12, 12), 5, player.Team == teams.Rose and -85 or 85) * CFrame.Angles(0, player.Team == teams.Rose and math.pi or 0, 0)
        style(player)
        sync(player)
        matchEvent:FireClient(player, match)
    end
    player.CharacterAdded:Connect(spawn)
    if player.Character then task.spawn(spawn, player.Character) end
end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(p) states[p] = nil end)
for _, p in Players:GetPlayers() do setup(p) end
local function damage(attacker, humanoid, amount)
    local victim = Players:GetPlayerFromCharacter(humanoid.Parent)
    if humanoid.Health <= 0 or humanoid.Parent:FindFirstChildOfClass("ForceField") then return false end
    if attacker and victim and (attacker == victim or attacker.Team == victim.Team) then return false end
    if victim then
        local s = states[victim]
        if s then
            s.shield, amount = Rules.absorb(s.shield, amount)
            s.lastDamage = os.clock()
            sync(victim)
            notice:FireClient(victim, "DAMAGE", "")
        end
    end
    local previous = humanoid.Health
    humanoid:TakeDamage(amount)
    if attacker and previous > 0 and humanoid.Health <= 0 then
        attacker.leaderstats.Eliminations.Value += 1
        attacker.leaderstats.StylePoints.Value += victim and 100 or 25
        notice:FireAllClients("FEED", attacker.DisplayName .. " eliminated " .. (victim and victim.DisplayName or "a drone"))
    end
    return true
end
local function validDirection(d)
    return typeof(d) == "Vector3" and d.X == d.X and d.Y == d.Y and d.Z == d.Z and d.Magnitude > 0.99 and d.Magnitude < 1.01
end
action.OnServerEvent:Connect(function(player, command, direction, aiming)
    local s = states[player]
    local live, character, _, root = alive(player)
    if not s or not live then return end
    local now = os.clock()
    s.tokens = math.min(12, s.tokens + (now - s.lastToken) * 24)
    s.lastToken = now
    if s.tokens < 1 then return end
    s.tokens -= 1
    local w = Weapons[s.weapon]
    if command == "Sync" then sync(player); matchEvent:FireClient(player, match)
    elseif command == "Palette" then
        s.palette = s.palette % #palettes + 1
        player:SetAttribute("Palette", s.palette)
        style(player); sync(player)
    elseif command == "Switch" and not s.reloading then
        local index = table.find(Weapons.Order, s.weapon)
        s.weapon = Weapons.Order[index % #Weapons.Order + 1]
        sync(player)
    elseif command == "Reload" and not s.reloading and s.ammo[s.weapon] < w.magazine then
        s.reloading = true
        local name = s.weapon
        sync(player)
        task.delay(w.reload, function()
            if states[player] ~= s then return end
            s.ammo[name], s.reloading = w.magazine, false
            sync(player)
        end)
    elseif command == "Dash" and now - s.lastDash >= 3 then
        s.lastDash = now
        local move = character:FindFirstChildOfClass("Humanoid").MoveDirection
        local d = move.Magnitude > 0.1 and move.Unit or root.CFrame.LookVector
        local params = RaycastParams.new()
        params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {character}
        local obstruction = workspace:Raycast(root.Position, d * 12, params)
        local distance = obstruction and math.max(0, obstruction.Distance - 3) or 12
        root.CFrame += d * distance
        sync(player)
    elseif command == "Pulse" and now - s.lastPulse >= 12 then
        s.lastPulse = now
        s.shield = math.min(50, s.shield + 25)
        for _, other in Players:GetPlayers() do
            local ok, _, _, otherRoot = alive(other)
            if ok and other.Team == player.Team and (otherRoot.Position - root.Position).Magnitude <= 25 and states[other] then
                states[other].shield = math.min(50, states[other].shield + (other == player and 0 or 25))
                sync(other)
            end
        end
        effect:FireAllClients("Pulse", root.Position, root.Position, s.weapon)
        sync(player)
    elseif command == "Fire" then
        if match.phase == "RESULTS" or s.reloading or s.ammo[s.weapon] <= 0 or now - s.lastShot < w.interval or not validDirection(direction) then return end
        local head = character:FindFirstChild("Head")
        if not head then return end
        s.lastShot, s.ammo[s.weapon] = now, s.ammo[s.weapon] - 1
        local params = RaycastParams.new()
        params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {character}
        local origin, base = head.Position, CFrame.lookAt(Vector3.zero, direction)
        local hit = false
        for _ = 1, w.pellets do
            local spread = math.rad(w.spread * (aiming == true and 0.35 or 1) * (root.AssemblyLinearVelocity.Magnitude > 5 and 1.6 or 1))
            local ray = (base * CFrame.Angles(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), 0)).LookVector * w.range
            local result = workspace:Raycast(origin, ray, params)
            if result then
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                local h = model and model:FindFirstChildOfClass("Humanoid")
                if h then hit = damage(player, h, w.damage * (result.Instance.Name == "Head" and w.headMultiplier or 1)) or hit end
            end
            effect:FireAllClients("Shot", origin, result and result.Position or origin + ray, s.weapon)
        end
        sync(player, hit)
    end
end)
local arena = workspace:WaitForChild("PrismArena")
local drones = arena:WaitForChild("Drones")
-- Training drones orbit the objective, shoot visible players, and respawn.
for _, drone in drones:GetChildren() do
    local template = drone:Clone()
    local function bind(model)
        model.Humanoid.Died:Connect(function()
            task.delay(5, function()
                if not model.Parent then return end
                model:Destroy()
                local replacement = template:Clone()
                replacement.Parent = drones
                bind(replacement)
            end)
        end)
    end
    bind(drone)
end
task.spawn(function()
    while true do
        task.wait(0.15)
        if match.phase == "RESULTS" then continue end
        local solo = #Players:GetPlayers() < 2
        for _, drone in drones:GetChildren() do
            local h, root = drone:FindFirstChildOfClass("Humanoid"), drone.PrimaryPart
            if not h or h.Health <= 0 or not root then continue end
            local i = drone:GetAttribute("Index")
            local angle = os.clock() * 0.22 + i * math.pi / 2
            local point = Vector3.new(math.cos(angle) * 35, 5 + math.sin(angle * 2), math.sin(angle) * 35)
            drone:PivotTo(CFrame.lookAt(point, Vector3.new(0, 5, 0)))
            if solo and random:NextNumber() < 0.1 then
                for _, p in Players:GetPlayers() do
                    local ok, c, humanoid, playerRoot = alive(p)
                    if not ok or (playerRoot.Position - point).Magnitude > 80 then continue end
                    local params = RaycastParams.new()
                    params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {drone}
                    local hit = workspace:Raycast(point, playerRoot.Position - point, params)
                    if hit and hit.Instance:IsDescendantOf(c) then
                        damage(nil, humanoid, 5)
                        effect:FireAllClients("Shot", point, playerRoot.Position, "Glimmer")
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        for p, s in states do
            local ok = alive(p)
            if ok and os.clock() - s.lastDamage >= 5 then s.shield = math.min(50, s.shield + 8) end
            sync(p)
        end
        if #Players:GetPlayers() == 0 then continue end
        match.seconds -= 1
        if match.phase == "LIVE" then
            local rose, aqua = 0, 0
            for _, p in Players:GetPlayers() do
                local ok, _, _, r = alive(p)
                if ok and math.abs(r.Position.X) <= 15 and math.abs(r.Position.Z) <= 15 and r.Position.Y < 12 then
                    if p.Team == teams.Rose then rose += 1 else aqua += 1 end
                    p.leaderstats.StylePoints.Value += 1
                end
            end
            match.owner, match.progress, match.status = Rules.capture(rose, aqua, match.owner, match.progress)
            if match.status == "HELD" then
                if match.owner == "Rose" then match.rose += 1 else match.aqua += 1 end
            end
            arena.CaptureZone.Color = match.owner == "Rose" and palettes[1] or match.owner == "Aqua" and palettes[2] or palettes[3]
            if match.seconds <= 0 or match.rose >= 90 or match.aqua >= 90 then
                match.phase, match.seconds = "RESULTS", 10
                match.winner = match.rose == match.aqua and "DRAW" or match.rose > match.aqua and "ROSE WINS" or "AQUA WINS"
                for _, p in Players:GetPlayers() do
                    local winner = p.Team == teams.Rose and match.rose > match.aqua or p.Team == teams.Aqua and match.aqua > match.rose
                    if winner then p.leaderstats.StylePoints.Value += 150 end
                end
            end
        elseif match.seconds <= 0 then
            match = {phase = "LIVE", seconds = 150, rose = 0, aqua = 0, owner = "Neutral", progress = 0, status = "EMPTY", winner = ""}
            for _, p in Players:GetPlayers() do task.spawn(function() p:LoadCharacterAsync() end) end
        end
        matchEvent:FireAllClients(match)
    end
end)
