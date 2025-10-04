-- Load the image (call this once, typically in love.load())
local maduro
local submarine
local projectile

-- Character properties
local player = {
	x = 500,
	y = 500,
	width = 80,
	height = 80,
	speed = 200, -- pixels per second
}

-- Array of submarines
local submarines = {
	{
		x = 100,
		y = 50,
		shootTimer = 0,
		shootInterval = 2.0, -- seconds between shots
	},
	{
		x = 300,
		y = 50,
		shootTimer = 0,
		shootInterval = 1.5,
	},
	{
		x = 500,
		y = 50,
		shootTimer = 0,
		shootInterval = 3.0,
	},
}

-- Array of active projectiles
local projectiles = {}

function love.load()
	maduro = love.graphics.newImage("assets/maduro.png")
	submarine = love.graphics.newImage("assets/submarine-trs.png")
	projectile = love.graphics.newImage("assets/projectile.png")
end

function love.update(dt)
	-- Handle WASD movement
	if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
		player.y = player.y - player.speed * dt
	end
	if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
		player.y = player.y + player.speed * dt
	end
	if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
		player.x = player.x - player.speed * dt
	end
	if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
		player.x = player.x + player.speed * dt
	end

	-- Update submarine shooting timers and shoot
	for _, sub in ipairs(submarines) do
		sub.shootTimer = sub.shootTimer + dt

		-- Random chance to shoot (not perfectly timed)
		if sub.shootTimer >= sub.shootInterval and math.random() < 0.1 then
			-- Create new projectile
			local dx = player.x - sub.x
			local dy = player.y - sub.y
			local distance = math.sqrt(dx * dx + dy * dy)

			-- Normalize direction vector
			local dirX = dx / distance
			local dirY = dy / distance

			-- Calculate rotation angle in radians
			-- Add π (180 degrees) because projectile image faces left
			local angle = math.atan2(dirY, dirX) + math.pi

			-- Calculate submarine center position
			local subCenterX = sub.x + (submarine:getWidth() * 0.15) / 2

			local proj = {
				x = subCenterX,
				y = sub.y + submarine:getHeight() * 0.15,
				dirX = dirX,
				dirY = dirY,
				speed = 150, -- pixels per second
				angle = angle,
			}
			-- Add projectile to array
			table.insert(projectiles, proj)

			-- Reset timer
			sub.shootTimer = 0
		end
	end

	-- Update projectiles
	for i = #projectiles, 1, -1 do
		local proj = projectiles[i]
		proj.x = proj.x + proj.dirX * proj.speed * dt
		proj.y = proj.y + proj.dirY * proj.speed * dt

		-- Remove projectiles that are off screen
		if proj.x < 0 or proj.x > 800 or proj.y < 0 or proj.y > 600 then
			table.remove(projectiles, i)
		end
	end
end

function love.draw()
	-- Set background color to ocean blue
	love.graphics.clear(0.1, 0.3, 0.5, 1.0) -- RGBA values (0-1 range)

	-- Draw the character at its current position
	if maduro then
		love.graphics.draw(
			maduro,
			player.x,
			player.y,
			0,
			player.width / maduro:getWidth(),
			player.height / maduro:getHeight()
		)
	end

	-- Draw all submarines
	if submarine then
		for _, sub in ipairs(submarines) do
			love.graphics.draw(submarine, sub.x, sub.y, 0, 0.15, 0.15)
		end
	end

	-- Draw all projectiles
	if projectile then
		for _, proj in ipairs(projectiles) do
			-- Use graphics transform for proper rotation
			love.graphics.push()
			love.graphics.translate(proj.x, proj.y)
			love.graphics.rotate(proj.angle)
			love.graphics.draw(projectile, 0, 0, 0, 0.06, 0.06)
			love.graphics.pop()
		end
	end
end
