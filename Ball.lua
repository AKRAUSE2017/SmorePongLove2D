Ball = Class{}

function Ball:init(x, y, width, height)
    -- position and dimensions
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- delta x and delta y represent ball velocity/speed
    -- for DX generate random number between 1 and 2
    -- if rand num is 1 then DX is 100, otherwise it's -100
    -- delta y can be anywhere between -50 and 50
    -- random numbers are inclusive
    self.dx = math.random(2) == 1 and -100 or 100
    self.dy = math.random(-50, 50)
end

function Ball:collides(paddle)
    -- if the ball's left edge is beyond the paddle's right edge
    -- or if the paddle's left edge is beyond the ball's right edge
    if self.x > paddle.x + paddle.width or paddle.x > self.x + self.width then
        return false
    end

    -- if the ball's top edge is beyond the paddle's bottom edge
    -- or if the paddle's top edge is beyond the ball's bottom edge
    if self.y > paddle.y + paddle.height or paddle.y > self.y + self.height then
        return false
    end
    
    -- overlapping
    return true
end

function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - (self.width / 2)
    self.y = VIRTUAL_HEIGHT / 2 - (self.height / 2)
    self.dy = math.random(2) == 1 and -100 or 100 -- if else ternary logic
    self.dx = math.random(-50, 50)
end

function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Ball:render(image, scale)
    love.graphics.draw(image, self.x, self.y, 0, scale, scale) -- ball
end