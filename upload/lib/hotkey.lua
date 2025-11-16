---@meta
--[[

v.1.2

Encoding: UTF-8

За основу биндера был взят скрипт https://github.com/AnWuPP/rkeys

Обозначения:
	Hotkey — название модуля.
	Слово 'хоткей' — визуальная часть хоткея.
	Слово 'бинд' — программная часть хоткея

Импорт модуля:
	При импорте вызываем функцию init() из модуля Hotkey и передаем в параметры:
		[1] vkeys:
			Для работы с новыми кодами для колеса мыши.
			Будут добавлены дополнительные коды vkeys.VK_WHEELDOWN и vkeys.VK_WHEELUP.
		[2] imgui:
			Для работы с mimgui и для отрисовки кнопки хоткея

	Параметр imgui можно опустить, если нужно использовать этот модуль только в качестве биндера

	При локальном определении модулей:
	-- local vkeys = require 'vkeys'
	-- local imgui = require 'mimgui'
	-- local Hotkey = require 'hotkey'
	-- Hotkey.init(vkeys, imgui)

	При глобальном определении модулей:
	-- vkeys = require 'vkeys'
	-- imgui = require 'mimgui'
	-- local Hotkey = require 'hotkey'
	-- -- не надо писать Hotkey.init()

При редактировании хоткея:
	- Привязка учитывается после отпускания любой клавиши/кнопки;
	- Не допускается комбинация только из кнопки VK_LBUTTON (ЛКМ);
	- Не допускается комбинация только из клавиш модификации (VK_MENU, VK_SHIFT, VK_CONTROL и его подверсии)

Клавиши управления при редактировании хоткея:
	VK_BACK (Backspace):
		Убрать комбинации клавиш хоткея (оставить пустую таблицу)
	{VK_RETURN (Enter), VK_TAB, VK_F6, VK_F7, VK_F8, VK_T, VK_OEM_3 (знак ~)} и VK_ESCAPE:
		Клавиши для отмены редактирования (и оставить все как было)

Свойства модуля и их изначальные значения:
	Hotkey._status: boolean = true
		Определяет, будут ли выполняться действия биндов при нажатии на комбинации клавиш

	Hotkey.click_delay: integer = 375
		Задержка между быстрыми нажатиями (в миллисекундах)

	Hotkey.ignore_cancel_keys: boolean = false
		Определяет, игнорировать ли клавиши для отмены при редактировании хоткея (кроме VK_ESCAPE)

	Hotkey.empty_key_names: string = ""
		Текст хоткея при пустой таблице комб. клавиш

	Hotkey.nonexistent_hotkey: string = "Hotkey with ID [%d] does not exist!"
		Текст для форматированного вывода несуществующего бинда.
		Передается лишь проверяемый ID через string.format

	Hotkey: table = {}
		Сам модуль также является списком, где хранятся свойства всех текущих биндов.
		Получить или изменить свойство бинда:
			Hotkey[*id*].*свойство* = *значение*

Свойства биндов и их изначальные значения:
	keys: table [обязателен к заполнению]
		Комбинация клавиш

	action: function (id: integer) [обязателен к заполнению]
		Действие, выполняемое при нажатии на комб. клавиш.
		В параметры функции передается ID бинда, действие которого выполняется в данный момент.
		Лучше не менять это свойство в процессе его выполнения

	pressed: boolean = false [только для чтения]
		Состояние нажатия на комб. клавиш

	clicks: integer = 0
		Количество быстрых нажатий на комб. клавиш
	
	consume_flags: integer = Hotkey.ConsumeFlags.None
		Флаги для отключения передачи клавиш/кнопок после себя.
		Может иметь несколько режимов одновременно, включенные в таблицу Hotkey.ConsumeFlags:
			ConsumeFlags.None        - передавать всегда;
			ConsumeFlags.LastGame    - не передавать последнюю нажатую клавишу/кнопку игре;
			ConsumeFlags.LastScripts - не передавать последнюю нажатую клавишу/кнопку скриптам;
			ConsumeFlags.MouseVK     - отключать нажатую кнопку мышки бинда;
			ConsumeFlags.All         - отключать все нажатые клавиши/кнопки бинда (игнорирует остальные флаги);
	
	consume_condition: function(id: integer) -> boolean
		Условная функция, вызываемое и проверяемое перед отключением передачи клавиш/кнопок после себя.
		Передается ID бинда.
		Если вернет true, то будет выполнен consume клавиш/кнопок бинда в соответствии с указанными флагами

Далее, параметры функций выделенные как [параметр] можно опустить

Основные функции модуля:
	Hotkey.register(keys, action [, consume_flags] [, consume_condition]) -> id: integer
		Забиндить новую комбинацию клавиш.
		Если параметром `action` передать функцию `Hotkey.OnSetStatus`,
		то бинд будет играть роль переключателя состояния биндов (Hotkey._status),
		и будет выполняться независимо от `Hotkey._status`.
		Возвращает ID нового бинда

	Hotkey.unRegister(id)
		Убрать бинд по ID
	Примечание:
		При удалении бинда в списке Hotkey бинд приравняется к nil,
		создавая пустое место в списке.
		Так что если нужно пройтись по всем биндам, то рекомендуется использовать функцию Hotkey.getIds()

	Hotkey.Draw(id [, name] [, size]) -> edited: boolean
		Используется внутри `imgui.OnFrame`.
		Отображение хоткея в виде кнопки `imgui.Button`.
		При нажатии на кнопку начинается редактирование комб. клавиш хоткея.
		Параметр `name` определяет текст выводимый справа от хоткея.
		Параметр `size` определяет размеры кнопки хоткея.
		По-умолчанию размеры подстраиваются по содержанию комб. клавиш.
		Возвращает true, если хоткей только что был отредактирован
	Примечание:
		После редактирования хоткея новые комб. клавиш будут сохранены в свойстве `keys` бинда,
		которого можно получить и/или изменить:
			Hotkey[*id*].keys = {*комб. клавиш*}

	Hotkey.getEditing() -> id: integer|nil
		Возвращает ID бинда который редактируется на данный момент.
		В ином случае вернет nil
	
	Hotkey.getIds(comp) -> id_list: table
		Возвращает отсортированный таблицу-список с ID всех зарегистрированных биндов на данный момент.
		Если не указать функцию сортировки `comp`, то по-умолчанию сортирует по условию a < b

Дополнительные функции модуля:
	Hotkey.getAllMatches(keys) -> table|nil
		Возвращает список ID всех биндов, у которых совпадает комб. клавиш с таблицой `keys`.
		Порядок расположения клавиш неважен.
		Вернет nil если не нашлось ни одного

	Hotkey.getDownKeys([asList]) -> table
		Возвращает таблицу текущих нажатых клавиш/кнопок в виде:
			{..., [KEY_CODE] = true|nil, ...}
		Если `asList` == true, то вернет в виде списка:
			{..., *key_code*, ...}

	Hotkey.isOnlyKeyDown(key) -> boolean
		Возвращает true, если нажата ТОЛЬКО переданная клавиша/кнопка.
		Можно передать несколько клавиш сразу через таблицу

	Hotkey.getKeyNames(keys [, separator]) -> string|table
		Получить название клавиш/кнопок `keys` разделенным через `separator` в виде строки.
		Если `separator` не указан, то вернет названия в виде списка

	@Override
	Hotkey.OnDrawButton = function (keyNames: string, size: ImVec2)
		[Пере]Определяет функцию отрисовки кнопки хоткея.
		Будет использован последний отрисованный объект для проверки на нажатие
	
	@Override
	Hotkey.OnSetStatus = function (status: boolean, id: integer)
		[Пере]Определяет функцию вызываемую при переключении состояния биндов через другой бинд
]]

