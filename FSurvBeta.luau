--==================================================
-- ZZZCheat | tg: @wzeqq
--==================================================

local Rayfield = loadstring(game:HttpGet(
    "https://github.com/UnknownDeveloper-sqd/UnknownSquad-RayField-Lib/raw/refs/heads/main/Rayfield/CustomRayfield.luau"
))()

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

--==================================================
-- SETTINGS
--==================================================

local Settings = {
    PlayerESP = false,
    PlayerName = true,
    PlayerHealth = true,
    PlayerDistance = true,
    PlayerItem = true,
    PlayerTextSize = 14,

    BotESP = false,
    BotName = true,
    BotTextSize = 14,

    TimeChanger = false,
    TimeChangerHour = 12,

    AimTargets = {Player = true, NPC = false},
    SmoothAim = false,
    SilentAim = false,
    SilentAimFOV = 180,
    SilentAimMaxDistance = 3000,
    SilentAimPrediction = true,
    SilentAimPredictionStrength = 1,
    SilentAimVisibilityCheck = true,
    SilentAimProjectileSpeed = 550,
    SilentAimGravity = 100,
    AutoPrediction = true,
    VisibilityCheck = true,
    AimPart = "Head",
    Smoothness = 5,
    AimDistance = 3000,
    FOV = 150,
    ShowFOV = true,

    FreeCam = false,
    FreeCamSpeed = 50,
    FreeCamKey = "F",

    AntiAFK = false,
    ChestESP = false,
    OreESP = false,
    StorageESP = false
}

--==================================================
-- ESP COLORS
--==================================================

local ESPColors = {
    PlayerOutline = Color3.fromRGB(255, 255, 255),
    PlayerName = Color3.fromRGB(255, 255, 255),
    PlayerHealth = Color3.fromRGB(80, 255, 100),
    PlayerDistance = Color3.fromRGB(100, 200, 255),
    PlayerItem = Color3.fromRGB(255, 220, 100),

    BotOutline = Color3.fromRGB(255, 140, 50),
    BotName = Color3.fromRGB(255, 140, 50),

    ChestMilitary = Color3.fromRGB(255, 80, 80),
    ChestWood = Color3.fromRGB(100, 255, 120),
    ChestElite = Color3.fromRGB(190, 100, 255)
}

--==================================================
-- STARTUP CONFIG PRELOAD
-- Reads the previous config before the GUI controls are constructed.
--==================================================

local STARTUP_CONFIG_PATH = "ZZZCheat/Configs/Default.json"
local StartupConfigData

pcall(function()
    if readfile and HttpService then
        StartupConfigData = HttpService:JSONDecode(readfile(STARTUP_CONFIG_PATH))
    end
end)

local function mergeStoredTable(destination, source)
    if typeof(destination) ~= "table" or typeof(source) ~= "table" then
        return
    end
    for key, value in pairs(source) do
        local current = destination[key]
        if typeof(current) == "table" and typeof(value) == "table" then
            mergeStoredTable(current, value)
        elseif current ~= nil and typeof(current) == typeof(value) then
            destination[key] = value
        end
    end
end

if typeof(StartupConfigData) == "table" then
    mergeStoredTable(Settings, StartupConfigData.Settings)
    if typeof(StartupConfigData.ESPColors) == "table" then
        for key, rgb in pairs(StartupConfigData.ESPColors) do
            if ESPColors[key] and typeof(rgb) == "table" and #rgb >= 3 then
                ESPColors[key] = Color3.fromRGB(
                    math.clamp(tonumber(rgb[1]) or 255, 0, 255),
                    math.clamp(tonumber(rgb[2]) or 255, 0, 255),
                    math.clamp(tonumber(rgb[3]) or 255, 0, 255)
                )
            end
        end
    end
end

local function preloadExtraSettings(sectionName, destination)
    if typeof(StartupConfigData) == "table" then
        mergeStoredTable(destination, StartupConfigData[sectionName])
    end
end

