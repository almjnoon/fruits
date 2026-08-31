-- ╔════════════════════════════════════════════════════════════════════════════╗
-- ║                     NEXUS // FRUIT BATTLEGROUNDS                           ║
-- ║           Modern Cyberpunk Dashboard & Tabbed Exploit Suite v5.5           ║
-- ║         Engineered for High-Efficiency Mastery Leveling & Security         ║
-- ║                 Keybinds: [P] Toggle Farm  |  [M] Minimize                 ║
-- ╚════════════════════════════════════════════════════════════════════════════╝

-- ═════════════════════════ [ CORE CONFIGURATION ] ═════════════════════════
local CONFIG = {
    AttackDelay       = 0.10,                               -- Delay between move executions (seconds)
    ToggleKey         = Enum.KeyCode.P,                      -- Global hotkey to toggle Auto Farm
    MinimizeKey       = Enum.KeyCode.M,                      -- Global hotkey to collapse UI
    AutoSafeZone      = true,                               -- Auto-teleport & anchor inside safe cube
    SafeSpotLocation  = Vector3.new(5000, 5000, 5000),      -- Sky coordinates for isolated sanctuary
    BoxSize           = 60,                                 -- Safety cube dimensions (60x60 studs)
    BoxHeight         = 24,                                 -- Safety cube height
    FallbackFruit     = "Chop",                             -- Fallback fruit name if detection fails

    -- Known World Place IDs in Fruit Battlegrounds Universe
    Worlds = {
        {name = "WORLD 1: DRESSROSA",    placeId = 9224601490,  tag = "W1", desc = "Starter Sea & Colosseum"},
        {name = "WORLD 2: WANO",         placeId = 11424731404, tag = "W2", desc = "Onigashima & Samurai Realm"},
        {name = "WORLD 3: WHOLE CAKE",   placeId = 16190471004, tag = "W3", desc = "New World & Big Mom Realm"},
        {name = "AFK WORLD // REWARD",   placeId = 11445923563, tag = "AFK", desc = "Passive EXP & Gem Chamber"},
    }
}

-- Skill matrix state: Slots 1 through 9 (Independent Toggles)
local SkillToggles = {
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [8] = true,
    [9] = true,
}
-- ══════════════════════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Loader      = require(game.ReplicatedStorage.Loader)

-- Runtime States
local AutoFarmEnabled  = false
local SafePlatform     = nil
local StartExp         = nil
local StartTime        = os.time()
local SafeTargetCFrame = CFrame.new(CONFIG.SafeSpotLocation + Vector3.new(0, 5, 0))

-- ══════════════════════════════════════════════════════════════════════════
-- ║                 🛡️ SANCTUARY PROTOCOL (SKY CUBE LOCK)                 ║
-- ══════════════════════════════════════════════════════════════════════════

local function CreateSafePlatform()
    local existing = Workspace:FindFirstChild("Nexus_SanctuaryCube")
    if existing then 
        SafePlatform = existing
        return existing 
    end

    local model = Instance.new("Model")
    model.Name = "Nexus_SanctuaryCube"

    local size   = CONFIG.BoxSize
    local height = CONFIG.BoxHeight
    local center = CONFIG.SafeSpotLocation
    local wallThick = 10

    local function makeBoxPart(name, pSize, pPos)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = pSize
        p.Position = pPos
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 0.35
        p.Material = Enum.Material.ForceField
        p.Color = Color3.fromRGB(0, 200, 255)
        p.Parent = model
        return p
    end

    -- Heavy Reinforced Floor & Roof
    local floor = makeBoxPart("Floor", Vector3.new(size + 20, wallThick, size + 20), center - Vector3.new(0, wallThick/2, 0))
    makeBoxPart("Roof", Vector3.new(size + 20, wallThick, size + 20), center + Vector3.new(0, height + wallThick/2, 0))

    -- 4 Sealed Perimeter Walls
    makeBoxPart("WallNorth", Vector3.new(size + 20, height, wallThick), center + Vector3.new(0, height/2, size/2 + wallThick/2))
    makeBoxPart("WallSouth", Vector3.new(size + 20, height, wallThick), center + Vector3.new(0, height/2, -size/2 - wallThick/2))
    makeBoxPart("WallEast",  Vector3.new(wallThick, height, size + 20), center + Vector3.new(size/2 + wallThick/2, height/2, 0))
    makeBoxPart("WallWest",  Vector3.new(wallThick, height, size + 20), center + Vector3.new(-size/2 - wallThick/2, height/2, 0))

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(0, 220, 255)
    light.Range = 60
    light.Brightness = 3
    light.Parent = floor

    model.Parent = Workspace
    SafePlatform = model
    return model
end

