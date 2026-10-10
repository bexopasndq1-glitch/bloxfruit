-- VitaHub | Blox Fruits (v4) (запускать через executor)
-- F2 ESP фруктов | F3 полёт к фрукту
-- F4 автофарм по уровню | F5 смена оружия | F6 fast attack | RightShift скрыть/показать GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ===== Настройки =====
local FLY_SPEED = 250        -- скорость полёта (студов/сек), меньше = безопаснее
local FARM_HEIGHT = 10       -- высота зависания над мобом (выше = безопаснее, но клики достают хуже)
local FARM_APPROACH = 80     -- дальше этого расстояния сначала подлетаем
local FAST_RANGE = 60        -- радиус, в котором fast attack бьёт мобов
local WEAPONS = {"Melee", "Sword", "Blox Fruit"}
local FRUIT_KEYS = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
-- =====================

local alive = true           -- false после "Убить GUI": все циклы завершаются
local connections = {}
local function track(c) table.insert(connections, c) return c end

local weaponIndex = 1
local farmMobName = nil  -- имя моба текущего квеста (fast attack бьёт только его)

-- имя моба без суффикса вида " [Lv. 5]"
local function baseName(n)
    return (n:gsub("%s*%[.-%]%s*$", ""))
end
local flying = false
local currentTween
local noclipConn
local statusText = "Ожидание"

local state = {
    fastAttack = false,
    esp = false,
    autoFarm = false,
}

local refreshGui = function() end

local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "VitaHub", Text = text, Duration = 3,
        })
    end)
end

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Анти-AFK
track(player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))

-- ================= Фрукты =================
local function getFruits()
    local fruits = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Tool") and obj.Name:find("Fruit") then
            table.insert(fruits, obj)
        end
    end
    return fruits
end

local function updateESP()
    for _, fruit in ipairs(getFruits()) do
        local handle = fruit:FindFirstChild("Handle")
        if handle and not handle:FindFirstChild("FruitESP") then
            local g = Instance.new("BillboardGui")
            g.Name = "FruitESP"
            g.Adornee = handle
            g.Size = UDim2.new(0, 120, 0, 30)
            g.AlwaysOnTop = true

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = fruit.Name
            label.TextColor3 = Color3.fromRGB(255, 200, 0)
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            label.Parent = g
            g.Parent = handle
        end
    end
end

local function clearESP()
    for _, fruit in ipairs(getFruits()) do
        local handle = fruit:FindFirstChild("Handle")
        local esp = handle and handle:FindFirstChild("FruitESP")
        if esp then esp:Destroy() end
    end
end

-- ================= Полёт к фрукту =================
local function stopFlying()
    flying = false
    if currentTween then currentTween:Cancel() currentTween = nil end
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    local root = getRoot()
    local hold = root and root:FindFirstChild("FlyHold")
    if hold then hold:Destroy() end
    refreshGui()
end

local function flyToNearestFruit()
    if flying then
        stopFlying()
        notify("Полёт отменён")
        return
    end
    if state.autoFarm then
        notify("Сначала выключи автофарм")
        return
    end

    local char = player.Character
    local root = getRoot()
    if not root then return end

    local nearest, minDist = nil, math.huge
    for _, fruit in ipairs(getFruits()) do
        local handle = fruit:FindFirstChild("Handle")
        if handle then
            local dist = (handle.Position - root.Position).Magnitude
            if dist < minDist then nearest, minDist = handle, dist end
        end
    end

    if not nearest then
        notify("Фруктов на карте нет")
        return
    end

    flying = true
    refreshGui()
    notify(("Лечу к фрукту (%d студов)"):format(minDist))

    local hold = Instance.new("BodyVelocity")
    hold.Name = "FlyHold"
    hold.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    hold.Velocity = Vector3.zero
    hold.Parent = root

    noclipConn = RunService.Stepped:Connect(function()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)

    currentTween = TweenService:Create(
        root,
        TweenInfo.new(minDist / FLY_SPEED, Enum.EasingStyle.Linear),
        {CFrame = nearest.CFrame + Vector3.new(0, 3, 0)}
    )
    currentTween.Completed:Connect(function()
        stopFlying()
        notify("Прилетел")
    end)
    currentTween:Play()
end

