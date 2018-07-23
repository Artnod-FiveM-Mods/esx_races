ESX                              = nil
local isCollectingSoloKey        = {}
local quitDuringCollectSoloKey   = {}
local isCollectingMultiKey       = {}
local quitDuringCollectMultiKey  = {}

local createdMultiRace = {} -- {fxId, zone, owner, race, nbLaps, nbPers, registerOpen, readyToStart, isStart, isEnd, date, id}
local playerRegisteredMultiRace = {} -- {identifier, race, isReady, isStart, isEnded, checkPoint, raceTime}

local freezedVehicle = {} -- {identifier, vehicle}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function nbCops()
  local xPlayers = ESX.GetPlayers()
  local copsConnected = 0
  for i=1, #xPlayers, 1 do
    local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
    if xPlayer.job.name == 'police' then
      copsConnected = copsConnected + 1
    end
  end
  return copsConnected
end
function compressString(stringVar)
  local uncompressedString = stringVar
  local compressedString = ''
  local passString = ''
  for i=1, 16, 1 do
    local firstChar = string.byte(string.sub(uncompressedString, i, i))
    local lastChar = string.byte(string.sub(uncompressedString, (33-i), (33-i)))
    local tmpChar = math.floor((firstChar + lastChar)/2)
    passString = passString .. string.char(tmpChar)
  end
  for i=1, 8, 1 do
    local firstChar = string.byte(string.sub(uncompressedString, i, i))
    local lastChar = string.byte(string.sub(uncompressedString, (17-i), (17-i)))
    local tmpChar = math.floor((firstChar + lastChar)/2)
    compressedString = compressedString .. string.char(tmpChar)
  end
  return compressedString
end
function timeToString(mytime)
  local mytimeString = ''
  local milli = mytime % 1000
  local tmpTime = (mytime - milli) / 1000
  local seconde = math.floor(tmpTime % 60)
  local minute = math.floor((tmpTime - seconde) / 60)
  local tmpMilli = ''
  if milli < 100 then
    tmpMilli = '0'
  end
  if milli < 10 then
    tmpMilli = tmpMilli .. '0'
  end
  milli = tmpMilli .. milli
  if seconde < 10 then
    seconde = '0' .. seconde
  end
  if minute < 10 then
    minute = '0' .. minute
  end
  mytimeString = minute .. '\'' .. seconde .. '\'\'' .. milli
  return mytimeString
end

function getCurrentRace(fxId)
  local currentRace = {}
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      currentRace = createdMultiRace[i]
      break
    end
  end
  return currentRace
end
function getRacersFromRace(fxId)
  local racerList = {}
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId then
      table.insert(racerList, playerRegisteredMultiRace[i])
    end
  end
  return racerList
end
function removeOfflinePlayer()
  local newList = {}
  local playersList = ESX.GetPlayers()
  for i=1, #playersList, 1 do
    local tmpPlayer = ESX.GetPlayerFromId(playersList[i])
    for x=1, #playerRegisteredMultiRace, 1 do
      if playerRegisteredMultiRace[x].identifier == tmpPlayer.identifier then
        table.insert(newList, playerRegisteredMultiRace[x])
      end
    end
  end
  playerRegisteredMultiRace = newList
end
function getBestTime(identifier, race)
  local player = ESX.GetPlayerFromIdentifier(identifier)
  local request = 'SELECT record, nb_laps FROM record_multi WHERE user = MD5(\'' .. player.name .. '\') AND race = ' .. race
  local response = MySQL.Sync.fetchAll(request)
  local bestTime = 'no_record'
  for x=1, #response, 1 do
    if x == 1 then
      bestTime = response[x].record/response[x].nb_laps
    else
      if response[x].record/response[x].nb_laps < bestTime then
        bestTime = response[x].record/response[x].nb_laps
      end
    end
  end
  return bestTime
end
function getRacersOrderByBestTime(racersList)
  local racerList = racersList
  local poolPosition = {}
  for i=1, #racerList, 1 do
    if #poolPosition == 0 then
      table.insert(poolPosition, racerList[i])
    else
      if racerList[i].bestTime == 'no_record' then -- pas de meilleur temps = ajout a la fin
          table.insert(poolPosition, racerList[i])
      else
        local added = false
        for y=1, #poolPosition, 1 do
          if poolPosition[y].bestTime == 'no_record' then -- meilleur temps que pas de temps = ajout a la position
            table.insert(poolPosition, y, racerList[i])
            added = true
            break
          elseif racerList[i].bestTime < poolPosition[y].bestTime then -- meilleur temps = ajout a la position
            table.insert(poolPosition, y, racerList[i])
            added = true
            break
          end
        end
        if not added then -- plus mauvais temps = ajout a la fin
          table.insert(poolPosition, racerList[i])
        end
      end
    end
  end
  return poolPosition
end


function checkFreezedVehicle()
  local players = ESX.GetPlayers()
  for i=1, #freezedVehicle, 1 do
    freezedVehicle[i].remove = true
    for y=1, #players, 1 do
      local tmpPlayer = ESX.GetPlayerFromId(players[y])
      if freezedVehicle[i].identifier == tmpPlayer.identifier and not freezedVehicle[i].lockRemove then
        freezedVehicle[i].remove = false
        break
      end
    end
    if freezedVehicle[i].remove and not freezedVehicle[i].lockRemove then
      freezedVehicle[i].lockRemove = true
    end
  end
  for i=1, #freezedVehicle, 1 do
    if freezedVehicle[i].remove then
      if #players > 0 then
        local tmpPlayer = ESX.GetPlayerFromId(players[1])
        TriggerClientEvent('esx_races:unfreezedVehicle', tmpPlayer.source, freezedVehicle[i].vehicle)
        freezedVehicle[i] = nil
        local tmpList = {}
        for y=1, #freezedVehicle, 1 do
          if i ~= y then
            table.insert(tmpList, freezedVehicle[y])
          end
        end
        freezedVehicle = tmpList
        break
      end
    end
  end
  SetTimeout(5 * 1000, checkFreezedVehicle)
end
checkFreezedVehicle()

