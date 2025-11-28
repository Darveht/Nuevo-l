local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Configuración General
local SPAWN_COUNT = 20 -- Cuántos Demogorgons spawnar
local SPAWN_RADIUS = 500 -- Radio de spawn en el mapa
local DETECTION_RANGE = 100 -- Distancia para detectar jugadores
local ATTACK_RANGE = 8 -- Distancia para atacar
local WALK_SPEED = 16
local RUN_SPEED = 35
local HIP_HEIGHT = 3.0 -- Altura de la cadera

-- Colores y Materiales
local skinColor = BrickColor.new("Dark stone grey")
local bellyColor = BrickColor.new("Dark brown")
local innerMouthColor = BrickColor.new("Really red")
local petalOuterColor = BrickColor.new("Rust")
local toothColor = BrickColor.new("White")
local baseMaterial = Enum.Material.Plastic
local surfaceType = Enum.SurfaceType.Studs

-- ==========================================
-- FUNCIONES DE CONSTRUCCIÓN DEL MODELO
-- ==========================================

local function createPart(name, size, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.BrickColor = color
	part.Material = baseMaterial
	part.TopSurface = surfaceType
	part.BottomSurface = surfaceType
	part.CastShadow = true
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = false
	part.CanCollide = true
	return part
end

local function weldParts(part, parentPart, cframeRelative)
	-- Comprobación de seguridad para evitar errores si la parte padre no existe
	if not parentPart or not parentPart:IsA("BasePart") then
		warn("Weld Error: Parent part is missing or invalid for " .. part.Name .. ". Part will be anchored.")
		part.Anchored = true
		return nil
	end

	local weld = Instance.new("Weld")
	weld.Part0 = parentPart
	weld.Part1 = part
	weld.C0 = CFrame.new(0, 0, 0)
	weld.C1 = cframeRelative
	weld.Parent = part
	
	-- Establecer la posición
	part.CFrame = parentPart.CFrame * cframeRelative
	return weld
end

-- ==========================================
-- CONSTRUCCIÓN DEL DEMOGORGON
-- ==========================================

local function createDemogorgon(spawnPosition)
	local model = Instance.new("Model")
	model.Name = "Demogorgon"

	-- Humanoid (CRUCIAL para estabilidad, vida y HipHeight)
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.HipHeight = HIP_HEIGHT
	humanoid.Parent = model

	-- RootPart (base del modelo)
	local rootPart = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), skinColor)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.CFrame = CFrame.new(spawnPosition)
	rootPart.Parent = model

	-- CUERPO
	local torsoUpper = createPart("TorsoUpper", Vector3.new(3.2, 3.5, 2.0), skinColor)
	torsoUpper.Parent = model
	weldParts(torsoUpper, rootPart, CFrame.new(0, 1, 0))

	local torsoLower = createPart("TorsoLower", Vector3.new(2.5, 2.0, 1.5), bellyColor)
	torsoLower.Parent = model
	weldParts(torsoLower, torsoUpper, CFrame.new(0, -2.7, 0))

	-- CUELLO
	local neck = createPart("Neck", Vector3.new(1.2, 0.8, 1.2), skinColor)
	neck.Parent = model
	weldParts(neck, torsoUpper, CFrame.new(0, 2.5, 0.5))

	-- CABEZA (Pétalos, etc.)
	local mouthCore = createPart("MouthCore", Vector3.new(1.8, 1.8, 1.8), innerMouthColor, Enum.PartType.Ball)
	mouthCore.Parent = model
	weldParts(mouthCore, neck, CFrame.new(0, 0.5, 1.5))
	
	local innerRing = createPart("InnerMouthRing", Vector3.new(1.4, 1.4, 1.4), innerMouthColor, Enum.PartType.Ball)
	innerRing.Parent = model
	weldParts(innerRing, mouthCore, CFrame.new(0, 0, 0))

	local NUM_PETALS = 5
	local PETAL_HEIGHT = 4.0
	local PETAL_WIDTH = 2.0
	local PETAL_THICKNESS = 0.8
	local PETAL_OFFSET = 0.9

	for i = 0, NUM_PETALS - 1 do
		local angle = i * (360 / NUM_PETALS)
		local rad = math.rad(angle)
		local radialVector = Vector3.new(0, math.cos(rad), math.sin(rad)) 
		local distance = PETAL_OFFSET + (PETAL_HEIGHT / 2)
		local position = radialVector * distance
		local petalCF = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
		local petalOut = createPart("PetalOuter"..i, Vector3.new(PETAL_HEIGHT, PETAL_THICKNESS, PETAL_WIDTH), petalOuterColor)
		petalOut.Parent = model
		weldParts(petalOut, mouthCore, petalCF)
		local petalIn = createPart("PetalInner"..i, Vector3.new(PETAL_HEIGHT * 0.8, PETAL_THICKNESS * 0.7, PETAL_WIDTH * 0.7), innerMouthColor)
		petalIn.Parent = model
		weldParts(petalIn, petalOut, CFrame.new(0, 0, 0))
		for t = -1.5, 1.5, 1.5 do
			local tooth = createPart("Tooth"..i.."_"..t, Vector3.new(0.3, 0.5, 0.3), toothColor)
			tooth.Parent = model
			weldParts(tooth, petalIn, CFrame.new(t * 1.3, PETAL_THICKNESS * 0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0))
		end
	end

	-- ==========================================
	-- BRAZOS
	-- ==========================================

	local function buildArm(side)
		local shoulder = createPart("Shoulder_".. (side == 1 and "R" or "L"), Vector3.new(1.2, 1.2, 1.2), skinColor)
		shoulder.Parent = model
		local shoulderWeld = weldParts(shoulder, torsoUpper, CFrame.new(side * 1.8, 0.5, 0))
		
		-- CORRECCIÓN DE CRASH: Verificar que la soldadura exista antes de indexarla
		if shoulderWeld then
			shoulderWeld.Name = "ShoulderWeld" 
		end
		
		local upperArm = createPart("UpperArm_".. (side == 1 and "R" or "L"), Vector3.new(0.8, 3, 0.8), skinColor)
		upperArm.Parent = model
		weldParts(upperArm, shoulder, CFrame.new(side * 0.4, -1.8, 0.5) * CFrame.Angles(math.rad(45), 0, 0))
		
		local elbow = createPart("Elbow_".. (side == 1 and "R" or "L"), Vector3.new(0.9, 0.9, 0.9), skinColor)
		elbow.Parent = model
		weldParts(elbow, upperArm, CFrame.new(0, -1.8, 0))
		
		local foreArm = createPart("ForeArm_".. (side == 1 and "R" or "L"), Vector3.new(0.7, 3, 0.7), skinColor)
		foreArm.Parent = model
		weldParts(foreArm, elbow, CFrame.new(0, -1.8, 0) * CFrame.Angles(math.rad(-45), 0, 0))
		
		local hand = createPart("Hand_".. (side == 1 and "R" or "L"), Vector3.new(1.5, 1.5, 0.8), skinColor)
		hand.Parent = model
		weldParts(hand, foreArm, CFrame.new(0, -1.8, 0))
		
		for f = -1, 1, 1 do
			local fingerBase = createPart("Finger_".. (side == 1 and "R" or "L") .."_".. f, Vector3.new(0.4, 1.5, 0.4), skinColor)
			fingerBase.Parent = model
			weldParts(fingerBase, hand, CFrame.new(f * 0.4, -1.5, 0) * CFrame.Angles(math.rad(10), 0, 0))
			
			local claw = createPart("Claw_".. (side == 1 and "R" or "L") .."_".. f, Vector3.new(0.3, 1.2, 0.3), skinColor)
			claw.Parent = model
			weldParts(claw, fingerBase, CFrame.new(0, -0.7, 0))
		end
	end

	buildArm(1)
	buildArm(-1)

	-- ==========================================
	-- PIERNAS
	-- ==========================================

	local function buildLeg(side)
		local thigh = createPart("Thigh_".. (side == 1 and "R" or "L"), Vector3.new(1.5, 3.5, 1.5), skinColor)
		thigh.Parent = model
		local thighWeld = weldParts(thigh, rootPart, CFrame.new(side * 0.8, -1.5, 0.2) * CFrame.Angles(math.rad(-30), 0, 0))
		
		-- CORRECCIÓN DE CRASH: Verificar que la soldadura exista antes de indexarla
		if thighWeld then
			thighWeld.Name = "HipWeld"
		end
		
		local knee = createPart("Knee_".. (side == 1 and "R" or "L"), Vector3.new(1.2, 1.2, 1.2), skinColor)
		knee.Parent = model
		weldParts(knee, thigh, CFrame.new(0, -2.0, 0))
		
		local shin = createPart("Shin_".. (side == 1 and "R" or "L"), Vector3.new(1.2, 3.5, 1.2), skinColor)
		shin.Parent = model
		weldParts(shin, knee, CFrame.new(0, -1.8, -0.5) * CFrame.Angles(math.rad(60), 0, 0))
		
		local ankle = createPart("Ankle_".. (side == 1 and "R" or "L"), Vector3.new(1, 1, 1), skinColor)
		ankle.Parent = model
		weldParts(ankle, shin, CFrame.new(0, -1.8, 0))
		
		local footBone = createPart("FootBone_".. (side == 1 and "R" or "L"), Vector3.new(1.5, 1.5, 3.0), skinColor)
		footBone.Parent = model
		weldParts(footBone, ankle, CFrame.new(0, -0.8, 1.0) * CFrame.Angles(math.rad(-20), 0, 0))
		
		for t = -1, 1 do
			local toe = createPart("Toe_".. (side == 1 and "R" or "L") .."_".. t, Vector3.new(0.5, 1.2, 0.5), skinColor)
			toe.Parent = model
			weldParts(toe, footBone, CFrame.new(t*0.5, -0.8, 1.3) * CFrame.Angles(math.rad(10), 0, 0))
			
			local toeClaw = createPart("Claw_".. (side == 1 and "R" or "L") .."_".. t, Vector3.new(0.3, 0.8, 0.3), skinColor)
			toeClaw.Parent = model -- ¡CORRECCIÓN! Usar toeClaw en lugar de 'claw'
			weldParts(toeClaw, toe, CFrame.new(0, -0.8, 0))
		end
	end

	buildLeg(1)
	buildLeg(-1)

	model.PrimaryPart = rootPart
	model.Parent = workspace

	return model
