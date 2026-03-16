fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Codex'
description 'QBCore MDT + EMS Console + Adaptive Dispatch'
version '1.0.0'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'ui/index.html',
    'ui/app.js',
    'ui/style.css'
}

ui_page 'ui/index.html'
