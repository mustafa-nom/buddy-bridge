--!strict
-- Per-player connection registry. When a player leaves, every connection
-- registered against them gets disconnected. Keeps services from leaking
-- handlers across rejoins.

local SignalTracker = {}

local perPlayer: { [Player]: { RBXScriptConnection } } = {}

local function bucket(player: Player): { RBXScriptConnection }
	local list = perPlayer[player]
	if not list then
		list = {}
		perPlayer[player] = list
	end
	return list
end

function SignalTracker.Track(player: Player, signal: RBXScriptSignal, handler: (...any) -> ()): RBXScriptConnection
	local connection = signal:Connect(handler)
	table.insert(bucket(player), connection)
	return connection
end

function SignalTracker.Adopt(player: Player, connection: RBXScriptConnection)
	table.insert(bucket(player), connection)
end

function SignalTracker.Cleanup(player: Player)
	local list = perPlayer[player]
	if not list then return end
	for _, c in ipairs(list) do
		if c.Connected then c:Disconnect() end
	end
	perPlayer[player] = nil
end

return SignalTracker
