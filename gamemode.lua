--server information
local server_info = {
  pm = {
    last_send_time = nil,
    wait_pms = 1.5
  },
  chat = {
    last_send_time = nil,
    wait_msg = 1.5
  },
  player_vehicle = {},
  last_coords = nil
}

--admins
local admins_list = {
  ['FritRose'] = {
    fullaccess = true,
    lvl = 5
  },
  ['ronnyevansF'] = {
    fullaccess = true,
    lvl = 5
  }
}

-- custom functions
--get id by name
function getPlayerIdByName(name)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].nickname == name then
      return SPool.sPlayers[i].playerid
    end
  end
  return false
end
--get admin info
function isPlayerAdmin(playerid)
  local nickname = getPlayerName(playerid)
  return admins_list[nickname] or false 
end
-- admin commands
local admin_commands = {
  ['a'] = {
    lvl = 1,
    desc = '�������� ��������� � �����-���',
    func = function(playerid,args)
      local msg = table.concat(args, " ", 2, #args)
      if #msg > 0 then 
        for admin_nick, admin_data in pairs(admins_list) do
          local admin_id = getPlayerIdByName(admin_nick)
          if admin_id then
            sendClientMessage(admin_id, ('[A] %s(%d): %s'):format(getPlayerName(playerid),playerid,msg), 0x28B463)
          end
        end
      else
        sendClientMessage(playerid, '(������) {ffffff}��������� /a [message]', 0xCD0000)
      end
    end
  }
}

function onGamemodeInit()
  print('��� ������� ��������!')
end

-- proc cmds
--/veh
function createCarFunction(playerid,args)
  -- if player_vehicle
  local carid, clr1, clr2 = tonumber(args[2]), tonumber(args[3]) or 1, tonumber(args[4]) or 1
  if carid and carid >= 400 and carid <= 611 then
      if server_info.player_vehicle[playerid] then
        destroyVehicle(server_info.player_vehicle[playerid])
      end
      local x,y,z = getPlayerPos(playerid)
      server_info.player_vehicle[playerid] = createVehicle(carid,x,y,z,clr1,clr2)
  else
    sendClientMessage(playerid,('{CD0000}(������) {ffffff}����������� /veh [id] [color1] [color2]!'),0xCD0000)
  end
end
--/pm
function sendPm(sendFrom,args)
  local sendToId, msg = tonumber(args[2]), table.concat(args, " ", 3, #args)
  if sendToId and #msg > 0 then
    if isPlayerConnected(sendToId) and sendFrom ~= sendToId then
      if not server_info.pm.last_send_time or os.clock() - server_info.pm.last_send_time >= server_info.pm.wait_pms then
        server_info.pm.last_send_time = os.clock()
        sendClientMessage(sendFrom,('{F4D03F}(( PM ��� %s: %s))'):format(getPlayerName(sendToId),msg),0xF4D03F)
        sendClientMessage(sendToId,('{F4D03F}(( PM �� %s: %s))'):format(getPlayerName(sendFrom),msg),0xF4D03F)
      else
        sendClientMessage(sendFrom,'{CD0000}(������) {ffffff}�� �����!',0xCD0000)
      end
    else
      sendClientMessage(sendFrom,'{CD0000}(������) {ffffff}����� �� � ���� ��� �� ������ ��������� PM ������ ����!',0xCD0000)
    end
  else
    sendClientMessage(sendFrom,('{CD0000}(������) {ffffff}����������� /pm [id] [message]!'),0xCD0000)
  end
end
function getRandomPoints()
  local points = {
    [1] = {2226.0737304688, -1155.0428466797, 25.800720214844}, 
    [2] = {2216.2485351563, -1172.2932128906, 25.7265625},
    [3] = {2230.9721679688, -1158.5150146484, 29.796875}, 
    [4] = {2227.4060058594, -1179.9633789063, 29.797086715698} 
  }
  math.randomseed(os.time() - os.clock())
  local p = points[math.random(1,#points)]  
  return p[1],p[2],p[3]
end

function getSetPlayerSkin(myid,playerid)
  if isPlayerConnected(playerid) then
    local skin = getPlayerSkin(playerid)
    if setPlayerSkin(myid, skin) then
      sendClientMessage(myid, '���� ������' .. getPlayerName(playerid) .. ' ������� ����������!', 0xF4D03F)
    end
  else
    sendClientMessage(myid,'{CD0000}(������) {ffffff}������ � ����� id ��� � ����!',0xCD0000)
  end
end

function spawnPlayer(playerid)
  if not server_info.last_coords then
    server_info.last_coords = {}
    server_info.last_coords[1],server_info.last_coords[2],server_info.last_coords[3] = getRandomPoints()
  end 
  setPlayerPos(playerid, server_info.last_coords[1],server_info.last_coords[2],server_info.last_coords[3])
end
-- ���� ����� ������������
function onPlayerConnect(playerid)
  spawnPlayer(playerid)
  setPlayerSkin(playerid,16)
  sendClientMessage(playerid,'����� ���������� �� ������ SL Drift!',0xF4D03F)
  sendClientMessageToAll(('[Join] ����� %s(%d) ����������� � �������!'):format(getPlayerName(playerid),playerid), 0xF4D03F)
end
--���� ����� ������
function onPlayerDisconnect(playerid, reason)
  server_info.last_coords[1],server_info.last_coords[2],server_info.last_coords[3] = getPlayerPos(playerid)
  sendClientMessageToAll(('{CD0000}[Quit] ����� %s(%d) ���������� �� �������!'):format(getPlayerName(playerid),playerid), 0xCD0000)
end
-- ���� ����� ������� � ���
function onPlayerChat(playerid, message)
  if not server_info.chat.last_send_time or os.clock() - server_info.chat.last_send_time >= server_info.chat.wait_msg then
    server_info.chat.last_send_time = os.clock()
    sendClientMessageToAll(('{F4D03F}[Global Chat] %s(%d): {B9C1B8}%s'):format(getPlayerName(playerid),playerid,message), 0xF4D03F)
  else
    sendClientMessage(playerid,'{CD0000}(������) {ffffff}�� �����!',0xCD0000)
  end
end
--���� ����� ������� �������
function onPlayerCommand(playerid, command)
  local args = {}
  for _arg in command:gmatch('(%S+)') do
    args[#args+1] = _arg
  end
  if args[1] == 'pm' then
    sendPm(playerid,args)
    return true
  elseif args[1] == 'veh' then
    createCarFunction(playerid,args)
    return true
  elseif args[1] == 'skin' then
    local skinid = tonumber(args[2])
    if skinid and skinid >= 0 and skinid <= 302 then
      setPlayerSkin(playerid, skinid)
    else
      sendClientMessage(playerid,'{CD0000}(������) {ffffff}������� /skin [id] (0-302)',0xCD0000)
    end
    return true
  elseif args[1] == 'admins' then
    sendClientMessage(playerid, '������ ������������� � ����: ', 0xF4D03F)
    local i = 1
    for nick, data in pairs(admins_list) do
      if getPlayerIdByName(nick) then
        sendClientMessage(playerid, i .. '. ' .. nick .. '(' .. getPlayerIdByName(nick) .. ')', 0xF4D03F)
        i = i + 1
      end
      end
      return true
    elseif args[1] == 'getskin' then
        getSetPlayerSkin(playerid, tonumber(args[2]))
      return true
  elseif admin_commands[args[1]] then
    local adata = isPlayerAdmin(playerid)
    if adata then
      local acommand = admin_commands[args[1]]
      if adata.lvl >= acommand.lvl then
        acommand.func(playerid,args)
      end
    end
    return true
  elseif args[1] == 'spawnme' then
    spawnPlayer(playerid)
    return true
  elseif args[1] == 'help' then
    sendClientMessage(playerid,'{F4D03F}��������� �������:',0xF4D03F)
    sendClientMessage(playerid,'{F4D03F}    /pm - ��������� ��������� ��������� ������',0xF4D03F)
    sendClientMessage(playerid,'{F4D03F}    /skin - ��������� ���� ����',0xF4D03F)
    sendClientMessage(playerid,'{F4D03F}    /veh - ������� ���������',0xF4D03F)
    sendClientMessage(playerid,'{F4D03F}    /spawnme - ���������� ����',0xF4D03F)
    sendClientMessage(playerid,'{F4D03F}    /admins - ������ ������������� ������',0xF4D03F)
    sendClientMessage(playerid,'{F4D03F}    /getskin - ����� ���� ������',0xF4D03F)
    return true
  end
  sendClientMessage(playerid,'{CD0000}(������) {ffffff}������� �� �������! ������ - /help',0xCD0000)
end