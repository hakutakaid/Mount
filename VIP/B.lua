-- ✅ GUI FIXED FOR PC (SOLARA) & MOBILE (DELTA)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local hrp
local ROUTE_LINKS = { "https://raw.githubusercontent.com/WataXMenu/WataXSc/refs/heads/main/100.lua" }

local routes, animConn = {}, nil
local isMoving, isReplayRunning = false, false
local frameTime, playbackRate = 1/30, 1
local toggleBtn

------------------------------------------------
-- 🧩 SAFE PARENTING (support Solara/PC)
------------------------------------------------
local function safeParent(gui)
    local success, uiParent = pcall(function()
        if gethui then
            return gethui()
        elseif game:FindFirstChildOfClass("CoreGui") then
            return game.CoreGui
        elseif player:FindFirstChild("PlayerGui") then
            return player.PlayerGui
        else
            return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    gui.Parent = uiParent or player:WaitForChild("PlayerGui")
end

------------------------------------------------
-- 🔁 LOAD ROUTES
------------------------------------------------
for i, link in ipairs(ROUTE_LINKS) do
    if link ~= "" then
        local ok, data = pcall(function()
            return loadstring(game:HttpGet(link))()
        end)
        if ok and typeof(data) == "table" and #data > 0 then
            table.insert(routes, {"Route " .. i, data})
        end
    end
end

if #routes == 0 then
    warn("[HakutakaX] Tidak ada route valid ditemukan.")
    return
end

------------------------------------------------
-- 🧍 CHARACTER SETUP
------------------------------------------------
local function refreshHRP(char)
    char = char or player.Character or player.CharacterAdded:Wait()
    hrp = char:WaitForChild("HumanoidRootPart")
end
player.CharacterAdded:Connect(refreshHRP)
if player.Character then refreshHRP(player.Character) end

local function stopMovement() isMoving = false end
local function startMovement() isMoving = true end

------------------------------------------------
-- 🧭 ROUTE + MOVEMENT CODE (sama seperti punyamu)
------------------------------------------------
-- (Bagian ini tetap sama — tak perlu ubah apa pun)
-- [Kamu bisa paste ulang semua logic pathfinding, runRoute, walkTo, dll di sini]
-- (biar jawaban singkat, saya skip bagian logic movement karena tidak perlu diubah)
local DEFAULT_HEIGHT = 2.9
local function getCurrentHeight()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    return humanoid.HipHeight + (char:FindFirstChild("Head") and char.Head.Size.Y or 2)
end

local function adjustRoute(frames)
    local adjusted = {}
    local offsetY = getCurrentHeight() - DEFAULT_HEIGHT
    for _,cf in ipairs(frames) do
        local pos, rot = cf.Position, cf - cf.Position
        table.insert(adjusted, CFrame.new(Vector3.new(pos.X,pos.Y+offsetY,pos.Z)) * rot)
    end
    return adjusted
end

for i, data in ipairs(routes) do
    data[2] = adjustRoute(data[2])
end

local function getNearestRoute()
    local nearestIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i,data in ipairs(routes) do
            for _,cf in ipairs(data[2]) do
                local d = (cf.Position - pos).Magnitude
                if d < dist then dist=d nearestIdx=i end
            end
        end
    end
    return nearestIdx
end

local function getNearestFrameIndex(frames)
    local startIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i,cf in ipairs(frames) do
            local d = (cf.Position - pos).Magnitude
            if d < dist then dist=d startIdx=i end
        end
    end
    if startIdx >= #frames then startIdx = math.max(1,#frames-1) end
    return startIdx
end


local function lerpCF(fromCF,toCF)
    local duration = frameTime / math.max(0.05,playbackRate)
    local startTime = os.clock()
    local t = 0
    while t < duration and isReplayRunning do
        RunService.Heartbeat:Wait()
        t = os.clock() - startTime
        local alpha = math.min(t/duration,1)
        if hrp and hrp.Parent and hrp:IsDescendantOf(workspace) then
            hrp.CFrame = fromCF:Lerp(toCF,alpha)
        end
    end
end


local function walkTo(targetPos)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not hrp or humanoid.Health <= 0 or not isReplayRunning then return end
    
    local path = PathfindingService:CreatePath()
    local success, err = pcall(function()
        path:ComputeAsync(hrp.Position,targetPos)
    end)
    
    if not success or path.Status ~= Enum.PathStatus.Success then
        warn("[HakutakaX] Gagal membuat path untuk walkTo:", err)
        return
    end
    
    local waypoints = path:GetWaypoints()
    
    if #waypoints > 1 then
        for i = 2, #waypoints do
            local waypoint = waypoints[i]
            if not isReplayRunning or not humanoid or humanoid.Health <= 0 then break end
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait(2) 
        end
    elseif #waypoints == 1 then
        humanoid:MoveTo(targetPos)
        humanoid.MoveToFinished:Wait(2)
    end
end

local function stopRoute()
    isReplayRunning=false
    stopMovement()
end

local function runRoute(startIdx)
    if #routes==0 then return end
    if not hrp then refreshHRP() end
    
    isReplayRunning = true
    stopMovement() 

    local idx = getNearestRoute()
    local frames = routes[idx][2]
    if #frames < 2 then 
        warn("[HakutakaX] Route tidak valid, kurang dari 2 frame.")
        isReplayRunning=false 
        stopMovement()
        return 
    end

    local sIdx = startIdx or getNearestFrameIndex(frames)
    local targetPos = frames[sIdx].Position
    
    walkTo(targetPos) 

    if not isReplayRunning then 
        stopRoute() 
        if toggleBtn and toggleBtn.Parent then
            toggleBtn.Text = "▶" 
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70,200,120)
        end
        return 
    end
    
    startMovement() 

    for i=sIdx,#frames-1 do
        if not isReplayRunning then break end
        lerpCF(frames[i],frames[i+1])
    end

    if isReplayRunning then
        isReplayRunning=false
        stopMovement()
        if toggleBtn and toggleBtn.Parent then
            toggleBtn.Text = "▶" 
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70,200,120)
        end
    end
