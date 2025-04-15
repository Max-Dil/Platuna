local function getScaleSafe(img, desiredWidth, desiredHeight, originalWidth, originalHeight)
    local originalWidth = originalWidth or img:getWidth()
    local originalHeight = originalHeight or img:getHeight()

    local xScale = (originalWidth > 0) and desiredWidth / originalWidth or 0
    local yScale = (originalHeight > 0) and desiredHeight / originalHeight or 0

    return xScale, yScale
end

local spriteSheet = {}
spriteSheet[1] = mane.graphics.newSpriteSheet('res/images/blocks.png', 10, 10, 56, 16)
spriteSheet[2] = mane.graphics.newSpriteSheet('res/images/blocks2.png', 10, 10, 43, 12)
spriteSheet[3] = mane.graphics.newSpriteSheet('res/images/blocks3.png', 10, 10, 36, 20)

-- local function predictPlayerPosition(image, bulletSpeed)
--     local distance = love.distance(image.x, image.y, Player.x, Player.y)
--     local timeToHit = distance / bulletSpeed
--     local playerVx, playerVy = Player:getLinearVelocity()
--     local predictedX = Player.x + playerVx * timeToHit
--     local predictedY = Player.y + playerVy * timeToHit
--     return predictedX, predictedY
-- end

local function predictPlayerPosition(image, bulletSpeed)
    local gx, gy = World.world:getGravity()

    local distance = love.distance(image.x, image.y, Player.x, Player.y)

    local timeToHit = distance / bulletSpeed

    local playerVx, playerVy = Player:getLinearVelocity()

    -- s = s0 + v0*t + (1/2)*a*t^2
    local predictedX = Player.x + playerVx * timeToHit + 0.3 * gx * timeToHit^2
    local predictedY = Player.y + playerVy * timeToHit + 0.3 * gy * timeToHit^2
    
    return predictedX, predictedY
end

local function hasLineOfSight(image, targetX, targetY)
    local hitObstacle = false

    local function rayCastCallback(fixture, x, y, xn, yn, fraction)
        local obj = fixture:getUserData()
        if obj ~= image and obj ~= Player then
            hitObstacle = true
            return 0
        end
        return 1
    end

    World.world:rayCast(image.x, image.y, targetX, targetY, rayCastCallback)

    return not hitObstacle
end

local weapons = {
    Piston = {
        image = 'res/images/weapons/Piston.png',
        shootDelay = 0.33,
        bulletLifetime = 54.9,
        force = 250,
        bulletSpeed = 759,
        attackDistance = 820,
        distance = 5000,
        damage = 10
    },
    AK47 = {
        image = 'res/images/weapons/AK47.png',
        shootDelay = 0.22,
        bulletLifetime = 63,
        force = 180,
        bulletSpeed = 660,
        attackDistance = 700,
        distance = 5000,
        damage = 8
    },
    MP40 = {
        image = 'res/images/weapons/MP40.png',
        shootDelay = 0.1,
        bulletLifetime = 43.2,
        force = 75,
        bulletSpeed = 550,
        attackDistance = 400,
        distance = 5000,
        damage = 4
    },
    Snipe = {
        image = 'res/images/weapons/Snipe.png',
        shootDelay = 1,
        bulletLifetime = 180,
        force = 650,
        bulletSpeed = 1980,
        attackDistance = 5000,
        distance = 10000,
        damage = 40
    },
    Shotgun = {
        image = 'res/images/weapons/Shotgun.png',
        shootDelay = 0.85,
        bulletLifetime = 22.5,
        force = 100,
        bulletSpeed = 880,
        attackDistance = 336,
        distance = 5000,
        damage = 8
    }
}

