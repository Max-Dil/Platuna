local m = {}
local listeners = {}

local click = function(e)
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

m.create = function()
    local group = mane.display.game:newGroup()
    m.group = group

    local saves = require('saves')
    local optionsData = saves.load('options', {
        volume = 0.5,
        music = true,
        fps = 120,
        vsync = true
    })

    -- Music toggle
    local musicLabel = group:newPrint("Music: " .. (optionsData.music and "On" or "Off"), 'res/Venus.ttf', 100, 150, 20)
    local musicToggle = group:newRect(300, 150, 80, 40)
    musicToggle.color = optionsData.music and {0, 1, 0, 1} or {1, 0, 0, 1}
    musicToggle.button = "music"

    listeners.music = function(target)
        optionsData.music = not optionsData.music
        musicLabel.text = "Music: " .. (optionsData.music and "On" or "Off")
        target.color = optionsData.music and {0, 1, 0, 1} or {1, 0, 0, 1}
        saves.save('options', optionsData)
    end

    -- VSync toggle
    local vsyncLabel = group:newPrint("VSync: " .. (optionsData.vsync and "On" or "Off"), 'res/Venus.ttf', 100, 250, 20)
    local vsyncToggle = group:newRect(300, 250, 80, 40)
    vsyncToggle.color = optionsData.vsync and {0, 1, 0, 1} or {1, 0, 0, 1}
    vsyncToggle.button = "vsync"

    listeners.vsync = function(target)
        optionsData.vsync = not optionsData.vsync
        vsyncLabel.text = "VSync: " .. (optionsData.vsync and "On" or "Off")
        target.color = optionsData.vsync and {0, 1, 0, 1} or {1, 0, 0, 1}
        love.window.setMode(mane.display.width, mane.display.height, {vsync = optionsData.vsync and 1 or 0})
        saves.save('options', optionsData)
    end

    -- FPS selector
    local fpsOptions = {30, 60, 120, 240, 480, 960, "infinity"}
    local fpsLabel = group:newPrint("FPS: " .. optionsData.fps, 'res/Venus.ttf', 100, 200, 20)
    local fpsButtons = {}

    for i, fps in ipairs(fpsOptions) do
        local button = group:newRect(200 + (i-1) * 60, 200, 50, 40)
        button.color = optionsData.fps == fps and {0, 1, 0, 1} or {0.5, 0.5, 0.5, 1}
        button.button = "fps" .. fps
        button.fpsValue = fps

        local text = group:newPrint(tostring(fps), 'res/Venus.ttf', button.x, button.y, 20)

        listeners["fps" .. fps] = function(target)
            optionsData.fps = target.fpsValue
            fpsLabel.text = "FPS: " .. optionsData.fps
            for _, btn in ipairs(fpsButtons) do
                btn.color = {0.5, 0.5, 0.5, 1}
            end
            target.color = {0, 1, 0, 1}
            saves.save('options', optionsData)
        end

        fpsButtons[i] = button
    end

    for _, obj in pairs(group.obj) do
        if obj.button then
            obj:addEvent('touch', click)
        end
    end

    local exit = group:newCircle(40, 40, 0)
    exit.color = {1, 0, 0, 1}
    exit.button = "exit"

    listeners.exit = function()
        m.remove()
        Scenes.menu.create()
    end

    exit:addEvent('touch', click)

    exit:addEvent('key', function(e)
        if e.phase == "ended" and m.group.isVisible then
            if e.key == "escape" then
                m.remove()
                Scenes.menu.create()
                return true
            end
        end
    end)
end

m.remove = function()
    if m.group then
        m.group:remove()
        m.group = nil
    end
end

return m