local vkeys = _G.vkeys or require 'vkeys'
local bitex = require 'bitex'
local bit = bit or require 'bit'
local ffi = require 'ffi'
local wm = require 'windows.message'
local imgui = _G.imgui

local M = {}

local messages = {
	[wm.WM_KEYDOWN] = true,
	[wm.WM_SYSKEYDOWN] = true,
	[wm.WM_KEYUP] = true,
	[wm.WM_SYSKEYUP] = true,
	[wm.WM_LBUTTONDOWN] = true,
	[wm.WM_LBUTTONDBLCLK] = true,
	[wm.WM_LBUTTONUP] = true,
	[wm.WM_RBUTTONDOWN] = true,
	[wm.WM_RBUTTONDBLCLK] = true,
	[wm.WM_RBUTTONUP] = true,
	[wm.WM_MBUTTONDOWN] = true,
	[wm.WM_MBUTTONDBLCLK] = true,
	[wm.WM_MBUTTONUP] = true,
	[wm.WM_XBUTTONDOWN] = true,
	[wm.WM_XBUTTONDBLCLK] = true,
	[wm.WM_XBUTTONUP] = true,
	[wm.WM_MOUSEWHEEL] = true,
}
local mouseLRMVK = {
	[wm.WM_LBUTTONDOWN] = vkeys.VK_LBUTTON,
	[wm.WM_LBUTTONUP] = vkeys.VK_LBUTTON,
	[wm.WM_RBUTTONDOWN] = vkeys.VK_RBUTTON,
	[wm.WM_RBUTTONUP] = vkeys.VK_RBUTTON,
	[wm.WM_MBUTTONDOWN] = vkeys.VK_MBUTTON,
	[wm.WM_MBUTTONUP] = vkeys.VK_MBUTTON,
}
local mouseXMessages = {
	[wm.WM_XBUTTONUP] = true,
	[wm.WM_XBUTTONDOWN] = true,
	[wm.WM_XBUTTONDBLCLK] = true,
}
local mouseXVKList = {
	vkeys.VK_XBUTTON1,
	vkeys.VK_XBUTTON2,
}
local downMessages = {
	[wm.WM_KEYDOWN] = true,
	[wm.WM_SYSKEYDOWN] = true,
	[wm.WM_LBUTTONDOWN] = true,
	[wm.WM_RBUTTONDOWN] = true,
	[wm.WM_MBUTTONDOWN] = true,
	[wm.WM_XBUTTONDOWN] = true,
	[wm.WM_LBUTTONDBLCLK] = true,
	[wm.WM_RBUTTONDBLCLK] = true,
	[wm.WM_MBUTTONDBLCLK] = true,
	[wm.WM_XBUTTONDBLCLK] = true,
	[wm.WM_MOUSEWHEEL] = true,
}
local exitKeys = {
	[vkeys.VK_RETURN] = true,
	[vkeys.VK_TAB] = true,
	[vkeys.VK_F6] = true,
	[vkeys.VK_F7] = true,
	[vkeys.VK_F8] = true,
	[vkeys.VK_T] = true,
	[vkeys.VK_OEM_3] = true,
}
local modKeys0 = {
	[vkeys.VK_SHIFT] = true,
	[vkeys.VK_MENU] = true,
	[vkeys.VK_CONTROL] = true,
}
local modKeys = {
	[vkeys.VK_SHIFT] = true,
	[vkeys.VK_LSHIFT] = true,
	[vkeys.VK_RSHIFT] = true,
	[vkeys.VK_MENU] = true,
	[vkeys.VK_LMENU] = true,
	[vkeys.VK_RMENU] = true,
	[vkeys.VK_CONTROL] = true,
	[vkeys.VK_LCONTROL] = true,
	[vkeys.VK_RCONTROL] = true,
}
local modKeyExtendKeys = {
	[vkeys.VK_SHIFT] = {
		vkeys.VK_LSHIFT,
		vkeys.VK_RSHIFT,
	},
	[vkeys.VK_MENU] = {
		vkeys.VK_LMENU,
		vkeys.VK_RMENU,
	},
	[vkeys.VK_CONTROL] = {
		vkeys.VK_LCONTROL,
		vkeys.VK_RCONTROL,
	},
}
local extendKeysModKey = {
	[vkeys.VK_LSHIFT] = vkeys.VK_SHIFT,
	[vkeys.VK_RSHIFT] = vkeys.VK_SHIFT,
	[vkeys.VK_LMENU] = vkeys.VK_MENU,
	[vkeys.VK_RMENU] = vkeys.VK_MENU,
	[vkeys.VK_LCONTROL] = vkeys.VK_CONTROL,
	[vkeys.VK_RCONTROL] = vkeys.VK_CONTROL,
}

