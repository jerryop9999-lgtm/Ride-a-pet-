--[[
    OLIVER - New Mobile UI
    Built as a new standalone script.
    Core behavior:
      • One-finger mobile buttons
      • External OLIVER open/close button
      • Draggable main window
      • Auto Steal = one Egg, then return and OFF
      • Loop = Egg -> Steal -> Return -> 1s -> next Egg
      • Egg rarity filter
      • Return To: Base / Start Position
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local RenderedEggs = Workspace:FindFirstChild("RenderedEggs")

-- ==================== MOBILE INPUT ====================

local function setupTouchButton(button)
    if not button then return end
    button.Active = true
    button.Selectable = true
    button.AutoButtonColor = true
end

local function connectTap(button, callback)
    if not button then return end
    setupTouchButton(button)

    local touchInput
    local mouseDown = false

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchInput = input
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            mouseDown = true
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if touchInput == input then
                touchInput = nil
                callback()
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            if mouseDown then
                mouseDown = false
                callback()
            end
        end
    end)
end

local function makeDraggable(frame, handle)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    frame.Active = true
    handle = handle or frame
    handle.Active = true

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        -- Never steal a button tap.
        local objects = GuiService:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
        for _, obj in ipairs(objects) do
            if obj:IsA("GuiButton") then
                return
            end
        end

        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
            end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then return end

        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)
end

-- ==================== GUI ====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OLIVER_New"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = 999999

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then
            return hui
        end
    end

    if LocalPlayer then
        local ok, playerGui = pcall(function()
            return LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
        if ok and playerGui then
            return playerGui
        end
    end

    return CoreGui
end

local _oliverParentOK = pcall(function()
    ScreenGui.Parent = getGuiParent()
end)

if not _oliverParentOK then
    warn("[OLIVER] GUI parent failed")
end

ScreenGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("GuiButton") then
        setupTouchButton(obj)
    end
end)

-- Floating external button.
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "OLIVER"
ToggleBtn.Size = UDim2.new(0, 84, 0, 36)
ToggleBtn.Position = UDim2.new(0, 12, 0.42, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
ToggleBtn.Text = "OLIVER"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 14
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = ScreenGui
setupTouchButton(ToggleBtn)

local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(0, 9)
tc.Parent = ToggleBtn

local ts = Instance.new("UIStroke")
ts.Color = Color3.fromRGB(0, 190, 255)
ts.Thickness = 1
ts.Parent = ToggleBtn

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 235, 0, 305)
MainFrame.Position = UDim2.new(0.5, -117, 0.5, -152)
MainFrame.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 13)
mc.Parent = MainFrame

local ms = Instance.new("UIStroke")
ms.Color = Color3.fromRGB(0, 190, 255)
ms.Thickness = 1.3
ms.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 43)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "OLIVER"
Title.TextColor3 = Color3.fromRGB(245, 250, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 19
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0, 90, 0, 24)
Status.Position = UDim2.new(1, -100, 0, 9)
Status.BackgroundTransparency = 1
Status.Text = "IDLE"
Status.TextColor3 = Color3.fromRGB(150, 155, 165)
Status.Font = Enum.Font.SourceSansBold
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Right
Status.Parent = Header

local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Name = "MainScroll"
MainScroll.Size = UDim2.new(1, -12, 1, -49)
MainScroll.Position = UDim2.new(0, 6, 0, 45)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.ScrollBarThickness = 4
MainScroll.ScrollingDirection = Enum.ScrollingDirection.Y
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 570)
MainScroll.Parent = MainFrame

makeDraggable(MainFrame, Header)

connectTap(ToggleBtn, function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ==================== STATE ====================

local autoSteal = false
local loopSteal = false
local selectedEggs = { All = true }
local holdTime = 0.0
local stealBusy = false
local autoStealStartCFrame = nil
local capturedReturnBaseCFrame = nil
local returnMode = "Base"

local movementLock = {
    controls = nil,
    walkSpeed = nil,
    jumpPower = nil,
    jumpHeight = nil,
    autoRotate = nil,
}

-- Hidden compatibility page used only as a state target by the filter menu.
local EggPage = Instance.new("Frame")
EggPage.Visible = false
EggPage.Parent = MainScroll


-- ==================== NEW CONTROL UI ====================

local function newButton(name, textValue, y, height)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -18, 0, height or 42)
    b.Position = UDim2.new(0, 9, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(38, 41, 53)
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.Text = textValue
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 15
    b.BorderSizePixel = 0
    b.Parent = MainScroll
    setupTouchButton(b)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9)
    c.Parent = b
    return b
end

local AutoStealBtn = newButton("AutoSteal", "Auto Steal | OFF", 8, 46)
local LoopBtn = newButton("Loop", "Loop | OFF", 61, 46)

local SelectLabel = Instance.new("TextLabel")
SelectLabel.Size = UDim2.new(1, -18, 0, 19)
SelectLabel.Position = UDim2.new(0, 9, 0, 113)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Text = "Egg Type"
SelectLabel.TextColor3 = Color3.fromRGB(190, 195, 205)
SelectLabel.Font = Enum.Font.SourceSansBold
SelectLabel.TextSize = 13
SelectLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectLabel.Parent = MainScroll

local SelectEggBtn = newButton("EggType", "All  ∨", 135, 40)
SelectEggBtn.Font = Enum.Font.SourceSans

local EggList
EggList = Instance.new("ScrollingFrame")
EggList.Name = "EggList"
EggList.Size = UDim2.new(1, -18, 0, 205)
EggList.Position = UDim2.new(0, 9, 0, 179)
EggList.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
EggList.BorderSizePixel = 0
EggList.Visible = false
EggList.ZIndex = 20
EggList.ScrollBarThickness = 5
EggList.ClipsDescendants = true
EggList.CanvasSize = UDim2.new(0, 0, 0, 0)
EggList.Parent = MainScroll

