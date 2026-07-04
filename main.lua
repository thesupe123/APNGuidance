local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
-- Simulate pressing a key

local missile = nil
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mainheart
-- ==========================================
-- 1. MODERN UI CREATION
-- ==========================================
local playerGui = game.CoreGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissileLockSystem"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Control Frame
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(0, 220, 0, 140)
controlFrame.Position = UDim2.new(0, 20, 0, 50)
controlFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
controlFrame.BorderSizePixel = 0
controlFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = controlFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 1.5
uiStroke.Color = Color3.fromRGB(80, 80, 90)
uiStroke.Parent = controlFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "MISSILE LOCK SYSTEM"
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.Parent = controlFrame

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.9, 0, 0, 45)
toggleButton.Position = UDim2.new(0.05, 0, 0, 45)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "TARGETING: OFF"
toggleButton.TextSize = 16
toggleButton.Parent = controlFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

-- Destroy Button
local destroyButton = Instance.new("TextButton")
destroyButton.Size = UDim2.new(0.9, 0, 0, 30)
destroyButton.Position = UDim2.new(0.05, 0, 0, 100)
destroyButton.BackgroundColor3 = Color3.fromRGB(170, 20, 20)
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.Font = Enum.Font.GothamBold
destroyButton.Text = "DESTROY SYSTEM"
destroyButton.TextSize = 14
destroyButton.Parent = controlFrame

local destroyCorner = Instance.new("UICorner")
destroyCorner.CornerRadius = UDim.new(0, 8)
destroyCorner.Parent = destroyButton

-- Target Label (Improved Readability)
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 340, 0, 55)
targetLabel.Position = UDim2.new(0.5, -170, 0, 15)
targetLabel.BackgroundTransparency = 0.25
targetLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
targetLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
targetLabel.Font = Enum.Font.GothamBlack
targetLabel.Text = "NO TARGET LOCKED"
targetLabel.TextSize = 20
targetLabel.Parent = screenGui

local labelCorner = Instance.new("UICorner")
labelCorner.CornerRadius = UDim.new(0, 10)
labelCorner.Parent = targetLabel

local labelStroke = Instance.new("UIStroke")
labelStroke.Thickness = 2.5
labelStroke.Color = Color3.fromRGB(255, 60, 60)
labelStroke.Parent = targetLabel

-- Box Container
local boxContainer = Instance.new("Frame")
boxContainer.Size = UDim2.new(1, 0, 1, 0)
boxContainer.BackgroundTransparency = 1
boxContainer.Parent = screenGui

-- ==========================================
-- 2. LOGIC
-- ==========================================
local isTargeting = false
local targetPlayer = nil
local activeBoxes = {}
local connections = {}

local function createLockBox(player)
	local boxFrame = Instance.new("Frame")
	boxFrame.Name = player.Name .. "_LockBox"
	boxFrame.Size = UDim2.new(0, 68, 0, 68)
	boxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	boxFrame.BackgroundTransparency = 1
	boxFrame.Parent = boxContainer

	-- Sharp stroke (no corner)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(0, 255, 100)
	stroke.Parent = boxFrame

	-- Info Label (Name + Distance)
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(0, 200, 0, 40)
	infoLabel.Position = UDim2.new(0.5, -100, 0, -45)  -- Above the box
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 13
	infoLabel.TextStrokeTransparency = 0.4
	infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	infoLabel.Parent = boxFrame

	activeBoxes[player] = {Box = boxFrame, Info = infoLabel}

	-- Click on box to lock
	boxFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isTargeting then
			targetPlayer = player
			targetLabel.Text = "LOCKED → " .. string.upper(player.Name)
			targetLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
		end
	end)

	return activeBoxes[player]
end

-- Render loop
local renderConnection = RunService.RenderStepped:Connect(function()
	if not isTargeting then
		for _, data in pairs(activeBoxes) do
			data.Box.Visible = false
		end
		return
	end

	local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local root = player.Character.HumanoidRootPart
			local screenPos, onScreen = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.5, 0))

			local boxData = activeBoxes[player] or createLockBox(player)
			local box = boxData.Box
			local info = boxData.Info

			box.Visible = onScreen

			if onScreen then
				box.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)

				local distance = myRoot and math.floor((myRoot.Position - root.Position).Magnitude) or 0

				-- Update info text
				info.Text = string.upper(player.Name) .. "\n" .. distance .. " studs"

				local stroke = box:FindFirstChildOfClass("UIStroke")

				if player == targetPlayer then
					stroke.Color = Color3.fromRGB(255, 60, 60)
					stroke.Thickness = 4
					box.Size = UDim2.new(0, 82, 0, 82)
				else
					stroke.Color = Color3.fromRGB(0, 255, 100)
					stroke.Thickness = 2.5
					box.Size = UDim2.new(0, 68, 0, 68)
				end
			end
		end
	end
