local imgui = require 'imgui'
local encoding = require 'encoding'
local vkeys = require 'vkeys'
local dlstatus = require('moonloader').download_status

encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Íàñòðîéêè àâòîîáíîâëåíèÿ (GitHub: graizucoli-stack/gos-helper)
local CURRENT_VERSION = "1.0"
local URL_VERSION = "https://githubusercontent.com"
local URL_MAIN    = "https://githubusercontent.com"
local URL_BINDER  = "https://githubusercontent.com"
local URL_NOTES   = "https://githubusercontent.com"

package.loaded['gh_binder'] = nil
package.loaded['gh_notes'] = nil
local binder_ok, binder = pcall(require, 'gh_binder')
local notes_ok, notes = pcall(require, 'gh_notes')

local main_window = imgui.ImBool(false)
local active_page = "home"
local settings_tab = "profile"

_G.GH_Profile = {
    name = imgui.ImBuffer(u8'Ïîçûâíîé "Ëèñ"', 64),
    surname = imgui.ImBuffer(u8"", 64),
    gender = imgui.ImInt(0),
    fraction = imgui.ImBuffer(u8"ÓÑÁ", 64),
    rank = imgui.ImBuffer(u8"Ñòàðøèé ñëåäîâàòåëü", 64),
    phone = imgui.ImBuffer(u8"", 8),
    ar = 0.16, ag = 0.45, ab = 0.78,
    br = 0.07, bg = 0.10, bb = 0.15
}

local accent_buf = imgui.ImFloat3(0.16, 0.45, 0.78)
local bg_buf = imgui.ImFloat3(0.07, 0.10, 0.15)

