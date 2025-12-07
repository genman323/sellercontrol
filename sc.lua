local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game.Workspace
local TextChatService = game:GetService("TextChatService")
local Chat = game:GetService("Chat")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

if game.PlaceId ~= 2788229376 and game.PlaceId ~= 12076775711 then
    LocalPlayer:Kick("Wrong game")
    return
end

if getgenv().script_key ~= "qCqkyJnsIdGuValXkmeYLEcN" or not getgenv().host or getgenv().host == "" then
    LocalPlayer:Kick("Invalid")
    return
end

local dropping = false
local dropConnection = nil
local flyConnection = nil
local safeConnection = nil
local guardConnection = nil
local lastSafePos = nil
local isSafe = false
local isGuarding = false
local lastShot = 0
local lastReload = 0
local targetSwitchTime = 0
local currentTarget = nil

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local prefix = "."

local daHoodSpots = {
    club = Vector3.new(-264.9,-6.2,-374.9),
    bank = Vector3.new(-375,16,-286),
    boxing = Vector3.new(-263,53,-1129),
    basket = Vector3.new(-932,21.9,-483),
    soccer = Vector3.new(-749,18.2,-485),
    cell = Vector3.new(-295,18,-111),
    cell2 = Vector3.new(-295,19,-68),
    school = Vector3.new(-654,18,256),
    train = Vector3.new(636,42,-80)
}

local function hideCam()
    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.new(0,-5000000,0)
    task.spawn(function()
        while task.wait(110 + math.random(-50,70)) do
            local mouse = LocalPlayer:GetMouse()
            if mouse then
                mousemoverel(2,0)
                task.wait(0.1)
                mousemoverel(-2,0)
            end
        end
    end)
end

local function stopAllMovement()
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if safeConnection then safeConnection:Disconnect() safeConnection = nil end
    if guardConnection then guardConnection:Disconnect() guardConnection = nil end
    if humanoid then humanoid.PlatformStand = false end
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = true end
    isSafe = false
    isGuarding = false
end

local function startFly(pos,offset)
    stopAllMovement()
    offset = offset or 0
    for _,v in character:GetDescendants() do
        if v:IsA("BasePart") and not v:IsA("Accessory") then
            v.CanCollide = false
        end
    end
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = false end
    humanoid.PlatformStand = true
    local target = CFrame.new(pos.X,pos.Y-offset,pos.Z) * CFrame.Angles(0,math.pi,0)
    flyConnection = RunService.Heartbeat:Connect(function()
        root.CFrame = target
        root.Velocity = Vector3.new()
    end)
end

local function goSafe()
    if game.PlaceId ~= 12076775711 then return end
    if isSafe then return end
    stopAllMovement()
    lastSafePos = root.Position
    for _,v in character:GetDescendants() do
        if v:IsA("BasePart") and not v:IsA("Accessory") then
            v.CanCollide = false
        end
    end
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = false end
    humanoid.PlatformStand = true
    local skyPos = Vector3.new(root.Position.X, 500000, root.Position.Z)
    safeConnection = RunService.Heartbeat:Connect(function()
        root.CFrame = CFrame.new(skyPos)
        root.Velocity = Vector3.new()
    end)
    isSafe = true
end

local function goUnsafe()
    if not isSafe or not lastSafePos then return end
    stopAllMovement()
    startFly(lastSafePos + Vector3.new(0,4,0), 0)
    task.wait(0.3)
    stopAllMovement()
    root.CFrame = CFrame.new(lastSafePos + Vector3.new(0,4,0))
    task.wait(0.1)
    humanoid.PlatformStand = false
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = true end
end

local function getHostPlayer()
    for _, p in Players:GetPlayers() do
        if p.Name:lower() == getgenv().host:lower() then
            return p
        end
    end
end

local function getHostChar()
    local host = getHostPlayer()
    return host and host.Character
end

local function isLocalPlayerDino()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Dinosaurs"
end

local function getVisibleDinos()
    if isLocalPlayerDino() then return {} end
    local dinos = {}
    local myChar = character
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return dinos end
    local hostChar = getHostChar()
    if not hostChar then return dinos end
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Dinosaurs" and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local targetPart = p.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local origin = myHead.Position
                local dir = (targetPart.Position - origin).Unit * 500
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {myChar, hostChar}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local result = Workspace:Raycast(origin, dir, params)
                if result and result.Instance:IsDescendantOf(p.Character) then
                    table.insert(dinos, p)
                end
            end
        end
    end
    return dinos
end

