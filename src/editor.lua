local m = {}
local listeners = {}

local currentBlock = {sheet = 1, frame = 1}
local moveTimer = nil
local moveDirection = {x = 0, y = 0}
local cameraSpeed = 10

local function inputText(callback, title)
    local inputGroup = m.group:newGroup()
    local bg = inputGroup:newRect(mane.display.centerX, mane.display.centerY, mane.display.width, mane.display.height)
    bg.color = {0, 0, 0, 0.8}

    local inputBox = inputGroup:newRect(mane.display.centerX, mane.display.centerY, 200, 50)
    inputBox.color = {1, 1, 1, 1}

    local titleText = inputGroup:newPrint(title or "Enter text", 'res/Venus.ttf', mane.display.centerX, mane.display.centerY - 40, 20)
    local value = ""
    local text = inputGroup:newPrint(value, 'res/Venus.ttf', mane.display.centerX, mane.display.centerY, 25)
    text:setColor(0, 0, 0, 1)

    local lastKey = nil

    local function updateText()
        text.text = value
    end

    local function keyListener(e)
        print(lastKey)
        if e.phase == "ended" then
            if e.key == "enter" or e.key == "return" then
                inputGroup:remove()
                if value ~= "" then
                    m.back = 'main'
                    callback(value)
                end
            elseif e.key == "backspace" then
                value = value:sub(1, -2)
                updateText()
            elseif e.key == "v" and lastKey == "lctrl" then
                local pastedText = love.system.getClipboardText()
                if pastedText then
                    value = value .. pastedText
                    updateText()
                end
            elseif #e.key == 1 and e.key ~= "lctrl" then
                value = value .. e.key
                updateText()
            end
            lastKey = e.key
        end
        return true
    end

    bg:addEvent('touch', function() return true end)
    inputBox:addEvent('key', keyListener)

    m.back = 'lock'
end

local function inputNumber(callback, title)
    local inputGroup = m.group:newGroup()
    local bg = inputGroup:newRect(mane.display.centerX, mane.display.centerY, mane.display.width, mane.display.height)
    bg.color = {0, 0, 0, 0.8}

    local inputBox = inputGroup:newRect(mane.display.centerX, mane.display.centerY, 200, 50)
    inputBox.color = {1, 1, 1, 1}

    local titleText = inputGroup:newPrint(title or "Enter value", 'res/Venus.ttf', mane.display.centerX, mane.display.centerY - 40, 20)

    local value = ""
    local text = inputGroup:newPrint(value, 'res/Venus.ttf', mane.display.centerX, mane.display.centerY, 25)
    text:setColor(0,0,0,1)

    local function updateText()
        text.text = value
    end

    local function keyListener(e)
        if e.phase == "ended" then
            if e.key == "enter" or e.key == "return" then
                inputGroup:remove()
                if value ~= "" then
                    m.back = 'main'
                    callback(tonumber(value) or 0)
                end
            elseif e.key == "backspace" then
                value = value:sub(1, -2)
                updateText()
            elseif e.key:match("%d") or e.key == "." then
                value = value .. e.key
                updateText()
            end
        end
        return true
    end

    bg:addEvent('touch', function() return true end)
    inputBox:addEvent('key', keyListener)

    m.back = 'lock'
end

local function selectWeapon(callback)
    local weaponGroup = m.group:newGroup()
    local bg = weaponGroup:newRect(mane.display.centerX, mane.display.centerY, mane.display.width, mane.display.height)
    bg.color = {0, 0, 0, 0.8}
    bg:addEvent('touch', function() return true end)

    local weapons = {
        {name = "Piston", x = mane.display.centerX, y = mane.display.centerY},
        {name = "AK47", x = mane.display.centerX - 150, y = mane.display.centerY - 50},
        {name = "MP40", x = mane.display.centerX + 150, y = mane.display.centerY - 50},
        {name = "Snipe", x = mane.display.centerX - 150, y = mane.display.centerY + 50},
        {name = "Shotgun", x = mane.display.centerX + 150, y = mane.display.centerY + 50}
    }

    for i, weapon in ipairs(weapons) do
        local button = weaponGroup:newRect(weapon.x, weapon.y, 100, 40)
        button.color = {1, 1, 1, 1}
        local text = weaponGroup:newPrint(weapon.name, 'res/Venus.ttf', weapon.x, weapon.y, 20)
        text:setColor(0, 0, 0, 1)

        button:addEvent('touch', function(e)
            if e.phase == 'ended' then
                weaponGroup:remove()
                callback(weapon.name)
            end
            return true
        end)
    end
