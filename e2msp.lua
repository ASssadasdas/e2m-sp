if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

pcall(function()
    if CoreGui:FindFirstChild("XenoESP_UI") then
        CoreGui.XenoESP_UI:Destroy()
    end
end)

local Settings = {
    PlayersESP = false,
    PlayersName = false,
    PlayersDistance = false,
    PlayersHealth = false,
    PlayersLookVector = false,
    BotsESP = false,
    NPCHealth = false,
    ExitsESP = false,
    TrapsESP = false,
    Fullbright = false,
    AutoAim = false,
    AimNPCs = false,
    AimRadius = 100,
    AimHead = true,
    TeammateName = "",
    LookLength = 5,
}

local PLAYER_COLOR = Color3.fromRGB(255, 255, 255)
local DEAD_COLOR = Color3.fromRGB(255, 0, 0)
local BOT_COLOR = Color3.fromRGB(255, 255, 0)
local LOOK_COLOR = Color3.fromRGB(0, 80, 255)
local OUTLINE_COLOR = Color3.fromRGB(255, 0, 0)
local TEAM_COLOR = Color3.fromRGB(0, 255, 0)
local EXIT_COLOR = Color3.fromRGB(0, 255, 0)
local TRAP_COLOR = Color3.fromRGB(255, 50, 50)

local PlayerESP = {}
local BotESP = {}
local BotHealth = {}
local ExitESP = {}
local TrapESP = {}
local BotConnections = {}
local ExitConnections = {}
local TrapConnection = nil

local FOVCircle = nil
local hasDrawing = pcall(function() return Drawing end) and Drawing ~= nil

local CurrentWeapon = "None"
local CurrentAmmo = "Default"
local BulletSpeed = 2600
local DropMult = 0.7
local LastWeaponScan = 0

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient,
}

local TrapKeywords = {
    "pmn", "pmn2", "mon-50", "mon50", "mon 50",
    "f1 trap", "f1trap", "landmine", "claymore", "mine"
}