RegisterServerEvent('esx_races:freezedVehicle')
AddEventHandler('esx_races:freezedVehicle', function(vehicle, isFreezed)
  local xPlayer = ESX.GetPlayerFromId(source)
  if isFreezed then
    table.insert(freezedVehicle, {identifier = xPlayer.identifier, vehicle = vehicle, remove = false, lockRemove = false})
    print('Add freezed vehicle')
  else
    local tmpList = {}
    for i=1, #freezedVehicle, 1 do
      if freezedVehicle[i].identifier ~= xPlayer.identifier then
        table.insert(tmpList, freezedVehicle[y])
      end
    end
    freezedVehicle = tmpList
    print('Remove freezed vehicle')
  end
end)



-- collect solo key
function collectSoloKey(source)
  local _source = source
	SetTimeout(Config.TimeToCollectSoloKey, function()
	  if quitDuringCollectSoloKey[_source] then
      isCollectingSoloKey[_source] = false
	  end
    if isCollectingSoloKey[_source] then
      local xPlayer  = ESX.GetPlayerFromId(_source)
      local solokey = xPlayer.getInventoryItem('solo_key')
      if solokey.limit ~= -1 and solokey.count >= solokey.limit then
        TriggerClientEvent('esx:showNotification', _source, _U('inv_full_solo_key'))
      else
        xPlayer.addInventoryItem('solo_key', 1)
      end
      collectSoloKey(_source)
    end
  end)
end
RegisterServerEvent('esx_races:startCollectSoloKey')
AddEventHandler('esx_races:startCollectSoloKey', function()
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  if not isCollectingSoloKey[_source] then
    local solokey = xPlayer.getInventoryItem('solo_key')
    if solokey.limit ~= -1 and solokey.count >= solokey.limit then
      TriggerClientEvent('esx:showNotification', _source, _U('inv_full_solo_key'))
      return
    end
    local copsConnected = nbCops()
    if copsConnected < Config.RequiredCopsSolo then
      TriggerClientEvent('esx:showNotification', source, _U('act_imp_police', copsConnected, Config.RequiredCopsSolo))
      return
    end
    TriggerClientEvent('esx:showNotification', _source, _U('pickup_in_prog'))
    isCollectingSoloKey[_source]      = true
    quitDuringCollectSoloKey[_source] = false
    collectSoloKey(_source)
	end
	if quitDuringCollectSoloKey[_source] then
    TriggerClientEvent('esx:showNotification', _source, _U('pickup_retry'))
  end
end)
RegisterServerEvent('esx_races:stopCollectSoloKey')
AddEventHandler('esx_races:stopCollectSoloKey', function()
	local _source = source
	if isCollectingSoloKey[_source] then
    quitDuringCollectSoloKey[_source] = true
	end
end)
-- menu
RegisterServerEvent('esx_races:getSoloRaceDetails')
AddEventHandler('esx_races:getSoloRaceDetails', function(raceid, isRegistered_Solo, registerdRace)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local title    = Config.Races[raceid].Name
  local elements = {}
  local request = "SELECT count(*) FROM solo_race WHERE user = MD5('" .. xPlayer.name .. "') AND race = " .. raceid
  local response = MySQL.Sync.fetchScalar(request)
  table.insert(elements, {label = _U('own_stat'), value = 'own', race = raceid, count = response})
  request = "SELECT * FROM solo_race WHERE user = MD5('" .. xPlayer.name .. "') AND race = " .. raceid
  response = MySQL.Sync.fetchAll(request)
  local nbDaily = 0
  for i=1, #response, 1 do
    if (os.time() - math.floor(response[i].record_date/1000)) < 86400 then
      nbDaily = nbDaily + 1
    end
  end
  table.insert(elements, {label = _U('daily_stat'), value = 'daily', race = raceid, count = nbDaily})
  local nbMonthly = 0
  for i=1, #response, 1 do
    if (os.time() - math.floor(response[i].record_date/1000)) < (86400*30) then
      nbMonthly = nbMonthly + 1
    end
  end
  table.insert(elements, {label = _U('monthly_stat'), value = 'monthly', race = raceid, count = nbMonthly})
  local solokey = xPlayer.getInventoryItem('solo_key').count
  if solokey > 0 and not isRegistered_Solo  then
    table.insert(elements, {label = _U('registration'), value = 'registration', race = raceid, count = 1})
  end
  if isRegistered_Solo and registerdRace == raceid then
    table.insert(elements, {label = _U('remove_register'), value = 'remove_register', race = raceid, count = 1})
  end
  TriggerClientEvent('esx_races:openSoloRaceDetailsMenu', _source, elements, title, raceid)
end)
RegisterServerEvent('esx_races:tryToRegisterSolo')
AddEventHandler('esx_races:tryToRegisterSolo', function(isRegistered, raceid)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local solokey = xPlayer.getInventoryItem('solo_key').count
  local copsConnected = nbCops()
  
  local success = false
  local newSoloKey = solokey
  
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].identifier == xPlayer.identifier then
      isRegistered = true
      break
    end
  end
  if isRegistered then
    TriggerClientEvent('esx:showNotification', _source, _U('already_register'))
  elseif copsConnected < Config.RequiredCopsSolo then
    TriggerClientEvent('esx:showNotification', _source, _U('act_imp_police', copsConnected, Config.RequiredCopsSolo))
  elseif solokey < 1 then
    TriggerClientEvent('esx:showNotification', _source, _U('no_solo_key'))
    return
  else
    success = true
    newSoloKey = newSoloKey - 1
    xPlayer.removeInventoryItem('solo_key', 1)
    TriggerClientEvent('esx:showNotification', _source, _U('register_ok'))
   end
   TriggerClientEvent('esx_races:soloRegisterComplete', _source, success, raceid, newSoloKey)
