-- Box2D world
local world = nil
local ship = {
	initial_rotation = 0,
	body = nil,
	fixture = nil,
	acceleration_force = 100,
	rotation_torque = 500,
	max_linear_velocity = 600,
	max_angular_velocity = 3,
	current_animation = "idle",
	animation_timer = 0,
	animation_speed = 0.2, -- seconds per frame
	current_frame = 1,
	sheet = nil,
	idle_frames = {
		love.graphics.newQuad(0, 0, 16, 16, 48, 16),
	},
	running_frames = {
		love.graphics.newQuad(16, 0, 16, 16, 48, 16),
		love.graphics.newQuad(32, 0, 16, 16, 48, 16),
	},
}

local function load()
	love.graphics.setDefaultFilter("nearest", "nearest")

	-- Initialize Box2D world (no gravity for space ship)
	world = love.physics.newWorld(0, 0, true)

	-- Create ship body
	ship.body = love.physics.newBody(world, 100, 100, "dynamic")

	-- Create ship fixture (16x16 pixel sprite, scaled to 64x64)
	local ship_shape = love.physics.newRectangleShape(32, 32) -- Half-width, half-height
	ship.fixture = love.physics.newFixture(ship.body, ship_shape, 1) -- density = 1

	-- Set ship properties
	ship.body:setLinearDamping(0.1) -- Air resistance
	ship.body:setAngularDamping(0.2) -- Rotational resistance

	ship.sheet = love.graphics.newImage("ship.png")
end

local function update(dt)
	-- Handle rotation (A/D keys) using direct angular velocity
	if love.keyboard.isDown("a") then
		ship.body:setAngularVelocity(-ship.max_angular_velocity)
	elseif love.keyboard.isDown("d") then
		ship.body:setAngularVelocity(ship.max_angular_velocity)
	else
		-- Stop rotation when no keys are pressed
		ship.body:setAngularVelocity(0)
	end

	-- Handle acceleration (W key)
	if love.keyboard.isDown("w") then
		-- Set animation to running
		ship.current_animation = "running"

		-- Get current rotation angle
		local angle = ship.body:getAngle()

		-- Calculate forward direction based on current rotation
		-- Subtract π/2 (90°) because sprite faces up, but math assumes 0° is right
		local forward_x = math.cos(angle - math.pi / 2)
		local forward_y = math.sin(angle - math.pi / 2)

		-- Apply force in forward direction
		ship.body:applyForce(forward_x * ship.acceleration_force, forward_y * ship.acceleration_force)
	else
		-- Set animation to idle when not pressing W
		ship.current_animation = "idle"
	end

	-- Limit maximum linear velocity
	local vx, vy = ship.body:getLinearVelocity()
	local current_speed = math.sqrt(vx ^ 2 + vy ^ 2)
	if current_speed > ship.max_linear_velocity then
		local scale = ship.max_linear_velocity / current_speed
		ship.body:setLinearVelocity(vx * scale, vy * scale)
	end

	-- Update animation
	ship.animation_timer = ship.animation_timer + dt

	-- Handle animation frame updates
	if ship.current_animation == "running" then
		-- Cycle through running frames
		if ship.animation_timer >= ship.animation_speed then
			ship.animation_timer = 0
			ship.current_frame = ship.current_frame + 1
			if ship.current_frame > #ship.running_frames then
				ship.current_frame = 1
			end
		end
	else
		-- Reset to first frame for idle
		ship.current_frame = 1
		ship.animation_timer = 0
	end

	-- Update Box2D world
  -- disable linter
	world:update(dt)
end

local function draw()
	-- Get position and rotation from Box2D body
	local x, y = ship.body:getPosition()
	local rotation = ship.body:getAngle()
	local vx, vy = ship.body:getLinearVelocity()
	local speed = math.sqrt(vx ^ 2 + vy ^ 2)

	-- Select the correct animation frame
	local current_quad
	if ship.current_animation == "running" then
		current_quad = ship.running_frames[ship.current_frame]
	else
		current_quad = ship.idle_frames[1]
	end

	-- Draw with explicit parameters: image, quad, x, y, rotation, scale_x, scale_y
	-- Note: We need to offset the rotation point to center of sprite (8, 8) for 16x16 sprite
	love.graphics.draw(ship.sheet, current_quad, x, y, rotation + ship.initial_rotation, 4, 4, 8, 8)

	-- Debug information
	love.graphics.print("Ship position: " .. math.floor(x) .. ", " .. math.floor(y), 10, 10)
	love.graphics.print("Rotation: " .. math.floor(math.deg(rotation)) .. "°", 10, 25)
	love.graphics.print("Velocity: " .. math.floor(vx) .. ", " .. math.floor(vy), 10, 40)
	love.graphics.print("Speed: " .. math.floor(speed), 10, 55)
	love.graphics.print("Animation: " .. ship.current_animation .. " (frame " .. ship.current_frame .. ")", 10, 70)
	love.graphics.print("Controls: W=Accelerate, A/D=Rotate", 10, 85)
	love.graphics.print("Box2D Physics Active", 10, 100)
end

love.load = load
love.update = update
love.draw = draw
