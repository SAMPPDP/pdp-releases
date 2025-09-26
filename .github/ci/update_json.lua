local lfs = require('lfs')
local sha1 = require('sha1')
local dkjson = require('dkjson')

local argument = table.concat(arg, '   ')
local repos = argument:match('repository=(%S+)')
local branch = argument:match('branch=(%S+)')
local filename = argument:match('filename=(.-%.luac?)')

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
    print('scanning: ' .. path)

    local file_attributes = lfs.attributes(path)
    local tree = {}

    if not file_attributes then
        error('Error getting attributes for: ' .. path)
    end

    if file_attributes.mode == 'file' then
        local clock = os.clock()
        local file, err = io.open(path, 'rb')
        if not file or err then
            error(path .. ' | Type: ' .. type(file) .. ' -> Error: ' .. err)
        end
        local source_binary = file:read('*a')
        file:close()
        table.insert(tree, addFile(path, source_binary))
        print('added file to tree, clock:' .. tostring(os.clock() - clock))
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

do
    -- script
    local current_sha1 = nil
    local current_filename = nil
    local current_file, current_errmsg = io.open('script.json', 'r')
    if current_file and not current_errmsg then
        local source = current_file:read('*a')
        current_file:close()
        local current_json = dkjson.decode(source)
        current_filename = current_json.filename ---@diagnostic disable-line
        current_sha1 = current_json.sha1 ---@diagnostic disable-line
    else
        error('not found script.json?')
    end

    assert(current_sha1, 'empty sha1?')
    assert(current_filename, 'empty filename?')

    local file_script, errmsg_script = io.open(filename, 'rb')
    assert(file_script, errmsg_script)
    local source_binary = file_script:read('*a')
    file_script:close()
    local script_sha1 = sha1.sha1(source_binary)

    if
        current_sha1 and current_filename and
        current_sha1 == script_sha1 and current_filename == filename
    then
        return
    end

    local json = dkjson.encode({
        timestamp = os.time(),
        filename = filename,
        sha1 = script_sha1,
        url_raw = string.format('https://raw.githubusercontent.com/%s/%s/%s', repos, branch, filename)
    }, {
        indent = 4
    })

    local file, errmsg = io.open('script.json', 'w')
    if not file or errmsg then
        error('cannon create new file json, error: ' .. errmsg)
    end
    file:write(json) ---@diagnostic disable-line: param-type-mismatch
    file:close()
end

-- TODO: NEED CHECK SHA1!
-- for _, dir in ipairs({ 'lib', 'resource' }) do
--     local json = dkjson.encode({
--         timestamp = os.time(),
--         data = scan_directory(dir)[1].tree
--     }, {
--         indent = 4
--     })

--     local file, errmsg = io.open(dir .. '.json', 'w')
--     if not file or errmsg then
--         error('cannon create new file json, error: ' .. errmsg)
--     end
--     file:write(json) ---@diagnostic disable-line: param-type-mismatch
--     file:close()
-- end