end)

table.insert(connections, renderConnection)

-- Toggle
toggleButton.MouseButton1Click:Connect(function()
	isTargeting = not isTargeting
	if isTargeting then
		toggleButton.Text = "TARGETING: ON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
	else
		toggleButton.Text = "TARGETING: OFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		targetPlayer = nil
		targetLabel.Text = "NO TARGET LOCKED"
		targetLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
	end
end)

-- Destroy
destroyButton.MouseButton1Click:Connect(function()
	for _, c in ipairs(connections) do c:Disconnect() end
	screenGui:Destroy()
	mainheart:Disconnect()
	if game.Workspace:FindFirstChild("PredictedPosition") then
		game.Workspace.PredictedPosition:Destroy()	
	end
end)

-- ==================== LAUNCH BUTTON ====================
local launchButton = Instance.new("TextButton")
launchButton.Size = UDim2.new(0.9, 0, 0, 45)
launchButton.Position = UDim2.new(0.05, 0, 0, 145)  -- Below the destroy button
launchButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
launchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
launchButton.Font = Enum.Font.GothamBold
launchButton.Text = "LAUNCH MISSILE"
launchButton.TextSize = 17
launchButton.Parent = controlFrame

local launchCorner = Instance.new("UICorner")
launchCorner.CornerRadius = UDim.new(0, 8)
launchCorner.Parent = launchButton

local launch = false
local debounce = false
launchButton.MouseButton1Click:Connect(function()
	if not targetPlayer then
		launchButton.Text = "NO TARGET LOCKED!"
		task.wait(1.5)
		launchButton.Text = "LAUNCH MISSILE"
		return
	end

	if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		launchButton.Text = "TARGET NOT FOUND!"
		task.wait(1.2)
		launchButton.Text = "LAUNCH MISSILE"
		return
	end
	if debounce then
		launch = false
		debounce  = false
	else
		if not game.Workspace[localPlayer.Name.." Aircraft"]:FindFirstChildOfClass("Folder") then
			for i,v in pairs(game.Workspace[localPlayer.Name.." Aircraft"]:GetChildren()) do
				if v.Name == "ExplosiveBlock" then
					if not v.Parent:FindFirstChild(tostring(v.Decorate.BrickColor)) then
						local missilefolder = Instance.new("Folder")
						missilefolder.Name = tostring(v.Decorate.BrickColor)
						missilefolder.Parent = v.Parent
					else
						v.Parent = v.Parent:FindFirstChild(tostring(v.Decorate.BrickColor))
					end
				end
			end
		end
		launch = true
		debounce = true
	end
end)
local predictedPart = Instance.new("Part")
predictedPart.Anchored = true
predictedPart.Name = "PredictedPosition"
predictedPart.Size = Vector3.new(16, 16, 16)
predictedPart.Position = Vector3.new(0, 5, 0)
predictedPart.Parent = workspace
predictedPart.CanCollide = false
predictedPart.CanTouch = true
local handles = Instance.new("Handles")
handles.Adornee = predictedPart
handles.Style = Enum.HandlesStyle.Resize
handles.Color3 = Color3.new(1, 1, 0) -- Bright yellow
handles.Parent = workspace
handles.Faces = Faces.new(Enum.NormalId.Top)


local runservice = game:GetService("RunService")
local navigationconstant = 5

local players = game:GetService("Players")
local localplayer = players.LocalPlayer

