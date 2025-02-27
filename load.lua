-- Chargement des ressources
function love.load()
	-- Initialisation de la graine pour obtenir des nombres aléatoires différents à chaque exécution
	math.randomseed(os.time()) 
	-- Chargement de l'image de fond
	background = love.graphics.newImage("background.png")
	
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
	
	enemy = {
		x = WINDOW_WIDTH - 150,
		-- Générer une position Y aléatoire pour l'ennemi
		y = love.math.random(200, 600),
		width = 128,
		height = 64,
		speed = 100,
		image = love.graphics.newImage('enemy.png')
	}
end

-- Dessiner le jeu
function DrawGame()
	-- Dessiner le jeu
	love.graphics.draw(background, 0, 0) -- Dessiner l'image de fond
	
	DrawPlayer() -- Dessiner le joueur
	DrawEnemy() -- Dessiner l'ennemi
	
	-- Afficher le score et la vie
	love.graphics.print("Score: " .. score, 10, 10)
	love.graphics.print("Vie : " .. playerHealth, 550, 10)
end

-- Dessiner le joueur avec la nouvelle taille et orientation
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

-- Dessiner l'ennemi avec la nouvelle taille
function DrawEnemy()
	local scale = enemy.width / 128
	love.graphics.draw(enemy.image, enemy.x, enemy.y, 0, scale, enemy.height / 64)
end

-- Dessiner le Menu
function DrawMenu()
	-- Dessiner le menu
	local title = "ASCII WarZ"
	local startText = "Start"
	local quitText = "Quit"
	love.graphics.printCentered(title, 170)
	love.graphics.printCentered(startText, 300)
	love.graphics.printCentered(quitText, 350)
end