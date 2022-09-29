local PSRCore = exports["psr-core"]:GetCoreObject()

local CurrentWeather = Config.StartWeather
local baseTime = Config.BaseTime
local timeOffset = Config.TimeOffset
local freezeTime = Config.FreezeTime
local blackout = Config.Blackout
local newWeatherTimer = Config.NewWeatherTimer

--- Does source have permissions to run admin commands
--- @param src number - Source to check
--- @return boolean - has permission
local function isAllowedToChange(src)
	if src == 0 or PSRCore.Functions.HasPermission(src, "admin") or IsPlayerAceAllowed(src, "command") then
		return true
	end
	return false
end

--- Sets time offset based on minutes provided
--- @param minute number - Minutes to offset by
local function shiftToMinute(minute)
	timeOffset = timeOffset - (((baseTime + timeOffset) % 60) - minute)
end

--- Sets time offset based on hour provided
--- @param hour number - Hour to offset by
local function shiftToHour(hour)
	timeOffset = timeOffset - ((((baseTime + timeOffset) / 60) % 24) - hour) * 60
end

--- Triggers event to switch weather to next stage
local function nextWeatherStage()
	if CurrentWeather == "SUNNY" or CurrentWeather == "CLOUDS" or CurrentWeather == "HIGHPRESSURE" then
		CurrentWeather = (math.random(1, 5) > 2) and "SUNNY" or "OVERCAST" -- 60/40 chance
	elseif CurrentWeather == "SUNNY" or CurrentWeather == "OVERCAST" then
		local new = math.random(1, 6)
		if new == 1 then
			CurrentWeather = (CurrentWeather == "SUNNY") and "OVERCAST" or "RAIN"
		elseif new == 2 then
			CurrentWeather = "CLOUDS"
		elseif new == 3 then
			CurrentWeather = "SUNNY"
		elseif new == 4 then
			CurrentWeather = "HIGHPRESSURE"
		elseif new == 5 then
			CurrentWeather = "SANDSTORM"
		else
			CurrentWeather = "FOG"
		end
	elseif CurrentWeather == "THUNDER" or CurrentWeather == "RAIN" or CurrentWeather == "THUNDERSTORM" then
		CurrentWeather = "OVERCASTDARK"
	elseif CurrentWeather == "OVERCASTDARK" then
		CurrentWeather = "SUNNY"
	elseif CurrentWeather == "SMOG" or CurrentWeather == "FOG" then
		CurrentWeather = "SUNNY"
	else
		CurrentWeather = "HIGHPRESSURE"
	end
	TriggerEvent("psr-weathersync:server:RequestStateSync")
end

--- Switch to a specified weather type
--- @param weather string - Weather type from Config.AvailableWeatherTypes
--- @return boolean - success
local function setWeather(weather)
	local validWeatherType = false
	for _, weatherType in pairs(Config.AvailableWeatherTypes) do
		if weatherType == string.upper(weather) then
			validWeatherType = true
		end
	end
	if not validWeatherType then
		return false
	end
	CurrentWeather = string.upper(weather)
	newWeatherTimer = Config.NewWeatherTimer
	TriggerEvent("psr-weathersync:server:RequestStateSync")
	return true
end

--- Sets sun position based on time to specified
--- @param hour number|string - Hour to set (0-24)
--- @param minute number|string `optional` - Minute to set (0-60)
--- @return boolean - success
local function setTime(hour, minute)
	local argh = tonumber(hour)
	local argm = tonumber(minute) or 0
	if argh == nil or argh > 24 then
		print(Lang:t("time.invalid"))
		return false
	end
	shiftToHour((argh < 24) and argh or 0)
	shiftToMinute((argm < 60) and argm or 0)
	print(Lang:t("time.change", { value = argh, value2 = argm }))
	TriggerEvent("psr-weathersync:server:RequestStateSync")
	return true
end

--- Sets or toggles blackout state and returns the state
--- @param state boolean `optional` - enable blackout?
--- @return boolean - blackout state
local function setBlackout(state)
	if state == nil then
		state = not blackout
	end
	if state then
		blackout = true
	else
		blackout = false
	end
	TriggerEvent("psr-weathersync:server:RequestStateSync")
	return blackout
end

--- Sets or toggles time freeze state and returns the state
--- @param state boolean `optional` - Enable time freeze?
--- @return boolean - Time freeze state
local function setTimeFreeze(state)
	if state == nil then
		state = not freezeTime
	end
	if state then
		freezeTime = true
	else
		freezeTime = false
	end
	TriggerEvent("psr-weathersync:server:RequestStateSync")
	return freezeTime
end

