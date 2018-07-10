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
-- perso
local soloQTE             = nil
local myJob               = nil
-- zone
local alreadyInZone       = false
local lastZone            = nil
-- action
local currentAction       = nil
local currentActionMsg    = ''
local currentActionData   = {}
-- solo registration
local isRegistered_Solo   = false
local registeredRace_Solo = nil
-- init race to start
local isReadyToStartRace  = false
-- race
local raceIsStarted       = false
-- checkpoint
local currentCheckPoint   = 0
local lastCheckPoint      = -1
local currentBlip         = nil
-- chrono
local raceTimer = 0
local outTimer = 0
local chronoIsStarted     = false
local outOfVehicle        = true
local outTimeIsStarted    = false

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
  while true do
    Citizen.Wait(0)
    local coords = GetEntityCoords(GetPlayerPed(-1))
    for k,v in pairs(Config.Zones) do
      if k == 'RegisterSolo' then
        for kk,vv in pairs(Config.Zones.RegisterSolo) do
          drawMarker(coords, vv, Config.ZonesData)
        end
      else
        drawMarker(coords, v, Config.ZonesData)
      end
    end
    
    if isRegistered_Solo and not isReadyToStartRace  then
      drawMarker(coords, Config.Races[registeredRace_Solo].Checkpoints[1], Config.StartZoneData)
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
  for k,v in pairs(Config.Zones) do
    if k == 'RegisterSolo' then
      for kk,vv in pairs(Config.Zones.RegisterSolo) do
        addBlip(vv)
      end
    else
      addBlip(v)
    end
  end
end)
-- Draw Subtitle Timed
function drawMissionText(msg, mytime)
  ClearPrints()
  SetTextEntry_2('STRING')
  AddTextComponentString(msg)
  DrawSubtitleTimed(mytime, 1)
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

-- refresh item and job name 
RegisterNetEvent('esx_races:returnInventory')
AddEventHandler('esx_races:returnInventory', function(soloNbr, jobName)
  soloQTE = soloNbr
  myJob   = jobName
end)

-- Activate menu when player is inside zone
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
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
      else
        if(GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < Config.ZonesData.Size.x * 0.75) then
          isInMarker  = true
          currentZone = k
        end
      end
    end
    if isRegistered_Solo and not isReadyToStartRace then
      local startRaceZone = Config.Races[registeredRace_Solo].Checkpoints[1]
      if(GetDistanceBetweenCoords(coords, startRaceZone.x, startRaceZone.y, startRaceZone.z, true) < Config.ZonesData.Size.x * 0.75) then
        isInMarker  = true
        currentZone = 'race'
      end
    end
    if isInMarker and not alreadyInZone then
      alreadyInZone = true
      lastZone        = currentZone
      TriggerServerEvent('esx_races:getUserInventory')
      TriggerEvent('esx_races:hasEnteredZone', currentZone)
    end
    if not isInMarker and alreadyInZone then
      alreadyInZone = false
      TriggerEvent('esx_races:hasExitedZone', lastZone)
    end
  end
end)
-- entree/sortie de zone
AddEventHandler('esx_races:hasEnteredZone', function(zone)
  if zone == 'SoloKey' then
    if myJob == 'police' or myJob == 'ambulance' then
      return
    end
    ESX.UI.Menu.CloseAll()
    currentAction     = zone
    currentActionMsg  = _U('press_collect_solo')
    currentActionData = {}
  end
  if zone == 'RaceListing_one' or zone == 'RaceListing_two' then
    ESX.UI.Menu.CloseAll()
    currentAction     = zone
    currentActionMsg  = _U('press_race_list')
    currentActionData = {}
  end
  if zone == 'race' then
    ESX.UI.Menu.CloseAll()
    currentAction     = zone
    currentActionMsg  = _U('press_start_race')
    currentActionData = {}
  end
end)
AddEventHandler('esx_races:hasExitedZone', function(zone)
  currentAction       = nil
  currentActionMsg    = ''
  currentActionData   = {}
  ESX.UI.Menu.CloseAll()
  TriggerServerEvent('esx_races:stopCollectSoloKey')
end)
-- Key Controls with zone
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
        elseif currentAction == 'RaceListing_one' or currentAction == 'RaceListing_two' then
          if IsPedInAnyVehicle(playerPed, 0) then
            TriggerEvent('esx:showNotification', _U('out_vehicle'))
          else
            openSoloRacesListMenu()
            currentAction = nil
          end
        elseif currentAction == 'race' then
          initRaceToStart()
          currentAction = nil
        end
      end
    end
  end
