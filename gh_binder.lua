local imgui = require 'imgui'
local encoding = require 'encoding'
local vkeys = require 'vkeys'
local sampev_ok, sampev = pcall(require, 'lib.samp.events')

encoding.default = 'UTF-8'
local function u8(str) return str end
local to_ansi = encoding.CP1251

local M = {}
local binder_tab = "default"
local bind_queue, bind_paused = {}, false

local default_binds = {
    { cmd = "cuff", desc = "Надеть наручники.", enabled = imgui.ImBool(true), text = "/me резким движением снял{?} с пояса наручники\n<800>\n/me заломил{?} руки подозреваемому и защелкнул{?} браслеты\n<500>\n/cuff {param1}" },
    { cmd = "uncuff", desc = "Снять наручники.", enabled = imgui.ImBool(true), text = "/me достал{?} ключ из подсумка и снял{?} наручники с задержанного\n<500>\n/uncuff {param1}" },
    { cmd = "arrest", desc = "Арест подозреваемого.", enabled = imgui.ImBool(true), text = "/me открыл{?} камеру КПЗ, завел{???} задержанного и закрыл{?} дверь\n<500>\n/arrest {param1}" },
    { cmd = "frisk", desc = "Обыск подозреваемого.", enabled = imgui.ImBool(true), text = "/me надел{?} резиновые перчатки и провел{???} обыск гражданина\n<500>\n/frisk {param1}" },
    { cmd = "ud", desc = "Показ удостоверения.", enabled = imgui.ImBool(true), text = "/me достал{?} служебное удостоверение\n<700>\n/do В удостоверении: {fraction} | {rank} | {name} {surname}.\n<500>\n/showbadge {param1}" },
    { cmd = "su", desc = "Объявить в розыск.", enabled = imgui.ImBool(true), text = "/me достал{?} КПК и внес{???} приметы нарушителя в базу МВД\n<500>\n/su {param1full}" },
    { cmd = "ticket", desc = "Выписать штраф.", enabled = imgui.ImBool(true), text = "/me заполнил{?} бланк протокола и передал{?} квитанцию нарушителю\n<500>\n/ticket {param1full}" },
    { cmd = "eject", desc = "Выкинуть из т/с.", enabled = imgui.ImBool(true), text = "/me открыл{?} дверь авто и вытащил{?} нарушителя\n<500>\n/eject {param1}" },
    { cmd = "/m", desc = "Мегафон (прижаться к обочине).", enabled = imgui.ImBool(true), text = "/m [Мегафон] Водитель! Прижмитесь к обочине и заглушите двигатель!" },
    { cmd = "gotome", desc = "Повести за собой.", enabled = imgui.ImBool(true), text = "/me взял{?} задержанного под руку и повел{???} за собой\n<500>\n/gotome {param1}" },
    { cmd = "ungotome", desc = "Отпустить задержанного.", enabled = imgui.ImBool(true), text = "/me отпустил{?} руку задержанного\n<500>\n/ungotome {param1}" },
    { cmd = "incar", desc = "Посадить в т/с.", enabled = imgui.ImBool(true), text = "/me открыл{?} дверь авто и усадил{?} задержанного внутрь\n<500>\n/incar {param1full}" },
    { cmd = "pull", desc = "Вытащить из т/с силой.", enabled = imgui.ImBool(true), text = "/me разбил{?} стекло двери и вытащил{?} водителя из салона\n<500>\n/pull {param1}" },
    { cmd = "usemed", desc = "Использовать аптечку.", enabled = imgui.ImBool(true), text = "/me достал{?} аптечку и перевязал{?} рану\n<500>\n/usemed" },
    { cmd = "mask", desc = "Надеть маску.", enabled = imgui.ImBool(true), text = "/me натянул{?} балаклаву на лицо\n<500>\n/mask" },
    { cmd = "pas", desc = "Запросить паспорт.", enabled = imgui.ImBool(true), text = "{greeting}! {fraction}, {rank} {name} {surname}. Предъявите ваши документы." },
    { cmd = "pmir", desc = "Правила Миранды.", enabled = imgui.ImBool(true), text = "Вы имеете право хранить молчание. Всё, что вы скажете, может быть использовано против вас в суде.\n<1200>\nВы имеете право на телефонный звонок и адвоката." }
}

