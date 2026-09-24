local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Ride A Pet: Eggs are rendered under Workspace.RenderedEggs
local RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

-- 1. ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OliverHubUI_EggDistance"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- 2. មុខងារ Drag (អូស Frame/Button)
local function makeDraggable(gui)
    local dragging = false
    local dragInput, dragStart, startPos

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 3. Button បិទ/បើក Main Frame
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleMenuBtn"
ToggleBtn.Size = UDim2.new(0, 90, 0, 38)
ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ToggleBtn.Text = "OLIVER"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 230, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 15
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

makeDraggable(ToggleBtn)

-- 4. Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 450)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 200, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

makeDraggable(MainFrame)

-- Header Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Text = "OLIVER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 20
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = MainFrame

-- Fixed-height scroll area so the UI stays compact on screen.
local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Name = "MainScroll"
MainScroll.Size = UDim2.new(1, -12, 1, -52)
MainScroll.Position = UDim2.new(0, 6, 0, 46)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.ScrollBarThickness = 5
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
MainScroll.ScrollingDirection = Enum.ScrollingDirection.Y
MainScroll.ClipsDescendants = true
MainScroll.ZIndex = 5
MainScroll.Parent = MainFrame

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- 5. ESP EGG Button
local EspEggBtn = Instance.new("TextButton")
EspEggBtn.Size = UDim2.new(0.85, 0, 0, 42)
EspEggBtn.Position = UDim2.new(0.075, 0, 0, 70)
EspEggBtn.Text = "ESP EGG | OFF"
EspEggBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
EspEggBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EspEggBtn.Font = Enum.Font.SourceSansBold
EspEggBtn.TextSize = 15
EspEggBtn.Parent = MainScroll

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = EspEggBtn


-- ==================== AUTO STEAL ====================
local autoSteal = false
local selectedEggs = { All = true } -- multi-select rarity/type selector
local holdTime = 0.0
local stealBusy = false
local autoStealStartCFrame = nil
local returnMode = "Base" -- "Start Position" or "Base"

-- Lock player movement while Auto Steal is ON so manual input cannot
-- fight the teleport/steal sequence. Original values are restored on OFF.
local movementLock = {
    controls = nil,
    walkSpeed = nil,
    jumpPower = nil,
    jumpHeight = nil,
    autoRotate = nil,
}

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

local AutoStealBtn = Instance.new("TextButton")
AutoStealBtn.Size = UDim2.new(0.85, 0, 0, 38)
AutoStealBtn.Position = UDim2.new(0.075, 0, 0, 120)
AutoStealBtn.Text = "Auto Steal | OFF"
AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
AutoStealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoStealBtn.Font = Enum.Font.SourceSansBold
AutoStealBtn.TextSize = 15
AutoStealBtn.Parent = MainScroll

local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 8)
AutoCorner.Parent = AutoStealBtn

local StealStatus = Instance.new("TextLabel")
StealStatus.Size = UDim2.new(0.85, 0, 0, 22)
StealStatus.Position = UDim2.new(0.075, 0, 0, 135)
StealStatus.Text = "Status: Ready"
StealStatus.TextXAlignment = Enum.TextXAlignment.Left
StealStatus.TextColor3 = Color3.fromRGB(170, 170, 180)
StealStatus.BackgroundTransparency = 1
StealStatus.Font = Enum.Font.SourceSans
StealStatus.TextSize = 12
StealStatus.Parent = MainScroll

local SelectLabel = Instance.new("TextLabel")
SelectLabel.Size = UDim2.new(0.85, 0, 0, 24)
SelectLabel.Position = UDim2.new(0.075, 0, 0, 190)
SelectLabel.Text = "Select Egg Type"
SelectLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Font = Enum.Font.SourceSansBold
SelectLabel.TextSize = 14
SelectLabel.Parent = MainScroll

