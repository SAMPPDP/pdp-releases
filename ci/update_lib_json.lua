local lfs = require('lfs')

local function scan_directory(path)
  print('PATH! ' .. path)
  local file_attributes = lfs.attributes(path)

  if not file_attributes then
    print('Error getting attributes for: ' .. path)
    return
  end

  if file_attributes.mode == 'file' then
    print('File: ' .. path)
    --! FILE !--
    local file, err = io.open(path)
    if not file or err then
      error(path .. '(type: ' .. type(file) .. ') -> Error: ' .. err)
    end
    return
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

scan_directory('lua/lib')
