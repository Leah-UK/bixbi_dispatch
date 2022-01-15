ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(10)
    end
end)

local source = GetPlayerServerId(PlayerId())
local createdBlips = {}
RegisterNetEvent('bixbi_dispatch:CreateBlip')
AddEventHandler('bixbi_dispatch:CreateBlip', function(type, isNew, coords, num)
	CreateBlip(type, isNew, coords, num)
end)
function CreateBlip(type, isNew, coords, num)
    if (coords == nil) then return end
    local blipSettings = Config.Types[type] or Config.Types['default']

    if (isNew) then
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite (blip, blipSettings.marker.sprite)
        SetBlipDisplay(blip, 6)
        SetBlipScale  (blip, blipSettings.marker.scale)
        SetBlipColour (blip, blipSettings.marker.colour)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(blipSettings.label .. ' #' .. num)
        EndTextCommandSetBlipName(blip)

        if (blipSettings.enableFlash) then
            CreateBlipFlash(blipSettings, coords, num)
        end

        createdBlips[num] = blip
    else
        SetNewWaypoint(coords.x, coords.y)
    end
end

function CreateBlipFlash(blipSettings, coords, num)
    Citizen.CreateThread(function()
        local blip = AddBlipForRadius(coords.x, coords.y, coords.z, blipSettings.marker.flashscale)

        SetBlipSprite(blip, 9)
        SetBlipDisplay(blip, 4)
        SetBlipColour(blip, blipSettings.marker.colour)
        SetBlipAlpha(blip, 200)
        SetBlipAsShortRange(blip, true)
        SetBlipFlashes(blip, true)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(blipSettings.label .. ' #' .. num)
        EndTextCommandSetBlipName(blip)

        Citizen.Wait(blipSettings.marker.flashtime * 1000)
        RemoveBlip(blip)
    end)
end

RegisterNetEvent('bixbi_dispatch:DeleteBlip')
AddEventHandler('bixbi_dispatch:DeleteBlip', function(num)
    if (createdBlips[num] == nil) then return end
	RemoveBlip(createdBlips[num])
    createdBlips[num] = nil
end)

RegisterNetEvent('bixbi_dispatch:PanicButtonClient')
AddEventHandler('bixbi_dispatch:PanicButtonClient', function()
    TriggerServerEvent('bixbi_dispatch:PanicButton')
end)
-- function DispatchMenu()
-- 	ESX.UI.Menu.CloseAll()

--     -- local itemCount = exports['bixbi_core']:itemCount(Config.RequiredItem)
--     -- while (itemCount == nil) do
--     --     Citizen.Wait(100)
--     -- end
--     -- if (itemCount == 0) then
--     --     TriggerEvent('bixbi_core:Notify', 'error', 'You must have a ' .. Config.RequiredItem .. ' to use this.')
--     --     return 
--     -- end

--     local disList = nil
--     local time = ""
--     ESX.TriggerServerCallback('bixbi_dispatch:GetList', function(response) 
--         disList = response.list
--         time = " [" .. response.time .. "]"
--     end)
--     local waitAttempts = 0
-- 	while (disList == nil and waitAttempts < 20) do
--         waitAttempts = waitAttempts + 1
--         Citizen.Wait(100)
--     end
--     if (disList == nil) then
--         TriggerEvent('bixbi_core:Notify', 'error', 'DISPATCH: There was an issue with retrieving data.')
--         return
--     end

-- 	local elements = {}
--     if (Config.Jobs[ESX.PlayerData.job.name] ~= nil and Config.Jobs[ESX.PlayerData.job.name].PanicButton) then 
--         table.insert(elements, {label = '> PANIC BUTTON <', value = 'panic'})
--     end
--     table.insert(elements, {label = '> Create Dispatch', value = 'create'})
--     table.insert(elements, {label = '', value = ''})

--     local incidentCount = 0
--     for i=1, #disList, 1 do
--         local item = disList[i]
--         if (not item.complete) then
--             incidentCount = incidentCount + 1
--             table.insert(elements, {label = '> [' .. item.attending.count .. '] Incident #' .. item.num .. ' - ' .. item.type, value = item})
--         end
--     end
--     if (incidentCount == 0) then
--         table.insert(elements, {label = '- No Items Found -', value = ''})
--     end
    
--     ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'dispatchmenu', {
--         title    = 'Dispatch Menu' .. time,
--         align    = 'right',
--         elements = elements
--     }, function(data, menu)
--         ESX.UI.Menu.CloseAll()

--         if (data.current.value == '') then return end
--         if (data.current.value == 'panic') then
--             ExecuteCommand('panic')
--         elseif (data.current.value == 'create') then
--             CreateDispatch(time)
--         else
--             OpenDispatch(data.current.value)
--         end
--     end, function(data, menu)
--         menu.close()
--     end)
-- end

RegisterNetEvent('bixbi_dispatch:CreateDispatch')
AddEventHandler('bixbi_dispatch:CreateDispatch', function()
    CreateDispatch()
end)