local SelectEggBtn = Instance.new("TextButton")
SelectEggBtn.Size = UDim2.new(0.85, 0, 0, 34)
SelectEggBtn.Position = UDim2.new(0.075, 0, 0, 216)
SelectEggBtn.Text = "All  ∨"
SelectEggBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SelectEggBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectEggBtn.Font = Enum.Font.SourceSans
SelectEggBtn.TextSize = 14
SelectEggBtn.Parent = MainScroll

local SelectCorner = Instance.new("UICorner")
SelectCorner.CornerRadius = UDim.new(0, 8)
SelectCorner.Parent = SelectEggBtn

local ReturnLabel = Instance.new("TextLabel")
ReturnLabel.Size = UDim2.new(0.85, 0, 0, 22)
ReturnLabel.Position = UDim2.new(0.075, 0, 0, 267)
ReturnLabel.Text = "Return To"
ReturnLabel.TextXAlignment = Enum.TextXAlignment.Left
ReturnLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
ReturnLabel.BackgroundTransparency = 1
ReturnLabel.Font = Enum.Font.SourceSansBold
ReturnLabel.TextSize = 14
ReturnLabel.Parent = MainScroll

local ReturnBtn = Instance.new("TextButton")
ReturnBtn.Size = UDim2.new(0.85, 0, 0, 34)
ReturnBtn.Position = UDim2.new(0.075, 0, 0, 292)
ReturnBtn.Text = "Start Position  ∨"
ReturnBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ReturnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ReturnBtn.Font = Enum.Font.SourceSans
ReturnBtn.TextSize = 14
ReturnBtn.Parent = MainScroll

local ReturnCorner = Instance.new("UICorner")
ReturnCorner.CornerRadius = UDim.new(0, 8)
ReturnCorner.Parent = ReturnBtn

-- Forward declaration: Return To uses EggList in its click handler.
local EggList

local ReturnList = Instance.new("Frame")
ReturnList.Size = UDim2.new(0.85, 0, 0, 66)
ReturnList.Position = UDim2.new(0.075, 0, 0, 292)
ReturnList.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ReturnList.BorderSizePixel = 0
ReturnList.Visible = false
ReturnList.ZIndex = 110
ReturnList.Parent = MainScroll

local ReturnLayout = Instance.new("UIListLayout")
ReturnLayout.SortOrder = Enum.SortOrder.LayoutOrder
ReturnLayout.Parent = ReturnList

local function addReturnOption(textValue, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 32)
    b.LayoutOrder = order
    b.Text = textValue
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 13
    b.ZIndex = 111
    b.Parent = ReturnList
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = b
    b.MouseButton1Click:Connect(function()
        returnMode = textValue
        ReturnBtn.Text = textValue .. "  ∨"
        ReturnList.Visible = false
    end)
end
addReturnOption("Start Position", 1)
addReturnOption("Base", 2)

ReturnBtn.MouseButton1Click:Connect(function()
    EggList.Visible = false
    MainScroll.CanvasPosition = Vector2.new(0, 0)
    ReturnLabel.Position = UDim2.new(0.075, 0, 0, 267)
    ReturnBtn.Position = UDim2.new(0.075, 0, 0, 292)
    ReturnList.Position = UDim2.new(0.075, 0, 0, 292)
    ReturnList.Visible = not ReturnList.Visible
end)

EggList = Instance.new("ScrollingFrame")
EggList.Size = UDim2.new(0.85, 0, 0, 220)
EggList.Position = UDim2.new(0.075, 0, 0, 230)
EggList.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
EggList.BorderSizePixel = 0
EggList.Visible = false
EggList.ZIndex = 200
EggList.ScrollBarThickness = 6
EggList.ClipsDescendants = true
EggList.CanvasSize = UDim2.new(0, 0, 0, 0)
EggList.Parent = MainScroll

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = EggList