-- ================= Клик-цикл (fast attack, из старого скрипта) =================
-- Этот же клик-цикл работает для Fast Attack и для Автофарма (любое оружие, включая фрукт)
task.spawn(function()
    while alive do
        local farmClick = state.autoFarm
        if state.fastAttack or farmClick then
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(1280, 672))
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new(1280, 672))
        end
        task.wait(0.1)
    end
end)

-- ================= Fast Attack через сеть (из найденного скрипта) =================
-- Зависит от версии игры: если ремоутов нет, остаётся только клик-цикл выше.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RegisterAttack, RegisterHit
local netWarned = false

local function findNet()
    if RegisterAttack and RegisterHit then return end
    local mods = ReplicatedStorage:FindFirstChild("Modules")
    local net = mods and mods:FindFirstChild("Net")
    if net then
        RegisterAttack = net:FindFirstChild("RE/RegisterAttack")
        RegisterHit = net:FindFirstChild("RE/RegisterHit")
    end
end

local function netAttack()
    local root = getRoot()
    local folder = Workspace:FindFirstChild("Enemies")
    if not root or not folder then return end

    findNet()
    if not (RegisterAttack and RegisterHit) then
        if not netWarned then
            netWarned = true
            notify("Ремоуты fast attack не найдены, работает только клик")
        end
        return
    end

    local list = {}
    for _, e in ipairs(folder:GetChildren()) do
        local hum = e:FindFirstChildOfClass("Humanoid")
        local er = e:FindFirstChild("HumanoidRootPart")
        if hum and er and hum.Health > 0
            and (er.Position - root.Position).Magnitude <= FAST_RANGE
            and (not (state.autoFarm and farmMobName) or baseName(e.Name) == farmMobName) then
            list[#list + 1] = {e, er}
        end
    end
    if #list == 0 then return end

    local first = list[1][1]:FindFirstChild("Head") or list[1][2]
    RegisterAttack:FireServer(0.1)
    RegisterHit:FireServer(first, list)
end

-- Работает при включённом Fast Attack и всегда во время автофарма
task.spawn(function()
    while alive do
        if state.fastAttack or state.autoFarm then
            pcall(netAttack)
        end
        task.wait(0.05)
    end
end)

-- ================= Автофарм по квестам =================
-- Если авто-поиск NPC квеста не сработает, впиши позицию вручную:
-- QUEST_NPC_POS["BanditQuest1"] = Vector3.new(x, y, z)
local QUEST_NPC_POS = {}

local farmNoclip
local farmTween

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getPlayerLevel()
    local ok, lvl = pcall(function() return player.Data.Level.Value end)
    return ok and lvl or 1
end

local function equipWeapon()
    local char = player.Character
    local hum = getHumanoid()
    if not char or not hum then return end
    local want = WEAPONS[weaponIndex]

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.ToolTip == want then return tool end
            hum:UnequipTools()
            break
        end
    end
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == want then
            hum:EquipTool(tool)
            return tool
        end
    end
end

local function startFarmPhysics()
    local root = getRoot()
    if not root then return end
    if not root:FindFirstChild("FarmHold") then
        local hold = Instance.new("BodyVelocity")
        hold.Name = "FarmHold"
        hold.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        hold.Velocity = Vector3.zero
        hold.Parent = root
    end
    if not farmNoclip then
        farmNoclip = RunService.Stepped:Connect(function()
            local char = player.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
end

local function stopFarmPhysics()
    if farmTween then farmTween:Cancel() farmTween = nil end
    if farmNoclip then farmNoclip:Disconnect() farmNoclip = nil end
    local root = getRoot()
    local hold = root and root:FindFirstChild("FarmHold")
    if hold then hold:Destroy() end
end

-- Плавный полёт в точку. abort() == true прерывает. Возвращает true, если долетели.
local function flyToPos(dest, abort)
    local root = getRoot()
    if not root then return false end
    startFarmPhysics()

    local dist = (dest - root.Position).Magnitude
    local t = TweenService:Create(
        root,
        TweenInfo.new(math.max(dist / FLY_SPEED, 0.05), Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(dest)}
    )
    farmTween = t
    t:Play()

    while t.PlaybackState == Enum.PlaybackState.Playing do
        if abort and abort() then
            t:Cancel()
            farmTween = nil
            return false
        end
        task.wait(0.1)
    end
    farmTween = nil
    return true
end

-- ===== Квесты =====
local function getCommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommF_")
end

local QuestData
local function loadQuests()
    if QuestData then return QuestData end
    local ok, res = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Quests", 5))
    end)
    if ok and type(res) == "table" then QuestData = res end
    return QuestData
end

local function getSpawnPositions(mob)
    local list = {}
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    local folder = origin and origin:FindFirstChild("EnemySpawns")
    if folder then
        for _, p in ipairs(folder:GetChildren()) do
            if p:IsA("BasePart") and baseName(p.Name) == mob then
                list[#list + 1] = p.Position
            end
        end
    end
    return list
end

-- Квест с самым высоким требованием, которое не выше моего уровня,
-- и только такой, чьи мобы реально есть в текущем море.
local function pickQuest()
    local quests = loadQuests()
    if not quests then return nil end

    local lvl = getPlayerLevel()
    local best

    for qName, tiers in pairs(quests) do
        if type(tiers) == "table" then
            for idx, data in pairs(tiers) do
                if type(data) == "table"
                    and type(data.LevelReq) == "number"
                    and type(data.Task) == "table"
                    and data.LevelReq <= lvl
                    and (not best or data.LevelReq > best.req) then

                    local mob, cnt
                    for m, c in pairs(data.Task) do
                        mob, cnt = m, c
                    end

                    -- cnt > 1: пропускаем боссов
                    if mob and type(cnt) == "number" and cnt > 1 and #getSpawnPositions(mob) > 0 then
                        best = { name = qName, idx = idx, mob = mob, count = cnt, req = data.LevelReq }
                    end
                end
            end
        end
    end

    return best
end

local function questActive()
    local ok, vis = pcall(function() return player.PlayerGui.Main.Quest.Visible end)
    return ok and vis == true
end

local function takeQuest(q, center, abort)
    local function try()
        local comm = getCommF()
        if comm then
            pcall(function() comm:InvokeServer("StartQuest", q.name, q.idx) end)
        end
        task.wait(0.6)
        return questActive()
    end

    -- 1) пробуем взять сразу
    if try() then return true end

    -- 2) позиция NPC задана вручную
    if QUEST_NPC_POS[q.name] then
        flyToPos(QUEST_NPC_POS[q.name] + Vector3.new(0, 3, 0), abort)
        if try() then return true end
    end

    -- 3) ищем NPC рядом с зоной мобов и пробуем по очереди
    local npcs = Workspace:FindFirstChild("NPCs")
    if not npcs then return false end

    local list = {}
    for _, n in ipairs(npcs:GetChildren()) do
        local p = n:IsA("Model") and (n.PrimaryPart or n:FindFirstChild("HumanoidRootPart"))
        if p then
            list[#list + 1] = { p = p, d = (p.Position - center).Magnitude }
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)

    for i = 1, math.min(6, #list) do
        if abort() then return false end
        flyToPos(list[i].p.Position + Vector3.new(0, 3, 0), abort)
        if try() then return true end
    end

    return false
end

-- Ближайший живой моб ИМЕННО из квеста
local function getNearestQuestMob(mobName)
    local folder = Workspace:FindFirstChild("Enemies")
    local root = getRoot()
    if not folder or not root then return end

    local best, bestDist = nil, math.huge
    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local mroot = mob:FindFirstChild("HumanoidRootPart")
        if hum and mroot and hum.Health > 0 and baseName(mob.Name) == mobName then
            local d = (mroot.Position - root.Position).Magnitude
            if d < bestDist then best, bestDist = mob, d end
        end
    end
    return best
end

-- Висим над мобом, пока он жив и квест не завершён
local function attackMob(mob, q, abort)
    local mroot = mob:FindFirstChild("HumanoidRootPart")
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not mroot or not hum then return end

    statusText = ("%s | %s x%d | lvl %d"):format(mob.Name, q.name, q.count, getPlayerLevel())

    local r = getRoot()
    if r and (mroot.Position - r.Position).Magnitude > FARM_APPROACH then
        if not flyToPos(mroot.Position + Vector3.new(0, FARM_HEIGHT, 0), abort) then return end
    end
    startFarmPhysics()

    local conn
    conn = RunService.Heartbeat:Connect(function()
        local root = getRoot()
        if alive and state.autoFarm and root and mroot.Parent and hum.Health > 0 then
            local pos = mroot.Position + Vector3.new(0, FARM_HEIGHT, 0)
            root.CFrame = CFrame.new(pos, mroot.Position)
        else
            conn:Disconnect()
        end
    end)

    while not abort() and mroot.Parent and hum.Health > 0 and questActive() do
        task.wait()
    end
    if conn then conn:Disconnect() end
end

-- Один цикл: взять квест -> бить мобов квеста -> когда квест завершён, цикл начнётся заново
local function farmCycle()
    local function on() return alive and state.autoFarm end
    local abort = function() return not on() end

    local q = pickQuest()
    if not q then
        notify("Не нашёл квест под твой уровень, автофарм выключен")
        state.autoFarm = false
        refreshGui()
        return true
    end
    farmMobName = q.mob

    -- ближайший к нам кластер спаунов этого моба
    local root = getRoot()
    if not root then return false end
    local spawns = getSpawnPositions(q.mob)
    table.sort(spawns, function(a, b)
        return (a - root.Position).Magnitude < (b - root.Position).Magnitude
    end)
    local anchor = spawns[1]
    local cluster, sum = {}, Vector3.zero
    for _, p in ipairs(spawns) do
        if (p - anchor).Magnitude <= 250 then
            cluster[#cluster + 1] = p
            sum = sum + p
        end
    end
    local center = sum / #cluster

    -- квест берём при старте фарма и после каждого завершённого
    if not questActive() then
        statusText = "Беру квест: " .. q.name
        if not takeQuest(q, center, abort) then
            notify("Не удалось взять квест " .. q.name)
            return false
        end
        notify(("Квест взят: %s x%d"):format(q.mob, q.count))
    end

    local spIdx, lastSeen = 1, os.clock()

    while on() and questActive() do
        local hum = getHumanoid()
        if not getRoot() or not hum or hum.Health <= 0 then return true end

        equipWeapon()
        local mob = getNearestQuestMob(q.mob)

        if mob then
            lastSeen = os.clock()
            attackMob(mob, q, abort)
        else
            statusText = "Жду мобов: " .. q.mob
            if os.clock() - lastSeen > 3 then
                -- мобов нет: летим к другому споуну, чтобы они появились
                spIdx = spIdx % #cluster + 1
                flyToPos(cluster[spIdx] + Vector3.new(0, FARM_HEIGHT, 0), abort)
                lastSeen = os.clock()
            end
            task.wait(0.3)
        end
    end

    return true
end

task.spawn(function()
    while alive do
        if state.autoFarm then
            local hum = getHumanoid()
            if not getRoot() or not hum or hum.Health <= 0 then
                statusText = "Жду респавн"
                task.wait(1)
            else
                local ok = farmCycle()
                if not ok and alive and state.autoFarm then task.wait(2) end
            end
        else
            statusText = "Автофарм выкл"
            farmMobName = nil
            stopFarmPhysics()
            task.wait(0.3)
        end
        task.wait()
    end
    stopFarmPhysics()
end)

-- ================= Действия =================
local function toggleFast()
    state.fastAttack = not state.fastAttack
    refreshGui()
end

local function toggleESP()
    state.esp = not state.esp
    if not state.esp then clearESP() end
    refreshGui()
end

local function toggleFarm()
    if flying then stopFlying() end
    state.autoFarm = not state.autoFarm
    refreshGui()
end

local function setWeapon(i)
    weaponIndex = i
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum:UnequipTools() end
    refreshGui()
end

-- ================= GUI (VitaHub) =================
local ACCENT   = Color3.fromRGB(139, 92, 246)
local ACCENT2  = Color3.fromRGB(236, 72, 153)
local BG       = Color3.fromRGB(16, 16, 22)
local CARD     = Color3.fromRGB(30, 30, 42)
local TEXT     = Color3.fromRGB(235, 235, 245)
local MUTED    = Color3.fromRGB(140, 140, 165)
local OFFPILL  = Color3.fromRGB(62, 62, 80)
local RED      = Color3.fromRGB(200, 62, 78)
local GOOD     = Color3.fromRGB(52, 199, 120)

local gui = Instance.new("ScreenGui")
gui.Name = "VitaHubGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okParent or not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 8)
    c.Parent = obj
    return c
end

local function brandGradient(obj)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(ACCENT, ACCENT2)
    g.Rotation = 20
    g.Parent = obj
    return g
end

-- Главное окно
local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 250, 0, 0)
frame.AutomaticSize = Enum.AutomaticSize.Y
frame.Position = UDim2.new(0, 20, 0.5, -230)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
corner(frame, UDim.new(0, 12))

local stroke = Instance.new("UIStroke")
stroke.Color = ACCENT
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.Parent = frame

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = frame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = frame

-- Универсальное перетаскивание. Сдвиг меньше 6px считается кликом.
local function makeDraggable(handle, target, onClick)
    local dragging, moved = false, false
    local dragStart, startPos

    track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            dragStart, startPos = input.Position, target.Position
        end
    end))

    track(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end))

    track(UIS.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved and onClick then onClick() end
        end
    end))