local ell = Instance.new("UIListLayout")
ell.SortOrder = Enum.SortOrder.LayoutOrder
ell.Padding = UDim.new(0, 2)
ell.Parent = EggList

local ReturnLabel = Instance.new("TextLabel")
ReturnLabel.Size = UDim2.new(1, -18, 0, 19)
ReturnLabel.Position = UDim2.new(0, 9, 0, 185)
ReturnLabel.BackgroundTransparency = 1
ReturnLabel.Text = "Return To"
ReturnLabel.TextColor3 = Color3.fromRGB(190, 195, 205)
ReturnLabel.Font = Enum.Font.SourceSansBold
ReturnLabel.TextSize = 13
ReturnLabel.TextXAlignment = Enum.TextXAlignment.Left
ReturnLabel.Parent = MainScroll

local ReturnBtn = newButton("ReturnTo", "Base  ∨", 207, 40)
ReturnBtn.Font = Enum.Font.SourceSans

local ReturnList = Instance.new("Frame")
ReturnList.Name = "ReturnList"
ReturnList.Size = UDim2.new(1, -18, 0, 66)
ReturnList.Position = UDim2.new(0, 9, 0, 249)
ReturnList.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
ReturnList.BorderSizePixel = 0
ReturnList.Visible = false
ReturnList.ZIndex = 30
ReturnList.Parent = MainScroll

local rll = Instance.new("UIListLayout")
rll.SortOrder = Enum.SortOrder.LayoutOrder
rll.Parent = ReturnList

local function addReturnOption(textValue, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 31)
    b.LayoutOrder = order
    b.Text = textValue
    b.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 13
    b.ZIndex = 31
    b.Parent = ReturnList
    setupTouchButton(b)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
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
    ReturnList.Visible = not ReturnList.Visible
end)

MainScroll.CanvasSize = UDim2.new(0, 0, 0, 305)

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
        ReturnLabel.Position = UDim2.new(0.075, 0, 0, 538)
        ReturnBtn.Position = UDim2.new(0.075, 0, 0, 563)
        ReturnList.Position = UDim2.new(0.075, 0, 0, 563)
    else
        ReturnLabel.Position = UDim2.new(0.075, 0, 0, 295)
        ReturnBtn.Position = UDim2.new(0.075, 0, 0, 320)
        ReturnList.Position = UDim2.new(0.075, 0, 0, 320)
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
            -- Always return after a successful pickup.
            local returned = returnAfterSuccess()
            if returned then
                task.wait(1)
            else
                -- Keep retrying the captured Return Base until the character is back.
                warn("[OLIVER] Return failed; waiting until Return Base succeeds")
                while autoSteal and not returnAfterSuccess() do
                    task.wait(0.1)
                end
                if autoSteal then
                    task.wait(1)
                end
            end

            -- Auto Steal = take ONE Egg, return, then switch itself OFF.
            -- Loop = keep Auto Steal running for the next Egg.
            if success and autoSteal and not loopSteal then
                autoSteal = false
                AutoStealBtn.Text = "Auto Steal | OFF"
                AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                setMovementLocked(false)
                disconnectEggSpawnWatchers()
                resetExpiredEggTarget()
                autoStealStartCFrame = nil
                capturedReturnBaseCFrame = nil
            end
        else
            -- Auto Steal was turned OFF while waiting for confirmation.
            -- Do not return to Base or start another Egg.
            warn("[OLIVER] Auto Steal turned off before Egg pickup was confirmed")
        end
    end

    stealBusy = false
end

local toggleAutoSteal

connectTap(LoopBtn, function()
    loopSteal = not loopSteal

    if loopSteal then
        LoopBtn.Text = "Loop | ON"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)

        -- Loop is the phone-friendly continuous mode. It automatically starts
        -- Auto Steal so the same egg->return->next egg cycle keeps running.
        if not autoSteal then
            toggleAutoSteal()
        end
    else
        LoopBtn.Text = "Loop | OFF"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)

        -- Turning Loop off stops the continuous cycle.
        if autoSteal then
            autoSteal = false
            AutoStealBtn.Text = "Auto Steal | OFF"
            AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            setMovementLocked(false)
            disconnectEggSpawnWatchers()
            resetExpiredEggTarget()
            autoStealStartCFrame = nil
            capturedReturnBaseCFrame = nil
        end
    end
end)

toggleAutoSteal = function()
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
        loopSteal = false
        LoopBtn.Text = "Loop | OFF"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        AutoStealBtn.Text = "Auto Steal | OFF"
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        setMovementLocked(false)
        disconnectEggSpawnWatchers()
        resetExpiredEggTarget()
        autoStealStartCFrame = nil
        capturedReturnBaseCFrame = nil
    end
end

connectTap(AutoStealBtn, toggleAutoSteal)


-- ==================== STATUS / STARTUP ====================

local function updateStatus()
    if loopSteal then
        Status.Text = "LOOP"
        Status.TextColor3 = Color3.fromRGB(0, 220, 130)
    elseif autoSteal then
        Status.Text = "STEAL"
        Status.TextColor3 = Color3.fromRGB(0, 210, 255)
    else
        Status.Text = "IDLE"
        Status.TextColor3 = Color3.fromRGB(150, 155, 165)
    end
end

-- Keep the visible status synchronized with the automation state.
task.spawn(function()
    while ScreenGui.Parent do
        updateStatus()
        task.wait(0.15)
    end
end)

updateEggTypeButtonText()
updateStatus()

print("[OLIVER] New standalone mobile UI loaded.")
