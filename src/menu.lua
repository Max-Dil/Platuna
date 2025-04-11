local m = {}
local listeners = {}

listeners.start = function ()
    m.remove()
    Scenes.game.create()
end

listeners.editor = function ()
    m.remove()
    Scenes.editor.create()
end

listeners.exit = function ()
    os.exit()
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
end

m.create = function ()
    local group = mane.display.game:newGroup()
    m.group = group

    local title = group:newPrint('Platuna', 'res/Venus.ttf', mane.display.centerX, mane.display.centerY - 160, 30)

    local start = group:newImage('res/images/buttons/green.png', mane.display.centerX, mane.display.centerY - 100, 3, 3)
    local startText = group:newPrint('Уровни', 'res/Venus.ttf', start.x, start.y, 30)
    startText:scale(-0.2, -0.2)
    start.button = 'start'
    start:addEvent('touch', click)

    local editor = group:newImage('res/images/buttons/magenta.png', mane.display.centerX, mane.display.centerY - 30, 3, 3)
    local editorText = group:newPrint('Свой уровень', 'res/Venus.ttf', editor.x, editor.y, 30)
    editorText:scale(-0.2, -0.2)
    editor.button = 'editor'
    editor:addEvent('touch', click)

    local exit = group:newImage('res/images/buttons/red.png', mane.display.centerX, mane.display.centerY + 40, 3, 3)
    local exitText = group:newPrint('Выйти', 'res/Venus.ttf', exit.x, exit.y, 30)
    exitText:scale(-0.2, -0.2)
    exit.button = 'exit'
    exit:addEvent('touch', click)
end

m.remove = function ()
    m.group:remove()
    m.group = nil
end

return m