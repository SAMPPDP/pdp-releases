print(package.path)
print(package.cpath)

local lfs = require('lfs')
local dkjson = require('dkjson')
local sha1 = require('sha1')

print(sha1.version)

local message = 'hello world lua best love'
print(message)

local hash_as_hex = sha1.sha1(message)
local hash_as_data = sha1.binary(message)
local hmac_as_hex = sha1.hmac('x32', message)
local hmac_as_data = sha1.hmac_binary('x32', message)

local data = {
    hash_as_hex = hash_as_hex,
    hash_as_data = hash_as_data,
    hmac_as_hex = hmac_as_hex,
    hmac_as_data = hmac_as_data,
}

local str_json = dkjson.encode(data)
print(str_json)

local current_dir = lfs.currentdir()
print(current_dir)

print('Current working directory:', current_dir)
