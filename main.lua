-- Définition des dimensions de la fenêtre
function love.conf(t)
	t.window.width = 800
	t.window.height = 600
end

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

-- Variables globales
taille_de_la_police_title = 90
local titleFont = love.graphics.newFont("asciid.ttf", taille_de_la_police_title)
taille_de_la_police_button = 60
local buttonTextFont = love.graphics.newFont("computer.ttf", taille_de_la_police_button)
taille_de_la_police_HUD = 30
local buttonTextHUD = love.graphics.newFont("computer2.ttf", taille_de_la_police_HUD)

local healthBonusTimer = 0
local timeBetweenHealthBonuses = 10 -- En secondes
local lifeBonusCollected = false
local timeSinceLastLifeBonus = 0

local score = 0
local spacePressed = false
local playerHealth = 10
local timeSinceLastHit = 0
local minTimeBetweenHits = 1
local inMenu = true
local difficultyLevel = 1
local baseEnemyCount = 1
local enemyCountIncreasePerLevel = 0.5
local enemyGenerationTimer = 0
local enemyGenerationInterval = 3
local time = 0 -- Définir une variable pour le temps
local enemies = {}
local player
local backEnemy
local lifeBonuses = {}
local lifeBonusImage
local heartImage

-- Chargement des ressources
function love.load()
	math.randomseed(os.time())
	background = love.graphics.newImage("background.png")
	backgroundmenu = love.graphics.newImage("backgroundmenu.png")
	
	player = {
		x = 50,
		y = WINDOW_HEIGHT / 2,
		width = 128,
		height = 64,
		speed = 200,
		images = {
			default = love.graphics.newImage('player_default.png'),
			punch = love.graphics.newImage('player_punch.png')
		},
		currentImage = 'default',
		dx = 0,
		dy = 0
	}

	lifeBonusImage = love.graphics.newImage("bonus.png")
	heartImage = love.graphics.newImage("heart.png")
	backEnemy = {
		x = WINDOW_WIDTH / 2,
		y = WINDOW_HEIGHT / 2,
		speed = 100,
		dx = 0,
		dy = 0,
		image = love.graphics.newImage('enemy2.png') 
	}
	
	GenerateRandomEnemies(5)
end

-- Définition de la fonction CheckCollisionWithEnemies
function CheckCollisionWithEnemies(player)
	for _, enemy in ipairs(enemies) do
		if CheckCollision(player, enemy) then
			return true
		end
	end
	return false
end

-- Mise à jour de l'état du jeu
function love.update(dt)
	-- Mettre à jour le temps
	time = time + dt
	enemyGenerationTimer = enemyGenerationTimer + dt

	if inMenu then
		return
	end

	if enemyGenerationTimer >= enemyGenerationInterval then
		local currentEnemyCount = baseEnemyCount + math.floor(difficultyLevel * enemyCountIncreasePerLevel)
		if #enemies < currentEnemyCount then
			local newEnemyCount = currentEnemyCount - #enemies
			GenerateRandomEnemies(newEnemyCount)
		end
		enemyGenerationTimer = 0
	end

	difficultyLevel = difficultyLevel + (dt / 100) * 1

	timeSinceLastLifeBonus = timeSinceLastLifeBonus + dt
	if timeSinceLastLifeBonus >= 10 then
		GenerateLifeBonus()
		timeSinceLastLifeBonus = 0
	end

	for _, enemy in ipairs(enemies) do
		local dx = player.x - enemy.x
		local dy = player.y - enemy.y
		local distance = math.sqrt(dx * dx + dy * dy)
		if distance ~= 0 then
			dx = dx / distance
			dy = dy / distance
		end
		enemy.x = enemy.x + dx * enemy.speed * dt
		enemy.y = enemy.y + dy * enemy.speed * dt

		UpdateEnemyMovement(dt)

		local sizeFactor2 = 1 + (enemy.y - 150) / (600 - 150)
		enemy.width = 128 * sizeFactor2
		enemy.height = 64 * sizeFactor2
	end

	local dx, dy = 0, 0
	if love.keyboard.isDown('up') then
		if player.y > 40 then
			dy = dy - 1
		end
	elseif love.keyboard.isDown('down') then
		if player.y < 700 then
			dy = dy + 1
		end
	elseif love.keyboard.isDown('right') then
		dx = dx + 1
	elseif love.keyboard.isDown('left') then
		dx = dx - 1
	end

	if dx ~= 0 and dy ~= 0 then
		dx = dx * math.sqrt(0.5)
		dy = dy * math.sqrt(0.5)
	end

	player.x = player.x + player.speed * dx * dt
	player.y = player.y + player.speed * dy * dt

	local sizeFactor = 1 + (player.y - 150) / (600 - 150)
	player.width = 128 * sizeFactor
	player.height = 64 * sizeFactor

	if love.keyboard.isDown('space') and not spacePressed then
		player.currentImage = 'punch'
		for i, enemy in ipairs(enemies) do
			if CheckCollision(player, enemy) then
				score = score + 1
				spacePressed = true
				table.remove(enemies, i)
				break
			end
		end
	else
		player.currentImage = 'default'
	end

	player.x = math.max(0, math.min(player.x, WINDOW_WIDTH - player.width))
	player.y = math.max(0, math.min(player.y, WINDOW_HEIGHT - player.height))

	timeSinceLastHit = timeSinceLastHit + dt

	UpdatePlayerMovement(dt)

	HandlePlayerCollisionWithHealthBonus()

	UpdateBackEnemy(dt, backEnemy, player)

	for _, enemy in ipairs(enemies) do
		UpdateBackEnemy(dt, enemy, player)
	end

	HandlePlayerAttack()
	
	-- Vérification des collisions avec les bonus de vie
	for _, bonus in ipairs(lifeBonuses) do
		if bonus.active and CheckCollision(player, bonus) then
			playerHealth = playerHealth + 1
			bonus.active = false
		end
	end
	
	-- Collision avec les ennemis
	if CheckCollisionWithEnemies(player) then
		if timeSinceLastHit >= minTimeBetweenHits then
			playerHealth = playerHealth - 1
			timeSinceLastHit = 0
		end
	end
	
	if playerHealth <= 0 then
		ResetGame()
	end
