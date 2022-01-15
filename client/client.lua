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

if (not Config.PanicKeybind) then
    RegisterCommand('panic', function()
        TriggerServerEvent('bixbi_dispatch:PanicButton')
    end, false)
    RegisterKeyMapping('panic', 'Panic Button', 'keyboard', Config.PanicKeybind)
end
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