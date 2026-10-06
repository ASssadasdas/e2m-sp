if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
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
    ExitsESP = false,
    Fullbright = false,
    TeammateName = "",
    LookLength = 5,
}

local PLAYER_COLOR = Color3.fromRGB(255, 255, 255)
local DEAD_COLOR = Color3.fromRGB(255, 0, 0)
local BOT_COLOR = Color3.fromRGB(255, 140, 0)
local LOOK_COLOR = Color3.fromRGB(0, 80, 255)
local OUTLINE_COLOR = Color3.fromRGB(255, 0, 0)
local TEAM_COLOR = Color3.fromRGB(0, 255, 0)
local EXIT_COLOR = Color3.fromRGB(0, 255, 0)

local PlayerESP = {}
local BotESP = {}
local ExitESP = {}
local BotConnections = {}
local ExitConnections = {}

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient,
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

    if not Settings.PlayersESP and not Settings.PlayersLookVector then
        RemovePlayerESP(player)
        return
    end

    if not PlayerESP[player] then
        PlayerESP[player] = {}
    end

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
            if healthLabel then
                healthLabel.Visible = Settings.PlayersHealth
            end
            if distLabel then
                distLabel.Visible = Settings.PlayersDistance
            end
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
    if not Settings.BotsESP then return end
    if not model:IsA("Model") then return end
    if model == LocalPlayer.Character then return end
    if not IsAlive(model) then return end

    if not BotESP[model] or not BotESP[model].Parent then
        local hl = CreateHighlight(model, BOT_COLOR)
        if hl then
            BotESP[model] = hl
        end
    end
end

local function ClearBots()
    for model, hl in pairs(BotESP) do
        pcall(function() hl:Destroy() end)
    end
    table.clear(BotESP)
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
    ClearBots()
    ScanAiZones()

    local aiZones = Workspace:FindFirstChild("AiZones")
    if not aiZones then return end

    for _, conn in pairs(BotConnections) do
        conn:Disconnect()
    end
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
    for _, conn in pairs(BotConnections) do
        conn:Disconnect()
    end
    table.clear(BotConnections)
    ClearBots()
end

local function MaintainBots()
    if not Settings.BotsESP then return end

    for model, hl in pairs(BotESP) do
        if not model or not model.Parent or model == LocalPlayer.Character or not IsAlive(model) then
            pcall(function() hl:Destroy() end)
            BotESP[model] = nil
        else
            ForceHighlight(hl, BOT_COLOR)
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
    for obj, bb in pairs(ExitESP) do
        pcall(function() bb:Destroy() end)
    end
    table.clear(ExitESP)
end

local function ScanExits()
    local noCollision = Workspace:FindFirstChild("NoCollision")
    if not noCollision then return end

    local exitLocations = noCollision:FindFirstChild("ExitLocations")
    if not exitLocations then return end

    for _, obj in ipairs(exitLocations:GetChildren()) do
        TryAddExit(obj)
    end
end

local function StartExitTracking()
    ClearExits()
    ScanExits()

    local noCollision = Workspace:FindFirstChild("NoCollision")
    if not noCollision then return end

    local exitLocations = noCollision:FindFirstChild("ExitLocations")
    if not exitLocations then return end

    for _, conn in pairs(ExitConnections) do
        conn:Disconnect()
    end
    table.clear(ExitConnections)

    table.insert(ExitConnections, exitLocations.ChildAdded:Connect(function(obj)
        task.defer(TryAddExit, obj)
    end))
end

local function StopExitTracking()
    for _, conn in pairs(ExitConnections) do
        conn:Disconnect()
    end
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

