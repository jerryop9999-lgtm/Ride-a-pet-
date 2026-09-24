local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

-- 1. ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OliverHubUI"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- 2. Button បិទ/បើក Main Frame
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleMenuBtn"
ToggleBtn.Size = UDim2.new(0, 80, 0, 35)
ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
ToggleBtn.Text = "OLIVER"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

-- 3. Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 140)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -70)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Header Label (OLIVER)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Text = "OLIVER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = MainFrame

-- មុខងារ ចុចប៊ូតុងដើម្បី បិទ/បើក Main Frame
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- 4. ESP EGG Button
local EspEggBtn = Instance.new("TextButton")
EspEggBtn.Size = UDim2.new(0.85, 0, 0, 40)
EspEggBtn.Position = UDim2.new(0.075, 0, 0.45, 0)
EspEggBtn.Text = "ESP EGG | OFF"
EspEggBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
EspEggBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EspEggBtn.Font = Enum.Font.SourceSansBold
EspEggBtn.TextSize = 14
EspEggBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = EspEggBtn

-- ESP Logic សម្រាប់បង្ហាញ Highlight និង ឈ្មោះប្រភេទ Egg
local isEspEgg = false
local espObjects = {}

local function removeESP()
    for _, item in pairs(espObjects) do
        if item and item.Parent then 
            item:Destroy() 
        end
    end
    espObjects = {}
end

local function applyESP()
    removeESP()
    if not isEspEgg then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and string.find(obj.Name:lower(), "egg") then
            -- ១. បង្កើត Highlight (ពន្លឺជុំវិញ Egg)
            local highlight = Instance.new("Highlight")
            highlight.Name = "EggESPHighlight"
            highlight.Adornee = obj
            highlight.FillColor = Color3.fromRGB(255, 215, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = obj
            table.insert(espObjects, highlight)

            -- ២. បង្កើត BillboardGui សម្រាប់បង្ហាញឈ្មោះប្រភេទ Egg នៅពីលើ
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "EggESPName"
            billboard.Adornee = obj
            billboard.Size = UDim2.new(0, 160, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0) -- កម្ពស់ឈ្មោះនៅពីលើ Egg
            billboard.AlwaysOnTop = true
            billboard.Parent = obj

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.Text = "🥚 " .. obj.Name
            textLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.TextStrokeTransparency = 0
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextSize = 15
            textLabel.BackgroundTransparency = 1
            textLabel.Parent = billboard

            table.insert(espObjects, billboard)
        end
    end
end

EspEggBtn.MouseButton1Click:Connect(function()
    isEspEgg = not isEspEgg
    if isEspEgg then
        EspEggBtn.Text = "ESP EGG | ON"
        EspEggBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        applyESP()
    else
        EspEggBtn.Text = "ESP EGG | OFF"
        EspEggBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        removeESP()
    end
end)
