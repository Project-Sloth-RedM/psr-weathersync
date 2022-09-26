Config                  = {}
Config.DynamicWeather   = true -- Set this to false if you don't want the weather to change automatically every 10 minutes.

-- On server start
Config.StartWeather     = 'SUNNY' -- Default weather                       default: 'EXTRASUNNY'
Config.BaseTime         = 8 -- Time                                             default: 8
Config.TimeOffset       = 0 -- Time offset                                      default: 0
Config.FreezeTime       = false -- freeze time                                  default: false
Config.Blackout         = false -- Set blackout                                 default: false
Config.BlackoutVehicle  = false -- Set blackout affects vehicles                default: false
Config.NewWeatherTimer  = 10 -- Time (in minutes) between each weather change   default: 10
Config.Disabled         = false -- Set weather disabled                         default: false


Config.AvailableWeatherTypes = { -- DON'T TOUCH EXCEPT IF YOU KNOW WHAT YOU ARE DOING
    "BLIZZARD",			--0x27EA2814  --- Snow 
    "CLOUDS",			--0x30FDAF5C
    "DRIZZLE",			--0x995C7F44  --- 
    "FOG",				--0xD61BDE01
    "GROUNDBLIZZARD",		--0x7F622122
    "HAIL",				--0x75A9E268
    "HIGHPRESSURE",			--0xF5A87B65
    "HURRICANE",			--0x320D0951
    "MISTY",			--0x5974E8E5
    "OVERCAST",			--0xBB898D2D
    "OVERCASTDARK",			--0x19D4F1D9
    "RAIN",				--0x54A69840
    "SANDSTORM",			--0xB17F6111 -- Sandstorm
    "SHOWER",			--0xE72679D5   --- Sun and Rain
    "SLEET",			--0x0CA71D7C
    "SNOW",				--0xEFB6EFF6
    "SNOWLIGHT",	    		--0x23FB812B
    "SUNNY",	        	--0x614A1F91
    "THUNDER",	        	--0xB677829F
    "THUNDERSTORM",			--0x7C1C4A13
    "WHITEOUT",	    		--0x2B402288
}
