if game.PlaceId ~= 2788229376 then
	game:GetService("Players").LocalPlayer:Kick("wrong game retard")
	return
end

local function check()
	return getgenv().script_key == "qCqkyJnsIdGuValXkmeYLEcN" and getgenv().host and getgenv().host ~= ""
end

if not check() then
	game:GetService("Players").LocalPlayer:Kick("hi")
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ChatService = game:GetService("Chat")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local prefix = "."
local moving = nil
local connection = nil
local dropping = false
local dropConn = nil

local function hideCamera()
	local cam = Workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.new(0, -5000000, 0)
end

local function antiAFK()
	hideCamera()
	task.spawn(function()
		while task.wait(120 + math.random(-40, 70)) do
			if not player.Parent then break end
			pcall(function()
				local mouse = player:GetMouse()
				VirtualInputManager:SendMouseMoveEvent(mouse.X + 3, mouse.Y, false)
				task.wait(0.12)
				VirtualInputManager:SendMouseMoveEvent(mouse.X - 3, mouse.Y, false)
			end)
		end
	end)
end

local function stopMove()
	if humanoid then humanoid.PlatformStand = false end
	if root then root.Velocity = Vector3.new(0,0,0) end
	if connection then connection:Disconnect() connection = nil end
	local anim = character:FindFirstChild("Animate")
	if anim then anim.Enabled = true end
	moving = nil
end

local function goto(pos, offsetY)
	stopMove()
	if not root or not humanoid then return end
	offsetY = offsetY or 0
	local target = Vector3.new(pos.X, pos.Y - offsetY, pos.Z)

	for _, v in character:GetDescendants() do
		if v:IsA("BasePart") and v ~= root then
			v.CanCollide = false
		end
	end

	local anim = character:FindFirstChild("Animate")
	if anim then anim.Enabled = false end

	root.CFrame = CFrame.new(target) * CFrame.Angles(0, math.pi, 0)
	humanoid.PlatformStand = true
	moving = "active"

	connection = RunService.Heartbeat:Connect(function()
		if moving == "active" and root then
			root.CFrame = CFrame.new(target) * CFrame.Angles(0, math.pi, 0)
			root.Velocity = Vector3.new(0,0,0)
			root.AssemblyLinearVelocity = Vector3.new(0,0,0)
			root.AssemblyAngularVelocity = Vector3.new(0,0,0)
		end
	end)
end

local locations = {
	club = Vector3.new(-264.9, -6.2, -374.9),
	bank = Vector3.new(-375, 16, -286),
	boxingclub = Vector3.new(-263, 50.2, -1129),
	basketball = Vector3.new(-932, 16.9, -483),
	soccer = Vector3.new(-749, 18.2, -485),
	cell = Vector3.new(-295, 18, -111),
	cell2 = Vector3.new(-295, 19, -68),
	school = Vector3.new(-654, 18, 256),
	train = Vector3.new(636, 42, -80)
}

local function dropMoney()
	if not dropping then return end
	game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", 15000)
	dropConn = RunService.Heartbeat:Connect(function()
		if dropping then
			game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", 15000)
		else
			if dropConn then dropConn:Disconnect() end
		end
	end)
end

local function process(msg)
	if type(msg) ~= "string" then return end
	msg = msg:lower()
	if not msg:startswith(prefix) then return end

	local cmd = msg:sub(#prefix + 1):match("^%s*(.-)%s*$")
	if cmd == "" then return end

	if cmd:match("^s%s+(.+)") then
		local place = cmd:match("^s%s+(.+)")
		if locations[place] then
			goto(locations[place], 2.8)
		end
	elseif cmd == "start" then
		dropping = true
		dropMoney()
	elseif cmd == "stop" then
		dropping = false
	end
end

player.CharacterAdded:Connect(function(char)
	character = char
	root = char:WaitForChild("HumanoidRootPart")
	humanoid = char:WaitForChild("Humanoid")
	antiAFK()
	humanoid.Died:Connect(hideCamera)
end)

local channel = TextChatService.TextChannels and (TextChatService.TextChannels.RBXGeneral or TextChatService.TextChannels.RBXSystem)
if channel then
	channel.MessageReceived:Connect(function(message)
		if message.TextSource then
			local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
			if sender and sender.Name:lower() == getgenv().host:lower() then
				process(message.Text)
			end
		end
	end)
end

ChatService.Chatted:Connect(function(plr, text)
	if plr and plr.Name:lower() == getgenv().host:lower() then
		process(text)
	end
end)

antiAFK()
