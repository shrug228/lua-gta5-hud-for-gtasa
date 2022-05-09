script_author('shrug228')
script_name('gta5-hud')
require('lib.moonloader')

local memory = require('memory')

local imgui = require('imgui')
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8

local window = imgui.ImBool(false)
imgui.Process = false

local cfg, textures, hold = {}, {}, {} -- чтобы все было нормально с областью видимости
local path = getGameDirectory() .. '\\moonloader\\config\\gta5-hud.json' -- путь до конфига

local editMode, showChat = false, false

function main()
	repeat wait(100) until memory.read(0xC8D4C0, 4, false) ==   9
	lua_thread.create(function ()
		repeat wait(200) until isSampAvailable()
		sampRegisterChatCommand('gta5-hud', function () window.v = not window.v end)
		sampAddChatMessage('[GTA5-HUD] {ffffff}Загружен и вроде как работает, автор: {00ff00}shrug228{ffffff}. Версия: {00ff00}v1.0', 0xff00ff00)
		while true do
			showChat = sampGetChatDisplayMode() ~= 0
			wait(0)
		end
	end)

	displayHud(false)

	if doesFileExist(path) then
		cfg = jsonRead(path)
	else
		cfg = {
			['colors'] = {
				['bd'] = '000000',
				['mlower'] = '{ff6347}',
				['mhigher'] = '{90ee90}',
				['money'] = '{ffffff}',
				['arm'] = '1e90ff',
				['nohp'] = '2e8b57',
				['clip'] = '{909090}', -- текущий магазин
				['ammo'] = '{505050}', -- остальной боезапас
				['nost'] = 'ffe77a', -- нет стамины/воздуха в воде
				['noarm'] = '6495ed',
				['accent'] = 'f4c800', -- акцент для селектора оружия
				['stamina'] = 'f4c800',
				['hp'] = '3cb371'
			},
			['pos'] = {
				['gy'] = 15,		-- g - gun icon (отступ от правого верхнего угла)
				['rx'] = 100,		-- r - radar
				['gx'] = 15,		-- h - hud
				['hy'] = 300,
				['ry'] = 100,
				['hfixed'] = true,
				['hx'] = 15,
				['top'] = false
			},
			['size'] = {
				['bd'] = 7,
				['hh'] = 30,
				['gw'] = 210,
				['rh'] = 100,
				['rw'] = 100,
				['hw'] = 100
			}
		}
		jsonSave(path, cfg)
	end

	local rx, ry = convertWindowScreenCoordsToGameScreenCoords(cfg['pos']['rx'], cfg['pos']['ry'])
	local rw, rh = convertWindowScreenCoordsToGameScreenCoords(cfg['size']['rw'], cfg['size']['rh'])

	textures.star = imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\gta5-hud\\star.png')
	
	imgui.Process = true

	while true do
		imgui.ShowCursor, imgui.LockPlayer = window.v, window.v

		if isLocalPlayerSpawned() and showChat then
			local x, y = cfg['pos']['hx'], cfg['pos']['hy']
			local sx = cfg['size']['hw']
			if cfg['pos']['hfixed'] then
				x, y = cfg['pos']['rx'], cfg['pos']['ry'] + cfg['size']['rh']
				sx = cfg['size']['rw']
				if cfg['pos']['top'] then
					y = cfg['pos']['ry'] - cfg['size']['hh']
				end
			end

			-- обводка
			renderDrawBox(x, y, sx, cfg['size']['hh'] / 3, '0xff' .. cfg['colors']['bd'])
			renderDrawBox(x, y + cfg['size']['hh'] / 3 * 2, sx, cfg['size']['hh'] / 3, '0xff' .. cfg['colors']['bd'])
			renderDrawBox(x + sx / 21 * 10, y + cfg['size']['hh'] / 3, sx / 21, cfg['size']['hh'] / 3, '0xff' .. cfg['colors']['bd'])
			-- hp
			renderDrawBox(x, y + cfg['size']['hh'] / 3, sx / 21 * 10 / 100 * getCharHealth(PLAYER_PED), cfg['size']['hh'] / 3, '0xff' .. cfg['colors']['hp'])
			renderDrawBox(x + sx / 21 * 10 / 100 * getCharHealth(PLAYER_PED), y + cfg['size']['hh'] / 3, sx / 21 * 10 / 100 * (100 - getCharHealth(PLAYER_PED)), cfg['size']['hh'] / 3, '0xff' .. cfg['colors']['nohp'])
			-- armour
			renderDrawBox(x + sx / 21 * 11, y + cfg['size']['hh'] / 3, sx / 21 * 10 / 100 * getCharArmour(PLAYER_PED), cfg['size']['hh'] / 3, '0xff' .. cfg['colors']['arm'])
			renderDrawBox(x + sx / 21 * 11 + sx / 21 * 10 / 100 * getCharArmour(PLAYER_PED), y + cfg['size']['hh'] / 3, sx / 21 * 10 / 100 * (100 - getCharArmour(PLAYER_PED)), cfg['size']['hh'] / 3, '0xff' .. cfg['colors']['noarm'])
		
			renderDrawBox(cfg['pos']['rx'], cfg['pos']['ry'], cfg['size']['rw'], cfg['size']['rh'], 0x99000000)
		end

		wait(0)
	end
