fx_version 'cerulean'
game 'gta5'

author 'NS Marketplace'
description 'Advanced marketplace system for buying and selling items'
version '1.0.0'

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
    'ui/script.js',
    'ui/ns-logo.png'
}

lua54 'yes'

