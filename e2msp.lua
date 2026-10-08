if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    BulletTracers = false,
    NoGrass = false,
    AutoAim = false,
    AimNPCs = false,
    AimRadius = 100,
    AimHead = true,
    AimYOffset = 0,
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
local TRACER_COLOR = Color3.fromRGB(255, 220, 50)

local PlayerESP = {}
local BotESP = {}
local BotHealth = {}
local ExitESP = {}
local TrapESP = {}
local CorpseESP = {}
local BotConnections = {}
local ExitConnections = {}
local TrapConnection = nil
local TracerAddedConn = nil
local TrackedBullets = {}
local GrassRegionConn = nil

local FOVCircle = nil
local hasDrawing = pcall(function() return Drawing end) and Drawing ~= nil

local CurrentWeapon = "None"
local CurrentAmmo = "Default"
local CurrentCaliber = ""
local BulletSpeed = 700
local DropMult = 1
local SpeedSource = "base"
local LastWeaponScan = 0
local MeasuredSpeed = nil
local MeasuredSamples = 0

local BALLISTIC_G = 55

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

local WeaponDB = {
    {"tfz98s", 0.45, "338"}, {"tfz-98s", 0.45, "338"}, {"tfz 98s", 0.45, "338"},
    {"tfz98", 0.45, "338"}, {"mod-98s", 0.45, "338"}, {"mod98s", 0.45, "338"},
    {"mod-98", 0.45, "338"}, {"task force zero", 0.45, "338"},
    {"r700", 0.45, "338"}, {"remington", 0.45, "338"},
    {"svd", 0.55, "76254"}, {"mosin", 0.55, "76254"}, {"pkm", 0.55, "76254"},
    {"fn-fal", 0.60, "76251"}, {"fal", 0.60, "76251"},
    {"m4a1", 0.50, "556"}, {"m4", 0.50, "556"}, {"adar", 0.50, "556"},
    {"akmn", 0.70, "76239"}, {"akm", 0.72, "76239"}, {"sks", 0.70, "76239"},
    {"as val", 1.15, "939"}, {"val", 1.15, "939"},
    {"groza", 1.15, "939"}, {"ots-14", 1.15, "939"},
    {"mp5", 1.05, "919"}, {"mp443", 1.05, "919"}, {"yarygin", 1.05, "919"},
    {"mk23", 1.05, "45"},
    {"ppsh", 1.08, "76225"}, {"tt-33", 1.08, "76225"},
    {"tokarev", 1.08, "76225"}, {"nagant", 1.08, "76225"},
    {"makarov", 1.25, "918"}, {"skorpion", 1.20, "918"}, {"mod-0", 1.20, "918"},
    {"saiga", 1.30, "12ga"}, {"izh-81", 1.35, "12ga"},
    {"izh-12", 1.35, "12ga"}, {"izh", 1.35, "12ga"}, {"toz", 1.35, "12ga"},
    {"rpg", 2.00, "rpg"},
    {"knife", 0, "melee"}, {"karambit", 0, "melee"},
    {"machete", 0, "melee"}, {"dv-2", 0, "melee"},
}