local function TeleportToSanctuary()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    CreateSafePlatform()
    hrp.CFrame = SafeTargetCFrame
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- ─── Continuous Multi-Frame Position Lock ───
task.spawn(function()
    while true do
        if AutoFarmEnabled and CONFIG.AutoSafeZone then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                hrp.CFrame = SafeTargetCFrame
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
        RunService.RenderStepped:Wait()
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if AutoFarmEnabled and CONFIG.AutoSafeZone then
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            task.wait(0.2)
            TeleportToSanctuary()
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════
-- ║                 🌍 WORLD & DIMENSION TELEPORTATION                     ║
-- ══════════════════════════════════════════════════════════════════════════

local function TravelToPlace(placeId, worldLabel)
    print(string.format("[Nexus] Teleporting to %s (Place ID: %s)...", worldLabel, tostring(placeId)))
    pcall(function()
        TeleportService:Teleport(placeId, LocalPlayer)
    end)
end

local function RejoinCurrentServer()
    print("[Nexus] Reconnecting to same place...")
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

local function ServerHop()
    print("[Nexus] Server-Hopping to a fresh instance...")
    pcall(function()
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", tostring(game.PlaceId))
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════
-- ║                 🍇 FRUIT SWAPPER & INVENTORY LOGIC                     ║
-- ══════════════════════════════════════════════════════════════════════════

local function GetCurrentSlot()
    local data = LocalPlayer:FindFirstChild("MAIN_DATA")
    if data and data:FindFirstChild("Slot") then
        return data.Slot.Value
    end
    return 1
end

local function GetCurrentFruit()
    local data = LocalPlayer:FindFirstChild("MAIN_DATA")
    if data then
        local slotVal = data:FindFirstChild("Slot")
        local slotNum = slotVal and tostring(slotVal.Value) or "1"
        local slots = data:FindFirstChild("Slots")
        if slots and slots:FindFirstChild(slotNum) then
            local f = slots[slotNum].Value
            if f and f ~= "None" and f ~= "" then return f end
        end
    end
    return CONFIG.FallbackFruit
end

local function GetOwnedFruitSlots()
    local data = LocalPlayer:FindFirstChild("MAIN_DATA")
    local slotsList = {}
    if data and data:FindFirstChild("Slots") then
        for _, s in ipairs(data.Slots:GetChildren()) do
            local sNum = tonumber(s.Name) or 1
            local fName = s.Value
            if fName and fName ~= "None" and fName ~= "" then
                local fData = data:FindFirstChild("Fruits") and data.Fruits:FindFirstChild(fName)
                local lvl = fData and fData:FindFirstChild("Level") and fData.Level.Value or 1
                local exp = fData and fData:FindFirstChild("EXP") and fData.EXP.Value or 0
                table.insert(slotsList, {
                    slot = sNum,
                    fruit = fName,
                    level = lvl,
                    exp = exp
                })
            end
        end
    end
    table.sort(slotsList, function(a, b) return a.slot < b.slot end)
    return slotsList
end

local function SwitchFruitSlot(slotNumber)
    print(string.format("[Nexus] Switching active fruit to Slot %d...", slotNumber))
    pcall(function()
        Loader.Server("FruitsHandler", "SwitchSlot", {Slot = tonumber(slotNumber)})
    end)
end

local function GetFruitStats()
    local fruitName = GetCurrentFruit()
    local data = LocalPlayer:FindFirstChild("MAIN_DATA")
    if not data then return fruitName, 1, 0 end

    local fruits = data:FindFirstChild("Fruits")
    if not fruits then return fruitName, 1, 0 end

    local fruit = fruits:FindFirstChild(fruitName)
    if not fruit then return fruitName, 1, 0 end

    local lvl = (fruit:FindFirstChild("Level") and fruit.Level.Value) or 1
    local exp = (fruit:FindFirstChild("EXP") and fruit.EXP.Value) or 0
    return fruitName, lvl, exp
end

-- Retrieves map of all 9 skill slots with metadata
local function GetSkillInventory()
    local char = LocalPlayer.Character
    local bp   = LocalPlayer:FindFirstChild("Backpack")
    local matrix = {}

    for i = 1, 9 do
        matrix[i] = {
            slot    = i,
            name    = "Skill " .. i,
            tool    = nil,
            level   = 1,
            locked  = true,
        }
    end

    local function scanTool(tool)
        if tool:IsA("Tool") then
            local keyVal = tonumber(tool:GetAttribute("Key"))
            if keyVal and keyVal >= 1 and keyVal <= 9 then
                matrix[keyVal].name   = tool.Name
                matrix[keyVal].tool   = tool
                matrix[keyVal].level  = tool:GetAttribute("Level") or 1
                matrix[keyVal].locked = tool:GetAttribute("Locked") == true
            end
        end
    end

    if char then for _, t in ipairs(char:GetChildren()) do scanTool(t) end end
    if bp   then for _, t in ipairs(bp:GetChildren())   do scanTool(t) end end

    return matrix
end

-- ══════════════════════════════════════════════════════════════════════════
-- ║               💎 NEXUS MODERN TABBED DASHBOARD UI                    ║
-- ══════════════════════════════════════════════════════════════════════════

local function BuildInterface()
    local old = LocalPlayer.PlayerGui:FindFirstChild("Nexus_FruitBattlegrounds")
    if old then old:Destroy() end

    local SG = Instance.new("ScreenGui")
    SG.Name            = "Nexus_FruitBattlegrounds"
    SG.ResetOnSpawn    = false
    SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    SG.IgnoreGuiInset  = true
    SG.Parent          = LocalPlayer.PlayerGui

    -- Helper to disable auto-translate on all text objects
    local function PreventAutoTranslate(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            obj.AutoLocalize = false
        end
        obj.DescendantAdded:Connect(function(child)
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                child.AutoLocalize = false
            end
        end)
    end
    PreventAutoTranslate(SG)

    -- ─── Main Hub Frame (Modern Widescreen Dashboard) ───────
    local Hub = Instance.new("Frame")
    Hub.Name              = "NexusHub"
    Hub.Size              = UDim2.new(0, 520, 0, 360)
    Hub.Position          = UDim2.new(0.5, -260, 0.45, -180)
    Hub.BackgroundColor3  = Color3.fromRGB(11, 13, 20)
    Hub.BackgroundTransparency = 0.03
    Hub.BorderSizePixel   = 0
    Hub.ClipsDescendants  = true
    Hub.Active            = true
    Hub.Parent            = SG

    Instance.new("UICorner", Hub).CornerRadius = UDim.new(0, 14)

    local HubStroke = Instance.new("UIStroke")
    HubStroke.Color     = Color3.fromRGB(0, 210, 255)
    HubStroke.Thickness = 1.8
    HubStroke.Parent    = Hub

    task.spawn(function()
        local palette = {
            Color3.fromRGB(0, 210, 255),
            Color3.fromRGB(150, 60, 255),
            Color3.fromRGB(0, 255, 180),
        }
        local i = 1
        while Hub and Hub.Parent do
            local col = palette[i % #palette + 1]
            TweenService:Create(HubStroke, TweenInfo.new(2, Enum.EasingStyle.Sine), {Color = col}):Play()
            i = i + 1
            task.wait(2)
        end
    end)

    -- ─── Draggable Logic ───────────────────────────
    local dragging, dragInput, dragStart, startPos
    Hub.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Hub.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Hub.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Hub.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- ─── Top Bar ───────────────────────────────────
    local TopBar = Instance.new("Frame")
    TopBar.Name             = "TopBar"
    TopBar.Size             = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
    TopBar.BorderSizePixel  = 0
    TopBar.Parent           = Hub
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)

    local TopGrad = Instance.new("UIGradient")
    TopGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 55, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 20, 150)),
    })
    TopGrad.Rotation = 90
    TopGrad.Parent = TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name              = "Title"
    TitleLabel.Size              = UDim2.new(0, 220, 1, 0)
    TitleLabel.Position          = UDim2.new(0, 14, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text              = "⚡ NEXUS // SUITE"
    TitleLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextScaled        = true
    TitleLabel.Font              = Enum.Font.GothamBlack
    TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    TitleLabel.AutoLocalize      = false
    TitleLabel.Parent            = TopBar

    local VerBadge = Instance.new("TextLabel")
    VerBadge.Size                = UDim2.new(0, 48, 0, 18)
    VerBadge.Position            = UDim2.new(0, 155, 0.5, -9)
    VerBadge.BackgroundColor3    = Color3.fromRGB(0, 180, 240)
    VerBadge.Text                = "v5.5 PRO"
    VerBadge.TextColor3          = Color3.fromRGB(255, 255, 255)
    VerBadge.TextScaled          = true
    VerBadge.Font                = Enum.Font.GothamBold
    VerBadge.AutoLocalize        = false
    VerBadge.Parent              = TopBar
    Instance.new("UICorner", VerBadge).CornerRadius = UDim.new(0, 4)

    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Name               = "MinBtn"
    MinBtn.Size               = UDim2.new(0, 26, 0, 26)
    MinBtn.Position           = UDim2.new(1, -36, 0.5, -13)
    MinBtn.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
    MinBtn.BackgroundTransparency = 0.88
    MinBtn.Text               = "—"
    MinBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
    MinBtn.TextScaled         = true
    MinBtn.Font               = Enum.Font.GothamBold
    MinBtn.AutoLocalize       = false
    MinBtn.Parent             = TopBar
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    -- ─── Main Content Wrapper ──────────────────────
    local ContentWrapper = Instance.new("Frame")
    ContentWrapper.Name               = "ContentWrapper"
    ContentWrapper.Size               = UDim2.new(1, 0, 1, -42)
    ContentWrapper.Position           = UDim2.new(0, 0, 0, 42)
    ContentWrapper.BackgroundTransparency = 1
    ContentWrapper.Parent             = Hub

    -- ─── Left Sidebar Tabs ─────────────────────────
    local Sidebar = Instance.new("Frame")
    Sidebar.Name              = "Sidebar"
    Sidebar.Size              = UDim2.new(0, 125, 1, -10)
    Sidebar.Position          = UDim2.new(0, 8, 0, 6)
    Sidebar.BackgroundColor3  = Color3.fromRGB(15, 18, 28)
    Sidebar.BorderSizePixel   = 0
    Sidebar.Parent            = ContentWrapper
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

    local SideStroke = Instance.new("UIStroke", Sidebar)
    SideStroke.Color = Color3.fromRGB(30, 36, 52)
    SideStroke.Thickness = 1

    local SideLayout = Instance.new("UIListLayout")
    SideLayout.Padding        = UDim.new(0, 5)
    SideLayout.FillDirection  = Enum.FillDirection.Vertical
    SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SideLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    SideLayout.Parent         = Sidebar

    local SidePadding = Instance.new("UIPadding", Sidebar)
    SidePadding.PaddingTop    = UDim.new(0, 8)
    SidePadding.PaddingBottom = UDim.new(0, 8)
    SidePadding.PaddingLeft   = UDim.new(0, 6)
    SidePadding.PaddingRight  = UDim.new(0, 6)

    -- ─── Right Tab Pages Container ─────────────────
    local PagesContainer = Instance.new("Frame")
    PagesContainer.Name               = "PagesContainer"
    PagesContainer.Size               = UDim2.new(1, -145, 1, -10)
    PagesContainer.Position           = UDim2.new(0, 138, 0, 6)
    PagesContainer.BackgroundColor3   = Color3.fromRGB(14, 17, 26)
    PagesContainer.BorderSizePixel    = 0
    PagesContainer.Parent             = ContentWrapper
    Instance.new("UICorner", PagesContainer).CornerRadius = UDim.new(0, 10)

    local PageStroke = Instance.new("UIStroke", PagesContainer)
    PageStroke.Color = Color3.fromRGB(30, 36, 52)
    PageStroke.Thickness = 1

    -- Tab System
    local Tabs = {}
    local TabPages = {}
    local CurrentTab = "FARM"

    local function SwitchTab(tabName)
        CurrentTab = tabName
        for name, page in pairs(TabPages) do
            page.Visible = (name == tabName)
        end
        for name, tabData in pairs(Tabs) do
            local active = (name == tabName)
            tabData.btn.BackgroundColor3 = active and Color3.fromRGB(22, 38, 65) or Color3.fromRGB(18, 22, 34)
            tabData.stroke.Color         = active and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(32, 38, 56)
            tabData.label.TextColor3     = active and Color3.fromRGB(0, 220, 255) or Color3.fromRGB(160, 170, 195)
        end
    end

    local function CreateTabButton(order, name, icon)
        local btn = Instance.new("TextButton")
        btn.Name                  = "Tab_" .. name
        btn.Size                  = UDim2.new(1, 0, 0, 36)
        btn.LayoutOrder           = order
        btn.BackgroundColor3      = (name == "FARM") and Color3.fromRGB(22, 38, 65) or Color3.fromRGB(18, 22, 34)
        btn.BorderSizePixel       = 0
        btn.Text                  = ""
        btn.AutoButtonColor       = false
        btn.Parent                = Sidebar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", btn)
        stroke.Color     = (name == "FARM") and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(32, 38, 56)
        stroke.Thickness = 1

        local lbl = Instance.new("TextLabel")
        lbl.Size                  = UDim2.new(1, -8, 1, 0)
        lbl.Position              = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency= 1
        lbl.Text                  = icon .. "  " .. name
        lbl.TextColor3            = (name == "FARM") and Color3.fromRGB(0, 220, 255) or Color3.fromRGB(160, 170, 195)
        lbl.TextScaled            = true
        lbl.Font                  = Enum.Font.GothamBold
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.AutoLocalize          = false
        lbl.Parent                = btn

        btn.MouseButton1Click:Connect(function()
            SwitchTab(name)
        end)

        Tabs[name] = {btn = btn, stroke = stroke, label = lbl}

        -- Page Frame
        local page = Instance.new("ScrollingFrame")
        page.Name                 = "Page_" .. name
        page.Size                 = UDim2.new(1, -12, 1, -12)
        page.Position             = UDim2.new(0, 6, 0, 6)
        page.BackgroundTransparency = 1
        page.BorderSizePixel      = 0
        page.ScrollBarThickness   = 3
        page.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
        page.Visible              = (name == "FARM")
        page.CanvasSize           = UDim2.new(0, 0, 0, 0)
        page.Parent               = PagesContainer

        TabPages[name] = page
        return page
    end

    -- Create Navigation Tabs
    local FarmPage   = CreateTabButton(1, "FARM",   "⚡")
    local FruitsPage = CreateTabButton(2, "FRUITS", "🍇")
    local WorldsPage = CreateTabButton(3, "WORLDS", "🌍")
    local StatsPage  = CreateTabButton(4, "STATS",  "📊")

    -- ══════════════════════════════════════════════
    -- ║              TAB 1: FARM PAGE              ║
    -- ══════════════════════════════════════════════
    FarmPage.CanvasSize = UDim2.new(0, 0, 0, 290)

    -- 1. Master Switch Row
    local MasterRow = Instance.new("Frame")
    MasterRow.Size              = UDim2.new(1, 0, 0, 42)
    MasterRow.Position          = UDim2.new(0, 0, 0, 0)
    MasterRow.BackgroundColor3  = Color3.fromRGB(18, 22, 34)
    MasterRow.BorderSizePixel   = 0
    MasterRow.Parent            = FarmPage
    Instance.new("UICorner", MasterRow).CornerRadius = UDim.new(0, 8)
    local mStroke = Instance.new("UIStroke", MasterRow); mStroke.Color = Color3.fromRGB(35, 45, 70)

    local MasterTitle = Instance.new("TextLabel")
    MasterTitle.Size            = UDim2.new(1, -70, 1, 0)
    MasterTitle.Position        = UDim2.new(0, 10, 0, 0)
    MasterTitle.BackgroundTransparency = 1
    MasterTitle.Text            = "⚡ MASTER AUTOFARM [P]"
    MasterTitle.TextColor3      = Color3.fromRGB(240, 245, 255)
    MasterTitle.TextScaled      = true
    MasterTitle.Font            = Enum.Font.GothamBlack
    MasterTitle.TextXAlignment  = Enum.TextXAlignment.Left
    MasterTitle.AutoLocalize    = false
    MasterTitle.Parent          = MasterRow

    local SwitchBtn = Instance.new("TextButton")
    SwitchBtn.Name              = "SwitchBtn"
    SwitchBtn.Size              = UDim2.new(0, 52, 0, 24)
    SwitchBtn.Position          = UDim2.new(1, -60, 0.5, -12)
    SwitchBtn.BackgroundColor3  = Color3.fromRGB(45, 50, 70)
    SwitchBtn.BorderSizePixel   = 0
    SwitchBtn.Text              = ""
    SwitchBtn.AutoButtonColor   = false
    SwitchBtn.Parent            = MasterRow
    Instance.new("UICorner", SwitchBtn).CornerRadius = UDim.new(1, 0)

    local SwitchCircle = Instance.new("Frame")
    SwitchCircle.Name           = "Circle"
    SwitchCircle.Size           = UDim2.new(0, 18, 0, 18)
    SwitchCircle.Position       = UDim2.new(0, 3, 0.5, -9)
    SwitchCircle.BackgroundColor3 = Color3.fromRGB(160, 170, 190)
    SwitchCircle.BorderSizePixel= 0
    SwitchCircle.Parent         = SwitchBtn
    Instance.new("UICorner", SwitchCircle).CornerRadius = UDim.new(1, 0)

    -- 2. Sanctuary Action Button
    local SanctuaryBtn = Instance.new("TextButton")
    SanctuaryBtn.Name             = "SanctuaryBtn"
    SanctuaryBtn.Size             = UDim2.new(1, 0, 0, 32)
    SanctuaryBtn.Position         = UDim2.new(0, 0, 0, 48)
    SanctuaryBtn.BackgroundColor3 = Color3.fromRGB(16, 26, 42)
    SanctuaryBtn.BorderSizePixel  = 0
    SanctuaryBtn.Text             = "🛡️ ANCHOR INSIDE SAFE SKY CUBE"
    SanctuaryBtn.TextColor3       = Color3.fromRGB(0, 220, 255)
    SanctuaryBtn.TextScaled       = true
    SanctuaryBtn.Font             = Enum.Font.GothamBold
    SanctuaryBtn.AutoLocalize     = false
    SanctuaryBtn.Parent           = FarmPage
    Instance.new("UICorner", SanctuaryBtn).CornerRadius = UDim.new(0, 8)
    local sStroke = Instance.new("UIStroke", SanctuaryBtn); sStroke.Color = Color3.fromRGB(0, 150, 220)

    -- 3. Skill Matrix Header
    local MatrixHeader = Instance.new("Frame")
    MatrixHeader.Size             = UDim2.new(1, 0, 0, 22)
    MatrixHeader.Position         = UDim2.new(0, 0, 0, 86)
    MatrixHeader.BackgroundTransparency = 1
    MatrixHeader.Parent           = FarmPage

    local MatrixLabel = Instance.new("TextLabel")
    MatrixLabel.Size              = UDim2.new(0.55, 0, 1, 0)
    MatrixLabel.BackgroundTransparency = 1
    MatrixLabel.Text              = "SKILL MATRIX // SLOTS 1 - 9"
    MatrixLabel.TextColor3        = Color3.fromRGB(180, 190, 215)
    MatrixLabel.TextScaled        = true
    MatrixLabel.Font              = Enum.Font.GothamBold
    MatrixLabel.TextXAlignment    = Enum.TextXAlignment.Left
    MatrixLabel.AutoLocalize      = false
    MatrixLabel.Parent            = MatrixHeader

    local AllOnBtn = Instance.new("TextButton")
    AllOnBtn.Size                 = UDim2.new(0, 56, 0, 18)
    AllOnBtn.Position             = UDim2.new(1, -118, 0, 2)
    AllOnBtn.BackgroundColor3     = Color3.fromRGB(10, 60, 40)
    AllOnBtn.Text                 = "ALL ON"
    AllOnBtn.TextColor3           = Color3.fromRGB(0, 255, 150)
    AllOnBtn.TextScaled           = true
    AllOnBtn.Font                 = Enum.Font.GothamBold
    AllOnBtn.AutoLocalize         = false
    AllOnBtn.Parent               = MatrixHeader
    Instance.new("UICorner", AllOnBtn).CornerRadius = UDim.new(0, 4)

    local AllOffBtn = Instance.new("TextButton")
    AllOffBtn.Size                = UDim2.new(0, 56, 0, 18)
    AllOffBtn.Position            = UDim2.new(1, -58, 0, 2)
    AllOffBtn.BackgroundColor3    = Color3.fromRGB(50, 20, 25)
    AllOffBtn.Text                = "ALL OFF"
    AllOffBtn.TextColor3          = Color3.fromRGB(255, 90, 100)
    AllOffBtn.TextScaled          = true
    AllOffBtn.Font                = Enum.Font.GothamBold
    AllOffBtn.AutoLocalize        = false
    AllOffBtn.Parent              = MatrixHeader
    Instance.new("UICorner", AllOffBtn).CornerRadius = UDim.new(0, 4)

    -- 3x3 Grid for Skill Toggles
    local GridFrame = Instance.new("Frame")
    GridFrame.Name                = "GridFrame"
    GridFrame.Size                = UDim2.new(1, 0, 0, 126)
    GridFrame.Position            = UDim2.new(0, 0, 0, 112)
    GridFrame.BackgroundTransparency = 1
    GridFrame.Parent              = FarmPage

    local GridLayout = Instance.new("UIGridLayout")
    GridLayout.CellSize           = UDim2.new(0, 113, 0, 36)
    GridLayout.CellPadding        = UDim2.new(0, 6, 0, 6)
    GridLayout.SortOrder          = Enum.SortOrder.LayoutOrder
    GridLayout.Parent             = GridFrame

    local SkillButtons = {}

    for i = 1, 9 do
        local btn = Instance.new("TextButton")
        btn.Name                  = "SkillBtn_" .. i
        btn.LayoutOrder           = i
        btn.BackgroundColor3      = SkillToggles[i] and Color3.fromRGB(15, 50, 45) or Color3.fromRGB(22, 25, 36)
        btn.BorderSizePixel       = 0
        btn.Text                  = ""
        btn.AutoButtonColor       = false
        btn.Parent                = GridFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color           = SkillToggles[i] and Color3.fromRGB(0, 220, 150) or Color3.fromRGB(38, 44, 60)
        btnStroke.Thickness       = 1
        btnStroke.Parent          = btn

        local badge = Instance.new("TextLabel")
        badge.Name                = "Badge"
        badge.Size                = UDim2.new(0, 22, 0, 13)
        badge.Position            = UDim2.new(0, 4, 0, 3)
        badge.BackgroundColor3    = Color3.fromRGB(0, 160, 220)
        badge.Text                = string.format("[%02d]", i)
        badge.TextColor3          = Color3.fromRGB(255, 255, 255)
        badge.TextScaled          = true
        badge.Font                = Enum.Font.GothamBlack
        badge.AutoLocalize        = false
        badge.Parent              = btn
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)

        local stateLbl = Instance.new("TextLabel")
        stateLbl.Name             = "State"
        stateLbl.Size             = UDim2.new(0, 20, 0, 13)
        stateLbl.Position         = UDim2.new(1, -22, 0, 3)
        stateLbl.BackgroundTransparency = 1
        stateLbl.Text             = SkillToggles[i] and "ON" or "OFF"
        stateLbl.TextColor3       = SkillToggles[i] and Color3.fromRGB(0, 255, 160) or Color3.fromRGB(140, 150, 170)
        stateLbl.TextScaled       = true
        stateLbl.Font             = Enum.Font.GothamBold
        stateLbl.AutoLocalize     = false
        stateLbl.Parent           = btn

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name              = "SkillName"
        nameLbl.Size              = UDim2.new(1, -8, 0, 15)
        nameLbl.Position          = UDim2.new(0, 4, 0, 17)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text              = "Skill " .. i
        nameLbl.TextColor3        = Color3.fromRGB(230, 235, 245)
        nameLbl.TextScaled        = true
        nameLbl.Font              = Enum.Font.Gotham
        nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
        nameLbl.AutoLocalize      = false
        nameLbl.Parent            = btn

        btn.MouseButton1Click:Connect(function()
            SkillToggles[i] = not SkillToggles[i]
            local active = SkillToggles[i]
            btn.BackgroundColor3 = active and Color3.fromRGB(15, 50, 45) or Color3.fromRGB(22, 25, 36)
            btnStroke.Color      = active and Color3.fromRGB(0, 220, 150) or Color3.fromRGB(38, 44, 60)
            stateLbl.Text        = active and "ON" or "OFF"
            stateLbl.TextColor3  = active and Color3.fromRGB(0, 255, 160) or Color3.fromRGB(140, 150, 170)
        end)

        SkillButtons[i] = {btn = btn, stroke = btnStroke, state = stateLbl, name = nameLbl}
    end

    AllOnBtn.MouseButton1Click:Connect(function()
        for i = 1, 9 do
            SkillToggles[i] = true
            local item = SkillButtons[i]
            if item then
                item.btn.BackgroundColor3 = Color3.fromRGB(15, 50, 45)
                item.stroke.Color         = Color3.fromRGB(0, 220, 150)
                item.state.Text           = "ON"
                item.state.TextColor3     = Color3.fromRGB(0, 255, 160)
            end
        end
    end)

    AllOffBtn.MouseButton1Click:Connect(function()
        for i = 1, 9 do
            SkillToggles[i] = false
            local item = SkillButtons[i]
            if item then
                item.btn.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
                item.stroke.Color         = Color3.fromRGB(38, 44, 60)
                item.state.Text           = "OFF"
                item.state.TextColor3     = Color3.fromRGB(140, 150, 170)
            end
        end
    end)

    -- ══════════════════════════════════════════════
    -- ║             TAB 2: FRUITS PAGE             ║
    -- ══════════════════════════════════════════════
    FruitsPage.CanvasSize = UDim2.new(0, 0, 0, 220)

    local FruitTitle = Instance.new("TextLabel")
    FruitTitle.Size               = UDim2.new(1, 0, 0, 22)
    FruitTitle.BackgroundTransparency = 1
    FruitTitle.Text               = "🍇 OWNED FRUITS // INSTANT SWAPPER"
    FruitTitle.TextColor3         = Color3.fromRGB(180, 190, 215)
    FruitTitle.TextScaled         = true
    FruitTitle.Font               = Enum.Font.GothamBold
    FruitTitle.TextXAlignment     = Enum.TextXAlignment.Left
    FruitTitle.AutoLocalize       = false
    FruitTitle.Parent             = FruitsPage

    local FruitGrid = Instance.new("Frame")
    FruitGrid.Name                = "FruitGrid"
    FruitGrid.Size                = UDim2.new(1, 0, 0, 180)
    FruitGrid.Position            = UDim2.new(0, 0, 0, 28)
    FruitGrid.BackgroundTransparency = 1
    FruitGrid.Parent              = FruitsPage

    local FruitLayout = Instance.new("UIGridLayout")
    FruitLayout.CellSize          = UDim2.new(0, 172, 0, 36)
    FruitLayout.CellPadding       = UDim2.new(0, 8, 0, 6)
    FruitLayout.SortOrder         = Enum.SortOrder.LayoutOrder
    FruitLayout.Parent            = FruitGrid

    local function RenderFruitSlots()
        for _, c in ipairs(FruitGrid:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        local ownedSlots = GetOwnedFruitSlots()
        local activeSlot = GetCurrentSlot()

        for idx, sData in ipairs(ownedSlots) do
            local isCurrent = (sData.slot == activeSlot)

            local fBtn = Instance.new("TextButton")
            fBtn.Name                = "SlotBtn_" .. sData.slot
            fBtn.LayoutOrder         = idx
            fBtn.BackgroundColor3    = isCurrent and Color3.fromRGB(15, 60, 45) or Color3.fromRGB(20, 25, 38)
            fBtn.BorderSizePixel     = 0
            fBtn.Text                = ""
            fBtn.AutoButtonColor     = true
            fBtn.Parent              = FruitGrid
            Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 8)

            local fStroke = Instance.new("UIStroke", fBtn)
            fStroke.Color = isCurrent and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(40, 50, 75)
            fStroke.Thickness = 1

            local badge = Instance.new("TextLabel")
            badge.Size               = UDim2.new(0, 24, 0, 18)
            badge.Position           = UDim2.new(0, 6, 0.5, -9)
            badge.BackgroundColor3   = isCurrent and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(160, 50, 220)
            badge.Text               = tostring(sData.slot)
            badge.TextColor3         = Color3.fromRGB(255, 255, 255)
            badge.TextScaled         = true
            badge.Font               = Enum.Font.GothamBlack
            badge.AutoLocalize       = false
            badge.Parent             = fBtn
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size             = UDim2.new(1, -36, 1, 0)
            nameLbl.Position         = UDim2.new(0, 34, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text             = isCurrent and (sData.fruit .. " ★") or sData.fruit
            nameLbl.TextColor3       = isCurrent and Color3.fromRGB(0, 255, 180) or Color3.fromRGB(230, 235, 245)
            nameLbl.TextScaled       = true
            nameLbl.Font             = Enum.Font.GothamBold
            nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
            nameLbl.AutoLocalize     = false
            nameLbl.Parent           = fBtn

            fBtn.MouseButton1Click:Connect(function()
                if sData.slot == GetCurrentSlot() then
                    nameLbl.Text = "EQUIPPED ALREADY"
                    task.delay(1, function()
                        if nameLbl then nameLbl.Text = sData.fruit .. " ★" end
                    end)
                else
                    nameLbl.Text = "EQUIPPING..."
                    SwitchFruitSlot(sData.slot)
                    task.wait(0.3)
                    RenderFruitSlots()
                end
            end)
        end
    end

    RenderFruitSlots()

    -- ══════════════════════════════════════════════
    -- ║             TAB 3: WORLDS PAGE             ║
    -- ══════════════════════════════════════════════
    WorldsPage.CanvasSize = UDim2.new(0, 0, 0, 220)

    local WorldTitle = Instance.new("TextLabel")
    WorldTitle.Size               = UDim2.new(1, 0, 0, 22)
    WorldTitle.BackgroundTransparency = 1
    WorldTitle.Text               = "🌍 DIMENSION TELEPORTATION"
    WorldTitle.TextColor3         = Color3.fromRGB(180, 190, 215)
    WorldTitle.TextScaled         = true
    WorldTitle.Font               = Enum.Font.GothamBold
    WorldTitle.TextXAlignment     = Enum.TextXAlignment.Left
    WorldTitle.AutoLocalize       = false
    WorldTitle.Parent             = WorldsPage

    local WorldGrid = Instance.new("Frame")
    WorldGrid.Name                = "WorldGrid"
    WorldGrid.Size                = UDim2.new(1, 0, 0, 84)
    WorldGrid.Position            = UDim2.new(0, 0, 0, 28)
    WorldGrid.BackgroundTransparency = 1
    WorldGrid.Parent              = WorldsPage

    local WorldLayout = Instance.new("UIGridLayout")
    WorldLayout.CellSize          = UDim2.new(0, 172, 0, 36)
    WorldLayout.CellPadding       = UDim2.new(0, 8, 0, 6)
    WorldLayout.SortOrder         = Enum.SortOrder.LayoutOrder
    WorldLayout.Parent            = WorldGrid

    for idx, wData in ipairs(CONFIG.Worlds) do
        local isCurrentWorld = (game.PlaceId == wData.placeId)

        local wBtn = Instance.new("TextButton")
        wBtn.Name                = "WorldBtn_" .. idx
        wBtn.LayoutOrder         = idx
        wBtn.BackgroundColor3    = isCurrentWorld and Color3.fromRGB(15, 60, 45) or Color3.fromRGB(20, 25, 38)
        wBtn.BorderSizePixel     = 0
        wBtn.Text                = ""
        wBtn.AutoButtonColor     = true
        wBtn.Parent              = WorldGrid
        Instance.new("UICorner", wBtn).CornerRadius = UDim.new(0, 8)

        local wStroke = Instance.new("UIStroke", wBtn)
        wStroke.Color = isCurrentWorld and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(40, 50, 75)
        wStroke.Thickness = 1

        local tagLbl = Instance.new("TextLabel")
        tagLbl.Size              = UDim2.new(0, 32, 0, 18)
        tagLbl.Position          = UDim2.new(0, 6, 0.5, -9)
        tagLbl.BackgroundColor3  = isCurrentWorld and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(0, 160, 220)
        tagLbl.Text              = wData.tag
        tagLbl.TextColor3        = Color3.fromRGB(255, 255, 255)
        tagLbl.TextScaled        = true
        tagLbl.Font              = Enum.Font.GothamBlack
        tagLbl.AutoLocalize      = false
        tagLbl.Parent            = wBtn
        Instance.new("UICorner", tagLbl).CornerRadius = UDim.new(0, 4)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size             = UDim2.new(1, -44, 1, 0)
        nameLbl.Position         = UDim2.new(0, 42, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text             = isCurrentWorld and (wData.name .. " ★") or wData.name
        nameLbl.TextColor3       = isCurrentWorld and Color3.fromRGB(0, 255, 180) or Color3.fromRGB(230, 235, 245)
        nameLbl.TextScaled       = true
        nameLbl.Font             = Enum.Font.GothamBold
        nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
        nameLbl.AutoLocalize     = false
        nameLbl.Parent           = wBtn

        wBtn.MouseButton1Click:Connect(function()
            if isCurrentWorld then
                nameLbl.Text = "ALREADY HERE!"
                task.delay(1, function()
                    if nameLbl then nameLbl.Text = wData.name .. " ★" end
                end)
            else
                nameLbl.Text = "TELEPORTING..."
                TravelToPlace(wData.placeId, wData.name)
            end
        end)
    end

    local RejoinHopRow = Instance.new("Frame")
    RejoinHopRow.Size            = UDim2.new(1, 0, 0, 32)
    RejoinHopRow.Position        = UDim2.new(0, 0, 0, 124)
    RejoinHopRow.BackgroundTransparency = 1
    RejoinHopRow.Parent          = WorldsPage

    local RejoinBtn = Instance.new("TextButton")
    RejoinBtn.Size               = UDim2.new(0.48, 0, 1, 0)
    RejoinBtn.Position           = UDim2.new(0, 0, 0, 0)
    RejoinBtn.BackgroundColor3   = Color3.fromRGB(22, 28, 42)
    RejoinBtn.Text               = "🔄 REJOIN SERVER"
    RejoinBtn.TextColor3         = Color3.fromRGB(100, 210, 255)
    RejoinBtn.TextScaled         = true
    RejoinBtn.Font               = Enum.Font.GothamBold
    RejoinBtn.AutoLocalize       = false
    RejoinBtn.Parent             = RejoinHopRow
    Instance.new("UICorner", RejoinBtn).CornerRadius = UDim.new(0, 8)
    local rjStroke = Instance.new("UIStroke", RejoinBtn); rjStroke.Color = Color3.fromRGB(45, 60, 90)

    local HopBtn = Instance.new("TextButton")
    HopBtn.Size                  = UDim2.new(0.48, 0, 1, 0)
    HopBtn.Position              = UDim2.new(0.52, 0, 0, 0)
    HopBtn.BackgroundColor3      = Color3.fromRGB(22, 28, 42)
    HopBtn.Text                  = "🌐 SERVER HOP"
    HopBtn.TextColor3            = Color3.fromRGB(180, 140, 255)
    HopBtn.TextScaled            = true
    HopBtn.Font                  = Enum.Font.GothamBold
    HopBtn.AutoLocalize          = false
    HopBtn.Parent                = RejoinHopRow
    Instance.new("UICorner", HopBtn).CornerRadius = UDim.new(0, 8)
    local hopStroke = Instance.new("UIStroke", HopBtn); hopStroke.Color = Color3.fromRGB(60, 45, 95)

    RejoinBtn.MouseButton1Click:Connect(RejoinCurrentServer)
    HopBtn.MouseButton1Click:Connect(ServerHop)

    -- ══════════════════════════════════════════════
    -- ║             TAB 4: STATS PAGE              ║
    -- ══════════════════════════════════════════════
    StatsPage.CanvasSize = UDim2.new(0, 0, 0, 230)

    local function MakeTelemetryCard(yPos, icon, labelStr, defaultVal, valColor)
        local Card = Instance.new("Frame")
        Card.Size              = UDim2.new(1, 0, 0, 30)
        Card.Position          = UDim2.new(0, 0, 0, yPos)
        Card.BackgroundColor3  = Color3.fromRGB(18, 22, 34)
        Card.BorderSizePixel   = 0
        Card.Parent            = StatsPage
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

        local IconLbl = Instance.new("TextLabel")
        IconLbl.Size              = UDim2.new(0, 26, 1, 0)
        IconLbl.BackgroundTransparency = 1
        IconLbl.Text              = icon
        IconLbl.TextScaled        = true
        IconLbl.Font              = Enum.Font.GothamBold
        IconLbl.AutoLocalize      = false
        IconLbl.Parent            = Card

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size              = UDim2.new(0.42, 0, 1, 0)
        NameLbl.Position          = UDim2.new(0, 30, 0, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text              = labelStr
        NameLbl.TextColor3        = Color3.fromRGB(140, 150, 175)
        NameLbl.TextScaled        = true
        NameLbl.Font              = Enum.Font.Gotham
        NameLbl.TextXAlignment    = Enum.TextXAlignment.Left
        NameLbl.AutoLocalize      = false
        NameLbl.Parent            = Card

        local ValLbl = Instance.new("TextLabel")
        ValLbl.Name               = "Value"
        ValLbl.Size               = UDim2.new(0.58, -15, 1, 0)
        ValLbl.Position           = UDim2.new(0.42, 10, 0, 0)
        ValLbl.BackgroundTransparency = 1
        ValLbl.Text               = defaultVal
        ValLbl.TextColor3         = valColor
        ValLbl.TextScaled         = true
        ValLbl.Font               = Enum.Font.GothamBold
        ValLbl.TextXAlignment     = Enum.TextXAlignment.Right
        ValLbl.AutoLocalize       = false
        ValLbl.Parent             = Card

        return ValLbl
    end

    local FruitVal   = MakeTelemetryCard(0,   "🍎", "EQUIPPED FRUIT:",   "DETECTING...",        Color3.fromRGB(255, 110, 150))
    local LevelVal   = MakeTelemetryCard(36,  "🏆", "MASTERY & EXP:",     "LVL: 1 | EXP: 0",     Color3.fromRGB(255, 215, 60))
    local AttackVal  = MakeTelemetryCard(72,  "⚔️", "FIRING SEQUENCE:",   "STANDBY",             Color3.fromRGB(255, 140, 50))
    local StatusVal  = MakeTelemetryCard(108, "●",  "SYSTEM STATUS:",     "STANDBY [PAUSED]",    Color3.fromRGB(160, 170, 190))
    local TimerVal   = MakeTelemetryCard(144, "⏱️", "SESSION TIME:",     "00:00:00",            Color3.fromRGB(0, 220, 255))

    -- Dual Gradient Progress Bar
    local BarContainer = Instance.new("Frame")
    BarContainer.Size              = UDim2.new(1, 0, 0, 10)
    BarContainer.Position          = UDim2.new(0, 0, 0, 186)
    BarContainer.BackgroundColor3  = Color3.fromRGB(20, 25, 38)
    BarContainer.BorderSizePixel   = 0
    BarContainer.Parent            = StatsPage
    Instance.new("UICorner", BarContainer).CornerRadius = UDim.new(1, 0)

    local BarFill = Instance.new("Frame")
    BarFill.Name              = "BarFill"
    BarFill.Size              = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3  = Color3.fromRGB(0, 200, 255)
    BarFill.BorderSizePixel   = 0
    BarFill.Parent            = BarContainer
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

    local BarGrad = Instance.new("UIGradient")
    BarGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 50, 255)),
    })
    BarGrad.Parent = BarFill

    return SG, Hub, ContentWrapper, MinBtn, SwitchBtn, SwitchCircle, SanctuaryBtn, RenderFruitSlots, SkillButtons, FruitVal, LevelVal, AttackVal, StatusVal, TimerVal, BarFill
