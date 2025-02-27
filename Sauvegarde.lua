-- Définition des dimensions de la fenêtre
function love.conf(t)
	t.window.width = 800
	t.window.height = 600
end
-- Variables globales
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

local titleFont
local buttonTextFont
local buttonTextHUD

local dx, dy = 0, 0
local time = 0
local inMenu = true
local background
local baseEnemyCount = 1
local enemyCountIncreasePerLevel = 0.5
local enemyGenerationTimer = 0
local enemyGenerationInterval = 3
local difficultyLevel = 1
local score = 0
local spacePressed = false
local playerHealth = 10
local timeSinceLastHit = 0

local enemies = {}
local backEnemy = {}

-- Chargement des ressources


-- Déclaration de la variable player en tant que variable globale
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

-- Déclaration de la variable backEnemy
local backEnemy = {
	x = WINDOW_WIDTH / 2,
	y = WINDOW_HEIGHT / 2,
	speed = 100,
	dx = 0,
	dy = 0,
	image = love.graphics.newImage('enemy2.png')  -- Assurez-vous que l'image est correctement chargée
}

taille_de_la_police_title = 90
local titleFont = love.graphics.newFont("asciid.ttf", taille_de_la_police_title)
taille_de_la_police_button = 60
local buttonTextFont = love.graphics.newFont("computer.ttf", taille_de_la_police_button)
taille_de_la_police_HUD = 30
local buttonTextHUD = love.graphics.newFont("computer2.ttf", taille_de_la_police_HUD)

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
		currentImage = 'default'
	}

	backEnemy = {
		x = WINDOW_WIDTH / 2,
		y = WINDOW_HEIGHT / 2,
		speed = 100,
		dx = 0,  -- Assurez-vous que dx est initialisé
		dy = 0,  -- Assurez-vous que dy est initialisé
		image = love.graphics.newImage('enemy2.png') 
	}
	-- Initialisation des variables globales dx et dy pour le joueur
	player.dx = 0
	player.dy = 0

	GenerateRandomEnemies(5)
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

	difficultyLevel = difficultyLevel + (dt / 100 ) * 1
	
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
	
	dx, dy = 0, 0
	if love.keyboard.isDown('up') then
		if player.y > 40 then
			dy = dy - 1
		end
		if player.y < 200 then
			player.y = 200
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
end

-- Mise à jour du mouvement des ennemis
function UpdateEnemyMovement(dt)
	for i, enemy in ipairs(enemies) do
		UpdateSingleEnemyMovement(dt, enemy)
		-- Vérifier la collision avec d'autres ennemis
		for j, otherEnemy in ipairs(enemies) do
			if i ~= j and CheckCollision(enemy, otherEnemy) then
				ResolveEnemyCollision(enemy, otherEnemy)
			end
		end
	end
end

-- Fonction pour mettre à jour le mouvement d'un seul ennemi
function UpdateSingleEnemyMovement(dt, enemy)
	-- Calculer la direction vers le joueur
	local dx = player.x - enemy.x
	local dy = player.y - enemy.y
	local distance = math.sqrt(dx * dx + dy * dy)

	-- Normaliser le vecteur de direction
	if distance ~= 0 then
		dx = dx / distance
		dy = dy / distance
	end

	-- Déplacer l'ennemi vers le joueur en évitant les collisions avec d'autres ennemis
	local new_x = enemy.x + dx * enemy.speed * dt
	local new_y = enemy.y + dy * enemy.speed * dt

	-- Vérifier les collisions avec d'autres ennemis
	for _, otherEnemy in ipairs(enemies) do
		if enemy ~= otherEnemy and CheckCollisionWithOffset({x = new_x, y = new_y, width = enemy.width, height = enemy.height}, otherEnemy, 20) then
			-- Il y a une collision, ajuster le mouvement
			new_x = enemy.x
			new_y = enemy.y
			break -- Sortir de la boucle dès qu'une collision est détectée
		end
	end

	-- Mettre à jour la position de l'ennemi
	enemy.x = new_x
	enemy.y = new_y
end

-- Dessiner le jeu
function love.draw()
	if inMenu then
		DrawMenu(time)  -- Passer la valeur de time comme paramètre
	else
		DrawGame()
	end
end

