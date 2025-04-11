--love.window.setMode(800, 800, {vsync = 0})
love.window.setFullscreen(true)
love.graphics.setDefaultFilter( 'nearest', 'nearest', 1 )
require('mane')
math.randomseed(math.random(1,99999))

mane.fps = 5000

function mane.load()
    Runtime = mane.display.game:newRect(mane.display.centerX, mane.display.centerY, mane.display.width, mane.display.height)
    Runtime.isVisible = false

    Scenes = {
        menu = require('src.menu'),
        editor = require('src.editor'),
        game = require('src.game')
    }

    Scenes.menu.create()
end