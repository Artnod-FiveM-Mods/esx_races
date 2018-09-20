local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX                       = nil
-- zone
local alreadyInZone       = false
local lastZone            = nil
-- action
local currentAction       = nil
local currentActionMsg    = ''
local currentActionData   = {}

local solo = {
  isRegistered_Solo = false, 
  registeredRace_Solo = nil, 
  isReadyToStartRace = false, 
  raceIsStarted = false, 
  currentCheckPoint = 0, 
  lastCheckPoint = -1, 
  currentBlip = nil, 
  raceTimer = 0, 
  outTimer = 0, 
  chronoIsStarted = false, 
  outOfVehicle = true, 
  outTimeIsStarted = false,
}
local multi = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)
-- Render markers
function drawMarker(coords, zone, zoneData)
  if(GetDistanceBetweenCoords(coords, zone.x, zone.y, zone.z, true) < zoneData.DrawDistance) then
    DrawMarker(zoneData.Type, 
      zone.x, zone.y, zone.z, 
      0.0, 0.0, 0.0, 0, 0.0, 0.0, 
      zoneData.Size.x, zoneData.Size.y, zoneData.Size.z, 
      zoneData.Color.r, zoneData.Color.g, zoneData.Color.b, 
      100, false, true, 2, false, false, false, false
    )
  end