end

-- ==========================================
-- SISTEMA DE ANIMACIONES
-- ==========================================

local function setupAnimations(demogorgon)
	local animData = {
		state = "idle",
		walkCycle = 0,
		targetPlayer = nil,
		speed = 0
	}

	local walkConnection = RunService.Heartbeat:Connect(function(dt)
		if demogorgon.PrimaryPart and demogorgon.PrimaryPart.Parent == nil then return end

		if animData.state == "walking" or animData.state == "running" then
			local animSpeed = (animData.state == "running" and 8 or 4)
			animData.walkCycle = animData.walkCycle + (dt * animSpeed)
			
			local swing = math.sin(animData.walkCycle) * 0.5
			local swingArm = math.sin(animData.walkCycle) * 0.3

			-- Animación de Piernas (HipWeld)
			local legR = demogorgon:FindFirstChild("Thigh_R")
			local legL = demogorgon:FindFirstChild("Thigh_L")
			local rWeld = legR and legR:FindFirstChild("HipWeld")
			local lWeld = legL and legL:FindFirstChild("HipWeld")
			
			if rWeld and lWeld then
				rWeld.C1 = CFrame.new(0.8, -1.5, 0.2) * CFrame.Angles(math.rad(-30 + swing * 30), 0, 0)
				lWeld.C1 = CFrame.new(-0.8, -1.5, 0.2) * CFrame.Angles(math.rad(-30 - swing * 30), 0, 0)
			end

			-- Animación de Brazos (ShoulderWeld)
			local shoulderR = demogorgon:FindFirstChild("Shoulder_R")
			local shoulderL = demogorgon:FindFirstChild("Shoulder_L")
			local rShoulderWeld = shoulderR and shoulderR:FindFirstChild("ShoulderWeld")
			local lShoulderWeld = shoulderL and shoulderL:FindFirstChild("ShoulderWeld")

			if rShoulderWeld and lShoulderWeld then
				rShoulderWeld.C1 = CFrame.new(1.8, 0.5, 0) * CFrame.Angles(swingArm * 30, 0, 0)
				lShoulderWeld.C1 = CFrame.new(-1.8, 0.5, 0) * CFrame.Angles(-swingArm * 30, 0, 0)
			end
		end
	end)

	return animData, walkConnection