-- មុខងារតម្រង (Filter) រកតែ Egg ពិតប្រាកដ
function isValidEgg(obj)
    -- Ride A Pet eggs live directly under Workspace.RenderedEggs.
    if not RenderedEggs or not obj:IsDescendantOf(RenderedEggs) then
        return false
    end

    -- Only track the actual egg Model, not its Handle/BillboardGui children.
    if not obj:IsA("Model") then
        return false
    end

    -- ១. រំលងប្រសិនបើវាជាផ្នែកមួយនៃ Player Character ឬ Pet ដែលកំពុងជិះ
    local modelAncestor = obj:FindFirstAncestorOfClass("Model")
    if modelAncestor and Players:GetPlayerFromCharacter(modelAncestor) then
        return false
    end

    local nameLower = obj.Name:lower()

    -- ២. រំលងពាក្យបច្ចេកទេសដែលមិនមែនជា Egg (ដូចជា EggSpawn, EggBase, Spawn -ល-)
    if nameLower:find("spawn") or nameLower:find("base") or nameLower:find("holder") or nameLower:find("zone") then
        return false
    end

    -- ៣. ត្រូវតែមានពាក្យ "egg" ក្នុងឈ្មោះ
    if not nameLower:find("egg") then
        return false
    end

    -- ៤. ការពារឈ្មោះជាន់គ្នា៖ បើវាជា Part ធម្មតា ហើយ Parent Model វាមានឈ្មោះ Egg ស្រាប់ -> យកតែ Parent Model
    if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent.Name:lower():find("egg") then
        return false
    end

    return true
end


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
    ["90K Luck Egg"] = "Mythic",
    ["500K Luck Egg"] = "Mythic",
    ["Aurora Egg"] = "Divine",
    ["Galaxy Egg"] = "Divine",
    ["Black Hole Egg"] = "Ethereal",
    ["Solaris Egg"] = "Ethereal",
    ["Cherub Egg"] = "Ethereal"
}

local EggTypes = {"All", "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal"}
local RarityTypes = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal"}

local function isEggTypeSelected(rarity)
    if selectedEggs.All then
        return true
    end
    return rarity ~= nil and selectedEggs[rarity] == true
end

local function updateEggTypeButtonText()
    if selectedEggs.All then
        SelectEggBtn.Text = "All  ∨"
        return
    end

    local count = 0
    for _, rarity in ipairs(RarityTypes) do
        if selectedEggs[rarity] then
            count += 1
        end
    end

    if count == 0 then
        SelectEggBtn.Text = "None  ∨"
    elseif count == 1 then
        for _, rarity in ipairs(RarityTypes) do
            if selectedEggs[rarity] then
                SelectEggBtn.Text = rarity .. "  ∨"
                return
            end
        end
    else
        SelectEggBtn.Text = tostring(count) .. " Selected  ∨"
    end
end

local function getEggType(egg)
    if not egg then return nil end
    if EggRarity[egg.Name] then
        return EggRarity[egg.Name]
    end

    -- Fallback: some versions display rarity/type in an attribute or StringValue.
    local attr = egg:GetAttribute("Rarity") or egg:GetAttribute("Type") or egg:GetAttribute("EggType")
    if typeof(attr) == "string" then
        return attr
    end

    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("StringValue") and (d.Name == "Rarity" or d.Name == "Type" or d.Name == "EggType") then
            return d.Value
        end
    end
    return nil
end

