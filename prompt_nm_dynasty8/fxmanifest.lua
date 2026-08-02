-- Decrypted & Fixed by Escrow Fucker
fx_version('cerulean')
game('gta5')

author 'NekMods -- James'
description 'Dynasty 8 agency "nm_estate"'
version '1.0.0'
lua54 'yes'


files {
    'nm_timecycle.xml'
}

data_file 'TIMECYCLEMOD_FILE' 'nm_timecycle.xml'

escrow_ignore {
  'fxmanifest.lua', 
  'nm_timecycle.lua',   
  'stream/vanilla/*.*',
  'stream/ydr/nm_estate_r01_proxy.ydr',
  'stream/ydr/nm_estate_r02_proxy.ydr',
  'stream/ydr/nm_estate_r03_proxy.ydr',
  'stream/nm_estate_txd.ytd'
}

dependency '/assetpacks'