end)
RegisterServerEvent('esx_races:getOwnRecord')
AddEventHandler('esx_races:getOwnRecord', function(raceid)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local request = "SELECT record, vehicle, user, record_date FROM solo_race WHERE user = MD5('" .. xPlayer.name .. "') AND race = " .. tostring(raceid) .. " ORDER BY record ASC"
  local response = MySQL.Sync.fetchAll(request)
  local nbLine = 0
  local title = _U('own_title', Config.Races[raceid].Name)
  local elements = {}
  for i=1, #response, 1 do
    nbLine = nbLine + 1
  end
  if nbLine > 0 then
    local racer_id = compressString(response[1].user)
    for i=1, #response, 1 do
      if i <= 6 then
        local record_time = timeToString(response[i].record)
        local tmpLabel = i .. ' - ' .. record_time .. ' - ' .. Config.VehicleClass[response[i].vehicle + 1]
        local tmpValue = i
        local tmpNotif = {record_time, racer_id, os.date('%Y/%m/%d', math.floor(response[i].record_date/1000)), os.date('%H:%M:%S', math.floor(response[i].record_date/1000))}
        table.insert(elements, {label = tmpLabel, value = tmpValue, notif = tmpNotif})
      end
    end
    TriggerClientEvent('esx_races:recordsListMenu', _source, elements, title, raceid)
  end
end)
RegisterServerEvent('esx_races:getDailyRecord')
AddEventHandler('esx_races:getDailyRecord', function(raceid)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local request = "SELECT record, record_date, vehicle, user FROM solo_race WHERE race = " .. tostring(raceid) .. " ORDER BY record ASC"
  local response = MySQL.Sync.fetchAll(request)
  local nbLine = 0
  local nbDaily = 0
  local title = _U('daily_title', Config.Races[raceid].Name)
  local elements = {}
  for i=1, #response, 1 do
    if (os.time() - math.floor(response[i].record_date/1000)) < 86400 then
      nbLine = nbLine + 1
    end
  end
  if nbLine > 0 then
    for i=1, #response, 1 do
      if (os.time() - math.floor(response[i].record_date/1000)) < 86400 then
        if nbDaily < 6 then
          local racer_id = compressString(response[i].user)
          local record_time = timeToString(response[i].record)
          local tmpValue = nbDaily + 1
          local tmpLabel = tmpValue .. ' - ' .. record_time .. ' - ' .. Config.VehicleClass[response[i].vehicle + 1]
          local tmpNotif = {record_time, racer_id, os.date('%Y/%m/%d', math.floor(response[i].record_date/1000)), os.date('%H:%M:%S', math.floor(response[i].record_date/1000))}
          table.insert(elements, {label = tmpLabel, value = tmpValue, notif = tmpNotif})
          nbDaily = nbDaily + 1
        end
      end    
    end
    TriggerClientEvent('esx_races:recordsListMenu', _source, elements, title, raceid)
  end
end)
RegisterServerEvent('esx_races:getMonthlyRecord')
AddEventHandler('esx_races:getMonthlyRecord', function(raceid)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local request = "SELECT record, record_date, vehicle, user FROM solo_race WHERE race = " .. tostring(raceid) .. " ORDER BY record ASC"
  local response = MySQL.Sync.fetchAll(request)
  local nbMonthly = 0
  local nbLine = 0
  local title = _U('monthly_title', Config.Races[raceid].Name)
  local elements = {}
  for i=1, #response, 1 do
    if (os.time() - math.floor(response[i].record_date/1000)) < (86400 * 30) then
      nbLine = nbLine + 1
    end
  end
  if nbLine > 0 then
    for i=1, #response, 1 do
      if (os.time() - math.floor(response[i].record_date/1000)) < (86400 * 30) then
        if nbMonthly < 6 then
          local racer_id = compressString(response[i].user)
          local record_time = timeToString(response[i].record)
          local tmpValue = nbMonthly + 1
          local tmpLabel = tmpValue .. ' - ' .. record_time .. ' - ' .. Config.VehicleClass[response[i].vehicle + 1]
          local tmpNotif = {record_time, racer_id, os.date('%Y/%m/%d', math.floor(response[i].record_date/1000)), os.date('%H:%M:%S', math.floor(response[i].record_date/1000))}
          table.insert(elements, {label = tmpLabel, value = tmpValue, notif = tmpNotif})
          nbMonthly = nbMonthly + 1
        end
      end    
    end
    TriggerClientEvent('esx_races:recordsListMenu', _source, elements, title, raceid)
  end
end)
-- save solo race
RegisterServerEvent('esx_races:saveRace')
AddEventHandler('esx_races:saveRace', function(record, raceid, vehicleClass)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local request = "SELECT count(*) FROM solo_race WHERE user = MD5('" .. xPlayer.name .. "') AND race = " .. tostring(raceid) .. " AND record <= " .. tostring(record)
  local response = MySQL.Sync.fetchScalar(request)
  if response == 0 then
    TriggerClientEvent('esx:showNotification', _source, _U('new_record', timeToString(record)))
  else
    TriggerClientEvent('esx:showNotification', _source, _U('nice_ride', timeToString(record)))
  end
  
  request = "INSERT INTO solo_race (user, record, race, vehicle, record_date) VALUES (MD5('" .. xPlayer.name .. "'), " .. tostring(record) .. ", " .. tostring(raceid) .. ", "  .. tostring(vehicleClass) .. ", NOW())"
  response = MySQL.Sync.fetchScalar(request)
end)


-- collect multi key
function collectMultiKey(source)
  local _source = source
  SetTimeout(Config.TimeToCollectMultiKey, function()
    if quitDuringCollectMultiKey[_source] then
      isCollectingMultiKey[_source] = false
    end
    if isCollectingMultiKey[_source] then
      local xPlayer  = ESX.GetPlayerFromId(_source)
      local multikey = xPlayer.getInventoryItem('multi_key')
      if multikey.limit ~= -1 and multikey.count >= multikey.limit then
        TriggerClientEvent('esx:showNotification', _source, _U('inv_full_multi_key'))
      else
        xPlayer.addInventoryItem('multi_key', 1)
      end
      collectMultiKey(_source)
    end
  end)