local function toHex(color)
    return string.format(
        "#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

local function richText(value, color)
    local safeText = tostring(value)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")

    return '<font color="' .. toHex(color) .. '">' .. safeText .. "</font>"
end

--==================================================
-- GUI
--==================================================

local Window = Rayfield:CreateWindow({
    Name = "ZZZCheat",
    LoadingTitle = "ZZZCheat",
    LoadingSubtitle = "tg: @wzeqq",
    Theme = "Amethyst",
    Width = 460,
    Height = 360,
    Font = "Code",

    -- Автосохранение в один локальный конфиг.
    ConfigurationSaving = {
        Enabled = false,
        Folder = "ZZZCheat",
        FileName = "ZZZCheat"
    },

    KeySystem = false
})

local PvpTab = Window:CreateTab("PVP")
local PveTab = Window:CreateTab("PVE")
local VisualsTab = Window:CreateTab("Visuals")
local ColorTab = Window:CreateTab("Colors")

--==================================================
-- GUI PARENT
--==================================================

local GuiParent

pcall(function()
    if gethui then
        GuiParent = gethui()
    end
end)

if not GuiParent then
    GuiParent = LocalPlayer:WaitForChild("PlayerGui")
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ZZZCheatESP"
ESPFolder.Parent = GuiParent

local InjectionNotificationGui = nil

--==================================================
-- ESP CACHE
--==================================================

local HighlightCache = {}
local InfoCache = {}
local BotHighlightCache = {}
local BotInfoCache = {}

local function createHighlight(color)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ZZZCheatHighlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ESPFolder
    return highlight
end

local function createInfoGui(name, offset)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = name
    billboard.Size = UDim2.fromOffset(160, 48)
    billboard.StudsOffset = Vector3.new(0, offset, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = ESPFolder

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextSize = 10
    label.Font = Enum.Font.Code
    label.TextWrapped = true
    label.RichText = true
    label.Parent = billboard

    return billboard
end

local function removeESP(player)
    if HighlightCache[player] then
        HighlightCache[player]:Destroy()
        HighlightCache[player] = nil
    end
    if InfoCache[player] then
        InfoCache[player]:Destroy()
        InfoCache[player] = nil
    end
end

local function removeBotESP(model)
    if BotHighlightCache[model] then
        BotHighlightCache[model]:Destroy()
        BotHighlightCache[model] = nil
    end
    if BotInfoCache[model] then
        BotInfoCache[model]:Destroy()
        BotInfoCache[model] = nil
    end
end

local function clearBotESP()
    for model in pairs(BotHighlightCache) do
        removeBotESP(model)
    end
    for model in pairs(BotInfoCache) do
        removeBotESP(model)
    end
end

--==================================================
-- COLORS TAB
--==================================================

local function addColorPicker(name, color, flag, callback)
    local success, err = pcall(function()
        ColorTab:CreateColorPicker({
            Name = name,
            Color = color,
            Flag = flag,
            Callback = function(value)
                if typeof(value) == "Color3" then
                    callback(value)
                end
            end
        })
    end)
    if not success then
        warn("ZZZCheat Color Picker Error:", name, err)
    end
end

ColorTab:CreateSection("Player ESP")
addColorPicker("Player Name", ESPColors.PlayerName, "PlayerNameColor", function(color)
    ESPColors.PlayerName = color
end)
addColorPicker("Player Health", ESPColors.PlayerHealth, "PlayerHealthColor", function(color)
    ESPColors.PlayerHealth = color
end)
addColorPicker("Player Distance", ESPColors.PlayerDistance, "PlayerDistanceColor", function(color)
    ESPColors.PlayerDistance = color
end)
addColorPicker("Player Item", ESPColors.PlayerItem, "PlayerItemColor", function(color)
    ESPColors.PlayerItem = color
end)
addColorPicker("Player Outline", ESPColors.PlayerOutline, "PlayerOutlineColor", function(color)
    ESPColors.PlayerOutline = color
end)

ColorTab:CreateDivider()
ColorTab:CreateSection("Bot ESP")
addColorPicker("Bot Name", ESPColors.BotName, "BotNameColor", function(color)
    ESPColors.BotName = color
end)
addColorPicker("Bot Outline", ESPColors.BotOutline, "BotOutlineColor", function(color)
    ESPColors.BotOutline = color
end)

ColorTab:CreateDivider()
ColorTab:CreateSection("Chest ESP")
addColorPicker("Military Crate", ESPColors.ChestMilitary, "ChestMilitaryColor", function(color)
    ESPColors.ChestMilitary = color
end)
addColorPicker("Wood Crate", ESPColors.ChestWood, "ChestWoodColor", function(color)
    ESPColors.ChestWood = color
end)
addColorPicker("Elite Crate", ESPColors.ChestElite, "ChestEliteColor", function(color)
    ESPColors.ChestElite = color
end)

--==================================================
-- NPC SCANNER
--==================================================

local NPCList = {}
local NPCScanEnabled = false
local NPCConnection

local function isPlayerCharacter(model)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == model then
            return true
        end
    end
    return false
end

local BOT_MODEL_NAMES = {
    Guard = true,
    Soldier = true,
    Scavenger = true
}

local function getBotType(model)
    if not model or not model:IsA("Model") then
        return nil
    end
    if BOT_MODEL_NAMES[model.Name] then
        return model.Name
    end
    return nil
end

local function registerNPC(model)
    if not model or not model:IsA("Model") then
        return
    end
    if not getBotType(model) or isPlayerCharacter(model) then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        NPCList[model] = true
    end
end

local function startNPCScan()
    if NPCScanEnabled then
        return
    end
    NPCScanEnabled = true

    NPCConnection = Workspace.DescendantAdded:Connect(function(obj)
        if not NPCScanEnabled then
            return
        end
        if obj:IsA("Humanoid") then
            local model = obj.Parent
            if model and model:IsA("Model") then
                task.defer(registerNPC, model)
            end
        elseif obj:IsA("Model") then
            task.defer(registerNPC, obj)
        end
    end)

    task.spawn(function()
        local descendants = Workspace:GetDescendants()
        for i, obj in ipairs(descendants) do
            if not NPCScanEnabled then
                break
            end
            if obj:IsA("Humanoid") then
                local model = obj.Parent
                if model and model:IsA("Model") then
                    registerNPC(model)
                end
            end
            if i % 250 == 0 then
                task.wait()
            end
        end
        descendants = nil
    end)
end

local function stopNPCScan()
    if Settings.BotESP or (Settings.SmoothAim and Settings.AimTargets.NPC) then
        return
    end
    NPCScanEnabled = false
    if NPCConnection then
        NPCConnection:Disconnect()
        NPCConnection = nil
    end
end

local function updateNPCScanState()
    if Settings.BotESP or (Settings.SmoothAim and Settings.AimTargets.NPC) then
        startNPCScan()
    else
        stopNPCScan()
    end
end

--==================================================
-- PVP: SMOOTH AIM
--==================================================

local CachedTarget = nil
local RightMouseDown = false
local LastAimUpdate = 0
local AIM_UPDATE_INTERVAL = 0.05

-- Упреждение для движущихся Roblox-моделей.
-- Выключается отдельным переключателем Auto Prediction в PVP.
-- Если цель стоит на месте, leadOffset равен нулю и прицел остаётся на ней.
local AIM_PREDICTION_TIME = 0.13
local MAX_PREDICTION_OFFSET = 2.5

local RaycastParamsCache = RaycastParams.new()
RaycastParamsCache.FilterType = Enum.RaycastFilterType.Exclude
RaycastParamsCache.IgnoreWater = true

local function getAimPart(character)
    if not character then
        return nil
    end

    if Settings.AimPart == "Head" then
        return character:FindFirstChild("Head")
    elseif Settings.AimPart == "Torso" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    elseif Settings.AimPart == "Legs" then
        return character:FindFirstChild("LeftLowerLeg")
            or character:FindFirstChild("Left Leg")
            or character:FindFirstChild("RightLowerLeg")
            or character:FindFirstChild("Right Leg")
    end

    return character:FindFirstChild("Head")
end

local function isVisible(character, targetPosition)
    if not Settings.VisibilityCheck then
        return true
    end

    local origin = Camera.CFrame.Position
    RaycastParamsCache.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(origin, targetPosition - origin, RaycastParamsCache)

    return result == nil or result.Instance:IsDescendantOf(character)
end

-- Возвращает точку немного впереди движущейся модели.
-- Используется фактическая скорость root-part; MoveDirection служит запасным
-- вариантом, если физическая скорость на клиенте ещё не успела обновиться.
local function getPredictedAimPosition(character, targetPart)
    if not targetPart then
        return Vector3.zero
    end

    if not Settings.AutoPrediction then
        return targetPart.Position
    end

    if not character then
        return targetPart.Position
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
        or targetPart

    if not root then
        return targetPart.Position
    end

    local velocity = root.AssemblyLinearVelocity
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)

    if horizontalVelocity.Magnitude < 0.75 and humanoid then
        local moveDirection = humanoid.MoveDirection
        local horizontalDirection = Vector3.new(
            moveDirection.X,
            0,
            moveDirection.Z
        )

        if horizontalDirection.Magnitude > 0.05 then
            horizontalVelocity = horizontalDirection.Unit * humanoid.WalkSpeed
        end
    end

    local leadOffset = horizontalVelocity * AIM_PREDICTION_TIME

    if leadOffset.Magnitude > MAX_PREDICTION_OFFSET then
        leadOffset = leadOffset.Unit * MAX_PREDICTION_OFFSET
    end

    local predictedPosition = targetPart.Position + leadOffset

    -- Небольшая вертикальная поправка только во время прыжка/падения.
    if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
        predictedPosition += Vector3.new(
            0,
            math.clamp(velocity.Y * 0.08, -1.25, 1.25),
            0
        )
    end

    return predictedPosition
end

local function checkTarget(character, shortestDistance, center)
    if not character then
        return nil, shortestDistance
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return nil, shortestDistance
    end

    local targetPart = getAimPart(character)
    if not targetPart then
        return nil, shortestDistance
    end

    local localCharacter = LocalPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    local targetRoot = character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
        or targetPart

    if not localRoot or not targetRoot then
        return nil, shortestDistance
    end

    local worldDistance = (localRoot.Position - targetRoot.Position).Magnitude
    if worldDistance > Settings.AimDistance then
        return nil, shortestDistance
    end

    local predictedPosition = getPredictedAimPosition(character, targetPart)
    local screenPosition, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen or screenPosition.Z <= 0 then
        return nil, shortestDistance
    end

    local screenPoint = Vector2.new(screenPosition.X, screenPosition.Y)
    local screenDistance = (screenPoint - center).Magnitude

    if screenDistance < shortestDistance and isVisible(character, targetPart.Position) then
        return targetPart, screenDistance
    end

    return nil, shortestDistance
end

local function getClosestTarget()
    if not Camera then
        return nil
    end

    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local closestTarget = nil
    local shortestDistance = Settings.FOV

    if Settings.AimTargets.Player then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local target, distance = checkTarget(player.Character, shortestDistance, center)
                if target then
                    closestTarget = target
                    shortestDistance = distance
                end
            end
        end
    end

    if Settings.AimTargets.NPC then
        for model in pairs(NPCList) do
            if model and model.Parent and getBotType(model) and not isPlayerCharacter(model) then
                local target, distance = checkTarget(model, shortestDistance, center)
                if target then
                    closestTarget = target
                    shortestDistance = distance
                end
            else
                NPCList[model] = nil
            end
        end
    end

    return closestTarget
end

local FOVCircle
pcall(function()
    if Drawing then
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 1.5
        FOVCircle.NumSides = 60
        FOVCircle.Filled = false
        FOVCircle.Color = Color3.fromRGB(180, 100, 255)
        FOVCircle.Transparency = 1
    end
end)

PvpTab:CreateToggle({
    Name = "SilentAim",
    CurrentValue = Settings.SilentAim,
    Callback = function(value)
        Settings.SilentAim = value
    end
})

PvpTab:CreateSlider({
    Name = "SilentAim FOV",
    Range = {25, 500},
    Increment = 5,
    CurrentValue = Settings.SilentAimFOV,
    Callback = function(value)
        Settings.SilentAimFOV = value
    end
})

PvpTab:CreateSlider({
    Name = "SilentAim Distance",
    Range = {100, 5000},
    Increment = 100,
    CurrentValue = Settings.SilentAimMaxDistance,
    Callback = function(value)
        Settings.SilentAimMaxDistance = value
    end
})

PvpTab:CreateToggle({
    Name = "SilentAim Prediction",
    CurrentValue = Settings.SilentAimPrediction,
    Callback = function(value)
        Settings.SilentAimPrediction = value
    end
})

PvpTab:CreateSlider({
    Name = "SilentAim Prediction Strength",
    Range = {0, 2},
    Increment = 0.1,
    CurrentValue = Settings.SilentAimPredictionStrength,
    Callback = function(value)
        Settings.SilentAimPredictionStrength = value
    end
})

PvpTab:CreateToggle({
    Name = "SilentAim Visibility Check",
    CurrentValue = Settings.SilentAimVisibilityCheck,
    Callback = function(value)
        Settings.SilentAimVisibilityCheck = value
    end
})

PvpTab:CreateSlider({
    Name = "Default Projectile Speed",
    Range = {100, 3000},
    Increment = 50,
    CurrentValue = Settings.SilentAimProjectileSpeed,
    Callback = function(value)
        Settings.SilentAimProjectileSpeed = value
    end
})

PvpTab:CreateSlider({
    Name = "Default Projectile Gravity",
    Range = {0, 300},
    Increment = 5,
    CurrentValue = Settings.SilentAimGravity,
    Callback = function(value)
        Settings.SilentAimGravity = value
    end
})

local SmoothAimToggle = PvpTab:CreateToggle({
    Name = "SmoothAim",
    CurrentValue = Settings.SmoothAim,
    Callback = function(value)
        Settings.SmoothAim = value
        CachedTarget = nil
        updateNPCScanState()
    end
})

PvpTab:CreateToggle({
    Name = "Auto Prediction",
    CurrentValue = Settings.AutoPrediction,
    Callback = function(value)
        Settings.AutoPrediction = value
        CachedTarget = nil
    end
})

PvpTab:CreateDropdown({
    Name = "Aim Targets",
    Options = {"NPC", "Player"},
    CurrentOption = (function()
        local selected = {}
        if Settings.AimTargets.NPC then table.insert(selected, "NPC") end
        if Settings.AimTargets.Player then table.insert(selected, "Player") end
        if #selected == 0 then table.insert(selected, "Player") end
        return selected
    end)(),
    MultipleOptions = true,
    Callback = function(value)
        local selected = {}
        if typeof(value) == "table" then
            for _, targetName in ipairs(value) do
                selected[targetName] = true
            end
        elseif typeof(value) == "string" then
            selected[value] = true
        end
        Settings.AimTargets.Player = selected.Player == true
        Settings.AimTargets.NPC = selected.NPC == true
        CachedTarget = nil
        updateNPCScanState()
    end
})

PvpTab:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = Settings.VisibilityCheck,
    Callback = function(value)
        Settings.VisibilityCheck = value
    end
})

PvpTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Torso", "Legs"},
    CurrentOption = {Settings.AimPart},
    MultipleOptions = false,
    Callback = function(value)
        Settings.AimPart = typeof(value) == "table" and value[1] or value
    end
})

PvpTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = Settings.Smoothness,
    Callback = function(value)
        Settings.Smoothness = value
    end
})

PvpTab:CreateSlider({
    Name = "Aim Distance",
    Range = {100, 3000},
    Increment = 50,
    CurrentValue = Settings.AimDistance,
    Callback = function(value)
        Settings.AimDistance = value
        CachedTarget = nil
    end
})

PvpTab:CreateSlider({
    Name = "FOV",
    Range = {10, 500},
    Increment = 5,
    CurrentValue = Settings.FOV,
    Callback = function(value)
        Settings.FOV = value
    end
})

PvpTab:CreateToggle({
    Name = "Show FOV",
    CurrentValue = Settings.ShowFOV,
    Callback = function(value)
        Settings.ShowFOV = value
    end
})

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseDown = false
        CachedTarget = nil
    end
end)

--==================================================
-- VISUALS: PLAYER ESP (НЕ ИЗМЕНЯЛСЯ)
--==================================================

VisualsTab:CreateSection("Player ESP")

local PlayerESPToggle = VisualsTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = Settings.PlayerESP,
    Callback = function(value)
        Settings.PlayerESP = value
    end
})

VisualsTab:CreateToggle({
    Name = "Player Name",
    CurrentValue = Settings.PlayerName,
    Callback = function(value)
        Settings.PlayerName = value
    end
})

VisualsTab:CreateToggle({
    Name = "Player Health",
    CurrentValue = Settings.PlayerHealth,
    Callback = function(value)
        Settings.PlayerHealth = value
    end
})

VisualsTab:CreateToggle({
    Name = "Player Distance",
    CurrentValue = Settings.PlayerDistance,
    Callback = function(value)
        Settings.PlayerDistance = value
    end
})

VisualsTab:CreateToggle({
    Name = "Player Item",
    CurrentValue = Settings.PlayerItem,
    Callback = function(value)
        Settings.PlayerItem = value
    end
})

VisualsTab:CreateSlider({
    Name = "Player Text Size",
    Range = {10, 24},
    Increment = 1,
    CurrentValue = Settings.PlayerTextSize,
    Callback = function(value)
        Settings.PlayerTextSize = value
    end
})

--==================================================
-- VISUALS: BOT ESP
--==================================================

VisualsTab:CreateDivider()
VisualsTab:CreateSection("ESP Bot (Guard, Soldier, Scavenger)")

local BotESPToggle = VisualsTab:CreateToggle({
    Name = "ESP Bot",
    CurrentValue = Settings.BotESP,
    Callback = function(value)
        Settings.BotESP = value
        if value then
            startNPCScan()
        else
            clearBotESP()
        end
        updateNPCScanState()
    end
})

VisualsTab:CreateToggle({
    Name = "Bot Name",
    CurrentValue = Settings.BotName,
    Callback = function(value)
        Settings.BotName = value
    end
})

VisualsTab:CreateSlider({
    Name = "Bot Text Size",
    Range = {10, 24},
    Increment = 1,
    CurrentValue = Settings.BotTextSize,
    Callback = function(value)
        Settings.BotTextSize = value
    end
})

--==================================================
-- TIME CHANGER (ВМЕСТО FULLBRIGHT)
--==================================================

local OriginalClockTime = Lighting.ClockTime
local lastTimeUpdate = 0

local function setTimeChanger(value)
    Settings.TimeChanger = value
    if value then
        Lighting.ClockTime = Settings.TimeChangerHour
    else
        Lighting.ClockTime = OriginalClockTime
    end
end

VisualsTab:CreateDivider()
VisualsTab:CreateSection("Lighting")

local TimeChangerToggle = VisualsTab:CreateToggle({
    Name = "Time Changer",
    CurrentValue = Settings.TimeChanger,
    Callback = setTimeChanger
})

VisualsTab:CreateSlider({
    Name = "Time (Hour)",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = Settings.TimeChangerHour,
    Callback = function(value)
        Settings.TimeChangerHour = value
        if Settings.TimeChanger then
            Lighting.ClockTime = value
        end
    end
})

--==================================================
-- FREECAM (ТОЛЬКО КАМЕРА, ПЕРСОНАЖ НЕ ЗАМОРАЖИВАЕТСЯ)
--==================================================

local FreeCamEnabled = false
local FreeCamPosition
local FreeCamYaw = 0
local FreeCamPitch = 0
local FreeCamOldType
local FreeCamOldSubject
local FreeCamOldMouseBehavior
local FreeCamOldMouseIcon

local function setFreeCam(value)
    if value == FreeCamEnabled then
        return
    end

    Camera = Workspace.CurrentCamera
    if not Camera then
        return
    end

    FreeCamEnabled = value
    Settings.FreeCam = value

    if value then
        FreeCamPosition = Camera.CFrame.Position
        local look = Camera.CFrame.LookVector
        FreeCamYaw = math.atan2(-look.X, -look.Z)
        FreeCamPitch = math.asin(math.clamp(look.Y, -1, 1))

        FreeCamOldType = Camera.CameraType
        FreeCamOldSubject = Camera.CameraSubject
        FreeCamOldMouseBehavior = UserInputService.MouseBehavior
        FreeCamOldMouseIcon = UserInputService.MouseIconEnabled

        Camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        Camera.CameraType = FreeCamOldType or Enum.CameraType.Custom

        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if FreeCamOldSubject and FreeCamOldSubject.Parent then
            Camera.CameraSubject = FreeCamOldSubject
        elseif humanoid then
            Camera.CameraSubject = humanoid
        end

        UserInputService.MouseBehavior = FreeCamOldMouseBehavior or Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = FreeCamOldMouseIcon ~= nil and FreeCamOldMouseIcon or true
        FreeCamPosition = nil
    end
end