-- .338 LM: Tracer 992 m/s, AP 1015 m/s (TFZ98S / wiki)
local WikiVelocity = {
    ["918"] = {tracer = 359, ap = 383, tfz = 404},
    ["919"] = {tracer = 465, ap = 500, tfz = 500},
    ["76225"] = {tracer = 460, ap = 484, tfz = 484},
    ["45"] = {tracer = 465, ap = 515, tfz = 515},
    ["76239"] = {tracer = 715, ap = 767, tfz = 767},
    ["76254"] = {tracer = 885, ap = 940, tfz = 940},
    ["76251"] = {tracer = 820, ap = 900, tfz = 900},
    ["556"] = {tracer = 933, ap = 1000, tfz = 1000},
    ["939"] = {tracer = 357, ap = 357, tfz = 450},
    ["338"] = {tracer = 992, ap = 1015, tfz = 1015, t = 992},
    ["12ga"] = {tracer = 425, ap = 425, buckshot = 425, slug = 405, flechette = 340, ["ap-20"] = 625},
    ["rpg"] = {tracer = 200, ap = 200, tfz = 200},
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

local function TryHideTerrainDecoration()
    local terrain = Workspace.Terrain
    if not terrain then return end
    pcall(function()
        if typeof(sethiddenproperty) == "function" then
            sethiddenproperty(terrain, "Decoration", false)
        end
    end)
    pcall(function()
        if typeof(setscriptable) == "function" then
            setscriptable(terrain, "Decoration", true)
            terrain.Decoration = false
        end
    end)
    pcall(function()
        if typeof(sethiddenproperty) == "function" then
            sethiddenproperty(terrain, "GrassLength", 0.1)
        end
    end)
    pcall(function() terrain.Decoration = false end)
end

local function StripGrassAround(center, half)
    local terrain = Workspace.Terrain
    if not terrain or not center then return end
    half = half or 256
    local step = 128
    for ox = -half, half, step do
        for oz = -half, half, step do
            local min = Vector3.new(center.X + ox, center.Y - 64, center.Z + oz)
            local max = Vector3.new(center.X + ox + step, center.Y + 64, center.Z + oz + step)
            local region = Region3.new(min, max):ExpandToGrid(4)
            pcall(function()
                terrain:ReplaceMaterial(region, 4, Enum.Material.Grass, Enum.Material.Ground)
                terrain:ReplaceMaterial(region, 4, Enum.Material.LeafyGrass, Enum.Material.Ground)
            end)
        end
        task.wait()
    end
end

local function SetNoGrass(enabled)
    local terrain = Workspace.Terrain
    if not terrain then return end
    if enabled then
        TryHideTerrainDecoration()
        local function runStrip()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then StripGrassAround(hrp.Position, 384) end
        end
        runStrip()
        if GrassRegionConn then GrassRegionConn:Disconnect() end
        GrassRegionConn = RunService.Heartbeat:Connect(function()
            TryHideTerrainDecoration()
        end)
        task.spawn(function()
            while Settings.NoGrass do
                runStrip()
                task.wait(2.5)
            end
        end)
    else
        if GrassRegionConn then
            GrassRegionConn:Disconnect()
            GrassRegionConn = nil
        end
    end
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
            return name, entry[2], entry[3]
        end
    end
    return nil
end

local function ClassifyAmmoString(s)
    if not s then return nil end
    local l = string.lower(tostring(s))
    -- .338 LM T / Tracer
    if string.find(l, "338") and (l == "t" or string.find(l, " lm t", 1, true)
        or string.find(l, "lm t", 1, true) or string.find(l, ".338 lm t", 1, true)
        or string.find(l, "338t", 1, true)) then
        return "tracer", "Tracer"
    end
    if string.find(l, "tfz", 1, true) or string.find(l, "cqb", 1, true) then return "tfz", "TFZ" end
    if string.find(l, "flechette", 1, true) then return "flechette", "Flechette" end
    if string.find(l, "ap-20", 1, true) or string.find(l, "ap20", 1, true) then return "ap-20", "AP-20" end
    if string.find(l, "slug", 1, true) then return "slug", "Slug" end
    if string.find(l, "buck", 1, true) then return "buckshot", "Buckshot" end
    if string.find(l, "armor", 1, true) or string.find(l, "piercing", 1, true)
        or string.find(l, "ap ", 1, true) or string.find(l, " ap", 1, true)
        or l == "ap" or string.find(l, "_ap", 1, true)
        or string.find(l, "338 lm ap", 1, true) or string.find(l, ".338 lm ap", 1, true) then
        return "ap", "AP"
    end
    if string.find(l, "tracer", 1, true) or (l == "t" or string.find(l, " lm t", 1, true)) then
        return "tracer", "Tracer"
    end
    return nil
end

local AmmoTypesFolder = nil
local function FindAmmoTypes()
    if AmmoTypesFolder and AmmoTypesFolder.Parent then return AmmoTypesFolder end
    for _, root in ipairs({ReplicatedStorage, game:GetService("ReplicatedFirst"), Workspace}) do
        local found = root:FindFirstChild("AmmoTypes", true)
        if found then
            AmmoTypesFolder = found
            return found
        end
    end
    return nil
end

local function ReadMuzzleVelocityFromGame(searchName)
    local folder = FindAmmoTypes()
    if not folder or not searchName then return nil end
    local node = folder:FindFirstChild(searchName)
    if node then
        local v = node:GetAttribute("MuzzleVelocity")
        if typeof(v) == "number" and v > 10 then return v end
    end
    local lower = string.lower(tostring(searchName))
    for _, child in ipairs(folder:GetChildren()) do
        local n = string.lower(child.Name)
        if string.find(n, lower, 1, true) or string.find(lower, n, 1, true) then
            local v = child:GetAttribute("MuzzleVelocity")
            if typeof(v) == "number" and v > 10 then return v end
        end
    end
    return nil
end

local function ResolveBulletSpeed(caliberKey, ammoType, detectedAmmoName)
    if MeasuredSpeed and MeasuredSamples >= 3 then
        SpeedSource = "LIVE"
        return math.clamp(MeasuredSpeed, 80, 3000)
    end
    if detectedAmmoName then
        local v = ReadMuzzleVelocityFromGame(detectedAmmoName)
        if v then SpeedSource = "game" return v end
    end
    local folder = FindAmmoTypes()
    if folder and caliberKey then
        for _, child in ipairs(folder:GetChildren()) do
            local n = string.lower(child.Name)
            local matchCal = string.find(n, string.lower(caliberKey), 1, true)
                or (caliberKey == "556" and (string.find(n, "5.56", 1, true) or string.find(n, "556", 1, true)))
                or (caliberKey == "76239" and string.find(n, "7.62x39", 1, true))
                or (caliberKey == "76254" and string.find(n, "7.62x54", 1, true))
                or (caliberKey == "76251" and string.find(n, "7.62x51", 1, true))
                or (caliberKey == "338" and (string.find(n, "338", 1, true) or string.find(n, ".338", 1, true)))
                or (caliberKey == "918" and string.find(n, "9x18", 1, true))
                or (caliberKey == "919" and string.find(n, "9x19", 1, true))
                or (caliberKey == "939" and string.find(n, "9x39", 1, true))
                or (caliberKey == "12ga" and (string.find(n, "12ga", 1, true) or string.find(n, "12 ga", 1, true)))
            if matchCal then
                local isAP = string.find(n, "ap", 1, true) or string.find(n, "armor", 1, true)
                local isTFZ = string.find(n, "tfz", 1, true) or string.find(n, "cqb", 1, true)
                local isTracer = string.find(n, "tracer", 1, true) or string.find(n, " lm t", 1, true)
                    or n:match("%st$") or string.find(n, ".338 lm t", 1, true)
                local want = ammoType or "tracer"
                local ok = (want == "ap" and isAP) or (want == "tfz" and isTFZ) or (want == "tracer" and isTracer)
                    or (want == "slug" and string.find(n, "slug", 1, true))
                    or (want == "flechette" and string.find(n, "flechette", 1, true))
                    or (want == "ap-20" and string.find(n, "ap-20", 1, true))
                    or (want == "buckshot" and string.find(n, "buck", 1, true))
                if ok then
                    local v = child:GetAttribute("MuzzleVelocity")
                    if typeof(v) == "number" and v > 10 then
                        SpeedSource = "game"
                        return v
                    end
                end
            end
        end
    end
    local w = WikiVelocity[caliberKey or ""]
    if w then
        SpeedSource = "wiki"
        if ammoType == "tracer" or ammoType == "t" then
            return w.tracer or w.t or 700
        end
        return w[ammoType or "tracer"] or w.tracer or 700
    end
    SpeedSource = "base"
    return 700
end

local function DetectAmmoOnObject(obj)
    local ammoType, ammoName, found = "tracer", "Tracer", false
    local detectedName = nil
    local function try(s)
        if not s then return false end
        local t, n = ClassifyAmmoString(s)
        if t then
            ammoType, ammoName, found = t, n, true
            detectedName = tostring(s)
            return true
        end
        return false
    end
    if obj then
        local props = obj:FindFirstChild("ItemProperties")
        if props then
            for _, key in ipairs({
                "Ammo", "AmmoType", "AmmoName", "Cartridge", "Bullet", "Round",
                "Caliber", "LoadedAmmo", "CurrentAmmo", "Chambered", "ActiveAmmo",
                "CallSign", "Name", "Type"
            }) do
                if try(props:GetAttribute(key)) then break end
            end
            if not found then
                for attr, val in pairs(props:GetAttributes()) do
                    if try(val) then break end
                    if try(attr) then break end
                end
            end
        end
        if not found then
            try(obj:GetAttribute("Ammo"))
            try(obj:GetAttribute("AmmoType"))
            try(GetCallSign(obj))
        end
        if not found then
            for _, desc in ipairs(obj:GetDescendants()) do
                local n = string.lower(desc.Name)
                if string.find(n, "ammo", 1, true) or string.find(n, "mag", 1, true)
                    or string.find(n, "round", 1, true) or string.find(n, "bullet", 1, true)
                    or string.find(n, "338", 1, true) then
                    if try(desc.Name) then break end
                    if desc:IsA("StringValue") and try(desc.Value) then break end
                    local p = desc:FindFirstChild("ItemProperties")
                    if p then
                        if try(p:GetAttribute("CallSign")) then break end
                        if try(p:GetAttribute("Name")) then break end
                        if try(p:GetAttribute("AmmoType")) then break end
                    end
                end
            end
        end
    end
    return ammoType, ammoName, found, detectedName
end

local function DetectLocalWeapon()
    local char = LocalPlayer.Character
    if not char then
        CurrentWeapon, CurrentAmmo, CurrentCaliber = "None", "Default", ""
        BulletSpeed, DropMult, SpeedSource = 700, 1, "base"
        return
    end
    local function apply(name, drop, cal, obj)
        CurrentWeapon = name
        DropMult = drop
        CurrentCaliber = cal
        local ammoType, ammoName, found, detectedName = DetectAmmoOnObject(obj)
        CurrentAmmo = found and ammoName or ("?/" .. ammoName)
        BulletSpeed = ResolveBulletSpeed(cal, ammoType, detectedName or ammoName)
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local m, d, c = MatchWeapon(GetCallSign(tool) or tool.Name)
        if m then apply(m, d, c, tool) return end
    end
    for _, child in ipairs(char:GetChildren()) do
        if (child:IsA("Model") or child:IsA("Tool")) and not string.find(string.lower(child.Name), "clothing", 1, true) then
            local m, d, c = MatchWeapon(GetCallSign(child))
            if m then apply(m, d, c, child) return end
        end
    end
    for _, child in ipairs(Camera:GetChildren()) do
        if child:IsA("Model") then
            local m, d, c = MatchWeapon(GetCallSign(child) or child.Name)
            if m then apply(m, d, c, child) return end
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("Model") then
                    m, d, c = MatchWeapon(GetCallSign(sub) or sub.Name)
                    if m then apply(m, d, c, sub) return end
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
                        local m, d, c = MatchWeapon(GetCallSign(model) or model.Name)
                        if m then apply(m, d, c, model) return end
                    end
                end
            end
        end
    end
    CurrentWeapon, CurrentAmmo, CurrentCaliber = "Unknown", "Default", ""
    if MeasuredSpeed and MeasuredSamples >= 3 then
        BulletSpeed, SpeedSource = MeasuredSpeed, "LIVE"
    else
        BulletSpeed, SpeedSource = 700, "base"
    end
    DropMult = 1
end

local function GetEffectiveSpeed()
    return math.clamp(BulletSpeed, 80, 3000)
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
    end
    return character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")
end

local function GetVelocity(model)
    local hrp = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
    if hrp then return hrp.AssemblyLinearVelocity end
    return Vector3.zero
end

local function GetMyVelocity()
    local char = LocalPlayer.Character
    if not char then return Vector3.zero end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.AssemblyLinearVelocity end
    return Vector3.zero
end

local function GetPredictedPosition(part, model)
    local camPos = Camera.CFrame.Position
    local pos = part.Position
    local dist = (pos - camPos).Magnitude
    if dist < 0.05 then return pos end

    local heightDiff = pos.Y - camPos.Y
    local relVel = GetVelocity(model) - GetMyVelocity()
    local speed = GetEffectiveSpeed()
    local t = dist / speed

    local hRel = Vector3.new(relVel.X, 0, relVel.Z)
    local hSpeed = hRel.Magnitude

    local leadBlend = math.clamp((dist - 8) / 40, 0, 1)
    leadBlend = leadBlend * leadBlend * (3 - 2 * leadBlend)

    local maxLead = 0.28 + math.clamp(hSpeed / 80, 0, 0.15)
    local leadT = math.min(t * (0.55 + 0.45 * leadBlend), maxLead)

    local damp = 1 / (1 + hSpeed / 90)

    local runBoost = 1
    if hSpeed > 14 then
        runBoost = 1.15 + math.clamp((hSpeed - 14) / 20, 0, 0.35)
    end

    local lateral = hRel * leadT * damp * runBoost
    local vertical = relVel.Y * leadT * 0.2

    local g = BALLISTIC_G * DropMult
    local drop = 0.5 * g * t * t

    if dist < 45 then
        local f = dist / 45
        drop = drop * (f * f)
    elseif dist < 90 then
        drop = drop * (0.4 + 0.6 * ((dist - 45) / 45))
    end

    if heightDiff > 15 then
        drop = drop + (heightDiff - 15) * 0.01
    elseif heightDiff < -15 then
        drop = math.max(0, drop + (heightDiff + 15) * 0.008)
    end

    drop = math.clamp(drop, 0, 10)
    local manual = Settings.AimYOffset or 0

    return pos + lateral + Vector3.new(0, vertical + drop + manual, 0)
end

local function IsPartInFOV(part, center, radius)
    if not part then return false, math.huge end
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen or screenPos.Z < 0 then return false, math.huge end
    local d = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return d <= radius, d
end

local function GetClosestTarget()
    local closestPart, closestModel = nil, nil
    local closestDist = Settings.AimRadius
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

    local function checkModel(model)
        if not model or not IsAlive(model) then return end
        local anyInFOV, best = false, math.huge
        for _, partName in ipairs(BodyParts) do
            local part = model:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                local inFOV, d = IsPartInFOV(part, center, Settings.AimRadius)
                if inFOV then
                    anyInFOV = true
                    if d < best then best = d end
                end
            end
        end
        if not anyInFOV then return end
        local aimPart = GetAimPart(model)
        if not aimPart then return end
        if best < closestDist then
            closestDist, closestPart, closestModel = best, aimPart, model
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
    if hl.Parent == LocalPlayer.Character then pcall(function() hl:Destroy() end) return end
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
    for _, info in ipairs({
        {"NameLabel", 0, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold},
        {"HealthLabel", 18, Color3.fromRGB(0, 255, 100), Enum.Font.Gotham},
        {"DistanceLabel", 36, Color3.fromRGB(200, 200, 200), Enum.Font.Gotham},
    }) do
        local lab = Instance.new("TextLabel")
        lab.Name = info[1]
        lab.Size = UDim2.new(1, 0, 0, 18)
        lab.Position = UDim2.new(0, 0, 0, info[2])
        lab.BackgroundTransparency = 1
        lab.TextColor3 = info[3]
        lab.TextStrokeTransparency = 0.25
        lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lab.Font = info[4]
        lab.TextSize = 10
        lab.Text = ""
        lab.Visible = false
        lab.Parent = billboard
    end
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
    if not (Settings.PlayersESP or Settings.PlayersLookVector) then
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
            if nameLabel then
                nameLabel.Text = player.Name
                nameLabel.Visible = Settings.PlayersName
            end
            local healthLabel = bb:FindFirstChild("HealthLabel")
            if healthLabel then healthLabel.Visible = Settings.PlayersHealth end
            local distLabel = bb:FindFirstChild("DistanceLabel")
            if distLabel then distLabel.Visible = Settings.PlayersDistance end
        end
    else
        if PlayerESP[player].Highlight then pcall(function() PlayerESP[player].Highlight:Destroy() end) PlayerESP[player].Highlight = nil end
        if PlayerESP[player].Billboard then pcall(function() PlayerESP[player].Billboard:Destroy() end) PlayerESP[player].Billboard = nil end
    end

    if Settings.PlayersLookVector and IsAlive(character) then
        if not PlayerESP[player].LookPart or not PlayerESP[player].LookPart.Parent then
            PlayerESP[player].LookPart = CreateLookPart()
        else
            PlayerESP[player].LookPart.Size = Vector3.new(0.035, 0.035, Settings.LookLength)
        end
    else
        if PlayerESP[player].LookPart then pcall(function() PlayerESP[player].LookPart:Destroy() end) PlayerESP[player].LookPart = nil end
    end
end

local function TryAddCorpse(model)
    if not Settings.PlayersESP then return end
    if not model or not model:IsA("Model") or model == LocalPlayer.Character then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health > 0 then return end
    if not CorpseESP[model] or not CorpseESP[model].Parent then
        local hl = CreateHighlight(model, DEAD_COLOR)
        if hl then CorpseESP[model] = hl end
    else
        ForceHighlight(CorpseESP[model], DEAD_COLOR)
    end
end

local function MaintainCorpses()
    if not Settings.PlayersESP then
        for m, hl in pairs(CorpseESP) do pcall(function() hl:Destroy() end) end
        table.clear(CorpseESP)
        return
    end
    for model, hl in pairs(CorpseESP) do
        if not model or not model.Parent then
            pcall(function() hl:Destroy() end)
            CorpseESP[model] = nil
        else
            ForceHighlight(hl, DEAD_COLOR)
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not IsAlive(plr.Character) then
            TryAddCorpse(plr.Character)
        end
    end
    for _, name in ipairs({"Corpses", "DeadBodies", "Bodies", "Ragdolls", "Debris"}) do
        local folder = Workspace:FindFirstChild(name)
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") then TryAddCorpse(m) end
            end
        end
    end
end

local function TryAddBot(model)
    if not Settings.BotsESP and not Settings.NPCHealth then return end
    if not model:IsA("Model") or model == LocalPlayer.Character or not IsAlive(model) then return end
    if Settings.BotsESP and (not BotESP[model] or not BotESP[model].Parent) then
        local hl = CreateHighlight(model, BOT_COLOR)
        if hl then BotESP[model] = hl end
    end
    if Settings.NPCHealth and (not BotHealth[model] or not BotHealth[model].Parent) then
        BotHealth[model] = CreateNPCHealthBillboard(model)
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
    if not Settings.TrapsESP or not IsTrap(obj) then return end
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

local function GetBulletPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local function LooksLikeBullet(obj)
    if not obj then return false end
    local n = string.lower(obj.Name)
    for _, h in ipairs({"bullet", "projectile", "tracer", "round", "pellet", "slug", "shell", "ammo"}) do
        if string.find(n, h, 1, true) then return true end
    end
    local part = GetBulletPart(obj)
    if part then
        local dist = (part.Position - Camera.CFrame.Position).Magnitude
        local spd = part.AssemblyLinearVelocity.Magnitude
        if dist < 40 and spd > 50 and part.Size.Magnitude < 6 then return true end
    end
    return false
end

local function DrawPathSegment(from, to, folder)
    local dist = (to - from).Magnitude
    if dist < 0.4 then return end
    local seg = Instance.new("Part")
    seg.Name = "XenoPathSeg"
    seg.Anchored = true
    seg.CanCollide = false
    seg.CanQuery = false
    seg.CanTouch = false
    seg.CastShadow = false
    seg.Material = Enum.Material.Neon
    seg.Color = TRACER_COLOR
    seg.Transparency = 0.2
    seg.Size = Vector3.new(0.07, 0.07, dist)
    seg.CFrame = CFrame.lookAt(from:Lerp(to, 0.5), to)
    seg.Parent = folder
end

local function TrackBulletPath(obj)
    if TrackedBullets[obj] then return end
    local part = GetBulletPart(obj)
    if not part then return end
    TrackedBullets[obj] = true
    local folder = Instance.new("Folder")
    folder.Name = "XenoBulletPath"
    folder.Parent = Workspace
    local lastPos = part.Position
    local lastTime = tick()
    local startTime = tick()
    local samples = {}
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - startTime > 3 or not part.Parent then
            conn:Disconnect()
            TrackedBullets[obj] = nil
            task.delay(math.max(0, 3 - (now - startTime)), function()
                pcall(function() folder:Destroy() end)
            end)
            return
        end
        local pos = part.Position
        local dt = now - lastTime
        local moved = (pos - lastPos).Magnitude
        if dt > 0.015 and moved > 0.5 then
            local spd = moved / dt
            if spd > 60 and spd < 5000 then
                table.insert(samples, spd)
                if #samples >= 3 then
                    local sum, n = 0, 0
                    for i = math.max(1, #samples - 4), #samples do
                        sum = sum + samples[i]
                        n = n + 1
                    end
                    local avg = sum / n
                    if not MeasuredSpeed then MeasuredSpeed = avg
                    else MeasuredSpeed = MeasuredSpeed * 0.65 + avg * 0.35 end
                    MeasuredSamples = MeasuredSamples + 1
                    BulletSpeed = MeasuredSpeed
                    SpeedSource = "LIVE"
                end
            end
            DrawPathSegment(lastPos, pos, folder)
            lastPos = pos
            lastTime = now
        end
    end)
    task.delay(3.1, function()
        pcall(function() conn:Disconnect() end)
        TrackedBullets[obj] = nil
        pcall(function() folder:Destroy() end)
    end)
end

local function StartTracers()
    if TracerAddedConn then TracerAddedConn:Disconnect() end
    TracerAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not Settings.BulletTracers then return end
        task.defer(function()
            if LooksLikeBullet(obj) then TrackBulletPath(obj) end
        end)
    end)