local enemy = {}
do
    enemy.addHpEnemy =  function(image)
        image.health = 100
        image.maxHealth = 100

        local hpText = Level:newPrint(
            image.health .. " / " .. image.maxHealth,
            'res/Venus.ttf',
            image.x,
            image.y - 50,
            30
        )
        hpText:toFront()
        hpText:setColor(0,1,0)
        image:addEvent('update', function(e)
            hpText.x, hpText.y = image.x, image.y - 50
            hpText.text = image.health .. " / " .. image.maxHealth
        end)

        local damageGroup = Level:newGroup()
        image.showDamage = function (bullet)
            if damageGroup then
                local damageText = damageGroup:newPrint(
                    "-" .. bullet.damage,
                    'res/Venus.ttf',
                    image.x+ math.random(-30, 30),
                    image.y - 50+ math.random(-0, -30),
                    30
                )
                damageText:setColor(1, 0, 0)
                mane.timer.new(500, function()
                    if damageGroup then
                        damageGroup:removeObjects()
                    end
                end, 1, 'Game')
            end
        end
        return hpText, damageGroup
    end

    local createBullet = function(x, y, move, image, elem)
        local bullet = BulletGroup:newRect(image.x, image.y, 30, 10)
        bullet.name = 'bullet'
        bullet.typeComand = 'enemy'
        bullet:setColor(0.8, 0.3, 0.3)
        bullet.damage = weapons[elem.weapon].damage
        World:addBody(bullet, 'dynamic')
        bullet.fixture:setCategory(5)
        bullet.fixture:setMask(4, 5)
        bullet.body:setGravityScale(0.3, 0.3)
        bullet.fixture:setFriction(1000)
        bullet.fixture:setRestitution(0)
    
        local angle = math.atan2(y - image.y, x - image.x)
        local angleDegrees = (angle / math.pi) * 180
        if move then
            if image.type == 'ghost' then
                angleDegrees = (angleDegrees + 180) % 360
            else
                if image.x < x then
                    angleDegrees = (angleDegrees + 145) % 360
                else
                    angleDegrees = (angleDegrees + 225) % 360
                end
            end
        end
        angle = (angleDegrees / 180) * math.pi
    
        local bulletSpeed = weapons[elem.weapon].bulletSpeed
        local bulletVelocityX = math.cos(angle) * bulletSpeed
        local bulletVelocityY = math.sin(angle) * bulletSpeed
        bullet.angle = (angle / math.pi) * 180
        bullet.initialSpeed = bulletSpeed
    
        local lifetimeSeconds = weapons[elem.weapon].bulletLifetime / 60
        local elapsedTime = 0
    
        bullet.body:setLinearVelocity(bulletVelocityX, bulletVelocityY)

        local bulletTimer
        bulletTimer = mane.timer.new(0, function(dt)
            elapsedTime = elapsedTime + dt

            local vx, vy = bullet.body:getLinearVelocity()
            local currentSpeed = math.sqrt(vx^2 + vy^2)
            local alpha = math.max(0.6, currentSpeed / bullet.initialSpeed)
            bullet.color[4] = alpha
            if currentSpeed < bulletSpeed/100 or (elapsedTime >= lifetimeSeconds) then
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
            if e.target == Player or e.other == Player then
                local vx, vy = bullet.body:getLinearVelocity()
                local currentSpeed = math.sqrt(vx^2 + vy^2)
                local damageRatio = currentSpeed > 0 and math.min(1, currentSpeed / bullet.initialSpeed) or 0
                local scaledDamage = math.floor(bullet.damage * damageRatio)

                Player.health = Player.health - scaledDamage
                Player.showDamage({damage = scaledDamage})
                if Player.health <= 0 then
                    Reload()
                end
                bullet:remove()
                if bullet.timer then
                    bullet.timer:cancel()
                end
                return true
            end
        end)
    
        image.body:setPosition(image.x - 1, image.y)
        local force = weapons[elem.weapon].force
        local vx, vy = image.body:getLinearVelocity()
        image.body:setLinearVelocity(vx - (math.cos(angle) * force), vy - (math.sin(angle) * force))
        image.body:setPosition(image.x + 1, image.y)
    end

    enemy.newAttack = function(infers, image, elem)
        local targetX, targetY = predictPlayerPosition(image, weapons[elem.weapon].bulletSpeed)

        if infers == nil and not hasLineOfSight(image, targetX, targetY) and not image.mad then
            targetX, targetY = Player.x, Player.y
            if not hasLineOfSight(image, targetX, targetY) then
                if math.random() < 0.2 + (image.maxHealth - image.health)/1000 then
                    enemy.newAttack(true, image, elem)
                elseif math.random() < 0.2 + (image.maxHealth - image.health)/1000 then
                    enemy.newAttack(false, image, elem)
                else
                    image.moveTimer:setTime(100)
                end
                return
            end
        end
        if image.mad then
            image.mad = nil
        end

        if infers then
            targetX, targetY = Player.x, Player.y
            local angle = math.atan2(targetY - image.y, targetX - image.x)
            local angleDegrees = (angle / math.pi) * 180
            if image.x < Player.x then
                angleDegrees = (angleDegrees + 145) % 360
            else
                angleDegrees = (angleDegrees + 225) % 360
            end
            angle = (angleDegrees / 180) * math.pi
            image.targetX = image.x + math.cos(angle) * 100
            image.targetY = image.y + math.sin(angle) * 100
        else
            image.targetX = targetX
            image.targetY = targetY
        end

        targetX, targetY = targetX + math.random(-40, 40), targetY + math.random(-40, 40)
        if elem.weapon == 'Shotgun' then
            local spread = 0.08
            local baseAngle = math.atan2(targetY - image.y, targetX - image.x)
            for i = -3, 3 do
                local angleOffset = i * spread
                local shotAngle = baseAngle + angleOffset
                local spreadX = image.x + math.cos(shotAngle) * 10
                local spreadY = image.y + math.sin(shotAngle) * 10
                createBullet(spreadX, spreadY, infers, image, elem)
            end
        else
            createBullet(targetX, targetY, infers, image, elem)
        end
    end

    enemy.addWeponEnemy = function (image, elem)
        image.weaponObject = Level:newImage(weapons[elem.weapon].image, image.x, image.y, 1.25, 1.25)

        image.targetX = 0
        image.targetY = 0
        image.weaponObject:addEvent('update', function(e)
            if not image or not image.x then
                if image.weaponObject then
                    image.weaponObject:remove()
                    image.weaponObject = nil
                end
                return
            end
            local targetX, targetY = image.targetX, image.targetY
            local angle = math.atan2(targetY - image.y, targetX - image.x)

            local offsetX = 20 * math.cos(angle)
            local offsetY = 20 * math.sin(angle)
            image.weaponObject.x = image.x + offsetX
            image.weaponObject.y = image.y + offsetY

            image.weaponObject.angle = (angle / math.pi) * 180

            if targetX < image.x then
                image.weaponObject.yScale = -1.25
            else
                image.weaponObject.yScale = 1.25
            end
            image.weaponObject.xScale = 1.25
        end)
    end

    enemy.addRipEnemy = function (image, hpText, damageGroup)
        image:addEvent('collision', function(e)
            if e.phase == 'began' then
                local bullet = (e.other.name == 'bullet' and e.other) or (e.target.name == 'bullet' and e.target) or false
                if bullet and bullet.typeComand == 'Player' then
                    if image.health <= 0 then
                        if image.weaponObject then
                            image.weaponObject:remove()
                            image.weaponObject = nil
                        end
                        if image.moveTimer then
                            image.moveTimer:cancel()
                            image.moveTimer = nil
                        end
                        if hpText then
                            hpText:remove()
                            hpText = nil
                        end
                        if damageGroup then
                            damageGroup:remove()
                            damageGroup = nil
                        end
                        if image then
                            image:remove()
                            CountEnemy = CountEnemy - 1
                        end
                        image = nil

                        if CountEnemy <= 0 then
                            Win()
                            return true
                        end
                        return true
                    end
                    return true
                end
            end
        end)
    end