local BodyParts = {
    "Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg",
    "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}

-- Wiki m/s × 3.5 ≈ studs/s | {pattern, defaultSpeed, dropMult, caliberKey}
local WeaponDB = {
    {"mod-98",          3500, 0.45, "338"},
    {"task force zero", 3500, 0.45, "338"},
    {"r700",            3470, 0.45, "338"},
    {"remington",       3470, 0.45, "338"},
    {"svd",             3100, 0.55, "76254"},
    {"mosin",           3100, 0.55, "76254"},
    {"pkm",             3100, 0.55, "76254"},
    {"fn-fal",          3000, 0.60, "76251"},
    {"fal",             3000, 0.60, "76251"},
    {"m4a1",            3400, 0.50, "556"},
    {"m4",              3400, 0.50, "556"},
    {"adar",            3400, 0.50, "556"},
    {"akmn",            2600, 0.70, "76239"},
    {"akm",             2550, 0.72, "76239"},
    {"sks",             2600, 0.70, "76239"},
    {"as val",          1500, 1.15, "939"},
    {"val",             1500, 1.15, "939"},
    {"groza",           1500, 1.15, "939"},
    {"ots-14",          1500, 1.15, "939"},
    {"mp5",             1700, 1.05, "919"},
    {"mp443",           1700, 1.05, "919"},
    {"yarygin",         1700, 1.05, "919"},
    {"mk23",            1750, 1.05, "45"},
    {"ppsh",            1650, 1.08, "76225"},
    {"tt-33",           1650, 1.08, "76225"},
    {"tokarev",         1650, 1.08, "76225"},
    {"nagant",          1650, 1.08, "76225"},
    {"makarov",         1350, 1.25, "918"},
    {"skorpion",        1400, 1.20, "918"},
    {"mod-0",           1400, 1.20, "918"},
    {"saiga",           1500, 1.30, "12ga"},
    {"izh-81",          1450, 1.35, "12ga"},
    {"izh-12",          1450, 1.35, "12ga"},
    {"izh",             1450, 1.35, "12ga"},
    {"toz",             1450, 1.35, "12ga"},
    {"rpg",              700, 2.00, "rpg"},
    {"knife",           9999, 0.00, "melee"},
    {"karambit",        9999, 0.00, "melee"},
    {"machete",         9999, 0.00, "melee"},
    {"dv-2",            9999, 0.00, "melee"},
}

-- Wiki ammo velocities (m/s × 3.5) by caliber + type
local AmmoVel = {
    ["338"] = {tracer = 3470, ap = 3550, tfz = 3550},
    ["76254"] = {tracer = 3100, ap = 3290, tfz = 3290},
    ["76251"] = {tracer = 2870, ap = 3150, tfz = 3150},
    ["556"] = {tracer = 3265, ap = 3500, tfz = 3500},
    ["76239"] = {tracer = 2500, ap = 2685, tfz = 2685},
    ["939"] = {tracer = 1485, ap = 1485, tfz = 1575},
    ["919"] = {tracer = 1630, ap = 1750, tfz = 1750},
    ["45"] = {tracer = 1630, ap = 1800, tfz = 1800},
    ["76225"] = {tracer = 1610, ap = 1695, tfz = 1695},
    ["918"] = {tracer = 1255, ap = 1340, tfz = 1415},
    ["12ga"] = {tracer = 1490, ap = 1490, buckshot = 1490, slug = 1420, flechette = 1190, ["ap-20"] = 2190},
    ["rpg"] = {tracer = 700, ap = 700, tfz = 700},
    ["melee"] = {tracer = 9999, ap = 9999, tfz = 9999},
}

local function IsAlive(model)
    if not model then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function IsTeammate(player)
    if Settings.TeammateName == "" then return false end
    return string.lower(player.Name) == string.lower(Settings.TeammateName)
        or string.lower(player.DisplayName) == string.lower(Settings.TeammateName)
end

local function IsTrap(obj)
    if not obj then return false end
    local name = string.lower(obj.Name)
    for _, kw in ipairs(TrapKeywords) do
        if string.find(name, kw, 1, true) then return true end
    end
    return false
end

local function GetCallSign(obj)
    if not obj then return nil end
    local props = obj:FindFirstChild("ItemProperties")
    if props then
        local cs = props:GetAttribute("CallSign") or props:GetAttribute("Name")
        if cs and tostring(cs) ~= "" then return tostring(cs) end
    end
    local a = obj:GetAttribute("CallSign")
    if a then return tostring(a) end
    return obj.Name
end

local function MatchWeapon(name)
    if not name then return nil end
    local lower = string.lower(name)
    for _, entry in ipairs(WeaponDB) do
        if string.find(lower, entry[1], 1, true) then
            return name, entry[2], entry[3], entry[4]
        end
    end
    return nil
end

local function DetectAmmoType(obj, caliberKey)
    local ammoType = "tracer"
    local ammoName = "Tracer"

    local function checkStr(s)
        if not s then return end
        local l = string.lower(tostring(s))
        if string.find(l, "tfz", 1, true) or string.find(l, "cqb", 1, true) then
            ammoType = "tfz"
            ammoName = "TFZ"
        elseif string.find(l, "armor", 1, true) or string.find(l, "ap", 1, true) or string.find(l, "piercing", 1, true) then
            ammoType = "ap"
            ammoName = "AP"
        elseif string.find(l, "flechette", 1, true) then
            ammoType = "flechette"
            ammoName = "Flechette"
        elseif string.find(l, "slug", 1, true) then
            ammoType = "slug"
            ammoName = "Slug"
        elseif string.find(l, "buck", 1, true) then
            ammoType = "buckshot"
            ammoName = "Buckshot"
        elseif string.find(l, "ap-20", 1, true) or string.find(l, "ap20", 1, true) then
            ammoType = "ap-20"
            ammoName = "AP-20"
        elseif string.find(l, "tracer", 1, true) then
            ammoType = "tracer"
            ammoName = "Tracer"
        end
    end

    if obj then
        local props = obj:FindFirstChild("ItemProperties")
        if props then
            checkStr(props:GetAttribute("Ammo"))
            checkStr(props:GetAttribute("AmmoType"))
            checkStr(props:GetAttribute("Cartridge"))
            checkStr(props:GetAttribute("Bullet"))
            checkStr(props:GetAttribute("Round"))
            checkStr(props:GetAttribute("Caliber"))
            checkStr(props:GetAttribute("LoadedAmmo"))
            checkStr(props:GetAttribute("CurrentAmmo"))
        end
        checkStr(obj:GetAttribute("Ammo"))
        checkStr(obj:GetAttribute("AmmoType"))

        for _, desc in ipairs(obj:GetDescendants()) do
            if desc:IsA("StringValue") or desc:IsA("StringAttribute") then
                checkStr(desc.Value or desc.Name)
            end
            local n = string.lower(desc.Name)
            if string.find(n, "ammo", 1, true) or string.find(n, "mag", 1, true) or string.find(n, "round", 1, true) then
                checkStr(desc.Name)
                if desc:IsA("StringValue") then checkStr(desc.Value) end
                local p = desc:FindFirstChild("ItemProperties")
                if p then
                    checkStr(p:GetAttribute("CallSign"))
                    checkStr(p:GetAttribute("Name"))
                end
            end
        end
    end

    local table = AmmoVel[caliberKey]
    local speed = BulletSpeed
    if table then
        speed = table[ammoType] or table.tracer or BulletSpeed
    end

    return ammoName, speed
end

local function DetectLocalWeapon()
    local char = LocalPlayer.Character
    if not char then
        CurrentWeapon = "None"
        CurrentAmmo = "Default"
        BulletSpeed = 2600
        DropMult = 0.7
        return
    end

    local function apply(name, spd, drop, cal, obj)
        CurrentWeapon = name
        DropMult = drop
        local ammoName, ammoSpd = DetectAmmoType(obj, cal)
        CurrentAmmo = ammoName
        BulletSpeed = ammoSpd or spd
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local matched, spd, drop, cal = MatchWeapon(GetCallSign(tool) or tool.Name)
        if matched then
            apply(matched, spd, drop, cal, tool)
            return
        end
    end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Model") or child:IsA("Tool") then
            local n = string.lower(child.Name)
            if string.find(n, "clothing", 1, true) then continue end
            local matched, spd, drop, cal = MatchWeapon(GetCallSign(child))
            if matched then
                apply(matched, spd, drop, cal, child)
                return
            end
        end
    end

    for _, child in ipairs(Camera:GetChildren()) do
        if child:IsA("Model") then
            local matched, spd, drop, cal = MatchWeapon(GetCallSign(child) or child.Name)
            if matched then
                apply(matched, spd, drop, cal, child)
                return
            end
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("Model") then
                    matched, spd, drop, cal = MatchWeapon(GetCallSign(sub) or sub.Name)
                    if matched then
                        apply(matched, spd, drop, cal, sub)
                        return
                    end
                end
            end
        end
    end

    for _, handName in ipairs({"RightHand", "LeftHand", "Right Arm", "Left Arm"}) do
        local hand = char:FindFirstChild(handName)
        if not hand then continue end
        for _, joint in ipairs(hand:GetChildren()) do
            if joint:IsA("Motor6D") or joint:IsA("Weld") then
                local other = (joint.Part0 == hand) and joint.Part1 or joint.Part0
                if other and other.Parent then
                    local model = other:FindFirstAncestorWhichIsA("Model")
                    if model and model ~= char then
                        local matched, spd, drop, cal = MatchWeapon(GetCallSign(model) or model.Name)
                        if matched then
                            apply(matched, spd, drop, cal, model)
                            return
                        end
                    end
                end
            end
        end
    end

    CurrentWeapon = "Unknown"
    CurrentAmmo = "Default"
    BulletSpeed = 2600
    DropMult = 0.7
end

local function SetFullbright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.Ambient = OriginalLighting.Ambient
    end
end

local function CreateFOVCircle()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) FOVCircle = nil end
    if not hasDrawing then return end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
    FOVCircle.Radius = Settings.AimRadius