--- Sets or toggles dynamic weather state and returns the state
--- @param state boolean `optional` - Enable dynamic weather?
--- @return boolean - Dynamic Weather state
local function setDynamicWeather(state)
	if state == nil then
		state = not Config.DynamicWeather
	end
	if state then
		Config.DynamicWeather = true
	else
		Config.DynamicWeather = false
	end
	TriggerEvent("psr-weathersync:server:RequestStateSync")
	return Config.DynamicWeather
end

-- EVENTS

RegisterNetEvent("psr-weathersync:server:RequestStateSync", function()
	TriggerClientEvent("psr-weathersync:client:SyncWeather", -1, CurrentWeather, blackout)
	TriggerClientEvent("psr-weathersync:client:SyncTime", -1, baseTime, timeOffset, freezeTime)
end)

RegisterNetEvent("psr-weathersync:server:RequestCommands", function()
	local src = source
	if isAllowedToChange(src) then
		TriggerClientEvent("psr-weathersync:client:RequestCommands", src, true)
	end
end)

RegisterNetEvent("psr-weathersync:server:setWeather", function(weather)
	local src = source
	if isAllowedToChange(src) then
		local success = setWeather(weather)
		if src > 0 then
			if success then
				TriggerClientEvent("PSRCore:Notify", src, Lang:t("weather.updated"), "success", 5000)
			else
				TriggerClientEvent("PSRCore:Notify", src, Lang:t("weather.invalid"), "success", 5000)
			end
		end
	end
end)

RegisterNetEvent("psr-weathersync:server:setTime", function(hour, minute)
	local src = source
	if isAllowedToChange(src) then
		local success = setTime(hour, minute)
		if src > 0 then
			if success then
				TriggerClientEvent(
					"PSRCore:Notify",
					src,
					Lang:t("time.change", { value = hour, value2 = minute or "00" }),
					"success",
					5000
				)
			else
				TriggerClientEvent("PSRCore:Notify", src, Lang:t("time.invalid"), "success", 5000)
			end
		end
	end
end)

RegisterNetEvent("psr-weathersync:server:toggleBlackout", function(state)
	local src = source
	if isAllowedToChange(src) then
		local newstate = setBlackout(state)
		if src > 0 then
			if newstate then
				TriggerClientEvent("PSRCore:Notify", src, Lang:t("blackout.enabled"), "success", 5000)
			else
				TriggerClientEvent("PSRCore:Notify", src, Lang:t("blackout.disabled"), "success", 5000)
			end
		end
	end
end)

RegisterNetEvent("psr-weathersync:server:toggleFreezeTime", function(state)
	local src = source
	if isAllowedToChange(src) then
		local newstate = setTimeFreeze(state)
		if src > 0 then
			if newstate then
				TriggerClientEvent("PSRCore:Notify", src, Lang:t("time.now_frozen"), "success", 5000)
			else
				TriggerClientEvent("PSRCore:Notify", src, Lang:t("time.now_unfrozen"), "success", 5000)
			end
		end
	end
end)

RegisterNetEvent("psr-weathersync:server:toggleDynamicWeather", function(state)
	local src = source
	if isAllowedToChange(src) then
		local newstate = setDynamicWeather(state)
		if src > 0 then
			if newstate then
				TriggerClientEvent("PSRCore:Notify", src, Lang:t("weather.now_unfrozen"), "success", 5000)
			else
				TriggerClientEvent("PSRCore:Notify", src, 9, Lang:t("weather.now_frozen"), "success", 5000)
			end
		end
	end
end)

-- COMMANDS
PSRCore.Commands.Add("freezetime", Lang:t("help.freezecommand"), {}, false, function(source, args)
	local newState = setTimeFreeze()
	if newState then
		TriggerClientEvent("PSRCore:Notify", source, Lang:t("time.frozenc"), "success", 5000)
		print(Lang:t("time.now_frozen"))
	else
		TriggerClientEvent("PSRCore:Notify", source, Lang:t("time.unfrozenc"), "success", 5000)
		print(Lang:t("time.now_unfrozen"))
	end
end, "god")

PSRCore.Commands.Add("freezeweather", Lang:t("help.freezeweathercommand"), {}, false, function(source, args)
	local newState = setDynamicWeather()
	if newState then
		TriggerClientEvent("PSRCore:Notify", source, Lang:t("dynamic_weather.enabled"), "success", 5000)
		print(Lang:t("weather.now_unfrozen"))
	else
		TriggerClientEvent("PSRCore:Notify", source, Lang:t("dynamic_weather.disabled"), "success", 5000)
		print(Lang:t("weather.now_frozen"))
	end
end, "god")

