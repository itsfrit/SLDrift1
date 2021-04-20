local database = require "luasql.sqlite3"
local md5 = require "md5"
print(md5.sumhexa('123123'))

env = assert(database.sqlite3())

con = assert(env:connect("srp.db"))

local spawns = {{-1411.1115,-297.7862,14.1484,118.7103}, {2088.0974,1165.6863,10.8130,53.9443}, {1129.8339,-1418.2229,13.5990,359.9206}}

function onGamemodeInit()
	print("MOD ZAPUSTILSA")
	setTime(12); setWeather(24)
end

function onPlayerConnect(playerid)
	local pointer = getPlayerPointer(playerid)
	pointer:sendMessage(0x19a0e3FF, "Приветствуем вас на сервер SL Drift! Для продолжения следуйте указаниям сервера!")
	pointer:toggleSpectating(true)
	pointer:setWorld(228)
	pointer:setCameraPosition(150, 150, 150)
	pointer:setCameraLookAt(200, 150, 150)
	pointer:toggleControllable(false)

	cur = assert(con:execute("SELECT * FROM players WHERE nickname='"..pointer:getNickname().."'"))
	print("SELECT * FROM players WHERE nickname='"..pointer:getNickname().."'")

	row = cur:fetch ({}, "a")

	if row then
		pointer:setVar('password', row.password)
		print(row)
		pointer:showDialog(1, "Авторизация", "Здравствуйте! Вы уже зарегистрированы на нашем сервере!\nДля продолжения введите ваш пароль, который вы указывали при регистрации аккаунта", "Принять", "Отмена", 2)
	else
		pointer:showDialog(2, "Регистрация", "Здравствуйте! Вы не зарегистрированы на нашем сервере!\nДля начала игры придумайте пароль, он поможет защитить ваш аккаунт.", "Принять", "Отмена", 2)
	end

	cur:close()
	pointer:sendMessage(0x19a0e3FF, "[INFO] {FFFFFF}На сервер зашёл: " .. pointer:getNickname())

end

function onPlayerDisconnect(playerid, reason)

end

function onPlayerText(playerid, message)
	local pointer = getPlayerPointer(playerid)
	if not pointer:getVar('auth') then
		return true
	end
end

