local menuOpen = false
local currentlyAttending = {}
local dispatchList = {}
local dispatchListId = 0
local responseTime = ''
local source = GetPlayerServerId(PlayerId())
local doingAction = false

RegisterCommand(Config.Command, function()
    OpenMenu()
end, false)
if (Config.Keybind ~= nil) then RegisterKeyMapping(Config.Command, 'Dispatch Menu', 'keyboard', Config.Keybind) end

function OpenMenu()
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
                -- if (MenuNavigate(false, true)) then MenuControls() end
                MenuNavigate(false, true)
                MenuControls()
            end)
        else
            SendNUIMessage({ show = menuOpen })
        end
    end, Config.RequiredItem)
end

local menuLoop = nil
function MenuControls()
    menuLoop = SetInterval(function()
        if (not menuOpen) then return end
        if (IsControlJustReleased(0, 174) and #dispatchList > 1 and not navInProgress) then -- left arrow
            MenuNavigate(true, false)
            SendSound('navigate')
        end
        if (IsControlJustReleased(0, 175) and #dispatchList > 1 and not navInProgress) then -- right arrow
            MenuNavigate(false, false)
            SendSound('navigate')
        end
        
        if (IsControlJustReleased(0, 43)) then -- [ Respond
            RespondAction()
        end
        if (IsControlJustReleased(0, 304)) then -- H Waypoint
            WaypointAction()
        end
        if (IsControlJustReleased(0, 42)) then -- ] Delete
            GetYesNo(dispatchList[dispatchListId].number)
        end
    end, 1)
    SetInterval(menuLoop, 1)
end

function RespondAction()
    if (doingAction) then return end
    doingAction = true
    Citizen.SetTimeout(250, function()
        doingAction = false
    end)

    local dispatch = dispatchList[dispatchListId]
    if (currentlyAttending[dispatchListId] == nil and not currentlyAttending[dispatchListId]) then
        CreateBlip(dispatch.type, false, dispatch.gps, tostring(dispatch.number))
        TriggerServerEvent('bixbi_dispatch:Attend', source, dispatch.number)
        currentlyAttending[dispatchListId] = {}
    else
        TriggerServerEvent('bixbi_dispatch:UnAttend', source, dispatch.number)
        currentlyAttending[dispatchListId] = false
    end
    SendSound('pop')
end

function WaypointAction()
    if (doingAction) then return end
    doingAction = true
    Citizen.SetTimeout(250, function()
        doingAction = false
    end)

    local dispatch = dispatchList[dispatchListId]
    CreateBlip(dispatch.type, false, dispatch.gps, tostring(dispatch.number))
    SendSound('pop')
end

function GetYesNo(dispatchNumber)
    if (doingAction) then return end
    doingAction = true
    Citizen.SetTimeout(250, function()
        doingAction = false
    end)

    SendSound('pop')
    OpenMenu()
    ClearInterval(menuLoop)
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
    end)
    SetInterval(yesNoLoop)

    local waitTime = 0
    while (not responded) do 
        Citizen.Wait(100) 
        waitTime = waitTime + 100
        if (waitTime >= 50 * 100) then responded = true end
    end
    SendNUIMessage({ show = false, yesno = true })
    ClearInterval(yesNoLoop)
end

-- local menuNavAttempts = 0
-- local navInProgress = false
function MenuNavigate(isLeft, isNew)
    -- menuNavAttempts = 0
    if (doingAction) then return end
    doingAction = true
    Citizen.SetTimeout(250, function()
        doingAction = false
    end)
    return DoMenuNav(isLeft, isNew)
end

function DoMenuNav(isLeft, isNew)
    -- Citizen.Wait(0)
    
    if (isLeft) then
        if (dispatchListId <= 1) then 
            dispatchListId = #dispatchList
        else
            dispatchListId = dispatchListId - 1
        end
    else
        if (dispatchListId >= #dispatchList) then 
            dispatchListId = 1
        else
            dispatchListId = dispatchListId + 1
        end
    end
    
    SendNUIMessage(SetupUI(dispatchList[dispatchListId], isNew))
    -- Citizen.Wait(0)
    -- print(' ')
    -- if (dispatchList[dispatchListId] == nil or dispatchList[dispatchListId] == false) then       
    --     menuNavAttempts = menuNavAttempts + 1
    --     if (menuNavAttempts > 999) then
    --         exports['bixbi_core']:Notify('error', 'No incidents reported')
    --         return false
    --     elseif (menuNavAttempts == 200) then
    --         exports['bixbi_core']:Notify('error', 'There\'s more than 200 reports logged. Please wait...')
    --     end
    --     DoMenuNav(isLeft, isNew)
    -- else
    --     SendNUIMessage(SetupUI(dispatchList[dispatchListId], isNew))
    --     return true
    -- end
    -- Citizen.Wait(0)
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
        incident = tostring(dispatch.number) .. ' - ' .. dispatch.time,
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
