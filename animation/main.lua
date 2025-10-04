-- Simple Platformer Game
-- Character with idle/run animations and terrain

local player = {
	x = 100,
	y = 650,
	width = 32,
	height = 48,
	velocity_x = 0,
	velocity_y = 0,
	speed = 200,
	jump_power = 400,
	on_ground = false,
	state = "idle", -- "idle" or "running"
	direction = 1, -- 1 for right, -1 for left
	anim_timer = 0,
	current_animation = "idle",
	current_frame = 1,
	frame_timer = 0,
}

local idle_sprite_sheet = nil
local idle_sprite_sheet_width = 0
local idle_sprite_sheet_height = 0

local running_sprite_sheet = nil
local running_sprite_sheet_width = 0
local running_sprite_sheet_height = 0

local background_image = nil
local foreground_image = nil

-- Camera system
local camera = {
	x = 0,
	y = 0,
}

-- Ground collision height (for player physics)

local gravity = 800
local ground_y = 710

local animations = {
	idle = {
		sheet = nil,
		frames = {},
		frame_duration = 0.2,
		total_frames = 6,
	},
	running = {
		sheet = nil,
		frames = {},
		frame_duration = 0.1,
		total_frames = 8,
	},
}

local function update_animation(dt)
	local anim = animations[player.current_animation]

	player.frame_timer = player.frame_timer + dt

	if player.frame_timer >= anim.frame_duration then
		player.frame_timer = 0
		player.current_frame = player.current_frame + 1

		if player.current_frame > anim.total_frames then
			player.current_frame = 1 -- Loop back
		end
	end
end

local function update_camera()
	-- Camera follows player horizontally
	local screen_center = love.graphics.getWidth() / 2
	camera.x = player.x - screen_center
end

local function load()
	-- Set window size
	love.window.setMode(1024, 768) -- width, height

	love.graphics.setDefaultFilter("nearest", "nearest")

	idle_sprite_sheet = love.graphics.newImage("Idle.png")
	idle_sprite_sheet_width = idle_sprite_sheet:getWidth()
	idle_sprite_sheet_height = idle_sprite_sheet:getHeight()

	running_sprite_sheet = love.graphics.newImage("Run.png")
	running_sprite_sheet_width = running_sprite_sheet:getWidth()
	running_sprite_sheet_height = running_sprite_sheet:getHeight()

	-- Load background image
	background_image = love.graphics.newImage("background.png")

	-- Load foreground image
	foreground_image = love.graphics.newImage("foreground.png")

	-- Update the sheet references after loading
	animations.idle.sheet = idle_sprite_sheet
	animations.running.sheet = running_sprite_sheet

	-- Create quads with correct dimensions
	animations.idle.frames = {
		love.graphics.newQuad(46, 60, 36, 68, idle_sprite_sheet_width, idle_sprite_sheet_height),
		love.graphics.newQuad(174, 60, 36, 68, idle_sprite_sheet_width, idle_sprite_sheet_height),
		love.graphics.newQuad(302, 60, 36, 68, idle_sprite_sheet_width, idle_sprite_sheet_height),
		love.graphics.newQuad(430, 60, 36, 68, idle_sprite_sheet_width, idle_sprite_sheet_height),
		love.graphics.newQuad(558, 60, 36, 68, idle_sprite_sheet_width, idle_sprite_sheet_height),
		love.graphics.newQuad(686, 60, 36, 68, idle_sprite_sheet_width, idle_sprite_sheet_height),
	}

	animations.running.frames = {
		love.graphics.newQuad(31, 62, 38, 66, running_sprite_sheet_width, running_sprite_sheet_height),
		love.graphics.newQuad(154, 62, 46, 66, running_sprite_sheet_width, running_sprite_sheet_height),
		love.graphics.newQuad(275, 62, 49, 66, running_sprite_sheet_width, running_sprite_sheet_height),
		love.graphics.newQuad(412, 62, 42, 66, running_sprite_sheet_width, running_sprite_sheet_height),
		love.graphics.newQuad(543, 62, 39, 66, running_sprite_sheet_width, running_sprite_sheet_height),
		love.graphics.newQuad(667, 62, 44, 66, running_sprite_sheet_width, running_sprite_sheet_height),
		love.graphics.newQuad(791, 62, 49, 66, running_sprite_sheet_width, running_sprite_sheet_height),
		love.graphics.newQuad(925, 62, 44, 66, running_sprite_sheet_width, running_sprite_sheet_height),
	}
end

