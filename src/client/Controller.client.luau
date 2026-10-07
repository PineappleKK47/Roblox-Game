local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local Weapons = require(RS:WaitForChild("Shared"):WaitForChild("Weapons"))
local remotes = RS:WaitForChild("Combat")
local action, stateEvent, effect = remotes:WaitForChild("Action"), remotes:WaitForChild("State"), remotes:WaitForChild("Effect")
local matchEvent, notice = remotes:WaitForChild("Match"), remotes:WaitForChild("Notice")
local palettes = {Color3.fromRGB(255, 110, 195), Color3.fromRGB(110, 230, 255), Color3.fromRGB(210, 160, 255), Color3.fromRGB(255, 215, 100)}
local s = {weapon = "Bloom", ammo = 26, reloading = false, shield = 50, dash = 0, pulse = 0, palette = 1}
local firing, aiming, lastShot, recoil, lastSync = false, false, 0, 0, os.clock()
local comfortable = false
player.CameraMode = Enum.CameraMode.LockFirstPerson
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "PrismHUD", false, true
gui.Parent = player:WaitForChild("PlayerGui")
local function text(name, value, position, size, fontSize, color, background)
    local item = Instance.new("TextLabel")
    item.Name, item.Text, item.Position, item.Size = name, value, position, size
    item.BackgroundColor3, item.BackgroundTransparency = Color3.fromRGB(18, 21, 36), background and 0.15 or 1
    item.TextColor3, item.Font, item.TextSize = color or Color3.fromRGB(235, 230, 250), Enum.Font.GothamBold, fontSize
    item.BorderSizePixel = 0
    item.Parent = gui
    if background then
        local corner = Instance.new("UICorner")
        corner.CornerRadius, corner.Parent = UDim.new(0, 12), item
        local stroke = Instance.new("UIStroke")
        stroke.Color, stroke.Transparency, stroke.Parent = Color3.fromRGB(110, 100, 150), 0.5, item
    end
    return item
end
local title = text("Title", "PRISM RUSH", UDim2.new(0, 20, 0, 48), UDim2.fromOffset(180, 30), 22, palettes[1])
local teamLabel = text("Team", "", UDim2.new(0, 20, 0, 78), UDim2.fromOffset(180, 24), 12)
local score = text("Score", "ROSE  0    •    0  AQUA", UDim2.new(0.5, -170, 0, 45), UDim2.fromOffset(340, 48), 22, nil, true)
local objective = text("Objective", "CONNECTING", UDim2.new(0.5, -180, 0, 100), UDim2.fromOffset(360, 48), 14, nil, true)
local status = text("Weapon", "", UDim2.new(1, -250, 1, -105), UDim2.fromOffset(230, 76), 21, nil, true)
local vitality = text("Vitality", "", UDim2.new(0, 20, 1, -105), UDim2.fromOffset(230, 76), 18, nil, true)
local abilities = text("Abilities", "", UDim2.new(0.5, -155, 1, -95), UDim2.fromOffset(310, 42), 13, nil, true)
local crosshair = text("Crosshair", "+", UDim2.new(0.5, -15, 0.5, -15), UDim2.fromOffset(30, 30), 27)
local hitMarker = text("Hit", "", UDim2.new(0.5, -25, 0.5, -25), UDim2.fromOffset(50, 50), 38, palettes[2])
local feed = text("Feed", "", UDim2.new(1, -320, 0, 160), UDim2.fromOffset(300, 100), 13)
feed.TextXAlignment, feed.TextYAlignment = Enum.TextXAlignment.Right, Enum.TextYAlignment.Top
local help = text("Help", "R reload  ·  Q weapon  ·  Shift dash  ·  E shield pulse  ·  C color  ·  V comfort", UDim2.new(0.5, -300, 1, -30), UDim2.fromOffset(600, 20), 11)
local banner = text("Banner", "CAPTURE THE SPOTLIGHT", UDim2.new(0.5, -200, 0.25, 0), UDim2.fromOffset(400, 45), 20, palettes[3])
local damageFlash = Instance.new("Frame")
damageFlash.Size, damageFlash.BackgroundColor3, damageFlash.BackgroundTransparency = UDim2.fromScale(1, 1), palettes[1], 1
 damageFlash.BorderSizePixel, damageFlash.ZIndex, damageFlash.Parent = 0, 0, gui