local function refreshEggList()
    for _, child in ipairs(EggList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    for order, eggType in ipairs(EggTypes) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -4, 0, 28)
        b.LayoutOrder = order
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.SourceSans
        b.TextSize = 14
        b.ZIndex = 201
        b.Parent = EggList

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = b

        local function redraw()
            local checked = selectedEggs[eggType] == true
            b.Text = (checked and "☑ " or "☐ ") .. eggType
            if checked then
                b.BackgroundColor3 = Color3.fromRGB(0, 120, 75)
            else
                b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            end
        end

        redraw()

        b.MouseButton1Click:Connect(function()
            if eggType == "All" then
                -- All = every rarity selected. Clicking again clears all.
                if selectedEggs.All then
                    selectedEggs = {}
                else
                    selectedEggs = { All = true }
                end
            else
                -- Selecting a specific rarity turns off the All shortcut.
                selectedEggs.All = nil
                selectedEggs[eggType] = not selectedEggs[eggType]
            end

            -- If every rarity is selected individually, collapse to All.
            local allRarities = true
            for _, rarity in ipairs(RarityTypes) do
                if not selectedEggs[rarity] then
                    allRarities = false
                    break
                end
            end
            if allRarities then
                selectedEggs = { All = true }
            end

            updateEggTypeButtonText()
            refreshEggList()
        end)
    end

    EggList.CanvasSize = UDim2.new(0, 0, 0, #EggTypes * 30 + 4)
    MainScroll.CanvasSize = UDim2.new(0, 0, 0, 570)
end

updateEggTypeButtonText()
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 570)

SelectEggBtn.MouseButton1Click:Connect(function()
    if not EggList.Visible then
        MainScroll.CanvasPosition = Vector2.new(0, 0)
        refreshEggList()
    end

    EggList.Visible = not EggList.Visible
    ReturnList.Visible = false

    -- Move Return To below the open Egg Type list so the two menus never overlap.
    if EggList.Visible then
        ReturnLabel.Position = UDim2.new(0.075, 0, 0, 510)
        ReturnBtn.Position = UDim2.new(0.075, 0, 0, 535)
        ReturnList.Position = UDim2.new(0.075, 0, 0, 535)
    else
        ReturnLabel.Position = UDim2.new(0.075, 0, 0, 267)
        ReturnBtn.Position = UDim2.new(0.075, 0, 0, 292)
        ReturnList.Position = UDim2.new(0.075, 0, 0, 292)
    end
end)

