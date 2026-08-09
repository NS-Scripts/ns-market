fx_version 'cerulean'
game 'gta5'

author 'Beetle Studios'
description 'Advanced Item Marketplace (QBX, QB, ESX, ox_core + ox_inventory)'
version '1.0.1'

dependencies {
    'oxmysql',
    'ox_target'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}

lua54 'yes'

