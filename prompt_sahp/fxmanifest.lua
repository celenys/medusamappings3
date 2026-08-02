-- Decrypted & Fixed by Escrow Fucker
fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
lua54 'yes'
version '1.0.2'

-- Entity set management
shared_script '@ox_lib/init.lua'
shared_script 'config.lua'
client_script 'entitysets_client.lua'
server_script 'entitysets_server.lua'

data_file 'AUDIO_GAMEDATA' 'audio/prompt_sahp_game.dat' -- dat151

files {
  'audio/prompt_sahp_game.dat151.rel'
}


escrow_ignore {
    'stream/base_files/unlocked/**',
    'stream/freeway_placement/**',
    'stream/city_placement/unlocked/**',
    'config.lua',
    'entitysets_client.lua',
    'entitysets_server.lua',
    'stream/3d_logos_replace'
}


dependency '/assetpacks'