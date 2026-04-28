local spawnedVehicle = nil
local isMonitoring = false
local cooldown = false

RegisterCommand('veh', function()
    if cooldown then
        lib.notify({
            title = 'Vehicle Spawn',
            description = 'Wait before spawning another vehicle.',
            type = 'error'
        })
        return
    end

    TriggerEvent('ykaa_itemcar:spawnVehicle')
end)

RegisterKeyMapping('veh', 'Spawn configured vehicle', 'keyboard', '')

RegisterNetEvent('ykaa_itemcar:spawnVehicle', function()
    local playerPed = PlayerPedId()

    cooldown = true

    CreateThread(function()
        Wait(Config.Cooldown * 1000)
        cooldown = false
    end)

    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
        spawnedVehicle = nil
    end

    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)

    local spawnCoords = vector3(
        coords.x + (forward.x * 4.0),
        coords.y + (forward.y * 4.0),
        coords.z
    )

    local heading = GetEntityHeading(playerPed)
    local hash = joaat(Config.DefaultVehicle)

    RequestModel(hash)

    while not HasModelLoaded(hash) do
        Wait(10)
    end

    spawnedVehicle = CreateVehicle(
        hash,
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z,
        heading,
        true,
        false
    )

    SetVehicleOnGroundProperly(spawnedVehicle)
    SetEntityAsMissionEntity(spawnedVehicle, true, true)
    SetPedIntoVehicle(playerPed, spawnedVehicle, -1)

    if Config.Vehicle.Full then
        SetVehicleModKit(spawnedVehicle, 0)

        SetVehicleMod(spawnedVehicle, 11, GetNumVehicleMods(spawnedVehicle, 11) - 1, false)
        SetVehicleMod(spawnedVehicle, 12, GetNumVehicleMods(spawnedVehicle, 12) - 1, false)
        SetVehicleMod(spawnedVehicle, 13, GetNumVehicleMods(spawnedVehicle, 13) - 1, false)

        ToggleVehicleMod(spawnedVehicle, 18, true)
        ToggleVehicleMod(spawnedVehicle, 22, true)

        SetVehicleEngineOn(spawnedVehicle, true, true, false)
    end

    SetModelAsNoLongerNeeded(hash)

    lib.notify({
        title = 'Vehicle Spawn',
        description = 'Vehicle spawned successfully.',
        type = 'success'
    })

    StartVehicleMonitor()
end)

function StartVehicleMonitor()
    if isMonitoring then
        return
    end

    isMonitoring = true

    CreateThread(function()
        while spawnedVehicle and DoesEntityExist(spawnedVehicle) do
            local playerPed = PlayerPedId()

            if IsPedInVehicle(playerPed, spawnedVehicle, false) then
                if IsControlJustReleased(0, Config.Vehicle.DespawnKey) then
                    DeleteEntity(spawnedVehicle)
                    spawnedVehicle = nil

                    lib.notify({
                        title = 'Vehicle Spawn',
                        description = 'Vehicle despawned.',
                        type = 'inform'
                    })

                    break
                end
            end

            Wait(0)
        end

        isMonitoring = false
    end)
end
