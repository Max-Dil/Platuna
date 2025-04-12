local save_file = "save.dat"

local function save(key, value)
    local data = {}
    if love.filesystem.getInfo(save_file) then
        local file = love.filesystem.newFile(save_file)
        if file then
            local success, file_data = pcall(file.read, file)
            if success and file_data then
                data = mane.json.decode(file_data) or {}
            end
        end
    end

    data[key] = value

    local encoded_data = mane.json.encode(data)
    if encoded_data then
        love.filesystem.write(save_file, encoded_data)
    else
        print("Ошибка кодирования данных для сохранения.")
    end
end

local function load(key, default)
    if love.filesystem.getInfo(save_file) then
        local file = love.filesystem.newFile(save_file)
        if file then
            local success, file_data = pcall(file.read, file)
            if success and file_data then
                local data = mane.json.decode(file_data) or {}
                return data[key] or default
            end
        end
    end

    return default
end

return {
    save = save,
    load = load
}