--[[----------------------------------
Creation Date:	25/06/2021
]]------------------------------------
fx_version 'cerulean'
game 'gta5'
author 'Leah#0001'
version '1.1.4'
versioncheck 'https://raw.githubusercontent.com/Leah-UK/bixbi_dispatch/main/fxmanifest.lua'

shared_scripts {
	'@es_extended/imports.lua',
	'config.lua'
}

client_scripts {
	'client/client.lua',
	'client/cl_menu.lua'
}

server_scripts {
	'server/server.lua'
}

exports {
	"CreateDispatch"
}

ui_page 'ui/index.html'
files {
    'ui/*.html',
    'ui/*.js',
    'ui/*.css',
}

dependencies {
	'bixbi_core'
}