end

local SG, Hub, ContentWrapper, MinBtn, SwitchBtn, SwitchCircle, SanctuaryBtn, RenderFruitSlots, SkillButtons, FruitVal, LevelVal, AttackVal, StatusVal, TimerVal, BarFill = BuildInterface()

-- ─── Minimize / Expand Feature ─────────────────────
local isMinimized = false
local function ToggleMinimize()
    isMinimized = not isMinimized
    local targetHeight = isMinimized and 42 or 360
    MinBtn.Text = isMinimized and "+" or "—"
    ContentWrapper.Visible = not isMinimized

    TweenService:Create(Hub, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 520, 0, targetHeight)
    }):Play()
end

MinBtn.MouseButton1Click:Connect(ToggleMinimize)
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == CONFIG.MinimizeKey then
        ToggleMinimize()
    end
end)

-- ─── Master Toggle Logic ───────────────────────────
local function UpdateSwitchUI(state)
    if not SwitchBtn or not SwitchBtn.Parent then return end
    local targetPos   = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    local targetColor = state and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(45, 50, 70)
    local circleColor = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 170, 190)

    TweenService:Create(SwitchCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Position = targetPos,
        BackgroundColor3 = circleColor
    }):Play()

    TweenService:Create(SwitchBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        BackgroundColor3 = targetColor
    }):Play()