end

-- Шапка: название и подпись (за неё окно таскается)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundTransparency = 1
header.LayoutOrder = 1
header.Parent = frame

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, 0, 0, 28)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "VitaHub"
titleLbl.TextColor3 = Color3.new(1, 1, 1)
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 24
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = header
brandGradient(titleLbl)

local subLbl = Instance.new("TextLabel")
subLbl.Position = UDim2.new(0, 0, 0, 28)
subLbl.Size = UDim2.new(1, 0, 0, 16)
subLbl.BackgroundTransparency = 1
subLbl.Text = "Blox Fruits  •  v4"
subLbl.TextColor3 = MUTED
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 12
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Parent = header

makeDraggable(header, frame)

local function sectionLabel(text, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = MUTED
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order
    l.Parent = frame
end

-- Строка с ползунком-переключателем
local rows = {}
local function makeToggle(text, hotkey, order, getFn, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = CARD
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = order
    row.Parent = frame
    corner(row, UDim.new(0, 8))

    local label = Instance.new("TextLabel")
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -68, 1, 0)
    label.BackgroundTransparency = 1
    label.RichText = true
    label.Text = text .. '  <font color="#8c8ca5" size="11">' .. hotkey .. "</font>"
    label.TextColor3 = TEXT
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 38, 0, 20)
    pill.Position = UDim2.new(1, -48, 0.5, -10)
    pill.BackgroundColor3 = OFFPILL
    pill.BorderSizePixel = 0
    pill.Parent = row
    corner(pill, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    corner(knob, UDim.new(1, 0))

    row.Activated:Connect(callback)

    local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    table.insert(rows, function()
        local on = getFn()
        TweenService:Create(pill, info, {BackgroundColor3 = on and ACCENT or OFFPILL}):Play()
        TweenService:Create(knob, info, {
            Position = on and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
    end)
    return row
end

sectionLabel("БОЙ", 2)
makeToggle("Автофарм", "F4", 3, function() return state.autoFarm end, toggleFarm)
makeToggle("Fast Attack", "F6", 4, function() return state.fastAttack end, toggleFast)

sectionLabel("ФРУКТЫ", 6)
makeToggle("ESP фруктов", "F2", 7, function() return state.esp end, toggleESP)
makeToggle("Полёт к фрукту", "F3", 8, function() return flying end, flyToNearestFruit)

sectionLabel("ОРУЖИЕ  (F5)", 9)

local weaponRow = Instance.new("Frame")
weaponRow.Size = UDim2.new(1, 0, 0, 34)
weaponRow.BackgroundTransparency = 1
weaponRow.LayoutOrder = 10
weaponRow.Parent = frame

local weaponLayout = Instance.new("UIListLayout")
weaponLayout.FillDirection = Enum.FillDirection.Horizontal
weaponLayout.Padding = UDim.new(0, 6)
weaponLayout.SortOrder = Enum.SortOrder.LayoutOrder
weaponLayout.Parent = weaponRow

local weaponButtons = {}
local weaponLabels = {"Melee", "Sword", "Fruit"}
for i = 1, 3 do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / 3, -4, 1, 0)
    b.BackgroundColor3 = CARD
    b.BorderSizePixel = 0
    b.Text = weaponLabels[i]
    b.TextColor3 = TEXT
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.AutoButtonColor = false
    b.LayoutOrder = i
    b.Parent = weaponRow
    corner(b, UDim.new(0, 8))
    b.Activated:Connect(function() setWeapon(i) end)
    weaponButtons[i] = b
end

-- Строка статуса
local statusRow = Instance.new("Frame")
statusRow.Size = UDim2.new(1, 0, 0, 34)
statusRow.BackgroundColor3 = CARD
statusRow.BorderSizePixel = 0
statusRow.LayoutOrder = 11
statusRow.Parent = frame
corner(statusRow, UDim.new(0, 8))

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 12, 0.5, -4)
dot.BackgroundColor3 = MUTED
dot.BorderSizePixel = 0
dot.Parent = statusRow
corner(dot, UDim.new(1, 0))

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 28, 0, 0)
status.Size = UDim2.new(1, -36, 1, 0)
status.BackgroundTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.TextColor3 = MUTED
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Text = ""
status.Parent = statusRow