end

local function UpdateFOVCircle()
    if not FOVCircle then return end
    local viewport = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
    FOVCircle.Radius = Settings.AimRadius
    FOVCircle.Visible = Settings.AutoAim
end

local function GetAimPart(character)
    if Settings.AimHead then
        return character:FindFirstChild("Head")
    else
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    end
end

local function GetVelocity(model)
    local hrp = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
    if hrp then
        return hrp.AssemblyLinearVelocity
    end
    return Vector3.zero
end

local function GetPredictedPosition(part, model)
    local camPos = Camera.CFrame.Position
    local pos = part.Position
    local dist = (pos - camPos).Magnitude
    local vel = GetVelocity(model)

    local speed = math.clamp(BulletSpeed, 400, 6000)
    local t = dist / speed

    local r = math.clamp((dist - 8) / 55, 0, 1)
    r = r * r * (3 - 2 * r)

    local hVel = Vector3.new(vel.X, 0, vel.Z)
    local vVel = vel.Y

    local flat = Vector3.new(pos.X - camPos.X, 0, pos.Z - camPos.Z)
    local lateralBoost = 1
    if flat.Magnitude > 1 then
        local dir = flat.Unit
        local lateral = hVel - dir * hVel:Dot(dir)
        lateralBoost = 1 + math.clamp(lateral.Magnitude / 20, 0, 0.55)
    end

    local lead = t * r * lateralBoost

    local predicted = pos
        + hVel * lead
        + Vector3.new(0, vVel * lead * 0.25, 0)

    local drop = (t * t) * 55 * DropMult * r
    drop = math.clamp(drop, 0, 4)

    return predicted + Vector3.new(0, drop, 0)
