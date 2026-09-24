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
MainFrame.Size = UDim2.new(0, 300, 0, 330)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
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

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- 5. ESP EGG Button
local EspEggBtn = Instance.new("TextButton")
EspEggBtn.Size = UDim2.new(0.85, 0, 0, 42)
EspEggBtn.Position = UDim2.new(0.075, 0, 0.20, 0)
EspEggBtn.Text = "ESP EGG | OFF"
EspEggBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
EspEggBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EspEggBtn.Font = Enum.Font.SourceSansBold
EspEggBtn.TextSize = 15
EspEggBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = EspEggBtn


-- ==================== AUTO STEAL ====================
local autoSteal = false
local selectedEgg = "All" -- rarity/type selector
local holdTime = 0.0
local stealBusy = false
local autoStealStartCFrame = nil
local returnMode = "Start Position" -- "Start Position" or "Base"

local AutoStealBtn = Instance.new("TextButton")
AutoStealBtn.Size = UDim2.new(0.85, 0, 0, 38)
AutoStealBtn.Position = UDim2.new(0.075, 0, 0.38, 0)
AutoStealBtn.Text = "Auto Steal | OFF"
AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
AutoStealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoStealBtn.Font = Enum.Font.SourceSansBold
AutoStealBtn.TextSize = 15
AutoStealBtn.Parent = MainFrame

local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 8)
AutoCorner.Parent = AutoStealBtn

local SelectLabel = Instance.new("TextLabel")
SelectLabel.Size = UDim2.new(0.85, 0, 0, 24)
SelectLabel.Position = UDim2.new(0.075, 0, 0.54, 0)
SelectLabel.Text = "Select Egg Type"
SelectLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Font = Enum.Font.SourceSansBold
SelectLabel.TextSize = 14
SelectLabel.Parent = MainFrame

local SelectEggBtn = Instance.new("TextButton")
SelectEggBtn.Size = UDim2.new(0.85, 0, 0, 34)
SelectEggBtn.Position = UDim2.new(0.075, 0, 0.64, 0)
SelectEggBtn.Text = "All  ∨"
SelectEggBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SelectEggBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectEggBtn.Font = Enum.Font.SourceSans
SelectEggBtn.TextSize = 14
SelectEggBtn.Parent = MainFrame

local SelectCorner = Instance.new("UICorner")
SelectCorner.CornerRadius = UDim.new(0, 8)
SelectCorner.Parent = SelectEggBtn

local ReturnLabel = Instance.new("TextLabel")
ReturnLabel.Size = UDim2.new(0.85, 0, 0, 22)
ReturnLabel.Position = UDim2.new(0.075, 0, 0.755, 0)
ReturnLabel.Text = "Return To"
ReturnLabel.TextXAlignment = Enum.TextXAlignment.Left
ReturnLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
ReturnLabel.BackgroundTransparency = 1
ReturnLabel.Font = Enum.Font.SourceSansBold
ReturnLabel.TextSize = 14
ReturnLabel.Parent = MainFrame

local ReturnBtn = Instance.new("TextButton")
ReturnBtn.Size = UDim2.new(0.85, 0, 0, 34)
ReturnBtn.Position = UDim2.new(0.075, 0, 0.82, 0)
ReturnBtn.Text = "Start Position  ∨"
ReturnBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ReturnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ReturnBtn.Font = Enum.Font.SourceSans
ReturnBtn.TextSize = 14
ReturnBtn.Parent = MainFrame

local ReturnCorner = Instance.new("UICorner")
ReturnCorner.CornerRadius = UDim.new(0, 8)
ReturnCorner.Parent = ReturnBtn

local ReturnList = Instance.new("Frame")
ReturnList.Size = UDim2.new(0.85, 0, 0, 68)
ReturnList.Position = UDim2.new(0.075, 0, 0.82, 0)
ReturnList.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ReturnList.BorderSizePixel = 0
ReturnList.Visible = false
ReturnList.ZIndex = 20
ReturnList.Parent = MainFrame

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
    b.ZIndex = 21
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
    ReturnList.Visible = not ReturnList.Visible
end)

local EggList = Instance.new("ScrollingFrame")
EggList.Size = UDim2.new(0.85, 0, 0, 105)
EggList.Position = UDim2.new(0.075, 0, 0.69, 0)
EggList.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
EggList.BorderSizePixel = 0
EggList.Visible = false
EggList.ZIndex = 15
EggList.ScrollBarThickness = 4
EggList.CanvasSize = UDim2.new(0, 0, 0, 0)
EggList.Parent = MainFrame

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
    ["Aurora Egg"] = "Divine",
    ["Galaxy Egg"] = "Divine",
    ["Black Hole Egg"] = "Ethereal",
    ["Cherub Egg"] = "Ethereal"
}