end

local function openBlocks()
    m.back = "openBlocks"
    local group = m.group:newGroup()
    m.openBlocksGroup = group

    local bg = group:newRect(mane.display.centerX, mane.display.centerY, mane.display.width, mane.display.height)
    bg:addEvent('touch', function () return true end)
    bg.color = {0, 0, 0, 0.8}

    local baseScale = math.min(mane.display.width, mane.display.height) / 200
    local buttonSpacing = mane.display.width * 0.15

    local blocks = group:newSprite(m.spriteSheet[1], mane.display.centerX - buttonSpacing, mane.display.height * 0.95)
    blocks:scale(baseScale * 2, baseScale * 2)
    blocks.button = "blocks"

    local specials = group:newSprite(m.spriteSheet[2], mane.display.centerX, mane.display.height * 0.95)
    specials.frame = 2
    specials:scale(baseScale * 2, baseScale * 2)
    specials.button = "specials"

    local dekor = group:newSprite(m.spriteSheet[3], mane.display.centerX + buttonSpacing, mane.display.height * 0.95)
    dekor.frame = 4
    dekor:scale(baseScale * 2, baseScale * 2)
    dekor.button = "dekor"

    local blocksArea = group:newGroup()
    blocksArea.x = 0
    blocksArea.y = 0

    local function showCategory(category)
        blocksArea:removeObjects()

        local sheetIndex = (category == "blocks" and 1) or (category == "specials" and 2) or 3
        local frames = (sheetIndex == 1 and 56) or (sheetIndex == 2 and 43) or 36

        local cols = 8
        local rows = math.ceil(frames / cols)
        local blockSize = math.min(mane.display.width / (cols + 1), mane.display.height / (rows + 2))
        local blockScale = blockSize / 10
        local paddingX = blockSize * 0.5
        local paddingY = blockSize * 0.5

        local gridWidth = cols * blockSize
        local gridHeight = rows * blockSize
        local startX = (mane.display.width - gridWidth) / 2
        local startY = (mane.display.height - gridHeight) / 2

        for i = 1, frames do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local block = blocksArea:newSprite(m.spriteSheet[sheetIndex], 
                startX + col * blockSize + paddingX, 
                startY + row * blockSize + paddingY)
            block.frame = i
            block:scale(blockScale, blockScale)
            block:addEvent('touch', function(e)
                if e.phase == 'ended' then
                    currentBlock.sheet = sheetIndex
                    currentBlock.frame = i
                    m.block.frame = i
                    m.block.spriteSheet = m.spriteSheet[sheetIndex]
                    m.openBlocksGroup:remove()
                    m.openBlocksGroup = nil
                    m.back = "main"
                end
                return true
            end)
        end
    end

    local function categoryClick(e)
        if e.phase == 'ended' then
            showCategory(e.target.button)
        end
        return true
    end

    blocks:addEvent('touch', categoryClick)
    specials:addEvent('touch', categoryClick)
    dekor:addEvent('touch', categoryClick)
end

listeners.lastik = function (e)
    if not m.lastik then
        e.image = mane.images['res/images/buttons/green.png']
        m.lastik = true
    else
        e.image = mane.images['res/images/buttons/red.png']
        m.lastik = false
    end
end

listeners.block = function ()
    openBlocks()
end

listeners.save = function ()
    print(1)
    print(mane.json.encode(m.MapData))
    love.system.setClipboardText(mane.json.encode(m.MapData))
end