end
Citizen.CreateThread(function()
  while ESX == nil do
    Citizen.Wait(1000)
  end
  local PlayerData = ESX.GetPlayerData()
  while PlayerData.job == nil do
    Citizen.Wait(1000)
    PlayerData = ESX.GetPlayerData()
  end  
  while true do
    Citizen.Wait(0)
    local coords = GetEntityCoords(GetPlayerPed(-1))
    for k,v in pairs(Config.Zones) do
      if k == 'RegisterSolo' and Config.ZonesData.Enable then
        for kk,vv in pairs(Config.Zones.RegisterSolo) do
          drawMarker(coords, vv, Config.ZonesData)
        end
      elseif k == 'RegisterMulti' and Config.ZonesData.Enable then
        for kk,vv in pairs(Config.Zones.RegisterMulti) do
          drawMarker(coords, vv, Config.ZonesData)
        end
      elseif Config.ZonesData.Enable then
        if (PlayerData.job.name ~= 'police' and PlayerData.job.name ~= 'ambulance') or Config.AllowCopsToCollect then
          drawMarker(coords, v, Config.ZonesData)
        end
      end
    end
    -- solo starting block
    if solo.isRegistered_Solo and not solo.isReadyToStartRace and Config.StartZoneData.Enable then
      drawMarker(coords, Config.Races[solo.registeredRace_Solo].StartingBlock[1], Config.StartZoneData)
    end    
    -- multi starting block
    for i=1, #multi, 1 do
      if multi[i].initStartingBlock and not multi[i].isStart and Config.StartZoneData.Enable then
        drawMarker(coords, multi[i].startingBlock, Config.StartZoneData)
      end
    end      
  end
end)
-- Create blips
function addBlip(zone)
  local blip = AddBlipForCoord(zone.x, zone.y, zone.z)
  SetBlipSprite (blip, zone.sprite)
  SetBlipDisplay(blip, 4)
  SetBlipScale  (blip, 0.9)
  SetBlipColour (blip, zone.color)
  SetBlipAsShortRange(blip, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(zone.name)
  EndTextCommandSetBlipName(blip)
end
Citizen.CreateThread(function()
  while ESX == nil do
    Citizen.Wait(1000)
  end
  local PlayerData = ESX.GetPlayerData()
  while PlayerData.job == nil do
    Citizen.Wait(1000)
    PlayerData = ESX.GetPlayerData()
  end  
  if (PlayerData.job.name ~= 'police' and PlayerData.job.name ~= 'ambulance') or Config.AllowCopsToCollect then
  if Config.ZonesData.EnableBlip then
    for k,v in pairs(Config.Zones) do
      if k == 'RegisterSolo' then
        for kk,vv in pairs(Config.Zones.RegisterSolo) do
          addBlip(vv)
        end
      elseif k == 'RegisterMulti' then
        for kk,vv in pairs(Config.Zones.RegisterMulti) do
          addBlip(vv)
        end
      else
        addBlip(v)
      end
    end
  end
  end
end)
-- Draw HelpText
function drawMissionText(msg)
  SetTextComponentFormat('STRING')
  AddTextComponentString(msg)
  DisplayHelpTextFromStringLabel(0, 0, 0, -1)
end
-- convert time to string
function mytimeToString(mytime)
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

-- Activate menu when player is inside zone
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    -- get currentzone
    local coords      = GetEntityCoords(GetPlayerPed(-1))
    local isInMarker  = false
    local currentZone = nil
    for k,v in pairs(Config.Zones) do
      if k == 'RegisterSolo' then
        for kk,vv in pairs(Config.Zones.RegisterSolo) do
          if(GetDistanceBetweenCoords(coords, vv.x, vv.y, vv.z, true) < Config.ZonesData.Size.x * 0.75) then
            isInMarker  = true
            currentZone = kk
          end
        end
      elseif k == 'RegisterMulti' then
        for kk,vv in pairs(Config.Zones.RegisterMulti) do
          if(GetDistanceBetweenCoords(coords, vv.x, vv.y, vv.z, true) < Config.ZonesData.Size.x * 0.75) then
            isInMarker  = true
            currentZone = kk
          end
        end
      else
        if(GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < Config.ZonesData.Size.x * 0.75) then
          isInMarker  = true
          currentZone = k
        end
      end
    end
    if solo.isRegistered_Solo and not solo.isReadyToStartRace then
      local startRaceZone = Config.Races[solo.registeredRace_Solo].StartingBlock[1]
      if(GetDistanceBetweenCoords(coords, startRaceZone.x, startRaceZone.y, startRaceZone.z, true) < Config.ZonesData.Size.x * 0.75) then
        isInMarker  = true
        currentZone = 'race'
      end
    end
    for i=1, #multi, 1 do
      if multi[i].initStartingBlock and not multi[i].isReady and not multi[i].isStart then
        local startRaceZone = multi[i].startingBlock
        if(GetDistanceBetweenCoords(coords, startRaceZone.x, startRaceZone.y, startRaceZone.z, true) < Config.ZonesData.Size.x * 0.75) then
          isInMarker  = true
          currentZone = 'multi_race'
          currentActionData.multi = i
        end
      end
    end  
    -- process
    if isInMarker and not alreadyInZone then
      alreadyInZone = true
      lastZone        = currentZone
      TriggerEvent('esx_races:hasEnteredZone', currentZone)
    end
    if not isInMarker and alreadyInZone then
      alreadyInZone = false
      TriggerEvent('esx_races:hasExitedZone', lastZone)
    end
  end
end)
AddEventHandler('esx_races:hasEnteredZone', function(zone)
  local PlayerData = ESX.GetPlayerData()
  if zone == 'SoloKey' then
    if (PlayerData.job.name == 'police' or PlayerData.job.name == 'ambulance') and not Config.AllowCopsToCollect then
      return
    end
    ESX.UI.Menu.CloseAll()
    currentAction     = zone
    currentActionMsg  = _U('press_collect_solo')
    currentActionData = {}
  elseif zone == 'MultiKey' then
    if (PlayerData.job.name == 'police' or PlayerData.job.name == 'ambulance') and not Config.AllowCopsToCollect then
      return
    end
    ESX.UI.Menu.CloseAll()
    currentAction     = zone
    currentActionMsg  = _U('press_collect_multi')
    currentActionData = {}
  end
  ESX.UI.Menu.CloseAll()
  if string.sub(zone, 1, string.len('SoloListing')) == 'SoloListing' then
    currentAction     = zone
    currentActionMsg  = _U('press_solo_race_list')
    currentActionData = {}
  end
  if string.sub(zone, 1, string.len('MultiListing')) == 'MultiListing' then
    currentAction     = zone
    currentActionMsg  = _U('press_multi_race_list')
    currentActionData = {}
  end
  if zone == 'race' then
    currentAction     = zone
    currentActionMsg  = _U('press_start_race')
    currentActionData = {}
  end
  if zone == 'multi_race' then
    currentAction     = zone
    currentActionMsg  = _U('press_start_race')
  end
end)
AddEventHandler('esx_races:hasExitedZone', function(zone)
  currentAction       = nil
  currentActionMsg    = ''
  currentActionData   = {}
  ESX.UI.Menu.CloseAll()
  TriggerServerEvent('esx_races:stopCollectSoloKey')
  TriggerServerEvent('esx_races:stopCollectMultiKey')
end)
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(10)
    if currentAction ~= nil then
      SetTextComponentFormat('STRING')
      AddTextComponentString(currentActionMsg)
      DisplayHelpTextFromStringLabel(0, 0, 1, -1)
      if IsControlJustReleased(0, Keys['E']) then
        local playerPed      = GetPlayerPed(-1)
        if currentAction == 'SoloKey' then
          if IsPedInAnyVehicle(playerPed, 0) then
            TriggerEvent('esx:showNotification', _U('out_vehicle'))
          else
            TriggerServerEvent('esx_races:startCollectSoloKey')
            currentAction = nil
          end
        elseif currentAction == 'MultiKey' then
          if IsPedInAnyVehicle(playerPed, 0) then
            TriggerEvent('esx:showNotification', _U('out_vehicle'))
          else
            TriggerServerEvent('esx_races:startCollectMultiKey')
            currentAction = nil
          end
        elseif string.sub(currentAction, 1, string.len('SoloListing')) == 'SoloListing' then
          if IsPedInAnyVehicle(playerPed, 0) then
            TriggerEvent('esx:showNotification', _U('out_vehicle'))
          else
            openSoloRacesListMenu(currentAction)
            currentAction = nil
          end
        elseif string.sub(currentAction,1,string.len('MultiListing')) == 'MultiListing' then
          if IsPedInAnyVehicle(playerPed, 0) then
            TriggerEvent('esx:showNotification', _U('out_vehicle'))
          else
            TriggerServerEvent('esx_races:getMultiHomeMenu', currentAction, solo.isRegistered_Solo)
            currentAction = nil
          end
        elseif currentAction == 'race' then -- solo race
          initRaceToStart()
          currentAction = nil
        elseif currentAction == 'multi_race' then -- multi race
          waitToStart(currentActionData.multi)
          currentAction = nil
        end
      end
    end
  end