-- Keep core panels readable and separate on narrow screens.
local function fit()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local width = camera.ViewportSize.X
    local small = width < 850
    title.Visible, teamLabel.Visible = not small, not small
    score.Size = UDim2.fromOffset(small and 280 or 340, 48)
    score.Position = UDim2.new(0.5, small and -140 or -170, 0, 45)
    local panelWidth = math.min(230, math.max(100, width * 0.3 - 20))
    vitality.Size, status.Size = UDim2.fromOffset(panelWidth, 76), UDim2.fromOffset(panelWidth, 76)
    status.Position = UDim2.new(1, -panelWidth - 20, 1, -105)
    status.TextSize, vitality.TextSize = small and 13 or 21, small and 13 or 18
    abilities.Size = UDim2.fromOffset(math.min(310, width * 0.33), 42)
    abilities.Position = UDim2.new(0.5, -math.min(310, width * 0.33) / 2, 1, -95)
    abilities.TextSize = small and 10 or 13
    help.Visible = not small and not UIS.TouchEnabled
    feed.Visible = not small
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
fit()
if UIS.TouchEnabled then help.Visible = false end
local function refresh()
    local w = Weapons[s.weapon]
    status.Text = w.role .. " / " .. string.upper(s.weapon) .. "\n" .. s.ammo .. " / " .. w.magazine .. (s.reloading and "  RELOADING" or "")
    status.TextColor3 = palettes[s.palette]
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    vitality.Text = "HEALTH  " .. math.ceil(h and h.Health or 0) .. "\nSHIELD  ◇ " .. math.ceil(s.shield)
    teamLabel.Text = (player.Team and string.upper(player.Team.Name) or "") .. " TEAM • SPOTLIGHT"
    local elapsed = os.clock() - lastSync
    abilities.Text = "DASH " .. (s.dash <= elapsed and "READY" or math.ceil(s.dash - elapsed) .. "s") .. "    PULSE " .. (s.pulse <= elapsed and "READY" or math.ceil(s.pulse - elapsed) .. "s")
end
-- Camera-local procedural weapon. It is visual only; server raycasts determine hits.
local viewmodel, parts = nil, {}
local function createWeapon()
    if viewmodel then viewmodel:Destroy() end
    viewmodel = Instance.new("Model")
    viewmodel.Name, viewmodel.Parent = "PrismViewmodel", workspace.CurrentCamera
    parts = {}
    local function piece(name, size, offset, color, neon)
        local p = Instance.new("Part")
        p.Name, p.Size, p.Anchored = name, size, true
        p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
        p.Color, p.Material = color, neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
        p.Parent = viewmodel
        table.insert(parts, {part = p, offset = CFrame.new(offset)})
    end
    local length = s.weapon == "Nova" and 2.6 or s.weapon == "Glimmer" and 1.5 or 1.9
    local accent = palettes[s.palette]
    piece("Receiver", Vector3.new(0.45, 0.5, 1.3), Vector3.new(0, 0, 0), Color3.fromRGB(40, 42, 65))
    piece("Barrel", Vector3.new(0.2, 0.22, length), Vector3.new(0, 0.05, -length * 0.6), Color3.fromRGB(70, 72, 95))
    piece("LightRail", Vector3.new(0.46, 0.09, 1.2), Vector3.new(0, 0.28, -0.2), accent, true)
    piece("Grip", Vector3.new(0.28, 0.55, 0.3), Vector3.new(0, -0.5, 0.35), accent)
    piece("Magazine", Vector3.new(0.3, 0.65, 0.4), Vector3.new(0, -0.45, -0.3), Color3.fromRGB(65, 65, 85))
    if s.weapon == "Nova" then piece("Scope", Vector3.new(0.3, 0.3, 0.8), Vector3.new(0, 0.48, -0.2), accent) end