local custom_binds = {}
local ed_open, ed_custom, ed_tags, wait_key = false, false, false, false
local ed_idx, ed_key, sel_cust = 0, 0, 1
local ed_name = imgui.ImBuffer(64)
local ed_cmd = imgui.ImBuffer(32)
local ed_trig = imgui.ImBuffer(128)
local ed_text = imgui.ImBuffer(4096)
local ed_en = imgui.ImBool(true)

local key_names = {
    [0] = "Нет", [vkeys.VK_F3] = "F3", [vkeys.VK_F4] = "F4", [vkeys.VK_F5] = "F5", [vkeys.VK_F6] = "F6",
    [vkeys.VK_X] = "X", [vkeys.VK_Z] = "Z", [vkeys.VK_C] = "C", [vkeys.VK_V] = "V", [vkeys.VK_B] = "B",
    [vkeys.VK_N] = "N", [vkeys.VK_M] = "M", [vkeys.VK_G] = "G", [vkeys.VK_H] = "H", [vkeys.VK_K] = "K", [vkeys.VK_L] = "L"
}
local weapon_names = {
    [0] = "Кулаки", [1] = "Кастет", [3] = "Дубинка", [4] = "Нож", [5] = "Бита", [22] = "Пистолет 9мм",
    [23] = "Пистолет с глушителем", [24] = "Desert Eagle", [25] = "Дробовик", [29] = "MP5", [30] = "AK-47", [31] = "M4", [34] = "Снайперская винтовка"
}
local car_colors = {
    [0] = "Черный", [1] = "Белый", [2] = "Синий", [3] = "Красный", [6] = "Желтый",
    [7] = "Голубой", [8] = "Серый", [16] = "Зеленый", [17] = "Темно-красный",
    [24] = "Серебристый", [36] = "Темно-серый", [44] = "Темно-зеленый",
    [53] = "Темно-синий", [61] = "Бежевый", [62] = "Бордовый", [65] = "Золотистый",
    [79] = "Синий", [86] = "Зеленый", [126] = "Розовый", [128] = "Оранжевый"
}

local function get_kname(vk) return (not vk or vk == 0) and "Нет" or (key_names[vk] or ("Key " .. vk)) end
local function trim(s) return s:gsub("^%s*(.-)%s*$", "%1") end

local function get_my_id()
    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    return id or 0
end

local function get_target_id()
    local ok, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
    if ok and doesCharExist(ped) then
        local r, id = sampGetPlayerIdByCharHandle(ped)
        if r then return id end
    end
    return -1
end

local function get_near_player()
    local mx, my, mz = getCharCoordinates(PLAYER_PED)
    local md, nid = 9999.0, -1
    for i = 0, 1000 do
        if sampIsPlayerConnected(i) and i ~= get_my_id() then
            local r, ped = sampGetCharHandleBySampPlayerId(i)
            if r and doesCharExist(ped) then
                local px, py, pz = getCharCoordinates(ped)
                local d = getDistanceBetweenCoords3d(mx, my, mz, px, py, pz)
                if d < md then md, nid = d, i end
            end
        end
    end
    return nid
end

local function get_near_car(with_drv)
    local mx, my, mz = getCharCoordinates(PLAYER_PED)
    local md, nvid = 9999.0, -1
    for i = 0, 2000 do
        local r, veh = sampGetCarHandleBySampVehicleId(i)
        if r and doesVehicleExist(veh) then
            local drv = getDriverOfCar(veh)
            if not with_drv or (drv and drv ~= -1 and doesCharExist(drv)) then
                local vx, vy, vz = getCarCoordinates(veh)
                local d = getDistanceBetweenCoords3d(mx, my, mz, vx, vy, vz)
                if d < md then md, nvid = d, i end
            end
        end
    end
    if nvid == -1 and isCharInAnyCar(PLAYER_PED) then
        local _, vid = sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))
        return vid or -1
    end
    return nvid
end

