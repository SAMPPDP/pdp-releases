--[[

	CarboneumJsonConfig Library v.241220
	by Corenale for kekwait.su
	
	used libs:
		• dkjson - http://dkolf.de/dkjson-lua/
		• base64 - https://github.com/iskolbin/lbase64
		• reflect - https://github.com/corsix/ffi-reflect
	
	functionality:
		• save(path, cfg) for rewrite config in folder
		• load(path, cfg) for read config from folder
		• call config() for save it
		• or call like config("reset") for reset to default settings
		• full path like "C:\luaFolder\config\cfg.json"
		• or short path like "config\cfg.json" -- same places
		• can save cdata (a little)
		• saves cdata as table if can (unsupported some unknown weird shit)
		• if cdata can't be saved as table, it saves as base64 string
	
	update log:
		v250721 • fixed cdata parser fails with unk. reason (thx https://www.blast.hk/members/112329/ for find this)
		v241227 • fixed creating cdata from json (i'm stupud x2) (thx https://www.blast.hk/members/481726/ for find this)
		v241220 • short path fix for Windows (if you run the script just with "luajit shit.lua", the root folder will be the folder with the executable file) -- bruh pasted from todo
		v241127 • fixed cdata types mismatch problem when loading config x2 (thx https://www.blast.hk/members/125042/)
		v241024 • fixed cdata types mismatch problem when loading config
		v240804 • moved from parseback to reflect
		v240716 • fixed creating new cdata (i'm stupud) (thx https://www.blast.hk/members/481726/ for find this)
		v240709 • fixed script path qualifier
		v240706 • fixed pathFixer for Windows
		v240627 • fixed bugs and added new ones
		v240620 • added universal cdata saving method (saving bytes + base64 bytes packing)
		v240618 • added pathFixer
		v240617 • added main functional
		
	P.S.:
		• i would do autosave, but it won't work for cdata, so...
		• this code looks like a trash, so it's okay, that's my style

	TODO:
		• create folders if they don't exist
		• short path fix for Windows (if you run the script just with "luajit shit.lua", the root folder will be the folder with the executable file) -- completed (maybe)
		• multiconfig (if possible and if needed)
		• save lua functions (if needed)
		• save cdata functions (if possible)

]]

-- reflect pls (thx)

local carboneum = {}
local ffi = require('ffi')
ffi.cdef [[
	char *_getcwd(char *buffer, int maxlen);
	char *getcwd(char *buffer, int maxlen);
]]
local json = require('dkjson')
local base64 = require('base64')
local reflect = require('reflect')

local shortPath = ''
do
	local function getCDPath()
		if jit.os == 'Windows' then
			local testpath = ffi.new('char[256]')
			ffi.C._getcwd(testpath, 256)
			return ffi.string(testpath)
		else
			local testpath = ffi.new('char[4096]')
			ffi.C.getcwd(testpath, 4096)
			return ffi.string(testpath)
		end
	end

	local function getScriptPath()
		local i = 1
		while debug.getinfo(i, 'S') do
			-- print(debug.getinfo(i, "S").source)
			i = i + 1
		end
		local ret = debug.getinfo(i - 1, 'S').source
		return ret ~= '=[C]' and ret or debug.getinfo(i - 2, 'S').source
	end

	local scriptPath = getScriptPath()
	if scriptPath:find('/') or scriptPath:find('\\') then
		shortPath = getScriptPath():sub(2):gsub('(\\)', '/'):match('(.*/)') -- if not full path
	else
		shortPath = getCDPath():gsub('(\\)', '/') .. '/'                  -- if not full path
	end
end

local function pathFixer(path)
	-- local debugLevel = 2
	-- local temp = debug.getinfo(1, "S").source
	-- while temp do
	-- if debug.getinfo(debugLevel, "S").source ~= temp then
	-- temp = nil
	-- else
	-- debugLevel = debugLevel + 1
	-- end
	-- end
	-- local debugLevel = debug.getinfo(3) and 3 or 2 -- 3 if required, 2 if minified



	local pth = path:gsub('(\\)', '/')
	if jit.os == 'Windows' and not pth:find('^(%a:/)') then -- on linux everything is fine
		pth = shortPath .. pth
	end

	return pth
end

local function cdataparser(cdata, name, parcedcdata, outputtable)
	local multstruct
	if type(cdata) == 'cdata' then
		parcedcdata = cdata
		cdata = reflect.typeof(cdata)
		if (cdata.element_type and cdata.element_type.size ~= 'none') then
			multstruct = cdata.size / cdata.element_type.size
		end
	end

	local copy = outputtable or {}

	if multstruct then
		for i = 0, multstruct - 1 do
			copy[i + 1] = {}
			cdataparser(cdata.element_type, nil, parcedcdata[i], copy[i + 1])
		end
	elseif cdata.attributes or cdata.members then
		for refct in cdata:members() do
			if refct.type then
				if refct.type.what == 'array' then
					local count = refct.type.size / refct.type.element_type.size
					local name = refct.name and (name and name .. '.' or '') .. refct.name or name
					if refct.what == 'struct' then -- if struct shit[5]
						local refct = refct.type.element_type
						copy[refct.name] = {}
						for i = 0, count - 1 do
							copy[refct.name][i + 1] = {}
							local name = name .. '[' .. i .. ']'
							-- print(4, name)
							cdataparser(refct, name, parcedcdata[refct.name][i], copy[refct.name][i + 1])
						end
					else -- if float[5]
						copy[refct.name] = {}
						for i = 0, count - 1 do
							copy[refct.name][i + 1] = parcedcdata[refct.name][i]
							local name = name .. '[' .. i .. ']'
							-- print(3, name)
						end
					end
				elseif refct.type.what == 'struct' or refct.type.what == 'union' then -- if struct or union
					local name = refct.name and (name and name .. '.' or '') .. refct.name or name
					-- print(6, refct.what, refct.name, refct.type.what, name)
					copy[refct.name] = {}
					cdataparser(refct.type, name, parcedcdata[refct.name], copy[refct.name])
				else -- if just val lol
					copy[refct.name] = parcedcdata[refct.name]
					-- print(2, refct.what, refct.name, refct.type.what, refct.name and (name and name.."." or "")..refct.name or name)
				end
			elseif refct.transparent then -- if unnamed struct or union
				cdataparser(refct, name, parcedcdata, copy)
			end
		end
	end

	return copy
end

local function preptable2json(orig, copies, isKey)
	copies = copies or {}
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		if copies[orig] then
			copy = copies[orig]
		else
			copy = {}
			copies[orig] = copy
			for orig_key, orig_value in next, orig, nil do
				copy[preptable2json(orig_key, copies, true)] = preptable2json(orig_value, copies)
			end
		end
	elseif orig_type == 'cdata' then
		local typeof = tostring(ffi.typeof(orig)):match('^ctype<(.+)>$')

		local function saveAsBytes()
			local typeof = tostring(ffi.typeof(orig)):match('^ctype<(.+)>$')
			if typeof:match('(struct %d%d%d%d)') then
				typeof = nil
			end

			local isPointer = typeof:match('(%*)') and true or false
			local orig = isPointer and orig[0] or orig


			local size = ffi.sizeof(orig)
			local str = ffi.string(ffi.cast('void*', orig), size)

			copy = { orig_type, typeof, base64.encode(str) }
		end

		if typeof:find('struct') then
			if typeof:match('(struct %d%d%d%d)') then
				print('CarboneumJsonConfig: Saved unnamed cdata struct as bytes: ' .. typeof)
				saveAsBytes()
			else
				local tbl = cdataparser(orig)
				if tbl then
					copy = { orig_type, typeof, tbl }
				else
					saveAsBytes()
				end
			end
		else
			if typeof:match('%[(%d+)%]') then
				copy = { orig_type, typeof, {} }
				for i = 0, tonumber(typeof:match('%[(%d+)%]')) - 1 do
					copy[3][i + 1] = orig[i]
				end
			else
				print('CarboneumJsonConfig: Skipped weird cdata value: ' .. typeof)
			end
		end
	elseif orig_type == 'userdata' or orig_type == 'thread' or orig_type == 'function' then
		-- skip that shit
		print('CarboneumJsonConfig(save): Skipped unsavable variable type: ' .. orig_type)
	else
		copy = isKey and orig or { orig_type, orig }
	end
	return copy
end


function carboneum.load(path, table, original)
	local original = original or preptable2json(table)
	local mt = {}
	mt.__call = function(self, str)
		if str == 'reset' then
			configreset(path, table, original)
		else
			carboneum.save(path, table)
		end
	end
	setmetatable(table, mt)

	local file = io.open(pathFixer(path), 'r') -- open json file in read mode

	if not file then                          -- if json doesn't exist
		carboneum.save(path, table)
		return
	end

	local filestr = file:read('*a') -- read json file

	if filestr == '' then          -- if json is empty (for some reason)
		carboneum.save(path, table)
		return
	end

	local jsonTable = json.decode(filestr)
	file:close()

	function table_merge(target, source)
		for k, v in pairs(source) do
			if type(v) == 'table' then
				local orig_type
				if type(target) == 'table' then
					orig_type = type(target[k])
				else
					print('CarboneumJsonConfig(load): table struct has been changed, ignoring...')
					return
				end
				if (v[1] == nil) or type(v[1]) == 'table' then
					target[k] = target[k] or {}
					table_merge(target[k], v)
				elseif v[1] == 'cdata' then
					if type(v[3]) == 'string' then
						if not target[k] then
							if v[2] and not v[2]:match('(%*)') then
								target[k] = ffi.new(v[2])
							else
								if not v[2] then
									print('CarboneumJsonConfig(load): trying load var into unnamed unexisted cdata struct')
								else
									print('CarboneumJsonConfig(load): trying load var into unexisted pointer struct') -- ?
								end
							end
						end

						if target[k] then
							local isPointer = v[2]:match('(%*)') and true or false

							local bytes = base64.decode(v[3])
							if orig_type == 'cdata' and not (ffi.sizeof(isPointer and target[k][0] or target[k]) ~= #bytes) then
								ffi.copy(ffi.cast('void*', isPointer and target[k][0] or target[k]), bytes, #bytes)
							else
								if orig_type == 'cdata' then
									print(('CarboneumJsonConfig(load): cdata length size mismatch: j/t | %s/%s'):format(#bytes, ffi.sizeof(target[k])))
								else
									print(('CarboneumJsonConfig(load): data types mismatch: j/t | cdata/%s'):format(orig_type))
								end
								-- need to be config resaved, but fuck it
							end
						end
					else
						if orig_type == 'cdata' or orig_type == 'nil' then
							if target[k] and tostring(ffi.typeof(target[k])):match('^ctype<(.+)>$') == v[2] then
								local temp = ffi.new(v[2]:gsub('(%*)', ''), v[3])
								local str = ffi.string(temp, ffi.sizeof(temp))
								ffi.copy(ffi.cast('void*', target[k]), str, #str)
							else
								if not v[2]:match('(%*)') then
									if not target[k] or tostring(ffi.typeof(target[k])):match('^ctype<(.+)>$') == v[2] then
										target[k] = ffi.new(v[2], v[3])
									else
										print(('CarboneumJsonConfig(load): data types mismatch: j/t | %s/%s'):format(v[2], tostring(ffi.typeof(target[k])):match('^ctype<(.+)>$')))
										-- why we need to do something? (fix for devs bruh)
									end
								else
									print('CarboneumJsonConfig(load): trying load var into unexisted pointer struct')
								end
							end
						else
							print(('CarboneumJsonConfig(load): data types mismatch: j/t | %s/%s'):format(type(v[2]), orig_type))
							-- print(v[2])
						end
					end
				else
					if target[k] ~= nil and orig_type ~= type(v[2]) then -- for what
						print(('CarboneumJsonConfig(load): data types mismatch: j/t | %s/%s'):format(type(v[2]), orig_type))
					else
						target[k] = v[2]
					end
				end
			else
				print('CarboneumJsonConfig(load): weird shit happens..')
				-- target[k] = v -- if happens then user is stupid as piece of shit, or me (not me)
			end
		end
	end

	table_merge(table, jsonTable)
end

function carboneum.save(path, table)
	-- print(pathFixer(path))
	local file = io.open(pathFixer(path), 'w')

	local good = preptable2json(table)
	file:write(json.encode(good, { indent = true }))
	file:flush()
	file:close()
end

function configreset(path, table, original)
	local file = io.open(pathFixer(path), 'w')

	file:write(json.encode(original, { indent = true }))
	file:flush()
	file:close()

	carboneum.load(path, table, original)
end

return carboneum