end
local hitGeneration = 0
stateEvent.OnClientEvent:Connect(function(newState)
    local changed = newState.weapon ~= s.weapon or newState.palette ~= s.palette
    s, lastSync = newState, os.clock()
    if changed or not viewmodel then createWeapon() end
    refresh()
    if s.hit then
        hitGeneration += 1
        local generation = hitGeneration
        hitMarker.Text = "×"
        task.delay(0.16, function() if generation == hitGeneration then hitMarker.Text = "" end end)
    end
end)
local feedLines = {}
notice.OnClientEvent:Connect(function(kind, message)
    if kind == "DAMAGE" then
        damageFlash.BackgroundTransparency = 0.87
        TweenService:Create(damageFlash, TweenInfo.new(0.45), {BackgroundTransparency = 1}):Play()
    elseif kind == "FEED" then
        table.insert(feedLines, 1, message)
        if #feedLines > 4 then table.remove(feedLines) end
        feed.Text = table.concat(feedLines, "\n")
    end
end)
matchEvent.OnClientEvent:Connect(function(m)
    score.Text = "ROSE  " .. m.rose .. "    •    " .. m.aqua .. "  AQUA"
    objective.Text = string.format("%s  •  %d:%02d\n%s / %s", m.phase, math.floor(m.seconds / 60), m.seconds % 60, string.upper(m.owner), m.status)
    objective.TextColor3 = m.owner == "Rose" and palettes[1] or m.owner == "Aqua" and palettes[2] or palettes[3]
    if m.phase == "RESULTS" then banner.Text = m.winner .. " • NEXT ROUND IN " .. m.seconds
    elseif m.phase == "WARMUP" then banner.Text = "WARMUP • TRY YOUR WEAPONS"
    else banner.Text = "" end
    refresh()
end)
effect.OnClientEvent:Connect(function(kind, origin, endpoint, name)
    if kind == "Pulse" then
        local orb = Instance.new("Part")
        orb.Shape, orb.Size, orb.Position = Enum.PartType.Ball, Vector3.one, origin
        orb.Anchored, orb.CanCollide, orb.CanQuery, orb.CanTouch = true, false, false, false
        orb.Material, orb.Color, orb.Transparency = Enum.Material.Neon, palettes[2], 0.6
        orb.Parent = workspace
        TweenService:Create(orb, TweenInfo.new(0.5), {Size = Vector3.new(50, 50, 50), Transparency = 1}):Play()
        Debris:AddItem(orb, 0.6)
        return
    end
    local distance = (endpoint - origin).Magnitude
    if distance < 0.01 then return end
    local tracer = Instance.new("Part")
    tracer.Anchored, tracer.CanCollide, tracer.CanQuery, tracer.CanTouch = true, false, false, false
    tracer.Material, tracer.Color = Enum.Material.Neon, Weapons[name].color
    tracer.Size = Vector3.new(0.06, 0.06, distance)
    tracer.CFrame, tracer.Parent = CFrame.lookAt((origin + endpoint) / 2, endpoint), workspace
    Debris:AddItem(tracer, 0.07)
    local spark = Instance.new("Part")
    spark.Shape, spark.Size, spark.Position = Enum.PartType.Ball, Vector3.new(0.25, 0.25, 0.25), endpoint
    spark.Anchored, spark.CanCollide, spark.CanQuery, spark.CanTouch = true, false, false, false
    spark.Material, spark.Color, spark.Parent = Enum.Material.Neon, Weapons[name].color, workspace
    Debris:AddItem(spark, 0.12)
end)
local function bind(name, titleText, x, y, inputs, callback, touch)
    CAS:BindAction("Prism" .. name, callback, touch ~= false, table.unpack(inputs))
    CAS:SetTitle("Prism" .. name, titleText)
    CAS:SetPosition("Prism" .. name, UDim2.new(1, x, 1, y))