PSRCore.Commands.Add(
	"weather",
	Lang:t("help.weathercommand"),
	{ { name = Lang:t("help.weathertype"), help = Lang:t("help.availableweather") } },
	true,
	function(source, args)
		local weatherType = tostring(args[1]):lower()
		local success = setWeather(weatherType)
		if success then
			TriggerClientEvent(
				"PSRCore:Notify",
				source,
				Lang:t("weather.willchangeto", { value = string.lower(args[1]) }),
				"success",
				5000
			)
			print(Lang:t("weather.updated"))
		else
			print(Lang:t("weather.invalid"))
		end
	end,
	"god"
)

PSRCore.Commands.Add("blackout", Lang:t("help.blackoutcommand"), {}, false, function(source, args)
	local newState = setBlackout()
	if newState then
		TriggerClientEvent("PSRCore:Notify", source, Lang:t("blackout.enabledc"), "success", 5000)
		print(Lang:t("blackout.enabled"))
	else
		TriggerClientEvent("PSRCore:Notify", source, Lang:t("blackout.disabledc"), "success", 5000)
		print(Lang:t("blackout.disabled"))
	end
end, "god")

PSRCore.Commands.Add("morning", Lang:t("help.morningcommand"), {}, false, function(source, args)
	setTime(9, 0)
	TriggerClientEvent("PSRCore:Notify", source, Lang:t("time.morning"), "success", 5000)
end, "god")

PSRCore.Commands.Add("noon", Lang:t("help.nooncommand"), {}, false, function(source, args)
	setTime(12, 0)
	TriggerClientEvent("PSRCore:Notify", source, Lang:t("time.noon"), "success", 5000)
end, "god")

PSRCore.Commands.Add("evening", Lang:t("help.eveningcommand"), {}, false, function(source, args)
	setTime(18, 0)
	TriggerClientEvent("PSRCore:Notify", source, Lang:t("time.evening"), "success", 5000)
end, "god")

PSRCore.Commands.Add("night", Lang:t("help.nightcommand"), {}, false, function(source, args)
	setTime(23, 0)
	TriggerClientEvent("PSRCore:Notify", source, Lang:t("time.night"), "success", 5000)
end, "god")

PSRCore.Commands.Add(
	"time",
	Lang:t("help.timecommand"),
	{
		{ name = Lang:t("help.timehname"), help = Lang:t("help.timeh") },
		{ name = Lang:t("help.timemname"), help = Lang:t("help.timem") },
	},
	true,
	function(source, args)
		local hour = tonumber(args[1])
		local minute = tonumber(args[2])
		local success = setTime(hour, minute)
		if success then
			TriggerClientEvent(
				"PSRCore:Notify",
				source,
				Lang:t("time.changec", { value = args[1] .. ":" .. (args[2] or "00") }),
				"success",
				5000
			)
			print(Lang:t("time.change", { value = args[1], value2 = args[2] or "00" }))
		else
			print(Lang:t("time.invalid"))
		end
	end,
	"god"
)

-- THREAD LOOPS

CreateThread(function()
	local previous = 0
	while true do
		Wait(0)
		local newBaseTime = os.time(os.date("!*t")) / 2 + 360 --Set the server time depending of OS time
		if (newBaseTime % 60) ~= previous then --Check if a new minute is passed
			previous = newBaseTime % 60 --Only update time with plain minutes, seconds are handled in the client
			if freezeTime then
				timeOffset = timeOffset + baseTime - newBaseTime
			end
			baseTime = newBaseTime
		end
	end
end)

CreateThread(function()
	while true do
		Wait(2000) --Change to send every minute in game sync
		TriggerClientEvent("psr-weathersync:client:SyncTime", -1, baseTime, timeOffset, freezeTime)
	end
end)

CreateThread(function()
	while true do
		Wait(300000)
		TriggerClientEvent("psr-weathersync:client:SyncWeather", -1, CurrentWeather, blackout)
	end
end)

CreateThread(function()
	while true do
		newWeatherTimer = newWeatherTimer - 1
		Wait((1000 * 60) * Config.NewWeatherTimer)
		if newWeatherTimer == 0 then
			if Config.DynamicWeather then
				nextWeatherStage()
			end
			newWeatherTimer = Config.NewWeatherTimer
		end
	end
end)

-- EXPORTS

exports("nextWeatherStage", nextWeatherStage)
exports("setWeather", setWeather)
exports("setTime", setTime)
exports("setBlackout", setBlackout)
exports("setTimeFreeze", setTimeFreeze)
exports("setDynamicWeather", setDynamicWeather)
exports("getBlackoutState", function()
	return blackout
end)
exports("getTimeFreezeState", function()
	return freezeTime
end)
exports("getWeatherState", function()
	return CurrentWeather
end)
exports("getDynamicWeather", function()
	return Config.DynamicWeather
end)
