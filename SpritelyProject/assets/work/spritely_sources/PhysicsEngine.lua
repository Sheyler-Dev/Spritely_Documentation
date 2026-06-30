--!native
local RunService = game:GetService("RunService")
local Spritely = require(game.ReplicatedStorage:WaitForChild("Spritely"))

local PhysicsEngine = {}
PhysicsEngine.Bodies = {}

local CONFIG = {
	GRAVITY = Vector2.new(0, 800),
	BAUMGARTE = 0.2,
	PENETRATION_SLOP = 0.05,
	VELOCITY_THRESHOLD = 50,
	SLEEP_THRESHOLD = 1.5,
	DAMPING = 0.99,
	ANGULAR_DAMPING = 0.95,
	SUB_STEPS = 8,
}

local RigidBody = {}
RigidBody.__index = RigidBody

function RigidBody.new(uiObject, anchored)
	local self = setmetatable({}, RigidBody)
	self.Instance = uiObject
	self.Anchored = anchored or false

	local size = uiObject.AbsoluteSize
	self.Position = uiObject.AbsolutePosition + (size * 0.5)

	self.Radius = (size.X + size.Y) / 4 
	self.Velocity = Vector2.zero
	self.Angle = math.rad(uiObject.Rotation)
	self.AngularVelocity = 0

	if self.Anchored then
		self.InvMass = 0
		self.InvInertia = 0
	else
		local mass = (size.X * size.Y) / 100
		self.InvMass = 1 / mass
		self.InvInertia = 1 / ((mass * (size.X^2 + size.Y^2)) / 12)
	end

	self.Friction = 0.4
	self.Restitution = 0.1
	return self
end

function RigidBody:ApplyImpulse(impulse, r)
	if self.Anchored then return end
	self.Velocity += impulse * self.InvMass
	self.AngularVelocity += (r.X * impulse.Y - r.Y * impulse.X) * self.InvInertia
end

local function Resolve(A, B)
	local diff = B.Position - A.Position
	local distSq = diff.X^2 + diff.Y^2
	local radiusSum = A.Radius + B.Radius
	if distSq > radiusSum^2 then return end
	local Hit, Normal, Depth, _, ContactPoints = Spritely.IsTouching(A.Instance, B.Instance, "Detailed")
	if not Hit or Depth <= 0 then return end
	Normal = -Normal
	local invMassSum = A.InvMass + B.InvMass
	if invMassSum > 0 then
		local magnitude = math.max(Depth - CONFIG.PENETRATION_SLOP, 0) * CONFIG.BAUMGARTE
		local correction = Normal * (magnitude / invMassSum)
		if not A.Anchored then A.Position -= correction * A.InvMass end
		if not B.Anchored then B.Position += correction * B.InvMass end
	end
	local contactPos = Vector2.zero
	for _, p in ipairs(ContactPoints.B) do contactPos += p end
	contactPos /= #ContactPoints.B

	local rA, rB = contactPos-A.Position, contactPos-B.Position
	local vA = A.Velocity + Vector2.new(-A.AngularVelocity * rA.Y, A.AngularVelocity * rA.X)
	local vB = B.Velocity + Vector2.new(-B.AngularVelocity * rB.Y, B.AngularVelocity * rB.X)
	local rv = vB - vA

	local velAlongNormal = rv:Dot(Normal)
	if velAlongNormal > 0 then return end
	local e = math.min(A.Restitution, B.Restitution)
	if math.abs(velAlongNormal) < CONFIG.VELOCITY_THRESHOLD then
		e = 0
	end

	local raN = (rA.X * Normal.Y - rA.Y * Normal.X)
	local rbN = (rB.X * Normal.Y - rB.Y * Normal.X)
	local commonDenominator = invMassSum + (raN * raN) * A.InvInertia + (rbN * rbN) * B.InvInertia

	local j = -(1 + e) * velAlongNormal / commonDenominator
	local impulse = Normal * j

	A:ApplyImpulse(-impulse, rA)
	B:ApplyImpulse(impulse, rB)
	local vA_post = A.Velocity + Vector2.new(-A.AngularVelocity * rA.Y, A.AngularVelocity * rA.X)
	local vB_post = B.Velocity + Vector2.new(-B.AngularVelocity * rB.Y, B.AngularVelocity * rB.X)
	local rv_post = vB_post - vA_post

	local tangent = rv_post - (Normal * rv_post:Dot(Normal))
	if tangent.Magnitude > 0.01 then
		tangent = tangent.Unit
		local jt = -rv_post:Dot(tangent) / commonDenominator
		local mu = (A.Friction + B.Friction) / 2
		local frictionImpulse = tangent * math.clamp(jt, -j * mu, j * mu)

		A:ApplyImpulse(-frictionImpulse, rA)
		B:ApplyImpulse(frictionImpulse, rB)
	end
end

function PhysicsEngine.Step(dt)
	local subDt = dt / CONFIG.SUB_STEPS

	for s = 1, CONFIG.SUB_STEPS do
		for _, body in ipairs(PhysicsEngine.Bodies) do
			if not body.Anchored then
				body.Velocity += CONFIG.GRAVITY * subDt
				body.Velocity *= math.pow(CONFIG.DAMPING, subDt * 60)
				body.AngularVelocity *= math.pow(CONFIG.ANGULAR_DAMPING, subDt * 60)

				body.Position += body.Velocity * subDt
				body.Angle += body.AngularVelocity * subDt

				if body.Velocity.Magnitude < CONFIG.SLEEP_THRESHOLD and 
					math.abs(body.AngularVelocity) < math.rad(CONFIG.SLEEP_THRESHOLD) then
					body.Velocity = Vector2.zero
					body.AngularVelocity = 0
				end
			end
		end

		for i = 1, #PhysicsEngine.Bodies do
			for j = i + 1, #PhysicsEngine.Bodies do
				Resolve(PhysicsEngine.Bodies[i], PhysicsEngine.Bodies[j])
			end
		end
	end

	for _, body in ipairs(PhysicsEngine.Bodies) do
		local obj = body.Instance
		local size = obj.AbsoluteSize
		local anchor = obj.AnchorPoint
		local topLeft = body.Position - (size * 0.5)
		local anchoredPos = topLeft + (size * anchor)

		obj.Position = UDim2.fromOffset(anchoredPos.X, anchoredPos.Y)
		obj.Rotation = math.deg(body.Angle)
	end
end

function PhysicsEngine.AddBody(uiObject, anchored)
	local body = RigidBody.new(uiObject, anchored)
	table.insert(PhysicsEngine.Bodies, body)
	return body
end

function PhysicsEngine.RemoveBody(uiObject)
	for i, body in ipairs(PhysicsEngine.Bodies) do
		if body.Instance == uiObject then
			table.remove(PhysicsEngine.Bodies, i)
			break
		end
	end
end

return PhysicsEngine