local lfs = require('lfs')
local dkjson = require('dkjson')
local sha1 = require('sha1')

-- local path_github = lfs.currentdir() -- /home/runner/work/releases/%current_repos%
-- local path_lib = path_github .. '/lua/lib'

local function scan_directory(path)
  local file_attributes = lfs.attributes(path)

  if not file_attributes then
    print('Error getting attributes for: ' .. path)
    return
  end

  if file_attributes.mode == 'file' then
    print('File: ' .. path)
    -- print('  -- заметка: можно применить file = io.open(' .. path .. ', 'r') чтобы читать файл')
    local file, err = io.open(path)
    if not file or err then
      error(path .. '(type: ' .. type(file) .. ') -> Error: ' .. err)
    end
    return -- Stop scanning if it's a file
  elseif file_attributes.mode == 'directory' then
    local directory_iterator = lfs.dir(path)

    if type(directory_iterator) ~= 'function' then
      print('Error opening directory: ' .. path)
      return
    end

    for entry in directory_iterator do
      if entry ~= '.' and entry ~= '..' then
        local full_path = path .. '/' .. entry
        scan_directory(full_path) -- Recursive call
      end
    end
  else
    print('Unknown entry: ' .. path .. ' (mode: ' .. file_attributes.mode .. ')')
  end
end

local current_dir = lfs.currentdir()
print(current_dir)

scan_directory(current_dir) -- Start scanning from the current directory

-- local str_json = dkjson.encode(data, { indent = 4 })