end

local function SetAutoFarm(state)
    AutoFarmEnabled = state
    UpdateSwitchUI(state)

    if AutoFarmEnabled then
        StatusVal.Text = "ACTIVE // AUTOFARMING"
        StatusVal.TextColor3 = Color3.fromRGB(0, 255, 150)

        if CONFIG.AutoSafeZone then
            TeleportToSanctuary()
        end
        print("[Nexus] [INFO] Master AutoFarm Initialized & Anchored.")
    else
        StatusVal.Text = "STANDBY [PAUSED]"
        StatusVal.TextColor3 = Color3.fromRGB(160, 170, 190)
        AttackVal.Text = "STANDBY"
        print("[Nexus] [INFO] Master AutoFarm Paused.")
    end
end

SwitchBtn.MouseButton1Click:Connect(function()
    SetAutoFarm(not AutoFarmEnabled)
end)

SanctuaryBtn.MouseButton1Click:Connect(function()
    TeleportToSanctuary()
    SanctuaryBtn.Text = "✓ SANCTUARY LOCK ENGAGED"
    task.delay(1.5, function()
        if SanctuaryBtn then SanctuaryBtn.Text = "🛡️ ANCHOR INSIDE SAFE SKY CUBE" end
    end)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == CONFIG.ToggleKey then
        SetAutoFarm(not AutoFarmEnabled)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════
-- ║                     SKILL EXECUTION ENGINE                             ║
-- ══════════════════════════════════════════════════════════════════════════

local function ExecuteSkill(fruitName, tool)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- Equip tool
    if tool.Parent ~= char then
        hum:EquipTool(tool)
        task.wait(0.02)
    end

    local mouseRay = Loader.Main:GetMouseRay(300)
    local cleanName = tool.Name:gsub(" ", "")

    pcall(function()
        Loader.Server(fruitName, cleanName, {
            MouseRay = mouseRay
        })
    end)

    pcall(function() tool:Activate() end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(500, 500))
    end)

    -- Multi-frame snapback after move
    if AutoFarmEnabled and CONFIG.AutoSafeZone then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = SafeTargetCFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- ║                        AUTONOMOUS MAIN LOOP                            ║