refreshGui = function()
    for _, update in ipairs(rows) do update() end
    for i, b in ipairs(weaponButtons) do
        b.BackgroundColor3 = (i == weaponIndex) and ACCENT or CARD
    end
    dot.BackgroundColor3 = state.autoFarm and GOOD or MUTED
end
refreshGui()

-- Кружок VH: появляется при скрытии окна, двигается, по клику открывает GUI
local circle = Instance.new("TextButton")
circle.Size = UDim2.new(0, 50, 0, 50)
circle.Position = frame.Position
circle.BackgroundColor3 = Color3.new(1, 1, 1)
circle.BorderSizePixel = 0
circle.Text = "VH"
circle.TextColor3 = Color3.new(1, 1, 1)
circle.Font = Enum.Font.GothamBlack
circle.TextSize = 17
circle.AutoButtonColor = false
circle.Active = true
circle.Visible = false
circle.Parent = gui
corner(circle, UDim.new(1, 0))
brandGradient(circle).Rotation = 45

local circleStroke = Instance.new("UIStroke")
circleStroke.Color = Color3.new(1, 1, 1)
circleStroke.Thickness = 1.5
circleStroke.Transparency = 0.6
circleStroke.Parent = circle

local function setGuiVisible(v)
    if v then
        frame.Position = circle.Position -- окно открывается там, где стоит кружок
    else
        circle.Position = frame.Position -- кружок появляется там, где было окно
    end
    frame.Visible = v
    circle.Visible = not v
