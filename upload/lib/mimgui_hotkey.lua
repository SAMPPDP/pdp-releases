--[[
    Хоткеи для moonloader 027-026
    author - dmitry.karle
    vk - https://vk.com/dmitry.karle
    tg - @dmitrykarle
    edited by kyrtion 2025-10-26
]]

local vk = require('vkeys')
local imgui = require('mimgui')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local hotkey = {
    Text = {
        WaitForKey = '.  .  .',
        NoKey = u8 'Не задано'
    },
    List = {},
    ActiveKeys = {},
    isAnyFocused = false,
    ReturnHotKeys = nil,
    HotKeyIsEdit = nil,
    CancelKey = vk.VK_ESCAPE,
    RemoveKey = vk.VK_BACK,
    special_keys = {
        vk.VK_SHIFT,
        vk.VK_CONTROL,
        vk.VK_MENU, -- ALT
        vk.VK_LWIN,
        vk.VK_RWIN,
        vk.VK_XBUTTON1,
        vk.VK_XBUTTON2
    }
}

-- Вспомогательные функции для таблиц
local function tableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

local function tableIndexOf(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then return i end
    end
end

local function isArray(t)
    if type(t) ~= 'table' then return false end
    local count = 0
    for k, _ in pairs(t) do
        if type(k) ~= 'number' then return false end
        count = count + 1
    end
    return #t == count
end

local function jsonEncode(tbl)
    local function encodeValue(val)
        if type(val) == 'string' then
            return string.format('%q', val)
        elseif type(val) == 'number' then
            return tostring(val)
        elseif type(val) == 'boolean' then
            return val and 'true' or 'false'
        elseif type(val) == 'table' then
            return jsonEncode(val)
        else
            return 'null'
        end
    end

    if isArray(tbl) then
        local items = {}
        for _, v in ipairs(tbl) do
            table.insert(items, encodeValue(v))
        end
        return '[' .. table.concat(items, ',') .. ']'
    else -- Объект
        local items = {}
        for k, v in pairs(tbl) do
            if type(k) == 'number' then
                table.insert(items, encodeValue(v))
            else
                table.insert(items, string.format('%q:%s', tostring(k), encodeValue(v)))
            end
        end
        return '{' .. table.concat(items, ',') .. '}'
    end
end

local function jsonDecode(str)
    local pos = 1
    local function skipWhitespace()
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c == ' ' or c == '\t' or c == '\n' or c == '\r' then
                pos = pos + 1
            else
                break
            end
        end
    end
    local parse = {}
    parse.object = function()
        local obj = {}
        pos = pos + 1
        while true do
            skipWhitespace()
            if str:sub(pos, pos) == '}' then
                pos = pos + 1
                break
            end
            local key = parse.string()
            skipWhitespace()
            if str:sub(pos, pos) ~= ':' then
                sampAddChatMessage("Expected ':' at position " .. pos, -1)
            end
            pos = pos + 1
            local val = parse.value()
            obj[key] = val
            skipWhitespace()
            if str:sub(pos, pos) == ',' then
                pos = pos + 1
            elseif str:sub(pos, pos) == '}' then
            else
                sampAddChatMessage("Expected ',' or '}' at position " .. pos, -1)
            end
        end
        return obj
    end
    parse.array = function()
        local arr = {}
        pos = pos + 1
        while true do
            skipWhitespace()
            if str:sub(pos, pos) == ']' then
                pos = pos + 1
                break
            end
            local val = parse.value()
            table.insert(arr, val)
            skipWhitespace()
            if str:sub(pos, pos) == ',' then
                pos = pos + 1
            elseif str:sub(pos, pos) == ']' then
                -- will be handled in next iteration
            else
                sampAddChatMessage("Expected ',' or ']' at position " .. pos, -1)
            end
        end
        return arr
    end
    parse.string = function()
        pos = pos + 1
        -- local start = pos
        local result = ''
        local escaping = false
        while pos <= #str do
            local c = str:sub(pos, pos)
            if escaping then
                if c == '"' then
                    result = result .. '"'
                elseif c == '\\' then
                    result = result .. '\\'
                elseif c == '/' then
                    result = result .. '/'
                elseif c == 'b' then
                    result = result .. '\b'
                elseif c == 'f' then
                    result = result .. '\f'
                elseif c == 'n' then
                    result = result .. '\n'
                elseif c == 'r' then
                    result = result .. '\r'
                elseif c == 't' then
                    result = result .. '\t'
                else
                    result = result .. c
                end
                escaping = false
            elseif c == '\\' then
                escaping = true
            elseif c == '"' then
                pos = pos + 1
                return result
            else
                result = result .. c
            end
            pos = pos + 1
        end
        sampAddChatMessage('Unterminated string', -1)
    end
    parse.number = function()
        local start = pos
        while pos <= #str do
            local c = str:sub(pos, pos)
            if not (c:match('[0-9]') or c == '.' or c == '-' or c == '+' or c == 'e' or c == 'E') then
                break
            end
            pos = pos + 1
        end
        local num_str = str:sub(start, pos - 1)
        local num = tonumber(num_str)
        if not num then
            sampAddChatMessage('Invalid number at position ' .. start, -1)
        end
        return num
    end
    parse.boolean = function()
        if str:sub(pos, pos + 3) == 'true' then
            pos = pos + 4
            return true
        elseif str:sub(pos, pos + 4) == 'false' then
            pos = pos + 5
            return false
        else
            sampAddChatMessage('Invalid boolean at position ' .. pos, -1)
        end
    end
    parse.null = function()
        if str:sub(pos, pos + 3) == 'null' then
            pos = pos + 4
            return nil
        else
            sampAddChatMessage('Invalid null at position ' .. pos, -1)
        end
    end
    parse.value = function()
        skipWhitespace()
        local c = str:sub(pos, pos)
        if c == '{' then
            return parse.object()
        elseif c == '[' then
            return parse.array()
        elseif c == '"' then
            return parse.string()
        elseif c == 't' or c == 'f' then
            return parse.boolean()
        elseif c == 'n' then
            return parse.null()
        else
            return parse.number()
        end
    end
    local ok, result = pcall(function() return parse.value() end)
    if ok then
        return result
    else
        return nil, result
    end
end

function hotkey.StringToKeys(input)
    if type(input) == 'table' then return input end
    if type(input) == 'number' then return { input } end
    if type(input) ~= 'string' or input == '' then return {} end
    local result = {}
    for key in input:gmatch('([^,]+)') do
        table.insert(result, tonumber(key))
    end
    return result
end

function hotkey.KeysToString(input)
    if type(input) ~= 'table' then return '' end
    local result = {}
    for _, key in ipairs(input) do
        if type(key) == 'number' then
            table.insert(result, tostring(key))
        end
    end
    return table.concat(result, ',')
end

function hotkey.SerializeKeys(keys)
    if type(keys) ~= 'table' then return '[]' end
    return jsonEncode(keys)
end

function hotkey.DeserializeKeys(keys_str)
    local ok, result = pcall(jsonDecode, keys_str or '[]')
    return ok and type(result) == 'table' and result or {}
end

function hotkey.DeepCopy(orig)
    if type(orig) ~= 'table' then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[hotkey.DeepCopy(k)] = hotkey.DeepCopy(v)
    end
    return setmetatable(copy, getmetatable(orig))
end

-- Проверка на специальную клавишу
function hotkey.KeyIsSpecial(key)
    for _, v in ipairs(hotkey.special_keys) do
        if v == key then return true end
    end
    return false
end

function hotkey.GetKeysText(name)
    if not hotkey.List[name] or type(hotkey.List[name].keys) ~= 'table' then
        return ''
    end
    local keys_text = {}
    for i = 1, #hotkey.List[name].keys do
        local key_code = hotkey.List[name].keys[i]
        if type(key_code) == 'number' then
            local key_name = vk.id_to_name(key_code)
            if key_name then
                table.insert(keys_text, key_name)
            end
        end
    end
    return #keys_text > 0 and table.concat(keys_text, ' + ') or ''
end

-- Поиск и активация хоткея
function hotkey.SearchHotKey(keys)
    if type(keys) ~= 'table' or #keys == 0 then
        return
    end
    local sorted_keys = {}
    for i = 1, #keys do
        if type(keys[i]) == 'number' then
            table.insert(sorted_keys, keys[i])
        end
    end
    if #sorted_keys == 0 then return end
    table.sort(sorted_keys)
    local combo = table.concat(sorted_keys, ':')
    for _, data in pairs(hotkey.List) do
        if type(data) == 'table' and type(data.keys) == 'table' and #data.keys > 0 then
            local found_sorted = {}
            for i = 1, #data.keys do
                if type(data.keys[i]) == 'number' then
                    table.insert(found_sorted, data.keys[i])
                end
            end
            if #found_sorted > 0 then
                table.sort(found_sorted)
                if table.concat(found_sorted, ':') == combo then
                    if type(data.callback) == 'function' then
                        data.callback()
                    end
                    break
                end
            end
        end
    end
end

function hotkey.GetHotKey(name)
    if hotkey.List[name] then
        local keys_copy = {}
        for _, v in ipairs(hotkey.List[name].keys) do
            if type(v) == 'number' then
                table.insert(keys_copy, v)
            end
        end
        return keys_copy
    end
    return nil
end

local HotKeyObject = {
    __index = {
        Draw = function(self, size_button)
            return hotkey.Draw(self.name, size_button)
        end,
        EditHotKey = function(self, keys)
            if not keys then return false end
            hotkey.List[self.name].keys = keys
            return true
        end,
        RemoveHotKey = function(self)
            hotkey.List[self.name] = nil
            return true
        end,
        GetHotKey = function(self)
            return hotkey.List[self.name] and hotkey.List[self.name].keys or nil
        end
    }
}

-- Регистрация нового хоткея
function hotkey.RegisterHotKey(name, first_key, keys, callback)
    local key_table = type(keys) == 'string' and hotkey.DeserializeKeys(keys) or type(keys) == 'table' and keys or {}
    if not hotkey.List[name] then
        hotkey.List[name] = {
            first_key = first_key or false,
            keys = key_table,
            callback = callback
        }
        return setmetatable({ name = name }, HotKeyObject)
    end
    return nil
end

-- TODO: Переделывать, добавить аргумент название хоткей (как текст)
-- Отображения кнопки хоткея
function hotkey.Draw(name, size_button)
    local dl = imgui.GetWindowDrawList()
    local style = imgui.GetStyle()
    local colors = style.Colors
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 4)
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(8, 4))
    if not hotkey.List[name] then
        local pos = imgui.GetCursorScreenPos()
        local rect_min = pos
        local rect_max = imgui.ImVec2(pos.x + size_button.x, pos.y + size_button.y)
        dl:AddRectFilled(rect_min, rect_max, imgui.GetColorU32(colors[imgui.Col.FrameBg]), 4) -- Фон и текст
        local text = 'Хоткей не найден'
        local text_size = imgui.CalcTextSize(text)
        local text_pos = imgui.ImVec2(pos.x + (size_button.x - text_size.x) * 0.5, pos.y + (size_button.y - text_size.y) * 0.5)
        dl:AddText(text_pos, imgui.GetColorU32(colors[imgui.Col.Button]), text)
        imgui.InvisibleButton(('##missing_hk_%s'):format(name), size_button)
        imgui.PopStyleVar(2)
        return false
    end
    local is_editing = hotkey.HotKeyIsEdit and hotkey.HotKeyIsEdit.NameHotKey == name
    local HotKeyText = #hotkey.List[name].keys == 0 and (is_editing and hotkey.Text.WaitForKey or hotkey.Text.NoKey) or hotkey.GetKeysText(name)
    local pos = imgui.GetCursorScreenPos()
    local rect_min = pos
    local rect_max = imgui.ImVec2(pos.x + size_button.x, pos.y + size_button.y)
    local is_hovered = imgui.IsMouseHoveringRect(rect_min, rect_max, false)
    local bg_color, text_color
    if is_editing then
        bg_color = imgui.ImVec4(colors[imgui.Col.ButtonActive].x, colors[imgui.Col.ButtonActive].y, colors[imgui.Col.ButtonActive].z, colors[imgui.Col.ButtonActive].w * 0.40)
        text_color = colors[imgui.Col.Text]
    elseif #hotkey.List[name].keys == 0 then
        -- Не назначен
        bg_color = imgui.ImVec4(
            colors[imgui.Col.ButtonActive].x * 0.5,
            colors[imgui.Col.ButtonActive].y * 0.5,
            colors[imgui.Col.ButtonActive].z * 0.5,
            colors[imgui.Col.ButtonActive].w * 0.5
        )
        text_color = colors[imgui.Col.Text]
    else
        -- Назначен
        bg_color = imgui.ImVec4(colors[imgui.Col.ButtonHovered].x, colors[imgui.Col.ButtonHovered].y, colors[imgui.Col.ButtonHovered].z, colors[imgui.Col.ButtonHovered].w * 0.8)
        text_color = colors[imgui.Col.Text]
    end
    if is_hovered then
        -- Эффект при наведении
        bg_color.w = bg_color.w + 0.15 -- Увеличиваем прозрачность
        if not is_editing then
            text_color = colors[imgui.Col.Text]
        end
    end
    dl:AddRectFilled(rect_min, rect_max, imgui.GetColorU32Vec4(bg_color), 4) -- Отрисовка фона
    local text_size = imgui.CalcTextSize(HotKeyText)                         -- Отрисовка текста
    local text_pos = imgui.ImVec2(pos.x + (size_button.x - text_size.x) * 0.5, pos.y + (size_button.y - text_size.y) * 0.5)
    dl:AddText(text_pos, imgui.GetColorU32Vec4(text_color), HotKeyText)
    local ImButton = imgui.InvisibleButton('##button-hotkey-' .. name, size_button) -- Взаимодействие
    if is_editing then
        imgui.BeginTooltip()
        imgui.Text(u8 ' Нажмите нужную клавишу \n * ESC - отменить\n * Backspace - удалить')
        imgui.EndTooltip()
    end
    if ImButton then -- Обработка клика
        hotkey.isAnyFocused = true
        hotkey.HotKeyIsEdit = {
            NameHotKey = name,
            BackupHotKeyKeys = hotkey.DeepCopy(hotkey.List[name].keys),
            ActiveKeys = {}
        }
        hotkey.ActiveKeys = {}
        hotkey.List[name].keys = {}
    end
    imgui.PopStyleVar(2)
    if hotkey.ReturnHotKeys == name then
        hotkey.ReturnHotKeys = nil
        return true
    end
    return false
