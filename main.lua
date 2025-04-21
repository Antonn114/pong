local love = require("love")

local screen_width, screen_height
local left_y, right_y
local paddle_height, paddle_width, paddle_move_speed
local ball_x, ball_y
local ball_rot
local ball_speed
local ball_radius
local dash_width
local pong_sound
local paddle_margin

local stage
local font

local MAX_BOUNCE = 60

local score_left = 0
local score_right = 0

local last_winner_text
local press_enter_text

local endless_mode = false

-- stage 1: PRESS ENTER
-- stage 2: game
-- stage 3: win screen

function Reset()
    ball_rot = math.random(0, 360)
    ball_y = screen_height / 2
    ball_x = screen_width / 2
    stage = 1
end

-- Initialize function
function love.load()
    font = love.graphics.newFont("Emulogic.ttf")
    math.randomseed(os.time())
    screen_height, screen_width = 480, 640
    paddle_height = 60
    left_y, right_y = (screen_height - paddle_height) / 2, (screen_height - paddle_height) / 2
    paddle_move_speed = 300

    paddle_margin = 20
    paddle_width = 10
    ball_y = screen_height / 2
    ball_x = screen_width / 2
    ball_rot = math.random(0, 360)
    ball_speed = 300
    ball_radius = 5
    dash_width = 5
    last_winner_text = love.graphics.newText(font, "      WS FOR LEFT - UP DOWN FOR RIGHT")
    press_enter_text = love.graphics.newText(font, "PRESS ENTER TO PLAY")
    stage = 1

    pong_sound = love.audio.newSource("pong.wav", "static")

    love.window.setMode(screen_width, screen_height)
    love.window.setTitle("Pong")
end

function Move(dt)
    ball_y = ball_y - math.sin(math.rad(ball_rot)) * ball_speed * dt
    ball_x = ball_x + math.cos(math.rad(ball_rot)) * ball_speed * dt
end

function CheckCollisionLeft()
    return ball_x - ball_radius < paddle_width + paddle_margin and ball_y + ball_radius > left_y and
        ball_y - ball_radius < left_y + paddle_height and ball_x - ball_radius > paddle_margin and
        math.cos(math.rad(ball_rot)) < 0
end

function CheckCollisionRight()
    return ball_x + ball_radius > screen_width - paddle_width - paddle_margin and ball_y + ball_radius > right_y and
        ball_y - ball_radius < right_y + paddle_height and ball_x + ball_radius < screen_width - paddle_margin and
        math.cos(math.rad(ball_rot)) > 0
end

function CheckCollisionTop()
    return ball_y - ball_radius < 0 and math.sin(math.rad(ball_rot)) > 0
end

function CheckCollisionBottom()
    return ball_y + ball_radius > screen_height and math.sin(math.rad(ball_rot)) < 0
end

function StagePlay(dt)
    if (CheckCollisionLeft()) then
        local relative_intersect_y = (left_y + paddle_height / 2) - ball_y
        local normalized_intersect_y = relative_intersect_y / (paddle_height / 2)
        local bounce_angle = normalized_intersect_y * MAX_BOUNCE
        ball_rot = bounce_angle
        love.audio.play(pong_sound)
    end
    if (CheckCollisionRight()) then
        local relative_intersect_y = ball_y - (right_y + paddle_height / 2)
        local normalized_intersect_y = relative_intersect_y / (paddle_height / 2)
        local bounce_angle = normalized_intersect_y * MAX_BOUNCE + 180
        ball_rot = bounce_angle
        love.audio.play(pong_sound)
    end
    ball_rot = ball_rot % 360
    if (CheckCollisionTop() or CheckCollisionBottom()) then
        ball_rot = 360 - ball_rot
        love.audio.play(pong_sound)
    end
    if (not CheckCollisionLeft() and ball_x - ball_radius < 0) then
        score_right = score_right + 1
        last_winner_text:set("LAST WINNER: RIGHT")
        if (score_right == 11 and not endless_mode) then
            last_winner_text:set("RIGHT WINS! ENDLESS MODE STARTS NOW")
            endless_mode = true
        end
        Reset()
    end
    if (not CheckCollisionRight() and ball_x + ball_radius > screen_width) then
        score_left = score_left + 1
        last_winner_text:set("LAST WINNER: LEFT")
        if (score_right == 11 and not endless_mode) then
            last_winner_text:set("LEFT WINS! ENDLESS MODE STARTS NOW")
            endless_mode = true
        end
        Reset()
    end
    Move(dt)
end

-- Update function
function love.update(dt)
    if love.keyboard.isDown("w") then
        left_y = left_y - paddle_move_speed * dt
    end
    if love.keyboard.isDown("s") then
        left_y = left_y + paddle_move_speed * dt
    end
    if love.keyboard.isDown("up") then
        right_y = right_y - paddle_move_speed * dt
    end
    if love.keyboard.isDown("down") then
        right_y = right_y + paddle_move_speed * dt
    end
    if love.keyboard.isDown("r") then
        Reset()
    end

    left_y = math.max(math.min(left_y, screen_height - paddle_height), 0)
    right_y = math.max(math.min(right_y, screen_height - paddle_height), 0)
    if stage == 1 then
        if love.keyboard.isDown("return") then
            stage = 2
        end
    else
        if stage == 2 then
            StagePlay(dt)
        end
    end
end

-- Draw function
function love.draw()
    local score_show_left = love.graphics.newText(font, tostring(score_left))
    local score_show_right = love.graphics.newText(font, tostring(score_right))

    love.graphics.draw(score_show_left, screen_width / 2 - 50, screen_height / 2, 0, 1, 1, score_show_left:getWidth() / 2,
        score_show_left:getHeight() / 2)
    love.graphics.draw(score_show_right, screen_width / 2 + 50, screen_height / 2, 0, 1, 1, score_show_left:getWidth() /
        2, score_show_left:getHeight() / 2)

    love.graphics.setColor(1, 1, 1, 0.2)
    for i = 0, 20, 2 do
        love.graphics.rectangle("fill", screen_width / 2 - dash_width / 2, screen_height / 40 + i * screen_height / 20,
            dash_width,
            screen_height / 20)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", paddle_margin, left_y, paddle_width, paddle_height)
    love.graphics.rectangle("fill", screen_width - paddle_margin - paddle_width, right_y, paddle_width, paddle_height)
    love.graphics.circle("fill", ball_x, ball_y, ball_radius)

    if stage == 1 then
        love.graphics.draw(last_winner_text, screen_width / 2, screen_height * 2 / 5, 0, 1, 1,
            last_winner_text:getWidth() / 2,
            last_winner_text:getHeight() / 2)
        love.graphics.draw(press_enter_text, screen_width / 2, screen_height / 3, 0, 1, 1,
            press_enter_text:getWidth() / 2,
            press_enter_text:getHeight() / 2)
    end
end
