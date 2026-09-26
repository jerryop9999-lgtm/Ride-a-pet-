--[[
    OLIVER - Fresh Mobile Build
    UI and controls rebuilt from scratch.

    Requested behavior:
      • OLIVER floating open/close button
      • Main UI is draggable
      • Auto Steal starts OFF
      • HoldDuration = 0.0s
      • Fast direct flight/teleport to Egg
      • Confirm pickup before returning
      • Return to player's Base
      • Fixed 23-Egg pickup priority
      • Separate "Egg in Map" panel, OFF by default
      • One-finger mobile touch
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[OLIVER] LocalPlayer is not available; script stopped safely.")
    return
end

local RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

-- =========================================================
-- MOBILE INPUT
-- =========================================================

local function setupTouchButton(button)
    if not button then return end
    button.Active = true
    button.Selectable = true
    button.AutoButtonColor = true
end

local function connectTap(button, callback)
    if not button then return end
    setupTouchButton(button)

    local activeTouch = nil
    local activeMouse = false

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            activeTouch = input
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeMouse = true
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if activeTouch == input then
                activeTouch = nil
                callback()
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            if activeMouse then
                activeMouse = false
                callback()
            end
        end
    end)
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    handle.Active = true

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
            end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then return end

        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

-- =========================================================
-- GUI ROOT
-- =========================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OLIVER_Fresh"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- FLOATING OLIVER BUTTON
-- =========================================================

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "OLIVER"
ToggleBtn.Size = UDim2.new(0, 88, 0, 38)
ToggleBtn.Position = UDim2.new(0, 14, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
ToggleBtn.Text = "OLIVER"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 15
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = ScreenGui
setupTouchButton(ToggleBtn)

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = ToggleBtn

-- =========================================================
-- MAIN PANEL
-- =========================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 238, 0, 330)
MainFrame.Position = UDim2.new(0.5, -119, 0.5, -142)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 13)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1.2
mainStroke.Color = Color3.fromRGB(55, 155, 255)
mainStroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 13)
headerCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -20, 0, 25)
Title.Position = UDim2.new(0, 11, 0, 5)
Title.Text = "OLIVER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Status = Instance.new("TextLabel")
Status.BackgroundTransparency = 1
Status.Size = UDim2.new(0, 75, 0, 18)
Status.Position = UDim2.new(1, -85, 0, 21)
Status.Text = "OFF"
Status.TextColor3 = Color3.fromRGB(150, 155, 165)
Status.Font = Enum.Font.SourceSansBold
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Right
Status.Parent = Header

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.BackgroundTransparency = 1
Content.Size = UDim2.new(1, -16, 1, -53)
Content.Position = UDim2.new(0, 8, 0, 49)
Content.Parent = MainFrame

local function makeMainButton(name, textValue, y, height)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, 0, 0, height)
    b.Position = UDim2.new(0, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
    b.Text = textValue
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 15
    b.BorderSizePixel = 0
    b.Parent = Content
    setupTouchButton(b)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9)
    c.Parent = b
    return b
end

local AutoStealBtn = makeMainButton("AutoSteal", "Auto Steal | OFF", 4, 48)

local HoldLabel = Instance.new("TextLabel")
HoldLabel.Name = "Hold"
HoldLabel.Size = UDim2.new(1, 0, 0, 23)
HoldLabel.Position = UDim2.new(0, 0, 0, 57)
HoldLabel.BackgroundTransparency = 1
HoldLabel.Text = "Hold 0.0s"
HoldLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
HoldLabel.Font = Enum.Font.SourceSans
HoldLabel.TextSize = 14
HoldLabel.TextXAlignment = Enum.TextXAlignment.Left
HoldLabel.Parent = Content


local ESPEggBtn = makeMainButton("ESPEgg", "ESP EGG | OFF", 94, 34)

local MapPanelBtn = makeMainButton("MapPanel", "Egg in Map | OFF", 133, 43)

local SpeedBtn = makeMainButton("Speed", "SPEED | OFF", 181, 43)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, 0, 0, 42)
Info.Position = UDim2.new(0, 0, 0, 229)
Info.BackgroundTransparency = 1
Info.Text = "Fast flight → Egg → confirm → Base"
Info.TextColor3 = Color3.fromRGB(145, 150, 160)
Info.Font = Enum.Font.SourceSans
Info.TextSize = 12
Info.TextWrapped = true
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.Parent = Content

makeDraggable(MainFrame, Header)

do
    local dragging = false
    local moved = false
    local startPos, startBtnPos
    local activeInput

    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        activeInput = input
        dragging = true
        moved = false
        startPos = input.Position
        startBtnPos = ToggleBtn.Position
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= activeInput then return end
        local delta = input.Position - startPos
        if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then moved = true end
        if moved then
            ToggleBtn.Position = UDim2.new(
                startBtnPos.X.Scale, startBtnPos.X.Offset + delta.X,
                startBtnPos.Y.Scale, startBtnPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input ~= activeInput then return end
        dragging = false
        activeInput = nil
        if not moved then MainFrame.Visible = not MainFrame.Visible end
    end)
end

-- =========================================================
-- SEPARATE EGG-IN-MAP PANEL
-- =========================================================

local MapFrame = Instance.new("Frame")
MapFrame.Name = "EggInMapPanel"
MapFrame.Size = UDim2.new(0, 210, 0, 275)
MapFrame.Position = UDim2.new(0.5, 125, 0.5, -137)
MapFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
MapFrame.BorderSizePixel = 0
MapFrame.Visible = false
MapFrame.Parent = ScreenGui

local mapCorner = Instance.new("UICorner")
mapCorner.CornerRadius = UDim.new(0, 13)
mapCorner.Parent = MapFrame

local mapStroke = Instance.new("UIStroke")
mapStroke.Thickness = 1.1
mapStroke.Color = Color3.fromRGB(75, 120, 255)
mapStroke.Parent = MapFrame

