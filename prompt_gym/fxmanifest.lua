-- Decrypted & Fixed by Escrow Fucker
fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
lua54 'yes'

-- MAP-ONLY RESOURCE: Gym Locations and Map Data
-- This resource only provides map data and triggers spawn events to prompt_anim_core
author 'Prompt Studio'
description 'Sandy Gym - Map Only (Animations handled by prompt_anim_core)'
scripts_author 'Infames Dev'
version '1.1.1'


escrow_ignore {
    'config.lua',
    'stream/chumash/**',
    'stream/groove/**',
    'stream/paleto/**',
    'stream/sandy/**',
    'stream/vinewood/**',
    'stream/basefiles/unlocked/**'
}

shared_scripts {
    '@ox_lib/init.lua',
}

server_scripts {
    'sv_loader.lua',
    'server.lua',
}

client_script 'client.lua'
dependency '/assetpacks'