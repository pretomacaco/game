music = love.audio.newSource("orgia.mp3", "stream")
music:play()

function love.load()
    love.window.setTitle("boyllet friell")
    originalWidth, originalHeight = 800, 600
    love.window.setMode(originalWidth, originalHeight, {
        resizable = true,
        borderless = false
    })
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    bgImage = love.graphics.newImage("images/bg.jpg")
    playerImage = love.graphics.newImage("images/player.png")
    obstacleImage = love.graphics.newImage("images/obstacle.jpg")

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

    youCheatedImage = love.graphics.newImage("images/youcheated.png")

    playerWidth, playerHeight = 50, 50
    obstacleWidth, obstacleHeight = 50, 50
    gunWidth, gunHeight = 30, 30

    staticShader = love.graphics.newShader([[
        extern float time;
        extern float noiseIntensity;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            float noise = (sin(texture_coords.x * 100.0 + time * 10.0) + cos(texture_coords.y * 100.0 + time * 10.0)) * noiseIntensity;
            vec4 pixel = Texel(texture, texture_coords + vec2(noise, noise) * 0.01) * color;
            return pixel;
        }
    ]])

    rainbowShader = love.graphics.newShader([[
        extern float time;
        extern float frequency;
        extern float amplitude;
        extern float speed;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            float wave = sin(texture_coords.y * frequency + time * speed) * amplitude;
            vec2 distortedCoords = vec2(texture_coords.x + wave, texture_coords.y);
            vec4 pixel = Texel(texture, distortedCoords) * color;
            float r = pixel.r + 0.5 * sin(time * 3.0);
            float g = pixel.g + 0.5 * sin(time * 2.0);
            float b = pixel.b + 0.5 * sin(time * 4.0);
            return vec4(r, g, b, pixel.a);
        }
    ]])

    math.randomseed(os.time())
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
    shakeDuration = 5
    shakeAmount = 5
    shakeFrequency = 0.05
    shakeTimer = 0
    gunAcquired = false
    gunTimer = 0
    score = 0
    lastObstacleIncrement = 0
    youCheated = false
    showGunMessage = false
    gunMessageTimer = 0
    gunMessageDuration = 5
end

function love.update(dt)
    if gameOver or youCheated then
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

        if youCheated then
            rainbowShader:send("time", love.timer.getTime())
            rainbowShader:send("frequency", 10)
            rainbowShader:send("amplitude", 0.03)
            rainbowShader:send("speed", 3)
        elseif gameOver then
            staticShader:send("time", love.timer.getTime())
            staticShader:send("noiseIntensity", 0.1)
        end

        return
    end

    if not gunAcquired then
        gunTimer = gunTimer + dt
        if gunTimer >= 10 then
            player.hasGun = true
            gunAcquired = true
            showGunMessage = true
            gunMessageTimer = gunMessageDuration
        end
    end

    if showGunMessage then
        gunMessageTimer = gunMessageTimer - dt
        if gunMessageTimer <= 0 then
            showGunMessage = false
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
    if love.keyboard.isDown("space") and player.hasGun and bulletTimer >= 2 then
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

function love.keypressed(key)
    if key == "7" then
        youCheated = true
        print("Você trapaceou!")
    end
end

function love.draw()
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.draw(bgImage, 0, 0, 0, love.graphics.getWidth() / bgImage:getWidth(), love.graphics.getHeight() / bgImage:getHeight())
    love.graphics.setColor(1, 1, 1)

    if gameOver then
        love.graphics.setShader(staticShader)
        staticShader:send("time", love.timer.getTime())
        staticShader:send("noiseIntensity", 0.1)
        if gameOverImage then
            love.graphics.draw(gameOverImage, 0, 0, 0, love.graphics.getWidth() / gameOverImage:getWidth(), love.graphics.getHeight() / gameOverImage:getHeight())
        else
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("Game Over", 0, love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        end
        love.graphics.setShader()
        return
    end

    if youCheated then
        love.graphics.setShader(rainbowShader)
        rainbowShader:send("time", love.timer.getTime())
        rainbowShader:send("frequency", 10)
        rainbowShader:send("amplitude", 0.03)
        rainbowShader:send("speed", 3)
        love.graphics.draw(youCheatedImage, 0, 0, 0, love.graphics.getWidth() / youCheatedImage:getWidth(), love.graphics.getHeight() / youCheatedImage:getHeight())
        love.graphics.setShader()
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

    love.graphics.print("Pontos: " .. score, 10, 10)

    if showGunMessage then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("PRESS SPACE TO SHOOT", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")
    end
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end