local MapHeader = Instance.new("Frame")
MapHeader.Size = UDim2.new(1, 0, 0, 43)
MapHeader.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
MapHeader.BorderSizePixel = 0
MapHeader.Parent = MapFrame

local mapHeaderCorner = Instance.new("UICorner")
mapHeaderCorner.CornerRadius = UDim.new(0, 13)
mapHeaderCorner.Parent = MapHeader

local MapTitle = Instance.new("TextLabel")
MapTitle.BackgroundTransparency = 1
MapTitle.Size = UDim2.new(1, -16, 1, 0)
MapTitle.Position = UDim2.new(0, 9, 0, 0)
MapTitle.Text = "Egg in Map"
MapTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MapTitle.Font = Enum.Font.SourceSansBold
MapTitle.TextSize = 17
MapTitle.TextXAlignment = Enum.TextXAlignment.Left
MapTitle.Parent = MapHeader

local MapScroll = Instance.new("ScrollingFrame")
MapScroll.Name = "List"
MapScroll.Size = UDim2.new(1, -12, 1, -50)
MapScroll.Position = UDim2.new(0, 6, 0, 47)
MapScroll.BackgroundTransparency = 1
MapScroll.BorderSizePixel = 0
MapScroll.ScrollBarThickness = 4
MapScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MapScroll.Parent = MapFrame

local mapLayout = Instance.new("UIListLayout")
mapLayout.SortOrder = Enum.SortOrder.LayoutOrder
mapLayout.Padding = UDim.new(0, 2)
mapLayout.Parent = MapScroll

makeDraggable(MapFrame, MapHeader)

-- =========================================================
-- STATE
-- =========================================================

local autoSteal = false
local stealBusy = false
local autoStealStartCFrame = nil
local capturedReturnBaseCFrame = nil
local holdTime = 0.0
local espEggEnabled = false
local espEggFolder = nil
local espEggConnection = nil

-- SPEED
-- Mobile-friendly toggle. Default is OFF; ON forces WalkSpeed 600.
local speedEnabled = false
local SPEED_VALUE = 600
local speedConnection = nil
local speedCharacterConnection = nil
local speedOriginalWalkSpeed = nil
local speedOriginalCharacter = nil

local function applySpeed()
    if not speedEnabled then return end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = SPEED_VALUE
        end)
    end
end

local function stopSpeed()
    speedEnabled = false

    -- Restore the normal WalkSpeed that was active before SPEED was enabled.
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and speedOriginalWalkSpeed ~= nil then
        pcall(function()
            humanoid.WalkSpeed = speedOriginalWalkSpeed
        end)
    end

    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end

    if speedCharacterConnection then
        speedCharacterConnection:Disconnect()
        speedCharacterConnection = nil
    end

    SpeedBtn.Text = "SPEED | OFF"
    SpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
    speedOriginalWalkSpeed = nil
    speedOriginalCharacter = nil
end

local function startSpeed()
    -- Capture the current normal speed before forcing 600.
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        speedOriginalWalkSpeed = humanoid.WalkSpeed
        speedOriginalCharacter = character
    else
        speedOriginalWalkSpeed = nil
        speedOriginalCharacter = nil
    end

    speedEnabled = true

    SpeedBtn.Text = "SPEED | 600"
    SpeedBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 80)

    applySpeed()

    speedConnection = RunService.Heartbeat:Connect(function()
        applySpeed()
    end)

    speedCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        task.defer(function()
            local humanoid = character:WaitForChild("Humanoid", 8)
            if speedEnabled and humanoid then
                -- A respawn can have a different normal WalkSpeed, so capture it
                -- before applying the forced speed to this new character.
                speedOriginalWalkSpeed = humanoid.WalkSpeed
                speedOriginalCharacter = character
                pcall(function()
                    humanoid.WalkSpeed = SPEED_VALUE
                end)
            end
        end)
    end)
end

connectTap(SpeedBtn, function()
    if speedEnabled then
        stopSpeed()
    else
        startSpeed()
    end
end)

local movementLock = {
    controls = nil,
    walkSpeed = nil,
    jumpPower = nil,
    jumpHeight = nil,
    autoRotate = nil,
}

-- Exactly 24 Eggs, in the order Auto Steal checks them.
-- Updated named ladder with Volcanic Egg (2.5T Luck).
-- The current community table documents these 23 named eggs.
-- The separate 90K and 500K luck rows are intentionally NOT invented/named.
local EggPriority = {
    "White Egg",       -- 1 Luck
    "Brown Egg",       -- 5 Luck
    "Cracked Egg",     -- 30 Luck
    "Easter Egg",      -- 50 Luck
    "Stone Egg",       -- 100 Luck
    "Leaf Egg",        -- 200 Luck
    "Mushroom Egg",    -- 500 Luck
    "Flower Egg",      -- 750 Luck
    "Slime Egg",       -- 1,000 Luck
    "Ice Egg",         -- 3,000 Luck
    "Glass Egg",       -- 10,000 Luck
    "Golden Egg",      -- 30,000 Luck
    "Crystal Egg",     -- 150,000 Luck
    "Skull Egg",       -- 250,000 Luck
    "Dominus Egg",     -- 700,000 Luck
    "Flaming Egg",     -- 1,000,000 Luck
    "Sinister Egg",    -- 3,000,000 Luck
    "Soul Egg",        -- 7,000,000 Luck
    "Aurora Egg",      -- 300,000,000 Luck
    "Galaxy Egg",      -- 1,500,000,000 Luck
    "Black Hole Egg",  -- 100,000,000,000 Luck
    "Solaris Egg",     -- 300,000,000,000 Luck
    "Cherub Egg",      -- 1,000,000,000,000 Luck
    "Volcanic Egg",    -- 2,500,000,000,000 Luck
}