local keysDown = {}
local clickThreads = {}
local consumingKey = nil

local editHotkey = nil
local endKeys = nil
local editStart = false

local function tlen(t)
	local len = 0
	for _, _ in pairs(t) do
		len = len + 1
	end
	return len
end

local function tcopy(t)
	local r = {}
	for k, v in pairs(t) do
		r[k] = v
	end
	return r
end

local function tconcat(t1, ...)
	local ts = { ... }
	for _, t2 in ipairs(ts) do
		for i = 1, #t2 do
			t1[#t1 + 1] = t2[i]
		end
	end
	return t1
end

local function tcontains(t, value)
	for _, v in pairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

local function tsame(t1, t2)
	if tlen(t1) ~= tlen(t2) then
		return false
	end
	for i, _ in pairs(t1) do
		if t2[i] == nil or t1[i] ~= t2[i] then
			return false
		end
	end
	return true
end

local function isExitKeyDown()
	for k, _ in pairs(exitKeys) do
		if keysDown[k] then
			return true
		end
	end
	return false
end

local function otzhatModKeyExtendKeys(key)
	if key == vkeys.VK_SHIFT then
		keysDown[vkeys.VK_LSHIFT] = nil
		keysDown[vkeys.VK_RSHIFT] = nil
	elseif key == vkeys.VK_MENU then
		keysDown[vkeys.VK_LMENU] = nil
		keysDown[vkeys.VK_RMENU] = nil
	elseif key == vkeys.VK_CONTROL then
		keysDown[vkeys.VK_LCONTROL] = nil
		keysDown[vkeys.VK_RCONTROL] = nil
	end
end

local function otzhat()
	for k, _ in pairs(keysDown) do
		if not isKeyDown(k) then
			keysDown[k] = nil
		end
	end
end

local function isOnlyModKeysDown()
	local empty = true
	for k, _ in pairs(keysDown) do
		empty = false
		if not modKeys[k] then
			return false
		end
	end
	return not empty
end

local function bandall(x)
	local xs = {}
	while x > 0 do
		table.insert(xs, bit.band(x, 1) ~= 0)
		x = bit.rshift(x, 1)
	end
	return xs -- 1011 = ttft
end

-- Инициализация нужных модулей
---@param _vkeys? vkeys
---@param _imgui? imgui
function M.init(_vkeys, _imgui)
	imgui = _imgui or imgui

	vkeys = _vkeys or vkeys
	vkeys.VK_WHEELDOWN = 0x100
	vkeys.VK_WHEELUP = 0x101
	vkeys.key_names[vkeys.VK_WHEELDOWN] = 'Mouse Wheel Down'
	vkeys.key_names[vkeys.VK_WHEELUP] = 'Mouse Wheel Up'
end

M.init()

-- Определяет состояние биндов. Если true, то действия биндов будут выполнены
M._status = true

-- Определяет задержку между быстрыми нажатиями (в миллисекундах)
M.click_delay = 375

-- Определяет игнорирование клавиш для отмены при редактировании хоткея (кроме `VK_ESCAPE`)
M.ignore_cancel_keys = false

-- Определяет текст хоткея при пустой таблице комб. клавиш
M.empty_key_names = ''

-- Текст для форматированного вывода несуществующего бинда. Передается лишь проверяемый ID через string.format
M.nonexistent_hotkey = 'Hotkey with ID [%d] does not exist!'

---@enum ConsumeFlags
---Флаги для отключения передачи клавиш/кнопок после себя
M.ConsumeFlags = {
	None = 0,
	LastGame = 1,   -- не передавать последнюю нажатую клавишу/кнопку игре
	LastScripts = 2, -- не передавать последнюю нажатую клавишу/кнопку скриптам
	MouseVK = 4,    -- отключать нажатую кнопку мышки бинда
	All = 8,        -- отключать все нажатые клавиши/кнопки бинда
}

-- Забиндить новую комбинацию клавиш/кнопок. Если параметром `action` передать функцию `Hotkey.OnSetStatus`, то бинд будет играть роль переключателя состояния биндов (`Hotkey._status`)
---@param keys table                                   Комбинация клавиш/кнопок
---@param action fun(id: integer)                      Функция-действие
---@param consume_flags? ConsumeFlags|integer          Флаги для отключения передачи клавиш/кнопок после себя. См. `Hotkey.ConsumeFlags`
---@param consume_condition? fun(id: integer):boolean  Условная функция, вызываемое и проверяемое перед отключением передачи клавиш/кнопок после себя
---@return integer|nil id                              Возвращает ID нового бинда
function M.register(keys, action, consume_flags, consume_condition)
	if keys and action then
		local id = #M + 1
		local bind = {
			keys = keys,
			action = action,
			pressed = false,
			clicks = 0,
			consume_flags = consume_flags or 0,
			consume_condition = consume_condition or function() return true end,
		}
		M[id] = bind

		clickThreads[id] = lua_thread.create_suspended(function()
			wait(M.click_delay)
			bind.clicks = 0
		end)

		return id
	end
end

-- Убрать бинд по ID
---@param id integer
function M.unRegister(id)
	if type(id) == 'number' and M[id] then
		if ({ yielded = 1, running = 1 })[clickThreads[id]:status()] then
			clickThreads[id]:terminate()
		end
		clickThreads[id] = nil
		M[id] = nil
	end
end

-- Отобразить хоткей в виде кнопки `imgui.Button`. Используется внутри `imgui.OnDrawFrame`
---@param id integer
---@param name? string			Если не nil, отобразить хоткей с названием `name`
---@param size? ImVec2			Размер кнопки хоткея. По-умолчанию подстраивается по содержанию комб. клавиш.
---@return boolean|nil edited	Возвращает true, если хоткей только что был отредактирован
function M.Draw(id, name, size)
	if type(id) == 'number' and M[id] then
		local width = 40
		local height = 20
		local keyNames = nil
		local edited = false

		if editHotkey == id then
			if keysDown[vkeys.VK_BACK] then
				edited = true
				M[id].keys = {}
				editHotkey = nil
			elseif (not M.ignore_cancel_keys and isExitKeyDown()) or keysDown[vkeys.VK_ESCAPE] then
				editHotkey = nil
			elseif endKeys then
				endKeys[vkeys.VK_SHIFT] = nil
				endKeys[vkeys.VK_MENU] = nil
				endKeys[vkeys.VK_CONTROL] = nil

				local keys1, keys2, keys3 = {}, {}, {}
				for k, _ in pairs(endKeys) do
					if modKeys[k] then
						table.insert(keys1, k)
					elseif k == vkeys.VK_WHEELDOWN or k == vkeys.VK_WHEELUP then
						table.insert(keys3, k)
					else
						table.insert(keys2, k)
					end
				end
				table.sort(keys2, function(a, b)
					return #tostring(vkeys.id_to_name(a)) > #tostring(vkeys.id_to_name(b))
				end)

				tconcat(keys1, keys2, keys3)

				if not (#keys1 == 1 and keys1[1] == vkeys.VK_LBUTTON) then
					M[id].keys = keys1
					edited = true
				end

				endKeys = nil
				editHotkey = nil
			else
				keyNames = '...'
			end
		end
		keyNames = (keyNames or (#M[id].keys > 0 and M.getKeyNames(M[id].keys, ' + ')) or M.empty_key_names)
		local calcWidth = imgui.CalcTextSize(keyNames).x + 8
		if size then
			if size.x == 0 then
				width = math.max(width, calcWidth)
			else
				width = size.x
			end
			if size.y ~= 0 then
				height = size.y
			end
		else
			width = math.max(width, calcWidth)
		end

		M.OnDrawButton(keyNames, imgui.ImVec2(width, height))

		if imgui.IsItemHovered() and imgui.IsItemClicked() and not editHotkey then
			editHotkey = id
			editStart = true
			for i, _ in pairs(M) do
				if type(i) == 'number' then
					M[i].pressed = false
				end
			end
		end

		if name and name ~= '' then
			name = tostring(name)
			imgui.SameLine()
			imgui.Text(name)
		end

		return edited
	else
		imgui.Text(M.nonexistent_hotkey:format(id))

		return nil
	end
end

-- Возвращает ID бинда который редактируется на данный момент
---@return integer|nil
function M.getEditing()
	return editHotkey
end

---Возвращает отсортированную таблицу-список, содержащий ID всех зарегистрированных биндов на данный момент
---@param comp? fun(a: integer, b: integer):boolean Функция сортировки. Условие по-умолчанию: `a < b`
---@return table id_list
function M.getIds(comp)
	comp = comp or function(a, b)
		return a < b
	end
	local id_list = {}
	for id, _ in pairs(M) do
		if type(id) == 'number' then
			table.insert(id_list, id)
		end
	end
	table.sort(id_list, comp)
	return id_list
end

---Возвращает список ID всех биндов, у которых совпадает комб. клавиш с таблицой `keys`. Порядок клавиш/кнопок неважен
---@param keys table
---@return table|nil id_list	Вернет nil если не нашлось ни одного
function M.getAllMatches(keys)
	local binds = {}
	if #keys > 0 then
		for id, _ in pairs(M) do
			if type(id) == 'number' then
				local bool = true
				for _, vk in ipairs(keys) do
					if not tcontains(M[id].keys, vk) then
						bool = false
						break
					end
				end
				if bool then
					table.insert(binds, id)
				end
			end
		end
	end

	return #binds > 0 and binds or nil
end

-- Получить таблицу нажатых клавиш/кнопок. Проверить нажата ли клавиша/кнопка можно через: Hotkey.getDownKeys()[*key_code*] == true|nil
---@param asList? boolean	Если true, то вернет значение в виде списка: {..., *key_code*, ...}
---@return table keysDown
function M.getDownKeys(asList)
	local res = {}
	if asList then
		for k, _ in pairs(keysDown) do
			table.insert(res, k)
		end
	else
		res = tcopy(keysDown)
	end
	return res
end

--- Возвращает true, если нажата ТОЛЬКО переданная клавиша/кнопка
---@param key integer|table Можно передать несколько клавиш сразу через таблицу
---@return boolean
function M.isOnlyKeyDown(key)
	local len = tlen(keysDown)
	if len == 0 then
		return false
	end
	if type(key) == 'table' then
		local down = {}

		for _, k in ipairs(key) do
			down[k] = true
			local ekmk = extendKeysModKey[k]
			if modKeys0[k] then
				for _, ek in ipairs(modKeyExtendKeys[k]) do
					if keysDown[ek] then
						down[ek] = true
					end
				end
			elseif ekmk then
				down[ekmk] = true
			end
		end

		return tsame(down, keysDown)
	else
		return keysDown[key] and (len == 1 or modKeys[key] and len == 2) or false
	end
end

-- Получить название клавиш/кнопок `keys` разделенным через `separator` в виде строки. Если `separator == nil`, то вернет названия в виде списка
---@param keys table
---@param separator? string
---@return string|table keyNames
function M.getKeyNames(keys, separator)
	local keyNames = ''
	local nameList = {}
	for _, vk in ipairs(keys) do
		if not separator then
			table.insert(nameList, tostring(vkeys.id_to_name(vk)))
		else
			keyNames = keyNames .. (keyNames ~= '' and separator or '') .. tostring(vkeys.id_to_name(vk))
		end
	end
	return separator and keyNames or nameList
end

-- `@Override` функция для переопределения функции отрисовки кнопки. Будет использован последний отрисованный объект для проверки на нажатие
---@param keyNames string	Название комб. клавиш
---@param size ImVec2		Размер кнопки
function M.OnDrawButton(keyNames, size)
	imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.5, 0.5))
	imgui.Button(keyNames, size)
	imgui.PopStyleVar()
end

-- `@Override` функция для переопределения функции вызываемую при переключении состояния биндов через другой бинд
---@param status boolean текущее состояние биндов
---@param id integer ID бинда который переключил состояние биндов
function M.OnSetStatus(status, id)
	print(('Hotkeys have been %s'):format(status and '{00ff00}enabled' or '{ff0000}disabled'))
	print(('Toggled by hotkey with [id: %d]'):format(id))
end

addEventHandler('onWindowMessage', function(msg, key, lparam)
	if messages[msg] then
		local scancode = bitex.bextract(lparam, 16, 8)
		local keystate = bitex.bextract(lparam, 30, 1)
		local extend = bitex.bextract(lparam, 24, 1)
		local exkey = (key == vkeys.VK_MENU and (extend == 1 and vkeys.VK_RMENU or vkeys.VK_LMENU))
			or (key == vkeys.VK_SHIFT and (scancode == 42 and vkeys.VK_LSHIFT or scancode == 54 and vkeys.VK_RSHIFT))
			or (key == vkeys.VK_CONTROL and (extend == 1 and vkeys.VK_RCONTROL or vkeys.VK_LCONTROL))
			or nil

		key = mouseLRMVK[msg] or key
		if mouseXMessages[msg] then
			key = mouseXVKList[bit.rshift(bit.band(key, 0xffff0000), 16)]
		elseif msg == wm.WM_MOUSEWHEEL then
			local delta = bit.rshift(tonumber(ffi.cast('int32_t', key)), 16)
			if delta >= 0x8000 then delta = delta - 0xffff end
			if delta < 0 then
				key = vkeys.VK_WHEELDOWN
			elseif delta > 0 then
				key = vkeys.VK_WHEELUP
			end
		end

		if downMessages[msg] then
			if not keysDown[key] and keystate == 0 then
				keysDown[key] = true
				if exkey then
					keysDown[exkey] = true
				end
				if editStart then
					editStart = false
				end
			end

			if not editHotkey then
				if consumingKey and key == consumingKey.key and consumingKey.condition(consumingKey.id) then
					consumeWindowMessage(consumingKey.game, consumingKey.scripts)
				else
					consumingKey = nil
				end
				local statusChanged
				for id, _ in pairs(M) do
					if type(id) == 'number' then
						if M._status or ((not statusChanged) and M[id].action == M.OnSetStatus) then
							if #M[id].keys > 0 then
								local down = true

								for _, vk in ipairs(M[id].keys) do
									if not keysDown[vk] then
										down = false
										break
									end
								end

								if down then
									if not M[id].pressed then
										M[id].pressed = msg ~= wm.WM_MOUSEWHEEL
										if M[id].action == M.OnSetStatus then
											statusChanged = id
											break
										else
											clickThreads[id]:terminate()
											M[id].clicks = M[id].clicks + 1
											clickThreads[id]:run()
											lua_thread.create(M[id].action, id)
										end
									end

									local flags = bandall(M[id].consume_flags)
									if #flags > 0 then
										local game, scripts, mouse, all = unpack(flags)

										consumingKey = { key = key, game = game, scripts = scripts, condition = M[id].consume_condition, id = id }
										if consumingKey.condition(consumingKey.id) then
											consumeWindowMessage(game, scripts)
											if (mouseLRMVK[msg] or mouseXMessages[msg]) and mouse then
												setVirtualKeyDown(key, false)
											end
											if all then
												for _, vk in ipairs(M[id].keys) do
													setVirtualKeyDown(vk, false)
												end
											end
										end
									end
								end
							end
						end
					end
				end
				if statusChanged then
					M._status = not M._status
					lua_thread.create(M.OnSetStatus, M._status, statusChanged)
				end
			end

			if msg == wm.WM_MOUSEWHEEL then
				if editHotkey then
					endKeys = tcopy(keysDown)
				end

				keysDown[key] = nil
			end

			if ((not consumingKey) or consumingKey.key ~= key) and editHotkey and (exitKeys[key] or key == vkeys.VK_ESCAPE) then
				consumeWindowMessage(true, M.ignore_cancel_keys and exitKeys[key] or false)
			end
		else
			if keysDown[key] then
				if editStart and key == vkeys.VK_LBUTTON then
					editStart = false
				elseif (key ~= vkeys.VK_LBUTTON or ((not editStart) and (not M.isOnlyKeyDown(vkeys.VK_LBUTTON))))
					and editHotkey and (M.ignore_cancel_keys or not exitKeys[key]) and key ~= vkeys.VK_ESCAPE
					and not isOnlyModKeysDown()
				then
					endKeys = tcopy(keysDown)
				end

				keysDown[key] = nil
				otzhatModKeyExtendKeys(key)
			end
			if consumingKey and key == consumingKey.key and consumingKey.condition(consumingKey.id) then
				consumeWindowMessage(consumingKey.game, consumingKey.scripts)
				consumingKey = nil
			end
			local statusChangerFound = false
			for id, _ in pairs(M) do
				if type(id) == 'number' then
					if M[id].pressed then
						if editHotkey or (not M._status) and (M[id].action ~= M.OnSetStatus or statusChangerFound) then
							M[id].pressed = false
						else
							if M[id].action == M.OnSetStatus then
								statusChangerFound = true
							end
							for _, vk in ipairs(M[id].keys) do
								if vk == key then
									M[id].pressed = false
									break
								end
							end
						end
					end
				end
			end
			otzhat()
		end
	elseif msg == wm.WM_KILLFOCUS then
		keysDown = {}
	end
end)

return M