end

addEventHandler('onWindowMessage', function(msg, key)
    if msg == 0x0008 then
        hotkey.ActiveKeys = {}
    elseif msg == 0x0100 or msg == 0x0104 then
        if hotkey.HotKeyIsEdit then
            if key == hotkey.CancelKey then
                hotkey.List[hotkey.HotKeyIsEdit.NameHotKey].keys = hotkey.HotKeyIsEdit.BackupHotKeyKeys
                hotkey.HotKeyIsEdit = nil
            elseif key == hotkey.RemoveKey then
                hotkey.List[hotkey.HotKeyIsEdit.NameHotKey].keys = {}
                hotkey.ReturnHotKeys = hotkey.HotKeyIsEdit.NameHotKey
                hotkey.HotKeyIsEdit = nil
            elseif key ~= vk.VK_ESCAPE and key ~= vk.VK_BACK then
                local keys = hotkey.HotKeyIsEdit.ActiveKeys
                if not tableContains(keys, key) then
                    if hotkey.KeyIsSpecial(key) then
                        if not hotkey.List[hotkey.HotKeyIsEdit.NameHotKey].first_key then
                            table.insert(keys, key)
                            table.sort(keys)
                            hotkey.List[hotkey.HotKeyIsEdit.NameHotKey].keys = keys
                        end
                    else
                        table.insert(hotkey.List[hotkey.HotKeyIsEdit.NameHotKey].keys, key)
                        hotkey.ReturnHotKeys = hotkey.HotKeyIsEdit.NameHotKey
                        hotkey.HotKeyIsEdit = nil
                    end
                end
            end
            consumeWindowMessage(true, true)
        else
            if not tableContains(hotkey.ActiveKeys, key) and key ~= hotkey.CancelKey and key ~= hotkey.RemoveKey then
                table.insert(hotkey.ActiveKeys, key)
                if not hotkey.KeyIsSpecial(key) then
                    hotkey.SearchHotKey(hotkey.ActiveKeys)
                    table.remove(hotkey.ActiveKeys)
                end
            end
        end
    elseif msg == 0x0101 or msg == 0x0105 then
        if not hotkey.HotKeyIsEdit then
            hotkey.isAnyFocused = false
        end
        if hotkey.KeyIsSpecial(key) then
            local keys = hotkey.HotKeyIsEdit and hotkey.HotKeyIsEdit.ActiveKeys or hotkey.ActiveKeys
            table.remove(keys, tableIndexOf(keys, key))
        end
    end
end)

return hotkey