end)

-- Races List Menu 
function openSoloRacesListMenu()
  local elements = {}
  local nbElem = 0
  for i=1, #Config.Races, 1 do
    if(Config.Races[i].SoloRegister == currentAction) then
      table.insert(elements, {label = Config.Races[i].Name, value = Config.Races[i].Label, race = i})
      nbElem = nbElem + 1
    end
  end
  if nbElem == 0 then
    table.insert(elements, {label = _U('no_race'), value = 'no_race'})
  end
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'registration',
    {
      title    = 'Circuits',
      align    = 'top-left',
      elements = elements
    },
    function(data, menu)
      if data.current.value ~= 'no_race' then
        openRaceDetailsMenu(data.current.race)
      end
    end,
    function(data, menu)
      menu.close()
      alreadyInZone = false
    end
  )
end
-- Race Details Menu
function openRaceDetailsMenu(raceid)
  local title    = nil
  local elements = {}
  local raceName = Config.Races[raceid].Name
  table.insert(elements, {label = _U('own_stat'), value = 'own', race = raceid})
  table.insert(elements, {label = _U('daily_stat'), value = 'daily', race = raceid})
  table.insert(elements, {label = _U('monthly_stat'), value = 'monthly', race = raceid})
  if soloQTE >= 1 and not isRegistered_Solo then
    table.insert(elements, {label = _U('registration'), value = 'registration', race = raceid})
  end

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'registration_sub',
    {
      title    = raceName,
      align    = 'top-left',
      elements = elements
    }, 
    function(data, menu)
      if(data.current.value == 'registration') then
        TriggerServerEvent('esx_races:tryToRegisterSolo', isRegistered_Solo, data.current.race)
        menu.close()
      elseif(data.current.value == 'own') then
        TriggerServerEvent('esx_races:getOwnRecord', data.current.race)
      elseif(data.current.value == 'daily') then
        TriggerServerEvent('esx_races:getDailyRecord', data.current.race)
      elseif(data.current.value == 'monthly') then
        TriggerServerEvent('esx_races:getMonthlyRecord', data.current.race)
      end
    end, 
    function(data, menu)
      menu.close()
    end
  )
end
-- Records List Menu
RegisterNetEvent('esx_races:recordsListMenu')
AddEventHandler('esx_races:recordsListMenu', function(recordsList, recordsTitle)
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'records_list',
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
    end
  )
end)

-- init Race To Start
RegisterNetEvent('esx_races:soloRegisterComplete')
AddEventHandler('esx_races:soloRegisterComplete', function(success, raceid, nbSoloKey, menu)
  soloQTE = nbSoloKey
  if success then
    isRegistered_Solo = true
    registeredRace_Solo = raceid
  end
  openRaceDetailsMenu(raceid)
end)
function initRaceToStart()
  local playerPed      = GetPlayerPed(-1)
  if IsPedInAnyVehicle(playerPed, 0) then
    isReadyToStartRace = true
    raceIsStarted = false
  else
    TriggerEvent('esx:showNotification', _U('in_vehicle'))
  end
end

-- Run Race
function startRace()
  raceIsStarted     = true
  isRegistered_Solo = false  
  raceTimer = GetGameTimer()
end
function endRace()
  local record = GetGameTimer() - raceTimer
  TriggerServerEvent('esx_races:saveRace',record , registeredRace_Solo, GetVehicleClass(GetVehiclePedIsIn(GetPlayerPed(-1), false)))
  drawMissionText(_U('race_chrono', Config.Races[registeredRace_Solo].Name, mytimeToString(record)), 10000)
  -- clear var
  isRegistered_Solo   = false
  registeredRace_Solo = nil
  isReadyToStartRace  = false
  raceIsStarted     = false
  currentCheckPoint = 0
  lastCheckPoint    = -1
  currentBlip       = nil
  if DoesBlipExist(currentBlip) then
    RemoveBlip(currentBlip)
  end
  raceTimer = 0
  outTimer = 0
  chronoIsStarted   = false
  outOfVehicle      = true
  outTimeIsStarted  = false
