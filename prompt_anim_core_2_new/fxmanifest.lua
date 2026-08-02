-- Decrypted & Fixed by Escrow Fucker
fx_version "cerulean"
use_fxv2_oal "yes"
lua54 'yes'
game "gta5"

author "Adaz"
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua',
    'groups/client_menu.lua',
    'groups/client_despawn.lua',
}

server_scripts {
    'server/main.lua',
    'membership/server_membership.lua',
    'groups/server_manager.lua',
}

escrow_ignore {
    'config/**',
    'web/**',
    'locales/**',
    'server/',
    'client',
    'groups/**',
    'membership/**',
    'exports.md',
    'DOCUMENTATION.md'
}


files {
    'config/client.lua',
    'config/config_c.lua',
    'config/config_s.lua',
    'web/**/*',
    'locales/*',
    'client/*.lua',
    'server/*.lua',
    'groups/*.lua',
    'membership/*.lua',

    'data/prompt_gym.dat54.rel',
    'audiodirectory/prompt_gym.awc',
    'stream/**/*'
}

data_file 'AUDIO_WAVEPACK'  'audiodirectory'
data_file 'AUDIO_SOUNDDATA' 'data/prompt_gym.dat'
data_file 'DLC_ITYP_REQUEST' 'stream/anim/vin_chu.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/anim/vision_gymlegpress.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/anim/vision_gymspeedbagwall.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/anim/vision_gymspeedbag_yt.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/anim/vision_gymrowpull_yt.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/anim/vision_gymlatpull_yt.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/anim/vision_gympullmachine1_yt.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/anim/vision_gymbike_yt.ytyp'

ui_page 'web/index.html'
dependency '/assetpacks'