end
RegisterServerEvent('esx_races:startCollectMultiKey')
AddEventHandler('esx_races:startCollectMultiKey', function()
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  if not isCollectingMultiKey[_source] then
    local multikey = xPlayer.getInventoryItem('multi_key')
    if multikey.limit ~= -1 and multikey.count >= multikey.limit then
      TriggerClientEvent('esx:showNotification', _source, _U('inv_full_multi_key'))
      return
    end
    local copsConnected = nbCops()
    if copsConnected < Config.RequiredCopsSolo then
      TriggerClientEvent('esx:showNotification', source, _U('act_imp_police', copsConnected, Config.RequiredCopsSolo))
      return
    end
    TriggerClientEvent('esx:showNotification', _source, _U('pickup_in_prog'))
    isCollectingMultiKey[_source]      = true
    quitDuringCollectMultiKey[_source] = false
    collectMultiKey(_source)
  end
  if quitDuringCollectMultiKey[_source] then
    TriggerClientEvent('esx:showNotification', _source, _U('pickup_retry'))
  end
end)
RegisterServerEvent('esx_races:stopCollectMultiKey')
AddEventHandler('esx_races:stopCollectMultiKey', function()
  local _source = source
  if isCollectingMultiKey[_source] then
    quitDuringCollectMultiKey[_source] = true
  end
end)
-- return Multi Home Menu
function getRegisterLine(source, zoneName, isRegistered_Solo)
  local xPlayer = ESX.GetPlayerFromId(source)
  
  -- no multi_key
  local multikey = xPlayer.getInventoryItem('multi_key').count
  if multikey == 0 then
    return {success = false, retour = {}}
  end
  
  -- already registered
  local alreadyRegistered = isRegistered_Solo
  for i=1, #playerRegisteredMultiRace , 1 do
    if playerRegisteredMultiRace[i].identifier == xPlayer.identifier then
      alreadyRegistered = true
      local tmpRace = getCurrentRace(playerRegisteredMultiRace[i].race)
      if tmpRace.zone == zoneName then
        local tmpretour = {label = _U('show_registration'), value = 'show_registration', createdrace = tmpRace.fxId}
        return {success = true, retour = tmpretour}
      end
      break
    end
  end
  if alreadyRegistered then
    return {success = false, retour = {}}
  end
  
  -- no opened race in zone
  local openedRace = false
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].zone == zoneName and createdMultiRace[i].registerOpen then
      openedRace = true
      break
    end
  end
  if not openedRace then
    return {success = false, retour = {}}
  end
  
  -- inscription dispo
  for i=1, #createdMultiRace , 1 do
    if createdMultiRace[i].zone == zoneName and createdMultiRace[i].registerOpen then
      local tmpretour = {label = _U('registration'), value = 'registration', zone = zoneName}
      return {success = true, retour = tmpretour}
    end
  end

  return {success = false, retour = {}}
end
function getCreateLine(source, zoneName)
  local xPlayer = ESX.GetPlayerFromId(source)
  local multikey = xPlayer.getInventoryItem('multi_key').count
  local nonEndedRace = 0
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].zone == zoneName and not createdMultiRace[i].isEnd then
      nonEndedRace = nonEndedRace + 1
    end
  end
  if multikey > 0 and nonEndedRace == 0 then
    local tmpretour = {label = _U('create_race'), value = 'create_race', zone = zoneName}
    return {success = true, retour = tmpretour}
  end
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].owner == xPlayer.identifier and createdMultiRace[i].zone == zoneName and not createdMultiRace[i].isEnd then
      local tmpretour = {label = _U('edit_race'), value = 'edit_race', createdrace = createdMultiRace[i].fxId}
      return {success = true, retour = tmpretour}
    end
  end
  return {success = false, retour = {}}
end
function getHomeLine(source, zoneName, isRegistered_Solo)
  local title = _U('multi_home_title')
  local elements = {}
  table.insert(elements, {label = _U('ended_races'), value = 'ranking', zone = zoneName})
  local registerLine = getRegisterLine(source, zoneName, isRegistered_Solo)
  if registerLine.success then
    table.insert(elements, registerLine.retour)
  end
  local createLine = getCreateLine(source, zoneName)
  if createLine.success then
    table.insert(elements, createLine.retour)
  end
  TriggerClientEvent('esx_races:openMultiHomeMenu', source, elements, title)
