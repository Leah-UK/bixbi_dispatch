ESX = nil
TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)

local dispatchList = {police = {}, ambulance = {}, mechanic = {}}
local typeCooldown = {}

ESX.RegisterCommand('dispatchtest', 'user', function(xPlayer, args, showError)
	-- TriggerEvent('bixbi_dispatch:Add', xPlayer.playerId, 'police', 'test', 'Just a test :)')
    TriggerEvent('bixbi_dispatch:Add', xPlayer.playerId, 'police', 'prisonbreak', 'Prison Break Test', vector3(1755.32, 2604.94, 45.56))
    TriggerEvent('bixbi_dispatch:Add', xPlayer.playerId, 'police', 'drugsale', 'Drug Sale Test', vector3(411.67, -1009.09, 29.36))
    TriggerEvent('bixbi_dispatch:Add', xPlayer.playerId, 'police', 'default', 'Just a text message!', vector3(210.21, -805.9, 30.89))
end, false)

-- ESX.RegisterCommand('dispatchrem', 'user', function(xPlayer, args, showError)
-- 	TriggerEvent('bixbi_dispatch:Remove', xPlayer.playerId, 'police', 'test')
-- end, false)

local onTimer = {}
RegisterServerEvent('bixbi_dispatch:PanicButton')
AddEventHandler('bixbi_dispatch:PanicButton', function()
    local xPlayer = ESX.GetPlayerFromId(source)

    if (Config.Jobs[xPlayer.job.name].PanicButton) then
        if onTimer[xPlayer.playerId] and onTimer[xPlayer.playerId] > GetGameTimer() then
            local timeLeft = (onTimer[xPlayer.playerId] - GetGameTimer()) / 1000
            TriggerClientEvent('bixbi_core:Notify', source, 'error', 'Please wait ' .. tostring(ESX.Math.Round(timeLeft)) .. ' seconds before sending another panic.')
            return
        end

        local playerCoords = GetEntityCoords(GetPlayerPed(xPlayer.playerId))
        TriggerEvent('bixbi_dispatch:Add', xPlayer.playerId, 'police', 'panic', 'PANIC BUTTON INITIATED', playerCoords)
        onTimer[xPlayer.playerId] = GetGameTimer() + (120 * 1000)
    else
        TriggerClientEvent('bixbi_core:Notify', source, 'error', 'Your job doesn\'t have the ability to do this.')
    end
end)

