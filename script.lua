local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ==========================================
-- CONFIGURACIÓN
-- ==========================================
local CONFIG = {
    -- Cuántos Demogorgons spawner
    TotalDemogorgons = 8,

    -- Área del mapa (se distribuyen aleatoriamente)
    MapSize = 500, -- Studs en cada dirección desde (0,0,0)

    -- Comportamiento
    DetectionRange = 50,  -- Distancia para detectar jugadores
    AttackRange = 8,      -- Distancia para atacar
    PatrolSpeed = 12,     -- Velocidad caminando/patrullando
    ChaseSpeed = 26,      -- Velocidad corriendo (persecución)
    Damage = 20,
    AttackCooldown = 1.2,

    -- Patrulla
    PatrolWaitTime = 3,   -- Segundos esperando en cada punto
    PatrolRadius = 40     -- Radio de patrulla desde spawn
}

-- Colores
local COLORS = {
    Skin = BrickColor.new("Dark stone grey"),
    Belly = BrickColor.new("Sand red"),
    InnerMouth = BrickColor.new("Crimson"),
    Petal = BrickColor.new("Dark orange"),
    Tooth = BrickColor.new("Institutional white"),
    Claw = BrickColor.new("Really black")
}

-- Lista para gestionar todos los Demogorgons
local demogorgons = {}

