Config = {}

Config.Debug = true
Config.RequiredItem = 'tracker' -- Player needs the item to use the system.
Config.Keybind = nil            -- Set to a value like 'o' to enable menu opening through keybind.

Config.Jobs = {
    police = {
        discordWebHook = "",
        PanicButton = true
    },
    ambulance = {
        discordWebHook = "",
        PanicButton = true
    },
    mechanic = {
        discordWebHook = "",
        PanicButton = false
    }
}
Config.CreateDispatchCooldown = 10 -- in minutes.

Config.Types = {
    ['default'] = {
        label = "dispatch",
        enableFlash = true,
        marker = {
            sprite = 1, -- https://docs.fivem.net/docs/game-references/blips/
            colour = 0,
            scale = 1.0,
            flashscale = 50.0,
            flashtime = 30 -- seconds.
        }
    },
    ['robbery'] = {
        label = "Robbery",
        enableFlash = true,
        marker = {
            sprite = 362,
            colour = 1,
            scale = 1.0,
            flashscale = 50.0,
            flashtime = 60
        }
    },
    ['prisonbreak'] = {
        label = "Prison Break",
        enableFlash = true,
        notifCooldown = 60, -- How many seconds before sending a new alert of the same type.
        marker = { 
            sprite = 362,
            colour = 1,
            scale = 1.0,
            flashscale = 50.0,
            flashtime = 60
        }
    },
    ['drugsale'] = {
        label = "Drug Sale",
        enableFlash = true,
        marker = {
            sprite = 362,
            colour = 1,
            scale = 1.0,
            flashscale = 50.0,
            flashtime = 30
        }
    },
    ['panic'] = {
        label = "PANIC BUTTON!",
        enableFlash = true,
        marker = {
            sprite = 267,
            colour = 3,
            scale = 1.3,
            flashscale = 50.0,
            flashtime = 60
        }
    }
}