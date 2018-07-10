ESX                             = nil
local isCollectingSoloKey       = {}
local quitDuringCollectSoloKey  = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- return number of cops
function nbCops()
  local xPlayers = ESX.GetPlayers()
  copsConnected = 0
  for i=1, #xPlayers, 1 do
    local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
    if xPlayer.job.name == 'police' then
      copsConnected = copsConnected + 1
    end
  end
  return copsConnected
end

-- convert string to secure string
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

-- convert time to string
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

-- collect solo key
local function collectSoloKey(source)
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

-- register solo key
RegisterServerEvent('esx_races:tryToRegisterSolo')
AddEventHandler('esx_races:tryToRegisterSolo', function(isRegistered, raceid)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local solokey = xPlayer.getInventoryItem('solo_key').count
  local copsConnected = nbCops()
  
  local success = false
  local newSoloKey = solokey
  
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

-- return item
RegisterServerEvent('esx_races:getUserInventory')
AddEventHandler('esx_races:getUserInventory', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	TriggerClientEvent('esx_races:returnInventory', 
		_source, 
		xPlayer.getInventoryItem('solo_key').count,
		xPlayer.job.name
	)
end)

-- save record
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

-- return own record
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
  if nbLine == 0 then
    TriggerClientEvent('esx:showNotification', _source, _U('no_record'))
  else
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
    TriggerClientEvent('esx_races:recordsListMenu', _source, elements, title)
  end
end)

-- return daily record
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
  if nbLine == 0 then
    TriggerClientEvent('esx:showNotification', _source, _U('no_record'))
  else
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
    TriggerClientEvent('esx_races:recordsListMenu', _source, elements, title)
  end
end)

-- return monthly record
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
  if nbLine == 0 then
    TriggerClientEvent('esx:showNotification', _source, _U('no_record'))
  else
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
    TriggerClientEvent('esx_races:recordsListMenu', _source, elements, title)
  end
end)