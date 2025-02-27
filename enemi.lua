-- tout ce qui est relatif aux ennemis
-- Fonction pour générer une nouvelle position Y aléatoire pour l'ennemi
function GenerateRandomEnemyY()
	enemy.y = love.math.random(200, 600)
end
-- Fonction pour générer une nouvelle position X aléatoire pour l'ennemi
function GenerateRandomEnemyX()
	-- local ennemyRandomX
	ennemyRandomX = math.random() * (1 - 0) + 0  -- Cette expression renverra un nombre aléatoire entre 0 et 1 inclus
	
end

-- génération d'ennemies
function GenerateRandomEnemies(count)
	-- Générer un nombre spécifié d'ennemis avec des positions aléatoires
	for i = 1, count do
		-- Générer une position Y aléatoire pour chaque ennemi
		local enemyY = love.math.random(200, 600)
		-- Générer une position X aléatoire pour chaque ennemi
		local enemyX
		if love.math.random() <= 0.6 then
			enemyX = WINDOW_WIDTH + 150 
		else
			enemyX = -350
		end
		-- Créer un nouvel ennemi avec les positions générées
		local newEnemy = { x = enemyX, y = enemyY, width = 128, height = 64, speed = 100, image = love.graphics.newImage('enemy.png') }
		table.insert(enemies, newEnemy)
	end
end