RunService:BindToRenderStep(
    "ZZZCheatFreeCam",
    Enum.RenderPriority.Camera.Value + 1,
    function(deltaTime)
        if not FreeCamEnabled then
            return
        end

        Camera = Workspace.CurrentCamera
        if not Camera then
            return
        end

        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        local mouseDelta = UserInputService:GetMouseDelta()
        FreeCamYaw -= mouseDelta.X * 0.003
        FreeCamPitch = math.clamp(
            FreeCamPitch - mouseDelta.Y * 0.003,
            math.rad(-85),
            math.rad(85)
        )

        local rotation = CFrame.Angles(0, FreeCamYaw, 0)
            * CFrame.Angles(FreeCamPitch, 0, 0)
        local movement = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then movement += Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then movement += Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then movement += Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then movement += Vector3.new(1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then movement += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then movement += Vector3.new(0, -1, 0) end

        local speed = Settings.FreeCamSpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            speed *= 2
        end
        if movement.Magnitude > 0 then
            FreeCamPosition += rotation:VectorToWorldSpace(movement.Unit) * speed * deltaTime
        end

        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = CFrame.new(FreeCamPosition) * rotation
    end
)

PveTab:CreateDivider()
PveTab:CreateSection("FreeCam")
local FreeCamToggle = PveTab:CreateToggle({
    Name = "FreeCam",
    CurrentValue = Settings.FreeCam,
    Callback = setFreeCam
})
PveTab:CreateSlider({
    Name = "FreeCam Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = Settings.FreeCamSpeed,
    Callback = function(value)
        Settings.FreeCamSpeed = value
    end
})

local FreeCamWaitingForKey = false
PveTab:CreateButton({
    Name = "Set Key Freecam (" .. tostring(Settings.FreeCamKey) .. ")",
    Callback = function()
        FreeCamWaitingForKey = true
        notify("FreeCam", "Нажми любую клавишу для бинда...")
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode == Enum.KeyCode.Unknown then
        return
    end

    if FreeCamWaitingForKey then
        if gameProcessed then return end
        Settings.FreeCamKey = input.KeyCode.Name
        FreeCamWaitingForKey = false
        notify("FreeCam", "Бинд установлен: " .. Settings.FreeCamKey)
        return
    end

    if gameProcessed or UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode.Name == Settings.FreeCamKey then
        setFreeCam(not FreeCamEnabled)
    end
end)
PveTab:CreateButton({
    Name = "Reset Camera",
    Callback = function()
        if FreeCamEnabled then
            setFreeCam(false)
        end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and Camera then
            Camera.CameraSubject = humanoid
            Camera.CameraType = Enum.CameraType.Custom
        end
    end
})

--==================================================
-- ORE ESP
--==================================================

local OreSettings = {
    Enabled = false,
    Sulfur = true,
    Metal = true,
    Stone = true,
    ShowName = true,
    MaxDistance = 300
}

preloadExtraSettings("OreSettings", OreSettings)

local OreCache = {}
local OreDefinitions = {
    {
        key = "Sulfur",
        names = {SulfurOrePile = true, SulfurNode = true},
        label = "Сера",
        color = Color3.fromRGB(255, 220, 0)
    },
    {
        key = "Metal",
        names = {MetalOrePile = true, MetalNode = true},
        label = "Металл",
        color = Color3.fromRGB(194, 145, 95)
    },
    {
        key = "Stone",
        names = {StoneNode = true},
        label = "Камень",
        color = Color3.fromRGB(155, 155, 155)
    }
}

local function getOreDefinition(object)
    if not object then
        return nil
    end
    for _, definition in ipairs(OreDefinitions) do
        if definition.names[object.Name] then
            return definition
        end
    end
    return nil
end

local function isOreTypeEnabled(definition)
    return definition ~= nil and OreSettings.Enabled and OreSettings[definition.key] == true
end

local function getOreAdornee(object)
    if object:IsA("Model") then
        return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
    end
    if object:IsA("BasePart") then
        return object
    end
    return nil
end

local function getOreObject(object)
    if not object then
        return nil
    end
    local current = object
    while current and current ~= Workspace do
        if (current:IsA("Model") or current:IsA("BasePart")) and getOreDefinition(current) then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function removeOreESP(object)
    local entry = OreCache[object]
    if not entry then
        return
    end
    if entry.Highlight then entry.Highlight:Destroy() end
    if entry.Billboard then entry.Billboard:Destroy() end
    OreCache[object] = nil
end

local function registerOre(object)
    if not OreSettings.Enabled then
        return
    end
    object = getOreObject(object)
    if not object or OreCache[object] then
        return
    end
    local definition = getOreDefinition(object)
    if not isOreTypeEnabled(definition) then
        return
    end
    local adornee = getOreAdornee(object)
    if not adornee then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "OreHighlight"
    highlight.Adornee = object
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = definition.color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ESPFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OreInfo"
    billboard.Size = UDim2.fromOffset(150, 28)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = adornee
    billboard.Parent = ESPFolder

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = definition.label
    label.TextColor3 = definition.color
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = Enum.Font.Code
    label.Parent = billboard

    OreCache[object] = {Highlight = highlight, Billboard = billboard, Definition = definition}
end

local function clearOreESP()
    for object in pairs(OreCache) do
        removeOreESP(object)
    end
end

local OreScanId = 0
local function scanOres()
    if not OreSettings.Enabled then
        return
    end
    OreScanId += 1
    local scanId = OreScanId
    task.spawn(function()
        local descendants = Workspace:GetDescendants()
        for i, object in ipairs(descendants) do
            if scanId ~= OreScanId or not OreSettings.Enabled then
                break
            end
            registerOre(object)
            if i % 250 == 0 then
                task.wait()
            end
        end
        descendants = nil
    end)
end

local function refreshOreESP()
    clearOreESP()
    if OreSettings.Enabled then
        scanOres()
    else
        OreScanId += 1
    end
end

Workspace.DescendantAdded:Connect(function(object)
    if OreSettings.Enabled then
        task.defer(registerOre, object)
    end
end)

Workspace.DescendantRemoving:Connect(function(object)
    if OreCache[object] then
        removeOreESP(object)
    end
end)

local lastOreUpdate = 0
RunService.Heartbeat:Connect(function()
    if not OreSettings.Enabled then
        return
    end
    local now = os.clock()
    if now - lastOreUpdate < 0.25 then
        return
    end
    lastOreUpdate = now

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    for object, entry in pairs(OreCache) do
        if not object.Parent then
            removeOreESP(object)
            continue
        end
        local adornee = getOreAdornee(object)
        if not adornee then
            removeOreESP(object)
            continue
        end
        local distance = (root.Position - adornee.Position).Magnitude
        local visible = distance <= OreSettings.MaxDistance
        if entry.Highlight then
            entry.Highlight.Enabled = visible
        end
        if entry.Billboard then
            entry.Billboard.Enabled = visible and OreSettings.ShowName
        end
    end
end)

--==================================================
-- STORAGE ESP (Workbench2, Workbench3, Locker, LargeBox, ToolCupboard)
--==================================================

local StorageSettings = {
    Enabled = false,
    Workbench2 = true,
    Workbench3 = true,
    Locker = true,
    LargeBox = true,
    ToolCupboard = true,
    Turret = true,
    AutoTurret = true,
    ShowName = true,
    MaxDistance = 1000
}

preloadExtraSettings("StorageSettings", StorageSettings)

local StorageNames = {
    Workbench2 = "Верстак 2",
    Workbench3 = "Верстак 3",
    Locker = "Локер",
    LargeBox = "Большой ящик",
    ToolCupboard = "Шкаф",
    Turret = "Турель",
    AutoTurret = "Турель"
}

local StorageCache = {}
local function getStorageObject(object)
    local current = object
    while current and current ~= Workspace do
        if (current:IsA("Model") or current:IsA("BasePart")) and StorageNames[current.Name] then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function getStorageAdornee(object)
    if object:IsA("BasePart") then
        return object
    end
    if object:IsA("Model") then
        return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function removeStorageESP(object)
    local data = StorageCache[object]
    if not data then
        return
    end
    if data.Highlight then data.Highlight:Destroy() end
    if data.Billboard then data.Billboard:Destroy() end
    StorageCache[object] = nil
end

local function registerStorage(object)
    if not StorageSettings.Enabled then
        return
    end
    object = getStorageObject(object)
    if not object or StorageCache[object] or not StorageSettings[object.Name] then
        return
    end
    local part = getStorageAdornee(object)
    if not part then
        return
    end

    local color = Color3.fromRGB(105, 175, 255)
    local highlight = Instance.new("Highlight")
    highlight.Name = "StorageHighlight"
    highlight.Adornee = object
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ESPFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "StorageInfo"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(170, 28)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = ESPFolder

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = StorageNames[object.Name]
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = Enum.Font.Code
    label.Parent = billboard

    StorageCache[object] = {Highlight = highlight, Billboard = billboard, Part = part}
end

local function clearStorageESP()
    for object in pairs(StorageCache) do
        removeStorageESP(object)
    end
end

local StorageScanId = 0
local function refreshStorageESP()
    clearStorageESP()
    StorageScanId += 1
    if not StorageSettings.Enabled then
        return
    end
    local thisScan = StorageScanId
    task.spawn(function()
        local descendants = Workspace:GetDescendants()
        for i, object in ipairs(descendants) do
            if thisScan ~= StorageScanId or not StorageSettings.Enabled then
                break
            end
            registerStorage(object)
            if i % 250 == 0 then
                task.wait()
            end
        end
        descendants = nil
    end)
end

Workspace.DescendantAdded:Connect(function(object)
    if StorageSettings.Enabled then
        task.defer(registerStorage, object)
    end
end)

Workspace.DescendantRemoving:Connect(function(object)
    if StorageCache[object] then
        removeStorageESP(object)
    end
end)

local lastStorageUpdate = 0
RunService.Heartbeat:Connect(function()
    if not StorageSettings.Enabled then
        return
    end
    local now = os.clock()
    if now - lastStorageUpdate < 0.25 then
        return
    end
    lastStorageUpdate = now

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    for object, data in pairs(StorageCache) do
        if not object.Parent or not data.Part or not data.Part.Parent then
            removeStorageESP(object)
        else
            local distance = (root.Position - data.Part.Position).Magnitude
            local visible = distance <= StorageSettings.MaxDistance
            if data.Highlight then
                data.Highlight.Enabled = visible
            end
            if data.Billboard then
                data.Billboard.Enabled = visible and StorageSettings.ShowName
            end
        end
    end
end)

--==================================================
-- CHEST ESP (БЛОК ОСТАВЛЕН КАК В ПРИСЛАННОМ КОДЕ)
--==================================================

local ChestSettings = {
    Enabled = false,
    LootCrate = true,
    MilitaryCrate = true,
    EliteCrate = true,
    ShowName = true,
    MaxDistance = 1000,
    TextSize = 14
}

preloadExtraSettings("ChestSettings", ChestSettings)

local ChestCache = {}
local ChestScanId = 0

local ChestDefinitions = {
    LootCrate = {
        Label = "Деревянный ящик",
        ColorKey = "ChestWood"
    },
    MilitaryCrate = {
        Label = "Военный ящик",
        ColorKey = "ChestMilitary"
    },
    EliteCrate = {
        Label = "Элитный ящик",
        ColorKey = "ChestElite"
    }
}

local function getLootFolder()
    return Workspace:FindFirstChild("Loot")
end

local function getChestObject(object)
    local lootFolder = getLootFolder()
    if not lootFolder or not object then
        return nil
    end
    local current = object
    while current and current ~= lootFolder do
        if ChestDefinitions[current.Name]
            and (current:IsA("Model") or current:IsA("BasePart")) then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function getChestPart(object)
    if object:IsA("BasePart") then
        return object
    end
    if object:IsA("Model") then
        return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function removeChestESP(object)
    local data = ChestCache[object]
    if not data then
        return
    end
    if data.Highlight then
        data.Highlight:Destroy()
    end
    if data.Billboard then
        data.Billboard:Destroy()
    end
    ChestCache[object] = nil
end

local function clearChestESP()
    for object in pairs(ChestCache) do
        removeChestESP(object)
    end
end

local function registerChest(object)
    if not ChestSettings.Enabled then
        return
    end
    if not object or not object.Parent then
        return
    end
    object = getChestObject(object)
    if not object or ChestCache[object] then
        return
    end
    local definition = ChestDefinitions[object.Name]
    if not definition or not ChestSettings[object.Name] then
        return
    end
    local part = getChestPart(object)
    if not part then
        return
    end

    local chestColor = ESPColors[definition.ColorKey]
    local highlight = Instance.new("Highlight")
    highlight.Name = "ChestHighlight"
    highlight.Adornee = object
    highlight.FillColor = chestColor
    highlight.OutlineColor = chestColor
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ESPFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ChestName"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 180, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = ChestSettings.ShowName
    billboard.Parent = ESPFolder

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = definition.Label
    label.TextColor3 = chestColor
    label.TextStrokeTransparency = 1
    label.TextScaled = false
    label.TextSize = ChestSettings.TextSize
    label.Font = Enum.Font.Gotham
    label.Parent = billboard

    ChestCache[object] = {
        Highlight = highlight,
        Billboard = billboard,
        Part = part,
        ColorKey = definition.ColorKey
    }
end

local function refreshChestESP()
    ChestScanId += 1
    local currentScanId = ChestScanId
    clearChestESP()
    if not ChestSettings.Enabled then
        return
    end
    task.spawn(function()
        local lootFolder = getLootFolder()
        if not lootFolder then
            return
        end
        local descendants = lootFolder:GetDescendants()
        for i, object in ipairs(descendants) do
            if currentScanId ~= ChestScanId or not ChestSettings.Enabled then
                break
            end
            if ChestDefinitions[object.Name]
                and (object:IsA("Model") or object:IsA("BasePart")) then
                registerChest(object)
            end
            if i % 150 == 0 then
                task.wait()
            end
        end
        descendants = nil
    end)
end

Workspace.DescendantAdded:Connect(function(object)
    if not ChestSettings.Enabled then
        return
    end
    if object.Name == "Loot" then
        task.defer(refreshChestESP)
        return
    end
    task.defer(function()
        if ChestSettings.Enabled then
            registerChest(object)
        end
    end)
end)

Workspace.DescendantRemoving:Connect(function(object)
    if ChestCache[object] then
        removeChestESP(object)
    end
end)

local lastChestUpdate = 0
RunService.Heartbeat:Connect(function()
    if not ChestSettings.Enabled then
        return
    end
    local now = os.clock()
    if now - lastChestUpdate < 0.15 then
        return
    end
    lastChestUpdate = now
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end
    for object, data in pairs(ChestCache) do
        if not object.Parent or not data.Part or not data.Part.Parent then
            removeChestESP(object)
        else
            local distance = (root.Position - data.Part.Position).Magnitude
            local visible = distance <= ChestSettings.MaxDistance
            local chestColor = ESPColors[data.ColorKey]
            if data.Highlight then
                data.Highlight.Enabled = visible
                data.Highlight.FillColor = chestColor
                data.Highlight.OutlineColor = chestColor
            end
            if data.Billboard then
                data.Billboard.Enabled = visible and ChestSettings.ShowName
                local label = data.Billboard:FindFirstChild("Info")
                if label then
                    label.TextColor3 = chestColor
                    label.TextSize = ChestSettings.TextSize
                end
            end
        end
    end
end)

--==================================================
-- VISUALS: ORE / STORAGE / CHEST ESP
--==================================================

VisualsTab:CreateSection("Ore ESP")
local OreESPToggle = VisualsTab:CreateToggle({
    Name = "Ore ESP",
    CurrentValue = OreSettings.Enabled,
    Callback = function(value)
        OreSettings.Enabled = value
        Settings.OreESP = value
        refreshOreESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Sulfur",
    CurrentValue = OreSettings.Sulfur,
    Callback = function(value)
        OreSettings.Sulfur = value
        refreshOreESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Metal",
    CurrentValue = OreSettings.Metal,
    Callback = function(value)
        OreSettings.Metal = value
        refreshOreESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Stone",
    CurrentValue = OreSettings.Stone,
    Callback = function(value)
        OreSettings.Stone = value
        refreshOreESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Ore Name",
    CurrentValue = OreSettings.ShowName,
    Callback = function(value)
        OreSettings.ShowName = value
    end
})
VisualsTab:CreateSlider({
    Name = "Ore Distance",
    Range = {25, 1000},
    Increment = 25,
    CurrentValue = OreSettings.MaxDistance,
    Callback = function(value)
        OreSettings.MaxDistance = value
    end
})

--==================================================
-- STORAGE ESP UI
--==================================================

VisualsTab:CreateDivider()
VisualsTab:CreateSection("Storage ESP")
local StorageESPToggle = VisualsTab:CreateToggle({
    Name = "Storage ESP",
    CurrentValue = StorageSettings.Enabled,
    Callback = function(value)
        StorageSettings.Enabled = value
        Settings.StorageESP = value
        refreshStorageESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Workbench 2",
    CurrentValue = StorageSettings.Workbench2,
    Callback = function(value)
        StorageSettings.Workbench2 = value
        refreshStorageESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Workbench 3",
    CurrentValue = StorageSettings.Workbench3,
    Callback = function(value)
        StorageSettings.Workbench3 = value
        refreshStorageESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Локер",
    CurrentValue = StorageSettings.Locker,
    Callback = function(value)
        StorageSettings.Locker = value
        refreshStorageESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Large Box",
    CurrentValue = StorageSettings.LargeBox,
    Callback = function(value)
        StorageSettings.LargeBox = value
        refreshStorageESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Шкаф",
    CurrentValue = StorageSettings.ToolCupboard,
    Callback = function(value)
        StorageSettings.ToolCupboard = value
        refreshStorageESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Турель",
    CurrentValue = StorageSettings.Turret,
    Callback = function(value)
        StorageSettings.Turret = value
        StorageSettings.AutoTurret = value
        refreshStorageESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Storage Name",
    CurrentValue = StorageSettings.ShowName,
    Callback = function(value)
        StorageSettings.ShowName = value
    end
})
VisualsTab:CreateSlider({
    Name = "Storage Distance",
    Range = {50, 2000},
    Increment = 50,
    CurrentValue = StorageSettings.MaxDistance,
    Callback = function(value)
        StorageSettings.MaxDistance = value
    end
})

--==================================================
-- CHEST ESP UI (БЕЗ ИЗМЕНЕНИЙ)
--==================================================

VisualsTab:CreateDivider()
VisualsTab:CreateSection("Chest ESP")
local ChestESPToggle = VisualsTab:CreateToggle({
    Name = "Chest ESP",
    CurrentValue = ChestSettings.Enabled,
    Callback = function(value)
        ChestSettings.Enabled = value
        Settings.ChestESP = value
        refreshChestESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Деревянный ящик",
    CurrentValue = ChestSettings.LootCrate,
    Callback = function(value)
        ChestSettings.LootCrate = value
        refreshChestESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Военный ящик",
    CurrentValue = ChestSettings.MilitaryCrate,
    Callback = function(value)
        ChestSettings.MilitaryCrate = value
        refreshChestESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Элитный ящик",
    CurrentValue = ChestSettings.EliteCrate,
    Callback = function(value)
        ChestSettings.EliteCrate = value
        refreshChestESP()
    end
})
VisualsTab:CreateToggle({
    Name = "Chest Name",
    CurrentValue = ChestSettings.ShowName,
    Callback = function(value)
        ChestSettings.ShowName = value
        for _, data in pairs(ChestCache) do
            if data.Billboard then
                data.Billboard.Enabled = value
            end
        end
    end
})
VisualsTab:CreateSlider({
    Name = "Chest Text Size",
    Range = {10, 24},
    Increment = 1,
    CurrentValue = ChestSettings.TextSize,
    Callback = function(value)
        ChestSettings.TextSize = value
        for _, data in pairs(ChestCache) do
            if data.Billboard then
                local label = data.Billboard:FindFirstChild("Info")
                if label then
                    label.TextSize = value
                end
            end
        end
    end
})
VisualsTab:CreateSlider({
    Name = "Chest Distance",
    Range = {50, 2000},
    Increment = 50,
    CurrentValue = ChestSettings.MaxDistance,
    Callback = function(value)
        ChestSettings.MaxDistance = value
    end
})

--==================================================
-- ANTI-AFK (ПО УМОЛЧАНИЮ ВЫКЛЮЧЕН)
--==================================================

PveTab:CreateDivider()
PveTab:CreateSection("Anti-AFK")
local AntiAFKToggle = PveTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = Settings.AntiAFK,
    Callback = function(value)
        Settings.AntiAFK = value
    end
})

