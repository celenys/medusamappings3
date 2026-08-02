-- Decrypted & Fixed by Escrow Fucker
fx_version('cerulean')
game('gta5')

author 'James / PROMPT STUDIO'
description 'Prompt DLC Busines - mechanic garage'
version '1.0.0'
lua54 'yes'

files {
    'stream/anims/prompt_sandy_repair_anims.ytyp'

}

data_file 'DLC_ITYP_REQUEST' 'prompt_sandy_repair_anims.ytyp'

escrow_ignore {
    'config.lua',
    'open_config.lua',
    'stream/base/unlocked/**',
    'stream/beach/**',
    'stream/chumash/**',
    'stream/city/**',
    'stream/highway/**',
    'stream/paleto/**'

}

shared_scripts {
    'config.lua',
    'open_config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'sv_loader.lua',
    'server/*.lua',
}

dependency '/assetpacks'
dependency '/assetpacks'