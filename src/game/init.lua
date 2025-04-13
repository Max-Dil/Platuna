local m = {}
local PlayerFactory = require('src.game.player')
local loadMap = require('src.game.loadMap')

m.remove = function ()
    mane.display.setBackgroundColor(0, 0, 0)
    Runtime:removeEvent('touch', Player.listener)
    mane.timer.cancelAll('Game')
    mane.timer.cancelAll()
    Game:remove()
    BulletGroup = nil
    Map = nil
    Game = nil
    Player = nil
    for key, value in pairs(m) do
        if key ~= 'remove' and key ~= 'create' and key ~= 'runEditor' and key ~= 'run' and key ~= 'selectWeapon' then
            m[key] = nil
        end
    end
    World:remove()
end

m.runEditor = function (MapData)
    m.back = "editor"

    local levelData = {}

    for key, value in pairs(MapData) do
        for i2 = 1, #value, 1 do
            table.insert(levelData, value[i2])
        end
    end

    m.editor = levelData

    m.run()

    loadMap(levelData)

    Player = PlayerFactory()

    mane.timer.pauseAll('Game')
    m.selectWeapon(function (weapon)
        Player.weapon = weapon
        Player.updateWeapon()
        mane.timer.resumeAll('Game')
        World.update = true
    end)
end

m.selectWeapon = function (callback)
    local weapons = {
        Piston = 'res/images/weapons/Piston.png',
        AK47 = 'res/images/weapons/AK47.png',
        MP40 = 'res/images/weapons/MP40.png',
        Snipe = 'res/images/weapons/Snipe.png',
        Shotgun = 'res/images/weapons/Shotgun.png',
    }

    local selectGroup = Game:newGroup()

    local bg = selectGroup:newRect(mane.display.centerX, mane.display.centerY, mane.display.width, mane.display.height)
    bg.color = {0, 0, 0, 0.8}
    bg:addEvent('touch', function () return true end)

    local i = 1
    for key, value in pairs(weapons) do
        local rect = selectGroup:newRect(200 + 25 * i, 100 * i, 200, 60, 20, 20)
        rect.color = {0.2, 0.4, 0.7, 1}
        i = i + 1

        local image = selectGroup:newImage(value, rect.x - 150, rect.y, 1.25, 1.25)

        local text = selectGroup:newPrint(key, 'res/Venus.ttf', image.x + 100, image.y, 17)

        rect:addEvent('touch', function ()
            selectGroup:remove()
            selectGroup = nil
            callback(key)
            return true
        end)
    end
end

m.run = function ()
    mane.display.setBackgroundColor(0, 0, 33/255)
    m.save = {
        isBig = {},
        isMin = {},
        playerSize = 'big',
        checkpoint = {mane.display.centerX, mane.display.centerY},
        tpMap = {},
    }
    Game = mane.display.game:newGroup()
    Map = Game:newGroup()
    World = mane.physics.newWorld(0, 500, true)
    World.world:setGravity(0, 500)

    BulletGroup = Map:newGroup()

    CountEnemy = 0
    CountLevel = 1

    Money = 0
    MaxMoney = 0
    MoneyText = Game:newPrint('Монет: '..Money, 'res/Venus.ttf', 100, 40, 30)

    local exit = Game:newCircle(40, 40, 0)
    exit.button = 'exit'
    exit.isVisible = false
    exit:addEvent('key', function (e)
        if e.phase == "ended" and Game.isVisible then
            if e.key == "escape" then
                if m.back == "main" then
                    m.remove()
                    Scenes.menu.create()
                elseif m.back == "editor" then
                    m.remove()
                    Scenes.editor.group.isVisible = true
                end
                return true
            end
        end
    end)

    local textLevel = Game:newPrint('Уровень: '..CountLevel, 'res/Venus.ttf', mane.display.centerX, 40, 30)
    if m.editor then
        textLevel.text = "Уровень: редактор"
    else
        local saves = require('saves')
        textLevel.text = 'Уровень: '.. saves.load('level', 1)
    end

    local fpsText = Game:newPrint('FPS: 0', 'res/Venus.ttf', mane.display.width - 100, 40, 30)
    local frameCount = 0
    local function updateFPS()
        frameCount = frameCount + 1
    end
    mane.timer.new(1000, function ()
        local fps = math.floor(frameCount)
        fpsText.text = 'FPS: ' .. fps
        frameCount = 0
    end, 0, 'Game')
    exit:addEvent('update', updateFPS)

    function Reload()
        BulletGroup:remove()
        BulletGroup = Map:newGroup()
        Level:remove()
        Player:removeBody()

        CountEnemy = 0

        mane.timer.cancelAll('Game')
        World:remove()
        World = mane.physics.newWorld(0, 500, true)
        World.world:setGravity(0, 500)
        Player.damageGroup:removeObjects()
        Player.health = Player.maxHealth
        Player.x, Player.y = mane.display.centerX, mane.display.centerY
        Player.size = 'big'
        Player.xScale = 6
        Player.yScale = 6
        World:addBody(Player, 'dynamic', {
            shape = "rect",
            width = Player.image:getWidth() * 6,
            height = Player.image:getHeight() * 6
        })
        Player:setFixedRotation(true)
        Player.fixture:setCategory(2)
        Player.fixture:setMask(3)

        if m.editor then
            loadMap(m.editor)
        else
            loadMap(m.level)
        end
        if m.save.checkpoint then
            Player.x, Player.y = m.save.checkpoint[1], m.save.checkpoint[2]
        end
        Player.hpText:toFront()
        Money = MaxMoney

        mane.timer.pauseAll('Game')
        m.selectWeapon(function (weapon)
            Player.weapon = weapon
            Player.updateWeapon()
            mane.timer.resumeAll('Game')
            World.update = true
        end)
    end

    Win = function ()
        if m.editor then
            m.remove()
            Scenes.editor.group.isVisible = true
            return
        else
            local saves = require('saves')
            if m.currentLevel >= saves.load('level', 1) then
                saves.save('level', saves.load('level', 1) + 1)
            end
            m.remove()
            Scenes.levels.create()
            return
        end
    end
end

m.create = function (level)
    m.back = "main"

    local level2 = mane.json.decode(require('res.levels.'..level))

    local levelData = {}

    for key, value in pairs(level2) do
        for i2 = 1, #value, 1 do
            table.insert(levelData, value[i2])
        end
    end

    m.level = levelData
    m.currentLevel = level
    m.run()

    loadMap(m.level)
    --loadMap(require('res.levels.'..CountLevel))

    Player = PlayerFactory()
    mane.timer.pauseAll('Game')
    m.selectWeapon(function (weapon)
        Player.weapon = weapon
        Player.updateWeapon()
        mane.timer.resumeAll('Game')
        World.update = true
    end)
end

--mane.display.renderMode = 'hybrid'
return m