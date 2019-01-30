script_name("Eye Killer")
script_author("Elias Torvalds")
script_version("1.0")
script_description("Чекер старшего состава в МО штата Blue")
script_moonloader(26)
script_dependencies("SAMP", "submenus", "JSON.lua")

local sampev = require 'lib.samp.events'
local submenus = require 'submenus'
local json = require 'json'
local dl_status = require('moonloader').download_status

local configPath = getGameDirectory() .. "\\moonloader\\config"

local faction = ""
local list = {}
local spawnCount = 0

local settingsDialog = {
	title = "{e74c3c}Eye Killer:{FFFFFF} Выбор фракции",
	{
		title = "Сухопутные Войска",
		onclick = function(menu, row)
			faction = "GF"
			saveConfig()
		end
	},
	{
		title = "Военно-Воздушные Силы",
		onclick = function(menu, row)
			faction = "AF"
			saveConfig()
		end
	},
	{
		title = "Военно-Морской Флот",
		onclick = function(menu, row)
			faction = "Navy"
			saveConfig()
		end
	}
}

function showDialogWithAllPolkansOnline(args)
	if list[faction] ~= nil then
		local polkansDialogText = "Ник[id]\tЗвание\n"
		local maxPlayerId = sampGetMaxPlayerId(false)
		print(maxPlayerId)
		for i = 0, maxPlayerId do
			if sampIsPlayerConnected(i) then
				local playerName = sampGetPlayerNickname(i)
				if list[faction][playerName] ~= nil then
					polkansDialogText = polkansDialogText .. playerName .. "[" .. i .. "]" .. "\t" .. list[faction][playerName] .. "\n"
				end
			end
		end
		sampShowDialog(25000, "{e74c3c}Eye Killer:{FFFFFF} Старшие офицеры онлайн", polkansDialogText, "Закрыть", "", 5)
	end
end

function reloadEyeKiller(args)
	sampAddChatMessage("[Eye Killer] {FFFFFF}Перезагрузка списка старшего состава МО...", 0xffe74c3c)
	initConfig()
end

function initList(id, status, p1, p2)
	if status == dl_status.STATUS_DOWNLOADINGDATA then
		print("Загрузка списка старшего состава МО (" .. p1 .. "/" .. p2 ..")...")
	elseif status == dl_status.STATUS_ENDDOWNLOADDATA then
		local file = io.open(configPath .. "\\eyelist.json")
		local data = file:read("*all")
		list = json.decode(data)
		file:close()
		print("Список старшего состава МО готов.")
	end
end

function saveConfig()
	local file = io.open(configPath .. "\\eyefaction.file", "w+")
	file:write(faction)
	file:close()
	downloadUrlToFile("http://pinig.in/modaid/eye/list.json", configPath .. "\\eyelist.json", initList)
end

function createConfig()
	submenus_show(settingsDialog, "{e74c3c}Eye Killer:{FFFFFF} Выбор фракции", "Выбрать", "Отмена", "Назад")
end

function initConfig()
	local file = io.open(configPath .. "\\eyefaction.file")
	if file == nil then
		lua_thread.create(createConfig)
		return false
	end

	local data = file:read("*all")
	faction = data
	file:close()
	downloadUrlToFile("http://pinig.in/modaid/eye/list.json", configPath .. "\\eyelist.json", initList)
end

function onExitScript(quitGame)
	sampUnregisterChatCommand("eyereload")
	sampUnregisterChatCommand("polkans")
end

function main()
	sampRegisterChatCommand("eyereload", reloadEyeKiller)
	sampRegisterChatCommand("polkans", showDialogWithAllPolkansOnline)
	wait(-1)
end

function sampev.onPlayerJoin(playerId, color, isNpc, nickname)
	if list[faction] ~= nil then
		if list[faction][nickname] ~= nil then
			sampAddChatMessage("[Внимание] Подключился " .. list[faction][nickname] .. " " .. nickname .. "[" .. playerId .. "]", 0xffe74c3c)
		end
	end
end

function sampev.onSendSpawn()
	if spawnCount == 0 then initConfig() end
	spawnCount = spawnCount + 1
end