end

local function IsPartInFOV(part, center, radius)
    if not part then return false, math.huge end
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen or screenPos.Z < 0 then return false, math.huge end
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return dist <= radius, dist
end

local function GetClosestTarget()
    local closestPart = nil
    local closestModel = nil
    local closestDist = Settings.AimRadius
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

    local function checkModel(model)
        if not model or not IsAlive(model) then return end

        local anyInFOV = false
        local bestPartDist = math.huge

        for _, partName in ipairs(BodyParts) do
            local part = model:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                local inFOV, dist = IsPartInFOV(part, center, Settings.AimRadius)
                if inFOV then
                    anyInFOV = true
                    if dist < bestPartDist then
                        bestPartDist = dist
                    end
                end
            end
        end

        if not anyInFOV then return end

        local aimPart = GetAimPart(model)
        if not aimPart then return end

        if bestPartDist < closestDist then
            closestDist = bestPartDist
            closestPart = aimPart
            closestModel = model
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not IsTeammate(player) then
            checkModel(player.Character)
        end
    end

    if Settings.AimNPCs then
        local aiZones = Workspace:FindFirstChild("AiZones")
        if aiZones then
            for _, zone in ipairs(aiZones:GetChildren()) do
                for _, model in ipairs(zone:GetChildren()) do
                    if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
                        checkModel(model)
                    end
                end
            end
        end
    end

    return closestPart, closestModel
end

local function CreateHighlight(parent, fillColor)
    if parent == LocalPlayer.Character then return nil end
    local old = parent:FindFirstChild("XenoESP_Highlight")
    if old then old:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Name = "XenoESP_Highlight"
    hl.Adornee = parent
    hl.FillColor = fillColor
    hl.OutlineColor = OUTLINE_COLOR
    hl.FillTransparency = 0.75
    hl.OutlineTransparency = 0.75
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = true
    hl.Parent = parent
    return hl
end

local function ForceHighlight(hl, fillColor)
    if not hl or not hl.Parent then return end
    if hl.Parent == LocalPlayer.Character then
        pcall(function() hl:Destroy() end)
        return
    end
    pcall(function()
        hl.Enabled = true
        hl.FillColor = fillColor
        hl.OutlineColor = OUTLINE_COLOR
        hl.FillTransparency = 0.75
        hl.OutlineTransparency = 0.75
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end)
end

local function CreateBillboard(character)
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if not head then return nil end
    local old = head:FindFirstChild("XenoESP_Billboard")
    if old then old:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "XenoESP_Billboard"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 220, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = math.huge
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 18)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.25
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 10
    nameLabel.Text = ""
    nameLabel.Visible = false
    nameLabel.Parent = billboard

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 0, 18)
    healthLabel.Position = UDim2.new(0, 0, 0, 18)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    healthLabel.TextStrokeTransparency = 0.25
    healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 10
    healthLabel.Text = ""
    healthLabel.Visible = false
    healthLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistanceLabel"
    distLabel.Size = UDim2.new(1, 0, 0, 18)
    distLabel.Position = UDim2.new(0, 0, 0, 36)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextStrokeTransparency = 0.25
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 10
    distLabel.Text = ""
    distLabel.Visible = false
    distLabel.Parent = billboard

    return billboard
end

local function CreateNPCHealthBillboard(model)
    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if not head then return nil end
    local old = head:FindFirstChild("XenoNPC_Health")
    if old then old:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "XenoNPC_Health"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 120, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = math.huge
    billboard.Parent = head
    local label = Instance.new("TextLabel")
    label.Name = "HealthLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 255, 100)
    label.TextStrokeTransparency = 0.25
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.Text = ""
    label.Parent = billboard
    return billboard
end

local function CreateExitBillboard(part)
    local old = part:FindFirstChild("XenoExit_Billboard")
    if old then old:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "XenoExit_Billboard"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = math.huge
    billboard.Parent = part
    local label = Instance.new("TextLabel")
    label.Name = "ExitLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "[Exit]"
    label.TextColor3 = EXIT_COLOR
    label.TextStrokeTransparency = 0.25
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.Parent = billboard
    return billboard