local EggRarity = {
    ["White Egg"] = "Common",
    ["Brown Egg"] = "Common",
    ["Cracked Egg"] = "Rare",
    ["Easter Egg"] = "Rare",
    ["Stone Egg"] = "Rare",
    ["Leaf Egg"] = "Rare",
    ["Mushroom Egg"] = "Epic",
    ["Flower Egg"] = "Epic",
    ["Slime Egg"] = "Epic",
    ["Ice Egg"] = "Epic",
    ["Glass Egg"] = "Legendary",
    ["Golden Egg"] = "Legendary",
    ["Crystal Egg"] = "Mythic",
    ["Skull Egg"] = "Mythic",
    ["Dominus Egg"] = "Mythic",
    ["Flaming Egg"] = "Mythic",
    ["Sinister Egg"] = "Mythic",
    ["Soul Egg"] = "Mythic",
    ["Aurora Egg"] = "Divine",
    ["Galaxy Egg"] = "Divine",
    ["Black Hole Egg"] = "Ethereal",
    ["Solaris Egg"] = "Ethereal",
    ["Cherub Egg"] = "Ethereal",
}

connectTap(MapPanelBtn, function()
    MapFrame.Visible = not MapFrame.Visible
    MapPanelBtn.Text = MapFrame.Visible and "Egg in Map | ON" or "Egg in Map | OFF"
    MapPanelBtn.BackgroundColor3 = MapFrame.Visible
        and Color3.fromRGB(0, 120, 80)
        or Color3.fromRGB(40, 43, 55)
end)

-- =========================================================
-- EGG ESP
-- Mobile optimized:
--   • one ESP label per actual Egg container
--   • no black background
--   • only Khmer distance text: "ចម្ងាយ: XX m"
--   • ignores internal names such as EggBase
--   • scans less often to reduce mobile lag
-- =========================================================

local function getESPPart(obj)
    if not obj then return nil end

    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        local handle = obj:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            return handle
        end

        if obj.PrimaryPart and obj.PrimaryPart:IsA("BasePart") then
            return obj.PrimaryPart
        end

        return obj:FindFirstChildWhichIsA("BasePart", true)
    end

    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local ESPKnownEggNames = {}
for _, eggName in ipairs(EggPriority) do
    ESPKnownEggNames[eggName:lower()] = true
end

local function looksLikeEggName(name)
    if not name then return false end

    local lower = tostring(name):lower()
    if ESPKnownEggNames[lower] then
        return true
    end

    if not lower:find("egg", 1, true) then
        return false
    end

    if lower:find("spawn", 1, true)
        or lower:find("point", 1, true)
        or lower:find("spot", 1, true)
        or lower:find("folder", 1, true)
        or lower:find("holder", 1, true)
        or lower:find("zone", 1, true)
        or lower:find("container", 1, true) then
        return false
    end

    return true
end

-- Resolve every visible part to ONE top-level Egg object.
-- This prevents 2-3 labels being created for the same EggBase/model.
local function getESPEggCandidate(obj, renderedRoot)
    if not obj or not obj.Parent or not renderedRoot then
        return nil
    end

    local current = obj
    local best = nil

    while current and current ~= renderedRoot do
        if current:IsA("Model") and looksLikeEggName(current.Name) then
            best = current
        end
        current = current.Parent
    end

    if best then
        return best
    end

    -- If the direct child is an internal EggBase/container, use it as the
    -- identity object, but only one ESP is created for that container.
    local top = obj
    while top.Parent and top.Parent ~= renderedRoot do
        top = top.Parent
    end

    if top ~= renderedRoot then
        local topName = tostring(top.Name or ""):lower()
        if topName == "eggbase" or topName:find("eggbase", 1, true) then
            return top
        end
    end

    if (obj:IsA("Model") or obj:IsA("BasePart")) and looksLikeEggName(obj.Name) then
        return obj
    end

    return nil
end

