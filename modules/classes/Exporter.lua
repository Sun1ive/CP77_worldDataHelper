Exporter = {}

function Exporter.fileExists(filename)
    local f = io.open(filename, "r")
    if (f ~= nil) then
        io.close(f)
        return true
    else
        return false
    end
end

function Exporter.saveFile(path, data)
    local file = io.open(path, "w")
    if (file ~= nil) then
        file:write(data)
        file:close()
    end
end

return Exporter