-- Calculates the variables needed for the APN formula in 3D space
function getNavigationVariables(missile, target)
	local r = target.Position - missile.Position
	local distance = r.Magnitude
	local losDirection = r.Unit -- The normalized LOS vector

	-- Grab the current velocities of both parts
	local v_missile = missile.AssemblyLinearVelocity
	local v_target = target.AssemblyLinearVelocity

	-- Relative Velocity (How the target is moving from the missile's perspective)
	local v_rel = v_target - v_missile

	-- 1. Calculate Closing Velocity (V_c)
	-- We use the Dot Product to see how much of the relative velocity is directly along the LOS.
	-- We make it negative because "closing" implies the distance is shrinking.
	local V_c = -v_rel:Dot(losDirection)

	-- 2. Calculate LOS Rate (lambda_dot)
	-- In 3D, rotation rate is found using the Cross Product of position and velocity,
	-- divided by the square of the distance.
	local losRateVector = r:Cross(v_rel) / (distance * distance)
	local lambda_dot = losRateVector.Magnitude

	-- 3. Calculate Target Lateral Acceleration (a_T)
	-- Assuming you track the target's acceleration (as discussed previously), 
	-- you want the part of its acceleration that is perpendicular to the LOS.
	-- (Placeholder for wherever you store your target's current acceleration vector)
	local targetAccelVector = target:GetAttribute("CurrentAcceleration") or Vector3.zero

	-- Remove the portion of acceleration moving directly toward/away from the missile
	local a_T_vector = targetAccelVector - (targetAccelVector:Dot(losDirection) * losDirection)
	local a_T = a_T_vector.Magnitude

	return V_c, lambda_dot, a_T, losRateVector
end


function calculate3DAPN(N, V_c, losRateVector, losDirection, targetAccelVector)

	-- 1. Standard PN Component in 3D
	-- The Cross Product gives us the exact 3D direction the missile needs to pull
	local pn_accel_vector = N * V_c * losRateVector:Cross(losDirection)

	-- 2. Augmented Component in 3D
	-- Strip out the forward/backward acceleration of the target to only get lateral
	local a_T_vector = targetAccelVector - (targetAccelVector:Dot(losDirection) * losDirection)
	local augmented_accel_vector = (N / 2) * a_T_vector

	-- 3. Total Commanded Acceleration (Vector3)
	-- This single vector contains both your required Pitch and Yaw acceleration!
	local total_a_c = pn_accel_vector + augmented_accel_vector

	return total_a_c
end

local targetlastvelocity = Vector3.new(0,0,0)
local missilelastvelocity = Vector3.new(0,0,0)
local targetsmoothedaccel = Vector3.new(0,0,0)
local missilesmoothedaccel = Vector3.new(0,0,0)

local targetlastacceleration = Vector3.new(0,0,0)
local bg = Instance.new("BodyGyro")
bg.MaxTorque = Vector3.new(1, 1, 1) * 100000 -- Adjust if too weak
bg.P = 3000       -- "Stiffness" (Turn speed)
bg.D = 500        -- "Damping" (Crucial for stopping the shake)
bg.Parent = missile
local sensitivityFactor = 50000
local localplayer = game:GetService("Players").LocalPlayer
local target = nil
local speed = 800
local VirtualInputManager = game:GetService("VirtualInputManager")
mainheart = game:GetService("RunService").Stepped:Connect(function(dt)
	if targetPlayer and launch then
		game.Workspace.CurrentCamera.CameraSubject = missile
		target = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		missile = game.Workspace[localplayer.Name.." Aircraft"]:FindFirstChildOfClass("Folder").ExplosiveBlock.Decorate
		bg.Parent = missile
	end
	if launch and target ~= nil then
	    local ping = localplayer:GetNetworkPing()
	    local targetPos = target.Position + (target.AssemblyLinearVelocity * ping)
	    
	    local r = targetPos - missile.Position
	    local losDirection = r.Unit
	    local V_c, _, _, losRateVector = getNavigationVariables(missile, target)
	    
	    local targetAccelVector = target:GetAttribute("CurrentAcceleration") or Vector3.zero
	    
	    local total_a_c = calculate3DAPN(navigationconstant, V_c, losRateVector, losDirection, targetAccelVector)
		local local_accel = missile.CFrame:VectorToObjectSpace(total_a_c)

		local pitchTorque = local_accel.Y * sensitivityFactor
		local yawTorque = local_accel.X * sensitivityFactor

		missile.BodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 100000
		missile.BodyGyro.CFrame = missile.CFrame * CFrame.Angles(pitchTorque, yawTorque, 0)
			
		if (missile.Position-targetPos).Magnitude < 15 then
				local newdist = (missile.Position-(targetPos+(target.Velocity*ping))).Magnitude
				task.wait(newdist/(missilevelocity.Magnitude))
				for i,v in pairs(missile.Parent.Parent:GetChildren()) do
					if v.Name == "ExplosiveBlock" then
						v.Events.Explode:Fire(4)
					end
				end
				launch = false
				debounce = false
				task.wait(3)
				game.Workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
				missile.Parent.Parent:Destroy()
		end
	end
end)
