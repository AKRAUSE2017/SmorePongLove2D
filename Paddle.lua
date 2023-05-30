Paddle = Class{}

function Paddle:init(x, y, width, height)
    -- position and dimensions
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- delta y velocity (i.e. speed)
    self.dy = 0

    self.hit = {0,0,0}
    self.score = 0
end

function Paddle:update(dt)
    -- using max/min here enforces screen boundaries for player movement
    -- new position = old position + speed * dt
    if self.dy < 0 then -- if dy is negative paddle is moving up
        newPosition = self.y + self.dy * dt
        self.y = math.max(0, newPosition)
    else -- dy is positive the paddle is moving down
        newPosition = self.y + self.dy * dt 
        self.y = math.min(VIRTUAL_HEIGHT - self.height, newPosition)
    end
end

function Paddle:render(image, rotation, scale)
    love.graphics.draw(image, self.x, self.y, rotation, scale, scale) -- ball
end