end

local TILESET_CONFIG = {
    [1] = {
        [10] = {heightScale = 3, offsetY = 2.5},
        [11] = {heightScale = 3, offsetY = 2.5},
        [12] = {heightScale = 3, offsetY = 2.5}
    },
    [2] = {
        [1] = {heightScale = 4, main = function(image)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    Reload()
                    return true
                end
            end)
        end},
        [2] = {bodyRadius = 3.7, main = function(image)
            image:addEvent('update', function(e)
                image:rotate(61 * e.dt)
            end)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    Reload()
                    return true
                end
            end)
        end},
        [3] = {restitution = 1},
        [4] = {heightScale = 3, offsetY = 2.5, restitution = 1},
        [5] = {main = function (image, xScale, yScale, elem)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    local angle = elem.angle or 0
                    local gx, gy = World.world:getGravity()
                    local gravityMagnitude = math.sqrt(gx^2 + gy^2)
                    if gravityMagnitude == 0 then gravityMagnitude = 500 end
                    local rad = math.rad((angle + 90) % 360)
                    local newGx = math.cos(rad) * gravityMagnitude
                    local newGy = math.sin(rad) * gravityMagnitude
                    World.world:setGravity(-newGx, -newGy)
                    return true
                end
            end)
        end},
        [6] = {main = function(image)
            image.fixture:setSensor(true)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    if Player.size == 'big' then
                        Player.size = 'min'
                        Scenes.game.save.playerSize = 'min'
                        Player.xScale = 2.5
                        Player.yScale = 2.5
                        mane.timer.new(1, function()
                            Player:removeBody()
                            World:addBody(Player, 'dynamic', {
                                shape = "rect",
                                width = Player.image:getWidth() * 2.5,
                                height = Player.image:getHeight() * 2.5
                            })
                            Player:setFixedRotation(true)
                            Player.fixture:setCategory(2)
                            Player.fixture:setMask(3)

                            for i = 1, #Scenes.game.save.isBig, 1 do
                                local obj = Scenes.game.save.isBig[i]
                                if obj and obj.body then
                                    obj:removeBody()
                                    World:addBody(obj, 'static', {
                                        shape = "rect",
                                        width = 8 * obj.xScale,
                                        height = 8 * obj.yScale
                                    })
                                    obj.fixture:setCategory(1)
                                    obj.fixture:setSensor(true)
                                end
                            end

                            for i = 1, #Scenes.game.save.isMin, 1 do
                                local obj = Scenes.game.save.isMin[i]
                                if obj and obj.body then
                                    obj:removeBody()
                                    World:addBody(obj, 'static', {
                                        shape = "rect",
                                        width = 8 * obj.xScale,
                                        height = 8 * obj.yScale
                                    })
                                    obj.fixture:setCategory(1)
                                    obj.fixture:setSensor(false)
                                end
                            end
                        end, 1, 'Game')
                    end
                    return true
                end
            end)
        end},
        [7] = {main = function(image)
            image.fixture:setSensor(true)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    if Player.size == 'min' then
                        Player.size = 'big'
                        Scenes.game.save.playerSize = 'big'
                        Player.xScale = 6
                        Player.yScale = 6
                        mane.timer.new(1, function()
                            Player:removeBody()
                            World:addBody(Player, 'dynamic', {
                                shape = "rect",
                                width = Player.image:getWidth() * 6,
                                height = Player.image:getHeight() * 6
                            })
                            Player.body:setFixedRotation(true)
                            Player.fixture:setCategory(2)
                            Player.fixture:setMask(3)

                            for i = 1, #Scenes.game.save.isBig, 1 do
                                local obj = Scenes.game.save.isBig[i]
                                if obj and obj.body then
                                    obj:removeBody()
                                    World:addBody(obj, 'static', {
                                        shape = "rect",
                                        width = 8 * obj.xScale,
                                        height = 8 * obj.yScale
                                    })
                                    obj.fixture:setCategory(1)
                                    obj.fixture:setSensor(true)
                                end
                            end

                            for i = 1, #Scenes.game.save.isMin, 1 do
                                local obj = Scenes.game.save.isMin[i]
                                if obj and obj.body then
                                    obj:removeBody()
                                    World:addBody(obj, 'static', {
                                        shape = "rect",
                                        width = 8 * obj.xScale,
                                        height = 8 * obj.yScale
                                    })
                                    obj.fixture:setCategory(1)
                                    obj.fixture:setSensor(false)
                                end
                            end
                        end, 1, 'Game')
                    end
                    return true
                end
            end)
        end},
        [8] = {main = function(image)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    Win()
                    return true
                end
            end)
        end},
        [9] = {main = function(image)
            table.insert(Scenes.game.save.isBig, image)
            image.fixture:setSensor(true)
        end},
        [10] = {main = function(image)
            table.insert(Scenes.game.save.isMin, image)
        end},
        [11] = {main = function (image, xScale, yScale, elem)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    if Scenes.game.save.tpMap[elem.id] then
                        Player.x, Player.y = Scenes.game.save.tpMap[elem.id].x, Scenes.game.save.tpMap[elem.id].y - 80
                    end
                    return true
                end
            end)
        end},
        [12] = {main = function (image, xScale, yScale, elem)
            Scenes.game.save.tpMap[elem.id] = image
        end},
        [13] = {main = function(image)
            image:addEvent('collision', function(e)
                if e.phase == 'began' then
                    local bullet = (e.other.name == 'bullet' and e.other) or (e.target.name == 'bullet' and e.target) or false
                    if bullet then
                        if bullet.timer then
                            bullet.timer:cancel()
                        end
                        bullet:remove()
                        if image then
                            image:remove()
                        end
                        bullet = nil
                        image = nil
                        return true
                    end
                end
            end)
        end},
        [14] = {main = function(image)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    if Scenes.game.save.checkpoint then
                        if Scenes.game.save.checkpoint[1] ~= image.x or Scenes.game.save.checkpoint[2] ~= image.y then
                            Scenes.game.save.checkpoint = {image.x, image.y}
                            local text = Map:newPrint('Сохранено!', 'res/Venus.ttf', image.x, image.y - (10 * image.yScale)/2, 30)
                            mane.timer.new(2000, function()
                                text:remove()
                            end, 1, 'Game')
                        end
                    else
                        Scenes.game.save.checkpoint = {image.x, image.y}
                        local text = Map:newPrint('Сохранено!', 'res/Venus.ttf', image.x, image.y - (10 * image.yScale)/2, 30)
                        mane.timer.new(2000, function()
                            text:remove()
                        end, 1, 'Game')
                    end
                    return true
                end
            end)
        end},
        [16] = {main = function (image)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    mane.timer.new(1000, function ()
                        if image then
                            image:remove()
                            image = nil
                        end
                    end, 1, 'Game')
                    return true
                end
            end)
        end},
        [17] = {main = function (image, xScale, yScale, elem)
            image.isVisible = false
            Level:newPrint(elem.text, 'res/Venus.ttf', image.x, image.y, 25)
        end},
        [20] = {main = function(image, xScale, yScale, elem)
            local distance = elem.distance or 1000
            local shootDelay = 2
            local bulletSize = 40
            local bulletSpeed = 400
            local bulletDamage = 50

            mane.timer.new(shootDelay * 1000, function()
                if not image or not image.x then return end
                local bullet = BulletGroup:newCircle(image.x, image.y, bulletSize / 2)
                bullet.name = 'bullet'
                bullet.typeComand = 'enemy'
                bullet:setColor(0.5, 0.5, 0.5)
                bullet.damage = bulletDamage
                World:addBody(bullet, 'dynamic')
                bullet.fixture:setCategory(5)
                bullet.fixture:setMask(4, 5)
                bullet.body:setGravityScale(0, 0)

                local angle = math.rad(0)
                local bulletVelocityX = math.cos(angle) * bulletSpeed
                local bulletVelocityY = math.sin(angle) * bulletSpeed
                bullet.angle = 0

                local lifetimeSeconds = distance / bulletSpeed
                local elapsedTime = 0

                local bulletTimer
                bulletTimer = mane.timer.new(0, function(dt)
                    if not bullet then return end
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
                    if e.phase ~= 'began' then return false end
                    if e.target == Player or e.other == Player then
                        Player.health = Player.health - bullet.damage
                        Player.showDamage(bullet)
                        if Player.health <= 0 then
                            Reload()
                        end
                        bullet:remove()
                        if bullet.timer then
                            bullet.timer:cancel()
                        end
                        return true
                    elseif e.target ~= image and e.other ~= image then
                        mane.timer.new(10, function()
                            if bullet then
                                bullet:remove()
                            end
                            if bullet.timer then
                                bullet.timer:cancel()
                                bulletTimer = nil
                            end
                        end, 1, 'Game')
                    end
                end)
            end, 0, 'Game')
        end},
        [21] = {main = function(image, xScale, yScale, elem)
            local distance = elem.distance or 1000
            local shootDelay = 2
            local bulletSize = 40
            local bulletSpeed = 400
            local bulletDamage = 50

            mane.timer.new(shootDelay * 1000, function()
                if not image or not image.x then return end
                local bullet = BulletGroup:newCircle(image.x, image.y, bulletSize / 2)
                bullet.name = 'bullet'
                bullet.typeComand = 'enemy'
                bullet:setColor(0.5, 0.5, 0.5)
                bullet.damage = bulletDamage
                World:addBody(bullet, 'dynamic')
                bullet.fixture:setCategory(5)
                bullet.fixture:setMask(4, 5)
                bullet.body:setGravityScale(0, 0)

                local angle = math.rad(180)
                local bulletVelocityX = math.cos(angle) * bulletSpeed
                local bulletVelocityY = math.sin(angle) * bulletSpeed
                bullet.angle = 180

                local lifetimeSeconds = distance / bulletSpeed
                local elapsedTime = 0

                local bulletTimer
                bulletTimer = mane.timer.new(0, function(dt)
                    if not bullet then return end
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
                    if e.phase ~= 'began' then return false end
                    if e.target == Player or e.other == Player then
                        Player.health = Player.health - bullet.damage
                        Player.showDamage(bullet)
                        if Player.health <= 0 then
                            Reload()
                        end
                        bullet:remove()
                        if bullet.timer then
                            bullet.timer:cancel()
                        end
                        return true
                    elseif e.target ~= image and e.other ~= image then
                        mane.timer.new(10, function()
                            if bullet then
                                bullet:remove()
                            end
                            if bullet.timer then
                                bullet.timer:cancel()
                                bulletTimer = nil
                            end
                        end, 1, 'Game')
                    end
                end)
            end, 0, 'Game')
        end},
        [22] = {main = function(image, xScale, yScale, elem)
            local distance = elem.distance or 1000
            local shootDelay = 0.8
            local bulletSize = {30, 10}
            local bulletSpeed = 600
            local bulletDamage = 10

            mane.timer.new(shootDelay * 1000, function()
                if not image or not image.x then return end
                local bullet = BulletGroup:newRect(image.x, image.y, bulletSize[1], bulletSize[2])
                bullet.name = 'bullet'
                bullet.typeComand = 'enemy'
                bullet:setColor(0.8, 0.3, 0.3)
                bullet.damage = bulletDamage
                World:addBody(bullet, 'dynamic')
                bullet.fixture:setCategory(5)
                bullet.fixture:setMask(4, 5)
                bullet.body:setGravityScale(0, 0)

                local angle = math.rad(((elem.angle or 0) + 270) % 360)
                local bulletVelocityX = math.cos(angle) * bulletSpeed
                local bulletVelocityY = math.sin(angle) * bulletSpeed
                bullet.angle = ((elem.angle or 0) + 270) % 360

                local lifetimeSeconds = distance / bulletSpeed
                local elapsedTime = 0

                local bulletTimer
                bulletTimer = mane.timer.new(0, function(dt)
                    if not bullet then return end
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
                    if e.phase ~= 'began' then return false end
                    if e.target == Player or e.other == Player then
                        Player.health = Player.health - bullet.damage
                        Player.showDamage(bullet)
                        if Player.health <= 0 then
                            Reload()
                        end
                        bullet:remove()
                        if bullet.timer then
                            bullet.timer:cancel()
                        end
                        return true
                    elseif e.target ~= image and e.other ~= image then
                        mane.timer.new(10, function()
                            if bullet then
                                bullet:remove()
                            end
                            if bullet.timer then
                                bullet.timer:cancel()
                                bulletTimer = nil
                            end
                        end, 1, 'Game')
                    end
                end)
            end, 0, 'Game')
        end},
        [23] = {main = function (image, xScale, yScale, elem)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    local gravityMagnitude = elem.gravity or 500
                    local gx, gy = World.world:getGravity()
                    local currentMagnitude = math.sqrt(gx^2 + gy^2)
                    if currentMagnitude > 0 then
                        gx = (gx / currentMagnitude) * gravityMagnitude
                        gy = (gy / currentMagnitude) * gravityMagnitude
                    else
                        gx, gy = 0, gravityMagnitude
                    end
                    World.world:setGravity(gx, gy)
                    return true
                end
            end)
        end},
        [24] = {main=function (image, xScale, yScale, elem)
            image.fixture:setSensor(true)
            image:addEvent('collision', function(e)
                if e.phase == 'began' and (e.other == Player or e.target == Player) then
                    if Scenes.game.save.doors.doors[elem.id or 0] then
                        Scenes.game.save.doors.doors[elem.id or 0]:remove()
                        Scenes.game.save.doors.doors[elem.id or 0] = nil

                        image:remove()
                        image = nil
                    end
                    return true
                end
            end)
        end},
        [25] = {main=function (image, xScale, yScale, elem)
            Scenes.game.save.doors.doors[elem.id or 0] = image
        end},
        [26] = {main = function(image)
            CountEnemy = CountEnemy + 1
            image:addEvent('collision', function(e)
                if e.phase == 'began' then
                    local bullet = (e.other.name == 'bullet' and e.other) or (e.target.name == 'bullet' and e.target) or false
                    if bullet and bullet.typeComand ~= 'enemy' then
                        if bullet.timer then
                            bullet.timer:cancel()
                        end
                        bullet:remove()
                        bullet = nil

                        if image then
                            image:remove()
                            CountEnemy = CountEnemy - 1
                        end
                        image = nil

                        if CountEnemy <= 0 then
                            Win()
                            return true
                        end
                        return true
                    end
                end
            end)
        end},
        [27] = {main = function(image, xScale, yScale, elem)
            CountEnemy = CountEnemy + 1
            image.name = 'enemy'
            image.body:setFixedRotation(true)
            image.fixture:setCategory(4)
            image.fixture:setMask(5)
            
            local hpText, damageGroup = enemy.addHpEnemy(image)

            enemy.addWeponEnemy(image, elem)

            enemy.addRipEnemy(image, hpText, damageGroup)

            local shootDelay = weapons[elem.weapon].shootDelay
            image.moveTimer = mane.timer.new(shootDelay * 1000, function()
                if not image or not image.x then
                    if image.moveTimer then
                        image.moveTimer:cancel()
                        image.moveTimer = nil
                    end
                    return
                end
                local distance = love.distance(image.x, image.y, Player.x, Player.y)

                if distance <= weapons[elem.weapon].attackDistance then
                    enemy.newAttack(false, image, elem)
                elseif distance <= weapons[elem.weapon].distance then
                    enemy.newAttack(true, image, elem)
                end
                image.moveTimer:setTime(shootDelay * (1000 - (image.maxHealth - image.health)/10))
            end, 0, 'Game')
        end},
        [30] = {main=function (image, xScale, yScale, elem)
            table.insert(Scenes.game.save.doors.gold, image)
        end},
        [31] = {main = function (image, xScale, yScale, elem)
            Scenes.game.save.doors.goldMoney = Scenes.game.save.doors.goldMoney + 1
            image:addEvent('collision', function (e)
                if e.phase == 'began' then
                    if e.other == Player or e.target == Player then
                        Money = Money + 1
                        MoneyText.text = 'Монет: '..Money
                        image:remove()
                        image = nil
                        Scenes.game.save.doors.goldMoney = Scenes.game.save.doors.goldMoney - 1
                        if Scenes.game.save.doors.goldMoney <= 0 then
                            for i = 1, #Scenes.game.save.doors.gold, 1 do
                                Scenes.game.save.doors.gold[i]:remove()
                                Scenes.game.save.doors.gold[i] = nil
                            end
                        end
                    end
                end
            end)
        end},
        [32] = {main=function (image, xScale, yScale, elem)
            table.insert(Scenes.game.save.doors.blue, image)
        end},
        [33] = {main = function (image, xScale, yScale, elem)
            Scenes.game.save.doors.blueMoney = Scenes.game.save.doors.blueMoney + 1
            image:addEvent('collision', function (e)
                if e.phase == 'began' then
                    if e.other == Player or e.target == Player then
                        image:remove()
                        image = nil
                        Scenes.game.save.doors.blueMoney = Scenes.game.save.doors.blueMoney - 1
                        if Scenes.game.save.doors.blueMoney <= 0 then
                            for i = 1, #Scenes.game.save.doors.blue, 1 do
                                Scenes.game.save.doors.blue[i]:remove()
                                Scenes.game.save.doors.blue[i] = nil
                            end
                        end
                    end
                end
            end)
        end},
        [34] = {main=function (image, xScale, yScale, elem)
            table.insert(Scenes.game.save.doors.green, image)
        end},
        [35] = {main = function (image, xScale, yScale, elem)
            Scenes.game.save.doors.greenMoney = Scenes.game.save.doors.greenMoney + 1
            image:addEvent('collision', function (e)
                if e.phase == 'began' then
                    if e.other == Player or e.target == Player then
                        image:remove()
                        image = nil
                        Scenes.game.save.doors.greenMoney = Scenes.game.save.doors.greenMoney - 1
                        if Scenes.game.save.doors.greenMoney <= 0 then
                            for i = 1, #Scenes.game.save.doors.green, 1 do
                                Scenes.game.save.doors.green[i]:remove()
                                Scenes.game.save.doors.green[i] = nil
                            end
                        end
                    end
                end
            end)
        end},
        [42] = {main = function(image, xScale, yScale, elem)
            local distance = elem.distance or 1000
            local shootDelay = 2
            local bulletSize = {30, 10}
            local bulletSpeed = 700
            local bulletDamage = 10
            local spreadAngle = 10

            image:addEvent('update', function(e)
                if not image or not Player or not Player.x then return end
                local angle = math.atan2(Player.y - image.y, Player.x - image.x)
                image.angle = (((angle / math.pi) * 180)+90) % 360
            end)

            local function createBullet(angleOffset)
                local bullet = BulletGroup:newRect(image.x, image.y, bulletSize[1], bulletSize[2])
                bullet.name = 'bullet'
                bullet.typeComand = 'enemy'
                bullet:setColor(0.8, 0.3, 0.3)
                bullet.damage = bulletDamage
                World:addBody(bullet, 'dynamic')
                bullet.fixture:setCategory(5)
                bullet.fixture:setMask(4, 5)
                bullet.body:setGravityScale(0, 0)

                local targetAngle = math.atan2(Player.y - image.y, Player.x - image.x) + math.rad(angleOffset)
                local bulletVelocityX = math.cos(targetAngle) * bulletSpeed
                local bulletVelocityY = math.sin(targetAngle) * bulletSpeed
                bullet.angle = (targetAngle / math.pi) * 180

                local lifetimeSeconds = distance / bulletSpeed
                local elapsedTime = 0
                local bulletTimer 
                bulletTimer= mane.timer.new(0, function(dt)
                    if not bullet then return end
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
                    if e.phase ~= 'began' then return false end
                    if e.target == Player or e.other == Player then
                        Player.health = Player.health - bullet.damage
                        Player.showDamage(bullet)
                        if Player.health <= 0 then
                            Reload()
                        end
                        bullet:remove()
                        if bullet.timer then
                            bullet.timer:cancel()
                        end
                        return true
                    elseif e.target ~= image and e.other ~= image then
                        mane.timer.new(10, function()
                            if bullet then
                                bullet:remove()
                            end
                            if bullet.timer then
                                bullet.timer:cancel()
                                bulletTimer = nil
                            end
                        end, 1, 'Game')
                    end
                end)
            end

            mane.timer.new(shootDelay * 1000, function()
                if not image or not image.x or not Player or not Player.x then return end
                createBullet(-spreadAngle * 1.5)
                mane.timer.new(50, function() createBullet(-spreadAngle * 0.5) end, 1, 'Game')
                mane.timer.new(100, function() createBullet(spreadAngle * 0.5) end, 1, 'Game')
                mane.timer.new(150, function() createBullet(spreadAngle * 1.5) end, 1, 'Game')
            end, 0, 'Game')
        end},
        [43] = {main = function (image, xScale, yScale, elem)
            CountEnemy = CountEnemy + 1
            image.name = 'enemy'
            image.enemyType = 'ghost'

            image.body:setGravityScale(0, 0)
            image.body:setFixedRotation(true)
            image.fixture:setCategory(4)
            image.fixture:setMask(5)
            
            local hpText, damageGroup = enemy.addHpEnemy(image)

            enemy.addWeponEnemy(image, elem)

            enemy.addRipEnemy(image, hpText, damageGroup)

            local count = 10

            local shootDelay = weapons[elem.weapon].shootDelay
            image.moveTimer = mane.timer.new(shootDelay * 1000, function()
                if not image or not image.x then
                    if image.moveTimer then
                        image.moveTimer:cancel()
                        image.moveTimer = nil
                    end
                    return
                end
                local distance = love.distance(image.x, image.y, Player.x, Player.y)

                if distance <= weapons[elem.weapon].attackDistance then
                    enemy.newAttack(false, image, elem)
                elseif distance <= weapons[elem.weapon].distance then
                    enemy.newAttack(true, image, elem)
                end

                image.moveTimer:setTime(shootDelay * (1000 - (image.maxHealth - image.health)/10))

                count = count - 1
                if count == 0 then
                    if image.color[4] == 0 then
                        image.color[4] = 1
                        hpText.color[4] = 1
                        image.weaponObject.color[4] = 1
                    else
                        image.color[4] = 0
                        hpText.color[4] = 0
                        image.weaponObject.color[4] = 0
                    end
                    count = 10
                end
            end, 0, 'Game')
        end}
    },
    [3] = {removeBody = true},
}

