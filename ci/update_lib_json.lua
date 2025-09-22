local lfs = require('lfs')
local dkjson = require('dkjson')
local sha1 = require('sha1')

-- local path_github = lfs.currentdir() -- /home/runner/work/releases/%current_repos%
-- local path_lib = path_github .. '/lua/lib'

local function scan_directory(path)
  local directory_iterator, error_message = lfs.dir(path)

  if not directory_iterator then
    error('Error opening directory: ' .. path .. ' - ' .. error_message)
  end

  for entry in directory_iterator do
    if entry ~= '.' and entry ~= '..' then
      local full_path = path .. '/' .. entry
      local file_attributes = lfs.attributes(full_path)

      if file_attributes then
        if file_attributes.mode == 'file' then
          local file, errmsg = io.open(full_path)
          if not file or errmsg then
            error(errmsg)
          end
          local source = file:read('a')
          file:close()
          print('File: ' .. full_path)
          print('SHA1.SHA1: ' .. sha1.sha1(source))
          print('SHA1 Binary: ' .. sha1.binary(source))
        elseif file_attributes.mode == 'directory' then
          print('Directory: ' .. full_path)
          scan_directory(full_path) -- recursive sub-dir
        else
          print('Unknown entry: ' .. full_path .. ' (mode: ' .. file_attributes.mode .. ')')
        end
      else
        print('Error getting attributes for: ' .. full_path)
      end
    end
  end
end

scan_directory(lfs.currentdir()) -- Start scanning from the current directory

-- local str_json = dkjson.encode(data, { indent = 4 })
