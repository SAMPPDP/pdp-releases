-- Tiny grok lib, made in logstash style, written by snus for internal usage.
-- Author: Snusmumriken | Mar 12th, 2023

local grok         = {}
grok.__index       = grok
grok._template     = '[%t%s]*(.-)%s+(.-)[\r\n]+' -- "WORD       %w+\n"
grok._templateword = '%$(%w+)'                   -- "USERNAME   $WORD"
grok._pair         = '%%{(.-):(.-)}'             -- "%{USERNAME:user}"
grok._word         = '%w+'                       -- "USERNAME"

function grok:new(text)
	self = setmetatable({}, self)
	self.patterns = {}
	-- TEST NEW MESSAGE!
	if text then self:addPatterns(text) end
	return self
end

function grok:addPatterns(text)
	local n = 0
	for key, pattern in text:gmatch(self._template) do
		self.patterns[key] = pattern
		n = n + 1
	end
	self.builded = false
	return self, n
end

function grok:build()
	while true do
		local stop = true
		for key, pattern in pairs(self.patterns) do
			local replaces
			-- USERNAME $WORD => USERNAME %w+
			self.patterns[key], replaces = pattern:gsub(self._templateword, self.patterns)
			if replaces > 0 then stop = false end
		end
		if stop then break end
	end
	self.builded = true

	function self._compiler(c)
		return self.patterns[c] and '(' .. self.patterns[c] .. ')' or c
	end

	return self
end

function grok:expand(pattern)
	if not self.builded then self:build() end
	local str      = pattern:gsub(self._pair, '%1')
	local template = str:gsub(self._word, self._compiler)
	return template
end

function grok:expandkey(pattern)
	return pattern:gsub(self._pair, '%2')
end

function grok:grok(text, pattern)
	if not self.builded then self:build() end

	local keys = {}
	for type, key in pattern:gmatch(self._pair) do
		keys[#keys + 1] = key
	end

	local template = self:expand(pattern)
	local values = { text:match(template) }
	local out = {}
	for i = 1, #keys do
		out[keys[i]] = values[i]
	end
	return out
end

function grok:format(data, pattern, verify)
	if not self.builded then self:build() end
	local succ, err = true, ''
	local function fmt(patt, key)
		if not succ then return '' end

		local datavalue = data[key]
		if not datavalue then
			succ, err = false, ('Key [%s] expected in datatable'):format(key)
			return ''
		end

		if verify then
			local expanded = self.patterns[patt]
			if not expanded then
				succ, err = false, ('Key [%s] is not found in datatable'):format(patt)
				return ''
			end
			if not datavalue:find('^' .. expanded .. '$') then
				succ, err = false,
					('Malformed data in \"%s\" (%s) field, pattern: [%s](%s)'):format(key, tostring(datavalue), patt,
						expanded)
				return ''
			end
		end

		return datavalue
	end

	local result = pattern:gsub(self._pair, fmt)
	return succ and result, not succ and err
end

return grok

-- local template = [[
--   INT     %+?%-?[0-9]+
--   NUMBER  %+?%-?[0-9]+%.?[0-9]*
--   HEX   %x+
--   HEX2  %x%x
--   HEX4  %x%x%x%x
--   HEX8  $HEX4$HEX4
--   HEX12 $HEX8$HEX4
--   HEX16 $HEX8$HEX8
--   WORD     %w+
--   SPACE    %s+
--   NOTSPACE %S+
--   DATA       .-
--   GREEDYDATA .*
--   QUOTEDSTRING %b""
--   USERNAME $WORD
--   DATE %d%d?[%./]%d%d?[%./]%d%d%d?%d?
--   TIME %d%d?:%d%d?:?%d?%d?:?%d*
--   UUID $HEX8%-$HEX4%-$HEX4%-$HEX4%-$HEX12
-- ]]


-- local g = grok:new(template)


-- local text    = "2 FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF Mario - Princess is in another castle"
-- local pattern = "%{INT:id} %{UUID:guid} %{USERNAME:username} %- %{GREEDYDATA:msg}"

-- local expanded = g:expand(pattern)
-- print(expanded)
-- --> "(%+?%-?[0-9]+) (%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x) (%w+) %- (.*)"

-- local parsed = g:grok(text, pattern)
-- for k, v in pairs(parsed) do
-- 	print(k, v)
-- end

-- --> id              2
-- --> guid            FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF
-- --> username        Mario
-- --> msg             Princess is in another castle

-- local data = g:format(parsed, pattern)
-- --> data = "2 FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF Mario - Princess is in another castle"