local function update(dt)
	-- Handle input
	local left = love.keyboard.isDown("left") or love.keyboard.isDown("a")
	local right = love.keyboard.isDown("right") or love.keyboard.isDown("d")
	local jump = love.keyboard.isDown("space") or love.keyboard.isDown("w") or love.keyboard.isDown("up")

	-- Jump
	if jump and player.on_ground then
		player.velocity_y = -player.jump_power
	end

	-- Horizontal movement
	if left then
		player.velocity_x = -player.speed
		player.direction = -1
		player.state = "running"
	elseif right then
		player.velocity_x = player.speed
		player.direction = 1
		player.state = "running"
	else
		player.velocity_x = 0
		player.state = "idle"
	end

	-- Apply gravity
	player.velocity_y = player.velocity_y + gravity * dt

	-- Update position
	player.x = player.x + player.velocity_x * dt
	player.y = player.y + player.velocity_y * dt

	-- Ground collision
	if player.y + player.height >= ground_y then
		player.y = ground_y - player.height
		player.velocity_y = 0
		player.on_ground = true
	else
		player.on_ground = false
	end

	local new_animation = "idle"
	if math.abs(player.velocity_x) > 0 then
		new_animation = "running"
	end

	-- Reset frame when switching animations
	if player.current_animation ~= new_animation then
		player.current_animation = new_animation
		player.current_frame = 1
		player.frame_timer = 0
	end

	update_animation(dt)

	-- Update camera
	update_camera()
end

local function drawBackground()
	-- Draw background image (behind everything)
	if background_image then
		love.graphics.setColor(1, 1, 1, 1) -- Reset color to white

		-- Calculate scale to fill window while maintaining aspect ratio
		local window_width = love.graphics.getWidth()
		local window_height = love.graphics.getHeight()
		local image_width = background_image:getWidth()
		local image_height = background_image:getHeight()

		-- Calculate scale factors for both dimensions
		local scale_x = window_width / image_width
		local scale_y = window_height / image_height

		-- Use the larger scale to fill the entire window (may crop image)
		local scale = math.max(scale_x, scale_y)

		-- Calculate centered position
		local scaled_width = image_width * scale
		local scaled_height = image_height * scale
		local x = (window_width - scaled_width) / 2
		local y = (window_height - scaled_height) / 2

		love.graphics.draw(background_image, x + scaled_width, y, 0, -scale, scale)
	end
end

local function drawForeground()
	-- Draw foreground image (scrolling ground) - tiled to create infinite scrolling
	if foreground_image then
		love.graphics.setColor(1, 1, 1, 1) -- Reset color to white

		local image_width = foreground_image:getWidth()
		local screen_width = love.graphics.getWidth()

		-- Calculate how many times to tile the image
		local tiles_needed = math.ceil(screen_width / image_width) + 2

		-- Draw tiled foreground with camera offset
		for i = -1, tiles_needed do
			local x = (i * image_width) - (camera.x % image_width)
			-- Position foreground at ground level
			local y = ground_y - foreground_image:getHeight()
			love.graphics.draw(foreground_image, x, y, 0, 1, 1.2)
		end
	end
end

local function drawPlayer()
	local anim = animations[player.current_animation]
	local current_quad = anim.frames[player.current_frame]

	-- Reset color to white (no tinting) before drawing sprite
	love.graphics.setColor(1, 1, 1, 1)

	-- Draw player relative to camera
	local screen_x = player.x - camera.x
	local screen_y = player.y

	if player.direction == -1 then
		love.graphics.draw(anim.sheet, current_quad, screen_x + player.width, screen_y, 0, -1, 1)
	else
		love.graphics.draw(anim.sheet, current_quad, screen_x, screen_y)
	end
end

local function draw()
	-- Draw background (static)
	drawBackground()

	-- Draw foreground (scrolling)
	drawForeground()

	-- Draw player
	drawPlayer()

	-- Debug info
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("State: " .. player.state, 10, 10)
	love.graphics.print("Position: " .. math.floor(player.x) .. ", " .. math.floor(player.y), 10, 25)
	love.graphics.print("Velocity: " .. math.floor(player.velocity_x) .. ", " .. math.floor(player.velocity_y), 10, 40)
	love.graphics.print("Camera: " .. math.floor(camera.x), 10, 55)
	love.graphics.print("Controls: A/D to move, Space/W/Up to jump", 10, 70)
end

-- Register LÖVE2D callbacks
love.load = load
love.update = update
love.draw = draw
