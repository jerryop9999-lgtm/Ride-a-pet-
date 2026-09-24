local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Mobile touch support: every TextButton accepts direct finger taps.
local function setupTouchButton(button)
    if button and button:IsA("TextButton") then
        button.Active = true
        button.Selectable = true
        button.AutoButtonColor = true
    end
end

-- One-finger tap handler: use the button's own input so ScrollingFrame/drag
-- handling cannot require a second finger. Touch activates on release.
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

local LocalPlayer = Players.LocalPlayer

-- Ride A Pet: Eggs are rendered under Workspace.RenderedEggs
local RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

-- 1. ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OliverHubUI_EggDistance"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = 999

-- Make every button reliably tappable on phones/tablets.
ScreenGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("GuiButton") then
        obj.Active = true
        obj.AutoButtonColor = true
    end
end)

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

    gui.Active = true

    gui.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        -- Do not steal a tap from any Button / ScrollingFrame underneath.
        local objects = game:GetService("GuiService"):GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
        for _, obj in ipairs(objects) do
            if obj:IsA("GuiButton") or obj:IsA("ScrollingFrame") then
                return
            end
            if obj == gui then
                break
            end
        end

        dragging = true
        dragStart = input.Position
        startPos = gui.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
            end
        end)
    end)

    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then
            return
        end

        local delta = input.Position - dragStart
        gui.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)
end
-- 3. Button បិទ/បើក Main Frame
local EggMainFrame

local ToggleBtn = Instance.new("TextButton")
setupTouchButton(ToggleBtn)
ToggleBtn.Active = true
ToggleBtn.Name = "OLIVER"
ToggleBtn.Size = UDim2.new(0, 78, 0, 32)
ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ToggleBtn.Text = "OLIVER"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 230, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

-- ToggleBtn is tap-only on mobile so one finger activates it reliably.

-- 4. Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Active = true
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 280)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
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
TitleLabel.Size = UDim2.new(1, 0, 0, 34)
TitleLabel.Text = "OLIVER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = MainFrame

-- Fixed-height scroll area so the UI stays compact on screen.
local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Name = "MainScroll"
MainScroll.Size = UDim2.new(1, -12, 1, -44)
MainScroll.Position = UDim2.new(0, 6, 0, 38)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.ScrollBarThickness = 5
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 660)
MainScroll.ScrollingDirection = Enum.ScrollingDirection.Y
MainScroll.ClipsDescendants = true
MainScroll.ZIndex = 5
MainScroll.Parent = MainFrame

connectTap(ToggleBtn, function()
    MainFrame.Visible = not MainFrame.Visible
    ToggleBtn.Text = "OLIVER"
end)

-- 5. ESP EGG Button
local EspEggBtn = Instance.new("TextButton")
setupTouchButton(EspEggBtn)
EspEggBtn.Size = UDim2.new(0.85, 0, 0, 44)
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
local capturedReturnBaseCFrame = nil
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
setupTouchButton(AutoStealBtn)
AutoStealBtn.Size = UDim2.new(0.85, 0, 0, 44)
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

local SelectLabel = Instance.new("TextLabel")
SelectLabel.Size = UDim2.new(0.85, 0, 0, 24)
SelectLabel.Position = UDim2.new(0.075, 0, 0, 168)
SelectLabel.Text = "Select Egg Type"
SelectLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Font = Enum.Font.SourceSansBold
SelectLabel.TextSize = 14
SelectLabel.Parent = MainScroll

local SelectEggBtn = Instance.new("TextButton")
setupTouchButton(SelectEggBtn)
SelectEggBtn.Size = UDim2.new(0.85, 0, 0, 44)
SelectEggBtn.Position = UDim2.new(0.075, 0, 0, 194)
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
ReturnLabel.Position = UDim2.new(0.075, 0, 0, 245)
ReturnLabel.Text = "Return To"
ReturnLabel.TextXAlignment = Enum.TextXAlignment.Left
ReturnLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
ReturnLabel.BackgroundTransparency = 1
ReturnLabel.Font = Enum.Font.SourceSansBold
ReturnLabel.TextSize = 14
ReturnLabel.Parent = MainScroll

local ReturnBtn = Instance.new("TextButton")
setupTouchButton(ReturnBtn)
ReturnBtn.Size = UDim2.new(0.85, 0, 0, 44)
ReturnBtn.Position = UDim2.new(0.075, 0, 0, 270)
ReturnBtn.Text = "Base  ∨"
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
ReturnList.Position = UDim2.new(0.075, 0, 0, 270)
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
        setupTouchButton(b)
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
    connectTap(b, function()
        returnMode = textValue
        ReturnBtn.Text = textValue .. "  ∨"
        ReturnList.Visible = false
    end)