end
RegisterServerEvent('esx_races:getMultiHomeMenu')
AddEventHandler('esx_races:getMultiHomeMenu', function(zoneName, isRegistered_Solo)
  getHomeLine(source, zoneName, isRegistered_Solo)
end)
-- return multi ranking
RegisterServerEvent('esx_races:getMultiRankingList')
AddEventHandler('esx_races:getMultiRankingList', function(zone)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local elements = {}
  local title = _U('multi_rank_title')
  -- classement perso
  local isFirstRace = true
  local sqlWhere = ''
  for i=1, #Config.Races, 1 do
    if Config.Races[i].MultiRegister == zone then
      if isFirstRace then
        isFirstRace = not isFirstRace
        sqlWhere = '( race = ' .. i
      else
        sqlWhere = sqlWhere .. ' OR race = ' .. i
      end
    end
  end
  sqlWhere = sqlWhere .. ' )'  
  local request = "SELECT count(*) FROM record_multi WHERE user = MD5('" .. xPlayer.name .. "') AND " .. sqlWhere
  local response = MySQL.Sync.fetchScalar(request)
  table.insert(elements, {label = _U('multi_rank_own'), value = 'own_record', count = response})
  -- liste des circuits
  for i=1, #Config.Races, 1 do
    if Config.Races[i].MultiRegister == zone then
      request = "SELECT count(*) FROM record_multi WHERE race = " .. i
      response = MySQL.Sync.fetchScalar(request)
      table.insert(elements, {label = Config.Races[i].Name, value = 'race', count = response, race = i})
    end
  end
  -- retourne les data
  TriggerClientEvent('esx_races:openMultiRankingMenu', _source, elements, title, zone)
end)
-- own ranking menu
RegisterServerEvent('esx_races:getMultiOwnRacesList')
AddEventHandler('esx_races:getMultiOwnRacesList', function(zone)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local elements = {}
  local title = _U('multi_rank_own') 
  for i=1, #Config.Races, 1 do
    if Config.Races[i].MultiRegister == zone then
      local request = "SELECT count(*) FROM record_multi WHERE user = MD5('" .. xPlayer.name .. "') AND race = " .. i
      local response = MySQL.Sync.fetchScalar(request)
      table.insert(elements, {label = Config.Races[i].Name, value = 'race', race = i, count = response})
    end
  end
  TriggerClientEvent('esx_races:openMultiOwnRacesList', _source, elements, title, zone)
end)
RegisterServerEvent('esx_races:getMultiOwnRaceRecords')
AddEventHandler('esx_races:getMultiOwnRaceRecords', function(race, zone)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local elements = {}
  local title = _U('multi_rank_own') .. ' - ' .. Config.Races[race].Name
  local request = "SELECT * FROM record_multi WHERE user = MD5('" .. xPlayer.name .. "') AND race = " .. race .. " ORDER BY record_date ASC"
  local response = MySQL.Sync.fetchAll(request)
  for i=1, #response, 1 do
    local req         = "SELECT nb_pers FROM multi_race WHERE id = " .. response[i].multi_race_id
    local nbPers      = MySQL.Sync.fetchScalar(req)
    local record      = timeToString(response[i].record)
    local avr         = math.floor(response[i].record/response[i].nb_laps)
    local average     = timeToString(avr)
    local racer       = compressString(response[i].user)
    local record_date = os.date('%Y-%m-%d', math.floor(response[i].record_date/1000))
    local record_time = os.date('%H:%M:%S', math.floor(response[i].record_date/1000))
    local label       = _U('multi_rank_own_race', '', response[i].nb_laps, nbPers, record, Config.VehicleClass[response[i].vehicle+1])
    local notif       = {record, average, racer, record_date, record_time}
    table.insert(elements, {label = label, value = i, notif = notif, avr = avr})
  end
  local tmpTable = {}
  for i=1, #elements, 1 do
    if i == 1 then
      table.insert(tmpTable, elements[i])
    else
      local added = false
      for x=1, #tmpTable, 1 do
        if elements[i].avr < tmpTable[x].avr then
          table.insert(tmpTable, x, elements[i])
          added = true
          break
        end
      end
      if not added then
        table.insert(tmpTable, elements[i])
      end
    end
  end
  elements = tmpTable
  for i=1, #elements, 1 do
    elements[i].label = i .. elements[i].label
  end
  TriggerClientEvent('esx_races:openMultiOwnRaceRecords', _source, elements, title, zone)
end)
-- multi ranking menu
RegisterServerEvent('esx_races:getMultiRacesList')
AddEventHandler('esx_races:getMultiRacesList', function(configRaceIdx, zone)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local elements = {}
  local title = Config.Races[configRaceIdx].Name
  -- liste des course pour un circuit
  local request = "SELECT * FROM multi_race WHERE ended = 1 AND race = " .. configRaceIdx .. " ORDER BY created_date DESC"
  local response = MySQL.Sync.fetchAll(request)
  for i=1, #response, 1 do
    local label = _U('multi_rank_race', response[i].nb_laps, response[i].nb_pers, os.date('%Y/%m/%d %H:%M:%S', math.floor(response[i].created_date/1000)))
    table.insert(elements, {label = label, value = 'race', race = response[i].id})
  end
  TriggerClientEvent('esx_races:openMultiRankingRaceMenu', _source, elements, title, zone)
end)
RegisterServerEvent('esx_races:getMultiRaceDetails')
AddEventHandler('esx_races:getMultiRaceDetails', function(race, zone)
  local elements = {}
  -- date de la course 
  local request = "SELECT * FROM multi_race WHERE id = " .. race
  local response = MySQL.Sync.fetchAll(request)
  local title = _U('multi_rank_multi_title', Config.Races[response[1].race].Name, response[1].nb_laps, response[1].nb_pers)
  -- liste des temps de la course
  local req = "SELECT * FROM record_multi WHERE multi_race_id = " .. race .. " ORDER BY record ASC"
  local resp = MySQL.Sync.fetchAll(req)
  for i=1, #resp, 1 do
    local record      = timeToString(resp[i].record)
    local average     = timeToString(math.floor(resp[i].record/resp[i].nb_laps))
    local racer       = compressString(resp[i].user)
    local record_date = os.date('%Y-%m-%d', math.floor(resp[i].record_date/1000))
    local record_time = os.date('%H:%M:%S', math.floor(resp[i].record_date/1000))
    local label       = _U('multi_rank_multi_race', i, record, Config.VehicleClass[resp[i].vehicle+1])
    local notif = {record, average, racer, record_date, record_time}
    table.insert(elements, {label = label, value = i, notif = notif})
  end
  -- retourne les data
  TriggerClientEvent('esx_races:recordsListMultiMenu', source, elements, title, zone, response[1].race)
end)
-- Create Race - return Manage Race Menu
RegisterServerEvent('esx_races:getCreateRace')
AddEventHandler('esx_races:getCreateRace', function(zoneName)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local multikey = xPlayer.getInventoryItem('multi_key').count
  for i=1, #createdMultiRace, 1 do
    if zoneName == createdMultiRace[i].zone then
      TriggerClientEvent('esx:showNotification', _source, _U('race_already_exist'))
      getHomeLine(_source, zoneName)
      return
    end
  end
  if multikey == 0 then
    TriggerClientEvent('esx:showNotification', _source, _U('no_multi_key'))
    getHomeLine(_source, zoneName)
    return
  end
  local copsConnected = nbCops()
  if copsConnected < Config.RequiredCopsMulti then
    TriggerClientEvent('esx:showNotification', source, _U('act_imp_police', copsConnected, Config.RequiredCopsSolo))
    getHomeLine(_source, zoneName)
    return
  end
  for i=1, #Config.Races, 1 do
    if Config.Races[i].MultiRegister == zoneName then
      local newRace = {
        fxId = os.time(), 
        zone = zoneName, 
        owner = xPlayer.identifier, 
        race = i, 
        nbLaps = 2, 
        nbPers = 2, 
        registerOpen = false, 
        readyToStart = false, 
        isStart = false, 
        isEnd = false, 
        date = nil, 
        id = nil
      }
      TriggerClientEvent('esx:showNotification', _source, _U('create_in_prog'))
      xPlayer.removeInventoryItem('multi_key', 1)
      table.insert(createdMultiRace, newRace)
      manageRaceData(_source, newRace.fxId)
      return
    end
  end
end)
function manageRaceData(source, fxId)
  local currentRace = getCurrentRace(fxId)
  local title = _U('multi_edit_title', Config.Races[currentRace.race].Name)
  local elements = {}
  table.insert(elements, {label = _U('multi_edit_race', Config.Races[currentRace.race].Name), value = 'id_race', createdrace = fxId})
  table.insert(elements, {label = _U('multi_edit_laps', currentRace.nbLaps), count = currentRace.nbLaps, value = 'nb_laps', createdrace = fxId})
  table.insert(elements, {label = _U('multi_edit_pers', currentRace.nbPers), count = currentRace.nbPers, value = 'nb_pers', createdrace = fxId})
  if currentRace.isStart then
    if not currentRace.isEnd then
      table.insert(elements, {label = _U('remove_multi'), value = 'remove_multi', createdrace = fxId})
    end
  else
    if currentRace.registerOpen and currentRace.readyToStart then
      table.insert(elements, {label = _U('multi_edit_registerC'), value = 'register_open', createdrace = fxId})
      table.insert(elements, {label = _U('multi_edit_readyC'), value = 'ready_to_start', createdrace = fxId})
    elseif currentRace.registerOpen and not currentRace.readyToStart then
      table.insert(elements, {label = _U('multi_edit_registerC'), value = 'register_open', createdrace = fxId})
    elseif not currentRace.registerOpen and currentRace.readyToStart then
      table.insert(elements, {label = _U('multi_edit_readyC'), value = 'ready_to_start', createdrace = fxId})
    elseif not currentRace.registerOpen and not currentRace.readyToStart then
      table.insert(elements, {label = _U('multi_edit_registerO'), value = 'register_open', createdrace = fxId})
      table.insert(elements, {label = _U('multi_edit_readyO'), value = 'ready_to_start', createdrace = fxId})
    end
  end
  TriggerClientEvent('esx_races:openManageRaceMenu', source, elements, title, currentRace.zone)
