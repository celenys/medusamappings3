Config = {
    -- Configuración general
    EnablePlayerAnimations = true, -- Habilitar/deshabilitar animaciones de jugador
    SpawnDistance = 80.0, -- Distancia para spawnear los props

    Props = {
    	lift_1 = {
    		location = "highway",
		    name = "prompt_sandy_is_lift_mechanic_1",
		    displayName = "Car Lift 1",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(2589.301, 481.663361, 108.254745),
		    rotation = vector3(0.0, 0.0, -35.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_1",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(2589.301, 481.663361, 107.503),
		        rotation = vector3(0.0, 0.0, -35.0),
		        startCoords = vector3(2589.301, 481.663361, 107.503),
		        endCoords = vector3(2589.301, 481.663361, 109.4),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(2588.301, 482.663361, 108.254745),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = 35.0
		    }
		},
		lift_2 = {
			location = "highway",
		    name = "prompt_sandy_is_lift_mechanic_2",
		    displayName = "Car Lift 2",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(2589.27783, 486.527954, 108.254745),
		    rotation = vector3(0.0, 0.0, -35.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_2",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(2589.27783, 486.527954, 107.503),
		        rotation = vector3(0.0, 0.0, -35.0),
		        startCoords = vector3(2589.27783, 486.527954, 107.503),
		        endCoords = vector3(2589.27783, 486.527954, 109.4),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(2588.27783, 487.527954, 108.254745),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -35.0
		    }
		},
		lift_3 = {
			location = "city",
		    name = "prompt_sandy_is_lift_mechanic_3",
		    displayName = "Car Lift 3",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(1005.33789, -1390.79419, 31.0960674),
		    rotation = vector3(0.0, 0.0, -30.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_3",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(1005.33789, -1390.79419, 30.3450674),
		        rotation = vector3(0.0, 0.0, -30.0),
		        startCoords = vector3(1005.33789, -1390.79419, 30.3450674),
		        endCoords = vector3(1005.33789, -1390.79419, 32.2420674),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(1004.33789, -1389.79419, 31.0960674),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -30.0
		    }
		},
		lift_4 = {
			location = "city",
		    name = "prompt_sandy_is_lift_mechanic_4",
		    displayName = "Car Lift 4",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(1005.26886, -1385.81177, 31.0958271),
		    rotation = vector3(0.0, 0.0, -30.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_4",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(1005.26886, -1385.81177, 30.3448271),
		        rotation = vector3(0.0, 0.0, -30.0),
		        startCoords = vector3(1005.26886, -1385.81177, 30.3448271),
		        endCoords = vector3(1005.26886, -1385.81177, 32.2418271),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(1004.26886, -1384.81177, 31.0958271),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -30.0
		    }
		},
		lift_5 = {
			location = "beach",
		    name = "prompt_sandy_is_lift_mechanic_5",
		    displayName = "Car Lift 5",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(-1666.01025, -785.792664, 9.892327),
		    rotation = vector3(0.0, 0.0, -70.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_5",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(-1666.01025, -785.792664, 9.141327),
		        rotation = vector3(0.0, 0.0, -70.0),
		        startCoords = vector3(-1666.01025, -785.792664, 9.141327),
		        endCoords = vector3(-1666.01025, -785.792664, 11.038327),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(-1667.01025, -784.792664, 9.892327),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -70.0
		    }
		},
		lift_6 = {
			location = "beach",
		    name = "prompt_sandy_is_lift_mechanic_6",
		    displayName = "Car Lift 6",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(-1669.17493, -789.532654, 9.892327),
		    rotation = vector3(0.0, 0.0, -70.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_6",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(-1669.17493, -789.532654, 9.141327),
		        rotation = vector3(0.0, 0.0, -70.0),
		        startCoords = vector3(-1669.17493, -789.532654, 9.141327),
		        endCoords = vector3(-1669.17493, -789.532654, 11.038327),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(-1670.17493, -788.532654, 9.892327),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -70.0
		    }
		},
		lift_7 = {
			location = "chumash",
		    name = "prompt_sandy_is_lift_mechanic_7",
		    displayName = "Car Lift 7",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(-2950.03174, 441.7606, 14.9530125),
		    rotation = vector3(0.0, 0.0, -35.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_7",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(-2950.03174, 441.7606, 14.2020125),
		        rotation = vector3(0.0, 0.0, -35.0),
		        startCoords = vector3(-2950.03174, 441.7606, 14.2020125),
		        endCoords = vector3(-2950.03174, 441.7606, 16.0990125),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(-2951.03174, 442.7606, 14.9530125),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -35.0
		    }
		},
		lift_8 = {
			location = "chumash",
		    name = "prompt_sandy_is_lift_mechanic_8",
		    displayName = "Car Lift 8",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(-2950.28149, 436.9673, 14.9530125),
		    rotation = vector3(0.0, 0.0, -35.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_8",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(-2950.28149, 436.9673, 14.2020125),
		        rotation = vector3(0.0, 0.0, -35.0),
		        startCoords = vector3(-2950.28149, 436.9673, 14.2020125),
		        endCoords = vector3(-2950.28149, 436.9673, 16.0990125),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(-2951.28149, 437.9673, 14.9530125),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -35.0
		    }
		},
		lift_9 = {
			location = "paleto",
		    name = "prompt_sandy_is_lift_mechanic_9",
		    displayName = "Car Lift 9",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(-277.796051, 6030.797, 31.1866989),
		    rotation = vector3(0.0, 0.0, -75.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_9",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(-277.796051, 6030.797, 30.4356989),
		        rotation = vector3(0.0, 0.0, -75.0),
		        startCoords = vector3(-277.796051, 6030.797, 30.4356989),
		        endCoords = vector3(-277.796051, 6030.797, 32.3326989),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(-278.796051, 6031.797, 31.1866989),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -75.0
		    }
		},
		lift_10 = {
			location = "paleto",
		    name = "prompt_sandy_is_lift_mechanic_10",
		    displayName = "Car Lift 10",
		    model = "prompt_sandy_is_lift_mechanic",
		    coords = vector3(-274.291748, 6034.198, 31.1866989),
		    rotation = vector3(0.0, 0.0, -75.0),
		    collision = {
		        name = "prompt_sandy_is_lift_col_mechanic_10",
		        model = "prompt_sandy_is_lift_col_mechanic",
		        coords = vector3(-274.291748, 6034.198, 30.4356989),
		        rotation = vector3(0.0, 0.0, -75.0),
		        startCoords = vector3(-274.291748, 6034.198, 30.4356989),
		        endCoords = vector3(-274.291748, 6034.198, 32.3326989),
		        moveType = "coords",
		        liftSettings = {
		            upDelay = 300,
		            upSpeedFactor = 0.9,
		            downSpeedFactor = 0.9,
		            upCurve = "easeInQuad",
		            downCurve = "easeOutQuad"
		        }
		    },
		    animations = {
		        dict = "prompt_sandy_is_lift_new_new_mechanic",
		        open = "prompt_sandy_is_lift_opened",
		        close = "prompt_sandy_is_lift_closed",
		        static = "prompt_sandy_is_lift_static",
		        duration = 5000
		    },
		    interactionZone = {
		        coords = vector3(-275.291748, 6035.198, 31.1866989),
		        size = vector3(2.0, 2.0, 2.0),
		        rotation = -75.0
		    }
		}
    }
}