-- ==================== BASE FINDER ====================
-- Dynamically finds the player's own Ranch/Base/Plot.
-- It checks names, attributes and ValueObjects instead of assuming
-- a fixed Workspace path.
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

    -- Attributes
    for _, attrName in ipairs({
        "Owner", "owner", "OwnerName", "ownerName",
        "Player", "PlayerName", "UserId", "OwnerUserId"
    }) do
        local ok, value = pcall(function()
            return obj:GetAttribute(attrName)
        end)
        if ok and value ~= nil and valueMatchesPlayer(value) then
            score += 12
        end
    end

    -- Direct ValueObjects
    for _, child in ipairs(obj:GetChildren()) do
        if child:IsA("ObjectValue") then
            if child.Value == LocalPlayer then score += 12 end
        elseif child:IsA("StringValue") then
            if valueMatchesPlayer(child.Value) then score += 12 end
        elseif child:IsA("IntValue") or child:IsA("NumberValue") then
            if valueMatchesPlayer(child.Value) then score += 12 end
        end
    end

    local n = obj.Name:lower()
    if n == LocalPlayer.Name:lower() then score += 10 end
    if n == LocalPlayer.DisplayName:lower() then score += 8 end

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
    -- Refresh periodically because plots can be created/claimed after script start.
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

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if hasKeyword(obj.Name) then
            local score = baseNameScore(obj) + candidateOwnerMatch(obj)
            local part = findReturnPart(obj)

            if part then
                -- Prefer bases that are explicitly owned by the local player.
                -- Do not pick an arbitrary object merely because its name contains
                -- "base"/"plot"/"ranch".
                if score > cachedBaseScore and candidateOwnerMatch(obj) > 0 then
                    cachedBaseScore = score
                    cachedBasePart = part
                end
            end
        end
    end

    if cachedBasePart then
        print("[OLIVER] Owned Base found:", cachedBasePart:GetFullName(), "score=", cachedBaseScore)
    else
        warn("[OLIVER] Explicitly-owned Base/Ranch was not found")
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

    -- Prefer a prompt explicitly named Steal.
    for _, x in ipairs(egg:GetDescendants()) do
        if x:IsA("ProximityPrompt") and x.Name:lower():find("steal") then
            return x
        end
    end

    -- Fallback to the first ProximityPrompt on the egg.
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
        -- Move directly to the Egg's center, with only a tiny lift so the
        -- character does not get stuck inside the Egg.
        local y = heightOffset or 0.05
        root.CFrame = cf + Vector3.new(0, y, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        return true
    end
    return false
end

local function valueMatchesLocalPlayer(value)
    if value == LocalPlayer then return true end
    if typeof(value) == "string" then
        local v = value:lower()
        return v == LocalPlayer.Name:lower() or v == LocalPlayer.DisplayName:lower()
    end
    if typeof(value) == "number" then
        return value == LocalPlayer.UserId
    end
    return false
end

-- Ownership is intentionally conservative. The public game documentation does
-- not expose a documented Owner/ClaimedBy field for Eggs, so disappearance from
-- RenderedEggs is NEVER treated as a successful steal by itself.
local OWNER_KEYS = {
    "owner", "ownername", "owneruserid", "userid", "player",
    "playername", "playerid", "claimedby", "claimedbyname",
    "claimedbyuserid", "ownedby", "ownedbyname", "ownedbyuserid"
}

local function normalizedKey(name)
    return tostring(name):lower():gsub("[%s_%-]", "")
end

local function hasLocalOwnershipMarker(root)
    if not root then return false end

    local function keyMatches(name)
        local n = normalizedKey(name)
        for _, key in ipairs(OWNER_KEYS) do
            if n == key then return true end
        end
        return false
    end

    -- Attributes on the root.
    for _, attrName in ipairs({
        "Owner", "OwnerName", "OwnerUserId", "UserId", "Player",
        "PlayerName", "PlayerId", "ClaimedBy", "ClaimedByName",
        "ClaimedByUserId", "OwnedBy", "OwnedByName", "OwnedByUserId"
    }) do
        local ok, value = pcall(function() return root:GetAttribute(attrName) end)
        if ok and value ~= nil and valueMatchesLocalPlayer(value) then
            return true
        end
    end

    -- ValueObjects / attributes on descendants.
    for _, d in ipairs(root:GetDescendants()) do
        if keyMatches(d.Name) then
            if d:IsA("ObjectValue") and d.Value == LocalPlayer then
                return true
            elseif d:IsA("StringValue") and valueMatchesLocalPlayer(d.Value) then
                return true
            elseif (d:IsA("IntValue") or d:IsA("NumberValue")) and valueMatchesLocalPlayer(d.Value) then
                return true
            end
        end

        for _, attrName in ipairs({
            "Owner", "OwnerName", "OwnerUserId", "UserId", "Player",
            "PlayerName", "PlayerId", "ClaimedBy", "ClaimedByName",
            "ClaimedByUserId", "OwnedBy", "OwnedByName", "OwnedByUserId"
        }) do
            local ok, value = pcall(function() return d:GetAttribute(attrName) end)
            if ok and value ~= nil and valueMatchesLocalPlayer(value) then
                return true
            end
        end
    end

    return false
end

local function containsNamedOwnedObject(root, targetName)
    if not root or not targetName then return false end
    if root.Name == targetName and hasLocalOwnershipMarker(root) then
        return true
    end
    for _, d in ipairs(root:GetDescendants()) do
        if d.Name == targetName and hasLocalOwnershipMarker(d) then
            return true
        end
    end
    return false
end

local function findOwnedEggEvidence(egg)
    if not egg then return false end
    local targetName = egg.Name

    -- A) Original egg gets an explicit ownership marker.
    if hasLocalOwnershipMarker(egg) then
        return true
    end

    -- B) Game reparents/moves an owned copy into a player-owned container.
    local roots = {
        LocalPlayer.Character,
        LocalPlayer:FindFirstChild("Backpack"),
        LocalPlayer:FindFirstChild("Inventory"),
        LocalPlayer:FindFirstChild("Pets"),
        LocalPlayer:FindFirstChild("Eggs")
    }
    for _, root in ipairs(roots) do
        if containsNamedOwnedObject(root, targetName) then
            return true
        end
    end

    -- C) If the game puts the claimed Egg into the player's own ranch/base,
    -- treat a same-named object with an ownership marker as confirmation.
    local base = findPlayerBase()
    if base then
        local container = base:FindFirstAncestorOfClass("Model") or base.Parent
        if container and containsNamedOwnedObject(container, targetName) then
            return true
        end
    end

    return false