end
RegisterServerEvent('esx_races:getManageRace')
AddEventHandler('esx_races:getManageRace', function(fxId)
  manageRaceData(source, fxId)
end)
-- edit created race - return Manage Race Menu
RegisterServerEvent('esx_races:getRacesList')
AddEventHandler('esx_races:getRacesList', function(fxId)
  local currentRace = {}
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      currentRace = createdMultiRace[i]
      break
    end
  end
  local title = 'Selectionner un circuit'
  local elements = {}
  for i=1, #Config.Races, 1 do
    if Config.Races[i].MultiRegister == Config.Races[currentRace.race].MultiRegister then
      table.insert(elements, {label = Config.Races[i].Name, value = i, createdrace = fxId})
    end
  end
  TriggerClientEvent('esx_races:openSelectRaceMenu', source, elements, title, fxId)
end)
RegisterServerEvent('esx_races:changeRaceIdRace')
AddEventHandler('esx_races:changeRaceIdRace', function(fxId, raceid)
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      createdMultiRace[i].race = raceid
      break
    end
  end
  manageRaceData(source, fxId)
end)
RegisterServerEvent('esx_races:changeRaceRegisterOpen')
AddEventHandler('esx_races:changeRaceRegisterOpen', function(fxId)
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      createdMultiRace[i].registerOpen = not createdMultiRace[i].registerOpen
      if createdMultiRace[i].registerOpen then
        createdMultiRace[i].readyToStart = false
      end
      break
    end
  end
  manageRaceData(source, fxId)
end)
RegisterServerEvent('esx_races:changeRaceReadyToStart')
AddEventHandler('esx_races:changeRaceReadyToStart', function(fxId)
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      createdMultiRace[i].readyToStart = not createdMultiRace[i].readyToStart
      if createdMultiRace[i].readyToStart then
        createdMultiRace[i].registerOpen = false
        readyToStart(fxId)
      else
        reportStart(fxId)
      end
      break
    end
  end
  manageRaceData(source, fxId)
end)
RegisterServerEvent('esx_races:changeRaceLaps')
AddEventHandler('esx_races:changeRaceLaps', function(fxId, newLaps)
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      if newLaps > 0 and newLaps <= Config.MaxLaps then
        createdMultiRace[i].nbLaps = newLaps
      else
        TriggerClientEvent('esx:showNotification', source, _U('value_between', 1, Config.MaxLaps))
      end
      break
    end
  end
  manageRaceData(source, fxId)
end)
RegisterServerEvent('esx_races:changeRacePers')
AddEventHandler('esx_races:changeRacePers', function(fxId, newPers)
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      if newPers > 0 and newPers <= #Config.Races[createdMultiRace[i].race].StartingBlock then
        createdMultiRace[i].nbPers = newPers
      else
        TriggerClientEvent('esx:showNotification', source, _U('value_between', 1, #Config.Races[createdMultiRace[i].race].StartingBlock))
      end
      break
    end
  end
  manageRaceData(source, fxId)
end)
RegisterServerEvent('esx_races:removeRace')
AddEventHandler('esx_races:removeRace', function(fxId)
  local tmpTable = {}
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId ~= fxId then
      table.insert(tmpTable, createdMultiRace[i])
    else
      local request = "DELETE FROM multi_race WHERE id = " .. createdMultiRace[i].id
      local response = MySQL.Sync.fetchScalar(request)
    end
  end
  createdMultiRace = tmpTable
  tmpTable = {}
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race ~= fxId then
      table.insert(tmpTable, createdMultiRace[i])
    end
  end
  playerRegisteredMultiRace = tmpTable
end)
-- register multi race
RegisterServerEvent('esx_races:getRegisterMultiList')
AddEventHandler('esx_races:getRegisterMultiList', function(zoneName)
  local title = _U('multi_register_title')
  local elements = {}
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].zone == zoneName and createdMultiRace[i].registerOpen then
      -- recuperer nombre de participant
      local nbPers = 0
      for y=1, #playerRegisteredMultiRace, 1 do
        if playerRegisteredMultiRace[y].race == createdMultiRace[i].fxId then
          nbPers = nbPers + 1
        end
      end
      nbPers = nbPers .. '/' .. createdMultiRace[i].nbPers
      local tmpLabel = _U('multi_register_list',Config.Races[createdMultiRace[i].race].Name, createdMultiRace[i].nbLaps, nbPers)
      table.insert(elements, {label = tmpLabel, value = createdMultiRace[i].fxId})
    end
  end
  TriggerClientEvent('esx_races:openSelectRegistrationMenu', source, elements, title, zoneName)
end)
RegisterServerEvent('esx_races:tryToRegisterMulti')
AddEventHandler('esx_races:tryToRegisterMulti', function(fxId, isRegistered)
  local currentRace = getCurrentRace(fxId)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local success = true
  
  -- multi_key
  local multikey = xPlayer.getInventoryItem('multi_key').count
  if multikey < 1 then
    TriggerClientEvent('esx:showNotification', _source, _U('no_multi_key'))
    success = false
  end
  
  -- cops
  local copsConnected = nbCops()
  if copsConnected < Config.RequiredCopsSolo and success then
    TriggerClientEvent('esx:showNotification', _source, _U('act_imp_police', copsConnected, Config.RequiredCopsSolo))
    success = false
  end
  
  -- retire les participants deco
  removeOfflinePlayer()
  
  -- nombre de participants
  local nbPers = 0
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId then
      nbPers = nbPers + 1
    end
  end
  if nbPers >= currentRace.nbPers  and success then
    TriggerClientEvent('esx:showNotification', _source, _U('multi_register_full'))
    success = false
  end
  
  -- deja enregistrer
  local alreadyregister = isRegistered
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].identifier == xPlayer.identifier then
      alreadyregister = true
      break
    end
  end
  if alreadyregister and success then
    TriggerClientEvent('esx:showNotification', _source, _U('already_register'))
    success = false
  end
  
  if success then
    xPlayer.removeInventoryItem('multi_key', 1)
    TriggerClientEvent('esx:showNotification', _source, _U('multi_register_ok'))
    local newRacer = {identifier = xPlayer.identifier, race = fxId, isReady = false, isStart = false, isEnded = false, checkPoint = 0}
    table.insert(playerRegisteredMultiRace, newRacer)
  end
   
  TriggerClientEvent('esx_races:multiRegisterComplete', _source, (multikey - 1), currentRace.zone)
end)
RegisterServerEvent('esx_races:getRegistrationDetails')
AddEventHandler('esx_races:getRegistrationDetails', function(fxId)
  local tmpRace = {}
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      tmpRace = createdMultiRace[i]
      break
    end
  end
  local title = _U('multi_my_register_title')
  local elements = {}
  local nbPers = 0
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId then
      nbPers = nbPers + 1
    end
  end
  nbPers = nbPers .. '/' .. tmpRace.nbPers
  table.insert(elements, {label = _U('multi_edit_race',Config.Races[tmpRace.race].Name)})
  table.insert(elements, {label = _U('multi_edit_laps',tmpRace.nbLaps)})
  table.insert(elements, {label = _U('multi_edit_pers',nbPers)})
  if tmpRace.registerOpen then
    table.insert(elements, {label = _U('multi_register_registerO')})
  else
    table.insert(elements, {label = _U('multi_register_registerC')})
  end
  if tmpRace.readyToStart then
    table.insert(elements, {label = _U('multi_register_readyO')})
  else
    table.insert(elements, {label = _U('multi_register_readyC')})
  end
  table.insert(elements, {label = _U('remove_register'), value = 'remove_register', race = fxId})
  TriggerClientEvent('esx_races:openRegistrationDetailsMenu', source, elements, title, tmpRace.zone)
end)
RegisterServerEvent('esx_races:removeRegistration')
AddEventHandler('esx_races:removeRegistration', function(fxId)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local elements = {}
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race ~= fxId or playerRegisteredMultiRace[i].identifier ~= xPlayer.identifier then
      table.insert(elements, playerRegisteredMultiRace[i])
    end
  end
  playerRegisteredMultiRace = elements
  TriggerClientEvent('esx:showNotification', _source, _U('removed_register'))
end)
-- init startingblock
function readyToStart(fxId)
  local currentRace = getCurrentRace(fxId)
  -- retire les participants deco
  removeOfflinePlayer()
  --liste des participants
  local racerList = getRacersFromRace(fxId)
  -- recupere meilleur chrono
  for i=1, #racerList, 1 do
    local bestTime = getBestTime(racerList[i].identifier, currentRace.race)
    racerList[i].bestTime = bestTime
  end
  -- trie par chrono
  local poolPosition = getRacersOrderByBestTime(racerList)
  -- envoie aux participants
  for i=1, #poolPosition, 1 do
    local player = ESX.GetPlayerFromIdentifier(poolPosition[i].identifier)
    local playerStartingBlock = Config.Races[currentRace.race].StartingBlock[i]
    TriggerClientEvent('esx_races:initStartingBlock', player.source, playerStartingBlock, fxId)
  end