function onPlayerCommand(playerid, command)
	local pointer = getPlayerPointer(playerid)
	if pointer:getVar('auth') then
		if command == "/help" then
			pointer:showDialog(3, "Информация", "Доступные команды на сервере:\n\n1. /help\tинформация о доступных командах\n2. /createveh\tсоздать автомобиль\n3. /driftscore\tвключить счётчик drift\n4. /pm\tсообщение игроку\n\nМод находится в разработке! О всех найденных багах сообщайте по контактам ниже\n\n\nКонтакты:\nTelegram\t@FritRose\nVK\t@eowidzmxncfrit", "Принять", "Отмена", 3)
		elseif command == "/createveh" then
			pointer:showDialog(4, "Создание авто", "Введите ID автомобиля, который вы хотите создать", "Принять", "Отмена", 1)
		elseif command == "/driftscore" then
			pointer:setVar('dscore', not pointer:getVar('dscore'))
			pointer:sendMessage(0xFFFFFFFF, "Счётчик дрифта " .. (pointer:getVar('dscore') and '{45d624}Включен{FFFFFF}' or '{d62424}Выключен{FFFFFF}'))
		elseif command:find("/pm") then
			if command:match("/pm (%d+) (.+)") then
				local pm_pointer = getPlayerPointer(tonumber(command:match("/pm (%d+)")))
				if pm_pointer and pm_pointer:isConnected() and pm_pointer:getVar('auth') then
					if tonumber(command:match("/pm (%d+)")) ~= playerid then
						pointer:sendMessage(0xf5e216FF, "[PM] Игроку "..pm_pointer:getNickname()..": " .. command:match("/pm %d+ (.+)"))
						pm_pointer:sendMessage(0xf5e216FF, "[PM] "..pointer:getNickname().." | Входящее: " .. command:match("/pm %d+ (.+)"))
					else
						pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Нельзя отправить PM самому себе!")
					end
				else
					pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Игрока не существует!")
				end
			else
				pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Неправильное использование команды! Пример: /pm 1 Привет.")
			end
		elseif command:find("/tpto") then
			if command:match("/tpto (%d+)") then 
				local tp_pointer = getPlayerPointer(tonumber(command:match("/tpto (%d+)")))
				if tp_pointer and tp_pointer:isConnected() and tp_pointer:getVar('auth') then
					pointer:setPosition(tp_pointer:getPosition())
				else
					pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Игрока не существует!")
				end
			else
				pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Неправильное использование команды! Пример: /tpto 1.")
			end

		elseif command == "/time" then
			pointer:sendMessage(0x19a0e3FF, "[INFO] {FFFFFF}Время на нашем сервере: " .. os.date("%H:%M:%S"))
		elseif command:find("/cinvite") then
			if command:match("/cinvite (%d+)") then
				if pointer:getVar('clan') then
					if pointer:getVar('clan_level') > 1 then
						local ci_pointer = getPlayerPointer(tonumber(command:match("/cinvite (%d+)")))
						if ci_pointer and ci_pointer:isConnected() and ci_pointer:getVar('auth') then
							if tonumber(command:match("/cinvite (%d+)")) ~= playerid then
								if not ci_pointer:getVar('clan') then
									pointer:sendMessage(0x19a0e3FF, "[INFO] {FFFFFF}Вы отправили приглашение игроку " .. ci_pointer:getNickname())
									ci_pointer:showDialog(5, "Приглашение в " .. pointer:getVar('clan'), "Игрок " .. pointer:getNickname() .. "["..playerid.."] приглашает вас вступить в клан " ..pointer:getVar('clan') .. "\nВы хотите вступить в клан?" , "Да", "Нет", 3)
									ci_pointer:setVar("clan_invite", {pointer:getVar('clan'), playerid})
								else
									pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Игрок уже состоит в каком-то клане!")
								end
							else
								pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Вы не можете отправить приглашение самому себе!")
							end
						else
							pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Игрока не существует!")
						end
					else
						pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Ваше звание в клане слишком низкое!")
					end
				else
					pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Вы не состоите в клане!")
				end
			else
				pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Неправильное использование команды! Пример: /cinvite 1.")
			end

		elseif command:find("/cc") then
			if command:match("/cc (.+)") then
				if pointer:getVar('clan') then
					cur = assert(con:execute("SELECT nickname FROM players WHERE clan='"..pointer:getVar('clan').."'"))
					row = cur:fetch ({}, "a")
					while row do
						local ccto_pointer = getPlayerPointer(getIdByNickname(row.nickname))
						if ccto_pointer and ccto_pointer:isConnected() and ccto_pointer:getVar('auth') then
							ccto_pointer:sendMessage(0x9f43eaFF, pointer:getVar('clan').." | " ..pointer:getNickname() .. "["..playerid.."]: " .. command:match("/cc (.+)"))
						end
						row = cur:fetch ({}, "a")
					end
				end
			else
				pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Неправильное использование команды! Пример: /cc Привет.")
			end
		elseif command == '/cleave' then
			if pointer:getVar('clan') then
				if pointer:getVar('clan_level') ~= 3 then
					if assert(con:execute(string.format([[UPDATE players SET clan = NULL WHERE nickname = '%s']], pointer:getNickname()))) then
						pointer:sendMessage(0x19a0e3FF, "[INFO] {FFFFFF}Вы вышли из клана " .. pointer:getVar('clan'))
						pointer:setVar('clan', nil)
						pointer:setVar('clan_level', nil)
					end
				else
					pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Вы глава этого клана, вы не можете его покинуть!")
				end
			else
				pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Вы не состоите в клане!")
			end




		else pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Такой команды не существует") end

		
	

	else
		pointer:sendMessage(0xcf3634FF, "[Ошибка] {FFFFFF}Вы не авторизовались!")
	end
	return true
end

function onPlayerUpdate(playerid)
end

function onPlayerStreamIn(playerid, forplayerid)

end

function onPlayerStreamOut(playerid, forplayerid)

end

