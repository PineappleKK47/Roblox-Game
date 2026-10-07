local Lighting = game:GetService("Lighting")
local arena = Instance.new("Folder")
arena.Name = "PrismArena"
arena.Parent = workspace
local colors = {dark = Color3.fromRGB(24, 26, 47), stone = Color3.fromRGB(58, 55, 86), pink = Color3.fromRGB(255, 105, 185), cyan = Color3.fromRGB(85, 225, 240)}
local function block(name, size, position, color, neon)
    local part = Instance.new("Part")
    part.Name, part.Size, part.Position = name, size, position
    part.Anchored, part.Color = true, color
    part.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.Parent = arena
    return part
end
local function sign(text, position, color)
    local panel = block("Sign", Vector3.new(24, 7, 0.5), position, colors.dark)
    if position.Z < 0 then panel.CFrame *= CFrame.Angles(0, math.pi, 0) end
    local gui = Instance.new("SurfaceGui")
    gui.Face, gui.CanvasSize, gui.Parent = Enum.NormalId.Front, Vector2.new(800, 240), panel
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
    label.Text, label.TextColor3, label.TextScaled = text, color, true
    label.Font, label.Parent = Enum.Font.GothamBlack, gui
    return panel
end
block("Floor", Vector3.new(200, 2, 200), Vector3.new(0, -1, 0), colors.dark)
for _, x in {-100, 100} do block("Wall", Vector3.new(2, 25, 200), Vector3.new(x, 11.5, 0), colors.stone) end
for _, z in {-100, 100} do block("Wall", Vector3.new(200, 25, 2), Vector3.new(0, 11.5, z), colors.stone) end
for _, x in {-90, -60, -30, 0, 30, 60, 90} do
    local strip = block("FloorLine", Vector3.new(0.15, 0.04, 190), Vector3.new(x, 0.03, 0), colors.cyan, true)
    strip.CanCollide = false
end
for _, x in {-52, 52} do
    for _, z in {-38, 0, 38} do
        block("Cover", Vector3.new(14, 8, 12), Vector3.new(x, 4, z), colors.stone)
        block("CoverLight", Vector3.new(14.2, 0.25, 12.2), Vector3.new(x, 8.1, z), colors.pink, true)
    end
end
for _, z in {-38, 38} do
    for _, x in {-20, 20} do
        block("LowCover", Vector3.new(10, 4, 6), Vector3.new(x, 2, z), colors.stone)
    end
end
for _, x in {-78, 78} do
    block("Balcony", Vector3.new(24, 1, 90), Vector3.new(x, 9, 0), colors.stone)
    for i = 1, 10 do
        block("Step", Vector3.new(12, i * 0.9, 3), Vector3.new(x, i * 0.45, 65 - i * 3), colors.stone)
        block("Step", Vector3.new(12, i * 0.9, 3), Vector3.new(x, i * 0.45, -65 + i * 3), colors.stone)
    end
end
local zone = block("CaptureZone", Vector3.new(30, 0.15, 30), Vector3.new(0, 0.08, 0), colors.pink, true)
zone.CanCollide = false
block("Stage", Vector3.new(16, 0.5, 16), Vector3.new(0, 0.25, 0), colors.stone)
sign("PRISM / RUSH", Vector3.new(0, 15, -98), colors.pink)
sign("CAPTURE THE SPOTLIGHT", Vector3.new(0, 15, 98), colors.cyan).Name = "ObjectiveSign"
-- Only physical spawn points; Combat assigns teams and teleports respawns.
for _, z in {-85, 85} do
    local spawn = Instance.new("SpawnLocation")
    spawn.Name, spawn.Size, spawn.Position = "ArenaSpawn", Vector3.new(12, 1, 12), Vector3.new(0, 0.5, z)
    spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 3
    spawn.Color, spawn.Parent = z < 0 and colors.pink or colors.cyan, arena
end
local drones = Instance.new("Folder")
drones.Name, drones.Parent = "Drones", arena
for i = 1, 4 do
    local model = Instance.new("Model")
    model.Name = "Training Drone " .. i
    model:SetAttribute("Drone", true)
    model:SetAttribute("Index", i)
    local body = block("HumanoidRootPart", Vector3.new(3, 3, 3), Vector3.new(i * 10 - 25, 5, 40), colors.stone)
    body.Shape, body.Parent = Enum.PartType.Ball, model
    local eye = block("Head", Vector3.new(1.7, 1.2, 1), body.Position + Vector3.new(0, 0.8, -1.3), colors.cyan, true)
    eye.Parent = model
    local humanoid = Instance.new("Humanoid")
    humanoid.RequiresNeck, humanoid.BreakJointsOnDeath = false, false
    humanoid.MaxHealth, humanoid.Health = 90, 90
    humanoid.DisplayName = "TRAINING DRONE"
    humanoid.Parent = model
    model.PrimaryPart, model.Parent = body, drones
end
Lighting.ClockTime, Lighting.Brightness = 20, 2
Lighting.Ambient = Color3.fromRGB(115, 100, 150)
local bloom = Instance.new("BloomEffect")
bloom.Intensity, bloom.Size, bloom.Threshold, bloom.Parent = 0.35, 24, 1.2, Lighting
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density, atmosphere.Color, atmosphere.Parent = 0.2, Color3.fromRGB(180, 165, 220), Lighting