end
------------------------------------------------
-- 🧱 GUI CREATION (PC compatible)
------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HakutakaXReplayUI"
screenGui.ResetOnSpawn = false
safeParent(screenGui)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 120, 0, 75)
frame.Position = UDim2.new(0.05, 0, 0.75, 0)
frame.BackgroundColor3 = Color3.fromRGB(50, 30, 70)
frame.BackgroundTransparency = 0.3
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local glow = Instance.new("UIStroke")
glow.Parent = frame
glow.Color = Color3.fromRGB(180, 120, 255)
glow.Thickness = 1.5
glow.Transparency = 0.4

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(0.7, 0, 0, 18)
title.Position = UDim2.new(0.05, 0, 0, 3)
title.Text = "MT YAHAYUK"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.BackgroundTransparency = 0.3
title.BackgroundColor3 = Color3.fromRGB(70, 40, 120)
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 6)

-- 🌈 Rainbow title
task.spawn(function()
    local hue = 0
    while screenGui.Parent do
        hue = (hue + 1) % 360
        title.TextColor3 = Color3.fromHSV(hue / 360, 1, 1)
        task.wait(0.05)
    end
end)

-- ❌ Close button
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -21, 0, 3)
closeBtn.Text = "✖"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- ▶️ Toggle button
toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.8, 0, 0.28, 0)
toggleBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
toggleBtn.Text = "▶"
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 120)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
toggleBtn.MouseButton1Click:Connect(function()
    if not isReplayRunning then
        toggleBtn.Text = "■"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        isReplayRunning = true
        task.spawn(function()
            runRoute()
        end)
    else
        toggleBtn.Text = "▶"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 120)
        isReplayRunning = false
        stopMovement()
    end
end)

-- ⏩ Speed controls
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size = UDim2.new(0.35, 0, 0.22, 0)
speedLabel.Position = UDim2.new(0.325, 0, 0.68, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextScaled = true
speedLabel.Text = playbackRate .. "x"

local speedDown = Instance.new("TextButton", frame)
speedDown.Size = UDim2.new(0.2, 0, 0.22, 0)
speedDown.Position = UDim2.new(0.05, 0, 0.68, 0)
speedDown.Text = "-"
speedDown.Font = Enum.Font.GothamBold
speedDown.TextScaled = true
speedDown.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
speedDown.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", speedDown).CornerRadius = UDim.new(0, 4)
speedDown.MouseButton1Click:Connect(function()
    playbackRate = math.max(0.25, playbackRate - 0.25)
    speedLabel.Text = playbackRate .. "x"
end)

local speedUp = Instance.new("TextButton", frame)
speedUp.Size = UDim2.new(0.2, 0, 0.22, 0)
speedUp.Position = UDim2.new(0.75, 0, 0.68, 0)
speedUp.Text = "+"
speedUp.Font = Enum.Font.GothamBold
speedUp.TextScaled = true
speedUp.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
speedUp.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", speedUp).CornerRadius = UDim.new(0, 4)
speedUp.MouseButton1Click:Connect(function()
    playbackRate = math.min(3, playbackRate + 0.25)
    speedLabel.Text = playbackRate .. "x"
end)