local EggTypes = {"All", "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal"}

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
        b.Text = eggType
        b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.SourceSans
        b.TextSize = 13
        b.Parent = EggList

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = b

        b.MouseButton1Click:Connect(function()
            selectedEgg = eggType
            SelectEggBtn.Text = eggType .. "  ∨"
            EggList.Visible = false
        end)
    end

    EggList.CanvasSize = UDim2.new(0, 0, 0, #EggTypes * 30)
end

SelectEggBtn.MouseButton1Click:Connect(function()
    if not EggList.Visible then
        refreshEggList()
    end
    EggList.Visible = not EggList.Visible
    if EggList.Visible then ReturnList.Visible = false end
end)

-- Finds the player's ranch using common Ride A Pet naming patterns.
local function getRanchCFrame()
    local roots = {
        Workspace:FindFirstChild("Ranches"),
        Workspace:FindFirstChild("Plots"),
        Workspace:FindFirstChild("PlayerPlots"),
        Workspace:FindFirstChild("RanchPlots")
    }

    local function findIn(root)
        if not root then return nil end

        local candidates = {
            LocalPlayer.Name,
            LocalPlayer.DisplayName,
            "Your Ranch",
            "Ranch"
        }

        for _, n in ipairs(candidates) do
            local x = root:FindFirstChild(n)
            if x then
                local part = x:IsA("BasePart") and x or x:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.CFrame end
            end
        end

        for _, x in ipairs(root:GetChildren()) do
            local text = x.Name:lower()
            if text:find(LocalPlayer.Name:lower(), 1, true) or text == "your ranch" then
                local part = x:IsA("BasePart") and x or x:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.CFrame end
            end
        end
        return nil
    end

    for _, root in ipairs(roots) do
        local cf = findIn(root)
        if cf then return cf end
    end

    -- Fallback: search descendants for an object named after the player.
    for _, x in ipairs(Workspace:GetDescendants()) do
        local n = x.Name:lower()
        if n == LocalPlayer.Name:lower() or n == "your ranch" then
            local part = x:IsA("BasePart") and x or x:FindFirstChildWhichIsA("BasePart", true)
            if part then return part.CFrame end
        end
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

local function teleportCharacter(cf)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and cf then
        root.CFrame = cf + Vector3.new(0, 3, 0)
        return true
    end
    return false
end

local function findTargetEgg()
    RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
    if not RenderedEggs then return nil end

    for _, egg in ipairs(RenderedEggs:GetChildren()) do
        if isValidEgg(egg) and (selectedEgg == "All" or getEggType(egg) == selectedEgg) then
            if getEggPart(egg) and getStealPrompt(egg) then
                return egg
            end
        end
    end

    return nil
end

local function stealOneEgg(egg)
    if stealBusy or not autoSteal or not egg or not egg.Parent then return end
    stealBusy = true

    local eggPart = getEggPart(egg)
    local prompt = getStealPrompt(egg)
    if eggPart and prompt then
        teleportCharacter(eggPart.CFrame)
        task.wait(0.05)

        -- Hold 0.0s: trigger the ProximityPrompt immediately.
        pcall(function()
            prompt.HoldDuration = holdTime
        end)

        if fireproximityprompt then
            pcall(function()
                fireproximityprompt(prompt, 1, true)
            end)
        else
            pcall(function()
                prompt:InputHoldBegin()
                prompt:InputHoldEnd()
            end)
        end

        task.wait(0.15)

        -- Return to either the saved start position or the player's Base.
        if returnMode == "Base" then
            local baseCFrame = getRanchCFrame()
            if baseCFrame then
                teleportCharacter(baseCFrame)
            elseif autoStealStartCFrame then
                teleportCharacter(autoStealStartCFrame)
            end
        elseif autoStealStartCFrame then
            teleportCharacter(autoStealStartCFrame)
        end
    end

    task.wait(0.25)
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
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)

        task.spawn(function()
            while autoSteal do
                local egg = findTargetEgg()
                if egg then
                    stealOneEgg(egg)
                else
                    task.wait(0.25)
                end
            end
        end)
    else
        AutoStealBtn.Text = "Auto Steal | OFF"
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        autoStealStartCFrame = nil
    end
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
