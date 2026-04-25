--!strict
-- Shared badge options for Stranger Danger Park.

local BadgeConfig = {}

BadgeConfig.Colors = {
	Red = Color3.fromRGB(220, 70, 70),
	Blue = Color3.fromRGB(70, 130, 230),
	Green = Color3.fromRGB(80, 180, 95),
	Yellow = Color3.fromRGB(245, 210, 70),
}

BadgeConfig.ColorOrder = { "Red", "Blue", "Green", "Yellow" }
BadgeConfig.ShapeOrder = { "Star", "Circle", "Square", "Triangle" }

export type Badge = {
	Color: string,
	Shape: string,
}

function BadgeConfig.IsValidColor(color: string?): boolean
	return typeof(color) == "string" and BadgeConfig.Colors[color] ~= nil
end

function BadgeConfig.IsValidShape(shape: string?): boolean
	return typeof(shape) == "string" and table.find(BadgeConfig.ShapeOrder, shape) ~= nil
end

function BadgeConfig.IsValidBadge(badge: any): boolean
	return typeof(badge) == "table"
		and BadgeConfig.IsValidColor(badge.Color)
		and BadgeConfig.IsValidShape(badge.Shape)
end

function BadgeConfig.Key(color: string, shape: string): string
	return color .. ":" .. shape
end

function BadgeConfig.BadgeKey(badge: Badge): string
	return BadgeConfig.Key(badge.Color, badge.Shape)
end

function BadgeConfig.AllBadges(): { Badge }
	local badges = {}
	for _, color in ipairs(BadgeConfig.ColorOrder) do
		for _, shape in ipairs(BadgeConfig.ShapeOrder) do
			table.insert(badges, {
				Color = color,
				Shape = shape,
			})
		end
	end
	return badges
end

return BadgeConfig
