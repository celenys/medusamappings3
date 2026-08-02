-- Server-side configuration for gym system mechanics
-- This file controls exhaustion, stat progression, and gameplay balance

return {
    debug = false, -- Enable debug logging for troubleshooting
    syncDistance = 50.0, -- Distance (in meters) for synchronizing equipment between players

    enableMinigame = false, -- Enable skill check minigame when starting exercises

    gymCreator = { -- /gymcreator command
        enable = true,
        restricted = 'group.admin', -- ox_lib's addCommand restriction string, set to false to disable restriction

        ---@param source number
        ---@return boolean
        canAccess = function(source)
            -- additional checks can be added here
            return true
        end
    },

    -- Exhaustion/fatigue system - prevents spam and adds realism
    exhaustion = {
        enable = false, -- Enable exhaustion system
        recoveryRate = 0.01, -- Recovery per minute (0.01 = 1% per minute)

        enableMuscleGroups = true, -- Enable separate exhaustion tracking per muscle group
        muscleGroups = { -- Muscle groups for targeted exhaustion trackingaustion tracking
            legs = { 'leg_press', 'gymbike' }, -- Leg exercises
            arms = { 'speedbag', 'gymspeedbag', 'gympullmachine1', 'gympullmachine2', 'bench' }, -- Arm exercises
            back = { 'gymlatpull', 'gymrowpull' }, -- Back exercises
            core = { 'vin_chu' } -- Core/abs exercises
        },

        rates = { -- Exhaustion amount added per exercise completion (0-1 scale)
            vin_chu = 0.2,
            leg_press = 0.3,
            speedbag = 0.15,
            gymbike = 0.25,
            gymlatpull = 0.2,
            gympullmachine1 = 0.3,
            gympullmachine2 = 0.3,
            gymrowpull = 0.3,
            gymspeedbag = 0.3,
            bench = 0.3,
        }
    },

    -- Groups system - allows creating, saving, loading, and editing prop groups
    -- Groups are stored in groups/saved_groups.json (persists across restarts)
    groups = {
        enable = true, -- Enable the groups system
        -- Groups are accessed via /gymcreator -> "Manage Groups"
        -- Permission is inherited from gymCreator.restricted above

        -- Whether the original creator of a group can edit their own groups (without admin permission)
        creatorCanEdit = true,
        -- Whether the original creator of a group can delete their own groups (without admin permission)
        creatorCanDelete = false,

        -- Despawn monitoring interval (in ms) - how often to re-check for respawned world props
        -- while a player is inside a group's location. Lower = more responsive, higher = less CPU
        despawnCheckInterval = 10000, -- 10 seconds
    },

    -- Membership system - optionally restrict gym usage to members
    -- Members are stored in membership/members.json (persists across restarts)
    -- Other resources can override the check via exports (see DOCUMENTATION.md)
    membership = {
        enable = false, -- Global toggle. When true, ALL gym locations require membership.
        -- Individual config locations can opt out by setting requireMembership = false.
        -- Groups do NOT require membership by default (toggle per-group via Manage Groups menu).
        -- Custom-spawned equipment (via /gymcreator) never requires membership.

        -- Locations that NEVER require membership (by name)
        -- These are the location names used when creating gym locations (e.g., 'prison', 'vinewood')
        -- Useful for locations from external resources (prison gyms, etc.)
        exemptLocations = {
            'prison',
        },

        -- Admin commands for memberships
        -- /gymmembership <playerId> [days]   → grant (no days = permanent)
        -- /gymrevoke <playerId>              → revoke
        commandRestricted = 'group.admin', -- ACE restriction for the commands, set to false to disable
    },

    -- Player stats progression system (4 stats: speed, stamina, combat, strength)
    -- speed    = sprint speed          (trained by leg exercises)
    -- stamina  = endurance & recovery  (trained by cardio exercises)
    -- combat   = melee damage          (trained by punching / combat dummy)
    -- strength = damage resistance     (trained by upper body pulls & bench)
    stats = {
        enable = true, -- Enable stat progression
        rates = { -- Stat gains per exercise completion
            vin_chu = { combat = 0.4 },
            leg_press = { speed = 0.1 },
            speedbag = { combat = 0.4 },
            gymbike = { stamina = 0.1 },
            gymlatpull = { strength = 0.1 },
            gympullmachine1 = { strength = 0.1 },
            gympullmachine2 = { strength = 0.1 },
            gymrowpull = { stamina = 0.3, strength = 0.3 },
            gymspeedbag = { combat = 0.4 },
            bench = { strength = 0.1 },
        },

        decrease = {
            enable = true, -- Set to false to disable stat decay entirely
            multiplier = 1.0, -- Global multiplier for decay rates (0.5 = half speed, 2.0 = double speed)
            speed = 0.02, -- Speed loss per minute (~1.2 per hour at 1.0x multiplier)
            stamina = 0.02, -- Stamina loss per minute (~1.2 per hour at 1.0x multiplier)
            combat = 0.015, -- Combat loss per minute (~0.9 per hour at 1.0x multiplier)
            strength = 0.01, -- Strength loss per minute (~0.6 per hour at 1.0x multiplier)
        }
    },
}