end

local function findTargetEgg()
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
    if not RenderedEggs then return nil end

    for _, egg in ipairs(RenderedEggs:GetChildren()) do
        if isValidEgg(egg) and isEggTypeSelected(getEggType(egg)) then
            if getEggPart(egg) and getStealPrompt(egg) then
                return egg
            end
        end
    end

    return nil
end

local function waitForEggTaken(egg, timeout)
    local deadline = os.clock() + (timeout or 4)
    local sawRemoved = false

    while os.clock() < deadline do
        if not autoSteal then
            return false
        end

        -- SUCCESS: the game has explicitly marked this Egg as belonging to us
        -- (or moved an owned copy into a player-owned container).
        if findOwnedEggEvidence(egg) then
            return true
        end

        -- If it disappears/reparents before ownership is visible, remember that
        -- state but DO NOT return yet. Another player may have taken it.
        if not egg or not egg.Parent or not RenderedEggs or not egg:IsDescendantOf(RenderedEggs) then
            sawRemoved = true
        end

        task.wait(0.03)
    end

    if sawRemoved then
        warn("[OLIVER] Egg disappeared, but ownership was not confirmed; will NOT return or count it as stolen")
    else
        warn("[OLIVER] Egg ownership was not confirmed; will NOT return or count it as stolen")
    end

    return false
end

local function isNearCFrame(cf, maxDistance)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not cf then return false end
    return (root.Position - cf.Position).Magnitude <= (maxDistance or 8)
end

local function returnAfterSuccess()
    local targetCFrame = nil

    if returnMode == "Base" then
        targetCFrame = getRanchCFrame()
        if not targetCFrame then
            warn("[OLIVER] Base not detected. Auto Steal will NOT continue to the next Egg.")
            StealStatus.Text = "Status: Base not detected — PAUSED"
            return false
        end
    else
        targetCFrame = autoStealStartCFrame
        if not targetCFrame then
            warn("[OLIVER] Start Position unavailable. Auto Steal will NOT continue.")
            return false
        end
    end

    local ok = teleportCharacter(targetCFrame, returnMode == "Base" and 2.5 or 0.05)
    if not ok then
        return false
    end

    -- Verify that the teleport really put the character at the return point.
    for _ = 1, 20 do
        if isNearCFrame(targetCFrame, 10) then
            StealStatus.Text = "Status: Returned to " .. returnMode .. " ✓"
            return true
        end
        task.wait(0.05)
    end

    warn("[OLIVER] Return position was not reached; blocking next Egg.")
    StealStatus.Text = "Status: Return not confirmed — PAUSED"
    return false
end