end)

-- Solo Races List Menu 
function openSoloRacesListMenu(zoneName)
  local elements = {}
  local nbElem = 0
  local tmpRace = Config.Races
  for i=1, #tmpRace, 1 do
    if(tmpRace[i].SoloRegister == zoneName) then
      table.insert(elements, {label = tmpRace[i].Name, value = tmpRace[i].Label, race = i})
      nbElem = nbElem + 1
    end
  end
  if nbElem == 0 then
    TriggerEvent('esx:showNotification', _U('no_race'))
  else
    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'SoloRacesListMenu',
      {
        title    = 'Circuits',
        align    = 'top-left',
        elements = elements
      },
      function(data, menu)
        menu.close()
        TriggerServerEvent('esx_races:getSoloRaceDetails', data.current.race, solo.isRegistered_Solo, solo.registeredRace_Solo)
      end,
      function(data, menu)
        menu.close()
        alreadyInZone = false
      end
    )
  end
end
-- Solo Race Details Menu
RegisterNetEvent('esx_races:openSoloRaceDetailsMenu')
AddEventHandler('esx_races:openSoloRaceDetailsMenu', function(elements, title, raceid)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'SoloRaceDetailsMenu',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      if data.current.count == 0 then
        TriggerEvent('esx:showNotification', _U('no_record'))
      else
        if(data.current.value == 'own') then
          menu.close()
          TriggerServerEvent('esx_races:getOwnRecord', data.current.race)
        elseif(data.current.value == 'daily') then
          menu.close()
          TriggerServerEvent('esx_races:getDailyRecord', data.current.race)
        elseif(data.current.value == 'monthly') then
          menu.close()
          TriggerServerEvent('esx_races:getMonthlyRecord', data.current.race)
        elseif(data.current.value == 'registration') then
          menu.close()
          TriggerServerEvent('esx_races:tryToRegisterSolo', solo.isRegistered_Solo, data.current.race)
        elseif(data.current.value == 'remove_register') then
          menu.close()
          solo.isRegistered_Solo   = false
          solo.registeredRace_Solo = nil
          solo.isReadyToStartRace  = false
          solo.raceIsStarted     = false
          solo.currentCheckPoint = 0
          solo.lastCheckPoint    = -1
          if DoesBlipExist(solo.currentBlip) then
            RemoveBlip(solo.currentBlip)
          end
          solo.currentBlip       = nil
          solo.raceTimer = 0
          solo.outTimer = 0
          solo.chronoIsStarted   = false
          solo.outOfVehicle      = true
          solo.outTimeIsStarted  = false
          TriggerEvent('esx:showNotification', _U('removed_register'))
          TriggerServerEvent('esx_races:getSoloRaceDetails', data.current.race, solo.isRegistered_Solo, solo.registeredRace_Solo)
        end
      end
    end, 
    function(data, menu)
      menu.close()
      openSoloRacesListMenu(Config.Races[raceid].SoloRegister)
    end
  )
end)
-- Records List Menu
RegisterNetEvent('esx_races:recordsListMenu')
AddEventHandler('esx_races:recordsListMenu', function(recordsList, recordsTitle, raceid)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'Recordslist',
    {
      title    = recordsTitle,
      align    = 'top-left',
      elements = recordsList
    }, 
    function(data, menu)
      local record_chrono = data.current.notif[1]
      local record_racer  = data.current.notif[2]
      local record_date   = data.current.notif[3]
      local record_time   = data.current.notif[4]
      TriggerEvent('esx:showNotification', _U('record_notif', record_chrono, record_racer, record_date, record_time))
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getSoloRaceDetails', raceid, solo.isRegistered_Solo, solo.registeredRace_Solo)
    end
  )
