local menuOpen = false
local currentlyAttending = {}
local dispatchList = {}
local dispatchListId = 0
local responseTime = ''
local source = GetPlayerServerId(PlayerId())
RegisterCommand(Config.Command, function()
    ESX.TriggerServerCallback('bixbi_core:itemCountCb', function(itemCount)
        while (itemCount == nil) do Citizen.Wait(100) end
        if (itemCount == 0) then
            TriggerEvent('bixbi_core:Notify', 'error', 'You must have a ' .. Config.RequiredItem .. ' to use this.')
            menuOpen = false
            SendNUIMessage({ show = menuOpen })
            return 
        end

        menuOpen = not menuOpen
        dispatchList = {}
        if (menuOpen) then
            ESX.TriggerServerCallback('bixbi_dispatch:GetDispatches', function(response) 
                while (response == nil) do Citizen.Wait(100) end
                dispatchList = response.list
                if (#dispatchList == 0) then 
                    exports['bixbi_core']:Notify('error', 'No incidents reported')
                    return 
                end

                responseTime = tostring(response.time)
                dispatchListId = 0
                if (MenuNavigate(false, true)) then MenuControls() end
            end)
        else
            SendNUIMessage({ show = menuOpen })
            -- ClearInterval(1)
        end
    end, Config.RequiredItem)

	
end, false)
if (Config.Keybind ~= nil) then RegisterKeyMapping(Config.Command, 'Dispatch Menu', 'keyboard', Config.Keybind) end

function MenuControls()
    menuLoop = SetInterval(function()
        if (not menuOpen) then return end
        if (IsControlJustReleased(0, 174)) then -- left arrow
            if (#dispatchList > 1) then MenuNavigate(true, false) end
            SendSound('navigate')
        end
        if (IsControlJustReleased(0, 175)) then -- right arrow
            if (#dispatchList > 1) then MenuNavigate(false, false) end
            SendSound('navigate')
        end
        
        if (IsControlJustReleased(0, 43)) then -- [ Respond
            SendSound('pop')
            local dispatch = dispatchList[dispatchListId]
            if (currentlyAttending[dispatchListId] == nil) then
                CreateBlip(dispatch.type, false, dispatch.gps, dispatch.num)
                TriggerServerEvent('bixbi_dispatch:Attend', source, dispatchListId)
                currentlyAttending[dispatchListId] = {}
                table.insert(currentlyAttending, currentlyAttending[dispatchListId])
            else
                TriggerServerEvent('bixbi_dispatch:UnAttend', source, dispatchListId)
                currentlyAttending[dispatchListId] = nil
            end
        end
        if (IsControlJustReleased(0, 304)) then -- H Waypoint
            SendSound('pop')
            local dispatch = dispatchList[dispatchListId]
            CreateBlip(dispatch.type, false, dispatch.gps, dispatch.num)
        end
        if (IsControlJustReleased(0, 42)) then -- ] Delete
            SendSound('pop')
            GetYesNo(dispatchListId)
        end
    end, 1)
end

function GetYesNo(dispatchNumber)
    ExecuteCommand(Config.Command)
    local responded = false
    SendNUIMessage({ show = true, yesno = true })

    yesNoLoop = SetInterval(function()
        if (responded) then return end
        if (IsControlJustReleased(0, 43)) then -- [ Yes
            SendSound('pop')
            TriggerServerEvent('bixbi_dispatch:Remove', source, dispatchNumber)
            responded = true
            return
        end
        if (IsControlJustReleased(0, 42)) then -- ] No
            SendSound('pop')
            responded = true
            return
        end
    end, 2)

    local waitTime = 0
    while (not responded) do 
        Citizen.Wait(100) 
        waitTime = waitTime + 100
        if (waitTime >= 50 * 100) then responded = true end
    end
    SendNUIMessage({ show = false, yesno = true })
    -- ClearInterval(2)
end

local menuNavAttempts = 0
function MenuNavigate(isLeft, isNew)
    menuNavAttempts = 0
    return DoMenuNav(isLeft, isNew)
end

function DoMenuNav(isLeft, isNew)
    Citizen.Wait(0)

    if (isLeft) then
        if (dispatchListId == 1) then 
            dispatchListId = #dispatchList
        else
            dispatchListId = dispatchListId - 1
        end
    else
        if (dispatchListId == #dispatchList) then 
            dispatchListId = 1
        else
            dispatchListId = dispatchListId + 1
        end
    end

    if (dispatchList[dispatchListId] == nil or dispatchList[dispatchListId] == false) then       
        menuNavAttempts = menuNavAttempts + 1
        if (menuNavAttempts > 999) then
            exports['bixbi_core']:Notify('error', 'No incidents reported')
            return false
        elseif (menuNavAttempts == 200) then
            exports['bixbi_core']:Notify('error', 'There\'s more than 200 reports logged. Please wait...')
        end
        DoMenuNav(isLeft, isNew)
    else
        SendNUIMessage(SetupUI(dispatchList[dispatchListId], isNew))
        return true
    end
end

function SetupUI(dispatch, isNew)
    local location = 'Unknown'
    if (dispatch.gps ~= nil) then
        local streetName, crossingRoad = GetStreetNameAtCoord(dispatch.gps.x, dispatch.gps.y, dispatch.gps.z)
        location = GetStreetNameFromHashKey(streetName)
    end

    local responders = {}
    if (dispatch.attending.count ~= 0) then
        for k, v in pairs(dispatch.attending) do
            if (k == tostring(source)) then
                table.insert(responders, '[' .. source .. '] You')
            elseif (k ~= 'count' and k ~= tostring(source)) then
                for _, z in pairs(v) do
                    table.insert(responders, '[' .. k .. '] ' .. z)
                end
            end
        end
    else
        table.insert(responders, '- No Responders -')
    end

    return {
        show = menuOpen,
        time = '[' .. responseTime .. ']',
        incident = dispatch.num .. ' - ' .. dispatch.time,
        type =   dispatch.type,
        details = dispatch.message,
        location = location,
        responders = responders,
        isnew = isNew,
    }
end

function SendSound(type)
    if (type == 'navigate') then TriggerServerEvent('InteractSound_SV:PlayOnSource', 'button_click', 0.2) end
    if (type == 'pop') then TriggerServerEvent('InteractSound_SV:PlayOnSource', 'pop', 0.1) end
end