local canCreateDispatch = true
function CreateDispatch()
    ESX.TriggerServerCallback('bixbi_core:itemCount', function(itemCount)
        while (itemCount == nil) do Citizen.Wait(100) end
        if (itemCount == 0) then
            TriggerEvent('bixbi_core:Notify', 'error', 'You must have a ' .. Config.RequiredItem .. ' to use this.')
            return 
        end
        if (not canCreateDispatch) then 
            TriggerEvent('bixbi_core:Notify', 'error', 'DISPATCH: You cannot create another dispatch yet.')
            return 
        end
        local elements = {}

        for k, v in pairs(Config.Jobs) do
            if (k ~= ESX.PlayerData.job.name) then
                table.insert(elements, { label = string.upper(k) })
            end
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'createdispatch', {
            title    = 'Create Dispatch',
            align    = 'right',
            elements = elements
        }, function(data, menu)
            ESX.UI.Menu.CloseAll()

            local dialog = exports['zf_dialog']:DialogInput({
                header = "Send Dispatch to " .. data.current.label, 
                rows = {
                    {
                        id = 0, 
                        txt = "Message"
                    }
                }
            })
            if dialog ~= nil then
                if dialog[1].input == nil then return end
                local msg = dialog[1].input
                if (#msg > 50) then
                    local overCount = #msg - 50
                    msg = msg:sub(1, -overCount)
                end
                TriggerServerEvent('bixbi_dispatch:Add', source, string.lower(data.current.label), 'Manual', msg, GetEntityCoords(PlayerPedId()))
                TriggerEvent('bixbi_core:Notify', '', 'DISPATCH: Message sent to ' .. data.current.label)
            end       
        end, function(data, menu)
            menu.close()
        end)
    end, Config.RequiredItem)
end

function CreatedDispatch()
    Citizen.CreateThread(function()
        canCreateDispatch = false
        Citizen.Wait(Config.CreateDispatchCooldown * 60000)
        canCreateDispatch = true
    end)
end

-- function OpenDispatch(dispatch)
--     local elements = {}
        
--     if (currentlyAttending[tostring(dispatch.num)] == nil) then
--         table.insert(elements, {label = '> Respond', value = 'respond'})
--     else
--         table.insert(elements, {label = '> Set Waypoint', value = 'waypoint'})
--         if (Config.Jobs[ESX.PlayerData.job.name] ~= nil and Config.Jobs[ESX.PlayerData.job.name].RequestPolice) then 
--             table.insert(elements, {label = '> Request Police', value = 'police'})
--         end
--         table.insert(elements, {label = '> Stop Responding', value = 'unrespond'})
--         table.insert(elements, {label = '> Complete Dispatch', value = 'complete'})
--         table.insert(elements, {label = '', value = ''})
--     end

--     local msg = dispatch.message
--     if (#msg > 50) then
--         local overCount = #msg - 50
--         msg = msg:sub(1, -overCount)
--     end

--     table.insert(elements, {label = dispatch.type .. ' | ' .. msg, value = ''})
--     -- table.insert(elements, {label = 'Location: ' .. GetLabelText(GetNameOfZone(GetEntityCoords(PlayerPedId()))), value = ''})
--     local coords = GetEntityCoords(PlayerPedId())
--     local streetName, crossingRoad = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
--     table.insert(elements, {label = 'Location: ' .. GetStreetNameFromHashKey(streetName), value = ''})
--     table.insert(elements, {label = '', value = ''})
    
--     table.insert(elements, {label = 'Current Responders', value = ''})
--     if (dispatch.attending.count ~= 0) then
--         for k, v in pairs(dispatch.attending) do
--             if (k == tostring(source)) then
--                 table.insert(elements, {label = '[' .. source .. '] You', value = ''})
--             elseif (k ~= 'count' and k ~= tostring(source)) then
--                 for _, z in pairs(v) do
--                     table.insert(elements, {label = '[' .. k .. '] ' .. z, value = ''})
--                 end
--             end
--         end
--     else
--         table.insert(elements, {label = '- No Responders -', value = ''})
--     end
    
--     ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'opendispatch', {
--         title    = 'Incident #' .. dispatch.num .. ' [' .. dispatch.time .. ']',
--         align    = 'right',
--         elements = elements
--     }, function(data, menu)
--         ESX.UI.Menu.CloseAll()
--         local value = data.current.value

--         if (value == '') then return end
--         if (value == 'respond') then
--             CreateBlip(dispatch.type, false, dispatch.gps, dispatch.num)
--             TriggerServerEvent('bixbi_dispatch:Attend', source, tostring(dispatch.num))
--             currentlyAttending[tostring(dispatch.num)] = {}
--             table.insert(currentlyAttending, currentlyAttending[tostring(dispatch.num)])
--         elseif (value == 'unrespond') then
--             TriggerServerEvent('bixbi_dispatch:UnAttend', source, tostring(dispatch.num))
--             currentlyAttending[tostring(dispatch.num)] = nil
--         elseif (value == 'waypoint') then
--             CreateBlip(dispatch.type, false, dispatch.gps, dispatch.num)
--         elseif (value == 'police') then
--             TriggerServerEvent('bixbi_dispatch:Add', source, 'police', 'Assistance', ESX.PlayerData.job.name .. ' member has requested assistance.', dispatch.gps)
--         elseif (value == 'complete') then
--             TriggerServerEvent('bixbi_dispatch:Remove', source, tostring(dispatch.num))
--             DispatchMenu()
--         end
--     end, function(data, menu)
--         menu.close()
--     end)
-- end

--[[--------------------------------------------------
Setup
--]]--------------------------------------------------
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    while (ESX == nil) do Citizen.Wait(100) end
    ESX.PlayerData = xPlayer
 	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
	ESX.PlayerLoaded = false
	ESX.PlayerData = {}
end)