end)
-- init Solo Race To Start
RegisterNetEvent('esx_races:soloRegisterComplete')
AddEventHandler('esx_races:soloRegisterComplete', function(success, raceid, nbSoloKey)
  if success then
    solo.isRegistered_Solo = true
    solo.registeredRace_Solo = raceid
  end
  TriggerServerEvent('esx_races:getSoloRaceDetails', raceid, solo.isRegistered_Solo, solo.registeredRace_Solo)
end)
-- Run Race
function initRaceToStart()
  local playerPed      = GetPlayerPed(-1)
  local vehicle = GetVehiclePedIsIn(playerPed, 0)
  if IsPedInAnyVehicle(playerPed, 0) then
    solo.isReadyToStartRace = true
    solo.raceIsStarted = false
    drawMissionText(_U('ready_to_start'))
    PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
    FreezeEntityPosition(playerPed, true)
    FreezeEntityPosition(vehicle, true)
    -- send freezed vehicle
    TriggerServerEvent('esx_races:freezedVehicle', vehicle, true)
    Citizen.Wait(2000)
    drawMissionText(_U('race_chrono', Config.Races[solo.registeredRace_Solo].Name, '~r~00\'04~s~', solo.currentCheckPoint, #Config.Races[solo.registeredRace_Solo].Checkpoints))
    Citizen.Wait(1000)
    drawMissionText(_U('race_chrono', Config.Races[solo.registeredRace_Solo].Name, '~r~00\'03~s~', solo.currentCheckPoint, #Config.Races[solo.registeredRace_Solo].Checkpoints))
    Citizen.Wait(1000)
    drawMissionText(_U('race_chrono', Config.Races[solo.registeredRace_Solo].Name, '~r~00\'02~s~', solo.currentCheckPoint, #Config.Races[solo.registeredRace_Solo].Checkpoints))
    Citizen.Wait(1000)
    drawMissionText(_U('race_chrono', Config.Races[solo.registeredRace_Solo].Name, '~r~00\'01~s~', solo.currentCheckPoint, #Config.Races[solo.registeredRace_Solo].Checkpoints))
    Citizen.Wait(1000)
    solo.raceIsStarted     = true
    solo.isRegistered_Solo = false  
    solo.raceTimer = GetGameTimer()
    FreezeEntityPosition(playerPed, false)
    FreezeEntityPosition(vehicle, false)
    -- send unfreezed vehicle
    TriggerServerEvent('esx_races:freezedVehicle', vehicle, false)
    PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
  else
    TriggerEvent('esx:showNotification', _U('in_vehicle'))
  end
end
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(10)
    if solo.raceIsStarted then 
      solo.isReadyToStartRace = false
    end
    if solo.isReadyToStartRace or solo.raceIsStarted then
      local playerPed      = GetPlayerPed(-1)
      local coords         = GetEntityCoords(playerPed)
      local vehicle = GetVehiclePedIsIn(playerPed, 0)
      local nextCheckPoint = solo.currentCheckPoint + 1
      local tmpCheckpoint = Config.Races[solo.registeredRace_Solo].Checkpoints[nextCheckPoint]
      
      if tmpCheckpoint ~= nil then
        local distance = GetDistanceBetweenCoords(coords, tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z, true)
        -- change blip when checkpoint change
        if solo.currentCheckPoint ~= solo.lastCheckPoint and Config.CheckpointsData.EnableBlip then
          if solo.currentCheckPoint > 0 then
            if DoesBlipExist(solo.currentBlip) then
              RemoveBlip(solo.currentBlip)
            end
            solo.currentBlip = AddBlipForCoord(tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z)
            SetBlipColour(solo.currentBlip, Config.CheckpointsData.BlipColor)
            SetBlipRoute(solo.currentBlip, 1)
            solo.lastCheckPoint = solo.currentCheckPoint
          end
        end
        -- draw marker for next checkpoint
        if distance <= Config.CheckpointsData.DrawDistance and Config.CheckpointsData.Enable  then
          DrawMarker(Config.CheckpointsData.Type, 
            tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z, 
            0.0, 0.0, 0.0, 0, 0.0, 0.0, 
            Config.CheckpointsData.Size.x, Config.CheckpointsData.Size.y, Config.CheckpointsData.Size.z, 
            Config.CheckpointsData.Color.r, Config.CheckpointsData.Color.g, Config.CheckpointsData.Color.b, 
            100, false, true, 2, false, false, false, false
          )
        end
        -- out of vehicle detection
        if IsPedInAnyVehicle(playerPed, 0) then
          solo.outOfVehicle = false
          solo.outTimeIsStarted = false
        else
          solo.outOfVehicle = true
        end
        -- passing in next checkpoint
        if distance <= (Config.CheckpointsData.Size.x * 0.75) then
          if not solo.outOfVehicle then
            solo.currentCheckPoint = solo.currentCheckPoint + 1
            PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
          else
            TriggerEvent('esx:showNotification', _U('in_vehicle'))
          end
        end
        -- show race info
        if solo.outTimeIsStarted and solo.raceIsStarted then
          drawMissionText(_U('race_in_vehicle', mytimeToString(Config.CheckpointsData.OutTime - (GetGameTimer() - solo.outTimer))))
        elseif not solo.outTimeIsStarted and solo.raceIsStarted then
          drawMissionText(_U('race_chrono', 
              Config.Races[solo.registeredRace_Solo].Name, 
              mytimeToString(GetGameTimer() - solo.raceTimer), 
              solo.currentCheckPoint, 
              #Config.Races[solo.registeredRace_Solo].Checkpoints
            )
          )
        end
        -- out of vehicle process
        if solo.outOfVehicle and not solo.outTimeIsStarted then
          solo.outTimeIsStarted = true
          solo.outTimer = GetGameTimer()
        elseif solo.outOfVehicle and solo.outTimeIsStarted then
          if (GetGameTimer() - solo.outTimer) >= Config.CheckpointsData.OutTime then
            looseRace()
          end
        end
      else
        if DoesBlipExist(solo.currentBlip) then
          RemoveBlip(solo.currentBlip)
        end
        endRace()
      end
    end
  end
end)
function endRace()
  local record = GetGameTimer() - solo.raceTimer
  TriggerServerEvent('esx_races:saveRace',record , solo.registeredRace_Solo, GetVehicleClass(GetVehiclePedIsIn(GetPlayerPed(-1), false)))
  drawMissionText(_U('race_chrono', Config.Races[solo.registeredRace_Solo].Name, mytimeToString(record), solo.currentCheckPoint, #Config.Races[solo.registeredRace_Solo].Checkpoints))
  -- clear var
  solo.isRegistered_Solo   = false
  solo.registeredRace_Solo = nil
  solo.isReadyToStartRace  = false
  solo.raceIsStarted       = false
  solo.currentCheckPoint   = 0
  solo.lastCheckPoint      = -1
  if DoesBlipExist(solo.currentBlip) then
    RemoveBlip(solo.currentBlip)
  end
  solo.currentBlip         = nil
  solo.raceTimer           = 0
  solo.outTimer            = 0
  solo.chronoIsStarted     = false
  solo.outOfVehicle        = true
  solo.outTimeIsStarted    = false
end
function looseRace()
  drawMissionText(_U('race_loose'))
  -- clear var
  solo.isRegistered_Solo   = false
  solo.registeredRace_Solo = nil
  solo.isReadyToStartRace  = false
  solo.raceIsStarted     = false
  solo.currentCheckPoint = 0
  solo.lastCheckPoint    = -1
  if DoesBlipExist(solo.currentBlip) then
    RemoveBlip(solo.currentBlip)
  end
  solo.currentBlip       = nil
  solo.raceTimer = 0
  solo.outTimer = 0
  solo.chronoIsStarted   = false
  solo.outOfVehicle      = true
  solo.outTimeIsStarted  = false
end

-- Multi Home Menu
RegisterNetEvent('esx_races:openMultiHomeMenu')
AddEventHandler('esx_races:openMultiHomeMenu', function(elements, title)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'MultiHomeMenu',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      if data.current.value == 'ranking' then
        menu.close()
        TriggerServerEvent('esx_races:getMultiRankingList', data.current.zone)
      end
      if data.current.value == 'create_race' then
        menu.close()
        TriggerServerEvent('esx_races:getCreateRace', data.current.zone)
      end
      if data.current.value == 'edit_race' then
        menu.close()
        TriggerServerEvent('esx_races:getManageRace', data.current.createdrace)
      end
      if data.current.value == 'registration' then
        menu.close()
        TriggerServerEvent('esx_races:getRegisterMultiList', data.current.zone)
      end
      if data.current.value == 'show_registration' then
        menu.close()
        TriggerServerEvent('esx_races:getRegistrationDetails', data.current.createdrace)
      end
    end, 
    function(data, menu)
      menu.close()
      alreadyInZone = false
    end
  )
end)
-- Multi Ranking Menu (perso,liste des cuircuit)
RegisterNetEvent('esx_races:openMultiRankingMenu')
AddEventHandler('esx_races:openMultiRankingMenu', function(elements, title, zone)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'MultiRankingMenu',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      if data.current.count == 0 then
        TriggerEvent('esx:showNotification', _U('no_record'))
      else
        if data.current.value == 'own_record' then
          menu.close()
          TriggerServerEvent('esx_races:getMultiOwnRacesList', zone)
        end
        if data.current.value == 'race' then
          menu.close()
          TriggerServerEvent('esx_races:getMultiRacesList', data.current.race, zone)
        end
      end
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getMultiHomeMenu', zone)
    end
  )
end)
-- Multi Own Record List
RegisterNetEvent('esx_races:openMultiOwnRacesList')
AddEventHandler('esx_races:openMultiOwnRacesList', function(elements, title, zone)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'MultiOwnRacesList',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      if data.current.count > 0 then
        menu.close()
        TriggerServerEvent('esx_races:getMultiOwnRaceRecords', data.current.race, zone)
      else
        TriggerEvent('esx:showNotification', _U('no_record'))
      end
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getMultiRankingList', zone)
    end
  )
end)
RegisterNetEvent('esx_races:openMultiOwnRaceRecords')
AddEventHandler('esx_races:openMultiOwnRaceRecords', function(elements, title, zone)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'MultiOwnRaceRecords',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      local record      = data.current.notif[1]
      local average     = data.current.notif[2]
      local racer       = data.current.notif[3]
      local record_date = data.current.notif[4]
      local record_time = data.current.notif[5]
      TriggerEvent('esx:showNotification', _U('multi_record_notif', record, average, racer, record_date, record_time))
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getMultiOwnRacesList', zone)
    end
  )
end)
-- Multi Record List
RegisterNetEvent('esx_races:openMultiRankingRaceMenu')
AddEventHandler('esx_races:openMultiRankingRaceMenu', function(elements, title, zone)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'MultiRanking',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      TriggerServerEvent('esx_races:getMultiRaceDetails', data.current.race, zone)
      menu.close()
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getMultiRankingList', zone)
    end
  )
end)
RegisterNetEvent('esx_races:recordsListMultiMenu')
AddEventHandler('esx_races:recordsListMultiMenu', function(recordsList, recordsTitle, zone, race)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'RecordslistMulti',
    {
      title    = recordsTitle,
      align    = 'top-left',
      elements = recordsList
    }, 
    function(data, menu)
      local record      = data.current.notif[1]
      local average     = data.current.notif[2]
      local racer       = data.current.notif[3]
      local record_date = data.current.notif[4]
      local record_time = data.current.notif[5]
      TriggerEvent('esx:showNotification', _U('multi_record_notif', record, average, racer, record_date, record_time))
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getMultiRacesList', race, zone)
    end
  )
end)
-- Select created race for registration
RegisterNetEvent('esx_races:openSelectRegistrationMenu')
AddEventHandler('esx_races:openSelectRegistrationMenu', function(elements, title, zone)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'SelectRegistration',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:tryToRegisterMulti', data.current.value, solo.isRegistered_Solo)
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getMultiHomeMenu', zone)
    end
  )
end)
RegisterNetEvent('esx_races:openRegistrationDetailsMenu')
AddEventHandler('esx_races:openRegistrationDetailsMenu', function(elements, title, zone)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'RegistrationDetails',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      if data.current.value == 'remove_register' then
        menu.close()
        TriggerServerEvent('esx_races:removeRegistration', data.current.race)
        TriggerServerEvent('esx_races:getMultiHomeMenu', zone)
        --
        local tmpTable = {}
        for i=1, #multi, 1 do
          if multi[i].createdRace ~= data.current.race then
            table.insert(tmpTable, multi[i])
          end
        end
        multi = tmpTable
      end
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getMultiHomeMenu', zone)
    end
  )
end)
RegisterNetEvent('esx_races:multiRegisterComplete')
AddEventHandler('esx_races:multiRegisterComplete', function(nbMultiKey, zoneName)
  TriggerServerEvent('esx_races:getMultiHomeMenu', zoneName)
end)
-- Manage Race Menu
RegisterNetEvent('esx_races:openManageRaceMenu')
AddEventHandler('esx_races:openManageRaceMenu', function(elements, title, zone)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'ManageRace',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      if data.current.value == 'remove_multi' then
        menu.close()
        TriggerServerEvent('esx_races:removeRace', data.current.createdrace)
        TriggerServerEvent('esx_races:getMultiHomeMenu', zone)
        local tmpTable = {}
        for i=1, #multi, 1 do
          if multi[i].createdRace ~= data.current.createdrace then
            table.insert(tmpTable,multi[i])
          else
            if DoesBlipExist(multi[i].currentBlip) then
              RemoveBlip(multi[i].currentBlip)
            end
          end 
        end
        multi = tmpTable
      end
      if data.current.value == 'id_race' then
        TriggerServerEvent('esx_races:getRacesList', data.current.createdrace)
        menu.close()
      end
      if data.current.value == 'register_open' then
        TriggerServerEvent('esx_races:changeRaceRegisterOpen', data.current.createdrace)
        menu.close()
      end
      if data.current.value == 'ready_to_start' then
        TriggerServerEvent('esx_races:changeRaceReadyToStart', data.current.createdrace)
        menu.close()
      end
      if data.current.value == 'nb_laps' or data.current.value == 'nb_pers'then
        local menuName = ''
        local title = ''
        if data.current.value == 'nb_laps' then
          menuName = 'change_nb_laps'
          title = _U('multi_change_laps_title')
        else
          menuName = 'change_nb_pers'
          title = _U('multi_change_pers_title')
        end
        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), menuName,
          {
            title = title,
            value = data.current.count
          },
          function(data2, menu2)
            local quantity = tonumber(data2.value)
            if quantity == nil then
              ESX.ShowNotification(_U('multi_change_fail'))
            else
              if data.current.value == 'nb_laps' then
                TriggerServerEvent('esx_races:changeRaceLaps', data.current.createdrace, quantity)
              else
                TriggerServerEvent('esx_races:changeRacePers', data.current.createdrace, quantity)
              end
            end
            menu2.close()
            menu.close()
          end,
          function(data2, menu2)
            menu2.close()
          end
        )
      end
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getMultiHomeMenu', zone)
    end
  )
