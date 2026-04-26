--!strict
-- Minimal analytics. Prints structured events to the Studio output for the
-- judges to skim. No external service.

local HttpService = game:GetService("HttpService")

local AnalyticsService = {}

function AnalyticsService.Emit(eventName: string, data: { [string]: any }?)
	local body = data and HttpService:JSONEncode(data) or ""
	print(("[Analytics] %s %s"):format(eventName, body))
end

function AnalyticsService.Init() end

return AnalyticsService