end
addReturnOption("Start Position", 1)
addReturnOption("Base", 2)

connectTap(ReturnBtn, function()
    EggList.Visible = false
    EggPage.Visible = false
    MainScroll.CanvasPosition = Vector2.new(0, 0)
    ReturnLabel.Position = UDim2.new(0.075, 0, 0, 245)
    ReturnBtn.Position = UDim2.new(0.075, 0, 0, 270)
    ReturnList.Position = UDim2.new(0.075, 0, 0, 270)
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
        setupTouchButton(b)
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

        connectTap(b, function()
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

connectTap(SelectEggBtn, function()
    if not EggList.Visible then
        MainScroll.CanvasPosition = Vector2.new(0, 0)
        refreshEggList()
    end

    EggList.Visible = not EggList.Visible
    ReturnList.Visible = false

    -- Move Return To below the open Egg Type list so the two menus never overlap.
    if EggList.Visible then
        ReturnLabel.Position = UDim2.new(0.075, 0, 0, 488)
        ReturnBtn.Position = UDim2.new(0.075, 0, 0, 513)
        ReturnList.Position = UDim2.new(0.075, 0, 0, 513)
    else
        ReturnLabel.Position = UDim2.new(0.075, 0, 0, 245)
        ReturnBtn.Position = UDim2.new(0.075, 0, 0, 270)
        ReturnList.Position = UDim2.new(0.075, 0, 0, 270)
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

    -- Fast path: most Eggs keep the prompt close to the model root.
    for _, x in ipairs(egg:GetChildren()) do
        if x:IsA("ProximityPrompt") and x.Name:lower():find("steal") then
            return x
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

-- ==================== EGG LUCK / HATCH LUCK PRIORITY ====================
-- IMPORTANT:
-- Ride A Pet has TWO different luck concepts:
--   1) Egg Luck = the Luck value printed on each map Egg (30, 50, 1K, 1M, ...)
--   2) Player Hatch Luck = the player's global Hatch Luck upgrade.
-- Player Hatch Luck is the same modifier for all Eggs, so it cannot be used
-- to rank Eggs against each other. Auto Steal therefore ranks by EGG LUCK.
--
-- The game can expose Egg Luck through attributes, ValueObjects, BillboardGui
-- text, or only through the egg's known name. We check all of those paths.

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
        "BaseLuck", "Base_Luck", "HatchLuck", "Hatch_Luck"
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
            or key == "baseluck"
            or key == "hatchluck" then

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

local function findTargetEgg()
    -- Scan BOTH the live RenderedEggs container and Egg models placed in Map.
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

    local candidates = {}
    local seen = {}

    local function addCandidate(egg)
        if seen[egg] then return end
        if not egg or not egg.Parent or not egg:IsA("Model") then return end

        local inRendered = RenderedEggs and egg:IsDescendantOf(RenderedEggs)
        local nameLower = egg.Name:lower()
        local looksLikeEgg = nameLower:find("egg") ~= nil

        local part = getEggPart(egg)
        local prompt = getStealPrompt(egg)
        if not part or not prompt then return end
        if not inRendered and not looksLikeEgg then return end

        local rarity = getEggType(egg)
        if not isEggTypeSelected(rarity) then return end

        local eggLuck = getEggLuck(egg)

        seen[egg] = true
        table.insert(candidates, {
            egg = egg,
            eggLuck = eggLuck,
            rarityPriority = RarityPriority[rarity] or 0,
        })
    end

    if RenderedEggs then
        for _, egg in ipairs(RenderedEggs:GetChildren()) do
            if isValidEgg(egg) then
                addCandidate(egg)
            end
        end
    end

    -- PERFORMANCE:
    -- Do NOT scan every descendant of Workspace.Map and then recursively scan
    -- every object again. Large maps can contain thousands of instances and
    -- this caused Auto Steal to freeze when enabled.
    --
    -- Prefer the common Egg containers first. Only inspect direct children of
    -- those containers; an Egg itself can still be searched recursively for
    -- its prompt/part.
    local map = Workspace:FindFirstChild("Map")
    if map then
        local containers = {}

        local function addContainer(container)
            if container and not table.find(containers, container) then
                table.insert(containers, container)
            end
        end

        -- Common explicit Egg folders.
        for _, name in ipairs({
            "Eggs", "RenderedEggs", "MapEggs", "WorldEggs", "EggSpawns",
            "EggSpawn", "EggsFolder", "EggModels"
        }) do
            addContainer(map:FindFirstChild(name, true))
        end

        -- If there is no explicit Egg folder, inspect only the first-level
        -- map children whose names themselves look Egg-related.
        if #containers == 0 then
            for _, child in ipairs(map:GetChildren()) do
                local n = child.Name:lower()
                if n:find("egg", 1, true)
                    or n:find("spawn", 1, true)
                    or n:find("eggzone", 1, true) then
                    addContainer(child)
                end
            end
        end

        for _, container in ipairs(containers) do
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Model") then
                    addCandidate(child)
                end
            end
        end
    end

    -- HIGHEST EGG LUCK FIRST.
    -- Player Hatch Luck is a global modifier and is NOT used as the ranking
    -- value because it would be identical across all Eggs.
    table.sort(candidates, function(a, b)
        if a.eggLuck ~= b.eggLuck then
            return a.eggLuck > b.eggLuck
        end

        if a.rarityPriority ~= b.rarityPriority then
            return a.rarityPriority > b.rarityPriority
        end

        return a.egg.Name < b.egg.Name
    end)

    local target = candidates[1]
    if target then
        print(string.format(
            "[OLIVER] Auto Steal target: %s | Egg Luck: %s",
            target.egg.Name,
            tostring(target.eggLuck)
        ))
        return target.egg
    end

    return nil
end

local function waitForEggTaken(egg)
    -- HARD CONFIRM GATE: never time out and never pause Auto Steal here.
    -- After Steal is triggered, stay with this Egg until the game actually
    -- removes/reparents it out of RenderedEggs and the state settles.
    -- This prevents returning to Base before the pickup is confirmed.
    while autoSteal do
        local removed = (not egg) or (not egg.Parent) or (not RenderedEggs)
            or (not egg:IsDescendantOf(RenderedEggs))

        if removed then
            task.wait(0.08)

            local stillGone = (not egg) or (not egg.Parent) or (not RenderedEggs)
                or (not egg:IsDescendantOf(RenderedEggs))

            if stillGone then
                return true
            end
        end

        task.wait(0.01)
    end

    return false
end

local function returnAfterSuccess()
    local targetCFrame = nil

    if returnMode == "Base" then
        -- IMPORTANT: use the Base CFrame captured when Auto Steal was enabled.
        -- Do not rescan the workspace after every Egg.
        targetCFrame = capturedReturnBaseCFrame

        if not targetCFrame then
            warn("[OLIVER] Captured Return Base is missing; pausing Auto Steal")
            return false
        end
    else
        targetCFrame = autoStealStartCFrame
    end

    if targetCFrame then
        local ok = teleportCharacter(targetCFrame)
        if ok then
            -- Give the game one frame to settle, then verify the character is near
            -- the captured return point before allowing the next Egg.
            task.wait(0.05)
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - targetCFrame.Position).Magnitude <= 8 then
                return true
            end
        end
    end

    warn("[OLIVER] Return to Base/Start failed; pausing before next Egg")
    return false
