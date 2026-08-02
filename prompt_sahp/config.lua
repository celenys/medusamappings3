Config = {}


-- THIS DOESN'T WORK AS INTENDED, I CANNOT GET IT TO WORK UNFORTUNATELY. 
-- IF YOU CAN HELP ME FIGURE OUT WHY CONFIG ENTITY SETS ARE NOT BEING APPLIED,
-- IT WILL BE APPRECIATED
-- OX_LIB WORKS BTW

-- Default entity set configuration
-- Set which entity sets should be enabled by default when the resource starts
-- Available options: "onlychairs", "chairsandtables", or false (disabled)
Config.DefaultEntitySets = {
    onlychairs = true,        -- Set to true to enable "Only Chairs" by default
    chairsandtables = false    -- Set to true to enable "Chairs and Tables" by default
}

-- Enable/disable the entity set manager menu (requires ox_lib)
-- If ox_lib is not found, the menu will be automatically disabled
-- but the default entity sets from above will still be applied
Config.EnableMenu = true

-- Command to open the entity set menu (only works if ox_lib is available and menu is enabled)
Config.MenuCommand = "sahp"
