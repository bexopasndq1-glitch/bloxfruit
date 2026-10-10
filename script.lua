-- VitaHub | Blox Fruits (v5.3) - Russian / English (запускать через executor)
-- Вкладки: Combat / Visuals / Misc
-- F2 ESP фруктов | F3 полёт к фрукту | F4 автофарм | F5 смена оружия | F6 fast attack
-- RightShift скрыть/показать GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ===== Настройки =====
local FLY_SPEED = 250        -- скорость полёта (студов/сек), меньше = безопаснее
local FARM_HEIGHTS = {20, 30, 45, 60}   -- варианты высоты фарма (выбор в Combat)
local farmHeightIndex = 2
local FARM_HEIGHT = FARM_HEIGHTS[farmHeightIndex]      -- высота зависания над мобом
local CRUISE_HEIGHTS = {80, 150, 250}     -- варианты высоты перелёта (выбор в Misc)
local cruiseIndex = 2
local CRUISE_HEIGHT = CRUISE_HEIGHTS[cruiseIndex]      -- на сколько выше всего летим при перелёте
local FARM_APPROACH = 80     -- дальше этого расстояния сначала подлетаем
local FAST_RANGE = 60        -- радиус, в котором fast attack бьёт мобов
local MOB_LEVEL_SLACK = 5    -- насколько уровень моба может быть выше моего
local WEAPONS = {"Melee", "Sword", "Blox Fruit"}
local BLUR_SIZE = 14         -- сила размытия фона за меню (0 = выкл)

-- Ручной выбор квеста (если авто-выбор ошибается). Пример:
-- local FORCE_QUEST = {name = "ZombieQuest", idx = 2}
local FORCE_QUEST = nil
-- =====================

-- ===== Палитра =====
local ACCENT   = Color3.fromRGB(139, 92, 246)
local ACCENT2  = Color3.fromRGB(236, 72, 153)
local TEXT     = Color3.fromRGB(240, 240, 250)
local MUTED    = Color3.fromRGB(170, 172, 200)
local RED      = Color3.fromRGB(220, 70, 90)
local GOOD     = Color3.fromRGB(52, 199, 120)

-- ===== Выбор языка / Language select =====
local LANG
do
    local selGui = Instance.new("ScreenGui")
    selGui.Name = "VitaHubLang"
    selGui.ResetOnSpawn = false
    selGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local okP = pcall(function() selGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not okP or not selGui.Parent then selGui.Parent = player:WaitForChild("PlayerGui") end

    local function round(obj, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = obj
    end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 360, 0, 200)
    panel.Position = UDim2.new(0.5, -180, 0.5, -100)
    panel.BackgroundColor3 = Color3.new(1, 1, 1)
    panel.BackgroundTransparency = 0.22
    panel.BorderSizePixel = 0
    panel.Parent = selGui
    round(panel, 20)

    local pg = Instance.new("UIGradient")
    pg.Color = ColorSequence.new(Color3.fromRGB(76, 64, 148), Color3.fromRGB(16, 18, 38))
    pg.Rotation = 55
    pg.Parent = panel

    local ps = Instance.new("UIStroke")
    ps.Color = Color3.new(1, 1, 1)
    ps.Thickness = 1.6
    ps.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ps.Parent = panel

    local psg = Instance.new("UIGradient")
    psg.Rotation = 45
    psg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.5, 0.88),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    psg.Parent = ps

    local title = Instance.new("TextLabel")
    title.Position = UDim2.new(0, 0, 0, 22)
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundTransparency = 1
    title.Text = "VitaHub"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 30
    title.Parent = panel
    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new(ACCENT, ACCENT2)
    tg.Rotation = 20
    tg.Parent = title

    local sub = Instance.new("TextLabel")
    sub.Position = UDim2.new(0, 0, 0, 64)
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.BackgroundTransparency = 1
    sub.Text = "Выбери язык  /  Choose your language"
    sub.TextColor3 = MUTED
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 14
    sub.Parent = panel

    local function langButton(text, x, code)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 150, 0, 54)
        b.Position = UDim2.new(0, x, 0, 112)
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 18
        b.AutoButtonColor = false
        b.BackgroundColor3 = Color3.new(1, 1, 1)
        b.BackgroundTransparency = 0.88
        b.BorderSizePixel = 0
        b.Parent = panel
        round(b, 14)

        local st = Instance.new("UIStroke")
        st.Color = Color3.new(1, 1, 1)
        st.Transparency = 0.7
        st.Thickness = 1
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.Parent = b

        b.MouseEnter:Connect(function()
            b.BackgroundColor3 = ACCENT
            b.BackgroundTransparency = 0.25
        end)
        b.MouseLeave:Connect(function()
            b.BackgroundColor3 = Color3.new(1, 1, 1)
            b.BackgroundTransparency = 0.88
        end)
        b.Activated:Connect(function() LANG = code end)
    end

    langButton("Русский", 20, "ru")
    langButton("English", 190, "en")

    while not LANG do
        if not selGui.Parent then LANG = "en" break end
        task.wait(0.1)
    end
    pcall(function() selGui:Destroy() end)
end

