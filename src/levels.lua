local m = {}

m.create = function ()
    local group = mane.display.game:newGroup()
    m.group = group

    
end

m.remove = function ()
    m.group:remove()
    m.group = nil
end

return m