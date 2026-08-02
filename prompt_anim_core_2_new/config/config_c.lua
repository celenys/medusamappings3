return {
    renderDistance = 100.0, -- Distance to render gym locations

    -- Language for UI text and notifications
    -- 'auto' = uses server's ox:locale convar value
    -- Available presets: 'en', 'es', 'fr', 'de', 'pt', 'ru', 'it', 'pl', 'zh', 'ko', 'sv', 'ar'
    language = 'auto',

    -- Interaction system to use for gym equipment
    -- Options: 'auto', 'ox_target', 'qb_target', 'textUI' (ox_lib text prompts), 'custom' (implement your own)
    interaction = 'auto',

    -- Custom interaction handler - implement your own interaction system
    -- Only used when interaction is set to 'custom'
    ---@param entities number[] -- List of created entities for the object
    ---@param object string -- Object name
    ---@param onUse function(entity: number) -- Called when player interact with object
    customInteraction = function(entities, object, onUse)
        -- only works when interaction is set to 'custom'
        return
    end,

    -- Remove custom interaction - cleanup when equipment is removed
    -- Only used when interaction is set to 'custom'
    removeCustomInteraction = function(entities, object)
        -- only works when interaction is set to 'custom'
        return
    end,

    -- Progress bar system to show exercise duration
    -- Options: 'built-in' (default system), 'custom' (implement your own)
    progressBar = 'built-in', -- built-in | custom

    -- Custom progress bar handler - implement your own progress display
    -- Only used when progressBar is set to 'custom'
    ---@param machine string -- machine name
    ---@param duration number -- duration in milliseconds
    ---@return boolean Returns true when completed
    customProgressBar = function(machine, duration)
        return true
    end,

    -- Blip configuration for gym locations on the map
    -- https://docs.fivem.net/docs/game-references/blips
    blip = {
        enable = true, -- Master toggle for ALL gym blips (locations + coords below)
        sprite = 311, -- Blip sprite ID
        color = 21, -- Blip color
        scale = 0.9, -- Blip size on map
        label = 'Gym', -- Blip label on map

        -- Static gym blips — placed at fixed coords, optionally tied to resources
        -- If resources is set, the blip only appears when one of those resources is started
        -- Set enable = false per entry to hide a specific blip
        coords = {
            { coords = vec3(-467.962, 286.688, 83.400), label = 'Vinewood Gym' },
            { coords = vec3(-175.039, -1719.904, 32.767), label = 'Grove Street Gym' },
            { coords = vec3(1767.101, 3691.660, 34.265), label = 'Sandy Shores Gym' },
            { coords = vec3(-75.121, 6434.685, 31.716), label = 'Paleto Bay Gym' },
            { coords = vec3(-3142.272, 1168.819, 20.809), label = 'Chumash Gym' },
            -- Example with resource check:
            -- { coords = vec3(100.0, 200.0, 30.0), label = 'Prison Gym', resources = {'prompt_prison_study', 'prompt_prison_tower_23'}, enable = true },
        },
    },

    -- Boxing ring configuration for PvP matches
    boxingRing = {
        enable = true, -- Enable/disable boxing ring feature
        model = "vision_gymboxingring",
        roundDuration = 60, -- Duration of round in seconds
        cancelDistance = 6.0, -- Max distance from ring center; player loses if exceeded
        showBoundary = true, -- Show red sphere boundary during fight

        coords = {
            vec4(-467.962, 286.688, 83.400, 353), -- vinewood gym
            vec4(-175.039, -1719.904, 32.767, 49), -- grove street gym
            vec4(1767.101, 3691.660, 34.265, 300), -- sandy shores gym
            vec4(-75.121, 6434.685, 31.716, 44), -- paleto bay gym
            vec4(-3142.272, 1168.819, 20.809, 265) -- chumash gym
        },

        -- Conditional coords: only added if one of the listed resources is started
        -- Useful for boxing rings placed inside MLOs from other resources
        conditionalCoords = {
            {
                resources = {'prompt_prison_study', 'prompt_prison_tower_23', 'prompt_church_prison'},
                coords = vec4(1710.738, 2523.927, 42.965, 230.654), -- prison fighting area
                cancelDistance = 6.1,
            },
            {
                resources = {'prompt_chinese_casino'},
                coords = vec4(267.422, 311.347, 86.111, 53.105), -- chinese casino fighting area
                cancelDistance = 5.7,
            },
        },
    },

    -- Models to clear from gym locations (works only when clearLocation is defined for location)
    clearLocationModels = {
        "prop_muscle_bench_01",
        "prop_muscle_bench_02",
        "prop_muscle_bench_03",
        "prop_muscle_bench_04",
        "prop_muscle_bench_05",
        "prop_muscle_bench_06",

        "prop_exer_bike_01",
        "prop_exer_bike_mg",

        "prop_weight_bench_02",
        "prop_weight_rack_01",
        "prop_weight_rack_02",
        "prop_weight_squat",

        "prop_barbell_01",
        "prop_barbell_02",
        "prop_barbell_10kg",
        "prop_barbell_20kg",
        "prop_barbell_30kg",
        "prop_barbell_40kg",
        "prop_barbell_50kg",
        "prop_barbell_60kg",
        "prop_barbell_80kg",
        "prop_barbell_100kg",

        "prop_weight_1_5k",
        "prop_weight_2_5k",
        "prop_weight_5k",
        "prop_weight_10k",
        "prop_weight_15k",
        "prop_weight_20k",

        "prop_curl_bar_01",

        "prop_yoga_mat_01",
        "prop_yoga_mat_02",
        "prop_yoga_mat_03",

        "p_ing_skiprope_01",
        "p_ing_skiprope_01_s",
        "p_skiprope_r_s",

        "prop_beach_bars",
        "prop_beach_bars_01",
        "prop_beach_dip_bars_01",
        "prop_beach_dip_bars_02",

        "prop_pris_bars_01",
        "prop_pris_bench_01",
    },

    -- Gym locations with equipment placements
    -- Each location contains coords (center point), optional name (for blips), and props (equipment positions)
    -- Blips are automatically created for each location if blip.enable = true
    -- Example location is commented out - uncomment and modify to add gyms
    locations = {
        -- ['example_gym'] = {
        --     coords = vec3(12.3, 45.6, 78.9), -- Center coordinates of the location
        --     renderDistance = 100.0, -- Optional custom render distance for this location (overrides renderDistance above)
        --     requireMembership = false, -- Optional: set to false to EXEMPT this location from membership when membership is enabled


        --     clearLocation = { -- Optional: Clear objects from location before spawning equipment
        --          -- radius to clear objects around location coords
        --          radius = 10.0,

        --          -- objects to clear from locations, that doesn't exist in clearLocationModels
        --          additionalObjects = {
        --          }
        -- },

        --     props = {
        --         speedbag = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         },
        --         gymspeedbag = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         },
        --         gympullmachine2 = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         },
        --         gympullmachine1 = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         },
        --         leg_press = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         },
        --         gymlatpull = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         },
        --         gymrowpull = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --     props = {
        --         gymbike = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         },
        --         vin_chu = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         },
        --         -- Bench example - simple format (bar attaches to player)
        --         bench = {
        --             vec4(12.3, 45.6, 78.9, 99.9),
        --         }
        --         -- Bench example - extended format (bar spawns at fixed position)
        --         -- bench = {
        --         --     {coords = vec4(12.3, 45.6, 78.9, 99.9), bar = vec4(12.4, 45.6, 79.2, 99.9)},
        --         -- }
        --     }
        -- },
        ['gym1'] = { -- Created by Prompt on 2026-02-10 12:18:55
            coords = vec3(-1349.36, -1134.01, 21.18),

            props = {
                bench = {
                    {coords = vec4(-1349.355, -1134.007, 21.183, 88.471), bar = vec4(-1349.838, -1134.002, 21.480, 88.471)},
                },
            }
        },
    },

    -- Equipment props configuration
    -- Each equipment type defines the model and animations
    -- Note: Bench supports two coordinate formats in locations:
    --   1. Simple: vector4(x, y, z, heading) - barbell attaches to player during exercise
    --   2. Extended: {coords = vector4(x, y, z, h), bar = vector4(x, y, z, h)} - bar spawns at fixed world position
    props = {
        bench = {
            model = "vision_gymbench1_pepe",

            playerAnimation = {
                dict = 'amb@prop_human_seat_muscle_bench_press@idle_a',
                name = 'idle_a',
                offsets = {
                    vec3(0.0, 0.3, 0.3),
                    vec3(0.0, 0.0, 0.0)
                },
                prop = {
                    model = "vision_gymbarbell_withweight",
                    offsets = {
                        vector3(0.159, 0.392, 0.048),
                        vector3(-15.544, -46.527, 76.150)
                    },
                    bone = 57005
                }
            },

            repetitions = 1
        },
        vin_chu = {
            model = "vin_chu",

            animations = {
                dict = "prompt@vin_chu",
                name = "vin_chu@skel_clip_0",
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "vin_chu_ped",
                offsets = {
                    vec3(0.7, 0.0, 1.0),
                    vec3(0.0, 0.0, 90.0)
                },
            },
        },

        leg_press = {
            model = "vision_gymlegpress",

            animations = {
                dict = "prompt@vision_gymlegpress",
                name = "vision_gymlegpress@skel_clip_0",
                delay = 250
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "press_ped",
                offsets = {
                    vec3(0.3, 0.0, 1.0),
                    vec3(0.0, 0.0, 180.0)
                },
            },

            repetitions = 5, -- Number of animation repetitions per exercise session

        },

        speedbag = {
            model = "vision_gymspeedbagwall",

            animations = {
                dict = "prompt@vision_gymspeedbagwall",
                name = "vision_gymspeedbagwall@skel_clip_0",
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "punch",
                offsets = {
                    vec3(-1.0, 0.0, -0.5),
                    vec3(0.0, 0.0, -90.0)
                },
            },
        },

        gymbike = {
            model = "vision_gymbike",

            animations = {
                dict = "prompt@vision_gymbike",
                name = "vision_gymbike@skel_clip_0",
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "gym_bike",
                offsets = {
                    vec3(0.0, 0.15, 1.0),
                    vec3(0.0, 0.0, 180.0)
                },
            },

            repetitions = 5
        },

        gymlatpull = {
            model = "vision_gymlatpull",

            animations = {
                dict = "prompt@vision_gymlatpull",
                name = "vision_gymlatpull@skel_clip_0",
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "gym_latpull",
                offsets = {
                    vec3(-0.68, 0.0, 0.97),
                    vec3(0.0, 0.0, 90.0)
                },
            },

            repetitions = 1
        },

        gympullmachine1 = {
            model = "vision_gympullmachine1",

            animations = {
                dict = "prompt@vision_gympullmachine1",
                name = "vision_gympullmachine1@skel_clip_0",
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "gympullmachine1",
                offsets = {
                    vec3(-0.3, -1.1, 0.98),
                    vec3(0.0, 0.0, -90.0)
                },
            },

            repetitions = 5
        },

        gympullmachine2 = {
            model = "vision_gympullmachine2",

            animations = {
                dict = "prompt@vision_gympullmachine2",
                name = "vision_gympullmachine2@skel_clip_0",
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "gympullmachine2",
                offsets = {
                    vec3(0.0, 1.02, 1.0),
                    vec3(0.0, 0.0, 180.0)
                },
            },

            repetitions = 5
        },

        gymrowpull = {
            model = "vision_gymrowpull",

            animations = {
                dict = "prompt@vision_gymrowpull",
                name = "vision_gymrowpull@skel_clip_0",
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "gymrowpull_ped",
                offsets = {
                    vec3(0.0, 0.4, 0.95),
                    vec3(0.0, 0.0, 180.0)
                },
            },

            repetitions = 5
        },

        gymspeedbag = {
            model = "vision_gymspeedbag",

            animations = {
                dict = "prompt@vision_gymspeedbag",
                name = "vision_gymspeedbag@skel_clip_0",
            },

            playerAnimation = {
                dict = "prompt@gym_ped",
                name = "gymspeedbag_ped",
                offsets = {
                    vec3(0.0, 0.7, 1.0),
                    vec3(0.0, 0.0, 180.0)
                },
            },

            repetitions = 5
        }
    }
}