local function parse_line(line, arg_str)
    local res, params = line, {}
    for w in (arg_str or ""):gmatch("%S+") do table.insert(params, w) end
    res = res:gsub("{param(%d+)full}", function(n) local i = tonumber(n) return (i and params[i]) and table.concat(params, " ", i) or "" end)
    res = res:gsub("{param(%d+)}", function(n) return params[tonumber(n)] or "" end)

    local msk = os.date("*t", os.time(os.date("!*t")) + 10800)
    local gr = (msk.hour >= 5 and msk.hour < 12) and "Доброе утро" or ((msk.hour < 18) and "Добрый день" or ((msk.hour < 23) and "Добрый вечер" or "Доброй ночи"))
    res = res:gsub("{greeting}", gr):gsub("{time}", string.format("%02d:%02d:%02d", msk.hour, msk.min, msk.sec)):gsub("{date}", string.format("%02d.%02d.%04d", msk.day, msk.month, msk.year))

    local p = _G.GH_Profile
    if p then
        res = res:gsub("{name}", p.name.v):gsub("{surname}", p.surname.v)
        res = res:gsub("{fraction}", p.fraction.v):gsub("{rank}", p.rank.v):gsub("{phone}", p.phone.v)
        if p.gender.v == 1 then res = res:gsub("{%?%?%?}", "ла"):gsub("{%?%?}", "ась"):gsub("{%?}", "а")
        else res = res:gsub("{%?%?%?}", "ел"):gsub("{%?%?}", "ся"):gsub("{%?}", "") end
    end

    res = res:gsub("{id}", tostring(get_my_id())):gsub("{target}", tostring(get_target_id()))
    res = res:gsub("{nearplayer}", tostring(get_near_player()))
    res = res:gsub("{nearcar}", tostring(get_near_car(false))):gsub("{nearcarwithdriver}", tostring(get_near_car(true)))

    res = res:gsub("<name%((.-)%)>", function(s)
        local id = tonumber(s)
        if id and sampIsPlayerConnected(id) then return (sampGetPlayerNickname(id) or ""):match("^([^_]+)") or "" end
        return p and p.name.v or ""
    end)
    res = res:gsub("<surname%((.-)%)>", function(s)
        local id = tonumber(s)
        if id and sampIsPlayerConnected(id) then return (sampGetPlayerNickname(id) or ""):match("_(.+)$") or "" end
        return p and p.surname.v or ""
    end)
    res = res:gsub("<namesurname%((.-)%)>", function(s)
        local id = tonumber(s)
        if id and sampIsPlayerConnected(id) then return (sampGetPlayerNickname(id) or ""):gsub("_", " ") end
        return p and trim(p.name.v .. " " .. p.surname.v) or ""
    end)
    res = res:gsub("<score%((.-)%)>", function(s) local id = tonumber(s) or get_my_id() return tostring(sampGetPlayerScore(id)) end)
    res = res:gsub("<ping%((.-)%)>", function(s) local id = tonumber(s) or get_my_id() return tostring(sampGetPlayerPing(id)) end)
    res = res:gsub("<color%((.-)%)>", function(s) local id = tonumber(s) or get_my_id() return string.format("%06X", bit.band(sampGetPlayerColor(id), 0xFFFFFF)) end)
    res = res:gsub("<gun%((.-)%)>", function(s)
        local id, ped = tonumber(s), PLAYER_PED
        if id and sampIsPlayerConnected(id) then local ok, cp = sampGetCharHandleBySampPlayerId(id) if ok and doesCharExist(cp) then ped = cp end end
        local w = getCurrentCharWeapon(ped)
        return weapon_names[w] or ("Оружие #" .. w)
    end)
    res = res:gsub("<carid%((.-)%)>", function(s)
        local id, ped = tonumber(s), PLAYER_PED
if id and sampIsPlayerConnected(id) then local ok, cp = sampGetCharHandleBySampPlayerId(id) if ok and doesCharExist(cp) then ped = cp end end
if isCharInAnyCar(ped) then local _, vid = sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(ped)) return tostring(vid or -1) end
return "-1"
end)
res = res:gsub("<carname%((.-)%)>", function(s)
local vid = tonumber(s)
if vid then local ok, v = sampGetCarHandleBySampVehicleId(vid) if ok and doesVehicleExist(v) then return getNameOfVehicleModel(getCarModel(v)) or "Т/С" end end
return "Неизвестно"
end)
res = res:gsub("<carcolor%((.-)%)>", function(s)
local vid = tonumber(s)
if vid then
local ok, veh = sampGetCarHandleBySampVehicleId(vid)
if ok and doesVehicleExist(veh) then
local c1, _ = getCarColours(veh)
return car_colors[c1] or ("Авто (цвет #" .. tostring(c1) .. ")")
end
end
return "Автомобиль"
end)
res = res:gsub("<carplate%((.-)%)>", function(s) return "Т/С #" .. tostring(tonumber(s) or 0) end)
res = res:gsub("<cardriver%((.-)%)>", function(s)
local vid = tonumber(s)
if vid then local ok, v = sampGetCarHandleBySampVehicleId(vid) if ok and doesVehicleExist(v) then local d = getDriverOfCar(v) if d and d ~= -1 then local r, pid = sampGetPlayerIdByCharHandle(d) if r then return tostring(pid) end end end end
return "-1"
end)
res = res:gsub("<pos([xyz])%((.-)%)>", function(ax, s)
local id, x, y, z = tonumber(s), getCharCoordinates(PLAYER_PED)
if id and sampIsPlayerConnected(id) then local ok, cp = sampGetCharHandleBySampPlayerId(id) if ok and doesCharExist(cp) then x, y, z = getCharCoordinates(cp) end end
return string.format("%.1f", ax == "x" and x or (ax == "y" and y or z))
end)
res = res:gsub("<random%((%d+)%s*,%s*(%d+)%)>", function(a, b) local n1, n2 = tonumber(a), tonumber(b) return (n1 and n2 and n2 >= n1) and tostring(math.random(n1, n2)) or "0" end)
res = res:gsub("<intellisu%((.-)%)>", function(s) local id = tonumber(s) sampProcessChatInput(id and ("/uk " .. id) or "/uk") return "" end)
return res
end
function M.run(raw, arg)
    for l in raw:gmatch("[^\r\n]+") do
        local f = parse_line(trim(l), arg)
        if f ~= "" then table.insert(bind_queue, f) end
    end
