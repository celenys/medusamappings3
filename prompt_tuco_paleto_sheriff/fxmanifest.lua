-- Decrypted & Fixed by Escrow Fucker
fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

name 'Paleto Bay Sheriff`s Office'
description 'Paleto Bay Sheriff`s Office MLO'
author 'Tuco'
this_is_a_map 'yes'

data_file 'AUDIO_GAMEDATA' 'audio/tuco_door_sounds_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tuco_paleto_sheriff_shell_col_game.dat'
data_file 'AUDIO_DYNAMIXDATA' 'audio/tuco_paleto_sheriff_shell_col_mix.dat'

files {
    'audio/tuco_door_sounds_game.dat151.rel',
    'audio/tuco_paleto_sheriff_shell_col_game.dat151.rel',
    'audio/tuco_paleto_sheriff_shell_col_mix.dat15.rel',
}

server_scripts {
    'sv_loader.lua'
}

escrow_ignore {
  'stream/meta/*.ytyp',
  'stream/meta/*.ytd',
  'stream/meta/*.ybn',
  'stream/meta/*.ymap',
  'stream/vanilla/**'
}


dependency '/assetpacks'