RunService.Heartbeat:Connect(function()
    if Settings.Fullbright then
        SetFullbright(true)
    end

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
                        local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
                        distLabel.Text = dist .. " S"
                        distLabel.Visible = true
                    end
                end

                if Settings.PlayersLookVector and PlayerESP[player] and PlayerESP[player].LookPart then
                    local head = character:FindFirstChild("Head")
                    local lookPart = PlayerESP[player].LookPart
                    if head and lookPart then
                        local origin = head.Position
                        local look = head.CFrame.LookVector
                        local mid = origin + look * (Settings.LookLength / 2)
                        lookPart.CFrame = CFrame.lookAt(mid, mid + look)
                    end
                end
            end
        end
    end

    MaintainBots()
    MaintainExits()
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
            if player.Character == character then
                ApplyPlayerESP(player)
            end
        end)
    end

    player.CharacterAdded:Connect(onCharacterAdded)

    if player.Character then
        onCharacterAdded(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

Players.PlayerAdded:Connect(SetupPlayer)

Players.PlayerRemoving:Connect(function(player)
    RemovePlayerESP(player)
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XenoESP_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 560)
Main.Position = UDim2.new(0.5, -130, 0.5, -280)
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

    local enabled = false

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

        if flag == "BotsESP" then
            if enabled then
                StartBotTracking()
            else
                StopBotTracking()
            end
        elseif flag == "ExitsESP" then
            if enabled then
                StartExitTracking()
            else
                StopExitTracking()
            end
        elseif flag == "Fullbright" then
            SetFullbright(enabled)
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
CreateToggle("Exits ESP", "ExitsESP", 320)
CreateToggle("Fullbright", "Fullbright", 365)

local TeamLabel = Instance.new("TextLabel")
TeamLabel.Size = UDim2.new(1, -20, 0, 18)
TeamLabel.Position = UDim2.new(0, 10, 0, 408)
TeamLabel.BackgroundTransparency = 1
TeamLabel.Text = "Teammate Name:"
TeamLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
TeamLabel.Font = Enum.Font.Gotham
TeamLabel.TextSize = 13
TeamLabel.TextXAlignment = Enum.TextXAlignment.Left
TeamLabel.Parent = Main

local TeamBox = Instance.new("TextBox")
TeamBox.Size = UDim2.new(1, -20, 0, 26)
TeamBox.Position = UDim2.new(0, 10, 0, 426)
TeamBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TeamBox.BorderSizePixel = 0
TeamBox.Text = ""
TeamBox.PlaceholderText = "Teammate username..."
TeamBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TeamBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
TeamBox.Font = Enum.Font.Gotham
TeamBox.TextSize = 14
TeamBox.ClearTextOnFocus = false
TeamBox.Parent = Main

Instance.new("UICorner", TeamBox).CornerRadius = UDim.new(0, 6)

TeamBox.FocusLost:Connect(function()
    Settings.TeammateName = TeamBox.Text
    for _, plr in ipairs(Players:GetPlayers()) do
        ApplyPlayerESP(plr)
    end
end)

local LookLabel = Instance.new("TextLabel")
LookLabel.Size = UDim2.new(1, -20, 0, 18)
LookLabel.Position = UDim2.new(0, 10, 0, 460)
LookLabel.BackgroundTransparency = 1
LookLabel.Text = "Look Length (studs):"
LookLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
LookLabel.Font = Enum.Font.Gotham
LookLabel.TextSize = 13
LookLabel.TextXAlignment = Enum.TextXAlignment.Left
LookLabel.Parent = Main

local LookBox = Instance.new("TextBox")
LookBox.Size = UDim2.new(1, -20, 0, 26)
LookBox.Position = UDim2.new(0, 10, 0, 478)
LookBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
LookBox.BorderSizePixel = 0
LookBox.Text = "5"
LookBox.PlaceholderText = "5"
LookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
LookBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
LookBox.Font = Enum.Font.Gotham
LookBox.TextSize = 14
LookBox.ClearTextOnFocus = false
LookBox.Parent = Main

Instance.new("UICorner", LookBox).CornerRadius = UDim.new(0, 6)

LookBox.FocusLost:Connect(function()
    local num = tonumber(LookBox.Text)
    if num and num > 0 then
        Settings.LookLength = num
        UpdateLookPartsSize()
    else
        LookBox.Text = tostring(Settings.LookLength)
    end
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
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.K then
        Main.Visible = not Main.Visible
    end
end)
