-- Decrypted & Fixed by Escrow Fucker
fx_version "cerulean"
games { "gta5" }
this_is_a_map "yes"
lua54 "yes"

author "GungeGP"
description "Part of the Chop Shop DLC"
version "1.0.0"

escrow_ignore {
    "stream/unlocked/**"
}

shared_scripts {
    "Config.lua"
}

client_scripts {
	"main.lua"
}

dependencies {
    "/server:7257",
    "/gameBuild:3095",
}

dependency '/assetpacks'