local function load(map)
    Level = Map:newGroup()
    --Level.x, Level.y = mane.display.centerX, mane.display.centerY

    for i = 1, #map, 1 do
        local elem = mane.json.decode(mane.json.encode(map[i]))
        elem.width = elem.width or (80)
        elem.height = elem.height or (80)
        elem.x, elem.y = elem.x + mane.display.centerX, elem.y + mane.display.centerY
        local width, height = elem.width * 1.25, elem.height * 1.25
        local xScale, yScale = getScaleSafe(nil, width or 0, height or 0, 10, 10)

        if elem.inxScale then
            xScale = -xScale
        end
        if elem.inyScale then
            yScale = -yScale
        end
        local image = Level:newSprite(spriteSheet[elem.tileset or 1], elem.x, elem.y)
        image.frame = elem.frame
        image.xScale = xScale
        image.yScale = yScale
        image.angle = elem.angle or 0
        image.color[4] = elem.alpha or 1
        if elem.body then
            World:addBody(image, elem.body or 'static', {
                shape = 'rect',
                width = 8 * xScale,
                height = 8 * yScale,
            })
            if elem.isSensor then
                image.fixture:setSensor(true)
            end
            image.fixture:setCategory(1)
        end

        local tilesetConfig = TILESET_CONFIG[elem.tileset or 1]
        if tilesetConfig then
            local frameConfig = tilesetConfig[elem.frame]
            if frameConfig then
                if frameConfig.removeBody then
                    image:removeBody()
                elseif frameConfig.heightScale then
                    image:removeBody()
                    World:addBody(image, elem.body or 'static', {
                        shape = 'rect',
                        width = 8 * xScale,
                        height = frameConfig.heightScale * yScale,
                        offsetX = frameConfig.offsetX and (frameConfig.offsetX * xScale),
                        offsetY = frameConfig.offsetY and (frameConfig.offsetY * yScale)
                    })
                    image.fixture:setCategory(1)
                end

                if frameConfig.bodyRadius then
                    image:removeBody()
                    World:addBody(image, elem.body or 'static', {
                        shape = 'circle',
                        radius = frameConfig.bodyRadius * xScale,
                    })
                    image.fixture:setCategory(1)
                end

                if frameConfig.restitution then
                    image.fixture:setRestitution(frameConfig.restitution)
                end

                if frameConfig.main then
                    frameConfig.main(image, xScale, yScale, elem)
                end
            end
        end
    end
end

return load