LocalPlayer.Idled:Connect(function()
    if not Settings.AntiAFK then
        return
    end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

--==================================================
-- PLAYER ESP UPDATE (НЕ ИЗМЕНЯЛСЯ)
--==================================================

local function updatePlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and (
            character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("Head")
        )

        if not Settings.PlayerESP then
            if HighlightCache[player] then
                HighlightCache[player].Enabled = false
            end
            if InfoCache[player] then
                InfoCache[player].Enabled = false
            end
            continue
        end

        if not character or not humanoid or humanoid.Health <= 0 or not root then
            if HighlightCache[player] then
                HighlightCache[player].Adornee = nil
            end
            if InfoCache[player] then
                InfoCache[player].Adornee = nil
                InfoCache[player].Enabled = false
            end
            continue
        end

        local highlight = HighlightCache[player]
        if not highlight then
            highlight = createHighlight(ESPColors.PlayerOutline)
            HighlightCache[player] = highlight
        end
        highlight.Adornee = character
        highlight.OutlineColor = ESPColors.PlayerOutline
        highlight.Enabled = true

        local billboard = InfoCache[player]
        if not billboard then
            billboard = createInfoGui("PlayerInfo", -3)
            InfoCache[player] = billboard
        end
        billboard.Adornee = root

        local lines = {}
        if Settings.PlayerName then
            table.insert(lines, richText(player.Name, ESPColors.PlayerName))
        end
        if Settings.PlayerHealth then
            table.insert(lines, richText(
                string.format("HP: %d / %d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)),
                ESPColors.PlayerHealth
            ))
        end
        if Settings.PlayerDistance then
            local localCharacter = LocalPlayer.Character
            local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            if localRoot then
                local distance = (localRoot.Position - root.Position).Magnitude
                table.insert(lines, richText(string.format("DIST: %d m", math.floor(distance)), ESPColors.PlayerDistance))
            end
        end
        if Settings.PlayerItem then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                table.insert(lines, richText(tool.Name, ESPColors.PlayerItem))
            end
        end

        local label = billboard:FindFirstChild("Info")
        if label then
            label.RichText = true
            label.Text = table.concat(lines, "\n")
            label.TextSize = Settings.PlayerTextSize
        end
        billboard.Enabled = #lines > 0
    end
end

--==================================================
-- BOT ESP UPDATE
--==================================================

local function updateBotESP()
    if not Settings.BotESP then
        clearBotESP()
        return
    end

    for model in pairs(NPCList) do
        if not model or not model.Parent then
            removeBotESP(model)
            NPCList[model] = nil
            continue
        end

        local botType = getBotType(model)
        if not botType then
            removeBotESP(model)
            NPCList[model] = nil
            continue
        end

        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
        if not humanoid or humanoid.Health <= 0 or not root then
            removeBotESP(model)
            continue
        end

        local highlight = BotHighlightCache[model]
        if not highlight then
            highlight = createHighlight(ESPColors.BotOutline)
            BotHighlightCache[model] = highlight
        end
        highlight.Adornee = model
        highlight.OutlineColor = ESPColors.BotOutline
        highlight.Enabled = true

        local billboard = BotInfoCache[model]
        if not billboard then
            billboard = createInfoGui("BotInfo", 2.5)
            BotInfoCache[model] = billboard
        end
        local head = model:FindFirstChild("Head")
        billboard.Adornee = head or root

        local label = billboard:FindFirstChild("Info")
        if label then
            label.RichText = true
            -- Все NPC имеют одинаковую подпись Bot, независимо от имени модели.
            label.Text = Settings.BotName and richText("Bot", ESPColors.BotName) or ""
            label.TextSize = Settings.BotTextSize
        end
        billboard.Enabled = Settings.BotName
    end
end

--==================================================
-- CONFIG SYSTEM: CREATE / SAVE / LOAD / DELETE
--==================================================

local CONFIG_FOLDER = "ZZZCheat/Configs"
local configName = "Default"

local function notify(title, content)
    pcall(function()
        Rayfield:Notify({Title = title, Content = content, Duration = 3})
    end)
end

local function ensureConfigFolder()
    if not (isfolder and makefolder) then
        return false
    end
    pcall(function()
        if not isfolder("ZZZCheat") then
            makefolder("ZZZCheat")
        end
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
    end)
    return isfolder(CONFIG_FOLDER)
end

local function cleanConfigName(value)
    local name = tostring(value or "Default")
    name = name:gsub("%.json$", ""):gsub("[^%w%-%_ ]", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return "Default"
    end
    return name:sub(1, 40)
end

local function colorToTable(color)
    return {
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    }
end

local function tableToColor(value, fallback)
    if typeof(value) == "table" and #value >= 3 then
        return Color3.fromRGB(
            math.clamp(tonumber(value[1]) or 255, 0, 255),
            math.clamp(tonumber(value[2]) or 255, 0, 255),
            math.clamp(tonumber(value[3]) or 255, 0, 255)
        )
    end
    return fallback
end

local function makeConfigData()
    local colors = {}
    for key, value in pairs(ESPColors) do
        colors[key] = colorToTable(value)
    end


    return {
        Settings = Settings,
        ESPColors = colors,
        OreSettings = OreSettings,
        StorageSettings = StorageSettings,
        ChestSettings = ChestSettings
    }
end

local function configPath(name)
    return CONFIG_FOLDER .. "/" .. cleanConfigName(name) .. ".json"
end

local function saveConfig(silent)
    if not (writefile and HttpService) or not ensureConfigFolder() then
        notify("ZZZCheat", "Файловые функции executor недоступны")
        return
    end
    local ok, result = pcall(function()
        return HttpService:JSONEncode(makeConfigData())
    end)
    if not ok then
        notify("ZZZCheat", "Не удалось собрать конфиг: " .. tostring(result))
        return
    end
    local saved, err = pcall(writefile, configPath(configName), result)
    if saved then
        if not silent then notify("ZZZCheat", "Конфиг сохранён: " .. cleanConfigName(configName)) end
    else
        if not silent then notify("ZZZCheat", "Ошибка сохранения: " .. tostring(err)) end
    end
end

local function applyConfigData(data)
    if typeof(data) ~= "table" then
        return false
    end

    if typeof(data.Settings) == "table" then
        for key, value in pairs(data.Settings) do
            if Settings[key] ~= nil and typeof(value) == typeof(Settings[key]) then
                Settings[key] = value
            end
        end
    end

    if typeof(data.ESPColors) == "table" then
        for key, value in pairs(data.ESPColors) do
            if ESPColors[key] then
                ESPColors[key] = tableToColor(value, ESPColors[key])
            end
        end
    end

    local function copyBooleanSettings(source, target)
        if typeof(source) ~= "table" then
            return
        end
        for key, value in pairs(source) do
            if target[key] ~= nil and typeof(value) == typeof(target[key]) then
                target[key] = value
            end
        end
    end
    copyBooleanSettings(data.OreSettings, OreSettings)
    copyBooleanSettings(data.StorageSettings, StorageSettings)
    copyBooleanSettings(data.ChestSettings, ChestSettings)


    -- Применяем загруженные настройки к работающим функциям.
    Settings.OreESP = OreSettings.Enabled
    Settings.ChestESP = ChestSettings.Enabled
    Settings.StorageESP = StorageSettings.Enabled
    if FreeCamEnabled then
        setFreeCam(false)
    end
    Settings.FreeCam = false
    if Settings.TimeChanger then
        Lighting.ClockTime = Settings.TimeChangerHour
    else
        Lighting.ClockTime = OriginalClockTime
    end
    refreshOreESP()
    refreshChestESP()
    refreshStorageESP()
    updateNPCScanState()
    return true
end

local function loadConfig(silent)
    if not (readfile and isfile and HttpService) then
        if not silent then notify("ZZZCheat", "Файловые функции executor недоступны") end
        return
    end
    local path = configPath(configName)
    if not isfile(path) then
        if not silent then notify("ZZZCheat", "Конфиг не найден: " .. cleanConfigName(configName)) end
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok then
        if not silent then notify("ZZZCheat", "Не удалось прочитать конфиг") end
        return
    end
    if applyConfigData(data) then
        if not silent then notify("ZZZCheat", "Конфиг загружен: " .. cleanConfigName(configName)) end
    else
        if not silent then notify("ZZZCheat", "Неверный формат конфига") end
    end
end

-- Загружаем единый конфиг при запуске; затем сохраняем изменения автоматически.
loadConfig(true)
local lastConfigSnapshot = ""
local function autoSaveConfig()
    if not (writefile and HttpService and ensureConfigFolder()) then return end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(makeConfigData())
    end)
    if not ok or encoded == lastConfigSnapshot then return end

    -- Save as soon as a setting changes; no long debounce window between injections.
    if pcall(writefile, configPath(configName), encoded) then
        lastConfigSnapshot = encoded
    end
end

-- Автоконфиг: один файл, без ручного управления.
VisualsTab:CreateSection("Made By: @wzeqq")

--==================================================
-- SILENT AIM
-- Targeting is restricted to live player characters and their Head part.
-- Weapon stats are read from Tool attributes/ValueObjects when available;
-- configurable defaults are used for weapons without exposed stats.
--==================================================

local SilentAimVelocities = {}
local SilentAimLastPositions = {}
local SilentAimLastVelocityUpdate = os.clock()
local SilentAimRaycastParams = RaycastParams.new()
SilentAimRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
SilentAimRaycastParams.IgnoreWater = true

local function getSilentAimPlayers()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local head = character and character:FindFirstChild("Head")
            if character and character.Parent and humanoid and humanoid.Health > 0
                and head and head:IsA("BasePart") then
                table.insert(targets, {
                    Player = player,
                    Character = character,
                    Humanoid = humanoid,
                    Part = head
                })
            end
        end
    end
    return targets
end

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    local dt = now - SilentAimLastVelocityUpdate
    if dt < 0.05 then return end
    SilentAimLastVelocityUpdate = now

    local activeParts = {}
    for _, target in ipairs(getSilentAimPlayers()) do
        local part = target.Part
        activeParts[part] = true
        local previous = SilentAimLastPositions[part]
        if previous and dt > 0 then
            SilentAimVelocities[part] = (part.Position - previous) / dt
        end
        SilentAimLastPositions[part] = part.Position
    end

    for part in pairs(SilentAimLastPositions) do
        if not activeParts[part] then
            SilentAimLastPositions[part] = nil
            SilentAimVelocities[part] = nil
        end
    end
end)

local function isSilentAimTargetVisible(character, targetPosition)
    if not Settings.SilentAimVisibilityCheck then
        return true
    end
    if not Camera then return false end

    SilentAimRaycastParams.FilterDescendantsInstances = {
        LocalPlayer.Character
    }

    local origin = Camera.CFrame.Position
    local direction = targetPosition - origin
    local ok, result = pcall(function()
        return Workspace:Raycast(origin, direction, SilentAimRaycastParams)
    end)
    if not ok then return false end
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function getSilentAimTarget()
    if not Camera then return nil end

    local viewport = Camera.ViewportSize
    local mousePosition
    if UserInputService.TouchEnabled or not UserInputService.MouseEnabled
        or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        mousePosition = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    else
        local inset = Vector2.zero
        pcall(function()
            local GuiService = game:GetService("GuiService")
            local topLeftInset = GuiService:GetGuiInset()
            inset = Vector2.new(topLeftInset.X, topLeftInset.Y)
        end)
        mousePosition = UserInputService:GetMouseLocation() - inset
    end

    local bestPart, bestDistance = nil, math.max(0, tonumber(Settings.SilentAimFOV) or 180)
    local cameraPosition = Camera.CFrame.Position
    local maxDistance = tonumber(Settings.SilentAimMaxDistance) or 3000

    for _, target in ipairs(getSilentAimPlayers()) do
        local part = target.Part
        local worldDistance = (part.Position - cameraPosition).Magnitude
        if worldDistance <= maxDistance then
            local screenPosition, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen and screenPosition.Z > 0 then
                local screenDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
                if screenDistance <= bestDistance
                    and isSilentAimTargetVisible(target.Character, part.Position) then
                    bestPart = part
                    bestDistance = screenDistance
                end
            end
        end
    end

    return bestPart
end

local function readToolNumber(tool, names)
    if not tool then return nil end

    for _, name in ipairs(names) do
        local ok, value = pcall(function()
            return tool:GetAttribute(name)
        end)
        if ok and typeof(value) == "number" then
            return value
        end
    end

    for _, name in ipairs(names) do
        local valueObject = tool:FindFirstChild(name, true)
        if valueObject and (valueObject:IsA("NumberValue") or valueObject:IsA("IntValue")) then
            return valueObject.Value
        end
    end

    return nil
end

local function getSilentAimWeaponStats()
    local character = LocalPlayer.Character
    local tool = character and character:FindFirstChildWhichIsA("Tool")

    local speed = readToolNumber(tool, {
        "ProjectileSpeed", "BulletSpeed", "MuzzleVelocity", "ProjectileVelocity"
    })
    local gravity = readToolNumber(tool, {
        "ProjectileGravity", "BulletGravity", "Gravity"
    })

    speed = tonumber(speed) or tonumber(Settings.SilentAimProjectileSpeed) or 550
    gravity = tonumber(gravity) or tonumber(Settings.SilentAimGravity) or 100

    return math.max(1, speed), math.max(0, gravity)
end

local function getSilentAimDirection(origin, target)
    if not target or not target.Parent then return nil end

    local aimPosition = target.Position
    if Settings.SilentAimPrediction then
        local speed, gravity = getSilentAimWeaponStats()
        local velocity = target.AssemblyLinearVelocity
        if not velocity or velocity.Magnitude < 0.05 then
            velocity = SilentAimVelocities[target] or Vector3.zero
        end

        local strength = math.clamp(tonumber(Settings.SilentAimPredictionStrength) or 1, 0, 2)
        local flightTime = (aimPosition - origin).Magnitude / speed

        -- Two refinement passes make the lead estimate more stable for moving targets.
        for _ = 1, 2 do
            local lead = velocity * flightTime * strength
            local dropCompensation = Vector3.new(0, 0.5 * gravity * flightTime * flightTime, 0)
            aimPosition = target.Position + lead + dropCompensation
            flightTime = (aimPosition - origin).Magnitude / speed
        end
    end

    local delta = aimPosition - origin
    if delta.Magnitude <= 0 then return nil end
    return delta.Unit
end

local silentAimOldNamecall
local silentAimHookInstalled = false

local function installSilentAimHook()
    if silentAimHookInstalled then return end
    if type(getnamecallmethod) ~= "function" then
        warn("ZZZCheat: executor does not support getnamecallmethod")
        return
    end

    local wrap = newcclosure or function(fn) return fn end
    local callerCheck = checkcaller or function() return false end
    local callback = wrap(function(self, ...)
        local method = getnamecallmethod()
        if not callerCheck() and Settings.SilentAim and type(method) == "string"
            and method:lower() == "fireserver" and self.Name == "Shoot" then
            local args = {...}
            local originalPayload = args[1]
            local payload = typeof(originalPayload) == "table" and table.clone(originalPayload) or nil
            local target = getSilentAimTarget()

            if payload and target then
                local origin = typeof(payload.origin) == "Vector3"
                    and payload.origin
                    or (Camera and Camera.CFrame.Position)
                if origin then
                    local direction = getSilentAimDirection(origin, target)
                    if direction then
                        payload.dir = direction
                        return silentAimOldNamecall(self, payload)
                    end
                end
            end
        end
        return silentAimOldNamecall(self, ...)
    end)

    if type(hookmetamethod) == "function" then
        silentAimOldNamecall = hookmetamethod(game, "__namecall", callback)
    elseif type(getrawmetatable) == "function" and type(setreadonly) == "function" then
        local mt = getrawmetatable(game)
        if not mt then return end
        silentAimOldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = callback
        setreadonly(mt, true)
    else
        warn("ZZZCheat: executor does not support __namecall interception")
        return
    end

    silentAimHookInstalled = true
end

installSilentAimHook()

--==================================================
-- CLEANUP
--==================================================

Players.PlayerRemoving:Connect(removeESP)

Workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("Model") and NPCList[obj] then
        removeBotESP(obj)
        NPCList[obj] = nil
    end
end)