local function stealOneEgg(egg)
    if stealBusy or not autoSteal or not egg or not egg.Parent then return end
    stealBusy = true

    local success = false
    local eggPart = getEggPart(egg)
    local prompt = getStealPrompt(egg)

    if eggPart and prompt then
        -- Fly/teleport directly to the middle of the Egg. The tiny 0.8-stud
        -- lift keeps the root from being buried inside the Egg while remaining
        -- close enough for the Steal prompt.
        teleportCharacter(eggPart.CFrame, 0.05)
        task.wait(0.02)

        -- Hold 0.0s. Roblox documents HoldDuration=0 as immediate activation.
        pcall(function()
            prompt.HoldDuration = 0
        end)

        if fireproximityprompt then
            pcall(function()
                fireproximityprompt(prompt, 0, true)
            end)
        else
            pcall(function()
                prompt:InputHoldBegin()
                prompt:InputHoldEnd()
            end)
        end

        -- IMPORTANT: do not return just because the Egg disappeared. Wait until
        -- the game explicitly shows that the Egg belongs to LocalPlayer.
        success = waitForEggTaken(egg, 6)

        if success then
            StealStatus.Text = "Status: Ownership confirmed ✓ — RETURNING"

            -- HARD GATE: never search for another Egg until the character has
            -- actually reached the selected return point.
            local returned = returnAfterSuccess()
            if not returned then
                StealStatus.Text = "Status: RETURN FAILED — Auto Steal PAUSED"
                autoSteal = false
                AutoStealBtn.Text = "Auto Steal | PAUSED"
                AutoStealBtn.BackgroundColor3 = Color3.fromRGB(180, 90, 0)
                setMovementLocked(false)
                stealBusy = false
                return
            end

            -- Stay at Base/Start for exactly 1 second before the next Egg.
            StealStatus.Text = "Status: At " .. returnMode .. " ✓ — waiting 1s"
            task.wait(1.0)
        else
            StealStatus.Text = "Status: Ownership NOT confirmed — waiting"
            -- Do not immediately fire the same prompt again. Give the game a
            -- moment to finish its server-side state change.
            task.wait(0.20)
        end
    end

    stealBusy = false
end

AutoStealBtn.MouseButton1Click:Connect(function()
    autoSteal = not autoSteal

    if autoSteal then
        -- Save the exact place the player was standing when Auto Steal was turned ON.
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        autoStealStartCFrame = root and root.CFrame or nil

        AutoStealBtn.Text = "Auto Steal | ON"
        StealStatus.Text = "Status: Waiting for Egg..."
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)

        -- Prevent manual character movement while the automation is running.
        setMovementLocked(true)

        task.spawn(function()
            while autoSteal do
                local egg = findTargetEgg()
                if egg then
                    StealStatus.Text = "Status: Going to " .. egg.Name
                    stealOneEgg(egg)
                    if autoSteal then StealStatus.Text = "Status: Waiting for next Egg..." end
                else
                    task.wait(0.05)
                end
            end
        end)
    else
        AutoStealBtn.Text = "Auto Steal | OFF"
        StealStatus.Text = "Status: Ready"
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        setMovementLocked(false)
        autoStealStartCFrame = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    if not autoSteal then return end
    task.wait(0.15)
    setMovementLocked(true)
end)

-- ==================== ADVANCED & CLEAN ESP SYSTEM ====================
local isEspEgg = false
local activeESP = {}
local updateConnection
local addedConnection

local function removeESP()
    for obj, data in pairs(activeESP) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    activeESP = {}

    if updateConnection then updateConnection:Disconnect() updateConnection = nil end
    if addedConnection then addedConnection:Disconnect() addedConnection = nil end
end


