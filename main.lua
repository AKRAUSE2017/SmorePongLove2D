push = require('push')
Class = require('class')

require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
VIRTUAL_WIDTH = 640
VIRTUAL_HEIGHT = 360

PADDLE_SPEED = 200

SCORE_THRESH = 2

AI_ON = false;

function love.load()
    love.window.setTitle('S\'more Pong')
    love.graphics.setDefaultFilter('nearest', 'nearest')
    smallFont = love.graphics.newFont('assets/font.ttf', 10)
    love.graphics.setFont(smallFont)
    bigFont = love.graphics.newFont('assets/font.ttf', 22)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('assets/sounds/paddle_hit.wav', 'static'),
        ['point'] = love.audio.newSource('assets/sounds/point.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('assets/sounds/wall_hit.wav', 'static')
    }
    sounds['paddle_hit']:setVolume(0.25)
    sounds['point']:setVolume(0.25)
    sounds['wall_hit']:setVolume(0.25)

    math.randomseed(os.time()) -- seed random generator with current time in seconds

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    p1Sprites = {}
    p2Sprites = {}
    combinations = {"000", "001", "010", "100", "110", "111", "101", "011"}
    for _, combo in ipairs(combinations) do
        table.insert(p1Sprites, combo)
        p1Sprites[combo] = love.graphics.newImage("sprites/player1/"..combo..".png")
        table.insert(p2Sprites, combo)
        p2Sprites[combo] = love.graphics.newImage("sprites/player2/"..combo..".png")
    end
    
    ballSprite = love.graphics.newImage("sprites/ball.png")

    p1 = Paddle(VIRTUAL_WIDTH-20, VIRTUAL_HEIGHT-50, 10, 40)
    p2 = Paddle(10, 30, 10, 40)
    
    -- center the ball by identifying screen center and offsetting by 
    -- object width and height (origin point is top-left of object)
    ball = Ball(VIRTUAL_WIDTH/2-6.4, VIRTUAL_HEIGHT/2-6.4, 16*0.8, 16*0.8)
    
    gameState = 'start'  -- using string to track game state
end

function love.resize(w,h)
   push:resize(w,h)
end

function love.mousepressed(x, y, button, istouch)
    -- CHECK AI CLICK
    -- print(x,y)
    if x >= WINDOW_WIDTH-90 and x <= WINDOW_WIDTH-50 and y >= 15 and y <= 40 then
        AI_ON = true;
    elseif x >= WINDOW_WIDTH-40 and x <= WINDOW_WIDTH-20 and y >= 15 and y <= 40 then
        AI_ON = false;
    end
    -- CHECK SCORE CLICK
    if x >= 301 and x <= 308 and y >= 26 and y <= 34 and SCORE_THRESH < 10 then
        SCORE_THRESH = SCORE_THRESH + 1;
    elseif x >= 257 and x <= 267 and y >=26 and y <= 34 and SCORE_THRESH > 1 then
        SCORE_THRESH = SCORE_THRESH - 1;
    end
 end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            servingPlayer = math.random(1,2)
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            gameState = 'start'
            -- reset paddle
            p1.hit = {0,0,0}
            p2.hit = {0,0,0}
            p1.score = 0
            p2.score = 0
            -- reset ball position
            ball:reset();
        end
    end
end

function updatePaddles(dt)
    if love.keyboard.isDown('up') then
        p1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        p1.dy = PADDLE_SPEED
    else
        p1.dy = 0
    end

    if AI_ON == false then
        if love.keyboard.isDown('w') then
            p2.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('s') then
            p2.dy = PADDLE_SPEED
        else
            p2.dy = 0
        end
    else
        ballCenterY = ball.y + ball.height/2
        if ballCenterY < p2.y + p2.height/2 and ball.x < VIRTUAL_WIDTH - 2*(VIRTUAL_WIDTH / 3) then
            p2.dy = -PADDLE_SPEED
        elseif ball.y > p2.y + p2.height/2 and ball.x < VIRTUAL_WIDTH - 2*(VIRTUAL_WIDTH / 3) then
            p2.dy = PADDLE_SPEED
        else
            p2.dy = 0
        end
    end

    p1:update(dt)
    p2:update(dt)
end

