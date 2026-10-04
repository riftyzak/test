--!strict
-- Creates the RemoteEvents the client and server talk through.
-- Treat everything the client sends as untrusted: validate on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAMES = {
	"Ping", -- client -> server: ping wheel choice; server -> all clients: show it
	"RevivePrompt", -- server -> client: team wiped, here are your revive options
	"ReviveChoice", -- client -> server: "free" | "token" (paid goes through ProcessReceipt)
	"RunResult", -- server -> client: coins earned, shown before returning to lobby
}

local folder = Instance.new("Folder")
folder.Name = "Remotes"
for _, name in NAMES do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
end
folder.Parent = ReplicatedStorage

local Remotes = {}
function Remotes.get(name: string): RemoteEvent
	return folder:FindFirstChild(name) :: RemoteEvent
end
return Remotes
