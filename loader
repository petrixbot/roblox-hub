-- PetrixHub Game Loader
local gameId = game.PlaceId
local gameName = game:GetService("MarketplaceService"):GetProductInfo(gameId).Name
local baseUrl = "https://raw.githubusercontent.com/petrixbot/roblox-hub/refs/heads/main/game/"

-- Supported Games Map
local supportedGames = {
    [84988808589910] = "84988808589910.lua", -- Rogue Piece (Main Map)
    [96105075537655] = "84988808589910.lua", -- Rogue Piece (Dungeon Map)
}

-- Load Script
local scriptPath = supportedGames[gameId]

if scriptPath then
    local scriptUrl = baseUrl .. scriptPath
    print("✅ PetrixHub support ", gameName)
    loadstring(game:HttpGet(scriptUrl, true))()
else
    warn("⚠️ PetrixHub does not support ", gameName)
end