local function createESPForObject(obj)
    if not isEspEgg then return end
    if activeESP[obj] or not isValidEgg(obj) then return end

    local primaryPart
    if obj:IsA("Model") then
        -- Exact Ride A Pet structure uses Handle for the egg's world position.
        primaryPart = obj:FindFirstChild("Handle")
            or obj.PrimaryPart
            or obj:FindFirstChildWhichIsA("BasePart", true)
    elseif obj:IsA("BasePart") then
        primaryPart = obj
    else
        return
    end
    if not primaryPart then return end

    -- 1. Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "Oliver_EggHighlight"
    highlight.Adornee = obj
    highlight.FillColor = Color3.fromRGB(255, 170, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0
    highlight.Parent = obj

    -- 2. Billboard Label (ចេញតែ ១ គត់)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Oliver_EggName"
    billboard.Adornee = primaryPart
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = obj

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = "🥚 " .. obj.Name .. " [0m]"
    textLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.BackgroundTransparency = 1
    textLabel.Parent = billboard

    activeESP[obj] = {
        Highlight = highlight,
        Billboard = billboard,
        TextLabel = textLabel,
        Part = primaryPart
    }
end

local function applyESP()
    removeESP()
    if not isEspEgg then return end

    -- Scan only the game's actual egg container.
    -- This avoids unrelated BillboardGuis/objects elsewhere in Workspace.
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

    if RenderedEggs then
        for _, obj in ipairs(RenderedEggs:GetChildren()) do
            createESPForObject(obj)
        end

        -- Catch newly spawned eggs immediately.
        addedConnection = RenderedEggs.ChildAdded:Connect(function(obj)
            if not isEspEgg then return end

            task.spawn(function()
                for _ = 1, 8 do
                    if not isEspEgg then return end

                    createESPForObject(obj)

                    if activeESP[obj] then
                        return
                    end

                    task.wait(0.1)
                end
            end)
        end)
    else
        -- Folder may be created after the script starts.
        addedConnection = Workspace.ChildAdded:Connect(function(obj)
            if obj.Name ~= "RenderedEggs" then return end
            RenderedEggs = obj

            if not isEspEgg then return end

            for _, egg in ipairs(RenderedEggs:GetChildren()) do
                createESPForObject(egg)
            end

            if addedConnection then
                addedConnection:Disconnect()
            end

            addedConnection = RenderedEggs.ChildAdded:Connect(function(egg)
                if isEspEgg then
                    task.wait(0.1)
                    createESPForObject(egg)
                end
            end)
        end)
    end

    -- ==================== REAL-TIME DISTANCE ====================
    -- ប្រើ GetPivot() សម្រាប់ Model ដើម្បីកុំឲ្យ distance នៅ [0m]
    -- ប្រសិនបើ Egg មិនមាន PrimaryPart ឬ Character ទើប spawn មិនទាន់រួច។
    local function getWorldPosition(instance)
        if not instance or not instance.Parent then
            return nil
        end

        if instance:IsA("BasePart") then
            return instance.Position
        end

        if instance:IsA("Model") then
            -- Ride A Pet egg structure: <Egg Model>.Handle
            local handle = instance:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                return handle.Position
            end

            local ok, pivot = pcall(function()
                return instance:GetPivot()
            end)

            if ok and pivot then
                return pivot.Position
            end
        end

        return nil
    end

    updateConnection = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        local playerPos = getWorldPosition(char)

        for obj, data in pairs(activeESP) do
            if not obj or not obj.Parent then
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
                activeESP[obj] = nil
            else
                -- យកទីតាំងពី Egg Model ផ្ទាល់ជាមុន
                local eggPos = getWorldPosition(obj)

                -- Fallback ទៅ Part ដែលបានរកឃើញពេលបង្កើត ESP
                if not eggPos then
                    eggPos = getWorldPosition(data.Part)
                end

                if playerPos and eggPos then
                    local dist = math.floor((playerPos - eggPos).Magnitude + 0.5)
                    data.TextLabel.Text = string.format(
                        "🥚 %s [%dm]",
                        obj.Name,
                        dist
                    )
                elseif data.Part and data.Part.Parent then
                    -- Part អាចមានតែបន្ទាប់ពី Model spawn រួច
                    local partPos = getWorldPosition(data.Part)
                    if playerPos and partPos then
                        local dist = math.floor((playerPos - partPos).Magnitude + 0.5)
                        data.TextLabel.Text = string.format(
                            "🥚 %s [%dm]",
                            obj.Name,
                            dist
                        )
                    end
                end
            end
        end
    end)
end

EspEggBtn.MouseButton1Click:Connect(function()
    isEspEgg = not isEspEgg
    if isEspEgg then
        EspEggBtn.Text = "ESP EGG | ON"
        EspEggBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        applyESP()
    else
        EspEggBtn.Text = "ESP EGG | OFF"
        EspEggBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        removeESP()
    end
end)
