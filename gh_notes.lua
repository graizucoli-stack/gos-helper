local imgui = require 'imgui'
local encoding = require 'encoding'

encoding.default = 'UTF-8'
local function u8(str) return str end
local to_ansi = encoding.CP1251

local M = {}
local notes_tab = "notepad"
local notepad_buf = imgui.ImBuffer(8192)
local uk_id_buf = imgui.ImBuffer(16)

function M.save()
    local f = io.open(getWorkingDirectory() .. "\\gh_notes.txt", "w")
    if f then
        f:write(to_ansi(notepad_buf.v))
        f:close()
    end
end

function M.load()
    local path = getWorkingDirectory() .. "\\gh_notes.txt"
    if doesFileExist(path) then
        local f = io.open(path, "r")
        if f then
            local c = f:read("*a")
            if c then notepad_buf.v = to_ansi:decode(c) end
            f:close()
        end
    end
end

function M.init() M.load() end

function M.draw_sidebar()
    imgui.TextColored(imgui.ImVec4(0.55, 0.70, 0.70, 1.00), "  Заметки и Кодексы")
    imgui.Spacing()
    if imgui.Selectable("  Личные заметки", notes_tab == "notepad", 0, imgui.ImVec2(0, 26)) then notes_tab = "notepad" end
    if imgui.Selectable("  Скрипты и Кодексы", notes_tab == "laws", 0, imgui.ImVec2(0, 26)) then notes_tab = "laws" end
end

function M.draw_content(main_win)
    if notes_tab == "notepad" then
        imgui.TextColored(imgui.ImVec4(0.32, 0.78, 0.85, 1.00), "Личные заметки и шпаргалки")
        imgui.Separator()
        imgui.InputTextMultiline("##gh_notepad", notepad_buf, imgui.ImVec2(-1, -38))
        if imgui.Button("Сохранить заметки", imgui.ImVec2(160, 26)) then
            M.save()
            sampAddChatMessage("{33AAFF}[Gos Helper]{FFFFFF} " .. to_ansi("Заметки сохранены!"), -1)
        end
    elseif notes_tab == "laws" then
        imgui.TextColored(imgui.ImVec4(0.32, 0.78, 0.85, 1.00), "Быстрый вызов твоих скриптов законов")
        imgui.Separator()
        imgui.Spacing()

        imgui.Text("Умный розыск (твой скрипт /uk):")
        imgui.PushItemWidth(120)
        imgui.InputText("ID игрока##ukid", uk_id_buf)
        imgui.PopItemWidth()
        imgui.SameLine()
        if imgui.Button("Открыть /uk", imgui.ImVec2(140, 24)) then
            local id = notepad_buf and to_ansi(uk_id_buf.v):match("(%d+)")
            if main_win then main_win.v = false end
            lua_thread.create(function()
                wait(50)
                sampProcessChatInput(id and ("/uk " .. id) or "/uk")
            end)
        end

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        imgui.Text("Кодексы и законы:")
        if imgui.Button("Открыть ФЗ (/fz)", imgui.ImVec2(165, 30)) then
            if main_win then main_win.v = false end
            lua_thread.create(function() wait(50) sampProcessChatInput("/fz") end)
        end
        imgui.SameLine()
        if imgui.Button("Открыть ТК (/tkfind)", imgui.ImVec2(175, 30)) then
            if main_win then main_win.v = false end
            lua_thread.create(function() wait(50) sampProcessChatInput("/tkfind") end)
        end
        imgui.SameLine()
        if imgui.Button("Открыть КоАП (/koap)", imgui.ImVec2(175, 30)) then
            if main_win then main_win.v = false end
            lua_thread.create(function() wait(50) sampProcessChatInput("/koap") end)
        end
    end
end

return M