function handleCollision(p, offset)
    sounds['paddle_hit']:play()
    ballCenterY = ball.y + ball.height/2
    if(ballCenterY < p.y + p.height/3) then
        p.hit[1] = 1 -- top
    elseif(ballCenterY > p.y + p.height/3 and ballCenterY < p.y + (p.height/3)*2) then
        p.hit[2] = 1 -- middle
    else
        p.hit[3] = 1 -- bottom
    end

    ball.dx = -ball.dx * 1.03 -- increase ball's speed and change to opposite direction
    ball.x = offset -- offset position to prevent another collision

     -- keep the velocity in the same direction but randomize it
    if ball.dy < 0 then -- if the current dy is negative (moving up)
        ball.dy = -math.random(50,150) -- keep moving up but at a random velocity
    else
        ball.dy = math.random(50,150) -- keep moving down but at a random velocity
    end  
end

function handleScore(pWin, server)
    sounds['wall_hit']:play()
    servingPlayer = server
    pWin.score = pWin.score + 1
    if pWin.score == SCORE_THRESH then
        sounds['point']:play()
        winningPlayer = server == 1 and 2 or 1
        gameState = 'done'
    else
        ball:reset()
        gameState = 'serve'
    end
end

function updateBall(dt)
    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 2 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140,200)
        end

    elseif gameState == 'play' then
        if ball:collides(p2) then
            offset = p2.x + p2.width -- offset ball using right edge of paddle 2 (remember sprite origins are top left)
            handleCollision(p2, offset)
        end  
        if ball:collides(p1) then
            offset = p1.x - ball.width -- offset ball using left edge of paddle 1 plus width of ball (remember sprite origins are top left)
            handleCollision(p1, offset)
        end

        if ball.y <= 0 then -- if ball is at top of screen
            ball.y = 0 -- offset ball position
            ball.dy = -ball.dy -- change to opposite y direction
        end
        if ball.y >= VIRTUAL_HEIGHT - ball.width then -- if bottom edge of ball is at bottom of screen
            ball.y = VIRTUAL_HEIGHT - ball.width -- offset ball position
            ball.dy = -ball.dy -- change to opposite y direction
        end

        if ball.x < 0 then
            handleScore(p1, 2) -- pass in winning paddle and next server
        end
        if ball.x > VIRTUAL_WIDTH then
            handleScore(p2, 1) -- pass in winning paddle and next server
        end
        
        ball:update(dt)
    end
end

function love.update(dt)
    updatePaddles(dt)
    updateBall(dt)
end

function love.draw()
    push:apply('start')
    love.graphics.clear(40/255, 45/255, 52/255, 255/255)

    if gameState == 'start' then
        love.graphics.setFont(bigFont)
        love.graphics.printf('Welcome to S\'more Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to begin!', 0, 50, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'done' then
        love.graphics.setFont(bigFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 50, VIRTUAL_WIDTH, 'center')
    end

    love.graphics.setColor(0, 255/255, 0, 255/255)
    love.graphics.print("AI ON/OFF", VIRTUAL_WIDTH-60, 10)
    if AI_ON then
        love.graphics.rectangle("fill", VIRTUAL_WIDTH-43, 20, 10, 1)
    else
        love.graphics.rectangle("fill", VIRTUAL_WIDTH-22, 20, 10, 1)
    end

    if SCORE_THRESH < 10 and SCORE_THRESH > 1 then
        love.graphics.print("SCORE LIMIT: - "..tostring(SCORE_THRESH).." +", 60, 10)
    elseif SCORE_THRESH == 10 then
        love.graphics.print("SCORE LIMIT: - "..tostring(SCORE_THRESH).."  ", 60, 10)
    else
        love.graphics.print("SCORE LIMIT:   "..tostring(SCORE_THRESH).." +", 60, 10)
    end
    love.graphics.setColor(1, 1, 1)

    love.graphics.setFont(bigFont)
    love.graphics.print(tostring(p1.score), VIRTUAL_WIDTH/2+38, VIRTUAL_HEIGHT/3)
    love.graphics.print(tostring(p2.score), VIRTUAL_WIDTH/2-50, VIRTUAL_HEIGHT/3)

    ball:render(ballSprite, 0.80)

    p1Combo = tostring(p1.hit[1]) .. tostring(p1.hit[2]) .. tostring(p1.hit[3])
    p1:render(p1Sprites[p1Combo], 0, 1) -- image, rotation, scale

    p2Combo = tostring(p2.hit[1]) .. tostring(p2.hit[2]) .. tostring(p2.hit[3])
    p2:render(p2Sprites[p2Combo], 0, 1) -- image, rotation, scale

    displayFPS()
    
    push:apply('end')
end

function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255/255, 0, 255/255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10) -- concat in lua is '..'
end