-- ==========================================
-- UTILIDADES
-- ==========================================
local function createPart(name, size, color, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.BrickColor = color
    part.Material = Enum.Material.Plastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CanCollide = false
    part.Anchored = false
    part.Parent = parent
    return part
end

local function weld(part0, part1, c0, c1, name)
    local motor = Instance.new("Motor6D")
    motor.Name = name or (part1.Name.."Motor")
    motor.Part0 = part0
    motor.Part1 = part1
    motor.C0 = c0 or CFrame.new()
    motor.C1 = c1 or CFrame.new()
    motor.Parent = part0
    return motor
end

-- ==========================================
-- CONSTRUCCIÓN DEL DEMOGORGON
-- ==========================================
local function buildDemogorgon(spawnPos)
    local model = Instance.new("Model")
    model.Name = "Demogorgon"

    -- ===== ROOTPART =====
    local root = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), COLORS.Skin, model)
    root.Transparency = 1
    root.CanCollide = true
    root.CFrame = CFrame.new(spawnPos)

    -- ===== TORSO =====
    local torso = createPart("UpperTorso", Vector3.new(2.5, 2.5, 1.5), COLORS.Skin, model)
    torso.CFrame = root.CFrame * CFrame.new(0, 0.5, 0)
    local torsoMotor = weld(root, torso, CFrame.new(0, 0.5, 0), CFrame.new(0, 0, 0))

    -- Costillas decorativas
    for i = -1, 1, 2 do
        local rib = createPart("Rib", Vector3.new(0.3, 1.5, 0.3), COLORS.Skin, model)
        rib.CFrame = torso.CFrame * CFrame.new(i * 0.9, 0.3, -0.8)
        weld(torso, rib, CFrame.new(i * 0.9, 0.3, -0.8))
    end

    -- ===== ABDOMEN =====
    local lower = createPart("LowerTorso", Vector3.new(2, 2, 1.3), COLORS.Belly, model)
    lower.CFrame = torso.CFrame * CFrame.new(0, -2.2, 0)
    local lowerMotor = weld(torso, lower, CFrame.new(0, -2.2, 0), CFrame.new(0, 0, 0))

    -- ===== CUELLO =====
    local neck = createPart("Neck", Vector3.new(1.3, 1.2, 1.3), COLORS.Skin, model)
    neck.CFrame = torso.CFrame * CFrame.new(0, 1.8, 0)
    local neckMotor = weld(torso, neck, CFrame.new(0, 1.8, 0), CFrame.new(0, -0.6, 0))

    -- ===== CABEZA (Base esférica roja) =====
    local head = createPart("Head", Vector3.new(2.2, 2.2, 2.2), COLORS.InnerMouth, model)
    head.Shape = Enum.PartType.Ball
    head.CFrame = neck.CFrame * CFrame.new(0, 1.4, 0.2)
    local headMotor = weld(neck, head, CFrame.new(0, 1.4, 0.2), CFrame.new(0, -1.1, -0.1))

    -- Boca interna
    local innerMouth = createPart("InnerMouth", Vector3.new(1.2, 1.2, 1.2), COLORS.InnerMouth, model)
    innerMouth.Shape = Enum.PartType.Ball
    innerMouth.CFrame = head.CFrame * CFrame.new(0, 0, 0.6)
    weld(head, innerMouth, CFrame.new(0, 0, 0.6))

    -- Dientes circulares internos
    for i = 1, 12 do
        local angle = math.rad((360 / 12) * i)
        local tooth = Instance.new("WedgePart")
        tooth.Name = "InnerTooth"..i
        tooth.Size = Vector3.new(0.15, 0.5, 0.15)
        tooth.BrickColor = COLORS.Tooth
        tooth.CanCollide = false
        tooth.Anchored = false
        tooth.Parent = model
        
        local toothCF = innerMouth.CFrame * CFrame.new(
            math.sin(angle) * 0.5,
            math.cos(angle) * 0.5,
            0
        ) * CFrame.Angles(0, -angle, math.rad(90))
        
        tooth.CFrame = toothCF
        weld(innerMouth, tooth, innerMouth.CFrame:ToObjectSpace(toothCF))
    end

    -- ===== PÉTALOS (5 pétalos tipo flor) =====
    local petalMotors = {}
    for i = 1, 5 do
        local angle = math.rad((360 / 5) * i)
        
        local petal = Instance.new("WedgePart")
        petal.Name = "Petal"..i
        petal.Size = Vector3.new(1.8, 4, 1)
        petal.BrickColor = COLORS.Petal
        petal.CanCollide = false
        petal.Anchored = false
        petal.Parent = model
        
        local petalCF = head.CFrame * CFrame.new(
            math.sin(angle) * 1.4,
            0.8,
            math.cos(angle) * 1.4
        ) * CFrame.Angles(math.rad(-50), angle + math.rad(180), 0)
        
        petal.CFrame = petalCF
        local petalMotor = weld(head, petal, head.CFrame:ToObjectSpace(petalCF), CFrame.new(0, -2, 0))
        table.insert(petalMotors, {motor = petalMotor, baseAngle = angle, index = i})
        
        -- Interior rojo
        local inner = createPart("PetalInner"..i, Vector3.new(1.2, 3, 0.6), COLORS.InnerMouth, model)
        inner.CFrame = petal.CFrame * CFrame.new(0, -0.3, -0.3)
        weld(petal, inner, CFrame.new(0, -0.3, -0.3))
        
        -- Venas
        for v = 1, 3 do
            local vein = createPart("Vein", Vector3.new(0.15, 2.5, 0.15), BrickColor.new("Maroon"), model)
            vein.CFrame = inner.CFrame * CFrame.new((v - 2) * 0.3, 0, 0.1)
            weld(inner, vein, CFrame.new((v - 2) * 0.3, 0, 0.1))
        end
        
        -- Dientes en el pétalo
        for t = 1, 8 do
            local tooth = Instance.new("WedgePart")
            tooth.Name = "Tooth"..i.."_"..t
            tooth.Size = Vector3.new(0.2, 0.7, 0.2)
            tooth.BrickColor = COLORS.Tooth
            tooth.CanCollide = false
            tooth.Anchored = false
            tooth.Parent = model
            
            local toothY = ((t - 4.5) * 0.45)
            local toothCF = inner.CFrame * CFrame.new(0.4, toothY, 0.1) * CFrame.Angles(0, math.rad(-30), math.rad(45))
            
            tooth.CFrame = toothCF
            weld(inner, tooth, inner.CFrame:ToObjectSpace(toothCF))
        end
    end

    -- ===== BRAZO DERECHO =====
    local rShoulder = createPart("RightShoulder", Vector3.new(1.2, 1.2, 1.2), COLORS.Skin, model)
    rShoulder.CFrame = torso.CFrame * CFrame.new(2, 0.8, 0)
    local rShoulderMotor = weld(torso, rShoulder, CFrame.new(2, 0.8, 0), CFrame.new(0, 0, 0))

    local rUpperArm = createPart("RightUpperArm", Vector3.new(0.9, 3.2, 0.9), COLORS.Skin, model)
    rUpperArm.CFrame = rShoulder.CFrame * CFrame.new(0, -1.6, 0)
    local rShoulderJoint = weld(rShoulder, rUpperArm, CFrame.new(0, 0, 0), CFrame.new(0, 1.6, 0))

    local rForeArm = createPart("RightForeArm", Vector3.new(0.8, 3.8, 0.8), COLORS.Skin, model)
    rForeArm.CFrame = rUpperArm.CFrame * CFrame.new(0, -3.2, 0.3)
    local rElbow = weld(rUpperArm, rForeArm, CFrame.new(0, -1.6, 0), CFrame.new(0, 1.9, -0.3))

    local rHand = createPart("RightHand", Vector3.new(1.3, 1, 0.7), COLORS.Skin, model)
    rHand.CFrame = rForeArm.CFrame * CFrame.new(0, -1.9, 0)
    weld(rForeArm, rHand, CFrame.new(0, -1.9, 0), CFrame.new(0, 0.5, 0))

    for f = -1, 1 do
        local claw = Instance.new("WedgePart")
        claw.Size = Vector3.new(0.25, 1.5, 0.25)
        claw.BrickColor = COLORS.Claw
        claw.CanCollide = false
        claw.Anchored = false
        claw.Parent = model
        claw.CFrame = rHand.CFrame * CFrame.new(f * 0.4, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)
        weld(rHand, claw, CFrame.new(f * 0.4, -1, 0) * CFrame.Angles(math.rad(90), 0, 0))
    end

    -- ===== BRAZO IZQUIERDO =====
    local lShoulder = createPart("LeftShoulder", Vector3.new(1.2, 1.2, 1.2), COLORS.Skin, model)
    lShoulder.CFrame = torso.CFrame * CFrame.new(-2, 0.8, 0)
    local lShoulderMotor = weld(torso, lShoulder, CFrame.new(-2, 0.8, 0), CFrame.new(0, 0, 0))

    local lUpperArm = createPart("LeftUpperArm", Vector3.new(0.9, 3.2, 0.9), COLORS.Skin, model)
    lUpperArm.CFrame = lShoulder.CFrame * CFrame.new(0, -1.6, 0)
    local lShoulderJoint = weld(lShoulder, lUpperArm, CFrame.new(0, 0, 0), CFrame.new(0, 1.6, 0))

    local lForeArm = createPart("LeftForeArm", Vector3.new(0.8, 3.8, 0.8), COLORS.Skin, model)
    lForeArm.CFrame = lUpperArm.CFrame * CFrame.new(0, -3.2, 0.3)
    local lElbow = weld(lUpperArm, lForeArm, CFrame.new(0, -1.6, 0), CFrame.new(0, 1.9, -0.3))

    local lHand = createPart("LeftHand", Vector3.new(1.3, 1, 0.7), COLORS.Skin, model)
    lHand.CFrame = lForeArm.CFrame * CFrame.new(0, -1.9, 0)
    weld(lForeArm, lHand, CFrame.new(0, -1.9, 0), CFrame.new(0, 0.5, 0))

    for f = -1, 1 do
        local claw = Instance.new("WedgePart")
        claw.Size = Vector3.new(0.25, 1.5, 0.25)
        claw.BrickColor = COLORS.Claw
        claw.CanCollide = false
        claw.Anchored = false
        claw.Parent = model
        claw.CFrame = lHand.CFrame * CFrame.new(f * 0.4, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)
        weld(lHand, claw, CFrame.new(f * 0.4, -1, 0) * CFrame.Angles(math.rad(90), 0, 0))
    end

    -- ===== PIERNA DERECHA =====
    local rHip = createPart("RightHip", Vector3.new(1.2, 1, 1.2), COLORS.Skin, model)
    rHip.CFrame = lower.CFrame * CFrame.new(0.7, -1, 0)
    local rHipMotor = weld(lower, rHip, CFrame.new(0.7, -1, 0), CFrame.new(0, 0.5, 0))

    local rThigh = createPart("RightThigh", Vector3.new(1.1, 3.5, 1.1), COLORS.Skin, model)
    rThigh.CFrame = rHip.CFrame * CFrame.new(0, -1.75, 0)
    local rHipJoint = weld(rHip, rThigh, CFrame.new(0, -0.5, 0), CFrame.new(0, 1.75, 0))

    local rShin = createPart("RightShin", Vector3.new(1, 3.2, 1), COLORS.Skin, model)
    rShin.CFrame = rThigh.CFrame * CFrame.new(0, -1.75, 0.4)
    local rKnee = weld(rThigh, rShin, CFrame.new(0, -1.75, 0), CFrame.new(0, 1.6, -0.4))

    local rFoot = createPart("RightFoot", Vector3.new(1.2, 0.8, 2.8), COLORS.Skin, model)
    rFoot.CFrame = rShin.CFrame * CFrame.new(0, -1.6, 1)
    local rAnkle = weld(rShin, rFoot, CFrame.new(0, -1.6, 0), CFrame.new(0, 0.4, -1))

    for t = -1, 1 do
        local claw = Instance.new("WedgePart")
        claw.Size = Vector3.new(0.35, 1, 0.35)
        claw.BrickColor = COLORS.Claw
        claw.CanCollide = false
        claw.Anchored = false
        claw.Parent = model
        claw.CFrame = rFoot.CFrame * CFrame.new(t * 0.4, -0.5, 1.2) * CFrame.Angles(math.rad(90), 0, 0)
        weld(rFoot, claw, CFrame.new(t * 0.4, -0.5, 1.2) * CFrame.Angles(math.rad(90), 0, 0))
    end

    -- ===== PIERNA IZQUIERDA =====
    local lHip = createPart("LeftHip", Vector3.new(1.2, 1, 1.2), COLORS.Skin, model)
    lHip.CFrame = lower.CFrame * CFrame.new(-0.7, -1, 0)
    local lHipMotor = weld(lower, lHip, CFrame.new(-0.7, -1, 0), CFrame.new(0, 0.5, 0))

    local lThigh = createPart("LeftThigh", Vector3.new(1.1, 3.5, 1.1), COLORS.Skin, model)
    lThigh.CFrame = lHip.CFrame * CFrame.new(0, -1.75, 0)
    local lHipJoint = weld(lHip, lThigh, CFrame.new(0, -0.5, 0), CFrame.new(0, 1.75, 0))

    local lShin = createPart("LeftShin", Vector3.new(1, 3.2, 1), COLORS.Skin, model)
    lShin.CFrame = lThigh.CFrame * CFrame.new(0, -1.75, 0.4)
    local lKnee = weld(lThigh, lShin, CFrame.new(0, -1.75, 0), CFrame.new(0, 1.6, -0.4))

    local lFoot = createPart("LeftFoot", Vector3.new(1.2, 0.8, 2.8), COLORS.Skin, model)
    lFoot.CFrame = lShin.CFrame * CFrame.new(0, -1.6, 1)
    local lAnkle = weld(lShin, lFoot, CFrame.new(0, -1.6, 0), CFrame.new(0, 0.4, -1))

    for t = -1, 1 do
        local claw = Instance.new("WedgePart")
        claw.Size = Vector3.new(0.35, 1, 0.35)
        claw.BrickColor = COLORS.Claw
        claw.CanCollide = false
        claw.Anchored = false
        claw.Parent = model
        claw.CFrame = lFoot.CFrame * CFrame.new(t * 0.4, -0.5, 1.2) * CFrame.Angles(math.rad(90), 0, 0)
        weld(lFoot, claw, CFrame.new(t * 0.4, -0.5, 1.2) * CFrame.Angles(math.rad(90), 0, 0))
    end

    -- ===== HUMANOID =====
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 500
    humanoid.Health = 500
    humanoid.WalkSpeed = CONFIG.PatrolSpeed
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model

    local animData = {
        torsoMotor = torsoMotor,
        neckMotor = neckMotor,
        headMotor = headMotor,
        lowerMotor = lowerMotor,
        petalMotors = petalMotors,
        
        -- Brazos (AMBOS)
        rShoulderJoint = rShoulderJoint,
        rElbow = rElbow,
        lShoulderJoint = lShoulderJoint,
        lElbow = lElbow,
        
        -- Piernas (AMBAS)
        rHipJoint = rHipJoint,
        rKnee = rKnee,
        rAnkle = rAnkle,
        lHipJoint = lHipJoint,
        lKnee = lKnee,
        lAnkle = lAnkle,
        
        walkCycle = 0,
        isAttacking = false
    }

    model.PrimaryPart = root
    model.Parent = workspace

    return model, animData
