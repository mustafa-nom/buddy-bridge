--!strict
-- Minimal TopbarPlus stub. Satchel requires `script.Parent.topbarplus`
-- and uses the Icon class only for the optional topbar inventory
-- button. Vendoring the real TopbarPlus brings in dozens of nested
-- files (src/Elements, src/Features, src/Packages); we don't actually
-- need that visible chrome — the hotbar at the bottom of the screen
-- is all we want from Satchel.
--
-- This stub returns an Icon factory whose chained setters all no-op
-- (returning self) so Satchel's setup chain runs to completion. The
-- `toggled` BindableEvent and `enabled` flag exist so connections
-- and visibility checks don't error, but the button is never actually
-- rendered.

local Icon = {}
Icon.__index = Icon

function Icon.new()
	local self = setmetatable({
		enabled = true,
		toggled = Instance.new("BindableEvent").Event,
		_toggleEvent = nil,
	}, Icon)
	return self
end

local CHAIN_METHODS = {
	"setName", "setImage", "setImageScale", "setCaption",
	"bindToggleKey", "autoDeselect", "setOrder",
	"lock", "unlock", "deselect",
}
for _, name in ipairs(CHAIN_METHODS) do
	Icon[name] = function(self) return self end
end

function Icon:setEnabled(value: boolean)
	self.enabled = value
	return self
end

return Icon