end

local function CreateLookPart()
    local part = Instance.new("Part")
    part.Name = "XenoESP_Look"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = LOOK_COLOR
    part.Size = Vector3.new(0.035, 0.035, Settings.LookLength)
    part.Transparency = 0
    part.Parent = Workspace
    local hl = Instance.new("Highlight")
    hl.Name = "XenoLookHL"
    hl.FillColor = LOOK_COLOR
    hl.OutlineColor = LOOK_COLOR
    hl.FillTransparency = 0.3
    hl.OutlineTransparency = 1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = part
    return part
end

local function UpdateLookPartsSize()
    for _, data in pairs(PlayerESP) do
        if data.LookPart and data.LookPart.Parent then
            data.LookPart.Size = Vector3.new(0.035, 0.035, Settings.LookLength)
        end
    end
end

local function RemovePlayerESP(player)
    if PlayerESP[player] then
        pcall(function()
            if PlayerESP[player].Highlight then PlayerESP[player].Highlight:Destroy() end
            if PlayerESP[player].Billboard then PlayerESP[player].Billboard:Destroy() end
            if PlayerESP[player].LookPart then PlayerESP[player].LookPart:Destroy() end
        end)
        PlayerESP[player] = nil
    end
end

local function GetFillColor(player, character)
    if IsTeammate(player) then return TEAM_COLOR end
    return IsAlive(character) and PLAYER_COLOR or DEAD_COLOR
end

local function ApplyPlayerESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character or not character.Parent then return end

    local needAny = Settings.PlayersESP or Settings.PlayersLookVector
    if not needAny then
        RemovePlayerESP(player)
        return
    end

    if not PlayerESP[player] then PlayerESP[player] = {} end

    if Settings.PlayersESP then
        local fillColor = GetFillColor(player, character)
        local hl = PlayerESP[player].Highlight
        if not hl or not hl.Parent or hl.Parent ~= character then
            PlayerESP[player].Highlight = CreateHighlight(character, fillColor)
        else
            ForceHighlight(hl, fillColor)
        end
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Highlight") and obj.Name ~= "XenoESP_Highlight" then
                pcall(function() obj:Destroy() end)
            end
        end
        local bb = PlayerESP[player].Billboard
        if not bb or not bb.Parent then
            PlayerESP[player].Billboard = CreateBillboard(character)
            bb = PlayerESP[player].Billboard
        end
        if bb then
            local nameLabel = bb:FindFirstChild("NameLabel")
            local healthLabel = bb:FindFirstChild("HealthLabel")
            local distLabel = bb:FindFirstChild("DistanceLabel")
            if nameLabel then
                nameLabel.Text = player.Name
                nameLabel.Visible = Settings.PlayersName
            end
            if healthLabel then healthLabel.Visible = Settings.PlayersHealth end
            if distLabel then distLabel.Visible = Settings.PlayersDistance end
        end
    else
        if PlayerESP[player].Highlight then
            pcall(function() PlayerESP[player].Highlight:Destroy() end)
            PlayerESP[player].Highlight = nil
        end
        if PlayerESP[player].Billboard then
            pcall(function() PlayerESP[player].Billboard:Destroy() end)
            PlayerESP[player].Billboard = nil
        end
    end

    if Settings.PlayersLookVector then
        if not PlayerESP[player].LookPart or not PlayerESP[player].LookPart.Parent then
            PlayerESP[player].LookPart = CreateLookPart()
        else
            PlayerESP[player].LookPart.Size = Vector3.new(0.035, 0.035, Settings.LookLength)
        end
    else
        if PlayerESP[player].LookPart then
            pcall(function() PlayerESP[player].LookPart:Destroy() end)
            PlayerESP[player].LookPart = nil
        end
    end
end

local function TryAddBot(model)
    if not Settings.BotsESP and not Settings.NPCHealth then return end
    if not model:IsA("Model") then return end
    if model == LocalPlayer.Character then return end
    if not IsAlive(model) then return end
    if Settings.BotsESP then
        if not BotESP[model] or not BotESP[model].Parent then
            local hl = CreateHighlight(model, BOT_COLOR)
            if hl then BotESP[model] = hl end
        end
    end
    if Settings.NPCHealth then
        if not BotHealth[model] or not BotHealth[model].Parent then
            BotHealth[model] = CreateNPCHealthBillboard(model)
        end
    end
