---@class Exporter
local Exporter = {}

---Check if a file exists
---@param filename string
---@return boolean
function Exporter.fileExists(filename)
    local f = io.open(filename, "r")
    if f ~= nil then
        io.close(f)
        return true
    end
    return false
end

---Load string content from a file path
---@param path string
---@return string? content
---@return string? errorMsg
function Exporter.loadFile(path)
    local file, err = io.open(path, "r")
    if not file then
        return nil, err or "Failed to open file for reading"
    end
    local content = file:read("*a")
    file:close()
    return content, nil
end


---Save string content to a file path
---@param path string
---@param data string
---@return boolean success
---@return string? errorMsg
function Exporter.saveFile(path, data)
    local file, err = io.open(path, "w")
    if not file then
        return false, err or "Failed to open file for writing"
    end
    file:write(data)
    file:close()
    return true, nil
end

return Exporter