end

function M.reg_cmds()
    for _, b in ipairs(default_binds) do
        local c = b.cmd:gsub("^/", "")
        sampRegisterChatCommand(c, function(a)
            if b.enabled.v then M.run(b.text, a) else sampSendChat("/" .. c .. (a ~= "" and (" " .. a) or "")) end
        end)
    end
    for _, b in ipairs(custom_binds) do
        local c = (b.cmd or ""):gsub("^/", "")
        if c ~= "" then sampRegisterChatCommand(c, function(a) if b.enabled.v then M.run(b.text, a) end end) end
    end
end

function M.save()
    local f = io.open(getWorkingDirectory() .. "\\gh_binds.txt", "w")
    if f then
        for _, b in ipairs(default_binds) do
            f:write(string.format("DEF###%s###%s###%s\n", b.cmd, b.enabled.v and "1" or "0", to_ansi(b.text):gsub("\n", "\\n")))
        end
        for _, b in ipairs(custom_binds) do
            f:write(string.format("CUST###%s###%s###%d###%s###%s###%s\n", to_ansi(b.name), b.cmd, b.key or 0, to_ansi(b.trig or ""), b.enabled.v and "1" or "0", to_ansi(b.text):gsub("\n", "\\n")))
        end
        f:close()
    end
end

local function safe_decode(str)
    if not str or str == "" then return "" end
    local ok, res = pcall(function() return to_ansi:decode(str) end)
    return ok and res or str
end

function M.load()
    local path = getWorkingDirectory() .. "\\gh_binds.txt"
    if doesFileExist(path) then
        local f = io.open(path, "r")
        if f then
            custom_binds = {}
            for l in f:lines() do
                local parts = {}
                for part in (l .. "###"):gmatch("(.-)###") do
                    table.insert(parts, part)
                end
                local tag, a1, a2, a3, a4, a5, a6 = unpack(parts)
                if tag == "DEF" and a1 and a3 then
                    for _, b in ipairs(default_binds) do
                        if b.cmd == a1 then
                            b.enabled.v = (a2 == "1")
                            b.text = safe_decode(a3:gsub("\\n", "\n"))
                        end
                    end
                elseif tag == "CUST" and a1 and a6 then
                    table.insert(custom_binds, {
                        name = safe_decode(a1),
                        cmd = a2 or "",
                        key = tonumber(a3) or 0,
                        trig = safe_decode(a4 or ""),
                        enabled = imgui.ImBool(a5 == "1"),
                        text = safe_decode(a6:gsub("\\n", "\n"))
                    })
                end
            end
            f:close()
        end
    end
