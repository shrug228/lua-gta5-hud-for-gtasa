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

local path = getGameDirectory() .. '\\moonloader\\config\\gta5-hud.json' -- путь до конфига
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
			['hw'] = 100,
			['money'] = 23
		}
	}
	jsonSave(path, cfg)
end

local textures, hold = {}, {} -- чтобы все было нормально с областью видимости
local cyrillic 		= imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
textures.gtafont	= imgui.GetIO().Fonts:AddFontFromFileTTF(getGameDirectory() .. '\\moonloader\\resource\\gta5-hud\\GTA Russian.ttf', cfg['size']['money'])
textures.font		= imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14, _, cyrillic)
imgui.RebuildFonts()

local editMode, showChat, isHotkeyAvailable = false, false, true

local navigation = {
    current = 1,
    list = {u8'Общее', u8'HUD', u8'Радар'}
}

function hexToImFloat3(hex)
	hex = hex:gsub("#","")
	local r, g, b = tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
	return imgui.ImFloat3(r / 255, g / 255, b / 255)
end

local imVars = {
	{
		hfixed 			= imgui.ImBool(cfg['pos']['hfixed']),
		htop			= imgui.ImBool(cfg['pos']['top']),
		bd				= imgui.ImInt(cfg['size']['bd']),
		bdColor			= hexToImFloat3(cfg['colors']['bd'])
	},
	{
		hw				= imgui.ImInt(cfg['size']['hw']),
		hh				= imgui.ImInt(cfg['size']['hh']),
		gw				= imgui.ImInt(cfg['size']['gw']),
		money			= imgui.ImInt(cfg['size']['money'])
	},
	{
		rx				= imgui.ImInt(cfg['pos']['rx']),
		ry				= imgui.ImInt(cfg['pos']['ry']),
		rw				= imgui.ImInt(cfg['size']['rw']),
		rh				= imgui.ImInt(cfg['size']['rh'])
	}
}

function main()
	repeat wait(100) until memory.read(0xC8D4C0, 4, false) ==   9
	lua_thread.create(function ()
		repeat wait(200) until isSampAvailable()
		sampRegisterChatCommand('gta5-hud', function () window.v = not window.v end)
		sampAddChatMessage('[GTA5-HUD] {ffffff}Загружен и вроде как работает, автор: {00ff00}shrug228{ffffff}. Версия: {00ff00}v1.0', 0xff00ff00)
		while true do
			showChat = sampGetChatDisplayMode() ~= 0
			isHotkeyAvailable = not (sampIsChatInputActive() or sampIsDialogActive())
			wait(0)
		end
	end)

	displayHud(false)

	local rx, ry = convertWindowScreenCoordsToGameScreenCoords(cfg['pos']['rx'], cfg['pos']['ry'])
	local rw, rh = convertWindowScreenCoordsToGameScreenCoords(cfg['size']['rw'], cfg['size']['rh'])

	textures.star 		= imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\gta5-hud\\star.png')

	imgui.Process = true

	while true do
		if isLocalPlayerSpawned() and showChat then
			local x, y = cfg['pos']['hx'], cfg['pos']['hy']
			local sx = cfg['size']['hw']
			if cfg['pos']['hfixed'] then
				x, y = cfg['pos']['rx'], cfg['pos']['ry'] + cfg['size']['rh']
				sx = cfg['size']['rw'] + cfg['size']['bd'] * 2
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
		
			local cx, cy = getCursorPos()
			if isKeyJustPressed(1) and editMode and cx > x and cx < x + sx and cy > y and cy < y + cfg['size']['hh'] and not cfg['pos']['hfixed'] then
				hudMoving = true
			end
			if hudMoving then
				cfg['pos']['hx'] = cx
				cfg['pos']['hy'] = cy
				jsonSave(path, cfg)
			end
			if wasKeyReleased(1) and hudMoving then
				hudMoving = false
			end
		end

		if isKeyJustPressed(VK_SUBTRACT) and isHotkeyAvailable then
			window.v = not window.v
		end
		imgui.ShowCursor, imgui.LockPlayer = window.v, window.v

		wait(0)
	end
end

function onScriptTerminate()
	jsonSave(path, cfg)
	displayHud(true)
end