end

-- ==========================================
-- IA Y COMPORTAMIENTO
-- ==========================================

local function setupAI(demogorgon, animData)
	local rootPart = demogorgon.PrimaryPart
	local humanoid = demogorgon:FindFirstChildOfClass("Humanoid")
	
	if not rootPart or not humanoid then return end

	local bodyGyro = Instance.new("BodyGyro", rootPart)
	bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9) -- Torque Máximo para estabilidad absoluta
	bodyGyro.P = 10000

	local bodyVelocity = Instance.new("BodyVelocity", rootPart)
	bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)

	local bodyPosition = Instance.new("BodyPosition", rootPart)
	bodyPosition.MaxForce = Vector3.new(0, 500000, 0) 
	bodyPosition.P = 5000

	-- Función de utilidad para obtener el CFrame vertical basado en la dirección actual
	local function getUprightCFrame(currentCFrame)
		-- Obtenemos el ángulo de giro (Yaw) del CFrame actual
		local _, currentYaw, _ = currentCFrame:ToOrientation()
		-- Creamos un nuevo CFrame que mantiene la posición, y aplica SOLO el giro (Yaw), 
		-- forzando X (Pitch) y Z (Roll) a 0. Esto mantiene el modelo perfectamente vertical.
		return CFrame.new(currentCFrame.Position) * CFrame.Angles(0, currentYaw, 0)
	end
	
	local aiConnection = RunService.Heartbeat:Connect(function()
		if not demogorgon.Parent or not rootPart.Parent or not humanoid or humanoid.Health <= 0 then
			aiConnection:Disconnect()
			return
		end
		
		-- 1. Estabilización de Altura
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {demogorgon}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local rayResult = workspace:Raycast(rootPart.Position, Vector3.new(0, -100, 0), raycastParams)
		
		local targetY = rootPart.Position.Y
		if rayResult and rayResult.Instance then
			targetY = rayResult.Position.Y + humanoid.HipHeight
		end
		
		-- Control de altura (fuerza la posición verticalmente)
		bodyPosition.Position = Vector3.new(rootPart.Position.X, targetY, rootPart.Position.Z)

		-- 2. Detección de Jugadores
		local closestPlayer = nil
		local closestDistance = DETECTION_RANGE
		local targetCFrame = getUprightCFrame(rootPart.CFrame) -- Valor predeterminado: mantenerse recto (ESTABILIDAD)

		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local playerRoot = player.Character.HumanoidRootPart
				local distance = (rootPart.Position - playerRoot.Position).Magnitude
				
				if distance < closestDistance then
					closestDistance = distance
					closestPlayer = player
				end
			end
		end
		
		if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
			-- COMPORTAMIENTO: PERSECUCIÓN
			local targetRoot = closestPlayer.Character.HumanoidRootPart
			local direction = (targetRoot.Position - rootPart.Position)
			
			local flatDirection = Vector3.new(direction.X, 0, direction.Z)
			
			if flatDirection.Magnitude > 0.1 then 
				flatDirection = flatDirection.Unit
				
				-- Define el CFrame objetivo: Mira al jugador, pero usando un CFrame vertical
				targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flatDirection)
				
				if closestDistance < ATTACK_RANGE then
					animData.state = "attacking"
					bodyVelocity.Velocity = Vector3.new(0, 0, 0)
					
					local targetHumanoid = closestPlayer.Character:FindFirstChild("Humanoid")
					if targetHumanoid and targetHumanoid.Health > 0 then
						targetHumanoid:TakeDamage(10)
					end
				else
					animData.state = "running"
					bodyVelocity.Velocity = flatDirection * RUN_SPEED
				end
			else
				-- Detenido cerca del jugador
				animData.state = "idle"
				bodyVelocity.Velocity = Vector3.new(0, 0, 0)
				-- Mantiene la orientación vertical actual
				targetCFrame = getUprightCFrame(rootPart.CFrame)
			end
			
		else
			-- COMPORTAMIENTO: PATRULLA / IDLE
			animData.state = "walking"
			
			if math.random() > 0.98 then
				-- Elige una nueva dirección de patrulla
				local randomAngle = math.rad(math.random(-45, 45))
				local currentLookVector = rootPart.CFrame.LookVector
				local rotatedDir = CFrame.new(Vector3.new()) * CFrame.Angles(0, randomAngle, 0) * currentLookVector
				
				local flatRandomDir = Vector3.new(rotatedDir.X, 0, rotatedDir.Z).Unit
				bodyVelocity.Velocity = flatRandomDir * WALK_SPEED
				
				-- Define el CFrame objetivo: Mira la dirección de patrulla, manteniendo la verticalidad
				targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flatRandomDir)
			else
				-- Sigue caminando lentamente en la dirección actual y mantiene la verticalidad
				bodyVelocity.Velocity = rootPart.CFrame.LookVector * WALK_SPEED * 0.5 
				targetCFrame = getUprightCFrame(rootPart.CFrame)
			end
		end

		-- *** APLICACIÓN CONSTANTE DE ESTABILIDAD ***
		-- Esto se ejecuta en CADA FRAME, forzando la verticalidad y evitando que se caiga
		bodyGyro.CFrame = targetCFrame
	end)
end

-- ==========================================
-- SPAWNING MASIVO
-- ==========================================

print("Spawneando "..SPAWN_COUNT.." Demogorgons…")

for i = 1, SPAWN_COUNT do
	local angle = (i / SPAWN_COUNT) * math.pi * 2
	local x = math.cos(angle) * SPAWN_RADIUS
	local z = math.sin(angle) * SPAWN_RADIUS
	local spawnPos = Vector3.new(x, 50, z) 

	local demo = createDemogorgon(spawnPos)
    
	-- *** CORRECCIÓN CRÍTICA DE ORIENTACIÓN INICIAL DE ROOTPART ***
	-- Voltear 180 grados (X) y girar 180 grados (Y) el HumanoidRootPart. 
	-- Esto asegura que el modelo se construya y aterrice de pie.
	local currentCF = demo.PrimaryPart.CFrame
	local flipCF = CFrame.Angles(math.rad(180), math.rad(180), 0)
	demo.PrimaryPart.CFrame = currentCF * flipCF
	
	local animData, walkConnection = setupAnimations(demo)
	setupAI(demo, animData)

	wait(0.1) 
end

print("¡Sistema Demogorgon completo activado! "..SPAWN_COUNT.." criaturas en el mapa.")