end

makeDraggable(circle, circle, function() setGuiVisible(true) end)

local function killAll()
    alive = false
    state.autoFarm, state.fastAttack, state.esp = false, false, false
    stopFlying()
    stopFarmPhysics()
    clearESP()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
    notify("VitaHub остановлен, GUI удалён")
end

-- Нижние кнопки: Скрыть и Убить
local bottom = Instance.new("Frame")
bottom.Size = UDim2.new(1, 0, 0, 34)
bottom.BackgroundTransparency = 1
bottom.LayoutOrder = 12
bottom.Parent = frame

local function bottomButton(text, x, color, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -3, 1, 0)
    b.Position = UDim2.new(x, x == 0 and 0 or 3, 0, 0)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.AutoButtonColor = true
    b.Parent = bottom
    corner(b, UDim.new(0, 8))
    b.Activated:Connect(callback)
    return b
end

bottomButton("Скрыть GUI", 0, CARD, function() setGuiVisible(false) end)
bottomButton("Убить GUI", 0.5, RED, killAll)

task.spawn(function()
    while alive do
        status.Text = statusText
        task.wait(0.5)
    end
end)

-- ================= Горячие клавиши =================
track(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    local k = input.KeyCode

    if k == Enum.KeyCode.F2 then toggleESP()
    elseif k == Enum.KeyCode.F3 then flyToNearestFruit()
    elseif k == Enum.KeyCode.F4 then toggleFarm()
    elseif k == Enum.KeyCode.F5 then setWeapon(weaponIndex % #WEAPONS + 1)
    elseif k == Enum.KeyCode.F6 then toggleFast()
    elseif k == Enum.KeyCode.RightShift then setGuiVisible(not frame.Visible)
    end
end))

notify("VitaHub загружен. RightShift или «Скрыть GUI» — спрятать меню")