end

    function sampev.onServerMessage(col, text)
        local utf_text = to_ansi:decode(text)
        for _, b in ipairs(custom_binds) do
            if b.enabled.v and b.trig ~= "" and string.find(utf_text, b.trig, 1, true) then M.run(b.text, "") end
        end
    end
end

function M.init()
    math.randomseed(os.time())
    M.load()
    M.reg_cmds()
    lua_thread.create(function()
        while true do
            wait(10)
            if #bind_queue > 0 and not bind_paused then
                local st = table.remove(bind_queue, 1)
                local d = st:match("^<(%d+)>$")
                if d then wait(tonumber(d))
                elseif st == "*" then setVirtualKeyDown(vkeys.VK_F8, true) wait(50) setVirtualKeyDown(vkeys.VK_F8, false)
                elseif st == "<!>" then bind_paused = true sampAddChatMessage("{33AAFF}[Gos Helper]{FFCC00} " .. to_ansi("Пауза (F3 — продолжить, F4 — сброс)."), -1)
                elseif st:sub(1, 1) == "#" then sampAddChatMessage("{33AAFF}[" .. to_ansi("Заметка") .. "]{FFFFFF} " .. to_ansi(st:sub(2)), -1)
                elseif st:sub(1, 3) == ">>>" then sampProcessChatInput(to_ansi(st:sub(4)))
                elseif st:sub(1, 2) == ">>" then sampSetChatInputEnabled(true) sampSetChatInputText(to_ansi(st:sub(3)))
                else sampSendChat(to_ansi(st)) end
            end
        end
    end)
end

function M.update()
    if wait_key then
        for k = 1, 254 do
            if k ~= vkeys.VK_LBUTTON and k ~= vkeys.VK_RBUTTON and wasKeyPressed(k) then
                ed_key = (k == vkeys.VK_ESCAPE or k == vkeys.VK_BACK) and 0 or k
                wait_key = false
                break
            end
        end
    elseif not sampIsChatInputActive() and not sampIsDialogActive() then
        if bind_paused and wasKeyPressed(vkeys.VK_F3) then bind_paused = false end
        if #bind_queue > 0 and wasKeyPressed(vkeys.VK_F4) then bind_queue, bind_paused = {}, false end
        for _, b in ipairs(custom_binds) do
            if b.enabled.v and b.key > 0 and wasKeyPressed(b.key) then M.run(b.text, "") end
        end
    end
end

function M.is_popup_open() return ed_open end