function check_updates()
    local ver_path = getWorkingDirectory() .. "\\gh_ver_tmp.txt"
    downloadUrlToFile(URL_VERSION, ver_path, function(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            if doesFileExist(ver_path) then
                local f = io.open(ver_path, "r")
                if f then
                    local new_ver = (f:read("*a") or ""):gsub("%s+", "")
                    f:close()
                    os.remove(ver_path)

                    if new_ver ~= "" and new_ver ~= CURRENT_VERSION then
                        sampAddChatMessage("{33AAFF}[Gos Helper]{FFFFFF} Äîñòóïíî îáíîâëåíèå {33AAFF}v" .. new_ver .. "{FFFFFF}! Ñêà÷èâàþ...", -1)
                        downloadUrlToFile(URL_MAIN, thisScript().path, function(id2, st2)
                            if st2 == dlstatus.STATUS_ENDDOWNLOADDATA then
                                downloadUrlToFile(URL_BINDER, getWorkingDirectory() .. "\\lib\\gh_binder.lua", function(id3, st3)
                                    if st3 == dlstatus.STATUS_ENDDOWNLOADDATA then
                                        downloadUrlToFile(URL_NOTES, getWorkingDirectory() .. "\\lib\\gh_notes.lua", function(id4, st4)
                                            if st4 == dlstatus.STATUS_ENDDOWNLOADDATA then
                                                sampAddChatMessage("{33AAFF}[Gos Helper]{FFFFFF} Îáíîâëåíèå v" .. new_ver .. " óñòàíîâëåíî! Ïåðåçàãðóæàþ...", -1)
                                                lua_thread.create(function()
                                                    main_window.v = false
                                                    imgui.Process = false
                                                    imgui.ShowCursor = false
                                                    wait(200)
                                                    thisScript():reload()
                                                end)
                                            end
                                        end)
                                    end
                                end)
                            end
                        end)
                    end
                end
            end
        end
    end)
end

function sync_color_buffers()
    accent_buf = imgui.ImFloat3(_G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab)
    bg_buf = imgui.ImFloat3(_G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb)
end

function apply_custom_theme()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col

    local ar, ag, ab = _G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab
    local br, bg, bb = _G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb

    style.Alpha = 1.0
    style.WindowRounding = 8.0
    style.ChildWindowRounding = 6.0
    style.FrameRounding = 5.0
    style.ScrollbarRounding = 6.0
    style.GrabRounding = 5.0
    style.WindowPadding = imgui.ImVec2(14, 14)
    style.FramePadding = imgui.ImVec2(8, 5)
    style.ItemSpacing = imgui.ImVec2(8, 8)

    colors[clr.Text]            = imgui.ImVec4(0.94, 0.96, 0.98, 1.00)
    colors[clr.TextDisabled]    = imgui.ImVec4(0.55, 0.60, 0.65, 1.00)
    colors[clr.WindowBg]        = imgui.ImVec4(br, bg, bb, 0.98)
    colors[clr.ChildWindowBg]   = imgui.ImVec4(br * 0.85, bg * 0.85, bb * 0.85, 0.95)
    colors[clr.PopupBg]         = imgui.ImVec4(br * 1.1, bg * 1.1, bb * 1.1, 0.98)
    colors[clr.Border]          = imgui.ImVec4(ar, ag, ab, 0.60)
    colors[clr.FrameBg]         = imgui.ImVec4(br * 1.4, bg * 1.4, bb * 1.4, 1.00)
    colors[clr.FrameBgHovered]  = imgui.ImVec4(ar * 0.7, ag * 0.7, ab * 0.7, 0.90)
    colors[clr.FrameBgActive]   = imgui.ImVec4(ar * 0.9, ag * 0.9, ab * 0.9, 1.00)
    colors[clr.TitleBg]         = imgui.ImVec4(br * 0.8, bg * 0.8, bb * 0.8, 1.00)
    colors[clr.TitleBgActive]   = imgui.ImVec4(ar * 0.6, ag * 0.6, ab * 0.6, 1.00)
    colors[clr.Button]          = imgui.ImVec4(ar * 0.85, ag * 0.85, ab * 0.85, 1.00)
    colors[clr.ButtonHovered]   = imgui.ImVec4(ar, ag, ab, 1.00)
    colors[clr.ButtonActive]    = imgui.ImVec4(math.min(ar * 1.2, 1), math.min(ag * 1.2, 1), math.min(ab * 1.2, 1), 1.00)
    colors[clr.Header]          = imgui.ImVec4(ar * 0.85, ag * 0.85, ab * 0.85, 0.95)
    colors[clr.HeaderHovered]   = imgui.ImVec4(ar, ag, ab, 1.00)
    colors[clr.HeaderActive]    = imgui.ImVec4(math.min(ar * 1.2, 1), math.min(ag * 1.2, 1), math.min(ab * 1.2, 1), 1.00)
    colors[clr.Separator]       = imgui.ImVec4(ar, ag, ab, 0.50)
    colors[clr.CheckMark]       = imgui.ImVec4(math.min(ar * 1.3, 1), math.min(ag * 1.3, 1), math.min(ab * 1.3, 1), 1.00)
end

function save_profile()
    local f = io.open(getWorkingDirectory() .. "\\gh_profile.txt", "w")
    if f then
        f:write("NAME=" .. u8:decode(_G.GH_Profile.name.v) .. "\n")
        f:write("SURNAME=" .. u8:decode(_G.GH_Profile.surname.v) .. "\n")
        f:write("GENDER=" .. tostring(_G.GH_Profile.gender.v) .. "\n")
        f:write("FRACTION=" .. u8:decode(_G.GH_Profile.fraction.v) .. "\n")
        f:write("RANK=" .. u8:decode(_G.GH_Profile.rank.v) .. "\n")
        f:write(string.format("ACCENT=%.3f,%.3f,%.3f\n", _G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab))
        f:write(string.format("BG=%.3f,%.3f,%.3f\n", _G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb))
        f:close()
    end
end

function load_profile()
    local path = getWorkingDirectory() .. "\\gh_profile.txt"
    if doesFileExist(path) then
        local f = io.open(path, "r")
        if f then
            for line in f:lines() do
                local k, v = line:match("^([^=]+)=(.*)$")
                if k == "NAME" then _G.GH_Profile.name.v = u8(v)
                elseif k == "SURNAME" then _G.GH_Profile.surname.v = u8(v)
                elseif k == "GENDER" then _G.GH_Profile.gender.v = tonumber(v) or 0
                elseif k == "FRACTION" then _G.GH_Profile.fraction.v = u8(v)
                elseif k == "RANK" then _G.GH_Profile.rank.v = u8(v)
                elseif k == "ACCENT" then
                    local r, g, b = v:match("([%d%.]+),([%d%.]+),([%d%.]+)")
                    if r and g and b then
                        _G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab = tonumber(r), tonumber(g), tonumber(b)
                    end
                elseif k == "BG" then
                    local r, g, b = v:match("([%d%.]+),([%d%.]+),([%d%.]+)")
                    if r and g and b then
                        _G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb = tonumber(r), tonumber(g), tonumber(b)
                    end
                end
            end
            f:close()
        end
    end
    sync_color_buffers()
end

function get_accent_vec4(mult, alpha)
    return imgui.ImVec4(
        math.min(_G.GH_Profile.ar * mult, 1.0),
        math.min(_G.GH_Profile.ag * mult, 1.0),
        math.min(_G.GH_Profile.ab * mult, 1.0),
        alpha or 1.0
    )
end

function copy_dev_link()
    local link = "https://vk.ru"
    setClipboardText(link)
    sampAddChatMessage("{33AAFF}[Gos Helper]{FFFFFF} Ññûëêà ñêîïèðîâàíà â áóôåð îáìåíà: {33AAFF}" .. link, -1)
end

function draw_tile(id, title, subtitle, w, h)
    local p = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()
    local clicked = imgui.InvisibleButton(id, imgui.ImVec2(w, h))
    local hov = imgui.IsItemHovered()

    local br, bg, bb = _G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb
    local bg_c = hov and imgui.GetColorU32(get_accent_vec4(0.65, 0.95)) or imgui.GetColorU32(imgui.ImVec4(br * 1.35, bg * 1.35, bb * 1.35, 0.95))
    local brd = hov and imgui.GetColorU32(get_accent_vec4(1.2, 1.0)) or imgui.GetColorU32(get_accent_vec4(0.8, 0.60))

    dl:AddRectFilled(p, imgui.ImVec2(p.x + w, p.y + h), bg_c, 8.0)
    dl:AddRect(p, imgui.ImVec2(p.x + w, p.y + h), brd, 8.0, 15, 1.5)
    dl:AddRectFilled(imgui.ImVec2(p.x + 12, p.y + 18), imgui.ImVec2(p.x + 16, p.y + h - 18), imgui.GetColorU32(get_accent_vec4(1.15, 1.0)), 2.0)

    dl:AddText(imgui.ImVec2(p.x + 28, p.y + 18), imgui.GetColorU32(imgui.ImVec4(0.95, 0.98, 0.98, 1.00)), u8(title))
    dl:AddText(imgui.ImVec2(p.x + 28, p.y + 42), imgui.GetColorU32(imgui.ImVec4(0.75, 0.82, 0.88, 1.00)), u8(subtitle))
    return clicked
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    load_profile()
    apply_custom_theme()
    imgui.Process = false
    imgui.ShowCursor = false

if binder_ok and binder.init then binder.init() end
if notes_ok and notes.init then notes.init() end
sampUnregisterChatCommand("gh")
sampRegisterChatCommand("gh", function()
main_window.v = not main_window.v
end)
sampAddChatMessage("{33AAFF}[Gos Helper v" .. CURRENT_VERSION .. "]{FFFFFF} Çàãðóæåí! Îòêðûòü ìåíþ: {33AAFF}/gh{FFFFFF} èëè {33AAFF}F2{FFFFFF}", -1)
check_updates()
while true do
wait(0)
if not sampIsChatInputActive() and not sampIsDialogActive() then
if wasKeyPressed(vkeys.VK_F2) then
main_window.v = not main_window.v
end
end
if binder_ok and binder.update then binder.update() end
local pop = (binder_ok and binder.is_popup_open and binder.is_popup_open())
imgui.Process = main_window.v or pop
imgui.ShowCursor = imgui.Process
end
end
function imgui.OnDrawFrame()
if main_window.v then
apply_custom_theme()
imgui.SetNextWindowSize(imgui.ImVec2(800, 500), imgui.Cond.FirstUseEver)
imgui.Begin(u8"Gos Helper", main_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
local w, h = imgui.GetWindowWidth(), imgui.GetWindowHeight()
imgui.SetCursorPos(imgui.ImVec2(w - 38, 10))
if imgui.Button("X##close", imgui.ImVec2(26, 24)) then main_window.v = false end
if active_page == "home" then
imgui.SetCursorPos(imgui.ImVec2(24, 22))
imgui.TextColored(get_accent_vec4(1.25, 1.0), u8("GOS HELPER  v" .. CURRENT_VERSION))
imgui.SetCursorPos(imgui.ImVec2(24, 42))
imgui.TextColored(imgui.ImVec4(0.75, 0.85, 0.90, 1.00), u8"BY ÐÎÊÎÒÎÂ & ÐÅÁÐÎÂ  |  Åäèíûé ïîìîùíèê ãîñ. ñòðóêòóð")
imgui.SetCursorPos(imgui.ImVec2(14, 76))
imgui.Separator()
local tw, th = (w - 64) / 3, 105
imgui.SetCursorPos(imgui.ImVec2(20, 105))
if draw_tile("t_bind", "Áèíäåð", "Îòûãðîâêè äåéñòâèé,\nêîìàíäû è ñâîè áèíäû", tw, th) then active_page = "binder" end
imgui.SetCursorPos(imgui.ImVec2(20 + tw + 12, 105))
if draw_tile("t_note", "Çàìåòêè è Êîäåêñû", "Ëè÷íûé áëîêíîò, ÓÊ,\nÔÇ, ÒÊ è ÊîÀÏ Õåëïåð", tw, th) then active_page = "notes" end
imgui.SetCursorPos(imgui.ImVec2(20 + (tw + 12) * 2, 105))
if draw_tile("t_sett", "Íàñòðîéêè", "Ïðîôèëü ïåðñîíàæà\nè ïàëèòðà öâåòîâ ìåíþ", tw, th) then active_page = "settings" end
local bw2 = (w - 52) / 2
imgui.SetCursorPos(imgui.ImVec2(20, 225))
if draw_tile("t_info", "Info (Êîìàíäû)", "Ñïðàâî÷íèê ïî âñåì\nêîìàíäàì è êëàâèøàì", bw2, 95) then
active_page = "info"
end
imgui.SetCursorPos(imgui.ImVec2(20 + bw2 + 12, 225))
if draw_tile("t_dev", "Ñâÿçü ñ ðàçðàáîò÷èêîì", "ÂÊîíòàêòå: vk.ru\n(Íàæìèòå, ÷òîáû ñêîïèðîâàòü ññûëêó)", bw2, 95) then
copy_dev_link()
active_page = "developer"
end
else
imgui.SetCursorPos(imgui.ImVec2(14, 14))
imgui.BeginChild("Sidebar", imgui.ImVec2(210, h - 28), true)
if imgui.Button(u8"<-  Íà ãëàâíóþ", imgui.ImVec2(-1, 30)) then active_page = "home" end
imgui.Spacing()
if imgui.Selectable(u8"  Ãëàâíàÿ", false, 0, imgui.ImVec2(0, 26)) then active_page = "home" end
imgui.Separator()
imgui.Spacing()
if active_page == "binder" and binder_ok then
binder.draw_sidebar()
elseif active_page == "notes" and notes_ok then
notes.draw_sidebar()
elseif active_page == "settings" then
imgui.TextColored(imgui.ImVec4(0.55, 0.70, 0.75, 1.00), u8"  Íàñòðîéêè")
imgui.Spacing()
if imgui.Selectable(u8"  Ïðîôèëü è Áèíäåð", settings_tab == "profile", 0, imgui.ImVec2(0, 26)) then settings_tab = "profile" end
if imgui.Selectable(u8"  Öâåòà è Îôîðìëåíèå", settings_tab == "colors", 0, imgui.ImVec2(0, 26)) then settings_tab = "colors" end
elseif active_page == "info" then
imgui.TextColored(imgui.ImVec4(0.55, 0.70, 0.75, 1.00), u8"  Ñïðàâêà")
imgui.Spacing()
imgui.Selectable(u8"  Info (Êîìàíäû)", true, 0, imgui.ImVec2(0, 26))
elseif active_page == "developer" then
imgui.TextColored(imgui.ImVec4(0.55, 0.70, 0.75, 1.00), u8"  Èíôîðìàöèÿ")
imgui.Spacing()
imgui.Selectable(u8"  Ñâÿçü ñ ðàçðàáîò÷èêîì", true, 0, imgui.ImVec2(0, 26))
end
imgui.EndChild()
imgui.SetCursorPos(imgui.ImVec2(232, 42))
imgui.BeginChild("Content", imgui.ImVec2(w - 246, h - 56), true)
if active_page == "binder" then
if binder_ok then binder.draw_content() else imgui.Text(u8"Ôàéë gh_binder.lua íå íàéäåí!") end
elseif active_page == "notes" then
if notes_ok then notes.draw_content(main_window) else imgui.Text(u8"Ôàéë gh_notes.lua íå íàéäåí!") end
elseif active_page == "info" then
imgui.TextColored(get_accent_vec4(1.25, 1.0), u8"Info  Ñïðàâî÷íèê ïî îñíîâíûì êîìàíäàì")
imgui.Separator()
imgui.Spacing()
local cmds = {
{ cmd = "/gh  èëè  F2", desc = "Îòêðûòü / çàêðûòü ãëàâíîå ìåíþ Gos Helper" },
{ cmd = "/tk  (èëè /tkfind)", desc = "Òðóäîâîé Êîäåêñ (ÒÊ)" },
{ cmd = "/uk [ID èãðîêà]", desc = "Óìíûé ðîçûñê  îáúÿâèòü èãðîêà â ðîçûñê" },
{ cmd = "/fz", desc = "Ôåäåðàëüíûé çàêîí î ÔÑÁ (ÔÇîÔÑÁ)" },
{ cmd = "/koap", desc = "Êîäåêñ îá Àäìèíèñòðàòèâíûõ Ïðàâîíàðóøåíèÿõ (ÊîÀÏ Õåëïåð)" }
}
for _, item in ipairs(cmds) do
imgui.Spacing()
imgui.TextColored(get_accent_vec4(1.3, 1.0), u8(item.cmd))
imgui.SameLine(180)
imgui.Text(u8("  " .. item.desc))
imgui.Spacing()
imgui.Separator()
end
elseif active_page == "developer" then
imgui.TextColored(get_accent_vec4(1.25, 1.0), u8"Ñâÿçü ñ ðàçðàáîò÷èêîì (BY ÐÎÊÎÒÎÂ & ÐÅÁÐÎÂ)")
imgui.Separator()
imgui.Spacing()
imgui.TextWrapped(u8"Ïî âñåì âîïðîñàì, áàãàì, ïðåäëîæåíèÿì è äîðàáîòêàì ñêðèïòà Gos Helper îáðàùàéòåñü â ëè÷íûå ñîîáùåíèÿ ÂÊîíòàêòå:")
imgui.Spacing()
imgui.TextColored(imgui.ImVec4(0.35, 0.80, 1.00, 1.00), u8"vk.ru")
imgui.Spacing()
if imgui.Button(u8"Ñêîïèðîâàòü ññûëêó ÂÊ", imgui.ImVec2(190, 28)) then
copy_dev_link()
end
elseif active_page == "settings" then
if settings_tab == "profile" then
imgui.TextColored(get_accent_vec4(1.25, 1.0), u8"Íàñòðîéêè ïðîôèëÿ (àâòîïîäñòàíîâêà â áèíäåð)")
imgui.Separator()
imgui.Spacing()
imgui.PushItemWidth(220)
imgui.InputText(u8"Âàøå èìÿ / Ïîçûâíîé", _G.GH_Profile.name)
imgui.InputText(u8"Âàøà ôàìèëèÿ", _G.GH_Profile.surname)
imgui.Combo(u8"Âàø ïîë", _G.GH_Profile.gender, { u8"Ìóæñêîé", u8"Æåíñêèé" }, 2)
imgui.InputText(u8"Âàøà ôðàêöèÿ", _G.GH_Profile.fraction)
imgui.InputText(u8"Âàøà äîëæíîñòü", _G.GH_Profile.rank)
imgui.PopItemWidth()
imgui.Spacing()
if imgui.Button(u8"Ñîõðàíèòü ïðîôèëü", imgui.ImVec2(160, 28)) then
save_profile()
sampAddChatMessage("{33AAFF}[Gos Helper]{FFFFFF} Ïðîôèëü ñîõðàíåí!", -1)
end
elseif settings_tab == "colors" then
imgui.TextColored(get_accent_vec4(1.25, 1.0), u8"Íàñòðîéêà öâåòîâ èíòåðôåéñà (íà ëþáîé âêóñ)")
imgui.Separator()
imgui.Spacing()
imgui.PushItemWidth(220)
if imgui.ColorEdit3(u8"Öâåò àêöåíòà (êíîïêè, ðàìêè)", accent_buf) then
local r, g, b = accent_buf.v, accent_buf.v, accent_buf.v
_G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab = r, g, b
apply_custom_theme()
end
imgui.Spacing()
if imgui.ColorEdit3(u8"Öâåò ôîíà îêíà", bg_buf) then
local r, g, b = bg_buf.v, bg_buf.v, bg_buf.v
_G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb = r, g, b
apply_custom_theme()
end
imgui.PopItemWidth()
imgui.Spacing()
imgui.Separator()
imgui.Spacing()
imgui.Text(u8"Ãîòîâûå ïðåñåòû:")
if imgui.Button(u8"Police Ñèíèé", imgui.ImVec2(115, 26)) then
_G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab = 0.16, 0.45, 0.78
_G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb = 0.07, 0.10, 0.15
sync_color_buffers()
apply_custom_theme()
end
imgui.SameLine()
if imgui.Button(u8"Áèðþçîâûé", imgui.ImVec2(110, 26)) then
_G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab = 0.18, 0.62, 0.68
_G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb = 0.05, 0.15, 0.16
sync_color_buffers()
apply_custom_theme()
end
imgui.SameLine()
if imgui.Button(u8"ÔÑÁ Êðàñíûé", imgui.ImVec2(115, 26)) then
_G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab = 0.75, 0.18, 0.22
_G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb = 0.12, 0.06, 0.07
sync_color_buffers()
apply_custom_theme()
end
imgui.SameLine()
if imgui.Button(u8"Èçóìðóä", imgui.ImVec2(100, 26)) then
_G.GH_Profile.ar, _G.GH_Profile.ag, _G.GH_Profile.ab = 0.16, 0.65, 0.38
_G.GH_Profile.br, _G.GH_Profile.bg, _G.GH_Profile.bb = 0.06, 0.13, 0.09
sync_color_buffers()
apply_custom_theme()
end
imgui.Spacing()
imgui.Spacing()
if imgui.Button(u8"Ñîõðàíèòü öâåòà", imgui.ImVec2(160, 28)) then
save_profile()
sampAddChatMessage("{33AAFF}[Gos Helper]{FFFFFF} Öâåòîâàÿ ñõåìà ñîõðàíåíà!", -1)
end
end
end
imgui.EndChild()
end
imgui.End()
end
if binder_ok and binder.draw_popups then binder.draw_popups() end
end
function imgui.BeforeDrawFrame()
end
function onScriptTerminate(script, quitGame)
if script == thisScript() then
sampUnregisterChatCommand("gh")
main_window.v = false
imgui.Process = false
imgui.ShowCursor = false
end
end