local function getESPDisplayName(egg)
    if not egg then return "Egg" end

    -- Prefer the real Egg name, never show internal names such as EggBase.
    if looksLikeEggName(egg.Name) and tostring(egg.Name):lower() ~= "eggbase" then
        return tostring(egg.Name)
    end

    -- If the visible container is EggBase, find the real Egg name inside it.
    local bestName = nil
    for _, obj in ipairs(egg:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and looksLikeEggName(obj.Name) then
            local n = tostring(obj.Name)
            if n:lower() ~= "eggbase" then
                if ESPKnownEggNames[n:lower()] then
                    return n
                end
                bestName = bestName or n
            end
        end
    end

    return bestName or "Egg"
end

local function createEggESP(egg)
    local part = getESPPart(egg)
    if not part then return nil end

    local gui = Instance.new("BillboardGui")
    gui.Name = "OLIVER_EggESP"
    gui.Size = UDim2.new(0, 180, 0, 42)
    gui.StudsOffset = Vector3.new(0, 3.0, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 5000
    gui.ResetOnSpawn = false
    gui.Adornee = part
    gui.Parent = espEggFolder

    -- Text only: no Frame/background. Name + one distance line.
    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = getESPDisplayName(egg) .. "\nចម្ងាយ: -- m"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.15
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = gui

    return {
        gui = gui,
        egg = egg,
        part = part,
        label = label,
        displayName = getESPDisplayName(egg),
    }
end

local function destroyEggESP()
    if espEggConnection then
        espEggConnection:Disconnect()
        espEggConnection = nil
    end

    if espEggFolder then
        espEggFolder:Destroy()
        espEggFolder = nil
    end
end

local function stopEggESP()
    espEggEnabled = false
    destroyEggESP()

    ESPEggBtn.Text = "ESP EGG | OFF"
    ESPEggBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
end

local function startEggESP()
    destroyEggESP()
    espEggEnabled = true

    espEggFolder = Instance.new("Folder")
    espEggFolder.Name = "OLIVER_EggESP"
    espEggFolder.Parent = Workspace

    ESPEggBtn.Text = "ESP EGG | ON"
    ESPEggBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 80)

    local entries = {}
    local lastScan = 0
    local lastDistanceUpdate = 0

    local function scanEggs(renderedRoot)
        if not espEggEnabled or not renderedRoot or not renderedRoot.Parent then
            return
        end

        local alive = {}

        -- One scan per 0.60s is much lighter on mobile than scanning every frame.
        for _, obj in ipairs(renderedRoot:GetDescendants()) do
            local egg = getESPEggCandidate(obj, renderedRoot)

            if egg and egg.Parent and not alive[egg] then
                local part = getESPPart(egg)
                if part then
                    alive[egg] = true

                    if not entries[egg] then
                        local entry = createEggESP(egg)
                        if entry then
                            entries[egg] = entry
                        end
                    end
                end
            end
        end

        -- Also catch an Egg that is itself a direct child.
        for _, obj in ipairs(renderedRoot:GetChildren()) do
            local egg = getESPEggCandidate(obj, renderedRoot)
            if egg and egg.Parent and not alive[egg] then
                local part = getESPPart(egg)
                if part then
                    alive[egg] = true
                    if not entries[egg] then
                        local entry = createEggESP(egg)
                        if entry then
                            entries[egg] = entry
                        end
                    end
                end
            end
        end

        for egg, entry in pairs(entries) do
            if not alive[egg]
                or not egg.Parent
                or not egg:IsDescendantOf(renderedRoot) then

                if entry.gui then
                    entry.gui:Destroy()
                end
                entries[egg] = nil
            end
        end
    end

    espEggConnection = RunService.Heartbeat:Connect(function()
        if not espEggEnabled or not ScreenGui.Parent then
            return
        end

        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

        RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
        if not RenderedEggs then
            return
        end

        local now = os.clock()

        if now - lastScan >= 0.60 then
            lastScan = now
            scanEggs(RenderedEggs)
        end

        -- Distance text only needs a few updates per second.
        if now - lastDistanceUpdate < 0.20 then
            return
        end
        lastDistanceUpdate = now

        for egg, entry in pairs(entries) do
            if entry.gui and entry.gui.Parent and egg.Parent then
                local part = getESPPart(egg)

                if part then
                    entry.part = part
                    entry.gui.Adornee = part

                    local distance = (part.Position - root.Position).Magnitude
                    entry.label.Text = string.format("%s\nចម្ងាយ: %d m", entry.displayName or "Egg", math.floor(distance + 0.5))
                else
                    entry.gui:Destroy()
                    entries[egg] = nil
                end
            else
                entries[egg] = nil
            end
        end
    end)
end

connectTap(ESPEggBtn, function()
    if espEggEnabled then
        stopEggESP()
    else
        startEggESP()
    end
end)

-- =========================================================
-- GAME MECHANICS
-- =========================================================

local function setMovementLocked(locked)
    local player = LocalPlayer
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if locked then
        -- Disable Roblox's default PlayerModule controls when available.
        if not movementLock.controls then
            pcall(function()
                local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
                local module = require(playerModule)
                movementLock.controls = module:GetControls()
            end)
        end
        if movementLock.controls then
            pcall(function() movementLock.controls:Disable() end)
        end

        if humanoid then
            movementLock.walkSpeed = humanoid.WalkSpeed
            movementLock.jumpPower = humanoid.JumpPower
            movementLock.jumpHeight = humanoid.JumpHeight
            movementLock.autoRotate = humanoid.AutoRotate

            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.JumpHeight = 0
            humanoid.AutoRotate = false
            humanoid:Move(Vector3.zero, true)
        end
    else
        if humanoid then
            if movementLock.walkSpeed ~= nil then humanoid.WalkSpeed = movementLock.walkSpeed end
            if movementLock.jumpPower ~= nil then humanoid.JumpPower = movementLock.jumpPower end
            if movementLock.jumpHeight ~= nil then humanoid.JumpHeight = movementLock.jumpHeight end
            if movementLock.autoRotate ~= nil then humanoid.AutoRotate = movementLock.autoRotate end
        end

        if movementLock.controls then
            pcall(function() movementLock.controls:Enable() end)
        end

        movementLock.walkSpeed = nil
        movementLock.jumpPower = nil
        movementLock.jumpHeight = nil
        movementLock.autoRotate = nil
    end
end

local function valueMatchesPlayer(value)
    if value == LocalPlayer then return true end
    if typeof(value) == "string" then
        return value == LocalPlayer.Name or value == LocalPlayer.DisplayName
    end
    if typeof(value) == "number" then
        return value == LocalPlayer.UserId
    end
    return false
end

local function candidateOwnerMatch(obj)
    local score = 0

    -- Ownership may be stored on Plot/Ranch while the return part is a child.
    local containers = {obj}
    local p = obj.Parent
    for _ = 1, 6 do
        if not p then break end
        table.insert(containers, p)
        p = p.Parent
    end

    for _, container in ipairs(containers) do
        for _, attrName in ipairs({
            "Owner", "owner", "OwnerName", "ownerName",
            "Player", "PlayerName", "UserId", "OwnerUserId"
        }) do
            local ok, value = pcall(function() return container:GetAttribute(attrName) end)
            if ok and value ~= nil and valueMatchesPlayer(value) then
                score += 25
            end
        end

        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ObjectValue") then
                if child.Value == LocalPlayer then score += 25 end
            elseif child:IsA("StringValue") then
                if valueMatchesPlayer(child.Value) then score += 25 end
            elseif child:IsA("IntValue") or child:IsA("NumberValue") then
                if valueMatchesPlayer(child.Value) then score += 25 end
            end
        end

        local n = container.Name:lower()
        if n == LocalPlayer.Name:lower() then score += 20 end
        if n == LocalPlayer.DisplayName:lower() then score += 16 end
    end

    return score
end

local function baseNameScore(obj)
    local n = obj.Name:lower()
    local score = 0
    if n:find("ranch", 1, true) then score += 6 end
    if n:find("plot", 1, true) then score += 6 end
    if n:find("base", 1, true) then score += 5 end
    if n:find("home", 1, true) then score += 3 end
    return score
end

local function findReturnPart(container)
    if not container then return nil end

    local preferred = {
        "SpawnLocation", "Spawn", "Home", "HomeSpawn",
        "Return", "ReturnPoint", "Teleport", "Entrance",
        "Claim", "ClaimPoint", "Center", "PrimaryPart"
    }

    for _, wanted in ipairs(preferred) do
        local x = container:FindFirstChild(wanted, true)
        if x and x:IsA("BasePart") then
            return x
        end
    end

    if container:IsA("BasePart") then return container end
    if container:IsA("Model") and container.PrimaryPart then
        return container.PrimaryPart
    end

    return container:FindFirstChildWhichIsA("BasePart", true)
end

local cachedBasePart = nil
local cachedBaseScore = 0
local lastBaseScan = 0

local function findPlayerBase()
    if cachedBasePart and cachedBasePart.Parent and (os.clock() - lastBaseScan) < 2 then
        return cachedBasePart
    end

    lastBaseScan = os.clock()
    cachedBasePart = nil
    cachedBaseScore = 0

    local keywords = {"base", "bases", "ranch", "ranches", "plot", "plots", "home"}
    local function hasKeyword(name)
        name = name:lower()
        for _, key in ipairs(keywords) do
            if name:find(key, 1, true) then return true end
        end
        return false
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local nearestPart, nearestDistance = nil, math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if hasKeyword(obj.Name) then
            local part = findReturnPart(obj)
            if part then
                local distance = root and (part.Position - root.Position).Magnitude or math.huge
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPart = part
                end

                local ownerScore = candidateOwnerMatch(obj)
                if ownerScore > 0 then
                    local score = ownerScore + baseNameScore(obj)
                    if score > cachedBaseScore then
                        cachedBaseScore = score
                        cachedBasePart = part
                    end
                end
            end
        end
    end

    -- No owner marker: use the Base/Plot nearest to the player's position at startup,
    -- instead of arbitrarily selecting another player's plot.
    if not cachedBasePart then
        cachedBasePart = nearestPart
        cachedBaseScore = nearestPart and 1 or 0
    end

    if cachedBasePart then
        print("[OLIVER] OWN BASE RETURN:", cachedBasePart:GetFullName(), "score=", cachedBaseScore)
    else
        warn("[OLIVER] Player-owned Base/Ranch was not found")
    end

    return cachedBasePart
end

local function getRanchCFrame()
    local part = findPlayerBase()
    if part then
        return part.CFrame
    end
    return nil
end

local function getEggPart(egg)
    if not egg then return nil end
    local handle = egg:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then return handle end
    if egg:IsA("BasePart") then return egg end
    return egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
end

local function getStealPrompt(egg)
    if not egg then return nil end

    -- Fast path: prioritize the actual in-game action shown on the Egg
    -- ("Pick Up"), then fall back to any ProximityPrompt.
    for _, x in ipairs(egg:GetChildren()) do
        if x:IsA("ProximityPrompt") then
            local action = tostring(x.ActionText or ""):lower()
            local object = tostring(x.ObjectText or ""):lower()
            local name = x.Name:lower()
            if action:find("pick up", 1, true) or action:find("pickup", 1, true)
                or object:find("egg", 1, true) or name:find("steal", 1, true) then
                return x
            end
        end
    end

    for _, x in ipairs(egg:GetChildren()) do
        if x:IsA("ProximityPrompt") then
            return x
        end
    end

    -- Only recurse inside the already-selected Egg model.
    for _, x in ipairs(egg:GetDescendants()) do
        if x:IsA("ProximityPrompt") and x.Name:lower():find("steal") then
            return x
        end
    end

    for _, x in ipairs(egg:GetDescendants()) do
        if x:IsA("ProximityPrompt") then
            return x
        end
    end

    return nil
end

local function teleportCharacter(cf, heightOffset)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and cf then
        -- Keep the character slightly above the target instead of standing inside it.
        local y = heightOffset or 3
        root.CFrame = cf + Vector3.new(0, y, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        return true
    end
    return false
end

-- Keep the character attached/hovering over the current Egg while the steal
-- interaction is being confirmed. This is especially important for Eggs that
-- spawn on trees or other places with no floor underneath.
local function lockToEgg(eggPart, heightOffset)
    local connection
    local offset = heightOffset or 1.25

    connection = RunService.Heartbeat:Connect(function()
        if not autoSteal or not eggPart or not eggPart.Parent then
            if connection then connection:Disconnect() end
            return
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = eggPart.CFrame + Vector3.new(0, offset, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    return function()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end

-- ==================== EGG ORDER PRIORITY ====================
-- Auto Steal uses the configured EggPriority order.
-- Player Hatch Luck is NOT used to choose the target Egg.

local function parseLuckNumber(value)
    if value == nil then return nil end

    local text = tostring(value):lower()
        :gsub(",", "")
        :gsub("%s+", "")

    -- Accept "1k", "1.5m", "1000000", etc.
    local n, suffix = text:match("([%d%.]+)([kmbt]?)")
    if not n then return nil end

    n = tonumber(n)
    if not n then return nil end

    local mult = 1
    if suffix == "k" then mult = 1e3
    elseif suffix == "m" then mult = 1e6
    elseif suffix == "b" then mult = 1e9
    elseif suffix == "t" then mult = 1e12
    end

    return n * mult
end

local function readLuckFromObject(obj)
    if not obj then return nil end

    local names = {
        "Luck", "EggLuck", "Egg_Luck", "LuckValue",
        "BaseLuck", "Base_Luck"
    }

    for _, name in ipairs(names) do
        local ok, value = pcall(function()
            return obj:GetAttribute(name)
        end)
        if ok and value ~= nil then
            local n = parseLuckNumber(value)
            if n then return n end
        end
    end

    for _, d in ipairs(obj:GetDescendants()) do
        local key = d.Name:lower():gsub("[%s_%-]", "")
        if key == "luck"
            or key == "eggluck"
            or key == "luckvalue"
            or key == "baseluck" then

            if d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue") then
                local n = parseLuckNumber(d.Value)
                if n then return n end
            end
        end
    end

    return nil
end

local function readLuckFromVisibleText(obj)
    if not obj then return nil end

    local best = nil

    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            local txt = tostring(d.Text or "")
            local lower = txt:lower()

            -- Prefer text that explicitly describes Luck.
            if lower:find("luck", 1, true) then
                -- Examples:
                -- "Luck: 1K"
                -- "1K Luck"
                -- "Hatch Luck 1.5M"
                -- "x1.5M Luck"
                for numberText in txt:gmatch("([%d%.]+%s*[kKmMbBtT]?)") do
                    local n = parseLuckNumber(numberText)
                    if n and (not best or n > best) then
                        best = n
                    end
                end
            end
        end
    end

    return best
end

-- Known Ride A Pet map-Egg Luck values.
-- This is a FALLBACK only when the live object does not expose its Luck.
-- Live attributes/UI are always preferred first.
local KnownEggLuck = {
    ["White Egg"] = 1,
    ["Brown Egg"] = 5,
    ["Cracked Egg"] = 30,
    ["Easter Egg"] = 50,
    ["Stone Egg"] = 100,
    ["Leaf Egg"] = 200,
    ["Mushroom Egg"] = 500,
    ["Flower Egg"] = 750,
    ["Slime Egg"] = 1000,
    ["Ice Egg"] = 3000,
    ["Glass Egg"] = 10000,
    ["Golden Egg"] = 30000,
    ["Diamond Egg"] = 90000,
    ["Crystal Egg"] = 150000,
    ["Skull Egg"] = 250000,
    ["Asterold Egg"] = 500000,
    ["Asteroid Egg"] = 500000,
    ["Dominus Egg"] = 700000,
    ["Flaming Egg"] = 1000000,
    ["Sinister Egg"] = 3000000,
    ["Soul Egg"] = 7000000,
    ["Aurora Egg"] = 300000000,
    ["Galaxy Egg"] = 1500000000,
    ["Black Hole Egg"] = 100000000000,
    ["Blackhole Egg"] = 100000000000,
    ["Solaris Egg"] = 300000000000,
    ["Solaris"] = 300000000000,
    ["Volcanic Egg"] = 2500000000000,
    ["Volcanic"] = 2500000000000,
    ["Cherub Egg"] = 1000000000000,
}

local function getEggLuck(egg)
    if not egg then return 0 end

    -- 1) Direct live metadata.
    local direct = readLuckFromObject(egg)
    if direct then return direct end

    -- 2) Visible Luck text attached to the Egg.
    local visible = readLuckFromVisibleText(egg)
    if visible then return visible end

    -- 3) Only check the immediate parent for metadata. Avoid recursively
    -- walking large Map containers for every Egg.
    local parent = egg.Parent
    if parent and parent ~= Workspace then
        local n = readLuckFromObject(parent)
        if n then return n end
    end

    -- 4) Known Egg-name fallback.
    local exact = KnownEggLuck[egg.Name]
    if exact then return exact end

    -- Case-insensitive fallback for renamed/cased variants.
    local lowerName = egg.Name:lower()
    for name, luck in pairs(KnownEggLuck) do
        if lowerName == name:lower() then
            return luck
        end
    end

    return 0