end

local function ClearBots()
    for model, hl in pairs(BotESP) do pcall(function() hl:Destroy() end) end
    table.clear(BotESP)
end

local function ClearBotHealth()
    for model, bb in pairs(BotHealth) do pcall(function() bb:Destroy() end) end
    table.clear(BotHealth)
end

local function ScanAiZones()
    local aiZones = Workspace:FindFirstChild("AiZones")
    if not aiZones then return end
    for _, zone in ipairs(aiZones:GetChildren()) do
        for _, model in ipairs(zone:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
                TryAddBot(model)
            end
        end
    end
end

local function StartBotTracking()
    ScanAiZones()
    local aiZones = Workspace:FindFirstChild("AiZones")
    if not aiZones then return end
    for _, conn in pairs(BotConnections) do conn:Disconnect() end
    table.clear(BotConnections)
    table.insert(BotConnections, aiZones.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            task.defer(TryAddBot, obj)
        elseif obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
            task.defer(TryAddBot, obj.Parent)
        end
    end))
end

local function StopBotTracking()
    if not Settings.BotsESP and not Settings.NPCHealth then
        for _, conn in pairs(BotConnections) do conn:Disconnect() end
        table.clear(BotConnections)
    end
    if not Settings.BotsESP then ClearBots() end
    if not Settings.NPCHealth then ClearBotHealth() end
end

local function MaintainBots()
    for model, hl in pairs(BotESP) do
        if not Settings.BotsESP or not model or not model.Parent or model == LocalPlayer.Character or not IsAlive(model) then
            pcall(function() hl:Destroy() end)
            BotESP[model] = nil
        else
            ForceHighlight(hl, BOT_COLOR)
        end
    end
    for model, bb in pairs(BotHealth) do
        if not Settings.NPCHealth or not model or not model.Parent or not IsAlive(model) then
            pcall(function() bb:Destroy() end)
            BotHealth[model] = nil
        else
            local hum = model:FindFirstChildOfClass("Humanoid")
            local label = bb:FindFirstChild("HealthLabel")
            if hum and label then
                label.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
            end
        end
    end
end

local function TryAddExit(obj)
    if not Settings.ExitsESP then return end
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return end
    local target = obj
    if obj:IsA("Model") then
        target = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
        if not target then return end
    end
    if not ExitESP[obj] or not ExitESP[obj].Parent then
        ExitESP[obj] = CreateExitBillboard(target)
    end
end

local function ClearExits()
    for obj, bb in pairs(ExitESP) do pcall(function() bb:Destroy() end) end
    table.clear(ExitESP)
end

local function ScanExits()
    local noCollision = Workspace:FindFirstChild("NoCollision")
    if not noCollision then return end
    local exitLocations = noCollision:FindFirstChild("ExitLocations")
    if not exitLocations then return end
    for _, obj in ipairs(exitLocations:GetChildren()) do TryAddExit(obj) end
end

local function StartExitTracking()
    ClearExits()
    ScanExits()
    local noCollision = Workspace:FindFirstChild("NoCollision")
    if not noCollision then return end
    local exitLocations = noCollision:FindFirstChild("ExitLocations")
    if not exitLocations then return end
    for _, conn in pairs(ExitConnections) do conn:Disconnect() end
    table.clear(ExitConnections)
    table.insert(ExitConnections, exitLocations.ChildAdded:Connect(function(obj)
        task.defer(TryAddExit, obj)
    end))
end

local function StopExitTracking()
    for _, conn in pairs(ExitConnections) do conn:Disconnect() end
    table.clear(ExitConnections)
    ClearExits()
end

local function MaintainExits()
    if not Settings.ExitsESP then return end
    for obj, bb in pairs(ExitESP) do
        if not obj or not obj.Parent or not bb or not bb.Parent then
            pcall(function() if bb then bb:Destroy() end end)
            ExitESP[obj] = nil
        end
    end
end

local function TryAddTrap(obj)
    if not Settings.TrapsESP then return end
    if not IsTrap(obj) then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    local target = obj
    if obj:IsA("Model") then
        target = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") or obj
    end
    if not TrapESP[obj] or not TrapESP[obj].Parent then
        local hl = CreateHighlight(target, TRAP_COLOR)
        if hl then TrapESP[obj] = hl end
    end
end

local function ClearTraps()
    for obj, hl in pairs(TrapESP) do pcall(function() hl:Destroy() end) end
    table.clear(TrapESP)