function imgui.OnDrawFrame()
	if window.v then
		imgui.PushFont(textures.font)
		imgui.SetNextWindowSize(imgui.ImVec2(600, 400))
		imgui.Begin(u8'[GTA5-HUD]', window, imgui.WindowFlags.NoResize)
		for i, title in ipairs(navigation.list) do
			if HeaderButton(navigation.current == i, title) then
				navigation.current = i
			end
			if i ~= #navigation.list then
				imgui.SameLine(nil, 30)
			end
		end

		imgui.NewLine()

		if navigation.current == 1 then
			if imgui.Checkbox(u8'HUD зафиксирован на радаре', imVars[1].hfixed) then
				cfg['pos']['hfixed'] = imVars[1].hfixed.v
				jsonSave(path, cfg)
			end
			if cfg['pos']['hfixed'] then
				if imgui.Checkbox(u8'HUD над радаром', imVars[1].htop) then
					cfg['pos']['top'] = imVars[1].htop.v
					jsonSave(path, cfg)
				end
			end
			if imgui.SliderInt(u8'Толщина обводки радара', imVars[1].bd, 0, 10) then
				cfg['size']['bd'] = imVars[1].bd.v
				jsonSave(path, cfg)
			end
			-- if imgui.ColorPicker3(u8'Цвет обводки', imVars[1].bdColor) then
			-- 	cfg['colors']['bd'] = imFloat3ToHex(imVars[1].bdColor.v)
			-- 	jsonSave(path, cfg)
			-- end
		elseif navigation.current == 2 then
			if imgui.SliderInt(u8'Ширина HUD\'а', imVars[2].hw, 1, 500) then
				cfg['size']['hw'] = imVars[2].hw.v
				jsonSave(path, cfg)
			end
			if imgui.SliderInt(u8'Высота HUD\'а', imVars[2].hh, 1, 50) then
				cfg['size']['hh'] = imVars[2].hh.v
				jsonSave(path, cfg)
			end
			if imgui.SliderInt(u8'Размер иконки оружия', imVars[2].gw, 1, 500) then
				cfg['size']['gw'] = imVars[2].gw.v
				jsonSave(path, cfg)
			end
			if imgui.SliderInt(u8'Размер шрифта денег', imVars[2].money, 1, 60) then
				cfg['size']['money'] = imVars[2].money.v
				jsonSave(path, cfg)
				textures.gtafont	= imgui.GetIO().Fonts:AddFontFromFileTTF(getGameDirectory() .. '\\moonloader\\resource\\gta5-hud\\GTA Russian.ttf', cfg['size']['money'])
			end
			imgui.Separator()
			if imgui.Button(u8'Режим редактирования') then
				editMode = not editMode
			end
		elseif navigation.current == 3 then
		end

		imgui.End()
		imgui.PopFont()
	end

	if isLocalPlayerSpawned() and showChat then
		if editMode then
			imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.8))
		else
			imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
		end
		imgui.SetNextWindowSize(imgui.ImVec2(cfg['size']['gw'], cfg['size']['gw'] * 2))
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

		if editMode then
			cfg['pos']['gx'], cfg['pos']['gy'] = imgui.GetWindowPos().x, imgui.GetWindowPos().y
			jsonSave(path, cfg)
		else
			imgui.SetWindowPos(imgui.ImVec2(cfg['pos']['gx'], cfg['pos']['gy']))
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

