--[[----------------------------------
Creation Date:	25/06/2021
Discord: View Link on 'versioncheck' URL
]]------------------------------------
fx_version 'cerulean'
game 'gta5'
author 'Leah#0001'
version '1.0'
-- versioncheck 'https://raw.githubusercontent.com/Leah-UK/FiveM-Script-Versioning/main/bixbi_dispatch.lua'

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