--==================================================
-- MAIN LOOP
--==================================================

local ESP_UPDATE_INTERVAL = 0.35
local lastESPUpdate = 0

RunService.RenderStepped:Connect(function()
    autoSaveConfig()

    if not Camera then
        return
    end

    -- TIME CHANGER
    if Settings.TimeChanger then
        local now = os.clock()
        if now - lastTimeUpdate >= 0.5 then
            lastTimeUpdate = now
            Lighting.ClockTime = Settings.TimeChangerHour
        end
    end

    -- FOV CIRCLE
    if FOVCircle then
        local viewport = Camera.ViewportSize
        FOVCircle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Visible = Settings.ShowFOV and Settings.SmoothAim
    end

    -- SMOOTH AIM: активируется удержанием правой кнопки мыши.
    if Settings.SmoothAim and RightMouseDown and not FreeCamEnabled then
        local aimNow = os.clock()
        if aimNow - LastAimUpdate >= AIM_UPDATE_INTERVAL then
            LastAimUpdate = aimNow
            CachedTarget = getClosestTarget()
        end

        local target = CachedTarget
        if target and target.Parent then
            local smoothness = math.clamp(Settings.Smoothness, 1, 10)
            local alpha = 1 / smoothness
            local targetCharacter = target:FindFirstAncestorOfClass("Model")
            local aimPosition = getPredictedAimPosition(targetCharacter, target)
            local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, aimPosition)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
        else
            CachedTarget = nil
        end
    else
        CachedTarget = nil
    end

    -- ESP UPDATE
    local now = os.clock()
    if now - lastESPUpdate >= ESP_UPDATE_INTERVAL then
        lastESPUpdate = now
        updatePlayerESP()
        updateBotESP()
    end