function onDialogResponse(playerid, dialogid, button, listitem, inputtext)
	local pointer = getPlayerPointer(playerid)
	
	if dialogid == 1 then
		if button == 1 then
			if md5.sumhexa(tostring(inputtext)) ~= pointer:getVar('password') then
				pointer:showDialog(1, "Авторизация", "{d62d2d}Вы ввели неверный пароль!{FFFFFF}\n Вы уже зарегистрированы на нашем сервере!\nДля продолжения введите ваш пароль, который вы указывали при регистрации аккаунта", "Принять", "Отмена", 2)
			else
				local random = math.random(1, #spawns)
				pointer:setSpawn(spawns[random][1], spawns[random][2], spawns[random][3])
				pointer:setAngle(spawns[random][4])
				pointer:setWorld(1)

				pointer:toggleSpectating(false)
				pointer:restoreCamera()
				pointer:toggleControllable(true)

				pointer:sendMessage(0x19a0e3FF, "[INFO] {FFFFFF}Вы успешно авторизовались! Для получения информации введите /help")

				pointer:setVar('auth', true)
				pointer:setVar('dscore', false)

				cur = assert(con:execute("SELECT clan FROM players WHERE nickname='"..pointer:getNickname().."'"))
				row = cur:fetch ({}, "a")
				cur:close()
				if row then
					pointer:setVar('clan', row.clan)
					cur = assert(con:execute("SELECT clan_creator FROM clans WHERE clan_name='"..row.clan.."'"))
					row = cur:fetch ({}, "a")
					cur:close()
					pointer:setVar('clan_level', 1)
					if row.clan_creator == pointer:getNickname() then
						pointer:setVar('clan_level', 3)
					end
				end

			end
		else
			pointer:showDialog(1, "Авторизация", "Вы уже зарегистрированы на нашем сервере!\nДля продолжения введите ваш пароль, который вы указывали при регистрации аккаунта", "Принять", "Отмена", 2)
		end
	elseif dialogid == 2 then	
		if button == 1 and #tostring(inputtext) > 5 and #tostring(inputtext) < 25 then
			if assert(con:execute(string.format([[INSERT INTO players(nickname, password)  VALUES ('%s', '%s')]], pointer:getNickname(), md5.sumhexa(tostring(inputtext))))) then

				pointer:sendMessage(0x19a0e3FF, "[INFO] {FFFFFF}Вы успешно зарегистрированы! Для получения информации введите /help")

				local random = math.random(1, #spawns)
				pointer:setSpawn(spawns[random][1], spawns[random][2], spawns[random][3])
				pointer:setAngle(spawns[random][4])

				pointer:setWorld(1)

				pointer:toggleSpectating(false)
				pointer:restoreCamera()
				pointer:toggleControllable(true)

				pointer:setVar('auth', true)
				pointer:setVar('dscore', false)

			end
		else
			pointer:showDialog(2, "Регистрация", "Вы не зарегистрированы на нашем сервере!\nДля начала игры придумайте пароль, он поможет защитить ваш аккаунт.", "Принять", "Отмена", 2)
		end
	elseif dialogid == 5 then
		if button == 1 then
			local invite_pointer = getPlayerPointer(pointer:getVar('clan_invite')[2])
			if invite_pointer and pointer:getVar('clan_invite') ~= nil then	
				if assert(con:execute(string.format([[UPDATE players SET clan = '%s' WHERE nickname = '%s']], pointer:getVar('clan_invite')[1], pointer:getNickname()))) then
					invite_pointer:sendMessage(0x19a0e3FF, "[INFO] {FFFFFF}Игрок " .. pointer:getNickname() .. " принял ваше приглашение!")
					pointer:sendMessage(0x19a0e3FF, "[INFO] {FFFFFF}Вы приняли приглашение в клан".. pointer:getVar('clan_invite')[1])
					pointer:setVar('clan_invite', nil)
					pointer:setVar('clan', pointer:getVar('clan_invite')[1])
					pointer:setVar('clan_level', 1)
				end
			end
		else

		end
	end
end

function onPlayerKeyStateChange(playerid, oldkeys, newkeys)

end