end)
RegisterNetEvent('esx_races:openSelectRaceMenu')
AddEventHandler('esx_races:openSelectRaceMenu', function(elements, title, createdrace)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'SelectRace',
    {
      title    = title,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      TriggerServerEvent('esx_races:changeRaceIdRace', data.current.createdrace, data.current.value)
      menu.close()
    end, 
    function(data, menu)
      menu.close()
      TriggerServerEvent('esx_races:getManageRace', createdrace)
    end
  )
end)
-- Multi Starting Block
RegisterNetEvent('esx_races:initStartingBlock')
AddEventHandler('esx_races:initStartingBlock', function(startingBlock, createdRace)
  ESX.ShowNotification(_U('multi_ready_to_start'))
  table.insert(multi, {
    initStartingBlock = true, 
    startingBlock = startingBlock, 
    createdRace = createdRace,
    isReady = false,
    isStart = false,
    vehicle = nil
  })
end)
function waitToStart(multiId)
  local playerPed      = GetPlayerPed(-1)
  if IsPedInAnyVehicle(playerPed, 0) then
    local vehicle = GetVehiclePedIsIn(playerPed, 0)
    multi[multiId].isReady = true
    multi[multiId].vehicle = vehicle
    FreezeEntityPosition(vehicle, true)
    TriggerServerEvent('esx_races:freezedVehicle', vehicle, true)
    TriggerEvent('esx:showNotification', _U('multi_wait_to_start'))
    TriggerServerEvent('esx_races:setReadyToStart', multi[multiId].createdRace)
  else
    TriggerEvent('esx:showNotification', _U('in_vehicle'))
  end