end)

--==================================================
-- MOBILE UI
--==================================================

local toggleGui
if UserInputService.TouchEnabled then
    toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "ZZZCheatMobileToggle"
    toggleGui.ResetOnSpawn = false
    toggleGui.Parent = GuiParent

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleUI"
    toggleBtn.Size = UDim2.fromOffset(45, 45)
    toggleBtn.Position = UDim2.new(0.02, 0, 0.25, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Text = "UI"
    toggleBtn.TextSize = 16
    toggleBtn.Font = Enum.Font.Code
    toggleBtn.Parent = toggleGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toggleBtn
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 90, 220)
    stroke.Thickness = 1.5
    stroke.Parent = toggleBtn

    toggleBtn.Activated:Connect(function()
        pcall(function()
            Window:ToggleHide()
        end)
    end)
end

--==================================================
-- INJECTION NOTIFICATION
--==================================================

local function showInjectionNotification()
    if InjectionNotificationGui then
        InjectionNotificationGui:Destroy()
    end

    local notificationGui = Instance.new("ScreenGui")
    InjectionNotificationGui = notificationGui
    notificationGui.Name = "ZZZCheatNotification"
    notificationGui.ResetOnSpawn = false
    notificationGui.IgnoreGuiInset = true
    notificationGui.DisplayOrder = 999999
    notificationGui.Parent = GuiParent

    local frame = Instance.new("Frame")
    frame.Name = "Notification"
    frame.Size = UDim2.fromOffset(250, 65)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.Position = UDim2.new(1, 270, 1, -25)
    frame.BackgroundColor3 = Color3.fromRGB(28, 22, 38)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = notificationGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(155, 90, 220)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.1
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(12, 7)
    title.Size = UDim2.new(1, -24, 0, 22)
    title.Font = Enum.Font.GothamBold
    title.Text = "ZZZCheat"
    title.TextColor3 = Color3.fromRGB(200, 150, 255)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.BackgroundTransparency = 1
    message.Position = UDim2.fromOffset(12, 31)
    message.Size = UDim2.new(1, -24, 0, 22)
    message.Font = Enum.Font.Gotham
    message.Text = "ZZZCheat запущен"
    message.TextColor3 = Color3.fromRGB(235, 235, 235)
    message.TextSize = 13
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.Parent = frame

    local appearTween = TweenService:Create(
        frame,
        TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -20, 1, -25)}
    )
    appearTween:Play()

    task.delay(4, function()
        if not frame.Parent then
            return
        end
        local hideTween = TweenService:Create(
            frame,
            TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 270, 1, -25), BackgroundTransparency = 1}
        )
        hideTween:Play()
        hideTween.Completed:Wait()
        if notificationGui then
            notificationGui:Destroy()
        end
        if InjectionNotificationGui == notificationGui then
            InjectionNotificationGui = nil
        end
    end)
end

showInjectionNotification()

print("================================")
print("ZZZCheat successfully injected")
print("Author: tg: @wzeqq")
print("================================")