end

-- ==========================================
-- ANIMACIÓN COMPLETA
-- ==========================================
local function animate(model, data, dt)
    if not model or not model.Parent then return end

    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local moving = hum.MoveVector.Magnitude > 0.1
    local running = hum.WalkSpeed > CONFIG.PatrolSpeed

    if moving and not data.isAttacking then
        -- Velocidad de animación
        local speed = running and 10 or 6
        data.walkCycle = data.walkCycle + dt * speed
        
        local swing = math.sin(data.walkCycle)
        local swingCos = math.cos(data.walkCycle)
        local intensity = running and 1.2 or 0.8
        
        -- ===== BRAZOS (OPUESTOS A LAS PIERNAS) =====
        -- Brazo DERECHO: adelante cuando pierna IZQUIERDA adelante
        data.rShoulderJoint.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(-swing * intensity * 0.7, 0, 0)
        data.rElbow.C0 = CFrame.new(0, -1.6, 0) * CFrame.Angles(math.abs(swing) * 0.5, 0, 0)
        
        -- Brazo IZQUIERDO: atrás cuando pierna DERECHA adelante
        data.lShoulderJoint.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(swing * intensity * 0.7, 0, 0)
        data.lElbow.C0 = CFrame.new(0, -1.6, 0) * CFrame.Angles(math.abs(swing) * 0.5, 0, 0)
        
        -- ===== PIERNAS =====
        -- Pierna DERECHA
        data.rHipJoint.C0 = CFrame.new(0, -0.5, 0) * CFrame.Angles(swingCos * intensity * 0.6, 0, 0)
        data.rKnee.C0 = CFrame.new(0, -1.75, 0) * CFrame.Angles(math.max(0, -swingCos * 1.0), 0, 0)
        data.rAnkle.C0 = CFrame.new(0, -1.6, 0) * CFrame.Angles(swingCos * 0.4, 0, 0)
        
        -- Pierna IZQUIERDA
        data.lHipJoint.C0 = CFrame.new(0, -0.5, 0) * CFrame.Angles(-swingCos * intensity * 0.6, 0, 0)
        data.lKnee.C0 = CFrame.new(0, -1.75, 0) * CFrame.Angles(math.max(0, swingCos * 1.0), 0, 0)
        data.lAnkle.C0 = CFrame.new(0, -1.6, 0) * CFrame.Angles(-swingCos * 0.4, 0, 0)
        
        -- ===== TORSO (balancea al caminar) =====
        data.torsoMotor.C0 = CFrame.new(0, 0.5, 0) * CFrame.Angles(math.rad(5), swing * 0.12, 0)
        
        -- ===== CUELLO Y CABEZA =====
        data.neckMotor.C0 = CFrame.new(0, 1.8, 0) * CFrame.Angles(swing * 0.08, -swing * 0.1, 0)
        data.headMotor.C0 = CFrame.new(0, 1.4, 0.2) * CFrame.Angles(-swing * 0.1, swing * 0.05, 0)
        
    else
        -- ===== IDLE (Respiración) =====
        data.walkCycle = data.walkCycle + dt * 2.5
        local breathe = math.sin(data.walkCycle) * 0.06
        
        data.torsoMotor.C0 = CFrame.new(0, 0.5 + breathe, 0)
        data.neckMotor.C0 = CFrame.new(0, 1.8, 0) * CFrame.Angles(breathe * 0.4, 0, 0)
        data.headMotor.C0 = CFrame.new(0, 1.4, 0.2) * CFrame.Angles(breathe * 0.3, 0, 0)
        
        -- Brazos relajados
        data.rShoulderJoint.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(15), 0, 0)
        data.lShoulderJoint.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(15), 0, 0)
    end

    -- ===== PÉTALOS (Siempre se mueven) =====
    for _, pData in ipairs(data.petalMotors) do
        local offset = pData.index * 0.7
        local flutter = math.sin(data.walkCycle * 1.3 + offset) * 0.15
        local angle = pData.baseAngle
        
        local petalCF = CFrame.new(
            math.sin(angle) * 1.4,
            0.8 + flutter * 0.4,
            math.cos(angle) * 1.4
        ) * CFrame.Angles(math.rad(-50 + flutter * 18), angle + math.rad(180), flutter * 0.3)
        
        pData.motor.C0 = petalCF
    end
