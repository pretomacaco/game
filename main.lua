function love.load()
    love.window.setTitle("Mini Jogo - Evitar Obstáculos")
    originalWidth, originalHeight = 800, 600
    love.window.setMode(originalWidth, originalHeight, {resizable=true})
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    playerImage = love.graphics.newImage("images/player.png")
    obstacleImage = love.graphics.newImage("images/obstacle.png")

    local success, gunImageLoaded = pcall(love.graphics.newImage, "images/gun.png")
    if success then
        gunImage = gunImageLoaded
    else
        gunImage = nil
        print("Warning: gun.png not found!")
    end

    local success, gameOverImageLoaded = pcall(love.graphics.newImage, "images/9999damage.png")
    if success then
        gameOverImage = gameOverImageLoaded
    else
        gameOverImage = love.graphics.newImage("images/default_game_over.png")
        print("Error: Game Over image '9999damage.png' not found! Using default image.")
    end

    playerWidth, playerHeight = 50, 50
    obstacleWidth, obstacleHeight = 50, 50
    gunWidth, gunHeight = 30, 30

    resetGame()
end

function resetGame()
    player = {
        x = 400,
        y = 550,
        width = playerWidth,
        height = playerHeight,
        speed = 300,
        hasGun = false,
    }
    obstacles = {}
    bullets = {}
    obstacleTimer = 0
    bulletTimer = 0
    obstacleInterval = 1.5
    obstacleIncrementInterval = 10
    obstacleCountIncrement = 0.05
    gameOver = false
    shakeTime = 0
    shakeDuration = 10
    shakeAmount = 130
    shakeFrequency = 0.05
    shakeTimer = 0
    gunAcquired = false
    gunTimer = 0
    score = 0
    lastObstacleIncrement = 0
end

function love.update(dt)
    if gameOver then
        if shakeTime > 0 then
            shakeTime = shakeTime - dt
            shakeTimer = shakeTimer + dt

            local x, y = love.window.getPosition()
            local offsetX = math.sin(shakeTimer * (2 * math.pi / shakeFrequency)) * shakeAmount
            local offsetY = math.cos(shakeTimer * (2 * math.pi / shakeFrequency)) * shakeAmount
            love.window.setPosition(x + offsetX, y + offsetY)

            if shakeTime <= 0 then
                love.event.quit()
            end
        end

        return
    end

    if not gunAcquired then
        gunTimer = gunTimer + dt
        if gunTimer >= 10 then
            player.hasGun = true
            gunAcquired = true
        end
    end

    if love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    elseif love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end

    if player.x < 0 then player.x = 0 end
    if player.x > love.graphics.getWidth() - player.width then player.x = love.graphics.getWidth() - player.width end

    obstacleTimer = obstacleTimer + dt
    if obstacleTimer > obstacleInterval then
        obstacleTimer = 0
        local obstacle = {
            x = math.random(0, love.graphics.getWidth() - obstacleWidth),
            y = -obstacleHeight,
            width = obstacleWidth,
            height = obstacleHeight,
            speed = 600
        }
        table.insert(obstacles, obstacle)
        score = score + 1
    end

    local currentTime = love.timer.getTime()
    if currentTime - lastObstacleIncrement > obstacleIncrementInterval then
        obstacleInterval = math.max(0.5, obstacleInterval - obstacleCountIncrement)
        lastObstacleIncrement = currentTime
    end

    for i, obstacle in ipairs(obstacles) do
        obstacle.y = obstacle.y + obstacle.speed * dt

        if checkCollision(player, obstacle) then
            gameOver = true
            shakeTime = shakeDuration
            shakeTimer = 0
            return
        end

        if obstacle.y > love.graphics.getHeight() then
            table.remove(obstacles, i)
        end
    end

    bulletTimer = bulletTimer + dt
    if love.keyboard.isDown("space") and player.hasGun and bulletTimer >= 0.2 then
        bulletTimer = 0
        local bullet = {
            x = player.x + player.width / 2 - 5,
            y = player.y,
            width = 10,
            height = 20,
            speed = 500
        }
        table.insert(bullets, bullet)
    end

    for i, bullet in ipairs(bullets) do
        bullet.y = bullet.y - bullet.speed * dt

        if bullet.y < -bullet.height then
            table.remove(bullets, i)
        end

        for j, obstacle in ipairs(obstacles) do
            if checkCollision(bullet, obstacle) then
                table.remove(obstacles, j)
                table.remove(bullets, i)
                score = score + 5
                break
            end
        end
    end
end

function love.draw()
    if gameOver then
        if gameOverImage then
            love.graphics.draw(gameOverImage, 0, 0, 0, love.graphics.getWidth() / gameOverImage:getWidth(), love.graphics.getHeight() / gameOverImage:getHeight())
        else
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("Game Over", 0, love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        end
        return
    end

    love.graphics.draw(playerImage, player.x, player.y, 0, playerWidth / playerImage:getWidth(), playerHeight / playerImage:getHeight())
    if player.hasGun and gunImage then
        love.graphics.draw(gunImage, player.x + player.width / 2 - gunWidth / 2, player.y - gunHeight / 2, 0, gunWidth / gunImage:getWidth(), gunHeight / gunImage:getHeight())
    end

    for _, obstacle in ipairs(obstacles) do
        love.graphics.draw(obstacleImage, obstacle.x, obstacle.y, 0, obstacleWidth / obstacleImage:getWidth(), obstacleHeight / obstacleImage:getHeight())
    end

    love.graphics.setColor(1, 1, 0)
    for _, bullet in ipairs(bullets) do
        love.graphics.rectangle("fill", bullet.x, bullet.y, bullet.width, bullet.height)
    end
    love.graphics.setColor(1, 1, 1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Pontos: " .. score, 10, 10)
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end
