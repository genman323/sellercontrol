if game.PlaceId ~= 2788229376 then
    game:GetService('Players').LocalPlayer:Kick('wrong game retard')
    return
end
local env = getgenv()
local requiredKey = 'qCqkyJnsIdGuValXkmeYLEcN'
local hostVar = env.host
local scriptKey = env.script_key
local function isValid()
    return scriptKey == requiredKey and hostVar and hostVar ~= ''
end
if not isValid() then
    game:GetService('Players').LocalPlayer:Kick('hi')
    return
end
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService('RunService')
local TextChatService = game:GetService('TextChatService')
local ChatService = game:GetService('Chat')
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local root = character:WaitForChild('HumanoidRootPart')
local humanoid = character:WaitForChild('Humanoid')
local currentSetup = nil
local prefix = '.'
local connections = {setup = nil}
local isDropping = false
local dropConn = nil
local function safeSetCameraFar()
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.new(0, -5000000, 0)
end
local function resetState()
    if root then root.Velocity = Vector3.zero end
    if humanoid then humanoid.PlatformStand = false end
    local animate = character:FindFirstChild('Animate')
    if animate then animate.Enabled = true end
    if connections.setup then
        connections.setup:Disconnect()
        connections.setup = nil
    end
    currentSetup = nil
end
local function prepCharacter()
    if not root or not character or not humanoid then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA('BasePart') and not part:IsA('Accessory') then
            part.CanCollide = false
        end
    end
    local animate = character:FindFirstChild('Animate')
    if animate then animate.Enabled = false end
end
local function moveToFixed(pos, offsetY)
    prepCharacter()
    offsetY = offsetY or 0
    local targetY = pos.Y - offsetY
    local target = Vector3.new(pos.X, targetY, pos.Z)
    local targetCFrame = CFrame.new(target) * CFrame.Angles(0, math.pi, 0)
    root.CFrame = targetCFrame
    root.Velocity = Vector3.zero
    humanoid.PlatformStand = true
    currentSetup = 'fixed'
    connections.setup = RunService.Heartbeat:Connect(function()
        if currentSetup == 'fixed' and root then
            root.CFrame = targetCFrame
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            humanoid.PlatformStand = true
        end
    end)
end
local function moveToHost()
    prepCharacter()
    humanoid.PlatformStand = true
    currentSetup = 'host'
    connections.setup = RunService.Heartbeat:Connect(function()
        if currentSetup == 'host' and root then
            local hostPlayer = Players:FindFirstChild(hostVar)
            if hostPlayer and hostPlayer.Character and hostPlayer.Character:FindFirstChild('HumanoidRootPart') then
                local hostPos = hostPlayer.Character.HumanoidRootPart.Position
                local targetY = hostPos.Y - 2.8
                local target = Vector3.new(hostPos.X, targetY, hostPos.Z)
                local targetCFrame = CFrame.new(target) * CFrame.Angles(0, math.pi, 0)
                root.CFrame = targetCFrame
            end
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            humanoid.PlatformStand = true
        end
    end)
end
local locations = {
    club = function() resetState() moveToFixed(Vector3.new(-264.9, -6.2, -374.9), 2.8) end,
    bank = function() resetState() moveToFixed(Vector3.new(-375, 16, -286), 2.8) end,
    boxingclub = function() resetState() moveToFixed(Vector3.new(-263, 53 - 2.8, -1129), 2.8) end,
    basketball = function() resetState() moveToFixed(Vector3.new(-932, 21 - 5 + 0.3 + 0.6, -483), 2.8) end,
    soccer = function() resetState() moveToFixed(Vector3.new(-749, 22 - 5 + 1.2, -485), 2.8) end,
    cell = function() resetState() moveToFixed(Vector3.new(-295, 21 - 3, -111), 2.8) end,
    cell2 = function() resetState() moveToFixed(Vector3.new(-295, 22 - 3, -68), 2.8) end,
    school = function() resetState() moveToFixed(Vector3.new(-654, 21 - 3, 256), 2.8) end,
    train = function() resetState() moveToFixed(Vector3.new(636, 47 - 5, -80), 2.8) end,
    host = function() resetState() moveToHost() end,
}
local function startDrop()
    if isDropping then
        local args = { 'DropMoney', 15000 }
        game:GetService('ReplicatedStorage').MainEvent:FireServer(unpack(args))
        dropConn = RunService.Heartbeat:Connect(function()
            if isDropping then
                game:GetService('ReplicatedStorage').MainEvent:FireServer(unpack(args))
            else
                if dropConn then dropConn:Disconnect() end
            end
        end)
    end
end
local function handleCommand(msg)
    if not msg or type(msg) ~= 'string' then return end
    local text = msg:lower()
    if text:sub(1, #prefix) ~= prefix then return end
    local cmd = text:sub(#prefix + 1):match('^%s*(.-)%s*$')
    if not cmd or cmd == '' then return end
    local loc = cmd:match('^setup%s+(.+)$')
    if loc and locations[loc] then
        locations[loc]()
        return
    end
    if cmd == 'setup' then
        locations.host()
        return
    end
    if cmd == 'start' then
        isDropping = true
        startDrop()
    elseif cmd == 'stop' then
        isDropping = false
        if dropConn then dropConn:Disconnect() end
    end
end
local function onCharacterAdded(char)
    character = char
    root = char:WaitForChild('HumanoidRootPart')
    humanoid = char:WaitForChild('Humanoid')
    if root and humanoid then
        safeSetCameraFar()
        humanoid.Died:Connect(function()
            local cam = workspace.CurrentCamera
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.new(0, -5000000, 0)
        end)
    end
end
local channel = TextChatService and TextChatService.TextChannels and
    (TextChatService.TextChannels.RBXGeneral or TextChatService.TextChannels.RBXSystem)
if channel then
    channel.MessageReceived:Connect(function(msg)
        if msg.TextSource then
            local sender = Players:GetPlayerByUserId(msg.TextSource.UserId)
            if sender and sender.Name:lower() == hostVar:lower() then
                handleCommand(msg.Text)
            end
        end
    end)
end
ChatService.Chatted:Connect(function(player, message)
    if player and player.Name:lower() == hostVar:lower() then
        handleCommand(message)
    end
end)
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
safeSetCameraFar()
pcall(function()
    settings().Rendering.QualityLevel = 1
    settings().Physics.AllowSleep = true
end)
pcall(setfpscap, 15)