end

-- ==========================================
-- SISTEMA DE IA
-- ==========================================
local function createAI(model, data)
    local root = model.PrimaryPart
    local hum = model:FindFirstChildOfClass("Humanoid")
    local spawnPos = root.Position

    local ai = {
        state = "patrol",
        target = nil,
        lastAttack = 0,
        patrolPoint = nil,
        patrolWait = 0,
        isWaiting = false
    }

    local function findNearestPlayer()
        local nearest = nil
        local minDist = CONFIG.DetectionRange
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                local charHum = char:FindFirstChildOfClass("Humanoid")
                
                if charHum and charHum.Health > 0 then
                    local dist = (char.HumanoidRootPart.Position - root.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = char
                    end
                end
            end
        end
        
        return nearest
    end

    local function attack()
        if tick() - ai.lastAttack < CONFIG.AttackCooldown then return end
        
        if ai.target and ai.target:FindFirstChild("HumanoidRootPart") then
            local targetHum = ai.target:FindFirstChildOfClass("Humanoid")
            local dist = (ai.target.HumanoidRootPart.Position - root.Position).Magnitude
            
            if dist <= CONFIG.AttackRange and targetHum and targetHum.Health > 0 then
                -- Iniciar animación de ataque
                data.isAttacking = true
                hum:MoveTo(root.Position) -- Detener movimiento

                -- Aplicar daño
                targetHum:TakeDamage(CONFIG.Damage)
                
                -- Cooldown
                ai.lastAttack = tick()

                -- Esperar un momento para la animación de ataque y luego restablecer
                task.wait(0.5)
                data.isAttacking = false
            end
        end
    end

    local function updateState()
        if not root or not hum or hum.Health <= 0 then return end

        local nearestPlayer = findNearestPlayer()

        if nearestPlayer then
            ai.target = nearestPlayer
            ai.state = "chase"
            hum.WalkSpeed = CONFIG.ChaseSpeed
        else
            ai.target = nil
            ai.state = "patrol"
            hum.WalkSpeed = CONFIG.PatrolSpeed
        end

        if ai.state == "chase" then
            if ai.target and ai.target.Parent then
                local targetRoot = ai.target:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (targetRoot.Position - root.Position).Magnitude
                    
                    if dist <= CONFIG.AttackRange then
                        attack()
                    else
                        hum:MoveTo(targetRoot.Position)
                    end
                end
            else
                -- Target perdido, volver a patrullar
                ai.state = "patrol"
            end
        elseif ai.state == "patrol" then
            if ai.patrolPoint == nil or (root.Position - ai.patrolPoint).Magnitude < 5 then
                if not ai.isWaiting then
                    ai.isWaiting = true
                    ai.patrolWait = CONFIG.PatrolWaitTime
                    hum:MoveTo(root.Position) -- Detener movimiento
                end
            end

            if ai.isWaiting then
                if ai.patrolWait > 0 then
                    ai.patrolWait = ai.patrolWait - 0.3 -- Se actualiza cada 0.3s en el bucle principal
                else
                    ai.isWaiting = false
                    -- Elegir nuevo punto de patrulla
                    local randomOffset = Vector3.new(
                        math.random(-CONFIG.PatrolRadius, CONFIG.PatrolRadius),
                        0,
                        math.random(-CONFIG.PatrolRadius, CONFIG.PatrolRadius)
                    )
                    ai.patrolPoint = spawnPos + randomOffset
                    hum:MoveTo(ai.patrolPoint)
                end
            else
                -- Asegurarse de que se está moviendo hacia el punto de patrulla
                hum:MoveTo(ai.patrolPoint)
            end
        end
    end

    -- Bucle de IA se ejecuta en paralelo
    task.spawn(function()
        while model.Parent and hum.Health > 0 do
            updateState()
            task.wait(0.3) -- Tasa de actualización de la IA (no tan frecuente como la animación)
        end
    end)
end

-- ==========================================
-- BUCLE PRINCIPAL (Inicialización y Animación)
-- ==========================================
local function spawnDemogorgons()
    for i = 1, CONFIG.TotalDemogorgons do
        local randX = math.random(-CONFIG.MapSize / 2, CONFIG.MapSize / 2)
        local randZ = math.random(-CONFIG.MapSize / 2, CONFIG.MapSize / 2)
        
        -- Buscar una posición en el suelo
        local spawnPos = Vector3.new(randX, 100, randZ)
        local ray = Workspace:Raycast(spawnPos, Vector3.new(0, -200, 0), RaycastParams.new())
        
        local finalPos = Vector3.new(randX, 5, randZ) -- Posición predeterminada si el rayo falla
        if ray then
            finalPos = ray.Position + Vector3.new(0, 5, 0) -- 5 studs por encima del suelo
        end

        local model, data = buildDemogorgon(finalPos)
        createAI(model, data)
        table.insert(demogorgons, {model = model, data = data})
    end
end

-- Iniciar el spawner
spawnDemogorgons()

-- Bucle de animación (se ejecuta cada frame)
RunService.Heartbeat:Connect(function(dt)
    for i = #demogorgons, 1, -1 do
        local d = demogorgons[i]
        
        if d.model.Parent and d.model:FindFirstChildOfClass("Humanoid") and d.model:FindFirstChildOfClass("Humanoid").Health > 0 then
            animate(d.model, d.data, dt)
        else
            -- Limpiar Demogorgons muertos o eliminados
            table.remove(demogorgons, i)
        end
    end
end)

