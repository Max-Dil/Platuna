--love.window.setMode(800, 800, {vsync = 0})
love.window.setFullscreen(true)
love.graphics.setDefaultFilter( 'nearest', 'nearest', 1 )
require('mane')
math.randomseed(math.random(1,99999))

mane.fps = 5000

function mane.load()
    Runtime = mane.display.game:newRect(mane.display.centerX, mane.display.centerY, mane.display.width, mane.display.height)
    Runtime.isVisible = false

    local saves = require('saves')
    if saves.load('level', false) == false then
        saves.save('level', 1)
    end
    if saves.load('money', false) == false then
        saves.save('money', 0)
    end

    Scenes = {
        menu = require('src.menu'),
        levels = require('src.levels'),
        editor = require('src.editor'),
        game = require('src.game'),
        options = require('src.options')
    }

    Scenes.menu.create()
end