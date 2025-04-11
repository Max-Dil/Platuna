return {
    -- Нижняя платформа
    { x = 0, y = 175, width = 100, height = 100, frame = 1, body = 'static' },
    { x = 100, y = 175, width = 100, height = 100, frame = 1, body = 'static' },
    { x = -100, y = 175, width = 100, height = 100, frame = 1, body = 'static' },
    { x = -200, y = 175, width = 100, height = 100, frame = 1, body = 'static' },
    { x = 200, y = 175, width = 100, height = 100, frame = 1, body = 'static' },

    -- Платформы в середине уровня
    { x = -300, y = 75, width = 100, height = 100, frame = 1, body = 'static' },
    { x = -100, y = 75, width = 100, height = 100, frame = 1, body = 'static' },
    { x = 100, y = 75, width = 100, height = 100, frame = 1, body = 'static' },
    { x = 300, y = 75, width = 100, height = 100, frame = 1, body = 'static' },

    -- Верхняя платформа
    { x = 100, y = -25, width = 100, height = 100, frame = 1, body = 'static' },
    { x = -200, y = -25, width = 100, height = 100, frame = 1, body = 'static' },
    { x = 200, y = -25, width = 100, height = 100, frame = 1, body = 'static' },

    -- Препятствия
    { x = -150, y = -125, width = 50, height = 50, frame = 8, body = 'static' },
    { x = 150, y = -125, width = 50, height = 50, frame = 8, body = 'static' },
    { x = 0, y = -125, width = 50, height = 50, frame = 8, body = 'static' },

    -- Враги
    { x = -250, y = 100, width = 50, height = 50, frame = 26, tileset = 2, body = 'static' },
    { x = 250, y = 100, width = 50, height = 50, frame = 26, tileset = 2, body = 'static' },
    { x = 0, y = -200, width = 50, height = 50, frame = 26, tileset = 2, body = 'static' },

    -- Объекты
    { x = -300, y = -25, width = 50, height = 50, frame = 13, tileset = 2, body = 'static' },
    { x = 300, y = -25, width = 50, height = 50, frame = 13, tileset = 2, body = 'static' },
    { x = 0, y = 75, width = 50, height = 50, frame = 13, tileset = 2, body = 'static' },

    -- Дополнительные платформы
    { x = -400, y = 175, width = 100, height = 100, frame = 1, body = 'static' },
    { x = 400, y = 175, width = 100, height = 100, frame = 1, body = 'static' },
    { x = -400, y = -25, width = 100, height = 100, frame = 1, body = 'static' },
    { x = 400, y = -25, width = 100, height = 100, frame = 1, body = 'static' },
}