end

local function StopTracers()
    if TracerAddedConn then TracerAddedConn:Disconnect() TracerAddedConn = nil end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "XenoBulletPath" then pcall(function() obj:Destroy() end) end
    end
    table.clear(TrackedBullets)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not Settings.BulletTracers then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local t0 = tick()
    local scanConn
    scanConn = Workspace.DescendantAdded:Connect(function(obj)
        if tick() - t0 > 0.35 then scanConn:Disconnect() return end
        task.defer(function()
            local part = GetBulletPart(obj)
            if not part then return end
            local dist = (part.Position - Camera.CFrame.Position).Magnitude
            local spd = part.AssemblyLinearVelocity.Magnitude
            if dist < 50 and (spd > 40 or LooksLikeBullet(obj)) then
                TrackBulletPath(obj)
            end
        end)
    end)
    task.delay(0.35, function() pcall(function() scanConn:Disconnect() end) end)
end)

CreateFOVCircle()
local WeaponLabel = nil

RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()
    local now = tick()
    if now - LastWeaponScan > 0.3 then
        LastWeaponScan = now
        DetectLocalWeapon()
        if WeaponLabel then
            WeaponLabel.Text = string.format("%s | %s | %d (%s)", CurrentWeapon, CurrentAmmo, math.floor(BulletSpeed), SpeedSource)
        end
    end
    if Settings.AutoAim and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local part, model = GetClosestTarget()
        if part and model then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, GetPredictedPosition(part, model))
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
                if Settings.PlayersLookVector and PlayerESP[player] and PlayerESP[player].LookPart and IsAlive(character) then
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
    MaintainCorpses()