RegisterServerEvent('bixbi_dispatch:Add')
AddEventHandler('bixbi_dispatch:Add', function(source, job, type, message, gps)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (xPlayer ~= nil and gps == nil) then gps = xPlayer.coords end
    
    if (Config.Types[type].notifCooldown ~= nil) then
        if (typeCooldown[type] ~= nil) then
            if ((os.time() - typeCooldown[type]) < Config.Types[type].notifCooldown) then return else typeCooldown[type] = os.time() end
        else
            typeCooldown[type] = os.time()
        end
    end

    local dispatchNumber = "1"
    if (dispatchList[job][dispatchNumber] == nil) then
        -- Create new list.
        -- local newDispatch = {}
        dispatchList[job][dispatchNumber] = {}
        dispatchList[job][dispatchNumber].type = type
        dispatchList[job][dispatchNumber].message = message
        dispatchList[job][dispatchNumber].gps = gps
        dispatchList[job][dispatchNumber].time = os.date("%H:%M")
        dispatchList[job][dispatchNumber].num = 1
        dispatchList[job][dispatchNumber].attending = { count = 0 }
        dispatchList[job][dispatchNumber].complete = false

        table.insert(dispatchList[job], dispatchList[job][dispatchNumber])
    else
        -- Get last dispatch number.
        local lastElement = dispatchList[job][#dispatchList[job]]
        dispatchNumber = tostring(lastElement.num + 1)
        dispatchList[job][dispatchNumber] = {}
        dispatchList[job][dispatchNumber].type = type
        dispatchList[job][dispatchNumber].message = message
        dispatchList[job][dispatchNumber].gps = gps
        dispatchList[job][dispatchNumber].time = os.date("%H:%M")
        dispatchList[job][dispatchNumber].num = lastElement.num + 1
        dispatchList[job][dispatchNumber].attending = { count = 0 }
        dispatchList[job][dispatchNumber].complete = false

        table.insert(dispatchList[job], dispatchList[job][dispatchNumber])
    end

    for k, v in pairs(ESX.GetExtendedPlayers('job', job)) do
        local label = ''
        if (Config.Types[type] == nil) then 
            label = Config.Types['default'].label 
        else
            label = Config.Types[type].label
        end
        
        TriggerClientEvent('bixbi_core:Notify', k, '', 'DISPATCH: New ' .. label .. ' has been logged!', 10000)
        if (type == 'panic') then
            TriggerClientEvent('bixbi_core:Notify', k, 'error', 'DISPATCH: New ' .. label .. ' has been logged!', 10000)
            TriggerClientEvent('bixbi_core:Notify', k, 'error', 'DISPATCH: New ' .. label .. ' has been logged!', 10000)
        end
        TriggerClientEvent('bixbi_dispatch:CreateBlip', k, type, true, gps, dispatchNumber)
    end
end)

RegisterServerEvent('bixbi_dispatch:Remove')
AddEventHandler('bixbi_dispatch:Remove', function(source, number)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.job.name
    -- dispatchList[xPlayer.job.name][number] = nil
    -- table.remove(dispatchList[xPlayer.job.name], number)
    dispatchList[job][number].complete = true
    TriggerClientEvent('bixbi_core:Notify', source, 'success', 'DISPATCH: [#' .. number .. '] has been marked as complete and removed from the system.', 10000)
    SendDiscordLog(job, "**Dispatch #" .. number .. " [" .. dispatchList[job][number].time .. "]**\n\nClosed By: **" .. xPlayer.name .. "** [" .. source .. "]")

    for k, v in pairs(ESX.GetExtendedPlayers('job', job)) do
        TriggerClientEvent('bixbi_dispatch:DeleteBlip', k, number)
    end
end)

RegisterServerEvent('bixbi_dispatch:Attend')
AddEventHandler('bixbi_dispatch:Attend', function(source, number)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.job.name
    table.insert(dispatchList[job][number]['attending'], { source = xPlayer.name })
    dispatchList[job][number].attending.count = dispatchList[job][number].attending.count + 1
    TriggerClientEvent('bixbi_core:Notify', source, '', 'DISPATCH: You are now attending #' .. number, 10000)
end)

RegisterServerEvent('bixbi_dispatch:UnAttend')
AddEventHandler('bixbi_dispatch:UnAttend', function(source, number)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.job.name
    dispatchList[job][number].attending[source] = nil
    dispatchList[job][number].attending.count = dispatchList[job][number].attending.count - 1
    TriggerClientEvent('bixbi_core:Notify', source, 'error', 'DISPATCH: You are no longer attending #' .. number, 10000)
end)

ESX.RegisterServerCallback('bixbi_dispatch:GetList', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local response = { time = os.date("%H:%M"), list = dispatchList[xPlayer.job.name] }
    cb(response)
end)

ESX.RegisterServerCallback('bixbi_dispatch:GetListUnComplete', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local list = {}
    for k, v in ipairs(dispatchList[xPlayer.job.name]) do
        if (not v.complete) then table.insert(list, dispatchList[xPlayer.job.name][k]) end
    end
    local response = { time = os.date("%H:%M"), list = list }
    cb(response)
end)

function SendDiscordLog(job, message)
    local discordURL = Config.Jobs[job].discordWebHook
    if (discordURL == nil or Config.Jobs[job].discordWebHook == "" or message == "") then return end
    local embeds = {
        {
            ["title"]= 'Dispatch Completed',
            ["description"]= message,
            ["type"]= "rich",
            ["color"] = 16744192,
        }
    }
    PerformHttpRequest(discordURL, function(err, text, headers) end, 'POST', json.encode({ username = 'Dispatch Completed', embeds = embeds}), { ['Content-Type'] = 'application/json' })
end

AddEventHandler('onResourceStart', function(resourceName)
	if (GetResourceState('bixbi_core') ~= 'started' ) then
        print('Bixbi_Dispatch - ERROR: Bixbi_Core hasn\'t been found! This could cause errors!')
    end
end)