function HeaderButton(bool, str_id)
    local DL = imgui.GetWindowDrawList()
    local ToU32 = imgui.ColorConvertFloat4ToU32
    local result = false
    local label = string.gsub(str_id, "##.*$", "")
    local duration = { 0.5, 0.3 }
    local cols = {
        idle = imgui.GetStyle().Colors[imgui.Col.TextDisabled],
        hovr = imgui.GetStyle().Colors[imgui.Col.Text],
        slct = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
    }

    if not AI_HEADERBUT then AI_HEADERBUT = {} end
     if not AI_HEADERBUT[str_id] then
        AI_HEADERBUT[str_id] = {
            color = bool and cols.slct or cols.idle,
            clock = os.clock() + duration[1],
            h = {
                state = bool,
                alpha = bool and 1.00 or 0.00,
                clock = os.clock() + duration[2],
            }
        }
    end
    local pool = AI_HEADERBUT[str_id]

    local degrade = function(before, after, start_time, duration)
        local result = before
        local timer = os.clock() - start_time
        if timer >= 0.00 then
            local offs = {
                x = after.x - before.x,
                y = after.y - before.y,
                z = after.z - before.z,
                w = after.w - before.w
            }

            result.x = result.x + ( (offs.x / duration) * timer )
            result.y = result.y + ( (offs.y / duration) * timer )
            result.z = result.z + ( (offs.z / duration) * timer )
            result.w = result.w + ( (offs.w / duration) * timer )
        end
        return result
    end

    local pushFloatTo = function(p1, p2, clock, duration)
        local result = p1
        local timer = os.clock() - clock
        if timer >= 0.00 then
            local offs = p2 - p1
            result = result + ((offs / duration) * timer)
        end
        return result
    end

    local set_alpha = function(color, alpha)
        return imgui.ImVec4(color.x, color.y, color.z, alpha or 1.00)
    end

    imgui.BeginGroup()
        local pos = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
      
        imgui.TextColored(pool.color, label)
        local s = imgui.GetItemRectSize()
        local hovered = imgui.IsItemHovered()
        local clicked = imgui.IsItemClicked()
      
        if pool.h.state ~= hovered and not bool then
            pool.h.state = hovered
            pool.h.clock = os.clock()
        end
      
        if clicked then
            pool.clock = os.clock()
            result = true
        end

        if os.clock() - pool.clock <= duration[1] then
            pool.color = degrade(
                imgui.ImVec4(pool.color),
                bool and cols.slct or (hovered and cols.hovr or cols.idle),
                pool.clock,
                duration[1]
            )
        else
            pool.color = bool and cols.slct or (hovered and cols.hovr or cols.idle)
        end

        if pool.h.clock ~= nil then
            if os.clock() - pool.h.clock <= duration[2] then
                pool.h.alpha = pushFloatTo(
                    pool.h.alpha,
                    pool.h.state and 1.00 or 0.00,
                    pool.h.clock,
                    duration[2]
                )
            else
                pool.h.alpha = pool.h.state and 1.00 or 0.00
                if not pool.h.state then
                    pool.h.clock = nil
                end
            end

            local max = s.x / 2
            local Y = p.y + s.y + 3
            local mid = p.x + max

            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid + (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid - (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
        end

    imgui.EndGroup()
    return result
end

-- lemonager, тема хорошая, спасибо, но блять, что с форматированием?)
function apply_custom_style()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2

	style.WindowPadding = ImVec2(15, 15)
	style.WindowRounding = 15.0
	style.FramePadding = ImVec2(5, 5)
	style.ItemSpacing = ImVec2(12, 8)
	style.ItemInnerSpacing = ImVec2(8, 6)
	style.IndentSpacing = 25.0
	style.ScrollbarSize = 15.0
	style.ScrollbarRounding = 15.0
	style.GrabMinSize = 15.0
	style.GrabRounding = 7.0
	style.ChildWindowRounding = 8.0
	style.FrameRounding = 6.0
	
	colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
	colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
	colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
	colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
	colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
	colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
	colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
	colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
	colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.TitleBgActive] = ImVec4(0.08, 0.10, 0.12, 1.00)
	colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
	colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
	colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
	colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
	colors[clr.ComboBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
	colors[clr.CheckMark] = ImVec4(0.28, 0.56, 1.00, 1.00)
	colors[clr.SliderGrab] = ImVec4(0.28, 0.56, 1.00, 1.00)
	colors[clr.SliderGrabActive] = ImVec4(0.37, 0.61, 1.00, 1.00)
	colors[clr.Button] = ImVec4(0.20, 0.25, 0.29, 1.00)
	colors[clr.ButtonHovered] = ImVec4(0.28, 0.56, 1.00, 1.00)
	colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1.00)
	colors[clr.Header] = ImVec4(0.20, 0.25, 0.29, 0.55)
	colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.80)
	colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
	colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
	colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
	colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
	colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end
apply_custom_style()

function imFloat3ToHex(float3)
	local rgb = {float3[1] * 255, float3[2] * 255, float3[3] * 255}

	local hexadecimal = '0X'

	for key, value in pairs(rgb) do
		local hex = ''

		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
		end

		if(string.len(hex) == 0)then
			hex = '00'

		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end

		hexadecimal = hexadecimal .. hex
	end

	hexadecimal = hexadecimal:sub(3, 9)
	return hexadecimal
end