local tags_list = {
    { sec = "Основные возможности", items = {
        { "<1000>", "Задержка отыгровки в миллисекундах (1000 = 1 сек)." },
        { "#", "Вывод сообщения локально в ваш чат (не на сервер)." },
        { "*", "Сделать скриншот экрана (нажатие F8)." },
        { "<!>", "Пауза отыгровки до нажатия клавиши F3." },
        { ">>", "Вставить текст в поле ввода чата и открыть его." },
        { ">>>", "Выполнить команду или активировать другой бинд." }
    }},
    { sec = "Функции (подставляйте ID или тег в скобки)", items = {
        { "<name({target})>", "Имя игрока по ID (или ваше, если пусто)." },
        { "<surname({target})>", "Фамилия игрока по ID (или ваша, если пусто)." },
        { "<namesurname({target})>", "Имя и Фамилия игрока по ID." },
        { "<score({target})>", "Уровень (Score) игрока по ID." },
        { "<ping({target})>", "Пинг игрока по ID." },
        { "<color({target})>", "HEX-цвет ника игрока по ID." },
        { "<gun({target})>", "Название оружия в руках игрока по ID." },
        { "<carid({target})>", "ID транспорта, в котором сидит игрок." },
        { "<carname({nearcar})>", "Название транспорта по ID авто." },
        { "<carcolor({nearcar})>", "Возвращает цвет исходя из идентификатора транспорта." },
        { "<carplate({nearcar})>", "Номерной знак транспорта по ID авто." },
        { "<cardriver({nearcar})>", "ID водителя транспорта по ID авто." },
        { "<posx({id})>", "Координата X игрока или транспорта." },
        { "<posy({id})>", "Координата Y игрока или транспорта." },
        { "<posz({id})>", "Координата Z игрока или транспорта." },
        { "<random(1,10)>", "Случайное число в заданном диапазоне." },
        { "<intellisu({target})>", "Открыть умный розыск (/uk) на игрока по ID." }
    }},
    { sec = "Теги персонажа и окружения", items = {
        { "{id}", "Ваш текущий ID на сервере." },
        { "{target}", "ID игрока, на которого наведен прицел (ПКМ)." },
        { "{nearplayer}", "ID ближайшего к вам игрока." },
        { "{nearcar}", "ID ближайшего транспорта." },
        { "{nearcarwithdriver}", "ID ближайшего транспорта с водителем." },
        { "{name}", "Ваше имя / позывной из настроек." },
        { "{surname}", "Ваша фамилия из настроек." },
        { "{fraction}", "Ваша фракция из настроек." },
        { "{rank}", "Ваша должность из настроек." },
        { "{phone}", "Ваш номер телефона из настроек." },
        { "{greeting}", "Приветствие по времени МСК (Доброе утро/день/вечер)." },
        { "{time}", "Текущее время по МСК (ЧЧ:ММ:СС)." },
        { "{date}", "Текущая дата по МСК (ДД.ММ.ГГГГ)." },
        { "{?}", "Окончание по полу: -а (жен.) или пусто (муж.)." },
        { "{??}", "Окончание по полу: -ась (жен.) или -ся (муж.)." },
        { "{???}", "Окончание по полу: -ла (жен.) или -ел (муж.)." },
        { "{param1}", "1-е слово (аргумент) после команды." },
        { "{param1full}", "Весь текст после команды начиная с 1-го слова." }
    }}
}

function M.draw_sidebar()
    imgui.TextColored(imgui.ImVec4(0.55, 0.70, 0.70, 1.00), "  Биндер")
    imgui.Spacing()
    if imgui.Selectable("  Отыгровки по умолчанию", binder_tab == "default", 0, imgui.ImVec2(0, 26)) then binder_tab = "default" end
    if imgui.Selectable("  Пользовательские", binder_tab == "custom", 0, imgui.ImVec2(0, 26)) then binder_tab = "custom" end
end

function M.draw_content()
    if binder_tab == "default" then
        imgui.TextColored(imgui.ImVec4(0.32, 0.78, 0.85, 1.00), "Отыгровки по умолчанию") imgui.Separator()
        imgui.BeginChild("DefList", imgui.ImVec2(0, 0), false)
            for i, b in ipairs(default_binds) do
                if imgui.Checkbox("##d_en" .. i, b.enabled) then M.save() end
                imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(0.32, 0.78, 0.85, 1.00), "/" .. b.cmd) imgui.SameLine(115)
                imgui.Text(b.desc) imgui.SameLine(imgui.GetWindowWidth() - 95)
                if imgui.Button("Изменить##d" .. i, imgui.ImVec2(80, 22)) then
                    ed_custom, ed_idx, ed_tags = false, i, false
                    ed_name.v, ed_cmd.v, ed_text.v, ed_en.v = b.desc, b.cmd, b.text, b.enabled.v
                    ed_open = true
                end
                imgui.Separator()
            end
        imgui.EndChild()
    else
        imgui.TextColored(imgui.ImVec4(0.32, 0.78, 0.85, 1.00), "Пользовательские отыгровки") imgui.Separator()
        imgui.BeginChild("CustList", imgui.ImVec2(0, -38), false)
            for i, b in ipairs(custom_binds) do
                if imgui.Checkbox("##c_en" .. i, b.enabled) then M.save() end
                imgui.SameLine()
                local lbl = string.format("#%d  %-16s  /%-10s [%s]", i, b.name, b.cmd, get_kname(b.key))
                if imgui.Selectable(lbl .. "##cs" .. i, sel_cust == i, 0, imgui.ImVec2(0, 22)) then sel_cust = i end
                imgui.Separator()
            end
        imgui.EndChild()
        if imgui.Button("+ Создать", imgui.ImVec2(110, 26)) then
            ed_custom, ed_idx, ed_tags, ed_key = true, 0, false, 0
            ed_name.v, ed_cmd.v, ed_trig.v, ed_text.v, ed_en.v = "Новый бинд", "mycmd", "", "/me выполнил{?} действие", true
            ed_open = true