end

local function ScanTraps()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsTrap(obj) then TryAddTrap(obj) end
    end
end

local function StartTrapTracking()
    ClearTraps()
    task.spawn(ScanTraps)
    if TrapConnection then TrapConnection:Disconnect() end
    TrapConnection = Workspace.DescendantAdded:Connect(function(obj)
        if IsTrap(obj) then task.defer(TryAddTrap, obj) end
    end)
end

local function StopTrapTracking()
    if TrapConnection then TrapConnection:Disconnect() TrapConnection = nil end
    ClearTraps()
end

local function MaintainTraps()
    if not Settings.TrapsESP then return end
    for obj, hl in pairs(TrapESP) do
        if not obj or not obj.Parent or not hl or not hl.Parent then
            pcall(function() if hl then hl:Destroy() end end)
            TrapESP[obj] = nil
        else
            ForceHighlight(hl, TRAP_COLOR)
        end
    end
end

CreateFOVCircle()

local WeaponLabel = nil

RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()

    local now = tick()
    if now - LastWeaponScan > 0.3 then
        LastWeaponScan = now
        DetectLocalWeapon()
        if WeaponLabel then
            WeaponLabel.Text = string.format("%s | %s | %d", CurrentWeapon, CurrentAmmo, math.floor(BulletSpeed))
        end
    end

    if Settings.AutoAim then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local part, model = GetClosestTarget()
            if part and model then
                local aimPos = GetPredictedPosition(part, model)
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, aimPos)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Settings.Fullbright then SetFullbright(true) end

    if LocalPlayer.Character then
        local myHl = LocalPlayer.Character:FindFirstChild("XenoESP_Highlight")
        if myHl then pcall(function() myHl:Destroy() end) end
        if BotESP[LocalPlayer.Character] then
            pcall(function() BotESP[LocalPlayer.Character]:Destroy() end)
            BotESP[LocalPlayer.Character] = nil
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character.Parent then
                ApplyPlayerESP(player)
                local hum = character:FindFirstChildOfClass("Humanoid")
                local hrp = character:FindFirstChild("HumanoidRootPart")
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if Settings.PlayersESP and PlayerESP[player] and PlayerESP[player].Billboard then
                    local bb = PlayerESP[player].Billboard
                    local healthLabel = bb:FindFirstChild("HealthLabel")
                    local distLabel = bb:FindFirstChild("DistanceLabel")
                    if Settings.PlayersHealth and healthLabel and hum then
                        healthLabel.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                        healthLabel.Visible = true
                    end
                    if Settings.PlayersDistance and distLabel and hrp and myHrp then
                        distLabel.Text = math.floor((hrp.Position - myHrp.Position).Magnitude) .. " S"
                        distLabel.Visible = true
                    end
                end
                if Settings.PlayersLookVector and PlayerESP[player] and PlayerESP[player].LookPart then
                    local head = character:FindFirstChild("Head")
                    local lookPart = PlayerESP[player].LookPart
                    if head and lookPart then
                        local origin = head.Position
                        local look = head.CFrame.LookVector
                        lookPart.CFrame = CFrame.lookAt(origin + look * (Settings.LookLength / 2), origin + look * Settings.LookLength)
                    end
                end
            end
        end
    end

    MaintainBots()
    MaintainExits()
    MaintainTraps()
end)

local function SetupPlayer(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(character)
        RemovePlayerESP(player)
        task.spawn(function()
            local hum = character:WaitForChild("Humanoid", 8)
            if not hum then return end
            hum.Died:Connect(function()
                task.wait(0.15)
                ApplyPlayerESP(player)
            end)
            task.wait(0.7)
            if player.Character == character then ApplyPlayerESP(player) end
        end)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then onCharacterAdded(player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do SetupPlayer(player) end
Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(function(player) RemovePlayerESP(player) end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XenoESP_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 270, 0, 870)
Main.Position = UDim2.new(0.5, -135, 0.5, -435)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.BorderSizePixel = 0
Title.Text = "ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Main

Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local function CreateToggle(name, flag, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 36)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = Main

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 42, 0, 22)
    button.Position = UDim2.new(1, -42, 0.5, -11)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = frame

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 11)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = UDim2.new(0, 2, 0.5, -9)
    circle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    circle.BorderSizePixel = 0
    circle.Parent = button

    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local enabled = Settings[flag] == true

    local function UpdateVisual()
        if enabled then
            button.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
            circle.Position = UDim2.new(1, -20, 0.5, -9)
            circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            circle.Position = UDim2.new(0, 2, 0.5, -9)
            circle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        end
    end

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        Settings[flag] = enabled
        UpdateVisual()

        if flag == "BotsESP" or flag == "NPCHealth" then
            if Settings.BotsESP or Settings.NPCHealth then StartBotTracking() else StopBotTracking() end
            if not Settings.BotsESP then ClearBots() end
            if not Settings.NPCHealth then ClearBotHealth() end
            if Settings.BotsESP or Settings.NPCHealth then ScanAiZones() end
        elseif flag == "ExitsESP" then
            if enabled then StartExitTracking() else StopExitTracking() end
        elseif flag == "TrapsESP" then
            if enabled then StartTrapTracking() else StopTrapTracking() end
        elseif flag == "Fullbright" then
            SetFullbright(enabled)
        elseif flag == "AutoAim" then
            UpdateFOVCircle()
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                ApplyPlayerESP(plr)
            end
        end
    end)

    UpdateVisual()