-- ══════════════════════════════════════════════════════════════════════════

print("[Nexus] Fruit Battlegrounds Suite Loaded. Keybind: [P]")
SetAutoFarm(true)

local lastFruitCheck = ""

while true do
    -- 1. Refresh Live Telemetry
    local fruitName, lvl, exp = GetFruitStats()
    if not StartExp then StartExp = exp end

    FruitVal.Text  = string.upper(fruitName)
    LevelVal.Text  = string.format("LVL %d • EXP %.0f", lvl, exp)

    -- Refresh Fruit Slot list if fruit changed
    if fruitName ~= lastFruitCheck then
        lastFruitCheck = fruitName
        if RenderFruitSlots then RenderFruitSlots() end
    end

    -- EXP Progress Bar
    local expPerLevel = 500
    local pct = (exp % expPerLevel) / expPerLevel
    if BarFill and BarFill.Parent then
        TweenService:Create(BarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
        }):Play()
    end

    -- Session Timer
    local elapsed = os.time() - StartTime
    local hrs = math.floor(elapsed / 3600)
    local mins = math.floor((elapsed % 3600) / 60)
    local secs = elapsed % 60
    TimerVal.Text = string.format("%02d:%02d:%02d", hrs, mins, secs)

    -- Update Skill Names in GUI Matrix
    local skillMatrix = GetSkillInventory()
    for i = 1, 9 do
        local slotData = skillMatrix[i]
        local uiItem   = SkillButtons[i]
        if slotData and uiItem and uiItem.name then
            if slotData.tool then
                uiItem.name.Text = slotData.name
            else
                uiItem.name.Text = "Slot " .. i .. " (Empty)"
            end
        end
    end

    -- 2. Execute Enabled Skills
    if AutoFarmEnabled then
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local alive = hum and hum.Health > 0

        if not alive then
            StatusVal.Text = "CHARACTER DEAD [RESPAWNING...]"
            StatusVal.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.wait(2)
            if CONFIG.AutoSafeZone then
                TeleportToSanctuary()
            end
        else
            local executedAny = false

            for i = 1, 9 do
                if not AutoFarmEnabled then break end

                -- Check if this specific skill slot is toggled ON
                if SkillToggles[i] then
                    local slotData = skillMatrix[i]
                    if slotData and slotData.tool and not slotData.locked and lvl >= slotData.level then
                        local isBlocked = false
                        local ok, stunned = pcall(function()
                            return Loader.MainFunctions:CheckStuns(char, {"CantAttack", "Stunned"})
                        end)
                        if ok and stunned then isBlocked = true end

                        if not isBlocked then
                            AttackVal.Text = string.format("[%02d] %s", i, slotData.name)
                            ExecuteSkill(fruitName, slotData.tool)
                            executedAny = true
                            task.wait(CONFIG.AttackDelay)
                        else
                            task.wait(0.06)
                        end
                    end
                end
            end

            -- If no specific tool was executed but slot 1 is active, execute default M1
            if not executedAny and SkillToggles[1] then
                AttackVal.Text = "[01] DEFAULT M1"
                pcall(function()
                    Loader.Server(fruitName, "Cannon", {
                        MouseRay = Loader.Main:GetMouseRay(300)
                    })
                end)
                task.wait(CONFIG.AttackDelay)
            elseif not executedAny then
                task.wait(0.15)
            end
        end
    else
        task.wait(0.2)
    end
end