end

-- Mise à jour du mouvement des ennemis
function UpdateEnemyMovement(dt)
	for i, enemy in ipairs(enemies) do
		UpdateSingleEnemyMovement(dt, enemy)
		for j, otherEnemy in ipairs(enemies) do
			if i ~= j and CheckCollision(enemy, otherEnemy) then
				ResolveEnemyCollision(enemy, otherEnemy)
			end
		end
	end
end

function CheckCollisionWithPlayer(player, object)
	local playerLeft = player.x
	local playerRight = player.x + player.width
	local playerTop = player.y
	local playerBottom = player.y + player.height
	
	local objectLeft = object.x
	local objectRight = object.x + object.width
	local objectTop = object.y
	local objectBottom = object.y + object.height
	
	if playerRight > objectLeft and
	   playerLeft < objectRight and
	   playerBottom > objectTop and
	   playerTop < objectBottom then
		if object.type == "lifeBonus" and not lifeBonusCollected then
			playerHealth = playerHealth + 5
			lifeBonusCollected = true
		end
		return true
	else
		if object.type == "lifeBonus" and not CheckCollisionWithOffset(player, object, 20) then
			lifeBonusCollected = false
		end
		return false
	end
end

function UpdatePlayerMovement(dt)
	if love.keyboard.isDown('right') then
		player.dx = 1
	elseif love.keyboard.isDown('left') then
		player.dx = -1
	else
		player.dx = 0
	end

	if love.keyboard.isDown('down') then
		player.dy = 1
	elseif love.keyboard.isDown('up') then
		player.dy = -1
	else
		player.dy = 0
	end

	local speed = 200

	player.x = player.x + player.dx * speed * dt
	player.y = player.y + player.dy * speed * dt
end

function UpdateSingleEnemyMovement(dt, enemy)
	local dx = player.x - enemy.x
	local dy = player.y - enemy.y
	local distance = math.sqrt(dx * dx + dy * dy)

	if distance ~= 0 then
		dx = dx / distance
		dy = dy / distance
	end

	local new_x = enemy.x + dx * enemy.speed * dt
	local new_y = enemy.y + dy * enemy.speed * dt

	for _, otherEnemy in ipairs(enemies) do
		if enemy ~= otherEnemy and CheckCollisionWithOffset({x = new_x, y = new_y, width = enemy.width, height = enemy.height}, otherEnemy, 10) then
			return
		end
	end

	enemy.x = new_x
	enemy.y = new_y
end

function CheckCollisionWithOffset(object1, object2, offset)
	return object1.x + object1.width - offset > object2.x and
		   object1.x + offset < object2.x + object2.width and
		   object1.y + object1.height - offset > object2.y and
		   object1.y + offset < object2.y + object2.height
end

function UpdateBackEnemy(dt, enemy, player)
	local dx = player.x - enemy.x
	local dy = player.y - enemy.y
	local distance = math.sqrt(dx * dx + dy * dy)

	if distance ~= 0 then
		dx = dx / distance
		dy = dy / distance
	end

	enemy.x = enemy.x + dx * enemy.speed * dt
	enemy.y = enemy.y + dy * enemy.speed * dt
end

function HandlePlayerCollisionWithHealthBonus()
	for _, bonus in ipairs(lifeBonuses) do
		if bonus.active and CheckCollision(player, bonus) then
			playerHealth = playerHealth + 1
			bonus.active = false
		end
	end
end

