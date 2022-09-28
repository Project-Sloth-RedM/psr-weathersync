local CurrentWeather = Config.StartWeather
local lastWeather = CurrentWeather
local baseTime = Config.BaseTime
local timeOffset = Config.TimeOffset
local timer = 0
local freezeTime = Config.FreezeTime
local blackout = Config.Blackout
local blackoutVehicle = Config.BlackoutVehicle
local disable = Config.Disabled

RegisterNetEvent("PSRCore:Client:OnPlayerLoaded", function()
	disable = false
	TriggerServerEvent("psr-weathersync:server:RequestStateSync")
	-- TriggerServerEvent("psr-weathersync:server:RequestCommands")
end)

RegisterNetEvent("psr-weathersync:client:EnableSync", function()
	disable = false
	TriggerServerEvent("psr-weathersync:server:RequestStateSync")
end)

RegisterNetEvent("psr-weathersync:client:DisableSync", function()
	disable = true
	CreateThread(function()
		while disable do
			SetRainLevel(0.0)
			SetWeatherTypePersist("SUNNY")
			SetWeatherTypeNow("SUNNY")
			SetWeatherTypeNowPersist("SUNNY")
			NetworkOverrideClockTime(12, 0, 0)
			Wait(5000)
		end
	end)
end)

RegisterNetEvent("psr-weathersync:client:SyncWeather", function(NewWeather, newblackout)
	CurrentWeather = NewWeather
	blackout = newblackout
end)

-- RegisterNetEvent("psr-weathersync:client:RequestCommands", function(isAllowed)
-- 	if isAllowed then
-- 		TriggerEvent("chat:addSuggestion", "/freezetime", Lang:t("help.freezecommand"), {})
-- 		TriggerEvent("chat:addSuggestion", "/freezeweather", Lang:t("help.freezeweathercommand"), {})
-- 		TriggerEvent("chat:addSuggestion", "/weather", Lang:t("help.weathercommand"), {
-- 			{ name = Lang:t("help.weathertype"), help = Lang:t("help.availableweather") },
-- 		})
-- 		TriggerEvent("chat:addSuggestion", "/blackout", Lang:t("help.blackoutcommand"), {})
-- 		TriggerEvent("chat:addSuggestion", "/morning", Lang:t("help.morningcommand"), {})
-- 		TriggerEvent("chat:addSuggestion", "/noon", Lang:t("help.nooncommand"), {})
-- 		TriggerEvent("chat:addSuggestion", "/evening", Lang:t("help.eveningcommand"), {})
-- 		TriggerEvent("chat:addSuggestion", "/night", Lang:t("help.nightcommand"), {})
-- 		TriggerEvent("chat:addSuggestion", "/time", Lang:t("help.timecommand"), {
-- 			{ name = Lang:t("help.timehname"), help = Lang:t("help.timeh") },
-- 			{ name = Lang:t("help.timemname"), help = Lang:t("help.timem") },
-- 		})
-- 	end
-- end)

RegisterNetEvent("psr-weathersync:client:SyncTime", function(base, offset, freeze)
	freezeTime = freeze
	timeOffset = offset
	baseTime = base
end)

CreateThread(function()
	while true do
		if not disable then
			if lastWeather ~= CurrentWeather then
				lastWeather = CurrentWeather
				Citizen.InvokeNative(0x59174F1AFE095B5A, GetHashKey(CurrentWeather), false, true, true, 45.0, false) -- SetWeatherType
				Wait(15000)
			end
			Wait(100) -- Wait 0 seconds to prevent crashing.
			SetArtificialLightsState(blackout)
			-- SetArtificialLightsStateAffectsVehicles(blackoutVehicle)
			--ClearOverrideWeather()
			--ClearWeatherTypePersist()
			--SetWeatherTypeTransition(lastWeather)
			--SetWeatherTypeNowPersist(lastWeather)
			--SetWeatherTypeTransition(GetHashKey(lastWeather),GetHashKey(CurrentWeather), 0.7, 1)
			Citizen.InvokeNative(0xFA3E3CA8A1DE6D5D, GetHashKey(lastWeather), GetHashKey(CurrentWeather), 0.7, 1)
			--Citizen.InvokeNative(0x59174F1AFE095B5A, GetHashKey(CurrentWeather), false, true, true, 45.0, false)
			if lastWeather == "SNOW" or lastWeather == "WHITEOUT" then
				Citizen.InvokeNative(0xF6BEE7E80EC5CA40, 1) -- SetSnowLevel
			end
			if lastWeather == "DRIZZLE" or lastWeather == "SLEET" then
				Citizen.InvokeNative(0x193DFC0526830FD6, 0.2)
			elseif
				lastWeather == "RAIN"
				or lastWeather == "HAIL"
				or lastWeather == "SHOWER"
				or lastWeather == "THUNDER"
			then
				Citizen.InvokeNative(0x193DFC0526830FD6, 0.5)
			elseif lastWeather == "THUNDERSTORM" then
				Citizen.InvokeNative(0x193DFC0526830FD6, 0.7) -- SetRainLevel
			else
				Citizen.InvokeNative(0x193DFC0526830FD6, 0.0)
				Citizen.InvokeNative(0xF6BEE7E80EC5CA40, 0)
			end
		else
			Wait(1000)
		end
	end
end)

CreateThread(function()
	local hour = 0
	local minute = 0
	local second = 0 --Add seconds for shadow smoothness
	while true do
		if not disable then
			Wait(0)
			local newBaseTime = baseTime
			if GetGameTimer() - 22 > timer then --Generate seconds in client side to avoid communiation
				second = second + 1 --Minutes are sent from the server every 2 seconds to keep sync
				timer = GetGameTimer()
			end
			if freezeTime then
				timeOffset = timeOffset + baseTime - newBaseTime
			end
			baseTime = newBaseTime
			hour = math.floor(((baseTime + timeOffset) / 60) % 24)
			if minute ~= math.floor((baseTime + timeOffset) % 60) then --Reset seconds to 0 when new minute
				minute = math.floor((baseTime + timeOffset) % 60)
				second = 0
			end
			NetworkClockTimeOverride(hour, minute, second) --Send hour included seconds to network clock time
		else
			Wait(1000)
		end
	end
end)