end

local RarityPriority = {
    Ethereal = 7,
    Divine = 6,
    Mythic = 5,
    Legendary = 4,
    Epic = 3,
    Rare = 2,
    Common = 1,
}


-- =========================================================
-- 23-EGG TARGET FINDER
-- =========================================================

local function isValidEgg(obj)
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

    if not RenderedEggs or not obj or not obj.Parent then
        return false
    end

    if not obj:IsA("Model") then
        return false
    end

    if not obj:IsDescendantOf(RenderedEggs) then
        return false
    end

    local lower = obj.Name:lower()
    if not lower:find("egg", 1, true) then
        return false
    end

    if lower:find("spawn", 1, true)
        or lower:find("base", 1, true)
        or lower:find("holder", 1, true)
        or lower:find("zone", 1, true) then
        return false
    end

    return getEggPart(obj) ~= nil and getStealPrompt(obj) ~= nil
end

local function getEggByName(name)
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
    if not RenderedEggs then return nil end

    for _, egg in ipairs(RenderedEggs:GetChildren()) do
        if egg:IsA("Model") and egg.Name == name and isValidEgg(egg) then
            return egg
        end
    end

    -- Case-insensitive fallback.
    local target = name:lower()
    for _, egg in ipairs(RenderedEggs:GetChildren()) do
        if egg:IsA("Model")
            and egg.Name:lower() == target
            and isValidEgg(egg) then
            return egg
        end
    end

    return nil