local I18N = {
    ru = {
        status_wait = "Ожидание",
        cancelled = "Полёт отменён",
        turn_off_farm = "Сначала выключи автофарм / Factory",
        no_fruits = "Фруктов на карте нет",
        fly_fruit = "Лечу к фрукту (%d студов), высота %d",
        arrived = "Прилетел",
        net_missing = "Ремоуты fast attack не найдены, работает только клик",
        no_spawns = "нет споунов моба %s",
        mob_strong = "моб %s слишком сильный (Lv. %d)",
        quest_skipped = "Пропущен квест %s (Lv %d): %s",
        quest_skipped_log = "[VitaHub] пропущен %s:%s (req %d) - %s",
        abandon_fail = "Не удалось отменить старый квест, проверь вручную",
        status_attack = "%s | игрок %d | моб %s | %s x%d",
        no_quest = "Не нашёл квест под твой уровень, автофарм выключен",
        quest_log = "[VitaHub] квест %s:%s, моб %s x%d, req %d, игрок lvl %d",
        taking_quest = "Беру квест: %s",
        quest_failed = "Квест не взялся: %s, бью мобов без него",
        quest_taken = "Квест %s (от lvl %d), мобы %s x%d, игрок lvl %d",
        waiting_mobs = "Жду мобов: %s",
        waiting_respawn = "Жду респавн",
        farm_off = "Автофарм выкл",
        factory_wait = "Factory: жду Core (Sea 2)",
        call_error = "ошибка вызова",
        commf_missing = "CommF_ не найден",
        gacha_got = "получено (см. инвентарь)",
        max = "максимум",
        stat_max3 = "Можно выбрать максимум 3 стата",
        hint = "RightShift -\nскрыть меню",
        sec_farm = "ФАРМ",
        tg_autofarm = "Автофарм",
        sec_weapon = "ОРУЖИЕ  (F5 - сменить)",
        sec_farm_height = "ВЫСОТА ФАРМА (над мобами)",
        sec_auto = "АВТО",
        tg_gacha = "Auto Gacha (ролл фрукта)",
        sec_stats = "СТАТЫ  (куда качать)",
        tg_split = "Разделение (до 3 статов)",
        btn_stop_stats = "Остановить прокачку",
        btn_start_stats = "Начать прокачку",
        sec_cruise = "ВЫСОТА ПОЛЁТА (перелёты)",
        sec_misc = "ПРОЧЕЕ",
        tg_flyfruit = "Полёт к фрукту",
        tg_blur = "Blur фона (стекло)",
        killed = "VitaHub остановлен, GUI удалён",
        lvl_label = "Твой Лвл : ",
        next_label = "Следующий Остров : ",
        stats_info = "Очков: %d  |  Качаю: %s",
        storage_info = "Хранилище: ",
        gacha_info = "Ответ сервера: ",
        loaded = "VitaHub v5 загружен. RightShift - скрыть меню",
    },
    en = {
        status_wait = "Idle",
        cancelled = "Flight cancelled",
        turn_off_farm = "Turn off Auto Farm / Factory first",
        no_fruits = "No fruits on the map",
        fly_fruit = "Flying to fruit (%d studs), altitude %d",
        arrived = "Arrived",
        net_missing = "Fast attack remotes not found, clicks only",
        no_spawns = "no spawns for mob %s",
        mob_strong = "mob %s is too strong (Lv. %d)",
        quest_skipped = "Skipped quest %s (Lv %d): %s",
        quest_skipped_log = "[VitaHub] skipped %s:%s (req %d) - %s",
        abandon_fail = "Couldn't abandon the old quest, check it manually",
        status_attack = "%s | player %d | mob %s | %s x%d",
        no_quest = "No quest found for your level, Auto Farm turned off",
        quest_log = "[VitaHub] quest %s:%s, mob %s x%d, req %d, player lvl %d",
        taking_quest = "Taking quest: %s",
        quest_failed = "Quest not accepted: %s, fighting mobs without it",
        quest_taken = "Quest %s (from lvl %d), mobs %s x%d, player lvl %d",
        waiting_mobs = "Waiting for mobs: %s",
        waiting_respawn = "Waiting for respawn",
        farm_off = "Auto Farm off",
        factory_wait = "Factory: waiting for Core (Sea 2)",
        call_error = "call error",
        commf_missing = "CommF_ not found",
        gacha_got = "received (check inventory)",
        max = "max",
        stat_max3 = "You can select up to 3 stats",
        hint = "RightShift -\nhide menu",
        sec_farm = "FARM",
        tg_autofarm = "Auto Farm",
        sec_weapon = "WEAPON  (F5 - switch)",
        sec_farm_height = "FARM HEIGHT (above mobs)",
        sec_auto = "AUTO",
        tg_gacha = "Auto Gacha (roll fruit)",
        sec_stats = "STATS  (where to invest)",
        tg_split = "Split (up to 3 stats)",
        btn_stop_stats = "Stop leveling",
        btn_start_stats = "Start leveling",
        sec_cruise = "FLIGHT HEIGHT (travel)",
        sec_misc = "OTHER",
        tg_flyfruit = "Fly to fruit",
        tg_blur = "Background blur (glass)",
        killed = "VitaHub stopped, GUI removed",
        lvl_label = "Your Lvl : ",
        next_label = "Next Island : ",
        stats_info = "Points: %d  |  Leveling: %s",
        storage_info = "Storage: ",
        gacha_info = "Server reply: ",
        loaded = "VitaHub v5 loaded. RightShift - hide menu",
    },
}

-- T("key") или T("key", ...) для строк с %s / %d
local function T(key, ...)
    local pack = I18N[LANG] or I18N.ru
    local str = pack[key] or I18N.ru[key] or key
    if select("#", ...) > 0 then
        local ok, res = pcall(string.format, str, ...)
        return ok and res or str
    end
    return str
end

local alive = true           -- false после "Убить GUI": все циклы завершаются
local connections = {}
local function track(c) table.insert(connections, c) return c end

local weaponIndex = 1
local farmMobName = nil  -- имя моба, которого бьёт fast attack во время фарма

-- имя моба без суффикса вида " [Lv. 5]"
local function baseName(n)
    return (n:gsub("%s*%[.-%]%s*$", ""))
end

-- нормализованное имя для "мягкого" сравнения: "Snow Trooper" == "SnowTrooper2"
local function normName(s)
    s = baseName(s):lower():gsub("[^%w]", "")
    return (s:gsub("%d+$", ""))
end

local flying = false
local currentTween
local noclipConn
local statusText = T("status_wait")
local gachaStatus = "-"

local state = {
    fastAttack = false,
    espFruits = false,
    espPlayers = false,
    autoFarm = false,
    autoFactory = false,
    autoStats = false,
    autoGacha = false,
    autoStore = false,
    splitStats = false,
    blur = true,
}

local STAT_NAMES = {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}
local STAT_LABELS = {"Melee", "Defense", "Sword", "Gun", "Fruit"}
local statIndex = 1
local splitSel = {}      -- выбранные статы в режиме "Разделение" (индексы), максимум 3
local splitRot = 0       -- сдвиг для честной раздачи остатка
local storeStatus = "-"
local storeTried = setmetatable({}, {__mode = "k"})

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

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getPlayerLevel()
    local ok, lvl = pcall(function() return player.Data.Level.Value end)
    return ok and lvl or 1
end

local function getPoints()
    local ok, pts = pcall(function() return player.Data.Points.Value end)
    return ok and pts or 0
end

local function getCommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommF_")
end

-- Анти-AFK
track(player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))

-- ================= Фрукты: ESP =================
local function getFruits()
    local fruits = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Tool") and obj.Name:find("Fruit") then
            table.insert(fruits, obj)
        end
    end
    return fruits
end

local function updateFruitESP()
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

local function clearFruitESP()
    for _, fruit in ipairs(getFruits()) do
        local handle = fruit:FindFirstChild("Handle")
        local e = handle and handle:FindFirstChild("FruitESP")
        if e then e:Destroy() end
    end