end

function onScriptTerminate()
	jsonSave(path, cfg)
end

function imgui.OnDrawFrame()
	if isLocalPlayerSpawned() and showChat then
		if editMode then
			imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.8))
		else
			imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
		end
		imgui.SetNextWindowSize(imgui.ImVec2(cfg['size']['hw'], cfg['size']['hw'] * 2))
		imgui.Begin(u8'с днем говнокода', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
		
		local wanted = memory.getint8(5823328, false)
		for i = 1, wanted do
			imgui.SetCursorPosX(imgui.GetWindowSize().x - imgui.GetWindowSize().x / 10 * i)
			imgui.Image(textures.star, imgui.ImVec2(imgui.GetWindowSize().x / 10, imgui.GetWindowSize().x / 10))
			imgui.SameLine()
		end
		if wanted == 0 then
			imgui.SetCursorPosY(imgui.GetCursorPos().y + imgui.GetWindowSize().x / 10)
		end

		imgui.TextColoredRightRGB(cfg['colors']['money'] .. '$' .. getPlayerMoney())

		if hold.weapon ~= getCurrentCharWeapon(PLAYER_PED) then
			hold.weapon = getCurrentCharWeapon(PLAYER_PED)
			textures.weapon = imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\gta5-hud\\' .. hold.weapon .. '.png')
		end
		imgui.Image(textures.weapon, imgui.ImVec2(imgui.GetWindowSize().x, imgui.GetWindowSize().x / 2))
		local ammo = getAmmoInCharWeapon(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED))
		if ammo > 0 then
			imgui.TextColoredRightRGB(cfg['colors']['ammo'] .. ammo - getAmmoInClip() .. ' ' .. cfg['colors']['clip'] .. getAmmoInClip())
		end

		imgui.End()
		imgui.PopStyleColor()
	end
end