end



-- ==================== EGG TIMER / TARGET RESET ====================
-- When an Egg's visible countdown reaches 0, invalidate the cached target
-- immediately. We do not call an unknown server-side "reset" RemoteEvent;
-- instead we reset our target and wait for the game's normal respawn/new-Egg
-- event, which is safer and avoids firing arbitrary remotes.
local cachedEggExpireAt = 0

local function parseEggCountdown(egg)
    if not egg then return nil end

    local best = nil

    local function considerText(txt)
        if not txt then return end
        local t = tostring(txt):lower()

        -- mm:ss / hh:mm:ss
        local h, m, sec = t:match("(%d+):(%d+):(%d+)")
        if h then
            local total = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(sec)
            if total and total >= 0 and (not best or total < best) then best = total end
            return
        end

        m, sec = t:match("(%d+):(%d+)")
        if m then
            local total = tonumber(m) * 60 + tonumber(sec)
            if total and total >= 0 and (not best or total < best) then best = total end
            return
        end

        -- "15s", "15 sec", "15 seconds"
        local seconds = t:match("(%d+%.?%d*)%s*s(?:ec(?:ond)?s?)?")
        if seconds then
            local total = tonumber(seconds)
            if total and total >= 0 and (not best or total < best) then best = total end
        end
    end

    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            considerText(d.Text)
        end
    end

    -- Also support timer attributes / values if the game exposes them.
    for _, key in ipairs({"TimeLeft", "TimeRemaining", "Remaining", "Countdown", "Timer"}) do
        local ok, value = pcall(function() return egg:GetAttribute(key) end)
        if ok and value ~= nil then
            local n = tonumber(value) or parseLuckNumber(value)
            if n and n >= 0 and (not best or n < best) then
                best = n
            end
        end
    end

    return best