end
bind("Fire", "FIRE", -110, -220, {Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2}, function(_, input)
    firing = input == Enum.UserInputState.Begin or input == Enum.UserInputState.Change
    return Enum.ContextActionResult.Sink
end)
bind("Aim", "AIM", -200, -220, {Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2}, function(_, input)
    aiming = input == Enum.UserInputState.Begin or input == Enum.UserInputState.Change
    return Enum.ContextActionResult.Sink
end)
for _, config in {
    {"Reload", "RELOAD", Enum.KeyCode.R, Enum.KeyCode.ButtonX, -110, -310},
    {"Switch", "SWAP", Enum.KeyCode.Q, Enum.KeyCode.ButtonY, -200, -310},
    {"Dash", "DASH", Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonB, -290, -220},
    {"Pulse", "PULSE", Enum.KeyCode.E, Enum.KeyCode.ButtonL1, -290, -310},
    {"Palette", "COLOR", Enum.KeyCode.C, Enum.KeyCode.DPadUp, -200, -400},
} do
    bind(config[1], config[2], config[5], config[6], {config[3], config[4]}, function(_, input)
        if input == Enum.UserInputState.Begin then action:FireServer(config[1]) end
        return Enum.ContextActionResult.Sink
    end)
end
bind("Comfort", "COMFORT", -110, -400, {Enum.KeyCode.V, Enum.KeyCode.DPadDown}, function(_, input)
    if input == Enum.UserInputState.Begin then comfortable = not comfortable end
    return Enum.ContextActionResult.Sink
end)
UIS.WindowFocusReleased:Connect(function() firing, aiming = false, false end)
local function onCharacter(character)
    firing, aiming = false, false
    local h = character:WaitForChild("Humanoid")
    h.HealthChanged:Connect(refresh)
    task.delay(0.3, function() action:FireServer("Sync") end)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end
local refreshElapsed = 0
RunService:BindToRenderStep("PrismPresentation", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local camera = workspace.CurrentCamera
    if not camera then return end
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local live = h and h.Health > 0
    local targetFov = aiming and (s.weapon == "Nova" and 35 or 58) or 78
    camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 12)
    crosshair.Text = aiming and "·" or "+"
    local w = Weapons[s.weapon]
    if firing and live and not s.reloading and s.ammo > 0 and os.clock() - lastShot >= w.interval then
        lastShot, recoil = os.clock(), 1
        action:FireServer("Fire", camera.CFrame.LookVector, aiming)
        -- Comfort mode reduces visual kick only; server weapon spread stays the same.
        camera.CFrame *= CFrame.Angles(math.rad(w.recoil * (comfortable and 0.25 or 1)), 0, 0)
    end
    recoil = math.max(0, recoil - dt * 8)
    if viewmodel then
        local moving = h and h.MoveDirection.Magnitude > 0.1
        local bob = moving and not comfortable and math.sin(os.clock() * 10) * 0.025 or 0
        local offset = aiming and Vector3.new(0, -0.65, -1.35) or Vector3.new(0.7, -0.65 + bob, -1.2)
        local base = camera.CFrame * CFrame.new(offset + Vector3.new(0, 0, recoil * 0.15)) * CFrame.Angles(s.reloading and -0.5 or 0, 0, s.reloading and -0.35 or 0)
        for _, entry in parts do
            entry.part.CFrame = base * entry.offset
            entry.part.LocalTransparencyModifier = live and 0 or 1
        end
    end
    refreshElapsed += dt
    if refreshElapsed >= 0.1 then refreshElapsed = 0; refresh() end
end)
createWeapon()
action:FireServer("Sync")
refresh()