-- Fonction pour vérifier la collision entre deux rectangles
function CheckCollision(a, b)
	return a.x < b.x + b.width and
		   b.x < a.x + a.width and
		   a.y < b.y + b.height and
		   b.y < a.y + a.height
end

function ResetGame()
	enemies = {}
	score = 0
	playerHealth = 10
	spacePressed = false
	timeSinceLastHit = 0
	difficultyLevel = 1
	enemyGenerationTimer = 0
end

function GenerateRandomEnemies(count)
	for i = 1, count do
		local enemy = {
			x = math.random(WINDOW_WIDTH),
			y = math.random(WINDOW_HEIGHT),
			speed = 50,
			width = 64,
			height = 32,
			image = love.graphics.newImage('enemy.png')
		}
		table.insert(enemies, enemy)
	end
end

-- Fonction pour générer un bonus de vie
function GenerateLifeBonus()
	local bonus = {
		x = math.random(0, WINDOW_WIDTH - 32),
		y = math.random(0, WINDOW_HEIGHT - 32),
		width = 32,
		height = 32,
		active = true,
		image = heartImage
	}
	table.insert(lifeBonuses, bonus)
end

-- Fonction pour dessiner les bonus de vie
function DrawLifeBonuses()
	for _, bonus in ipairs(lifeBonuses) do
		if bonus.active then
			love.graphics.draw(bonus.image, bonus.x, bonus.y, 0, bonus.width / bonus.image:getWidth(), bonus.height / bonus.image:getHeight())
		end
	end
end

-- Résoudre les collisions entre ennemis
function ResolveEnemyCollision(enemy1, enemy2)
	local overlapX = math.min(enemy1.x + enemy1.width - enemy2.x, enemy2.x + enemy2.width - enemy1.x)
	local overlapY = math.min(enemy1.y + enemy1.height - enemy2.y, enemy2.y + enemy2.height - enemy1.y)

	if overlapX < overlapY then
		if enemy1.x < enemy2.x then
			enemy1.x = enemy1.x - overlapX / 2
			enemy2.x = enemy2.x + overlapX / 2
		else
			enemy1.x = enemy1.x + overlapX / 2
			enemy2.x = enemy2.x - overlapX / 2
		end
	else
		if enemy1.y < enemy2.y then
			enemy1.y = enemy1.y - overlapY / 2
			enemy2.y = enemy2.y + overlapY / 2
		else
			enemy1.y = enemy1.y + overlapY / 2
			enemy2.y = enemy2.y - overlapY / 2
		end
	end
end

-- Dessiner à l'écran
function love.draw()
	if inMenu then
		love.graphics.draw(backgroundmenu, 0, 0, 0, WINDOW_WIDTH / backgroundmenu:getWidth(), WINDOW_HEIGHT / backgroundmenu:getHeight())
		DrawMenu()
		return
	end

	love.graphics.draw(background, 0, 0, 0, WINDOW_WIDTH / background:getWidth(), WINDOW_HEIGHT / background:getHeight())
	love.graphics.setFont(buttonTextHUD)
	love.graphics.printf("Score: " .. score, 10, 10, WINDOW_WIDTH, 'left')
	love.graphics.printf("Vie: " .. playerHealth, 10, 50, WINDOW_WIDTH, 'left')
	love.graphics.draw(player.images[player.currentImage], player.x, player.y, 0, player.width / player.images[player.currentImage]:getWidth(), player.height / player.images[player.currentImage]:getHeight())

	DrawLifeBonuses()

	for _, enemy in ipairs(enemies) do
		love.graphics.draw(enemy.image, enemy.x, enemy.y, 0, enemy.width / enemy.image:getWidth(), enemy.height / enemy.image:getHeight())
	end
	
	DrawPlayerHealth()

	love.graphics.setFont(titleFont)
	love.graphics.printf("Your Game Title", 0, 50, WINDOW_WIDTH, 'center')
end

function DrawMenu()
	love.graphics.setFont(titleFont)
	love.graphics.printf("Game Menu", 0, WINDOW_HEIGHT / 4, WINDOW_WIDTH, 'center')
	love.graphics.setFont(buttonTextFont)
	love.graphics.printf("Press Enter to Start", 0, WINDOW_HEIGHT / 2, WINDOW_WIDTH, 'center')
end

function love.keypressed(key)
	if key == 'space' then
		spacePressed = true
	end

	if key == 'return' and inMenu then
		inMenu = false
	end
end

function love.keyreleased(key)
	if key == 'space' then
		spacePressed = false
	end
end

function HandlePlayerAttack()
	if spacePressed then
		player.currentImage = 'punch'
		for i, enemy in ipairs(enemies) do
			if CheckCollision(player, enemy) then
				score = score + 1
				table.remove(enemies, i)
				break
			end
		end
	else
		player.currentImage = 'default'
	end
end

function DrawPlayerHealth()
	love.graphics.print("Health: " .. playerHealth, 10, 10)
end