-- Fonction pour dessiner le menu
function DrawMenu(time)
	-- Utiliser la fonction sinus pour créer une animation de vague
	local yOffset = math.sin(time * 2) * 10  -- facteur de fréquence (2) et amplitude (10) 

	-- Utiliser la police pour le titre
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(backgroundmenu, 0, 0)
	love.graphics.setFont(titleFont)  

	local title = "ASCII WarZ"
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(title, WINDOW_WIDTH / 2 - titleFont:getWidth(title) / 2, 198 + yOffset)

	-- Utiliser la police pour les boutons
	love.graphics.setFont(buttonTextFont)
	local startText = "Start"
	local quitText = "Quit"
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(startText, WINDOW_WIDTH / 2 - buttonTextFont:getWidth(startText) / 2, 350)
	love.graphics.print(quitText, WINDOW_WIDTH / 2 - buttonTextFont:getWidth(quitText) / 2, 450)
end

-- Fonction pour dessiner le jeu
function DrawGame()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(background, 0, 0)
	DrawPlayer()
	DrawEnemies()
	DrawBackEnemy()
	love.graphics.setFont(buttonTextHUD)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print("Score: " .. score, 10, 0)
	love.graphics.print("Vie : " .. playerHealth, 650, 0)
end

-- Dessiner l'ennemi
function DrawBackEnemy()
	if backEnemy.image == nil then
		print("Erreur: backEnemy.image est nil")
	else
		love.graphics.draw(backEnemy.image, backEnemy.x, backEnemy.y)
	end
end

function GenerateRandomEnemies(count)
	for i = 1, count do
		local enemy = {
			x = math.random(100, WINDOW_WIDTH - 100),
			y = math.random(100, WINDOW_HEIGHT - 100),
			width = 64,
			height = 64,
			speed = 150,
			dx = 0,
			dy = 0,
			image = love.graphics.newImage('enemy.png')
		}
		table.insert(enemies, enemy)
	end
end

-- Gestion du clic de souris pour le menu
function love.mousepressed(x, y, button, istouch)
	if inMenu then
		if x > 400 and x < 400 + love.graphics.getFont():getWidth("Start") and y > 350 and y < 350 + love.graphics.getFont():getHeight() then
			inMenu = false
		elseif x > 400 and x < 400 + love.graphics.getFont():getWidth("Quit") and y > 450 and y < 450 + love.graphics.getFont():getHeight() then
			love.event.quit()
		end
	end
end

-- Fonction pour vérifier la collision entre deux objets rectangulaires avec un décalage
function CheckCollisionWithOffset(a, b, offset)
	return a.x + a.width + offset > b.x and
		   a.x - offset < b.x + b.width and
		   a.y + a.height + offset > b.y and
		   a.y - offset < b.y + b.height
end

-- Fonction pour vérifier la collision entre deux objets rectangulaires
function CheckCollision(a, b)
	return a.x < b.x + b.width and
		   b.x < a.x + a.width and
		   a.y < b.y + b.height and
		   b.y < a.y + a.height
end

-- Fonction pour dessiner le joueur
function DrawPlayer()
	local playerSprite = player.images[player.currentImage]
	local scale = player.width / 128
	local x, y = player.x, player.y
	if dx < 0 then
		x = x + player.width
		scale = -scale
	end
	love.graphics.draw(playerSprite, x, y, 0, scale, player.height / 64)
end

-- Fonction pour résoudre la collision entre deux ennemis
function ResolveEnemyCollision(enemy1, enemy2)
	-- Calculer le vecteur de déplacement relatif entre les deux ennemis
	local dx = enemy2.x - enemy1.x
	local dy = enemy2.y - enemy1.y
	local distance = math.sqrt(dx * dx + dy * dy)

	-- S'assurer que les ennemis ont un écart minimal de 20 pixels
	local minDistance = 20
	if distance < minDistance then
		-- Calculer le décalage nécessaire pour séparer les ennemis
		local overlap = (minDistance - distance) / 2
		local angle = math.atan2(dy, dx)

		-- Appliquer le décalage aux positions des ennemis
		enemy1.x = enemy1.x - overlap * math.cos(angle)
		enemy1.y = enemy1.y - overlap * math.sin(angle)
		enemy2.x = enemy2.x + overlap * math.cos(angle)
		enemy2.y = enemy2.y + overlap * math.sin(angle)
	end
end

-- Fonction pour dessiner les ennemis
function DrawEnemies()
	for _, enemy in ipairs(enemies) do
		local scale = enemy.width / 128
		love.graphics.draw(enemy.image, enemy.x, enemy.y, 0, scale, enemy.height / 64)
	end
end
