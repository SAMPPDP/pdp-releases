local sha1 = require('sha1')
local json = require('dkjson')

local argument = table.concat(arg, '   ')
local repos = argument:match('repository=(%S+)')
local branch = argument:match('branch=(%S+)')
local filename = argument:match('filename=(.-%.luac)')

local file, errmsg = io.open(filename, 'rb')
assert(file, errmsg)
local source_binary = file:read('*a')
file:close()

local lib_json = json.encode({
    timestamp = os.time(),
    filename = filename,
    sha1 = sha1.sha1(source_binary),
    url_raw = string.format('https://raw.githubusercontent.com/%s/%s/%s', repos, branch, filename)
}, {
    indent = 4
})

local file_json, errmsg_json = io.open('script.json', 'w')
if not file_json or errmsg_json then
    error('cannon create new file json, error: ' .. errmsg_json)
end
file_json:write(lib_json) ---@diagnostic disable-line: param-type-mismatch
file_json:close()