end
RegisterNetEvent('esx_races:stopStartingBlock')
AddEventHandler('esx_races:stopStartingBlock', function(createdRace)
  local newlist = {}
  for i=1, #multi, 1 do
    -- unfreeze player and vehicle
    if multi[i].createdRace == createdRace and multi[i].isReady then
      local playerPed      = GetPlayerPed(-1)
      drawMissionText(_U('report_to_start'))
      PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
      FreezeEntityPosition(multi[i].vehicle, false)
      TriggerServerEvent('esx_races:freezedVehicle', multi[i].vehicle, false)
    end
    -- remove starting block etc
    if multi[i].createdRace ~= createdRace then
      table.insert(newlist, multi[i])
    end
  end
  multi = newlist
end)
-- Multi Start Race
RegisterNetEvent('esx_races:startMultiRace')
AddEventHandler('esx_races:startMultiRace', function(createdRace, checkpointsList, raceName, myPos, nbPers, nbLaps)
  ESX.ShowNotification(_U('multi_race_start'))
  for i=1, #multi, 1 do
    if multi[i].createdRace == createdRace then
      multi[i].checkpoints       = checkpointsList
      multi[i].raceName          = raceName
      multi[i].currentCheckPoint = 0
      multi[i].lastCheckPoint    = -1
      multi[i].currentBlip       = nil
      multi[i].raceTimer         = 0
      multi[i].outTimer          = 0
      multi[i].myPos             = myPos
      multi[i].maxPos            = nbPers
      multi[i].nbLaps            = nbLaps
      multi[i].currentLap        = 0
      multi[i].isStart           = true
      drawMissionText(_U('ready_to_start'))
      PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
      Citizen.Wait(2000)
      drawMissionText(_U('multi_race_chrono', raceName, '~r~00\'04\'\'000~s~', 1, multi[i].nbLaps, multi[i].myPos, multi[i].maxPos))
      Citizen.Wait(1000)
      drawMissionText(_U('multi_race_chrono', raceName, '~r~00\'03\'\'000~s~', 1, multi[i].nbLaps, multi[i].myPos, multi[i].maxPos))
      Citizen.Wait(1000)
      drawMissionText(_U('multi_race_chrono', raceName, '~r~00\'02\'\'000~s~', 1, multi[i].nbLaps, multi[i].myPos, multi[i].maxPos))
      Citizen.Wait(1000)
      drawMissionText(_U('multi_race_chrono', raceName, '~r~00\'01\'\'000~s~', 1, multi[i].nbLaps, multi[i].myPos, multi[i].maxPos))
      Citizen.Wait(1000)
      FreezeEntityPosition(multi[i].vehicle, false)
      multi[i].raceTimer = GetGameTimer()
      multi[i].isReady = false
      PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
    end
  end
end)
Citizen.CreateThread(function()
  local updated = false
  while true do
    Citizen.Wait(10)
    local currentRace = {}
    local currentRaceId = 0
    for i=1, #multi, 1 do
      if multi[i].isStart then
        currentRace = multi[i]
        currentRaceId = i
      end
    end
    if currentRace.isStart then
      local playerPed      = GetPlayerPed(-1)
      local coords         = GetEntityCoords(playerPed)
      local vehicle        = GetVehiclePedIsIn(playerPed, 0)
      local nextCheckPoint = currentRace.currentCheckPoint + 1
      local tmpCheckpoint  = currentRace.checkpoints[nextCheckPoint]
      
      if tmpCheckpoint ~= nil then
        local distance = GetDistanceBetweenCoords(coords, tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z, true)
        -- change blip when checkpoint change
        if currentRace.currentCheckPoint ~= currentRace.lastCheckPoint and Config.CheckpointsData.EnableBlip then
          if DoesBlipExist(currentRace.currentBlip) then
            RemoveBlip(currentRace.currentBlip)
          end
          currentRace.currentBlip = AddBlipForCoord(tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z)
          SetBlipColour(currentRace.currentBlip, Config.CheckpointsData.BlipColor)
          SetBlipRoute(currentRace.currentBlip, 1)
          currentRace.lastCheckPoint = currentRace.currentCheckPoint
        end
        -- draw marker for next checkpoint
        if distance <= Config.CheckpointsData.DrawDistance and Config.CheckpointsData.Enable then
          DrawMarker(Config.CheckpointsData.Type, 
            tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z, 
            0.0, 0.0, 0.0, 0, 0.0, 0.0, 
            Config.CheckpointsData.Size.x, Config.CheckpointsData.Size.y, Config.CheckpointsData.Size.z, 
            Config.CheckpointsData.Color.r, Config.CheckpointsData.Color.g, Config.CheckpointsData.Color.b, 
            100, false, true, 2, false, false, false, false
          )
        end
        -- out of vehicle detection
        if IsPedInAnyVehicle(playerPed, 0) then
          currentRace.outOfVehicle = false
          currentRace.outTimeIsStarted = false
        else
          currentRace.outOfVehicle = true
        end
        -- passing in next checkpoint
        local raceTime = GetGameTimer() - currentRace.raceTimer
        local outTime = GetGameTimer() - currentRace.outTimer
        if distance <= (Config.CheckpointsData.Size.x * 0.75) then
          if not currentRace.outOfVehicle then
            if tmpCheckpoint.x == currentRace.checkpoints[1].x and tmpCheckpoint.y == currentRace.checkpoints[1].y and tmpCheckpoint.z == currentRace.checkpoints[1].z then
              if multi[currentRaceId].currentLap < currentRace.nbLaps then
                multi[currentRaceId].currentLap = multi[currentRaceId].currentLap + 1
              end
            end
            currentRace.currentCheckPoint = nextCheckPoint
            TriggerServerEvent('esx_races:setMultiRacePosition', nextCheckPoint, raceTime, currentRace.createdRace)
            PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
          else
            TriggerEvent('esx:showNotification', _U('in_vehicle'))
          end
        end
        -- show race info
        if currentRace.outTimeIsStarted then
          drawMissionText(_U('race_in_vehicle', mytimeToString(Config.CheckpointsData.OutTime - outTime)))
        else
          if not currentRace.isReady then
            local tmpLap = multi[currentRaceId].currentLap
            if tmpLap == 0 then
              tmpLap = 1
            end
            drawMissionText(_U('multi_race_chrono', currentRace.raceName, mytimeToString(raceTime), tmpLap, currentRace.nbLaps, currentRace.myPos, currentRace.maxPos))
          end
        end
        -- out of vehicle process
        if currentRace.outOfVehicle and not currentRace.outTimeIsStarted then
          currentRace.outTimeIsStarted = true
          currentRace.outTimer = GetGameTimer()
        elseif currentRace.outOfVehicle and currentRace.outTimeIsStarted then
          if outTime >= Config.CheckpointsData.OutTime then
            looseMultiRace(currentRaceId)
          end
        end
      
      else
        if DoesBlipExist(currentRace.currentBlip) then
          RemoveBlip(currentRace.currentBlip)
        end
        endMultiRace(currentRaceId)
      end
    end
  end
end)
function endMultiRace(currentRaceId)
  local currentRace = multi[currentRaceId]
  local record = GetGameTimer() - currentRace.raceTimer
  drawMissionText(_U('multi_race_chrono', currentRace.raceName, mytimeToString(record), currentRace.currentLap, currentRace.nbLaps, currentRace.myPos, currentRace.maxPos))
  if DoesBlipExist(currentRace.currentBlip) then
    RemoveBlip(currentRace.currentBlip)
  end
  multi[currentRaceId] = nil
  TriggerServerEvent('esx_races:setMultiRaceEnded', record, GetVehicleClass(GetVehiclePedIsIn(GetPlayerPed(-1), false)), currentRace.createdRace)
end
function looseMultiRace(currentRaceId)
  local currentRace = multi[currentRaceId]
  local record = GetGameTimer() - currentRace.raceTimer
  drawMissionText(_U('race_loose'))
  if DoesBlipExist(currentRace.currentBlip) then
    RemoveBlip(currentRace.currentBlip)
  end
  multi[currentRaceId] = nil
  TriggerServerEvent('esx_races:setMultiRaceFailed', record, currentRace.createdRace)
end
-- Multi Race Position
RegisterNetEvent('esx_races:getMultiRacePosition')
AddEventHandler('esx_races:getMultiRacePosition', function(myPos, maxPos, createdRace)
  for i=1, #multi, 1 do
    if multi[i].createdRace == createdRace then
      multi[i].myPos  = myPos
      multi[i].maxPos = maxPos
      break
    end
  end
end)


RegisterNetEvent('esx_races:unfreezedVehicle')
AddEventHandler('esx_races:unfreezedVehicle', function(vehicle)
  FreezeEntityPosition(vehicle, false)
end)


Citizen.CreateThread(function()
  while true do
    Citizen.Wait(5000)
    local playerPed = GetPlayerPed(-1)
    local coords = GetEntityCoords(playerPed)
    print(coords)
  end
end)