end

CreateToggle("Players ESP", "PlayersESP", 50)
CreateToggle("Players Name", "PlayersName", 95)
CreateToggle("Players Health", "PlayersHealth", 140)
CreateToggle("Players Distance", "PlayersDistance", 185)
CreateToggle("Players Look Vector", "PlayersLookVector", 230)
CreateToggle("Bots ESP", "BotsESP", 275)
CreateToggle("NPC Health", "NPCHealth", 320)
CreateToggle("Exits ESP", "ExitsESP", 365)
CreateToggle("Traps ESP", "TrapsESP", 410)
CreateToggle("Fullbright", "Fullbright", 455)

local AimSep = Instance.new("TextLabel")
AimSep.Size = UDim2.new(1, -20, 0, 20)
AimSep.Position = UDim2.new(0, 10, 0, 495)
AimSep.BackgroundTransparency = 1
AimSep.Text = "— Aim —"
AimSep.TextColor3 = Color3.fromRGB(150, 150, 160)
AimSep.Font = Enum.Font.GothamBold
AimSep.TextSize = 13
AimSep.Parent = Main

CreateToggle("Auto Aim", "AutoAim", 515)
CreateToggle("Aim NPCs", "AimNPCs", 560)
CreateToggle("Aim at Head", "AimHead", 605)

WeaponLabel = Instance.new("TextLabel")
WeaponLabel.Size = UDim2.new(1, -20, 0, 40)
WeaponLabel.Position = UDim2.new(0, 10, 0, 650)
WeaponLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
WeaponLabel.BorderSizePixel = 0
WeaponLabel.Text = "None | Default | 2600"
WeaponLabel.TextColor3 = Color3.fromRGB(0, 220, 140)
WeaponLabel.Font = Enum.Font.GothamBold
WeaponLabel.TextSize = 11
WeaponLabel.TextWrapped = true
WeaponLabel.Parent = Main
Instance.new("UICorner", WeaponLabel).CornerRadius = UDim.new(0, 6)

local function MakeField(labelText, default, y, onCommit)
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, -20, 0, 16)
    lab.Position = UDim2.new(0, 10, 0, y)
    lab.BackgroundTransparency = 1
    lab.Text = labelText
    lab.TextColor3 = Color3.fromRGB(180, 180, 180)
    lab.Font = Enum.Font.Gotham
    lab.TextSize = 12
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Parent = Main

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 0, 24)
    box.Position = UDim2.new(0, 10, 0, y + 16)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    box.BorderSizePixel = 0
    box.Text = default
    box.PlaceholderText = default
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = Main
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    box.FocusLost:Connect(function() onCommit(box) end)
    return box
end

MakeField("Aim Radius (min 5):", "100", 700, function(box)
    local n = tonumber(box.Text)
    if n and n >= 5 then Settings.AimRadius = n UpdateFOVCircle() else box.Text = tostring(Settings.AimRadius) end
end)

MakeField("Teammate Name:", "", 750, function(box)
    Settings.TeammateName = box.Text
    for _, plr in ipairs(Players:GetPlayers()) do ApplyPlayerESP(plr) end
end)

MakeField("Look Length (studs):", "5", 800, function(box)
    local n = tonumber(box.Text)
    if n and n > 0 then Settings.LookLength = n UpdateLookPartsSize() else box.Text = tostring(Settings.LookLength) end
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Main
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.K then
        Main.Visible = not Main.Visible
    end
end)