end

-- ================= Игроки: ESP =================
local function updatePlayerESP()
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local ch = plr.Character
            local hr = ch and ch:FindFirstChild("HumanoidRootPart")
            if ch and hr then
                if not ch:FindFirstChild("VH_Highlight") then
                    local h = Instance.new("Highlight")
                    h.Name = "VH_Highlight"
                    h.FillColor = ACCENT2
                    h.FillTransparency = 0.7
                    h.OutlineColor = Color3.new(1, 1, 1)
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = ch
                end

                local g = hr:FindFirstChild("VH_PlayerESP")
                if not g then
                    g = Instance.new("BillboardGui")
                    g.Name = "VH_PlayerESP"
                    g.Adornee = hr
                    g.Size = UDim2.new(0, 140, 0, 34)
                    g.StudsOffset = Vector3.new(0, 3.5, 0)
                    g.AlwaysOnTop = true

                    local l = Instance.new("TextLabel")
                    l.Name = "L"
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.BackgroundTransparency = 1
                    l.TextColor3 = Color3.new(1, 1, 1)
                    l.TextStrokeTransparency = 0.3
                    l.Font = Enum.Font.GothamBold
                    l.TextSize = 13
                    l.Parent = g
                    g.Parent = hr
                end

                local l = g:FindFirstChild("L")
                if l then
                    local d = myRoot and (hr.Position - myRoot.Position).Magnitude or 0
                    l.Text = ("%s\n%d m"):format(plr.DisplayName, d)
                end
            end
        end
    end
end

local function clearPlayerESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        local ch = plr.Character
        if ch then
            local h = ch:FindFirstChild("VH_Highlight")
            if h then h:Destroy() end
            local hr = ch:FindFirstChild("HumanoidRootPart")
            local g = hr and hr:FindFirstChild("VH_PlayerESP")
            if g then g:Destroy() end
        end
    end
end

-- ================= Полёт к фрукту =================
local stopFarmPhysics, flyToPos -- определены ниже (общий полёт с набором высоты)

local function stopFlying()
    flying = false
    if not (state.autoFarm or state.autoFactory) then
        stopFarmPhysics()
    end
    refreshGui()
end

local function flyToNearestFruit()
    if flying then
        stopFlying()
        notify(T("cancelled"))
        return
    end
    if state.autoFarm or state.autoFactory then
        notify(T("turn_off_farm"))
        return
    end

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
        notify(T("no_fruits"))
        return
    end

    flying = true
    refreshGui()
    notify(T("fly_fruit", math.floor(minDist), CRUISE_HEIGHT))

    task.spawn(function()
        local ok = flyToPos(nearest.Position + Vector3.new(0, 3, 0), function()
            return not flying or not alive or not nearest.Parent
        end)
        if flying then
            local r = getRoot()
            if ok and r and nearest.Parent then r.CFrame = nearest.CFrame end -- касание = подбор
            stopFlying()
            if ok then notify(T("arrived")) end
        end
    end)
end

-- ================= Клик-цикл =================
-- Работает для Fast Attack, Автофарма и Factory (любое оружие, включая фрукт)
task.spawn(function()
    while alive do
        if state.fastAttack or state.autoFarm or state.autoFactory then
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(1280, 672))
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new(1280, 672))
        end
        task.wait(0.1)
    end
end)