end

local function resetExpiredEggTarget()
    cachedTargetEgg = nil
    cachedTargetAt = 0
    cachedEggExpireAt = 0
end


-- ==================== EGG PAGE UI ====================
-- Shows every requested Egg in priority order, its current Egg Luck, and
-- its visible countdown. The list is refreshed periodically while the page
-- is open, so newly spawned Eggs appear without reopening the UI.

local EggPageBtn = Instance.new("TextButton")
setupTouchButton(EggPageBtn)
EggPageBtn.Name = "EggPageBtn"
EggPageBtn.Size = UDim2.new(0.85, 0, 0, 44)
EggPageBtn.Position = UDim2.new(0.075, 0, 0, 315)
EggPageBtn.Text = "Egg Page  >"
EggPageBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
EggPageBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EggPageBtn.Font = Enum.Font.SourceSansBold
EggPageBtn.TextSize = 14
EggPageBtn.Parent = MainScroll

local EggPageCorner = Instance.new("UICorner")
EggPageCorner.CornerRadius = UDim.new(0, 8)
EggPageCorner.Parent = EggPageBtn

-- Separate Egg window: this is NOT a child of MainFrame.
EggMainFrame = Instance.new("Frame")
EggMainFrame.Active = true
EggMainFrame.Name = "EggMainFrame"
EggMainFrame.Size = UDim2.new(0, 220, 0, 280)
EggMainFrame.Position = UDim2.new(0.5, -110, 0.5, 15)
EggMainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
EggMainFrame.BorderSizePixel = 0
EggMainFrame.ClipsDescendants = true
EggMainFrame.Visible = false
EggMainFrame.ZIndex = 500
EggMainFrame.Parent = ScreenGui

local EggMainCorner = Instance.new("UICorner")
EggMainCorner.CornerRadius = UDim.new(0, 12)
EggMainCorner.Parent = EggMainFrame

local EggMainStroke = Instance.new("UIStroke")
EggMainStroke.Color = Color3.fromRGB(0, 200, 255)
EggMainStroke.Thickness = 1.5
EggMainStroke.Parent = EggMainFrame
makeDraggable(EggMainFrame)

local EggPage = Instance.new("Frame")
EggPage.Name = "EggPage"
EggPage.Size = UDim2.new(1, -12, 1, -44)
EggPage.Position = UDim2.new(0, 6, 0, 38)
EggPage.BackgroundTransparency = 1
EggPage.BorderSizePixel = 0
EggPage.Visible = true
EggPage.ZIndex = 500
EggPage.Parent = EggMainFrame

local EggPageCorner2 = Instance.new("UICorner")
EggPageCorner2.CornerRadius = UDim.new(0, 10)
EggPageCorner2.Parent = EggPage

local EggMainTitle = Instance.new("TextLabel")
EggMainTitle.Size = UDim2.new(1, -50, 0, 34)
EggMainTitle.Position = UDim2.new(0, 10, 0, 0)
EggMainTitle.BackgroundTransparency = 1
EggMainTitle.Text = "EGG PAGE"
EggMainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
EggMainTitle.Font = Enum.Font.SourceSansBold
EggMainTitle.TextSize = 18
EggMainTitle.TextXAlignment = Enum.TextXAlignment.Left
EggMainTitle.ZIndex = 501
EggMainTitle.Parent = EggMainFrame

local EggMainClose = Instance.new("TextButton")
setupTouchButton(EggMainClose)
EggMainClose.Size = UDim2.new(0, 44, 0, 44)
EggMainClose.Position = UDim2.new(1, -48, 0, 2)
EggMainClose.Text = "X"
EggMainClose.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
EggMainClose.TextColor3 = Color3.fromRGB(255, 255, 255)
EggMainClose.Font = Enum.Font.SourceSansBold
EggMainClose.TextSize = 14
EggMainClose.ZIndex = 502
EggMainClose.Parent = EggMainFrame