listeners.load = function ()
    print(1)
    inputText(function (text)
        local level = mane.json.decode(text)
        m.MapBlocks = {}
        m.MapData = level

        m.Map:removeObjects()
        m.Map:newImage('res/images/skins/skin1.png', 0, 0, 5, 5)

        for key, value in pairs(level) do
            for i = 1, #value, 1 do
                local blockData = level[key][i]
                local block = m.Map:newSprite(
                    m.spriteSheet[blockData.tileset],
                    blockData.x,
                    blockData.y
                )
                block.frame = blockData.frame
                block:scale(72.5/8, 72.5/8)
                block.angle = blockData.angle
                block.color[4] = blockData.alpha

                -- local blockData2 = {
                --     tileset = currentBlock.sheet,
                --     frame = currentBlock.frame,
                --     x = gridX,
                --     y = gridY,
                --     angle = m.rotation,
                --     alpha = m.alpha,
                --     body = m.isDynamic and 'dynamic' or 'static',
                --     isSensor = m.isDecoration
                -- }
                m.MapBlocks["block_"..key .. #m.MapData[key]] = block
                if #m.MapData[key] > 1 then
                    local text
                    if not m.MapBlocks["blockText_"..key] then
                        text = m.Map:newPrint('block: ' .. tostring(#m.MapData[key]), 'res/Venus.ttf', block.x, block.y + 30, 15)
                        m.MapBlocks["blockText_"..key] = text
                    else
                        text = m.MapBlocks["blockText_"..key]
                        text.text = 'block: ' .. tostring(#m.MapData[key])
                        text:toFront()
                    end
                end
            end
        end
    end, 'Введите код уровня')
end

listeners.launch = function ()
    m.group.isVisible = false
    Scenes.game.runEditor(m.MapData)
end

listeners.exit = function ()
    m.remove()
    Scenes.menu.create()
end

listeners.transparency = function ()
    inputNumber(function(value)
        m.block.color[4] = math.max(0, math.min(1, value / 100))
        m.alpha = math.max(0, math.min(1, value / 100))
    end, "Enter transparency (0-100)")
end

listeners.rotation = function ()
    inputNumber(function(value)
        m.block.angle = value % 360
        m.rotation = value
    end, "Enter rotation (degrees)")
end

listeners.dynamic = function (e)
    if not m.isDynamic then
        e.image = mane.images['res/images/buttons/green.png']
        e.text.text = "Динамический"
        m.isDynamic = true
    else
        e.image = mane.images['res/images/buttons/red.png']
        e.text.text = "Статический"
        m.isDynamic = false
    end
end

listeners.decoration = function (e)
    if not m.isDecoration then
        e.image = mane.images['res/images/buttons/green.png']
        e.text.text = "Декорация"
        m.isDecoration = true
    else
        e.image = mane.images['res/images/buttons/red.png']
        e.text.text = "Блок"
        m.isDecoration = false
    end
end

local click = function (e)
    if e.phase == 'began' then
        e.target.color[4] = 0.8
    elseif e.phase == 'ended' or e.phase == 'cancelled' then
        e.target.color[4] = 1
        if listeners[e.target.button] then
            listeners[e.target.button](e.target)
        else
            error('no button in listeners', 2)
        end
    end
    return true
end

local function snapToGrid(value)
    return math.floor((value + 40) / 80) * 80
end

local function placeBlock(x, y)
    local gridX = snapToGrid(x)
    local gridY = snapToGrid(y)
    local key = gridX .. "," .. gridY

    if m.lastik and m.MapData[key] then
        if not m.MapData[key] then
            return
        end
        local block = m.MapBlocks["block_"..key .. #m.MapData[key]]
        if block then
            block:remove()
            m.MapBlocks["block_"..key .. #m.MapData[key]] = nil
            table.remove(m.MapData[key], #m.MapData[key])
            if #m.MapData[key] <= 1 then
                if m.MapBlocks["blockText_"..key] then
                    m.MapBlocks["blockText_"..key]:remove()
                    m.MapBlocks["blockText_"..key] = nil
                end
            end
            if #m.MapData[key] == 0 then
                m.MapData[key] = nil
            else
                if m.MapBlocks["blockText_"..key] then
                    m.MapBlocks["blockText_"..key].text = 'block: ' .. tostring(#m.MapData[key])
                end
            end
            block = nil
        end
        return
    end

    local block = m.Map:newSprite(
        m.spriteSheet[currentBlock.sheet],
        gridX,
        gridY
    )
    block.frame = currentBlock.frame
    block:scale(72.5/8, 72.5/8)
    block.angle = m.rotation
    block.color[4] = m.alpha

    local blockData = {
        tileset = currentBlock.sheet,
        frame = currentBlock.frame,
        x = gridX,
        y = gridY,
        angle = m.rotation,
        alpha = m.alpha,
        body = m.isDynamic and 'dynamic' or 'static',
        isSensor = m.isDecoration
    }

    if currentBlock.sheet== 3 then
        blockData.body = nil
    end

    local isSave = false
    local function saveBlock()
        if isSave then
            return
        end
        isSave = true
        if not m.MapData[key] then
            m.MapData[key] = {}
        end
        table.insert(m.MapData[key], blockData)
        m.MapBlocks["block_"..key .. #m.MapData[key]] = block
        if #m.MapData[key] > 1 then
            local text
            if not m.MapBlocks["blockText_"..key] then
                text = m.Map:newPrint('block: ' .. tostring(#m.MapData[key]), 'res/Venus.ttf', block.x, block.y + 30, 15)
                m.MapBlocks["blockText_"..key] = text
            else 
                text = m.MapBlocks["blockText_"..key]
                text.text = 'block: ' .. tostring(#m.MapData[key])
                text:toFront()
            end
        end
    end

    if currentBlock.sheet == 2 and (currentBlock.frame == 27 or currentBlock.frame == 43) then
        blockData.width = 50
        blockData.height = 50
        block.xScale, block.yScale = 50/8, 50/8
        blockData.body = 'dynamic'
        selectWeapon(function(weapon)
            blockData.weapon = weapon
            saveBlock()
        end)
    elseif currentBlock.sheet == 2 and (currentBlock.frame == 11 or currentBlock.frame == 12) then
        inputText(function (text)
            blockData.id = text
            saveBlock()
        end, 'Ввведите id телепортации')
    elseif currentBlock.sheet == 2 and currentBlock.frame == 17 then
        blockData.body = nil
        inputText(function (text)
            blockData.text = text
            saveBlock()
        end, 'Ввведите текст')
    elseif currentBlock.sheet == 2 and currentBlock.frame == 23 then
        blockData.isSensor = true
        inputNumber(function (num)
            blockData.gravity = num
            saveBlock()
        end, 'Ввведите силу гравитации')
    elseif currentBlock.sheet == 2 and (currentBlock.frame == 24 or currentBlock.frame == 25) then
        inputText(function (text)
            blockData.id = text
            saveBlock()
        end, 'Ввведите id двери')
    elseif currentBlock.sheet == 2 and (currentBlock.frame == 22 or currentBlock.frame == 21 or currentBlock.frame == 20 or currentBlock.frame == 42) then
        blockData.body = nil
        inputNumber(function (num)
            blockData.distance = num
            saveBlock()
        end, 'Ввведите дальность орудия')
    else
        saveBlock()
    end
    saveBlock()
end

local function stopMovement()
    if moveTimer then
        moveTimer:cancel()
        moveTimer = nil
    end
    moveDirection.x = 0
    moveDirection.y = 0
end

local function startMovement()
    if not moveTimer then
        moveTimer = mane.timer.new(16, function()
            if not m.Map then
                moveTimer:cancel()
                moveTimer = nil
                return
            end
            m.Map.x = m.Map.x + (moveDirection.x * cameraSpeed)
            m.Map.y = m.Map.y + (moveDirection.y * cameraSpeed)
        end, 0)
    end
end

m.create = function ()
    currentBlock = {sheet = 1, frame = 1}
    m.lastik = false
    m.alpha = 1
    m.rotation = 0
    m.isDynamic = false
    m.isDecoration = false
    m.back = "main"

    local spriteSheet = {}
    spriteSheet[1] = mane.graphics.newSpriteSheet('res/images/blocks.png',10, 10, 56, 16)
    spriteSheet[2] = mane.graphics.newSpriteSheet('res/images/blocks2.png',10, 10, 43, 12)
    spriteSheet[3] = mane.graphics.newSpriteSheet('res/images/blocks3.png',10, 10, 36, 20)
    m.spriteSheet = spriteSheet

    local group = mane.display.game:newGroup()
    m.group = group

    m.Map = group:newGroup()
    m.MapBlocks = {}
    m.MapData = {}

    local bgTouch = group:newRect(mane.display.centerX, mane.display.centerY, mane.display.width, mane.display.height)
    bgTouch.color = {0, 0, 0, 0}
    local oldBlock = "0.1 0.1"
    bgTouch:addEvent('touch', function(e)
        if e.phase == 'began' and m.back == "main" then
            placeBlock(e.x - m.Map.x, e.y - m.Map.y)
            oldBlock = snapToGrid(e.x - m.Map.x) .. " " .. snapToGrid(e.y - m.Map.y)
        elseif e.phase == 'moved' and m.back == "main" then
            if oldBlock ~= snapToGrid(e.x - m.Map.x) .. " " .. snapToGrid(e.y - m.Map.y) then
                oldBlock = snapToGrid(e.x - m.Map.x) .. " " .. snapToGrid(e.y - m.Map.y)
                placeBlock(e.x - m.Map.x, e.y - m.Map.y)
            end
        end
        return true
    end)

    local launch = group:newImage('res/images/buttons/green.png', mane.display.centerX + mane.display.width/2 - 100, 40, 2, 2)
    local launchText = group:newPrint('Запустить', 'res/Venus.ttf', launch.x, launch.y)
    launch.button = 'launch'
    launch:addEvent('touch', click)

    local save = group:newImage('res/images/buttons/yellow.png', mane.display.centerX + mane.display.width/2 - 270, 40, 2, 2)
    local saveText = group:newPrint('Сохранить', 'res/Venus.ttf', save.x, save.y)
    save.button = 'save'
    save:addEvent('touch', click)

    local load = group:newImage('res/images/buttons/blue.png', mane.display.centerX + mane.display.width/2 - 270 - 170, 40, 2, 2)
    local loadText = group:newPrint('Загрузить', 'res/Venus.ttf', load.x, load.y)
    load.button = 'load'
    load:addEvent('touch', click)

    local exit = group:newCircle(40, 40, 0)
    exit.button = 'exit'
    exit:addEvent('touch', click)
    exit:addEvent('key', function (e)
        if e.phase == "ended" and m.group.isVisible then
            if e.key == "escape" then
                if m.back == "openBlocks" then
                    m.openBlocksGroup:remove()
                    m.openBlocksGroup = nil
                    m.back = "main"
                elseif m.back == "main" then
                    m.remove()
                    Scenes.menu.create()
                end
                return true
            end
        end
        if e.phase == "began" and not e.isrepeat and m.Map then
            if e.key == "left" then
                moveDirection.x = 1
                startMovement()
            elseif e.key == "right" then
                moveDirection.x = -1
                startMovement()
            elseif e.key == "up" then
                moveDirection.y = 1
                startMovement()
            elseif e.key == "down" then
                moveDirection.y = -1
                startMovement()
            end
        elseif e.phase == "ended" and m.Map then
            if e.key == "left" and moveDirection.x == 1 then
                moveDirection.x = 0
            elseif e.key == "right" and moveDirection.x == -1 then
                moveDirection.x = 0
                if moveDirection.y == 0 then stopMovement() end
            elseif e.key == "up" and moveDirection.y == 1 then
                moveDirection.y = 0
                if moveDirection.x == 0 then stopMovement() end
            elseif e.key == "down" and moveDirection.y == -1 then
                moveDirection.y = 0
                if moveDirection.x == 0 then stopMovement() end
            end
        end
    end)

    local lastik = group:newImage('res/images/buttons/red.png', 90, mane.display.height - 25, 2, 2)
    local lastikText = group:newPrint('Ластик', 'res/Venus.ttf', lastik.x, lastik.y, 20)
    lastik.button = 'lastik'
    lastik:addEvent('touch', click)

    m.block = group:newSprite(spriteSheet[1], 60, mane.display.height - 100)
    m.block:scale(10, 10)
    m.block.button = "block"
    m.block:addEvent('touch', click)

    m.Map:newImage('res/images/skins/skin1.png', 0, 0, 5, 5)

    local transparency = group:newImage('res/images/buttons/purple.png', 250, mane.display.height - 25, 2, 2)
    local transText = group:newPrint('Прозрачность', 'res/Venus.ttf', transparency.x, transparency.y, 20)
    transparency.button = 'transparency'
    transparency:addEvent('touch', click)

    local rotation = group:newImage('res/images/buttons/orange.png', 410, mane.display.height - 25, 2, 2)
    local rotText = group:newPrint('Вращение', 'res/Venus.ttf', rotation.x, rotation.y, 20)
    rotation.button = 'rotation'
    rotation:addEvent('touch', click)

    local dynamic = group:newImage('res/images/buttons/red.png', 570, mane.display.height - 25, 2, 2)
    local dynamicText = group:newPrint('Статический', 'res/Venus.ttf', dynamic.x, dynamic.y, 20)
    dynamic.button = 'dynamic'
    dynamic.text = dynamicText
    dynamic:addEvent('touch', click)

    local decoration = group:newImage('res/images/buttons/red.png', 730, mane.display.height - 25, 2, 2)
    local decorText = group:newPrint('Блок', 'res/Venus.ttf', decoration.x, decoration.y, 20)
    decoration.button = 'decoration'
    decoration.text = decorText
    decoration:addEvent('touch', click)
end

m.remove = function ()
    m.group:remove()
    for key, value in pairs(m) do
        if key ~= 'create' and key ~= 'remove' then
            m[key] = nil
        end
    end
end

return m