end
function reportStart(fxId)
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId then
      playerRegisteredMultiRace[i].isReady = false
      local player = ESX.GetPlayerFromIdentifier(playerRegisteredMultiRace[i].identifier)
      TriggerClientEvent('esx_races:stopStartingBlock', player.source, fxId)
    end
  end
end
-- set racer ready
RegisterServerEvent('esx_races:setReadyToStart')
AddEventHandler('esx_races:setReadyToStart', function(fxId)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId and playerRegisteredMultiRace[i].identifier == xPlayer.identifier then
      playerRegisteredMultiRace[i].isReady = true
    end
  end
  -- retire les participants deco
  removeOfflinePlayer()
  local allIsReady = true
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId and not playerRegisteredMultiRace[i].isReady then
      allIsReady = false
      break
    end
  end
  if allIsReady then
    startRace(fxId)
  end
end)
-- start multi race
function startRace(fxId)
  local currentRace = {}
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      createdMultiRace[i].isStart = true
      currentRace = createdMultiRace[i]
      break
    end
  end
  --compte le nombre de participant
  local nbPers = 0
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId then
      nbPers = nbPers + 1
    end
  end
  -- genere la liste des checkpoints
  local defaultCkecpointsList = Config.Races[currentRace.race].Checkpoints
  local newCkecpointsList = {}
  for i=1, currentRace.nbLaps, 1 do
    for y=1, #defaultCkecpointsList-1, 1 do
      table.insert(newCkecpointsList, defaultCkecpointsList[y])
    end
  end
  table.insert(newCkecpointsList, defaultCkecpointsList[#defaultCkecpointsList])
  -- lance le départ
  local tmpcount = 0
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId then
      tmpcount = tmpcount + 1
      playerRegisteredMultiRace[i].isStart = true
      local player = ESX.GetPlayerFromIdentifier(playerRegisteredMultiRace[i].identifier)
      TriggerClientEvent('esx_races:startMultiRace', player.source, fxId, newCkecpointsList, Config.Races[currentRace.race].Name, tmpcount, nbPers, currentRace.nbLaps)
    end
  end
  -- ajout race in db
  currentRace.date = os.date('%Y-%m-%d %H:%M:%S', os.time())
  local request = "INSERT INTO multi_race (owner, race, nb_laps, nb_pers, ended, created_date) VALUES ('" .. 
    currentRace.owner .. "', " .. 
    currentRace.race .. ", " .. 
    currentRace.nbLaps .. ", "  .. 
    currentRace.nbPers .. ", " .. 
    "0" .. ", '" .. 
    currentRace.date .. "')"
  local response = MySQL.Sync.fetchScalar(request)
  request = "SELECT id FROM multi_race WHERE created_date = '" .. currentRace.date .. "'"
  response = MySQL.Sync.fetchScalar(request)
  currentRace.id = response
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      createdMultiRace[i] = currentRace
      break
    end
  end
end
-- set Multi race position
function getCheckpointsList(fxId)
  local checkPointList = {}
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId then
      if #checkPointList == 0 then
        table.insert(checkPointList, playerRegisteredMultiRace[i].checkPoint)
      else
        local added = false
        for y=1, #checkPointList, 1 do
          if playerRegisteredMultiRace[i].checkPoint > checkPointList[y] then
            table.insert(checkPointList, y, playerRegisteredMultiRace[i].checkPoint)
            added = true
            break
          elseif playerRegisteredMultiRace[i].checkPoint == checkPointList[y] then
            added = true
            break
          end
        end
        if not added then
          table.insert(checkPointList, playerRegisteredMultiRace[i].checkPoint)
        end
      end
    end
  end
  return checkPointList
end
function getRacerList(fxId, ckpt)
  local racersList = {}
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId and playerRegisteredMultiRace[i].checkPoint == ckpt then
      if #racersList == 0 then
        table.insert(racersList, playerRegisteredMultiRace[i])
      else
        local added = false
        for y=1, #racersList, 1 do
          if playerRegisteredMultiRace[i].raceTime < racersList[y].raceTime then
            table.insert(racersList, y, playerRegisteredMultiRace[i])
            added = true
            break
          end
        end
        if not added then
          table.insert(racersList, playerRegisteredMultiRace[i])
        end
      end
    end
  end
  return racersList
end
RegisterServerEvent('esx_races:setMultiRacePosition')
AddEventHandler('esx_races:setMultiRacePosition', function(checkPoint, raceTime, fxId)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local currentRace = getCurrentRace(fxId)
  
  -- maj perso
  for i=1, #playerRegisteredMultiRace ,1 do
    if playerRegisteredMultiRace[i].identifier == xPlayer.identifier and playerRegisteredMultiRace[i].race == fxId then
      playerRegisteredMultiRace[i].checkPoint = checkPoint
      playerRegisteredMultiRace[i].raceTime = raceTime
    end
  end
  
  -- retire les participants deco
  removeOfflinePlayer()
  
  -- liste par checkpoint
  local newList = {}
  local checkPointList = getCheckpointsList(fxId)
  for i=1, #checkPointList, 1 do
    local racerList = getRacerList(fxId, checkPointList[i])
    for y=1, #racerList, 1 do
      table.insert(newList, racerList[y])
    end
  end
  
  -- ajout des derniers
  for i=1, #playerRegisteredMultiRace ,1 do
    if playerRegisteredMultiRace[i].race == fxId then
      local isListed = false
      for y=1, #newList, 1 do
        if playerRegisteredMultiRace[i].identifier == newList[y].identifier then
          isListed = true
          break
        end
      end
      if not isListed then
        table.insert(newList, playerRegisteredMultiRace[i])
      end
    end
  end
  
  -- envoie position a tout les participants
  local racersList = getRacersFromRace(fxId)
  for i=1, #newList, 1 do
    local racer = ESX.GetPlayerFromIdentifier(newList[i].identifier)
    TriggerClientEvent('esx_races:getMultiRacePosition', racer.source, i, #racersList, fxId)
  end
end)
-- save multi race
RegisterServerEvent('esx_races:setMultiRaceEnded')
AddEventHandler('esx_races:setMultiRaceEnded', function(record, vehicleClass, fxId)
  local currentRace = getCurrentRace(fxId)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  if record ~= -1 then
    local request = "INSERT INTO record_multi (user, race, record, vehicle, nb_laps, multi_race_id, record_date) VALUES ( MD5('" .. 
      xPlayer.name .. "'), " .. 
      currentRace.race .. ", " .. 
      record .. ", "  .. 
      vehicleClass .. ", " ..  
      currentRace.nbLaps .. ", '" .. 
      currentRace.id .. "', " .. 
      "NOW() )"
    local response = MySQL.Sync.fetchScalar(request)
    TriggerClientEvent('esx:showNotification', _source, _U('nice_ride', timeToString(record)))
  end
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].identifier == xPlayer.identifier and playerRegisteredMultiRace[i].race == fxId then
        playerRegisteredMultiRace[i].isEnded = true
        break
    end
  end
  
  -- retire les participants deco
  removeOfflinePlayer()
  
  local allIsEnd = true
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race == fxId and not playerRegisteredMultiRace[i].isEnded then
      allIsEnd = false
      break
    end
  end
  if allIsEnd then
    closeRace(fxId)
  end
end)
-- close endend multi race
function closeRace(fxId)
  local currentRace = {}
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId == fxId then
      createdMultiRace[i].isEnd = true
      currentRace = createdMultiRace[i]
      break
    end
  end
  -- clear playerRegisteredMultiRace
  local nbPers = 0
  local tmpList = {}  
  for i=1, #playerRegisteredMultiRace, 1 do
    if playerRegisteredMultiRace[i].race ~= fxId then
      table.insert(tmpList, playerRegisteredMultiRace[i])
    else
      nbPers = nbPers + 1
    end
  end
  playerRegisteredMultiRace = tmpList
  -- update db
  local request = "SELECT count(*) FROM record_multi WHERE multi_race_id = " .. currentRace.id
  local response = MySQL.Sync.fetchScalar(request)
  if response > 0 then
    request = "UPDATE multi_race SET ended = 1, nb_pers = " .. nbPers .. " WHERE id = " .. currentRace.id
    response = MySQL.Sync.fetchScalar(request)
  else
    request = "DELETE FROM multi_race WHERE id = " .. currentRace.id
    response = MySQL.Sync.fetchScalar(request)
  end
  -- clear createdMultiRace
  tmpList = {} 
  for i=1, #createdMultiRace, 1 do
    if createdMultiRace[i].fxId ~= fxId then
      table.insert(tmpList, createdMultiRace[i])
    end
  end
  createdMultiRace = tmpList
end