end
imgui.SameLine()
if imgui.Button("Редактировать", imgui.ImVec2(120, 26)) and custom_binds[sel_cust] then
local b = custom_binds[sel_cust]
ed_custom, ed_idx, ed_tags, ed_key = true, sel_cust, false, b.key or 0
ed_name.v, ed_cmd.v, ed_trig.v, ed_text.v, ed_en.v = b.name, b.cmd, b.trig or "", b.text, b.enabled.v
ed_open = true
end
imgui.SameLine()
if imgui.Button("Удалить", imgui.ImVec2(100, 26)) and custom_binds[sel_cust] then table.remove(custom_binds, sel_cust) M.save() end
end
end
function M.draw_popups()
if not ed_open then return end
imgui.SetNextWindowSize(imgui.ImVec2(640, 480), imgui.Cond.FirstUseEver)
imgui.Begin("Редактирование отыгровки", nil, imgui.WindowFlags.NoCollapse)
local w = imgui.GetWindowWidth()
imgui.PushItemWidth(w - 135)
if ed_custom then imgui.InputText("##enm", ed_name) else imgui.InputText("##enm_ro", ed_name, imgui.InputTextFlags.ReadOnly) end
imgui.PopItemWidth() imgui.SameLine(w - 95) imgui.Checkbox("Вкл##een", ed_en)
if ed_custom then
if imgui.Button((wait_key and "Нажмите клавишу..." or ("Клавиша: " .. get_kname(ed_key))) .. "##bk", imgui.ImVec2(150, 24)) then wait_key = not wait_key end
imgui.SameLine() imgui.PushItemWidth(220) imgui.InputText("##etr", ed_trig) imgui.PopItemWidth()
imgui.SameLine() imgui.PushItemWidth(w - 405) imgui.InputText("##ecm", ed_cmd) imgui.PopItemWidth()
end
imgui.Separator()
if not ed_tags then
imgui.InputTextMultiline("##etxt", ed_text, imgui.ImVec2(-1, -42))
else
imgui.BeginChild("TagsHelp", imgui.ImVec2(0, -42), true)
for _, group in ipairs(tags_list) do
imgui.Spacing()
imgui.TextColored(imgui.ImVec4(1.0, 0.85, 0.30, 1.0), group.sec)
imgui.Separator()
for _, item in ipairs(group.items) do
if imgui.Button(item[1] .. "##tbtn", imgui.ImVec2(175, 24)) then
ed_text.v = ed_text.v .. item[1]
ed_tags = false
end
imgui.SameLine(190)
imgui.TextWrapped(item[2])
end
end
imgui.EndChild()
end
local bw = (w - 44) / 3
if imgui.Button("Сохранить", imgui.ImVec2(bw, 28)) then
local tx = ed_text.v
if ed_custom then
local nm, cm, tr = ed_name.v, ed_cmd.v:gsub("^/", ""), ed_trig.v
if ed_idx == 0 then table.insert(custom_binds, { name = nm, cmd = cm, key = ed_key, trig = tr, enabled = imgui.ImBool(ed_en.v), text = tx })
else custom_binds[ed_idx].name, custom_binds[ed_idx].cmd, custom_binds[ed_idx].key, custom_binds[ed_idx].trig, custom_binds[ed_idx].enabled.v, custom_binds[ed_idx].text = nm, cm, ed_key, tr, ed_en.v, tx end
M.reg_cmds()
else default_binds[ed_idx].enabled.v, default_binds[ed_idx].text = ed_en.v, tx end
M.save() wait_key, ed_open = false, false
end
imgui.SameLine()
if imgui.Button(ed_tags and "Вернуться к тексту" or "Теги и функции", imgui.ImVec2(bw, 28)) then ed_tags = not ed_tags end
imgui.SameLine()
if imgui.Button("Отмена", imgui.ImVec2(bw, 28)) then wait_key, ed_open = false, false end
imgui.End()
end
return M
