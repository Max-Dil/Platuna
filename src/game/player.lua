local speedCamera = 0.2
local bulletLifetime = 100

local shootDelay = 0.25
local lastShotTime = 0

local function PlayerFactory()
    local Player = Map:newImage('res/images/skins/skin1.png', mane.display.centerX, mane.display.centerY, 6, 6)
    Player.angle = 0
    Player.size = "big"
    Player.health = 100 
    Player.maxHealth = 100

    Player.weapons = {
        Piston = {
            image = 'res/images/weapons/Piston.png',
            shootDelay = 0.34,
            bulletLifetime = 70,
            force = 250,
            bulletSpeed = 600,
            damage = 10
        },
        AK47 = {
            image = 'res/images/weapons/AK47.png',
            shootDelay = 0.22,
            bulletLifetime = 70,
            force = 180,
            bulletSpeed = 550,
            damage = 8
        },
        MP40 = {
            image = 'res/images/weapons/MP40.png',
            shootDelay = 0.1,
            bulletLifetime = 60,
            force = 70,
            bulletSpeed = 400,
            damage = 4
        },
        Snipe = {
            image = 'res/images/weapons/Snipe.png',
            shootDelay = 1,
            bulletLifetime = 200,
            force = 650,
            bulletSpeed = 1800,
            damage = 50
        },
        Shotgun = {
            image = 'res/images/weapons/Shotgun.png',
            shootDelay = 0.85,
            bulletLifetime = 25,
            force = 100,
            bulletSpeed = 800,
            damage = 8
        }
    }
    Player.weapon = 'Piston'

    Player.updateWeapon = function()
        if Player.weaponObject then
            Player.weaponObject:remove()
        end
        Player.weaponObject = Map:newImage(Player.weapons[Player.weapon].image, Player.x, Player.y, 1.25, 1.25)
        shootDelay = Player.weapons[Player.weapon].shootDelay

        Player.weaponObject:addEvent('update', function(e)

            local mouseX = love.mouse.getX() - Map.x
            local mouseY = love.mouse.getY() - Map.y
            local angle = math.atan2(mouseY - Player.y, mouseX - Player.x)

            local offsetX = 36 * math.cos(angle)
            local offsetY = 36 * math.sin(angle)
            Player.weaponObject.x = Player.x + offsetX
            Player.weaponObject.y = Player.y + offsetY

            Player.weaponObject.angle = (angle / math.pi) * 180

            if mouseX < Player.x then
                Player.weaponObject.yScale = -1.25
            else
                Player.weaponObject.yScale = 1.25
            end
            Player.weaponObject.xScale = 1.25
        end)
    end

    Player.updateWeapon()

    World:addBody(Player, 'dynamic', {
        shape = "rect",
        width = Player.image:getWidth() * 6,
        height = Player.image:getHeight() * 6
    })
    Player:setFixedRotation(true)
    Player.fixture:setCategory(2)
    Player.fixture:setMask(3)

    local function lerp(a, b, t)
        return a + (b - a) * t
    end

    local hpText = Map:newPrint(
        Player.health .. " / " .. Player.maxHealth,
        'res/Venus.ttf',
        Player.x,
        Player.y - 50,
        15
    )
    Player.hpText = hpText
    hpText:toFront()
    hpText:setColor(0,1,0)


    -- local velocityX, velocityY = 0, 0
    -- local moveSpeed = 300
    -- Player:setGravityScale(0,0)
    -- Player:addEvent('key', function(e)
    --     if e.phase == 'began' then
    --         if e.key == 'w' then
    --             velocityY = -moveSpeed
    --         elseif e.key == 's' then
    --             velocityY = moveSpeed
    --         elseif e.key == 'a' then
    --             velocityX = -moveSpeed
    --         elseif e.key == 'd' then
    --             velocityX = moveSpeed
    --         end
    --     elseif e.phase == 'ended' then
    --         if e.key == 'w' or e.key == 's' then
    --             velocityY = 0
    --         elseif e.key == 'a' or e.key == 'd' then
    --             velocityX = 0
    --         end
    --     end
    -- end)

    Player:addEvent('update', function(e)

        --Player.body:setLinearVelocity(velocityX, velocityY)

        hpText.x, hpText.y = Player.x, Player.y - 50
        hpText.text = Player.health .. " / " .. Player.maxHealth
        Map.x = lerp(Map.x, -Player.x + mane.display.width / 2, speedCamera)
        Map.y = lerp(Map.y, -Player.y + mane.display.height / 2, speedCamera)
        if Player.y > 2000 or Player.health <= 0 then
            Reload()
            return true
        end
    end)

    local damageGroup = Map:newGroup()
    Player.damageGroup = damageGroup
    Player.showDamage = function (bullet)
        local damageText = damageGroup:newPrint(
            bullet.damage < 0 and "+" .. math.abs(bullet.damage) or "-" .. bullet.damage,
            'res/Venus.ttf',
            Player.x + math.random(-30, 30),
            Player.y - 70 + math.random(-0, -30),
            15
        )
        if bullet.damage < 0 then
            damageText:setColor(0, 1, 0)
        else
            damageText:setColor(1, 0, 0)
        end
        mane.timer.new(500, function()
            damageGroup:removeObjects()
        end, 1, 'Game')
    end

    local createBullet = function(x, y)
        local bullet = BulletGroup:newRect(Player.x, Player.y, 30, 10)
        bullet.name = 'bullet'
        bullet.typeComand = 'Player'
        bullet:setColor(0.8, 0.8, 0.3)
        bullet.damage = Player.weapons[Player.weapon].damage
        World:addBody(bullet, 'dynamic')
        --bullet.fixture:setSensor(true)
        bullet.fixture:setCategory(3)
        bullet.fixture:setMask(2, 3)
        bullet:setGravityScale(0, 0)

        local angle = math.atan2(y - Player.y, x - Player.x)
        local bulletSpeed = Player.weapons[Player.weapon].bulletSpeed or 600
        local bulletVelocityX = math.cos(angle) * bulletSpeed
        local bulletVelocityY = math.sin(angle) * bulletSpeed
        bullet.angle = (angle / math.pi) * 180

        local lifetimeSeconds = Player.weapons[Player.weapon].bulletLifetime * 0.0167
        local elapsedTime = 0

        local bulletTimer
        bulletTimer = mane.timer.new(0, function(dt)
            elapsedTime = elapsedTime + dt
            bullet.x = bullet.x + bulletVelocityX * dt
            bullet.y = bullet.y + bulletVelocityY * dt
            if elapsedTime >= lifetimeSeconds then
                bullet:remove()
                bulletTimer:cancel()
                bulletTimer = nil
                bullet = nil
            end
        end, 0, 'Game')
    
        bullet.timer = bulletTimer
        bullet:addEvent('collision', function(e)
            if e.phase ~= 'began' then
                return false
            end
            if e.target ~= Player and e.other ~= Player then
                local target = e.target.name == 'enemy' and e.target or e.other.name == 'enemy' and e.other
                if target then
                    target.health = target.health - bullet.damage
                    target.mad = true
                    target.showDamage(bullet)
                    Player.health = Player.health + math.ceil(bullet.damage / 2)
                    Player.showDamage({damage = -math.ceil(bullet.damage / 2)})
                    if Player.health >= Player.maxHealth then
                        Player.health = Player.maxHealth
                    end
                    bullet:remove()
                    if bullet.timer then
                        bullet.timer:cancel()
                    end
                    return true
                elseif e.other.name == 'bullet' and e.target.name == 'bullet' then
                    local bullet1 = e.other
                    local bullet2 = e.target
                    if bullet1.typeComand == 'enemy' or bullet2.typeComand == 'enemy' then
                        if bullet1 then bullet1:remove() end
                        if bullet1.timer then bullet1.timer:cancel() end
                        if bullet2 then bullet2:remove() end
                        if bullet2.timer then bullet2.timer:cancel() end
                    end
                else
                    mane.timer.new(10, function()
                        if bullet then
                            bullet:remove()
                        end
                        if bulletTimer then
                            bulletTimer:cancel()
                            bulletTimer = nil
                        end
                    end, 1, 'Game')
                end
            end
        end)
    
        Player.body:setPosition(Player.x - 1, Player.y)
        local force = (Player.weapons[Player.weapon].force or 200) * Player.body:getMass()
        Player.body:applyLinearImpulse(-math.cos(angle) * force, -math.sin(angle) * force)
        Player.body:setPosition(Player.x + 1, Player.y)
    end

    local timer
    local xClick, yClick
    local listener = function(e)
        if not Player then
            return false
        end
        if e.phase == 'began' and not timer then
            xClick = e.x
            yClick = e.y
            timer = mane.timer.new(10, function()
                local currentTime = os.clock()
                if currentTime - lastShotTime >= shootDelay then
                    lastShotTime = currentTime
                    local x = xClick - Map.x
                    local y = yClick - Map.y
                    if Player.weapon == 'Shotgun' then
                        local spread = 0.08
                        local baseAngle = math.atan2(y - Player.y, x - Player.x)
                        for i = -3, 3 do
                            local angleOffset = i * spread
                            local shotAngle = baseAngle + angleOffset
                            local spreadX = Player.x + math.cos(shotAngle) * 10
                            local spreadY = Player.y + math.sin(shotAngle) * 10
                            createBullet(spreadX, spreadY)
                        end
                    else
                        createBullet(x, y)
                    end
                end
            end, 0, 'Game')
        elseif e.phase == 'ended' or e.phase == 'cancelled' then
            timer:cancel()
            timer = nil
        else
            xClick = e.x
            yClick = e.y
        end
    end

    Player.listener = listener
    table.insert(Player.events.touch, listener)
    Runtime:addEvent('touch', listener)

    return Player
end

return PlayerFactory