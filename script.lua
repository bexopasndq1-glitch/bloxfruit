-- Blox Fruits utility script v4 (запускать через executor)
-- F1 автоклик | F2 ESP фруктов | F3 полёт к фрукту
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
local FARM_HEIGHT = 9        -- высота зависания над мобом
local FARM_APPROACH = 80     -- дальше этого расстояния сначала подлетаем
local LEVEL_WINDOW = 100     -- фармим мобов с уровнем от (мой - окно) до (мой)
local WEAPONS = {"Melee", "Sword", "Blox Fruit"}
local FRUIT_KEYS = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
-- =====================

local alive = true           -- false после "Убить GUI": все циклы завершаются
local connections = {}
local function track(c) table.insert(connections, c) return c end

local weaponIndex = 1
local flying = false
local currentTween
local noclipConn
local statusText = "Ожидание"

local state = {
    autoClick = false,
    fastAttack = false,
    esp = false,
    autoFarm = false,
}

local refreshGui = function() end

local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Script", Text = text, Duration = 3,
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
-- Один и тот же цикл работает для: Fast Attack, Автоклика и Автофарма (Melee/Sword)
task.spawn(function()
    while alive do
        local farmClick = state.autoFarm and WEAPONS[weaponIndex] ~= "Blox Fruit"
        if state.autoClick or state.fastAttack or farmClick then
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(1280, 672))
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new(1280, 672))
        end
        task.wait(0.1)
    end
end)

-- ================= Автофарм по уровню =================
local farmNoclip
local farmTween

local function getPlayerLevel()
    local data = player:FindFirstChild("Data")
    local lvl = data and data:FindFirstChild("Level")
    return lvl and lvl.Value or 1
end

-- Уровень моба берём из имени вида "Bandit [Lv. 5]"
local function getMobLevel(mob)
    local hum = mob:FindFirstChildOfClass("Humanoid")
    local s = (hum and hum.DisplayName or "") .. " " .. mob.Name
    local lv = s:match("%[Lv%.%s*(%d+)%]")
    return lv and tonumber(lv) or nil
end

local function pickEnemy()
    local folder = Workspace:FindFirstChild("Enemies")
    local root = getRoot()
    if not folder or not root then return end

    local myLevel = getPlayerLevel()
    local best, bestDist = nil, math.huge
    local fallback, fallbackDist = nil, math.huge

    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local mroot = mob:FindFirstChild("HumanoidRootPart")
        if hum and mroot and hum.Health > 0 then
            local dist = (mroot.Position - root.Position).Magnitude
            local lv = getMobLevel(mob)

            if lv and lv <= myLevel and lv >= myLevel - LEVEL_WINDOW then
                if dist < bestDist then best, bestDist = mob, dist end
            end
            if dist < fallbackDist then fallback, fallbackDist = mob, dist end
        end
    end

    if best then return best, bestDist end
    return fallback, fallbackDist
end

local function equipWeapon()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
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

-- Скиллы фрукта (для Melee/Sword бьёт общий клик-цикл выше)
local function fruitSkills()
    for _, key in ipairs(FRUIT_KEYS) do
        if not (alive and state.autoFarm) then return end
        VIM:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, key, false, game)
        task.wait(0.1)
    end
end

task.spawn(function()
    while alive do
        if state.autoFarm then
            local root = getRoot()
            local mob, dist = pickEnemy()

            if root and mob then
                startFarmPhysics()
                equipWeapon()

                local mroot = mob:FindFirstChild("HumanoidRootPart")
                local hum = mob:FindFirstChildOfClass("Humanoid")

                if mroot and hum and hum.Health > 0 then
                    statusText = ("%s | мой lvl %d"):format(mob.Name, getPlayerLevel())

                    if dist > FARM_APPROACH then
                        farmTween = TweenService:Create(
                            root,
                            TweenInfo.new(dist / FLY_SPEED, Enum.EasingStyle.Linear),
                            {CFrame = mroot.CFrame + Vector3.new(0, FARM_HEIGHT, 0)}
                        )
                        farmTween:Play()
                        farmTween.Completed:Wait()
                        farmTween = nil
                    end

                    local conn
                    conn = RunService.Heartbeat:Connect(function()
                        local r = getRoot()
                        if alive and r and mroot.Parent and hum.Health > 0 and state.autoFarm then
                            local pos = mroot.Position + Vector3.new(0, FARM_HEIGHT, 0)
                            r.CFrame = CFrame.new(pos, mroot.Position)
                        else
                            conn:Disconnect()
                        end
                    end)

                    while alive and state.autoFarm and mroot.Parent and hum.Health > 0 do
                        if WEAPONS[weaponIndex] == "Blox Fruit" then
                            fruitSkills()
                        end
                        task.wait()
                    end
                    if conn then conn:Disconnect() end
                end
            else
                statusText = "Мобов нет, жду"
                task.wait(1)
            end
        else
            statusText = "Автофарм выкл"
            stopFarmPhysics()
            task.wait(0.3)
        end
        task.wait()
    end
    stopFarmPhysics()
end)