local function selectTarget(dinos)
    if #dinos == 0 then
        currentTarget = nil
        return nil
    end
    if #dinos == 1 then
        currentTarget = dinos[1]
        return dinos[1]
    end
    local now = tick()
    if now - targetSwitchTime > 2 then
        targetSwitchTime = now
        currentTarget = dinos[math.random(1, #dinos)]
    end
    return currentTarget
end

local offset = Vector3.new(math.sin(LocalPlayer.UserId % 100), 0, math.cos(LocalPlayer.UserId % 100)) * 5

local function guardingFunction()
    if isLocalPlayerDino() then return end

    local hostChar = getHostChar()
    if not hostChar or not hostChar:FindFirstChild("Humanoid") or hostChar.Humanoid.Health <= 0 then
        return
    end

    if not character or not humanoid or humanoid.Health <= 0 then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        task.wait(0.4)
    end

    local hostRoot = hostChar:FindFirstChild("HumanoidRootPart")
    if not hostRoot then return end

    local targetPos = hostRoot.Position + offset + Vector3.new(0, 3, 0)

    local dinos = getVisibleDinos()
    local target = selectTarget(dinos)

    local lookAtPos
    if target then
        local targetPart = target.Character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            lookAtPos = targetPart.Position
            local now = tick()
            if now - lastShot > 0.3 then
                lastShot = now
                if tool then tool:Activate() end
            end
            if now - lastReload > 5.5 then
                lastReload = now
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
            end
        end
    else
        local outDir = (targetPos - hostRoot.Position).unit
        lookAtPos = targetPos + outDir * 30
    end

    local targetCFrame = CFrame.lookAt(targetPos, lookAtPos)
    root.CFrame = targetCFrame
    root.Velocity = Vector3.new()

    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 2, 0), lookAtPos)

    for _, v in character:GetDescendants() do
        if v:IsA("BasePart") and not v:IsA("Accessory") then
            v.CanCollide = false
        end
    end
    local anim = character:FindFirstChild("Animate")
    if anim then anim.Enabled = false end
    humanoid.PlatformStand = true
end

local function goGuard()
    if game.PlaceId ~= 12076775711 or isLocalPlayerDino() then return end
    stopAllMovement()
    isGuarding = true
    if not guardConnection then
        guardConnection = RunService.Heartbeat:Connect(guardingFunction)
    end
end

local function goUnguard()
    isGuarding = false
    stopAllMovement()
    if humanoid then
        humanoid.Health = 0
    end
end

local function dropMoney()
    if game.PlaceId ~= 2788229376 then return end
    dropping = true
    if dropConnection then dropConnection:Disconnect() end
    dropConnection = RunService.Heartbeat:Connect(function()
        if dropping then
            ReplicatedStorage.MainEvent:FireServer("DropMoney",15000)
        else
            if dropConnection then dropConnection:Disconnect() dropConnection = nil end
        end
    end)
end

local function process(msg)
    if type(msg) ~= "string" then return end
    msg = msg:lower()
    if not msg:startswith(prefix) then return end
    local cmd = msg:sub(#prefix+1):match("^%s*(.-)%s*$")

    if game.PlaceId == 2788229376 then
        if cmd == "start" then dropMoney()
        elseif cmd == "stop" then dropping = false
        elseif cmd:find("^s%s+(.+)") then
            local spot = cmd:match("^s%s+(.+)")
            if daHoodSpots[spot] then
                startFly(daHoodSpots[spot],2.8)
            end
        end

    elseif game.PlaceId == 12076775711 then
        if cmd == "safe" then
            goSafe()
        elseif cmd == "unsafe" then
            goUnsafe()
        elseif cmd == "guard" then
            goGuard()
        elseif cmd == "unguard" then
            goUnguard()
        end
    end
end

local function onMessage(player,text)
    if player and player.Name:lower() == getgenv().host:lower() then
        pcall(process,text)
    end
end

if TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
    TextChatService.TextChannels.RBXGeneral.MessageReceived:Connect(function(m)
        if m.TextSource then
            local p = Players:GetPlayerByUserId(m.TextSource.UserId)
            if p then onMessage(p,m.Text) end
        end
    end)
end

Chat.Chatted:Connect(function(plr,msg)
    onMessage(plr,msg)
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    character = c
    root = c:WaitForChild("HumanoidRootPart")
    humanoid = c:WaitForChild("Humanoid")
    stopAllMovement()
    hideCam()
    task.wait(1)
    if isGuarding and not isLocalPlayerDino() then
        guardConnection = RunService.Heartbeat:Connect(guardingFunction)
    end
end)

hideCam()

if game.PlaceId == 2788229376 then
    print("SellerControl Loaded [Da Hood]")
elseif game.PlaceId == 12076775711 then
    print("SellerControl Loaded [Primal Pursuit]")
end

return {
    Begin = function() end,
    Init = function() end,
    Load = function() end,
    Start = function() end,
    Show = function() end
}
