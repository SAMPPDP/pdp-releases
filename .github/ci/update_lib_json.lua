local lfs = require('lfs')
local sha1 = require('sha1')
local json = require('dkjson')

local argument = table.concat(arg, '   ')
print(argument)

local repos = argument:match('repository=(%S+)')
local branch = argument:match('branch=(%S+)')

print(repos)
print(branch)

local function smallPath(path)
    local small = path:match('[^/]+$')
    return small
end

local function addFile(path, source_binary)
    return {
        name = smallPath(path),
        type = 'file',
        sha1 = sha1.sha1(source_binary),
        url_raw = string.format('https://raw.githubusercontent.com/%s/%s/%s', repos, branch, path)
    }
end

local function addDir(path, tree)
    return {
        name = smallPath(path),
        type = 'dir',
        tree = tree or {}
    }
end

local function scan_directory(path)
    local file_attributes = lfs.attributes(path)
    local tree = {}

    if not file_attributes then
        error('Error getting attributes for: ' .. path)
    end

    if file_attributes.mode == 'file' then
        local file, err = io.open(path, 'rb')
        if not file or err then
            error(path .. ' | Type: ' .. type(file) .. ' -> Error: ' .. err)
        end
        local source_binary = file:read('*a')
        file:close()
        table.insert(tree, addFile(path, source_binary))
    elseif file_attributes.mode == 'directory' then
        local entries = {}
        for entry in lfs.dir(path) do
            if entry ~= '.' and entry ~= '..' then
                local full_path = path .. '/' .. entry
                local subtree = scan_directory(full_path)
                if subtree then
                    for i = 1, #subtree do
                        table.insert(entries, subtree[i])
                    end
                end
            end
        end
        table.insert(tree, addDir(path, entries))
    else
        error('Unknown entry: ' .. path .. ' (mode: ' .. file_attributes.mode .. ')')
    end

    return tree
end

local lib_json = json.encode({
    timestamp = os.time(),
    lib = scan_directory('lib')[1].tree
}, {
    indent = 4
})

local file_json, errmsg = io.open('lib.json', 'w')
if not file_json or errmsg then
    error('cannon create new file json, error: ' .. errmsg)
end

file_json:write(lib_json) ---@diagnostic disable-line: param-type-mismatch
file_json:close()
