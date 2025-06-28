local enums = {}

-- Game phases
enums.GamePhase = {
    PLAYER_ORDER = "PLAYER_ORDER",
    AUCTION = "AUCTION",
    RESOURCE_BUYING = "RESOURCE_BUYING",
    BUILDING = "BUILDING",
    BUREAUCRACY = "BUREAUCRACY"
}

-- Resource types
enums.ResourceType = {
    COAL = "COAL",
    OIL = "OIL",
    HYBRID = "HYBRID",
    GARBAGE = "GARBAGE",
    URANIUM = "URANIUM",
    WIND = "WIND",
    SOLAR = "SOLAR"
}

-- Resource Colors
enums.ResourceColors = {
    [enums.ResourceType.COAL] = {0.2, 0.2, 0.2, 1},
    [enums.ResourceType.OIL] = {0.8, 0.8, 0.2, 1},
    [enums.ResourceType.HYBRID] = {0.8, 0.4, 0.2, 1},
    [enums.ResourceType.GARBAGE] = {0.4, 0.4, 0.4, 1},
    [enums.ResourceType.URANIUM] = {0.2, 0.8, 0.2, 1},
    [enums.ResourceType.WIND] = {0.6, 0.8, 1.0, 1},
    [enums.ResourceType.SOLAR] = {1.0, 0.8, 0.2, 1}
}

return enums 