end

local function findTargetEgg()
    -- BEST-FIRST selection: choose the highest Egg Luck currently spawned.
    -- This checks the live Egg Luck first, so the order automatically adapts
    -- to whatever Eggs are actually in the Map. Player Hatch Luck is never used.
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
    if not RenderedEggs then return nil end

    local candidates = {}
    for _, egg in ipairs(RenderedEggs:GetChildren()) do
        if isValidEgg(egg) then
            local luck = getEggLuck(egg) or 0
            table.insert(candidates, {egg = egg, luck = luck})
        end
    end

    table.sort(candidates, function(a, b)
        if a.luck ~= b.luck then
            return a.luck > b.luck
        end
        return a.egg.Name:lower() < b.egg.Name:lower()
    end)

    if candidates[1] and candidates[1].luck > 0 then
        return candidates[1].egg
    end

    -- If live Luck is hidden, use the researched 23-Egg ladder from highest
    -- Luck to lowest Luck as the deterministic fallback.
    for i = #EggPriority, 1, -1 do
        local wanted = EggPriority[i]
        for _, egg in ipairs(RenderedEggs:GetChildren()) do
            if isValidEgg(egg) and egg.Name:lower() == wanted:lower() then
                return egg
            end
        end
    end
    return nil
end


local cachedTargetEgg = nil
local cachedTargetAt = 0

