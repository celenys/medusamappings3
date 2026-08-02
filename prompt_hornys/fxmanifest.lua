-- Decrypted & Fixed by Escrow Fucker
fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Igro45 for Prompt'
description 'Hornys Burger'
version '1.0.0'

this_is_a_map 'yes'

client_scripts {
	'client.lua'
}

server_scripts {
	'sv_loader.lua'
}

escrow_ignore {
    'stream/base/unlocked/**',
    'stream/ghetto/unlocked/**',
    'stream/mirror-park/**',
    'stream/paleto-bay/unlocked/**',
    'stream/sandy/**'

}


files {
  'data/i45pt_gtxd.meta'
}

data_file 'GTXD_PARENTING_DATA' 'data/i45pt_gtxd.meta'
dependency '/assetpacks'