if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
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
}

local PLAYER_COLOR = Color3.fromRGB(255, 255, 255)
local DEAD_COLOR   = Color3.fromRGB(255, 0, 0)
local BOT_COLOR    = Color3.fromRGB(255, 140, 0)
local LOOK_COLOR   = Color3.fromRGB(0, 80, 255)
local OUTLINE_COLOR = Color3.fromRGB(255, 0, 0)

local PlayerESP = {}
local BotESP = {}
local LOOK_LENGTH = 2.5

local function IsAlive(character)
    if not character then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    return hum.Health > 0
end

local function CreateHighlight(character, fillColor)
    local old = character:FindFirstChild("XenoESP_Highlight")
    if old then old:Destroy() end

    local hl = Instance.new("Highlight")
    hl.Name = "XenoESP_Highlight"
    hl.Adornee = character
    hl.FillColor = fillColor
    hl.OutlineColor = OUTLINE_COLOR
    hl.FillTransparency = 0.75
    hl.OutlineTransparency = 0.75
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = character
    return hl
end

local function CreateBillboard(character)
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if not head then return nil end

    local old = head:FindFirstChild("XenoESP_Billboard")
    if old then old:Destroy() end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "XenoESP_Billboard"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 220, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3.4, 0)
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
    part.Size = Vector3.new(0.035, 0.035, LOOK_LENGTH)
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

local function RemovePlayerESP(player)
    if PlayerESP[player] then
        pcall(function()
            if PlayerESP[player].Highlight then
                PlayerESP[player].Highlight:Destroy()
            end
            if PlayerESP[player].Billboard then
                PlayerESP[player].Billboard:Destroy()
            end
            if PlayerESP[player].LookPart then
                PlayerESP[player].LookPart:Destroy()
            end
        end)
        PlayerESP[player] = nil
    end
end

local function ApplyPlayerESP(player)
    if player == LocalPlayer then return end

    local character = player.Character
    if not character or not character.Parent then
        return
    end

    if not Settings.PlayersESP and not Settings.PlayersLookVector then
        RemovePlayerESP(player)
        return
    end

    if not PlayerESP[player] then
        PlayerESP[player] = {}
    end

    if Settings.PlayersESP then
        local fillColor = IsAlive(character) and PLAYER_COLOR or DEAD_COLOR

        local hl = PlayerESP[player].Highlight
        if not hl or not hl.Parent or hl.Adornee ~= character then
            PlayerESP[player].Highlight = CreateHighlight(character, fillColor)
        else
            hl.FillColor = fillColor
            hl.OutlineColor = OUTLINE_COLOR
            hl.FillTransparency = 0.75
            hl.OutlineTransparency = 0.75
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
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
        end
    else
        if PlayerESP[player].LookPart then
            pcall(function() PlayerESP[player].LookPart:Destroy() end)
            PlayerESP[player].LookPart = nil
        end
    end
end

local function IsBot(model)
    if not model:IsA("Model") then return false end
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then return false end
    end
    return true
end

local function UpdateBots()
    if not Settings.BotsESP then
        for model, hl in pairs(BotESP) do
            pcall(function() hl:Destroy() end)
        end
        table.clear(BotESP)
        return
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and IsBot(obj) then
            if not BotESP[obj] or not BotESP[obj].Parent then
                BotESP[obj] = CreateHighlight(obj, BOT_COLOR)
            end
        end
    end

    for model, hl in pairs(BotESP) do
        if not model.Parent or not IsBot(model) then
            pcall(function() hl:Destroy() end)
            BotESP[model] = nil
        end
    end
end

local lastBotUpdate = 0

RunService.Heartbeat:Connect(function()
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
                        local mid = origin + look * (LOOK_LENGTH / 2)
                        lookPart.CFrame = CFrame.lookAt(mid, mid + look)
                    end
                end
            end
        end
    end

    if Settings.BotsESP and tick() - lastBotUpdate > 1.5 then
        lastBotUpdate = tick()
        UpdateBots()
    end
end)

local function SetupPlayer(player)
    if player == LocalPlayer then return end

    local function onCharacterAdded(character)
        RemovePlayerESP(player)

        task.spawn(function()
            local hum = character:WaitForChild("Humanoid", 8)
            if not hum then return end

            hum.Died:Connect(function()
                task.wait(0.1)
                ApplyPlayerESP(player)
            end)

            task.wait(0.6)
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
Main.Size = UDim2.new(0, 260, 0, 370)
Main.Position = UDim2.new(0.5, -130, 0.5, -185)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.BorderSizePixel = 0
Title.Text = "ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

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

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 11)
    btnCorner.Parent = button

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = UDim2.new(0, 2, 0.5, -9)
    circle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    circle.BorderSizePixel = 0
    circle.Parent = button

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

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

        if flag == "PlayersESP" or flag == "PlayersLookVector" or flag == "PlayersName" or flag == "PlayersDistance" or flag == "PlayersHealth" then
            for _, plr in ipairs(Players:GetPlayers()) do
                ApplyPlayerESP(plr)
            end
        elseif flag == "BotsESP" then
            UpdateBots()
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

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.K then
        Main.Visible = not Main.Visible
    end
end)