-- ================= Fast Attack через сеть =================
-- Зависит от версии игры: если ремоутов нет, остаётся только клик-цикл выше.
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
            notify(T("net_missing"))
        end
        return
    end

    local onlyMob = (state.autoFarm or state.autoFactory) and farmMobName or nil
    local range = math.max(FAST_RANGE, FARM_HEIGHT + 30)

    local list = {}
    for _, e in ipairs(folder:GetChildren()) do
        local hum = e:FindFirstChildOfClass("Humanoid")
        local er = e:FindFirstChild("HumanoidRootPart")
        if hum and er and hum.Health > 0
            and (er.Position - root.Position).Magnitude <= range
            and (not onlyMob or baseName(e.Name) == onlyMob) then
            list[#list + 1] = {e, er}
        end
    end
    if #list == 0 then return end

    local first = list[1][1]:FindFirstChild("Head") or list[1][2]
    RegisterAttack:FireServer(0.1)
    RegisterHit:FireServer(first, list)
end

task.spawn(function()
    while alive do
        if state.fastAttack or state.autoFarm or state.autoFactory then
            pcall(netAttack)
        end
        task.wait(0.05)
    end
end)

-- ================= Автофарм по квестам =================
local farmNoclip
local farmTween

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

function stopFarmPhysics()
    if farmTween then farmTween:Cancel() farmTween = nil end
    if farmNoclip then farmNoclip:Disconnect() farmNoclip = nil end
    local root = getRoot()
    local hold = root and root:FindFirstChild("FarmHold")
    if hold then hold:Destroy() end
end

-- Один прямой отрезок полёта. abort() == true прерывает.
local function tweenTo(dest, abort)
    local root = getRoot()
    if not root then return false end

    local dist = (dest - root.Position).Magnitude
    if dist < 1 then return true end

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

-- Полёт в точку. На длинных дистанциях: вверх -> над картой -> вниз к цели.
-- Возвращает true, если долетели.
function flyToPos(dest, abort)
    local root = getRoot()
    if not root then return false end
    startFarmPhysics()

    local pos = root.Position
    local flat = (Vector3.new(dest.X, 0, dest.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude

    if flat > 120 then
        local cruiseY = math.max(pos.Y, dest.Y) + CRUISE_HEIGHT -- считаем один раз
        if not tweenTo(Vector3.new(pos.X, cruiseY, pos.Z), abort) then return false end
        if not tweenTo(Vector3.new(dest.X, cruiseY, dest.Z), abort) then return false end
    end

    return tweenTo(dest, abort)
end

-- ===== Квесты =====
local QuestData
local function loadQuests()
    if QuestData then return QuestData end
    local ok, res = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Quests", 5))
    end)
    if ok and type(res) == "table" then QuestData = res end
    return QuestData
end

-- Споуны моба: точное имя -> "мягкое" имя -> позиции живых мобов
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

        if #list == 0 then
            local want = normName(mob)
            for _, p in ipairs(folder:GetChildren()) do
                if p:IsA("BasePart") and normName(p.Name) == want then
                    list[#list + 1] = p.Position
                end
            end
        end
    end

    if #list == 0 then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, e in ipairs(enemies:GetChildren()) do
                local er = e:FindFirstChild("HumanoidRootPart")
                if er and baseName(e.Name) == mob then
                    list[#list + 1] = er.Position
                end
            end
        end
    end

    return list
end

-- Уровень моба из имени вида "Vampire [Lv. 975]"
local function getMobLevel(mob)
    local hum = mob:FindFirstChildOfClass("Humanoid")
    local str = (hum and hum.DisplayName or "") .. " " .. mob.Name
    local lv = str:match("%[Lv%.%s*(%d+)%]")
    return lv and tonumber(lv) or nil
end

local function mobLevelOk(mob)
    local ml = getMobLevel(mob)
    return not ml or ml <= getPlayerLevel() + MOB_LEVEL_SLACK
end

local function liveMobLevel(mobName)
    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then return nil end
    for _, mob in ipairs(folder:GetChildren()) do
        if baseName(mob.Name) == mobName then
            local ml = getMobLevel(mob)
            if ml then return ml end
        end
    end
    return nil
end

local function skipReason(c, lvl)
    if #getSpawnPositions(c.mob) == 0 then
        return T("no_spawns", c.mob)
    end
    local ml = liveMobLevel(c.mob)
    if ml and ml > lvl + MOB_LEVEL_SLACK then
        return T("mob_strong", c.mob, ml)
    end
    return nil
end

local warnedSkips = {}

local function pickQuest()
    local quests = loadQuests()
    if not quests then return nil end

    local lvl = getPlayerLevel()

    if FORCE_QUEST then
        local tier = quests[FORCE_QUEST.name] and quests[FORCE_QUEST.name][FORCE_QUEST.idx]
        if type(tier) == "table" and type(tier.Task) == "table" then
            local mob, cnt
            for m, c in pairs(tier.Task) do mob, cnt = m, c end
            if mob then
                return { name = FORCE_QUEST.name, idx = FORCE_QUEST.idx, mob = mob,
                         count = type(cnt) == "number" and cnt or 1, req = tier.LevelReq or 0 }
            end
        end
    end

    local cands = {}
    for qName, tiers in pairs(quests) do
        if type(tiers) == "table" then
            for idx, data in pairs(tiers) do
                if type(data) == "table"
                    and type(data.LevelReq) == "number"
                    and type(data.Task) == "table"
                    and data.LevelReq <= lvl then

                    local mob, cnt
                    for m, c in pairs(data.Task) do
                        mob, cnt = m, c
                    end
                    if mob and type(cnt) == "number" and cnt > 1 then
                        cands[#cands + 1] = { name = qName, idx = idx, mob = mob, count = cnt, req = data.LevelReq }
                    end
                end
            end
        end
    end

    table.sort(cands, function(a, b)
        if a.req ~= b.req then return a.req > b.req end
        return tostring(a.name) .. ":" .. tostring(a.idx) < tostring(b.name) .. ":" .. tostring(b.idx)
    end)

    local skipped = {}
    for _, c in ipairs(cands) do
        local why = skipReason(c, lvl)
        if not why then
            local top = skipped[1]
            if top and lvl - c.req >= 25 then
                local key = tostring(top.name) .. ":" .. tostring(top.idx)
                if not warnedSkips[key] then
                    warnedSkips[key] = true
                    notify(T("quest_skipped", tostring(top.name), top.req, top.why))
                end
            end
            for i = 1, math.min(3, #skipped) do
                print(T("quest_skipped_log",
                    tostring(skipped[i].name), tostring(skipped[i].idx), skipped[i].req, skipped[i].why))
            end
            return c
        end
        c.why = why
        skipped[#skipped + 1] = c
    end

    return nil
end

local function questActive()
    local ok, vis = pcall(function() return player.PlayerGui.Main.Quest.Visible end)
    return ok and vis == true
end

-- Упоминается ли моб в тексте активного квеста (true/false, nil - не удалось прочитать)
local function questMentionsMob(mob)
    local ok, qgui = pcall(function() return player.PlayerGui.Main.Quest end)
    if not ok or not qgui then return nil end

    local want = mob:lower()
    local stem = want:gsub("y$", "")
    local sawText = false

    for _, d in ipairs(qgui:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then
            sawText = true
            local txt = d.Text:lower()
            if txt:find(want, 1, true) or txt:find(stem, 1, true) then
                return true
            end
        end
    end
    return sawText and false or nil
end

-- Гарантирует, что активен ИМЕННО нужный квест
local function ensureQuest(q, abort)
    local comm = getCommF()
    if not comm then return false end

    if questActive() then
        if questMentionsMob(q.mob) == true then
            return true
        end

        for _ = 1, 3 do
            if abort() then return false end
            pcall(function() comm:InvokeServer("AbandonQuest") end)
            task.wait(0.6)
            if not questActive() then break end
        end
        if questActive() then
            notify(T("abandon_fail"))
        end
    end

    for _ = 1, 3 do
        if abort() then return false end
        pcall(function() comm:InvokeServer("StartQuest", q.name, q.idx) end)
        task.wait(0.8)
        if questActive() then return true end
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
        if hum and mroot and hum.Health > 0 and baseName(mob.Name) == mobName and mobLevelOk(mob) then
            local d = (mroot.Position - root.Position).Magnitude
            if d < bestDist then best, bestDist = mob, d end
        end
    end
    return best
end

-- Висим над мобом, пока он жив и abort() не вернул true
local function attackMob(mob, q, abort)
    local mroot = mob:FindFirstChild("HumanoidRootPart")
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not mroot or not hum then return end

    statusText = T("status_attack",
        q.mob, getPlayerLevel(), tostring(getMobLevel(mob) or "?"), tostring(q.name), q.count)

    local r = getRoot()
    if r and (mroot.Position - r.Position).Magnitude > FARM_APPROACH then
        if not flyToPos(mroot.Position + Vector3.new(0, FARM_HEIGHT, 0), abort) then return end
    end
    startFarmPhysics()

    local conn
    conn = RunService.Heartbeat:Connect(function()
        local root = getRoot()
        if alive and not abort() and root and mroot.Parent and hum.Health > 0 then
            local pos = mroot.Position + Vector3.new(0, FARM_HEIGHT, 0)
            root.CFrame = CFrame.new(pos, mroot.Position)
        else
            conn:Disconnect()
        end
    end)

    while not abort() and mroot.Parent and hum.Health > 0 do
        task.wait()
    end
    if conn then conn:Disconnect() end
    return hum.Health <= 0
end

local function farmCycle()
    local function on() return alive and state.autoFarm end
    local abort = function() return not on() end

    local q = pickQuest()
    if not q then
        notify(T("no_quest"))
        state.autoFarm = false
        refreshGui()
        return true
    end
    farmMobName = q.mob
    print(T("quest_log",
        tostring(q.name), tostring(q.idx), q.mob, q.count, q.req, getPlayerLevel()))

    local root = getRoot()
    if not root then return false end
    local spawns = getSpawnPositions(q.mob)
    if #spawns == 0 then return false end
    table.sort(spawns, function(a, b)
        return (a - root.Position).Magnitude < (b - root.Position).Magnitude
    end)
    local anchor = spawns[1]
    local cluster = {}
    for _, p in ipairs(spawns) do
        if (p - anchor).Magnitude <= 250 then
            cluster[#cluster + 1] = p
        end
    end

    statusText = T("taking_quest", tostring(q.name))
    if not ensureQuest(q, abort) then
        notify(T("quest_failed", tostring(q.name)))
    end
    local detect = questActive()
    notify(T("quest_taken",
        tostring(q.name), q.req, q.mob, q.count, getPlayerLevel()))

    local kills = 0
    local spIdx, lastSeen = 1, os.clock()
    local lastTry, lastPick = os.clock(), os.clock()

    while on() do
        local hum = getHumanoid()
        if not getRoot() or not hum or hum.Health <= 0 then return true end

        if detect then
            if not questActive() and os.clock() - lastTry > 2 then
                lastTry = os.clock()
                ensureQuest(q, abort)
            end
        elseif kills >= q.count then
            kills = 0
            ensureQuest(q, abort)
        end

        if os.clock() - lastPick > 5 then
            lastPick = os.clock()
            local nq = pickQuest()
            if nq and nq.req > q.req then
                return true
            end
        end

        equipWeapon()
        local mob = getNearestQuestMob(q.mob)

        if mob then
            lastSeen = os.clock()
            if attackMob(mob, q, abort) then kills = kills + 1 end
        else
            statusText = T("waiting_mobs", q.mob)
            if os.clock() - lastSeen > 3 then
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
                statusText = T("waiting_respawn")
                task.wait(1)
            else
                local ok = farmCycle()
                if not ok and alive and state.autoFarm then task.wait(2) end
            end
        else
            if not state.autoFactory and not flying then
                if not state.autoFarm and not state.autoStats and not state.autoGacha then
                    statusText = T("farm_off")
                end
                farmMobName = nil
                stopFarmPhysics()
            end
            task.wait(0.3)
        end
        task.wait()
    end
    stopFarmPhysics()
end)

-- ================= Auto Factory Core (Sea 2) =================
-- Core ищется среди врагов (Workspace.Enemies.Core). Работает, когда Factory активна.
local function getCore()
    local folder = Workspace:FindFirstChild("Enemies")
    local core = folder and folder:FindFirstChild("Core")
    if core and core:FindFirstChild("HumanoidRootPart") then
        local hum = core:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return core end
    end
    return nil
end

task.spawn(function()
    while alive do
        if state.autoFactory and not state.autoFarm then
            local hum = getHumanoid()
            local core = getCore()
            if hum and hum.Health > 0 and core then
                farmMobName = "Core"
                equipWeapon()
                attackMob(core, { mob = "Core", name = "Factory", count = 1 }, function()
                    return not (alive and state.autoFactory) or state.autoFarm
                end)
            else
                statusText = T("factory_wait")
                if farmMobName == "Core" then farmMobName = nil end
                task.wait(2)
            end
        else
            task.wait(0.5)
        end
        task.wait()
    end
end)

-- ================= Статы =================
-- Обычный режим: все очки в один выбранный стат.
-- Режим "Разделение": очки делятся поровну между выбранными статами (до 3),
-- остаток раздаётся по одному, каждый раз начиная с другого стата.
task.spawn(function()
    while alive do
        if state.autoStats then
            local total = getPoints()
            if total > 0 then
                local comm = getCommF()
                if comm then
                    local targets = {}
                    if state.splitStats then
                        for i = 1, #STAT_NAMES do
                            if splitSel[i] then targets[#targets + 1] = STAT_NAMES[i] end
                        end
                    end
                    if #targets == 0 then targets = { STAT_NAMES[statIndex] } end

                    local n = #targets
                    local share = math.floor(total / n)
                    local rest = total - share * n

                    local amounts = {}
                    for k = 1, n do amounts[k] = share end
                    for r = 1, rest do
                        local k = ((splitRot + r) % n) + 1
                        amounts[k] = amounts[k] + 1
                    end
                    splitRot = (splitRot + rest) % n

                    for k, stat in ipairs(targets) do
                        if amounts[k] > 0 then
                            pcall(function() comm:InvokeServer("AddPoint", stat, amounts[k]) end)
                            task.wait(0.15)
                        end
                    end
                end
            end
            task.wait(0.5)
        else
            task.wait(0.5)
        end
    end
end)

-- ================= Auto Store Fruit =================
-- Прячет фрукты из рюкзака в инвентарь (StoreFruit).
local function fruitRemoteName(tool)
    local attr = tool:GetAttribute("OriginalName")
    if type(attr) == "string" and attr ~= "" then return attr end

    -- запасной вариант: "Rocket Fruit" -> "Rocket-Rocket"
    local base = tool.Name:gsub("%s*Fruit%s*$", "")
    base = base:gsub("^%s+", "")
    return base .. "-" .. base
end

task.spawn(function()
    while alive do
        if state.autoStore then
            local comm = getCommF()
            if comm then
                local containers = { player.Backpack, player.Character }
                for _, container in ipairs(containers) do
                    if container then
                        for _, tool in ipairs(container:GetChildren()) do
                            if tool:IsA("Tool") and tool.Name:find("Fruit") then
                                local last = storeTried[tool]
                                if not last or os.clock() - last > 10 then
                                    storeTried[tool] = os.clock()
                                    local fname = fruitRemoteName(tool)
                                    local ok, res = pcall(function()
                                        return comm:InvokeServer("StoreFruit", fname, tool)
                                    end)
                                    if not ok then
                                        storeStatus = T("call_error")
                                    else
                                        storeStatus = fname .. ": " .. tostring(res)
                                    end
                                    task.wait(0.3)
                                end
                            end
                        end
                    end
                end
            else
                storeStatus = T("commf_missing")
            end
            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)

-- ================= Gacha (ролл фруктов) =================
task.spawn(function()
    while alive do
        if state.autoGacha then
            local comm = getCommF()
            if comm then
                local ok, res = pcall(function() return comm:InvokeServer("Cousin", "Buy") end)
                if not ok then
                    gachaStatus = T("call_error")
                elseif type(res) == "table" then
                    gachaStatus = T("gacha_got")
                else
                    gachaStatus = tostring(res)
                end
            else
                gachaStatus = T("commf_missing")
            end
            task.wait(3)
        else
            task.wait(0.5)
        end
    end
end)

-- ================= Следующий остров (по ближайшему квесту) =================
local function seaForLevel(l)
    if l < 700 then return "Sea 1" end
    if l < 1500 then return "Sea 2" end
    return "Sea 3"
end

local nextCacheLvl, nextCacheText
local function nextIslandText(lvl)
    if nextCacheLvl == lvl and nextCacheText then return nextCacheText end

    local quests = loadQuests()
    if not quests then return "-" end

    local nextReq
    for _, tiers in pairs(quests) do
        if type(tiers) == "table" then
            for _, d in pairs(tiers) do
                if type(d) == "table" and type(d.LevelReq) == "number" and type(d.Task) == "table"
                    and d.LevelReq > lvl and (not nextReq or d.LevelReq < nextReq) then
                    local cnt
                    for _, c in pairs(d.Task) do cnt = c end
                    if type(cnt) == "number" and cnt > 1 then
                        nextReq = d.LevelReq
                    end
                end
            end
        end
    end

    nextCacheLvl = lvl
    nextCacheText = nextReq and (seaForLevel(nextReq) .. " • Lv " .. nextReq) or T("max")
    return nextCacheText
end

-- ================= Действия =================
local function toggleFast()
    state.fastAttack = not state.fastAttack
    refreshGui()
end

local function toggleFruitESP()
    state.espFruits = not state.espFruits
    if not state.espFruits then clearFruitESP() end
    refreshGui()
end

local function togglePlayerESP()
    state.espPlayers = not state.espPlayers
    if not state.espPlayers then clearPlayerESP() end
    refreshGui()
end

local function toggleFarm()
    if flying then stopFlying() end
    state.autoFarm = not state.autoFarm
    if state.autoFarm then
        warnedSkips = {}
    end
    refreshGui()
end

local function toggleFactory()
    if flying then stopFlying() end
    state.autoFactory = not state.autoFactory
    if not state.autoFactory then
        if farmMobName == "Core" then farmMobName = nil end
        if not state.autoFarm then stopFarmPhysics() end
    end
    refreshGui()
end

local function toggleStats()
    state.autoStats = not state.autoStats
    refreshGui()
end

local function toggleGacha()
    state.autoGacha = not state.autoGacha
    refreshGui()
end

local function toggleStore()
    state.autoStore = not state.autoStore
    refreshGui()
end

local function toggleSplit()
    state.splitStats = not state.splitStats
    if state.splitStats and next(splitSel) == nil then
        splitSel[statIndex] = true
    end
    refreshGui()
end

local function setWeapon(i)
    weaponIndex = i
    local hum = getHumanoid()
    if hum then hum:UnequipTools() end
    refreshGui()
end

local function setStat(i)
    if state.splitStats then
        if splitSel[i] then
            splitSel[i] = nil
        else
            local count = 0
            for _ in pairs(splitSel) do count = count + 1 end
            if count >= 3 then
                notify(T("stat_max3"))
                return
            end
            splitSel[i] = true
        end
    else
        statIndex = i
    end
    refreshGui()
end

local function setFarmHeight(i)
    farmHeightIndex = i
    FARM_HEIGHT = FARM_HEIGHTS[i]
    refreshGui()
end

local function setCruiseHeight(i)
    cruiseIndex = i
    CRUISE_HEIGHT = CRUISE_HEIGHTS[i]
    refreshGui()
end

-- ================= GUI: Liquid Glass =================
local gui = Instance.new("ScreenGui")
gui.Name = "VitaHubGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okParent or not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 10)
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

-- "стеклянный" элемент: белая полупрозрачная заливка + тонкая светлая обводка
local function glass(obj, transp, strokeT)
    obj.BackgroundColor3 = Color3.new(1, 1, 1)
    obj.BackgroundTransparency = transp or 0.9
    obj.BorderSizePixel = 0
    local s = Instance.new("UIStroke")
    s.Color = Color3.new(1, 1, 1)
    s.Transparency = strokeT or 0.8
    s.Thickness = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local W, H = 600, 420

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
main.BackgroundColor3 = Color3.new(1, 1, 1)
main.BackgroundTransparency = 0.22
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
corner(main, UDim.new(0, 20))

local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new(Color3.fromRGB(76, 64, 148), Color3.fromRGB(16, 18, 38))
mainGrad.Rotation = 55
mainGrad.Parent = main

-- светящаяся обводка: ярче по углам, слабее посередине
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.new(1, 1, 1)
mainStroke.Thickness = 1.6
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = main

local strokeGrad = Instance.new("UIGradient")
strokeGrad.Rotation = 45
strokeGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1),
    NumberSequenceKeypoint.new(0.5, 0.88),
    NumberSequenceKeypoint.new(1, 0.2),
})
strokeGrad.Parent = mainStroke

-- блик сверху (имитация отражения на стекле)
local sheen = Instance.new("Frame")
sheen.Name = "Sheen"
sheen.Size = UDim2.new(1, 0, 0.42, 0)
sheen.BackgroundColor3 = Color3.new(1, 1, 1)
sheen.BorderSizePixel = 0
sheen.Active = false
sheen.Parent = main
corner(sheen, UDim.new(0, 20))

local sheenGrad = Instance.new("UIGradient")
sheenGrad.Rotation = 90
sheenGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.84),
    NumberSequenceKeypoint.new(1, 1),
})
sheenGrad.Parent = sheen

-- Размытие мира за меню (интерфейс остаётся чётким)
local blur = Instance.new("BlurEffect")
blur.Name = "VH_Blur"
blur.Size = 0
pcall(function() blur.Parent = Lighting end)

local function applyBlur()
    local target = (state.blur and main.Visible) and BLUR_SIZE or 0
    pcall(function()
        TweenService:Create(blur, TweenInfo.new(0.25), {Size = target}):Play()
    end)
end

local function toggleBlur()
    state.blur = not state.blur
    applyBlur()
    refreshGui()
end

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

-- ===== Шапка =====
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 56)
header.BackgroundTransparency = 1
header.Parent = main

local titleLbl = Instance.new("TextLabel")
titleLbl.Position = UDim2.new(0, 20, 0, 8)
titleLbl.Size = UDim2.new(0, 220, 0, 28)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "VitaHub"
titleLbl.TextColor3 = Color3.new(1, 1, 1)
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 24
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = header
brandGradient(titleLbl)

local subLbl = Instance.new("TextLabel")
subLbl.Position = UDim2.new(0, 20, 0, 36)
subLbl.Size = UDim2.new(0, 220, 0, 14)
subLbl.BackgroundTransparency = 1
subLbl.Text = "Blox Fruits  •  v5.3"
subLbl.TextColor3 = MUTED
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 12
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Parent = header

makeDraggable(header, main)

local function windowButton(text, x, tint, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, x, 0, 14)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.AutoButtonColor = false
    b.Parent = header
    glass(b, 0.88, 0.7)
    if tint then b.BackgroundColor3 = tint b.BackgroundTransparency = 0.45 end
    corner(b, UDim.new(1, 0))
    b.Activated:Connect(callback)
    return b
end

-- ===== Плашки: уровень и следующий остров =====
local function infoPill(x, w)
    local pill = Instance.new("Frame")
    pill.Position = UDim2.new(0, x, 0, 58)
    pill.Size = UDim2.new(0, w, 0, 26)
    pill.Parent = main
    glass(pill, 0.88, 0.72)
    corner(pill, UDim.new(0, 13))

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = TEXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Text = ""
    l.Parent = pill
    return l
end

local lvlLabel = infoPill(16, 170)
local nextLabel = infoPill(194, W - 194 - 16)

-- ===== Боковая панель вкладок =====
local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.new(0, 14, 0, 98)
sidebar.Size = UDim2.new(0, 128, 0, H - 98 - 14)
sidebar.BackgroundTransparency = 1
sidebar.Parent = main

local updaters = {}
local orders = {}
local function nextOrder(p)
    orders[p] = (orders[p] or 0) + 1
    return orders[p]
end

local tabNames = {"Combat", "Visuals", "Misc"}
local pages = {}
local tabButtons = {}
local currentTab = "Combat"

for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 38)
    b.Position = UDim2.new(0, 0, 0, (i - 1) * 46)
    b.Text = name
    b.TextColor3 = TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.Parent = sidebar
    glass(b, 0.9, 0.8)
    corner(b, UDim.new(0, 12))
    tabButtons[name] = b
end

local hint = Instance.new("TextLabel")
hint.Position = UDim2.new(0, 0, 1, -34)
hint.Size = UDim2.new(1, 0, 0, 32)
hint.BackgroundTransparency = 1
hint.Text = T("hint")
hint.TextColor3 = MUTED
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = sidebar

-- ===== Страницы =====
local CONTENT_X, CONTENT_Y = 152, 98
local CONTENT_W = W - CONTENT_X - 14
local CONTENT_H = H - CONTENT_Y - 14 - 34

local function makePage(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name
    sf.Position = UDim2.new(0, CONTENT_X, 0, CONTENT_Y)
    sf.Size = UDim2.new(0, CONTENT_W, 0, CONTENT_H)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = ACCENT
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible = false
    sf.Parent = main

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 8)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = sf

    local pd = Instance.new("UIPadding")
    pd.PaddingRight = UDim.new(0, 6)
    pd.PaddingBottom = UDim.new(0, 4)
    pd.Parent = sf

    pages[name] = sf
    return sf
end

local combatPage = makePage("Combat")
local visualsPage = makePage("Visuals")
local miscPage = makePage("Misc")

local function setTab(name)
    currentTab = name
    for n, p in pairs(pages) do p.Visible = (n == name) end
    refreshGui()
end

for name, b in pairs(tabButtons) do
    b.Activated:Connect(function() setTab(name) end)
end

table.insert(updaters, function()
    for name, b in pairs(tabButtons) do
        local sel = (name == currentTab)
        b.BackgroundColor3 = sel and ACCENT or Color3.new(1, 1, 1)
        b.BackgroundTransparency = sel and 0.15 or 0.9
    end
end)

-- ===== Элементы интерфейса =====
local function sectionLabel(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = MUTED
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = nextOrder(parent)
    l.Parent = parent
end

local function makeToggle(parent, text, hotkey, getFn, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = nextOrder(parent)
    row.Parent = parent
    glass(row, 0.9, 0.8)
    corner(row, UDim.new(0, 12))

    local label = Instance.new("TextLabel")
    label.Position = UDim2.new(0, 14, 0, 0)
    label.Size = UDim2.new(1, -76, 1, 0)
    label.BackgroundTransparency = 1
    label.RichText = true
    label.Text = text .. (hotkey ~= "" and ('  <font color="#9a9cc0" size="11">' .. hotkey .. "</font>") or "")
    label.TextColor3 = TEXT
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 22)
    pill.Position = UDim2.new(1, -52, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(110, 112, 140)
    pill.BackgroundTransparency = 0.4
    pill.BorderSizePixel = 0
    pill.Parent = row
    corner(pill, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    corner(knob, UDim.new(1, 0))

    row.Activated:Connect(callback)

    local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    table.insert(updaters, function()
        local on = getFn()
        TweenService:Create(pill, info, {
            BackgroundColor3 = on and ACCENT or Color3.fromRGB(110, 112, 140),
            BackgroundTransparency = on and 0.05 or 0.4,
        }):Play()
        TweenService:Create(knob, info, {
            Position = on and UDim2.new(0, 20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
    end)
end

local function makeSegment(parent, labels, getIdx, onSelect, isSel)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder(parent)
    row.Parent = parent

    local n = #labels
    local buttons = {}
    for i = 1, n do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1 / n, -6, 1, 0)
        b.Position = UDim2.new((i - 1) / n, 3, 0, 0)
        b.AutoButtonColor = false
        b.Text = labels[i]
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 13
        b.TextColor3 = TEXT
        b.Parent = row
        glass(b, 0.9, 0.8)
        corner(b, UDim.new(0, 10))
        b.Activated:Connect(function() onSelect(i) end)
        buttons[i] = b
    end

    table.insert(updaters, function()
        for i, b in ipairs(buttons) do
            local sel
            if isSel then sel = isSel(i) else sel = (i == getIdx()) end
            b.BackgroundColor3 = sel and ACCENT or Color3.new(1, 1, 1)
            b.BackgroundTransparency = sel and 0.15 or 0.9
        end
    end)
end

local function makeButton(parent, getText, getActive, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 40)
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Color3.new(1, 1, 1)
    b.LayoutOrder = nextOrder(parent)
    b.Parent = parent
    glass(b, 0.9, 0.7)
    corner(b, UDim.new(0, 12))
    b.Activated:Connect(callback)

    table.insert(updaters, function()
        b.Text = getText()
        local on = getActive()
        b.BackgroundColor3 = on and GOOD or ACCENT
        b.BackgroundTransparency = on and 0.25 or 0.35
    end)
end

local function makeInfo(parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.TextColor3 = MUTED
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Text = ""
    l.LayoutOrder = nextOrder(parent)
    l.Parent = parent
    return l
end

-- ===== Вкладка Combat =====
sectionLabel(combatPage, T("sec_farm"))
makeToggle(combatPage, T("tg_autofarm"), "F4", function() return state.autoFarm end, toggleFarm)
makeToggle(combatPage, "Fast Attack", "F6", function() return state.fastAttack end, toggleFast)
sectionLabel(combatPage, T("sec_weapon"))
makeSegment(combatPage, {"Melee", "Sword", "Fruit"}, function() return weaponIndex end, setWeapon)
sectionLabel(combatPage, T("sec_farm_height"))
makeSegment(combatPage, {"20", "30", "45", "60"}, function() return farmHeightIndex end, setFarmHeight)

-- ===== Вкладка Visuals =====
sectionLabel(visualsPage, "ESP")
makeToggle(visualsPage, "ESP Fruits", "F2", function() return state.espFruits end, toggleFruitESP)
makeToggle(visualsPage, "ESP Players", "", function() return state.espPlayers end, togglePlayerESP)

-- ===== Вкладка Misc =====
sectionLabel(miscPage, T("sec_auto"))
makeToggle(miscPage, "Auto Factory Core", "", function() return state.autoFactory end, toggleFactory)
makeToggle(miscPage, T("tg_gacha"), "", function() return state.autoGacha end, toggleGacha)
local gachaInfo = makeInfo(miscPage)
makeToggle(miscPage, "Auto Store Fruit", "", function() return state.autoStore end, toggleStore)
local storeInfo = makeInfo(miscPage)

sectionLabel(miscPage, T("sec_stats"))
makeToggle(miscPage, T("tg_split"), "", function() return state.splitStats end, toggleSplit)
makeSegment(miscPage, STAT_LABELS, function() return statIndex end, setStat, function(i)
    if state.splitStats then return splitSel[i] == true end
    return statIndex == i
end)
makeButton(miscPage,
    function() return state.autoStats and T("btn_stop_stats") or T("btn_start_stats") end,
    function() return state.autoStats end,
    toggleStats)
local statsInfo = makeInfo(miscPage)

sectionLabel(miscPage, T("sec_cruise"))
makeSegment(miscPage, {"80", "150", "250"}, function() return cruiseIndex end, setCruiseHeight)

sectionLabel(miscPage, T("sec_misc"))
makeToggle(miscPage, T("tg_flyfruit"), "F3", function() return flying end, flyToNearestFruit)
makeToggle(miscPage, T("tg_blur"), "", function() return state.blur end, toggleBlur)

-- ===== Строка статуса =====
local statusRow = Instance.new("Frame")
statusRow.Position = UDim2.new(0, CONTENT_X, 1, -14 - 26)
statusRow.Size = UDim2.new(0, CONTENT_W, 0, 26)
statusRow.Parent = main
glass(statusRow, 0.88, 0.75)
corner(statusRow, UDim.new(0, 13))

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
    for _, update in ipairs(updaters) do update() end
    dot.BackgroundColor3 = (state.autoFarm or state.autoFactory) and GOOD or MUTED
end

-- ===== Кружок VH (когда меню скрыто) =====
local circle = Instance.new("TextButton")
circle.Size = UDim2.new(0, 52, 0, 52)
circle.Position = main.Position
circle.BackgroundColor3 = Color3.new(1, 1, 1)
circle.BackgroundTransparency = 0.15
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
circleStroke.Transparency = 0.5
circleStroke.Parent = circle

local function setGuiVisible(v)
    if v then
        main.Position = circle.Position
    else
        circle.Position = main.Position
    end
    main.Visible = v
    circle.Visible = not v
    applyBlur()
end

makeDraggable(circle, circle, function() setGuiVisible(true) end)

local function killAll()
    alive = false
    state.autoFarm, state.fastAttack = false, false
    state.espFruits, state.espPlayers = false, false
    state.autoFactory, state.autoStats, state.autoGacha = false, false, false
    state.autoStore = false
    stopFlying()
    stopFarmPhysics()
    clearFruitESP()
    clearPlayerESP()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() blur:Destroy() end)
    gui:Destroy()
    notify(T("killed"))
end

windowButton("-", -76, nil, function() setGuiVisible(false) end)
windowButton("X", -40, RED, killAll)

-- ===== Фоновые обновления интерфейса =====
task.spawn(function()
    while alive do
        local lvl = getPlayerLevel()
        lvlLabel.Text = T("lvl_label") .. lvl
        nextLabel.Text = T("next_label") .. nextIslandText(lvl)
        local names = {}
        if state.splitStats then
            for i = 1, #STAT_LABELS do
                if splitSel[i] then names[#names + 1] = STAT_LABELS[i] end
            end
        else
            names[1] = STAT_LABELS[statIndex]
        end
        statsInfo.Text = T("stats_info", getPoints(), table.concat(names, " + "))
        storeInfo.Text = T("storage_info") .. storeStatus
        gachaInfo.Text = T("gacha_info") .. gachaStatus
        status.Text = statusText
        task.wait(0.5)
    end
end)

-- ESP-циклы
task.spawn(function()
    while alive do
        if state.espFruits then updateFruitESP() end
        task.wait(2)
    end
end)

task.spawn(function()
    while alive do
        if state.espPlayers then pcall(updatePlayerESP) end
        task.wait(0.5)
    end
end)

-- ================= Горячие клавиши =================
track(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    local k = input.KeyCode

    if k == Enum.KeyCode.F2 then toggleFruitESP()
    elseif k == Enum.KeyCode.F3 then flyToNearestFruit()
    elseif k == Enum.KeyCode.F4 then toggleFarm()
    elseif k == Enum.KeyCode.F5 then setWeapon(weaponIndex % #WEAPONS + 1)
    elseif k == Enum.KeyCode.F6 then toggleFast()
    elseif k == Enum.KeyCode.RightShift then setGuiVisible(not main.Visible)
    end
end))

setTab("Combat")
applyBlur()
notify(T("loaded"))