local EggMainCloseCorner = Instance.new("UICorner")
EggMainCloseCorner.CornerRadius = UDim.new(0, 6)
EggMainCloseCorner.Parent = EggMainClose

local EggPageTitle = Instance.new("TextLabel")
EggPageTitle.Size = UDim2.new(1, -50, 0, 38)
EggPageTitle.Position = UDim2.new(0, 12, 0, 0)
EggPageTitle.BackgroundTransparency = 1
EggPageTitle.Text = "🟢 LIVE | Priority"
EggPageTitle.TextColor3 = Color3.fromRGB(0, 230, 255)
EggPageTitle.Font = Enum.Font.SourceSansBold
EggPageTitle.TextSize = 16
EggPageTitle.TextXAlignment = Enum.TextXAlignment.Left
EggPageTitle.ZIndex = 501
EggPageTitle.Parent = EggPage

local EggPageClose = Instance.new("TextButton")
setupTouchButton(EggPageClose)

ScreenGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextButton") then
        setupTouchButton(obj)
    end
end)
EggPageClose.Size = UDim2.new(0, 44, 0, 44)
EggPageClose.Position = UDim2.new(1, -46, 0, 2)
EggPageClose.Text = "X"
EggPageClose.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
EggPageClose.TextColor3 = Color3.fromRGB(255, 255, 255)
EggPageClose.Font = Enum.Font.SourceSansBold
EggPageClose.TextSize = 14
EggPageClose.ZIndex = 501
EggPageClose.Visible = false
EggPageClose.Parent = EggPage

local EggPageCloseCorner = Instance.new("UICorner")
EggPageCloseCorner.CornerRadius = UDim.new(0, 6)
EggPageCloseCorner.Parent = EggPageClose

local EggPageList = Instance.new("ScrollingFrame")
EggPageList.Name = "EggList"
EggPageList.Size = UDim2.new(1, -16, 1, -42)
EggPageList.Position = UDim2.new(0, 8, 0, 38)
EggPageList.BackgroundTransparency = 1
EggPageList.BorderSizePixel = 0
EggPageList.ScrollBarThickness = 5
EggPageList.CanvasSize = UDim2.new(0, 0, 0, 0)
EggPageList.ZIndex = 501
EggPageList.Parent = EggPage

local EggPageLayout = Instance.new("UIListLayout")
EggPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
EggPageLayout.Padding = UDim.new(0, 3)
EggPageLayout.Parent = EggPageList

local RequestedEggNames = {
    "White Egg",
    "Brown Egg",
    "Cracked Egg",
    "Easter Egg",
    "Stone Egg",
    "Leaf Egg",
    "Mushroom Egg",
    "Flower Egg",
    "Slime Egg",
    "Ice Egg",
    "Glass Egg",
    "Golden Egg",
    "Crystal Egg",
    "Skull Egg",
    "Dominus Egg",
    "Flaming Egg",
    "Sinister Egg",
    "Soul Egg",
    "Aurora Egg",
    "Galaxy Egg",
    "Black Hole Egg",
    "Cherub Egg",
}

local function formatEggCountdown(seconds)
    if seconds == nil then return "--:--" end
    seconds = math.max(0, math.floor(seconds + 0.5))

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local sec = seconds % 60

    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, sec)
    end

    return string.format("%02d:%02d", m, sec)
end

local function findLiveEggByName(name)
    local found = nil
    local foundLuck = -1
    local seen = {}

    local function inspectContainer(container)
        if not container then return end

        for _, egg in ipairs(container:GetChildren()) do
            if not seen[egg] then
                seen[egg] = true
                if egg:IsA("Model") and egg.Name:lower() == name:lower() then
                    local luck = getEggLuck(egg)
                    if luck > foundLuck then
                        found = egg
                        foundLuck = luck
                    end
                end
            end
        end
    end

    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
    inspectContainer(RenderedEggs)

    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, containerName in ipairs({
            "Eggs", "RenderedEggs", "MapEggs", "WorldEggs",
            "EggSpawns", "EggSpawn", "EggsFolder", "EggModels"
        }) do
            inspectContainer(map:FindFirstChild(containerName, true))
        end
    end

    return found
end