task.spawn(function()
    while alive do
        if state.esp then updateESP() end
        task.wait(2)
    end
end)

-- ================= Действия =================
local function toggleAutoClick()
    state.autoClick = not state.autoClick
    refreshGui()
end

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

-- ================= GUI =================
local ON = Color3.fromRGB(46, 160, 90)
local OFF = Color3.fromRGB(60, 60, 70)
local SEL = Color3.fromRGB(70, 110, 220)
local RED = Color3.fromRGB(190, 60, 60)

local gui = Instance.new("ScreenGui")
gui.Name = "BFUtilGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okParent or not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 368)
frame.Position = UDim2.new(0, 20, 0.5, -184)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
title.BorderSizePixel = 0
title.Text = "Blox Fruits Utility"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- Универсальное перетаскивание. Если сдвиг меньше 6px, считается кликом.
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

makeDraggable(title, frame)

local function makeButton(text, x, y, w, callback, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 30)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = color or OFF
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.AutoButtonColor = true
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.Activated:Connect(callback)
    return b
end

local btnFarm  = makeButton("Автофарм (F4)", 10, 38, 200, toggleFarm)
local btnFast  = makeButton("Fast Attack (F6)", 10, 74, 200, toggleFast)
local btnClick = makeButton("Автоклик (F1)", 10, 110, 200, toggleAutoClick)
local btnESP   = makeButton("ESP фруктов (F2)", 10, 146, 200, toggleESP)
local btnFly   = makeButton("Полёт к фрукту (F3)", 10, 182, 200, flyToNearestFruit)

local wLabel = Instance.new("TextLabel")
wLabel.Size = UDim2.new(1, 0, 0, 18)
wLabel.Position = UDim2.new(0, 0, 0, 220)
wLabel.BackgroundTransparency = 1
wLabel.Text = "Оружие (F5)"
wLabel.TextColor3 = Color3.fromRGB(190, 190, 200)
wLabel.Font = Enum.Font.Gotham
wLabel.TextSize = 12
wLabel.Parent = frame

local weaponButtons = {}
local labels = {"Melee", "Sword", "Fruit"}
for i = 1, 3 do
    weaponButtons[i] = makeButton(labels[i], 10 + (i - 1) * 68, 240, 64, function() setWeapon(i) end)
end

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 36)
status.Position = UDim2.new(0, 10, 0, 278)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextColor3 = Color3.fromRGB(190, 190, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Text = ""
status.Parent = frame

refreshGui = function()
    btnFarm.BackgroundColor3 = state.autoFarm and ON or OFF
    btnFast.BackgroundColor3 = state.fastAttack and ON or OFF
    btnClick.BackgroundColor3 = state.autoClick and ON or OFF
    btnESP.BackgroundColor3 = state.esp and ON or OFF
    btnFly.BackgroundColor3 = flying and ON or OFF
    for i, b in ipairs(weaponButtons) do
        b.BackgroundColor3 = (i == weaponIndex) and SEL or OFF
    end
end
refreshGui()

-- Кружок, который появляется при скрытии окна: двигается, по клику открывает GUI
local circle = Instance.new("TextButton")
circle.Size = UDim2.new(0, 46, 0, 46)
circle.Position = frame.Position
circle.BackgroundColor3 = SEL
circle.BorderSizePixel = 0
circle.Text = "BF"
circle.TextColor3 = Color3.new(1, 1, 1)
circle.Font = Enum.Font.GothamBold
circle.TextSize = 14
circle.AutoButtonColor = false
circle.Active = true
circle.Visible = false
circle.Parent = gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

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

-- Кнопки внизу окна: Скрыть и Убить
makeButton("Скрыть GUI", 10, 326, 96, function() setGuiVisible(false) end)

local function killAll()
    alive = false
    state.autoFarm, state.autoClick, state.fastAttack, state.esp = false, false, false, false
    stopFlying()
    stopFarmPhysics()
    clearESP()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
    notify("Скрипт остановлен, GUI удалён")
end

makeButton("Убить GUI", 114, 326, 96, killAll, RED)

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

    if k == Enum.KeyCode.F1 then toggleAutoClick()
    elseif k == Enum.KeyCode.F2 then toggleESP()
    elseif k == Enum.KeyCode.F3 then flyToNearestFruit()
    elseif k == Enum.KeyCode.F4 then toggleFarm()
    elseif k == Enum.KeyCode.F5 then setWeapon(weaponIndex % #WEAPONS + 1)
    elseif k == Enum.KeyCode.F6 then toggleFast()
    elseif k == Enum.KeyCode.RightShift then setGuiVisible(not frame.Visible)
    end
end))

notify("Загружено. RightShift или кнопка «Скрыть GUI» — спрятать меню")