end)

local function SetupPlayer(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(character)
        RemovePlayerESP(player)
        task.spawn(function()
            local hum = character:WaitForChild("Humanoid", 8)
            if not hum then return end
            hum.Died:Connect(function()
                task.wait(0.2)
                ApplyPlayerESP(player)
                TryAddCorpse(character)
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
Players.PlayerRemoving:Connect(RemovePlayerESP)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XenoESP_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 270, 0, 1010)
Main.Position = UDim2.new(0.5, -135, 0.5, -505)
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
        elseif flag == "BulletTracers" then
            if enabled then StartTracers() else StopTracers() end
        elseif flag == "NoGrass" then
            SetNoGrass(enabled)
        elseif flag == "AutoAim" then
            UpdateFOVCircle()
        else
            for _, plr in ipairs(Players:GetPlayers()) do ApplyPlayerESP(plr) end
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
CreateToggle("Bullet Tracers", "BulletTracers", 500)
CreateToggle("No Grass", "NoGrass", 545)

local AimSep = Instance.new("TextLabel")
AimSep.Size = UDim2.new(1, -20, 0, 20)
AimSep.Position = UDim2.new(0, 10, 0, 585)
AimSep.BackgroundTransparency = 1
AimSep.Text = "— Aim —"
AimSep.TextColor3 = Color3.fromRGB(150, 150, 160)
AimSep.Font = Enum.Font.GothamBold
AimSep.TextSize = 13
AimSep.Parent = Main

CreateToggle("Auto Aim", "AutoAim", 605)
CreateToggle("Aim NPCs", "AimNPCs", 650)
CreateToggle("Aim at Head", "AimHead", 695)

WeaponLabel = Instance.new("TextLabel")
WeaponLabel.Size = UDim2.new(1, -20, 0, 40)
WeaponLabel.Position = UDim2.new(0, 10, 0, 740)
WeaponLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
WeaponLabel.BorderSizePixel = 0
WeaponLabel.Text = "None | Default | 700 (base)"
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

MakeField("Aim Radius (min 5):", "100", 790, function(box)
    local n = tonumber(box.Text)
    if n and n >= 5 then Settings.AimRadius = n UpdateFOVCircle() else box.Text = tostring(Settings.AimRadius) end
end)

MakeField("Y Offset (+ up / - down):", "0", 840, function(box)
    local n = tonumber(box.Text)
    if n then Settings.AimYOffset = n else box.Text = tostring(Settings.AimYOffset) end
end)

MakeField("Teammate Name:", "", 890, function(box)
    Settings.TeammateName = box.Text
    for _, plr in ipairs(Players:GetPlayers()) do ApplyPlayerESP(plr) end
end)

MakeField("Look Length (studs):", "5", 940, function(box)
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
    StopTracers()
    SetNoGrass(false)
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.K then
        Main.Visible = not Main.Visible
    end
end)