end
function looseRace()
  local record_Race = registeredRace_Solo
  drawMissionText(_U('race_loose'), 10000)
  -- clear var
  isRegistered_Solo   = false
  registeredRace_Solo = nil
  isReadyToStartRace  = false
  raceIsStarted     = false
  currentCheckPoint = 0
  lastCheckPoint    = -1
  if DoesBlipExist(currentBlip) then
    RemoveBlip(currentBlip)
  end
  currentBlip       = nil
  raceTimer = 0
  outTimer = 0
  chronoIsStarted   = false
  outOfVehicle      = true
  outTimeIsStarted  = false
end
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(10)
    if raceIsStarted then 
      isReadyToStartRace = false
    end
    if isReadyToStartRace or raceIsStarted then
      local playerPed      = GetPlayerPed(-1)
      local coords         = GetEntityCoords(playerPed)
      local vehicle = GetVehiclePedIsIn(playerPed, 0)
      local nextCheckPoint = currentCheckPoint + 1
      local tmpCheckpoint = Config.Races[registeredRace_Solo].Checkpoints[nextCheckPoint]
      
      if tmpCheckpoint ~= nil then
        local distance = GetDistanceBetweenCoords(coords, tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z, true)
        -- change blip when checkpoint change
        if currentCheckPoint ~= lastCheckPoint then
          if currentCheckPoint > 0 then
            if DoesBlipExist(currentBlip) then
              RemoveBlip(currentBlip)
            end
            currentBlip = AddBlipForCoord(tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z)
            SetBlipColour(currentBlip, Config.CheckpointsData.BlipColor)
            SetBlipRoute(currentBlip, 1)
            lastCheckPoint = currentCheckPoint
          end
        end
        -- draw marker for next checkpoint
        if distance <= Config.CheckpointsData.DrawDistance then
          if currentCheckPoint > 0 then
            DrawMarker(Config.CheckpointsData.Type, 
              tmpCheckpoint.x, tmpCheckpoint.y, tmpCheckpoint.z, 
              0.0, 0.0, 0.0, 0, 0.0, 0.0, 
              Config.CheckpointsData.Size.x, Config.CheckpointsData.Size.y, Config.CheckpointsData.Size.z, 
              Config.CheckpointsData.Color.r, Config.CheckpointsData.Color.g, Config.CheckpointsData.Color.b, 
              100, false, true, 2, false, false, false, false
            )
          end
        end
        -- out of vehicle detection
        if IsPedInAnyVehicle(playerPed, 0) then
          outOfVehicle = false
          outTimeIsStarted = false
        else
          outOfVehicle = true
        end
        -- passing in next checkpoint
        if distance <= (Config.CheckpointsData.Size.x * 0.75) then
          if not outOfVehicle then
            if currentCheckPoint == 0 then-- draw marker for next checkpoint
              drawMissionText(_U('ready_to_start'), 1500)
              PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
              FreezeEntityPosition(playerPed, true)
              FreezeEntityPosition(vehicle, true)
              Citizen.Wait(2000)
              drawMissionText('~r~- 4 -~s~', 1000)
              Citizen.Wait(1000)
              drawMissionText('~r~- 3 -~s~', 1000)
              Citizen.Wait(1000)
              drawMissionText('~r~- 2 -~s~', 1000)
              Citizen.Wait(1000)
              drawMissionText('~r~- 1 -~s~', 1000)
              Citizen.Wait(1000)
              startRace()
              FreezeEntityPosition(playerPed, false)
              FreezeEntityPosition(vehicle, false)
            end
            currentCheckPoint = currentCheckPoint + 1
            PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
          else
            TriggerEvent('esx:showNotification', _U('in_vehicle'))
          end
        end
        -- show race info
        if outTimeIsStarted then
          drawMissionText(_U('race_in_vehicle', mytimeToString(Config.CheckpointsData.OutTime - (GetGameTimer() - outTimer))), 9)
        else
          drawMissionText(_U('race_chrono', Config.Races[registeredRace_Solo].Name, mytimeToString(GetGameTimer() - raceTimer)), 9)
        end
        -- out of vehicle process
        if outOfVehicle and not outTimeIsStarted then
          outTimeIsStarted = true
          outTimer = GetGameTimer()
        elseif outOfVehicle and outTimeIsStarted then
          if (GetGameTimer() - outTimer) >= Config.CheckpointsData.OutTime then
            looseRace()
          end
        end
      
      else
        if DoesBlipExist(currentBlip) then
          RemoveBlip(currentBlip)
        end
        endRace()
      end
    end
  end
end)