function imgui.TextColoredRightRGB(text)
	local style = imgui.GetStyle()
	local colors = style.Colors
	local ImVec4 = imgui.ImVec4
	
	local explode_argb = function(argb)
		local a = bit.band(bit.rshift(argb, 24), 0xFF)
		local r = bit.band(bit.rshift(argb, 16), 0xFF)
		local g = bit.band(bit.rshift(argb, 8), 0xFF)
		local b = bit.band(argb, 0xFF)
		return a, r, g, b
	end
	
	local getcolor = function (color)
	if color:sub(1, 6):upper() == 'SSSSSS' then
		local r, g, b = colors[1].x, colors[1].y, colors[1].z
		local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
		return ImVec4(r, g, b, a / 255)
	end
	local color = type(color) == 'string' and tonumber(color, 16) or color
	if type(color) ~= 'number' then return end
		local r, g, b, a = explode_argb(color)
		return imgui.ImColor(r, g, b, a):GetVec4()
	end
	
	local render_text = function(text_)
	for w in text_:gmatch('[^\r\n]+') do
		local text, colors_, m = {}, {}, 1
		w = w:gsub('{(......)}', '{%1FF}')
		while w:find('{........}') do
			local n, k = w:find('{........}')
			local color = getcolor(w:sub(n + 1, k - 1))
			if color then
				text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
				colors_[#colors_ + 1] = color
				m = n
			end
			w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
		end
		if text[0] then
			local length = 0
			for i = 0, #text do
				length = length + imgui.CalcTextSize(text[i]).x / 0.5
			end
			imgui.SetCursorPosX(imgui.GetWindowSize().x - length)
			for i = 0, #text do
				imgui.OutlineText(text[i], colors_[i] or colors[1], imgui.ImVec4(0, 0, 0, 1))
				imgui.SameLine()
			end
			imgui.NewLine()
		else imgui.Text(w) end
		end
	end
	
	render_text(text)
end

function imgui.OutlineText(text, textColor, outlineColor, outlineSize)
	local outlineSize = outlineSize or 1
	local c = imgui.GetCursorPos()
	imgui.SetCursorPos(imgui.ImVec2(c.x - outlineSize, c.y))
	imgui.TextColored(outlineColor or imgui.ImVec4(0, 0, 0, 0.3), text)
	imgui.SetCursorPos(imgui.ImVec2(c.x + outlineSize, c.y))
	imgui.TextColored(outlineColor or imgui.ImVec4(0, 0, 0, 0.3), text)
	imgui.SetCursorPos(imgui.ImVec2(c.x, c.y - outlineSize)) 
	imgui.TextColored(outlineColor or imgui.ImVec4(0, 0, 0, 0.3), text)
	imgui.SetCursorPos(imgui.ImVec2(c.x, c.y + outlineSize)) 
	imgui.TextColored(outlineColor or imgui.ImVec4(0, 0, 0, 0.3), text)
	imgui.SetCursorPos(imgui.ImVec2(c.x - outlineSize, c.y + outlineSize)) 
	imgui.TextColored(outlineColor or imgui.ImVec4(0, 0, 0, 0.3), text)
	imgui.SetCursorPos(imgui.ImVec2(c.x + outlineSize, c.y + outlineSize)) 
	imgui.TextColored(outlineColor or imgui.ImVec4(0, 0, 0, 0.3), text)
	imgui.SetCursorPos(imgui.ImVec2(c.x - outlineSize, c.y - outlineSize))
	imgui.TextColored(outlineColor or imgui.ImVec4(0, 0, 0, 0.3), text)
	imgui.SetCursorPos(imgui.ImVec2(c.x + outlineSize, c.y - outlineSize))
	imgui.TextColored(outlineColor or imgui.ImVec4(0, 0, 0, 0.3), text)
	imgui.SetCursorPos(c)
	imgui.TextColored(textColor or imgui.ImVec4(1, 1, 1, 1), text)
end

function jsonSave(jsonFilePath, t)
	file = io.open(jsonFilePath, 'w')
	file:write(encodeJson(t))
	file:flush()
	file:close()
end

function jsonRead(jsonFilePath)
	local file = io.open(jsonFilePath, 'r+')
	local jsonInString = file:read('*a')
	file:close()
	local jsonTable = decodeJson(jsonInString)
	return jsonTable
end

function isLocalPlayerSpawned() -- взято у dmitriyewich из crosshair
	return (memory.read(getModuleHandle('gta_sa.exe') + 0x76F053, 1, false) >=  1 and true or false)
end

function getAmmoInClip()
    local pointer = getCharPointer(playerPed)
    local weapon = getCurrentCharWeapon(playerPed)
    local slot = getWeapontypeSlot(weapon)
    local cweapon = pointer + 0x5A0
    local current_cweapon = cweapon + slot * 0x1C
    return memory.getuint32(current_cweapon + 0x8)
end