local function clearEggPageRows()
    for _, child in ipairs(EggPageList:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function refreshEggPage()
    if not EggPage.Visible then return end

    clearEggPageRows()

    -- LIVE Egg types only, in the fixed priority order.
    -- If the same Egg type exists multiple times, combine them into one row
    -- and show the amount, e.g. "🟢 Slime Egg x3 | 00:25".
    local priority = {}
    for index, name in ipairs(RequestedEggNames) do
        priority[name:lower()] = index
    end

    local grouped = {}
    local seen = {}

    local function collect(container)
        if not container then return end

        for _, egg in ipairs(container:GetChildren()) do
            if egg:IsA("Model") and not seen[egg] then
                local key = egg.Name:lower()
                local order = priority[key]

                if order then
                    seen[egg] = true

                    local group = grouped[key]
                    if not group then
                        group = {
                            name = egg.Name,
                            order = order,
                            count = 0,
                            countdowns = {},
                            target = false,
                        }
                        grouped[key] = group
                    end

                    group.count += 1

                    local countdown = parseEggCountdown(egg)
                    if countdown ~= nil then
                        table.insert(group.countdowns, countdown)
                    end

                    if cachedTargetEgg == egg then
                        group.target = true
                    end
                end
            end
        end
    end

    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
    collect(RenderedEggs)

    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, containerName in ipairs({
            "Eggs", "RenderedEggs", "MapEggs", "WorldEggs",
            "EggSpawns", "EggSpawn", "EggsFolder", "EggModels"
        }) do
            collect(map:FindFirstChild(containerName, true))
        end
    end

    local live = {}
    for _, group in pairs(grouped) do
        -- Display the shortest countdown for the type. This makes the UI show
        -- the Egg type that will expire/reset first.
        local nextCountdown = nil
        for _, value in ipairs(group.countdowns) do
            if nextCountdown == nil or value < nextCountdown then
                nextCountdown = value
            end
        end

        group.countdown = nextCountdown
        table.insert(live, group)
    end

    table.sort(live, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.name < b.name
    end)

    for index, row in ipairs(live) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -4, 0, 29)
        label.LayoutOrder = index
        label.BackgroundColor3 = row.target
            and Color3.fromRGB(0, 95, 70)
            or Color3.fromRGB(35, 35, 48)
        label.BorderSizePixel = 0
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = row.target and Enum.Font.SourceSansBold or Enum.Font.SourceSans
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 502

        local countdown = formatEggCountdown(row.countdown)
        local targetMark = row.target and "  ★" or ""

        local baseText = string.format(
            "#%02d  🟢 %s x%d%s",
            index,
            row.name,
            row.count,
            targetMark
        )

        label.Text = baseText .. "  |  " .. countdown

        if row.countdown ~= nil then
            label:SetAttribute("EggPageCountdown", true)
            label:SetAttribute("EggPageBaseText", baseText)
            label:SetAttribute("EggPageExpireAt", os.clock() + row.countdown)
        end

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 6)
        pad.Parent = label

        label.Parent = EggPageList
    end

    if #live == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -4, 0, 32)
        empty.LayoutOrder = 1
        empty.BackgroundTransparency = 1
        empty.Text = "🟡 No Egg LIVE"
        empty.TextColor3 = Color3.fromRGB(200, 200, 210)
        empty.Font = Enum.Font.SourceSans
        empty.TextSize = 14
        empty.ZIndex = 502
        empty.Parent = EggPageList
    end

    EggPageList.CanvasSize = UDim2.new(0, 0, 0, math.max(#live, 1) * 32)
end

-- EGG PAGE: event-driven only.
-- No Map scanning loop. The page updates only when an Egg is added/removed.
local eggPageConnections = {}

local function eggPageSignalUpdate()
    if EggPage.Visible then
        task.defer(function()
            if EggPage.Visible then
                refreshEggPage()
            end
        end)
    end
end

local function watchEggPageContainer(container)
    if not container then return end

    if eggPageConnections[container] then return end

    local connections = {}
    connections.added = container.ChildAdded:Connect(function(child)
        -- New Egg spawned.
        task.defer(function()
            if child and child.Parent then
                eggPageSignalUpdate()
            end
        end)
    end)

    connections.removed = container.ChildRemoved:Connect(function(child)
        -- Egg disappeared/despawned.
        eggPageSignalUpdate()
    end)

    eggPageConnections[container] = connections
end

local function setupEggPageSpawnWatchers()
    -- Only attach listeners to known Egg containers.
    -- We do not enumerate/scan their descendants.
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
    watchEggPageContainer(RenderedEggs)

    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, containerName in ipairs({
            "Eggs", "RenderedEggs", "MapEggs", "WorldEggs",
            "EggSpawns", "EggSpawn", "EggsFolder", "EggModels"
        }) do
            watchEggPageContainer(map:FindFirstChild(containerName, true))
        end
    end
end

setupEggPageSpawnWatchers()

-- If a container itself is created later, attach to it once.
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "RenderedEggs" then
        watchEggPageContainer(child)
        eggPageSignalUpdate()
    elseif child.Name == "Map" then
        task.defer(function()
            setupEggPageSpawnWatchers()
            eggPageSignalUpdate()
        end)
    end
end)


local function openEggMainFrame()
    -- Egg UI is a separate window, but it does NOT hide/close the OLIVER MainFrame.
    EggMainFrame.Visible = true
    EggList.Visible = false
    ReturnList.Visible = false
    EggPage.Visible = true
    refreshEggPage()
end

local function closeEggMainFrame()
    EggMainFrame.Visible = false
end

-- Open the separate Egg UI directly from the OLIVER UI.
connectTap(EggPageBtn, openEggMainFrame)

-- X only closes the Egg UI; OLIVER MainFrame stays open.
connectTap(EggMainClose, closeEggMainFrame)

task.spawn(function()
    while ScreenGui.Parent do
        if EggPage.Visible then
            refreshEggPage()
        end
        task.wait(0.5)
    end
end)

local cachedTargetEgg = nil
local cachedTargetAt = 0
local TARGET_SCAN_INTERVAL = 0.35

-- Wake Auto Steal immediately when a new Egg is inserted into a watched
-- container. The small periodic fallback below is kept only for games that
-- do not fire ChildAdded for their final Egg state.
local eggSpawnEvent = Instance.new("BindableEvent")
local eggSpawnConnections = {}

local function disconnectEggSpawnWatchers()
    for _, connection in ipairs(eggSpawnConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(eggSpawnConnections)
end

local function signalEggSpawn()
    resetExpiredEggTarget()
    pcall(function()
        eggSpawnEvent:Fire()
    end)
end

local function watchEggContainer(container)
    if not container then return end

    local connection = container.ChildAdded:Connect(function(obj)
        if not autoSteal then return end
        if obj:IsA("Model") or obj:IsA("BasePart") then
            -- Give the game one frame to finish attaching the Prompt/Luck UI.
            task.defer(function()
                if autoSteal then
                    signalEggSpawn()
                end
            end)
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

    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, name in ipairs({
            "Eggs", "RenderedEggs", "MapEggs", "WorldEggs",
            "EggSpawns", "EggSpawn", "EggsFolder", "EggModels"
        }) do
            local container = map:FindFirstChild(name, true)
            if container then
                watchEggContainer(container)
            end
        end
    end
end

local function getCachedTargetEgg()
    local now = os.clock()

    if cachedTargetEgg then
        local stillInRendered = RenderedEggs and cachedTargetEgg:IsDescendantOf(RenderedEggs)
        local stillInMap = false
        local map = Workspace:FindFirstChild("Map")
        if map then
            stillInMap = cachedTargetEgg:IsDescendantOf(map)
        end

        if not cachedTargetEgg.Parent or (not stillInRendered and not stillInMap) then
            resetExpiredEggTarget()
        elseif cachedEggExpireAt > 0 and now >= cachedEggExpireAt then
            -- Countdown finished: reset our Egg target and immediately look for
            -- the next/new Egg. The game's own respawn system remains untouched.
            resetExpiredEggTarget()
        elseif (now - cachedTargetAt) < TARGET_SCAN_INTERVAL then
            return cachedTargetEgg
        end
    end

    local egg = findTargetEgg()
    cachedTargetEgg = egg
    cachedTargetAt = now

    if egg then
        local countdown = parseEggCountdown(egg)
        if countdown and countdown > 0 then
            cachedEggExpireAt = now + countdown
        else
            cachedEggExpireAt = 0
        end
    else
        cachedEggExpireAt = 0
    end

    return egg
end

local function stealOneEgg(egg)
    if stealBusy or not autoSteal or not egg or not egg.Parent then return end
    stealBusy = true

    local success = false
    local eggPart = getEggPart(egg)
    local prompt = getStealPrompt(egg)

    if eggPart and prompt then
        -- Hover just a little above the Egg, close enough for the prompt.
        -- Keep the character locked to the Egg so tree/high-place Eggs cannot
        -- make the character fall while the pickup is being confirmed.
        teleportCharacter(eggPart.CFrame, 0.75)
        local releaseEggLock = lockToEgg(eggPart, 0.75)
        task.wait(0.005)

        -- Hold 0.0s. Roblox documents HoldDuration=0 as immediate activation.
        pcall(function()
            prompt.HoldDuration = 0
        end)

        local function activateStealPrompt()
            local fired = false

            -- Prefer the executor prompt trigger when available.
            if fireproximityprompt then
                fired = pcall(function()
                    fireproximityprompt(prompt, 0, true)
                end)
            end

            -- Also use the normal ProximityPrompt input path when available.
            -- Some games do not react to the executor helper consistently.
            if not fired then
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(0.02)
                    prompt:InputHoldEnd()
                end)
            end
        end

        -- Keep trying the SAME Egg until the server/game actually accepts the pickup.
        -- There is intentionally no short retry deadline: we never switch to another
        -- Egg and never return to Base just because a few seconds elapsed.
        while autoSteal do
            local removed = (not egg) or (not egg.Parent) or (not RenderedEggs)
                or (not egg:IsDescendantOf(RenderedEggs))

            if removed then
                -- Give replication a tiny moment, then require the Egg to remain gone.
                task.wait(0.06)
                local stillGone = (not egg) or (not egg.Parent) or (not RenderedEggs)
                    or (not egg:IsDescendantOf(RenderedEggs))
                if stillGone then
                    success = true
                    break
                end
            end

            -- Prompt did not take yet: try again on the SAME Egg.
            activateStealPrompt()
            task.wait(0.08)
        end
        releaseEggLock()

        -- IMPORTANT: A triggered prompt is NOT proof that the Egg was taken.
        -- Only continue when the Egg actually leaves/reparents out of RenderedEggs.
        -- Do not use a time-based fallback here, otherwise the script can return
        -- to Base before the Egg is actually ours.
        if success then
            -- Never start the next Egg until Return has completed.
            local returned = returnAfterSuccess()
            if returned then
                task.wait(1)
            else
                -- Do not start another Egg. Keep Auto Steal ON and retry the
                -- captured Return Base until the character is actually back.
                warn("[OLIVER] Return failed; waiting until Return Base succeeds")
                while autoSteal and not returnAfterSuccess() do
                    task.wait(0.1)
                end
                if autoSteal then
                    task.wait(1)
                end
            end
        else
            -- Auto Steal was turned OFF while waiting for confirmation.
            -- Do not return to Base or start another Egg.
            warn("[OLIVER] Auto Steal turned off before Egg pickup was confirmed")
        end
    end

    stealBusy = false
end

connectTap(AutoStealBtn, function()
    autoSteal = not autoSteal

    if autoSteal then
        -- Save the exact place the player was standing when Auto Steal was turned ON.
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        autoStealStartCFrame = root and root.CFrame or nil

        AutoStealBtn.Text = "Auto Steal | ON"
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)

        -- Capture the Base ONCE when Auto Steal starts. This is the same Base
        -- discovery used by the old script, but we keep the CFrame for every return.
        local baseCFrame = getRanchCFrame()
        capturedReturnBaseCFrame = baseCFrame

        if baseCFrame then
            print("[OLIVER] Captured Return Base CFrame")
        else
            warn("[OLIVER] Could not capture Return Base; Auto Steal paused")
            autoSteal = false
            AutoStealBtn.Text = "Auto Steal | PAUSED"
            AutoStealBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
            return
        end

        -- Prevent manual character movement while the automation is running.
        setMovementLocked(true)

        setupEggSpawnWatchers()

        task.spawn(function()
            while autoSteal do
                local egg = getCachedTargetEgg()

                if egg then
                    stealOneEgg(egg)
                else
                    -- No Egg right now: sleep until a new Egg spawns instead
                    -- of continuously scanning the whole map.
                    local fired = false
                    local connection
                    connection = eggSpawnEvent.Event:Connect(function()
                        fired = true
                    end)

                    local deadline = os.clock() + 0.75
                    while autoSteal and not fired and os.clock() < deadline do
                        task.wait(0.05)
                    end

                    if connection then
                        connection:Disconnect()
                    end

                    -- Small fallback rescan for games that don't emit the
                    -- expected ChildAdded event.
                    if autoSteal and not fired then
                        cachedTargetAt = 0
                    end
                end
            end
        end)
    else
        AutoStealBtn.Text = "Auto Steal | OFF"
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        setMovementLocked(false)
        disconnectEggSpawnWatchers()
        resetExpiredEggTarget()
        autoStealStartCFrame = nil
        capturedReturnBaseCFrame = nil
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

connectTap(EspEggBtn, function()
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