local function resetExpiredEggTarget()
    cachedTargetEgg = nil
    cachedTargetAt = 0
end

local function getCachedTargetEgg()
    local now = os.clock()

    if cachedTargetEgg and isValidEgg(cachedTargetEgg) then
        return cachedTargetEgg
    end

    if now - cachedTargetAt < 0.15 then
        return nil
    end

    cachedTargetAt = now
    cachedTargetEgg = findTargetEgg()
    return cachedTargetEgg
end

local eggSpawnEvent = Instance.new("BindableEvent")
local eggSpawnConnections = {}

local function disconnectEggSpawnWatchers()
    for _, connection in ipairs(eggSpawnConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    eggSpawnConnections = {}
end

local function signalEggSpawn()
    resetExpiredEggTarget()
    pcall(function()
        eggSpawnEvent:Fire()
    end)
end

local function watchEggContainer(container)
    if not container then return end

    local connection = container.ChildAdded:Connect(function()
        if autoSteal then
            task.defer(signalEggSpawn)
        end
    end)

    table.insert(eggSpawnConnections, connection)
end

local function setupEggSpawnWatchers()
    disconnectEggSpawnWatchers()
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
    if RenderedEggs then
        watchEggContainer(RenderedEggs)
    end
end


-- =========================================================
-- STEAL / RETURN
-- =========================================================

local function returnAfterSuccess()
    local targetCFrame = capturedReturnBaseCFrame
    if not targetCFrame then
        return false
    end

    return teleportCharacter(targetCFrame, 2.5)
end

local function eggIsGone(egg)
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

    return (not egg)
        or (not egg.Parent)
        or (not RenderedEggs)
        or (not egg:IsDescendantOf(RenderedEggs))
end

-- Confirm only for a short window. If it did not work, the caller retries
-- the ProximityPrompt again. Auto Steal keeps retrying until the Egg is taken
-- or Auto Steal is turned OFF.
local function confirmEggTaken(egg, timeout)
    local started = os.clock()
    local limit = timeout or 1.25

    while autoSteal and (os.clock() - started) < limit do
        if eggIsGone(egg) then
            task.wait(0.06)
            if eggIsGone(egg) then
                return true
            end
        end

        task.wait(0.03)
    end

    return false
end

local function triggerStealPrompt(prompt)
    if not prompt or not prompt.Parent then
        return false
    end

    -- Prefer the executor's ProximityPrompt trigger when available.
    local triggered = false
    pcall(function()
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
            triggered = true
        end
    end)

    if triggered then
        return true
    end

    -- Roblox ProximityPrompt API fallback. This is still the Prompt itself,
    -- not mouse/touch Auto Click and not VirtualInput.
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(0, tonumber(prompt.HoldDuration) or 0))
        prompt:InputHoldEnd()
    end)

    return ok
end

local function stealOneEgg(egg)
    if stealBusy or not autoSteal or not isValidEgg(egg) then return end
    stealBusy = true

    local eggPart = getEggPart(egg)
    local prompt = getStealPrompt(egg)
    if not eggPart or not prompt then
        stealBusy = false
        return
    end

    -- Move to the Egg and keep the character at the Egg while retrying.
    Status.Text = "GO EGG"
    teleportCharacter(eggPart.CFrame, 0.75)
    local releaseLock = lockToEgg(eggPart, 0.75)

    local taken = false

    -- RETRY FOREVER:
    -- Keep refreshing the Prompt and triggering it until the selected Egg
    -- is actually removed from RenderedEggs. There is no fixed retry count.
    while autoSteal and not taken do
        if eggIsGone(egg) then
            taken = true
            break
        end

        -- Egg/Prompt can refresh while we are waiting, so find the Prompt
        -- again every retry instead of using a stale reference.
        prompt = getStealPrompt(egg)
        eggPart = getEggPart(egg)

        if eggPart then
            teleportCharacter(eggPart.CFrame, 0.75)
        end

        if prompt then
            Status.Text = "PROMPT"
            triggerStealPrompt(prompt)

            Status.Text = "CONFIRM"
            -- Short confirmation window. If it fails, loop immediately
            -- and trigger the Prompt again.
            taken = confirmEggTaken(egg, 1.25)
        else
            Status.Text = "RETRY"
            task.wait(0.15)
        end

        if not taken and autoSteal then
            Status.Text = "RETRY"
            task.wait(0.12)
        end
    end

    releaseLock()

    if taken and autoSteal then
        Status.Text = "RETURN"
        local returned = returnAfterSuccess()
        if returned then
            task.wait(2)
        end
        resetExpiredEggTarget()
    else
        -- If the user turned Auto Steal OFF, stop without returning.
        Status.Text = "WAIT"
        resetExpiredEggTarget()
    end

    stealBusy = false
end


