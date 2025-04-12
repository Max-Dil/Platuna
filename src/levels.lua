local m = {}
local listeners = {}

listeners.level = function (e)
    m.remove()
    Scenes.game.create(e.level)
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

    local saves = require('saves')
    local currentLevel = saves.load('level', 1)

    local count = 75
    local size = mane.display.width/15
    local l = 0
    for i = 1, count/15, 1 do
        for i2 = 1, 15, 1 do
            local level = group:newRect(-size/2 + (size * i2), -size/2 + (size * i), size-5, size-5, 10, 10)
            level:setColor(0 + 0.2 * i, 0.5, 0.7, 1)
            level.button = 'level'

            l = l + 1
            level.level = l
            local levelText = group:newPrint(l, 'res/Venus.ttf', level.x, level.y, 30)

            if currentLevel < l then
                level.color[4] = 0.5
            else
                level:addEvent('touch', click)
            end
        end
    end

    local exit = group:newCircle(40, 40, 0)
    exit:addEvent('key', function (e)
        if e.phase == "ended" and m.group.isVisible then
            if e.key == "escape" then
                m.remove()
                Scenes.menu.create()
                return true
            end
        end
    end)
end

m.remove = function ()
    m.group:remove()
    m.group = nil
end

return m