local function stealOneEgg(egg)
    if stealBusy or not autoSteal or not isValidEgg(egg) then return end
    stealBusy = true

    local eggPart = getEggPart(egg)
    local prompt = getStealPrompt(egg)
    if not eggPart or not prompt then
        stealBusy = false
        return
    end

    -- Move to the Egg. No mouse/touch Auto Click and no VirtualInput are used.
    Status.Text = "GO EGG"
    teleportCharacter(eggPart.CFrame, 0.75)
    local releaseLock = lockToEgg(eggPart, 0.75)

    -- Use the game's ProximityPrompt only. No click simulation or virtual input.
    pcall(function()
        prompt.HoldDuration = 0.0
    end)

    Status.Text = "PROMPT"

    -- ACTIVATE ONLY THE EGG'S ProximityPrompt.
    -- This is not a mouse/touch auto-click and does not use VirtualInput.
    -- The screenshot shows the actual action is "Pick Up", so the prompt
    -- must be fired after moving into range.
    local triggered = false
    pcall(function()
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
            triggered = true
        end
    end)

    -- Executor fallback: use the ProximityPrompt hold API itself.
    if not triggered then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(0, tonumber(prompt.HoldDuration) or 0))
            prompt:InputHoldEnd()
            triggered = true
        end)
    end

    -- CONFIRM FIRST: wait until the selected Egg is really gone.
    -- Only after confirmation do we return to Base, like the earlier build.
    Status.Text = "CONFIRM"
    local taken = confirmEggTaken(egg)

    releaseLock()

    if taken and autoSteal then
        Status.Text = "RETURN"
        local returned = returnAfterSuccess()
        if returned then task.wait(2) end
        resetExpiredEggTarget()
    else
        -- Never return to Base unless the Egg was confirmed taken.
        Status.Text = "WAIT"
        resetExpiredEggTarget()
        task.wait(0.35)
    end

    stealBusy = false
end


local function stopAutoSteal()
    autoSteal = false
    AutoStealBtn.Text = "Auto Steal | OFF"
    AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
    Status.Text = "OFF"
    Status.TextColor3 = Color3.fromRGB(150, 155, 165)

    setMovementLocked(false)
    disconnectEggSpawnWatchers()
    resetExpiredEggTarget()
    autoStealStartCFrame = nil
    capturedReturnBaseCFrame = nil
end

connectTap(AutoStealBtn, function()
    if autoSteal then
        stopAutoSteal()
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    autoStealStartCFrame = root and root.CFrame or nil
    capturedReturnBaseCFrame = getRanchCFrame()

    if not capturedReturnBaseCFrame then
        Status.Text = "NO BASE"
        Status.TextColor3 = Color3.fromRGB(220, 150, 40)
        return
    end

    autoSteal = true
    AutoStealBtn.Text = "Auto Steal | ON"
    AutoStealBtn.BackgroundColor3 = Color3.fromRGB(0, 145, 90)
    Status.Text = "STEAL"
    Status.TextColor3 = Color3.fromRGB(0, 210, 255)

    setMovementLocked(true)
    setupEggSpawnWatchers()

    task.spawn(function()
        while autoSteal do
            local egg = getCachedTargetEgg()

            if egg then
                stealOneEgg(egg)
            else
                task.wait(0.15)
            end
        end
    end)
end)

-- =========================================================
-- EGG IN MAP DISPLAY
-- =========================================================

local function clearMapPanel()
    for _, child in ipairs(MapScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function refreshMapPanel()
    clearMapPanel()

    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

    local found = {}

    if RenderedEggs then
        for _, egg in ipairs(RenderedEggs:GetChildren()) do
            if egg:IsA("Model") and isValidEgg(egg) then
                local key = egg.Name
                found[key] = (found[key] or 0) + 1
            end
        end
    end

    local entries = {}
    for eggName, count in pairs(found) do
        local luck = KnownEggLuck[eggName]
        if not luck then
            local lower = eggName:lower()
            for knownName, knownLuck in pairs(KnownEggLuck) do
                if lower == knownName:lower() then
                    luck = knownLuck
                    break
                end
            end
        end
        luck = luck or 0
        table.insert(entries, {name = eggName, count = count, luck = luck})
    end

    table.sort(entries, function(a, b)
        if a.luck ~= b.luck then
            return a.luck > b.luck
        end
        return a.name:lower() < b.name:lower()
    end)

    local rowOrder = 0

    for _, entry in ipairs(entries) do
        rowOrder += 1

        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, -4, 0, 27)
        row.LayoutOrder = rowOrder
        row.BackgroundColor3 = Color3.fromRGB(31, 34, 45)
        row.TextColor3 = Color3.fromRGB(235, 238, 245)
        row.Font = Enum.Font.SourceSans
        row.TextSize = 13
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Text = string.format("%02d  %s  ×%d", rowOrder, entry.name, entry.count)
        row.Parent = MapScroll

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row
    end

    if rowOrder == 0 then
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, -4, 0, 30)
        row.Text = "No Egg detected"
        row.BackgroundTransparency = 1
        row.TextColor3 = Color3.fromRGB(145, 150, 160)
        row.Font = Enum.Font.SourceSans
        row.TextSize = 13
        row.Parent = MapScroll
        rowOrder = 1
    end

    MapScroll.CanvasSize = UDim2.new(0, 0, 0, rowOrder * 29 + 5)
end

task.spawn(function()
    while ScreenGui.Parent do
        if MapFrame.Visible then
            refreshMapPanel()
        end
        task.wait(0.6)
    end
end)

print("[OLIVER] Mobile Auto Steal + ProximityPrompt | READY")

-- =========================================================
-- STARTUP
-- =========================================================

AutoStealBtn.Text = "Auto Steal | OFF"
AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
HoldLabel.Text = "Hold 0.0s"
Status.Text = "OFF"
Status.TextColor3 = Color3.fromRGB(0, 210, 255)
MapPanelBtn.Text = "Egg in Map | OFF"
MapPanelBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
ESPEggBtn.Text = "ESP EGG | OFF"
ESPEggBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
SpeedBtn.Text = "SPEED | OFF"
SpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 55)

-- All panels are independent. Main UI starts closed.
MainFrame.Visible = false
MapFrame.Visible = false
