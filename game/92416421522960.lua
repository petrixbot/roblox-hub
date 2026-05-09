-- Handle first attach
if not game:IsLoaded() then game.Loaded:Wait() end
if getgenv().PETRIXHUB_LOADED then
    warn("[.petrixhub] Script already executed!")
    return
end

-- .petrixhub Configuration
local petrixhub_name    = "Slime RNG"
local petrixhub_folder  = "slime-rng"
local petrixhub_version = "v1.5.0"

-- Roblox Services
local cloneref = (cloneref or clonereference or function(i) return i end)

local CoreGui               = cloneref(game:GetService("CoreGui"))
local Players               = cloneref(game:GetService("Players"))
local Lighting              = cloneref(game:GetService("Lighting"))
local Workspace             = cloneref(game:GetService("Workspace"))
local GuiService            = cloneref(game:GetService("GuiService"))
local RunService            = cloneref(game:GetService("RunService"))
local VirtualUser           = cloneref(game:GetService("VirtualUser"))
local HttpService           = cloneref(game:GetService("HttpService"))
local TweenService          = cloneref(game:GetService("TweenService"))
local TeleportService       = cloneref(game:GetService("TeleportService"))
local MaterialService       = cloneref(game:GetService("MaterialService"))
local UserInputService      = cloneref(game:GetService("UserInputService"))
local ReplicatedStorage     = cloneref(game:GetService("ReplicatedStorage"))
local VirtualInputManager   = cloneref(game:GetService("VirtualInputManager"))

local LocalPlayer = Players.LocalPlayer

-- WindUI Library Source
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.63/main.lua"))()

local Window = WindUI:CreateWindow({
    Icon = "star",
    Title = petrixhub_name,
    Author = "by .petrixhub",
    Folder = petrixhub_folder,
    
	NewElements = true,
    Acrylic = true,
    
    Size = UDim2.fromOffset(800, 600),
    Transparent = true,
    Theme = "Sky",
    Resizable = false,
    SideBarWidth = 200,
    HideSearchBar = true,
    ScrollBarEnabled = true,
    ToggleKey = Enum.KeyCode.RightControl,
    
    Topbar = {
        Height = 50,
        ButtonsType = "Default"
    },
    
    OpenButton = {
        Title = ".petrixhub",
        Size = 0.9,
        CornerRadius = UDim.new(0, 20),
        StrokeThickness = 0,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false
    },
})

Window:Tag({
    Title = petrixhub_version,
    Color = Color3.fromHex("#EA9999")
})

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

local function safeRequire(path)
    local ok, result = pcall(require, path)
    return ok and result or nil
end

local Networker = safeRequire(ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networker"))
local DataService = safeRequire(ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("DataService"))
local DataClient = DataService and DataService.client or nil

local NetCache = {}
local function getNet(serviceName)
    if not NetCache[serviceName] and Networker then
        local ok, net = pcall(function() return Networker.client.new(serviceName, {}) end)
        if ok then NetCache[serviceName] = net end
    end
    return NetCache[serviceName]
end

local function netFetch(serviceName, method, ...)
    local net = getNet(serviceName)
    if not net then return false, "No networker" end
    local ok, a, b = pcall(net.fetch, net, method, ...)
    if ok then return a, b end
    return false, tostring(a)
end

local function getData(key)
    if not DataClient then return nil end
    local ok, result = pcall(DataClient.get, DataClient, key)
    return ok and result or nil
end

local function notify(title, content, icon, duration)
    WindUI:Notify({
        Title = title or ".petrixhub",
        Content = content or "",
        Icon = icon or "info",
        Duration = duration or 3
    })
end

local function sendWebhook(url, payload)
    if not url or url == "" then return end
    pcall(function()
        local req = (syn and syn.request) or http_request or request
        if req then
            req({ Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload })
        end
    end)
end

local function formatNumber(n)
    if type(n) ~= "number" then return "0" end
    local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
    if n < 1000 then return tostring(math.floor(n)) end
    local i = math.floor(math.log10(n) / 3)
    i = math.min(i, #suffixes - 1)
    local v = n / (10 ^ (i * 3))
    return string.format("%.1f%s", v, suffixes[i + 1])
end

--------------------------------------------------------------------------------
-- GAME HELPERS
--------------------------------------------------------------------------------
local function getGameplayFolder()
    for _, child in pairs(Workspace:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            if string.match(child.Name, "^Gameplay") then
                return child
            end
        end
    end
    return nil
end

local function getEnemiesFolder()
    local gp = getGameplayFolder()
    if gp then
        return gp:FindFirstChild("Enemies")
    end
    return nil
end

local function getClosestEnemy()
    local enemies = getEnemiesFolder()
    if not enemies then return nil end
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    for _, enemy in pairs(enemies:GetChildren()) do
        local pos = enemy:IsA("Model") and enemy:GetPivot().Position or (enemy:IsA("BasePart") and enemy.Position or nil)
        if pos then
            local d = (pos - hrp.Position).Magnitude
            if d < dist then
                closest = enemy
                dist = d
            end
        end
    end
    return closest, dist
end

--------------------------------------------------------------------------------
-- GAME CONSTANTS
--------------------------------------------------------------------------------
local RECIPES = {"crafty", "thorn", "geode", "slimeSlimeSlime", "puffy", "astro", "sunny", "melly"}
local FOODS = {"apple", "carrot", "cherries", "grapes", "banana", "watermelon", "pizza", "chicken", "drumstick"}
local MUTATIONS = {"Base", "big", "huge", "shiny", "inverted"}
local BOOST_KINDS = {"luck", "ultraLuck", "currency", "rollSpeed"}
local DICE_TYPES = {"jackpotSpin", "bigDice", "hugeDice", "shinyDice", "invertedDice"}
local SPECIAL_ROLLS = {"golden", "diamond", "void"}
local UPGRADE_KEYS = {"luck", "rollSpeed", "cloverRolls", "bonusRolls", "extraRollChance", "coinIncome", "slots", "enemyCount", "enemySpawnSpeed", "slimeTargetRange", "overkill", "bigEnemyChance", "shinyEnemyChance", "hugeEnemyChance", "invertedEnemyChance", "offlineLootAmount", "magnetRadius", "walkSpeed", "friendLuck", "friendLuckBoost", "goopDropRate"}
local MAX_ZONES = 25

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local S = {
    AutoRoll = false,
    AutoEquipBest = false, EquipMode = "Default", AutoBuyZone = false, AutoTeleportBestZone = false, MaxZoneLimit = 28,
    AutoRebirth = false, AutoCollectLoot = false, AutoClaimOffline = false, AutoClaimIndex = false,
    CombatEnabled = false, CombatMethod = "Walk", CombatSpeed = 1, CombatTweenDistance = 10,
    UpgradeEnabled = false, UpgradePriority = {},
    CraftEnabled = false, CraftRecipe = "crafty", CraftAmount = 0,
    CraftMutationFilter = {"Base", "big", "huge", "shiny", "inverted"}, CraftStopOnMutation = false, CraftCount = 0,
    CraftObtainedMutations = {}, -- tracks which mutations have been obtained during this craft session
    FeedEnabled = false, FeedFood = {"apple", "carrot", "cherries", "grapes", "banana", "watermelon", "pizza", "chicken", "drumstick"}, FeedAmount = 0, FeedTargetLevel = 0, FeedTargetSlime = nil,
    PotionEnabled = false, PotionSelection = {}, PotionAmount = 0, PotionMethod = "Bulk Use",
    DiceEnabled = false, DiceSaveRolls = {"void", "diamond", "golden"}, DiceSelection = {}, DiceUseOnUnpause = false,
    _diceStackBusy = false, _diceStackPhase = 0, _diceLastUnpauseTime = 0,
    GamepassDoubleRoll = false, GamepassFastRoll = false, GamepassLuckyRolls = false,
    GamepassVIP = false, GamepassAutoCollect = false, GamepassExtraEquip = false, GamepassMoreLoot = false,
    ForceRare = false, ForceMutation = false, ForceSpecialRoll = false,
    FakeLuck = false, FakeFood = false, DisableRejoin = true,
    BringEnemy = false, OneHitKill = false, BringDistance = 5,
    NotifyScript = true, NotifyMutation = true, NotifyMutationFilter = "Any",
    NotifyRarity = true, NotifyMinRarity = "Rare", NotifyLoot = true,
    WebhookURL = "", WebhookEnabled = false, WebhookInterval = 300, WebhookPingEveryone = false,
    WebhookSendOnObtained = false, WebhookMinOdds = 0, WebhookMutationFilter = "Any",
    WebhookMustHaveSlime = "",
    WebhookFieldOdds = true, WebhookFieldStats = true, WebhookFieldMutations = true, WebhookFieldLevel = true,
    WebhookSummaryEnabled = false,
    WebhookFieldPlayer = true, WebhookFieldSession = true, WebhookFieldCurrency = true,
    WebhookFieldZones = true, WebhookFieldAttributes = true, WebhookFieldEquipped = true,
    WebhookFieldInventory = true, WebhookFieldTopOwned = false, WebhookFieldItems = true,
    WebhookFieldBoosts = true, WebhookFieldUpgrades = true, WebhookFieldIndex = true, WebhookFieldRecent = true,
    AntiAFK = false, AntiGameplayPaused = false,
    WalkSpeed = 16, JumpPower = 50,
    InfiniteJump = false, NoclipChar = false, NoclipCam = false,
    ESPPlayers = false, ESPRecipe = false, ESPLoot = false,
    AutoReconnect = false, AutoExecute = false,
    MaxFPS = 60, HideGUI = false, DisableRendering = false, FPSBoost = false,
}

-- Session tracking
local SessionStart = os.time()
local SessionRolls = 0
local SessionRebirths = 0
local RecentObtained = {}

--------------------------------------------------------------------------------
-- SECTIONS & TABS
--------------------------------------------------------------------------------
local Sections = {
    Automation  = Window:Section({ Title = "Automation",    Opened = true }),
    Bypass      = Window:Section({ Title = "Bypass",        Opened = false }),
    Notification= Window:Section({ Title = "Notification",  Opened = false }),
    MiscConfig  = Window:Section({ Title = "Misc & Config", Opened = false }),
}

local Tabs = {
    Farm        = Sections.Automation:Tab({     Title = "Farm",         Icon = "lucide:zap",                IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Combat      = Sections.Automation:Tab({     Title = "Combat",       Icon = "lucide:swords",             IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Upgrade     = Sections.Automation:Tab({     Title = "Upgrade",      Icon = "lucide:circle-plus",        IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Craft       = Sections.Automation:Tab({     Title = "Craft",        Icon = "lucide:hammer",             IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Feed        = Sections.Automation:Tab({     Title = "Feed",         Icon = "lucide:utensils",           IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Potion      = Sections.Automation:Tab({     Title = "Potion",       Icon = "lucide:flask-conical",      IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Dice        = Sections.Automation:Tab({     Title = "Dice",         Icon = "lucide:dice-5",             IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    
    Tutorial    = Sections.Bypass:Tab({         Title = "Tutorial",     Icon = "lucide:skip-forward",       IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Gamepass    = Sections.Bypass:Tab({         Title = "Gamepass",     Icon = "lucide:crown",              IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Enemy       = Sections.Bypass:Tab({         Title = "Enemy",        Icon = "lucide:target",             IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Manipulation= Sections.Bypass:Tab({         Title = "Manipulation", Icon = "lucide:wand-sparkles",      IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    
    Obtains     = Sections.Notification:Tab({   Title = "Obtains",      Icon = "lucide:bell",               IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Webhook     = Sections.Notification:Tab({   Title = "Webhook",      Icon = "lucide:webhook",            IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    
    LocalPlayer = Sections.MiscConfig:Tab({     Title = "LocalPlayer",  Icon = "lucide:user",               IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    ESP         = Sections.MiscConfig:Tab({     Title = "ESP",          Icon = "lucide:eye",                IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Misc        = Sections.MiscConfig:Tab({     Title = "Misc",         Icon = "lucide:wrench",             IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
    Config      = Sections.MiscConfig:Tab({     Title = "Configuration",Icon = "lucide:save",               IconColor = Color3.fromHex("#0369a1"), IconShape = "Square", Border = true }),
}


--------------------------------------------------------------------------------
-- TAB: AUTOMATION > FARM
--------------------------------------------------------------------------------
do
    Tabs.Farm:Select()

    local ProgressionSection = Tabs.Farm:Section({ Title = "Progression", TextSize = 18, Opened = true })
    ProgressionSection:Toggle({
        Flag = "toggle_farm_auto_roll",
        Title = "Auto Roll",
        --Desc = "Spaming rolls as fast as possible",
        Value = false,
        Callback = function(v) S.AutoRoll = v end
    })

    ProgressionSection:Toggle({
        Flag = "toggle_farm_auto_rebirth",
        Title = "Auto Rebirth",
        --Desc = "Rebirths when goop requirement is met",
        Value = false,
        Callback = function(v) S.AutoRebirth = v end
    })

    ProgressionSection:Toggle({
        Flag = "toggle_farm_auto_buy_zone",
        Title = "Auto Buy Next Zone",
        --Desc = "Purchases next zone when affordable",
        Value = false,
        Callback = function(v) S.AutoBuyZone = v end
    })

    ProgressionSection:Toggle({
        Flag = "toggle_farm_auto_teleport_zone",
        Title = "Auto Teleport to Best Zone",
        --Desc = "Teleports to highest unlocked zone (respects Max Zone limit)",
        Value = false,
        Callback = function(v) S.AutoTeleportBestZone = v end
    })

    ProgressionSection:Slider({
        Flag = "slider_farm_max_zone",
        Title = "Max Zone",
        Desc = "Max zone to teleport, but still buy next zone",
        Step = 1,
        Value = { Min = 1, Max = 28, Default = 28 },
        Callback = function(v) S.MaxZoneLimit = v end
    })

    local EquipedSection = Tabs.Farm:Section({ Title = "Equipped", TextSize = 18, Opened = true })
    EquipedSection:Dropdown({
        Title = "Equip Mode",
        Flag = "dropdown_farm_auto_equip_mode",
        --Desc = "How to equip mode",
        Values = {"Default", "Best Level", "Best Rarity", "Best Damage", "Best Health"},
        Value = "Default",
        AllowNone = false,
        Callback = function(v) S.EquipMode = v end
    })

    EquipedSection:Toggle({
        Flag = "toggle_farm_auto_equip_best",
        Title = "Auto Equip Best Slime",
        --Desc = "Equips strongest slimes",
        Value = false,
        Callback = function(v) S.AutoEquipBest = v end
    })

    local CollectSection = Tabs.Farm:Section({ Title = "Collect & Claim", TextSize = 18, Opened = true })
    CollectSection:Toggle({
        Flag = "toggle_farm_auto_collect_loot",
        Title = "Auto Collect Loot",
        --Desc = "Collects all loot drops instantly",
        Value = false,
        Callback = function(v) S.AutoCollectLoot = v end
    })

    CollectSection:Toggle({
        Flag = "toggle_farm_auto_claim_index",
        Title = "Auto Claim Index Rewards",
        --Desc = "Claims available index milestone rewards",
        Value = false,
        Callback = function(v) S.AutoClaimIndex = v end
    })

    CollectSection:Toggle({
        Flag = "toggle_farm_auto_claim_offline",
        Title = "Auto Claim Offline Earnings",
        --Desc = "Claims offline earnings on join",
        Value = false,
        Callback = function(v) S.AutoClaimOffline = v end
    })
end

-- Auto Roll
task.spawn(function()
    while true do
        if S.AutoRoll and not S._diceStackBusy then
            netFetch("RollService", "requestRoll")
            SessionRolls = SessionRolls + 1
        end
        task.wait(S.AutoRoll and 0 or 1)
    end
end)

-- Auto Equip Mode (Custom)
task.spawn(function()
    local SlimesModule = safeRequire(ReplicatedStorage.Source.Game.Items.Slimes)
    local InventoryRemote = nil
    pcall(function()
        InventoryRemote = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"].networker._remotes.InventoryService.RemoteFunction
    end)

    -- Slot count calculation (mirrors game's getOwnedSlotCount)
    -- slots upgrade table: {[1]=2, [2]=3, [3]=4, [4]=5, [5]=6, [6]=7, [7]=8}
    -- level 0 = 0 slots (no upgrade), level 1 = 2 slots, ..., level 7 = 8 slots
    -- + gamepass extraEquip (id 1787010888) = +1 slot
    local SLOTS_TABLE = {[1]=2, [2]=3, [3]=4, [4]=5, [5]=6, [6]=7, [7]=8}

    local function getSlotCount()
        local upgrades = getData("upgrades") or {}
        -- Find highest "slots" upgrade level (keys: "slots", "slots2", ..., "slots7")
        local level = 0
        if upgrades["slots"] then level = 1 end
        for k, v in pairs(upgrades) do
            if v and string.sub(k, 1, 5) == "slots" then
                local suffix = string.sub(k, 6)
                local num = tonumber(suffix)
                if num and num > level then level = num end
            end
        end
        local baseSlots = SLOTS_TABLE[level] or 0

        -- Check extraEquip gamepass (id 1787010888)
        local gamepassBonus = 0
        pcall(function()
            local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
            if MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, 1787010888) then
                gamepassBonus = 1
            end
        end)
        -- Also check spoofed gamepass state
        if S.GamepassExtraEquip then gamepassBonus = 1 end

        return math.max(baseSlots + gamepassBonus, 0)
    end

    local function getSlimeDataFromKey(invKey, invVal)
        local slimeId, mutations, level, xp = nil, {}, 1, 0
        if type(invVal) == "table" and invVal.id then
            slimeId = invVal.id
            mutations = invVal.mutations or {}
            level = invVal.level or 1
            xp = invVal.xp or 0
        elseif type(invVal) == "number" or invVal == nil then
            local dashPos = string.find(invKey, "-")
            if dashPos then
                slimeId = string.sub(invKey, dashPos + 1)
                local mutPart = string.sub(invKey, 1, dashPos - 1)
                if mutPart ~= "" then
                    for _, m in ipairs(string.split(mutPart, "_")) do
                        if m ~= "" then mutations[m] = true end
                    end
                end
            end
        end
        if not slimeId then return nil end

        local baseDmg, baseHp, odds = 1, 1, 1
        if SlimesModule and SlimesModule.getSlime then
            local ok, slime = pcall(SlimesModule.getSlime, slimeId)
            if ok and slime then
                baseDmg = slime.damage or 1
                baseHp = slime.health or 1
                odds = slime.odds or 1
            end
        end

        -- Calculate stats with level and mutation bonuses
        local mutBonus = 1
        for k, v in pairs(mutations) do if v == true then mutBonus = mutBonus * 1.5 end end
        local dmg = baseDmg * ((level - 1) * 0.1 + 1) * mutBonus
        local hp = baseHp * ((level - 1) * 0.1 + 1) * mutBonus

        return {
            uniqueId = invKey,
            slimeId = slimeId,
            level = level,
            xp = xp,
            damage = dmg,
            health = hp,
            odds = odds, -- lower odds = rarer
            mutations = mutations
        }
    end

    while true do
        if S.AutoEquipBest and S.EquipMode == "Default" then
            netFetch("InventoryService", "requestEquipBest")
        elseif S.AutoEquipBest and S.EquipMode ~= "Default" then
            pcall(function()
                local inv = getData("inventory") or {}
                local equipped = getData("equipped") or {}
                local maxSlots = getSlotCount()

                if maxSlots <= 0 then return end

                -- Build list of all slimes with stats
                local allSlimes = {}
                for invKey, invVal in pairs(inv) do
                    local data = getSlimeDataFromKey(invKey, invVal)
                    if data then
                        table.insert(allSlimes, data)
                    end
                end

                -- Sort based on equip mode
                if S.EquipMode == "Best Level" then
                    table.sort(allSlimes, function(a, b)
                        if a.level == b.level then return a.damage > b.damage end
                        return a.level > b.level
                    end)
                elseif S.EquipMode == "Best Rarity" then
                    table.sort(allSlimes, function(a, b)
                        if a.odds == b.odds then return a.damage > b.damage end
                        return a.odds < b.odds -- lower odds = rarer
                    end)
                elseif S.EquipMode == "Best Damage" then
                    table.sort(allSlimes, function(a, b) return a.damage > b.damage end)
                elseif S.EquipMode == "Best Health" then
                    table.sort(allSlimes, function(a, b)
                        if a.health == b.health then return a.damage > b.damage end
                        return a.health > b.health
                    end)
                end

                -- Get top N unique IDs to equip
                local toEquip = {}
                local usedIds = {}
                for _, slime in ipairs(allSlimes) do
                    if #toEquip >= maxSlots then break end
                    if not usedIds[slime.uniqueId] then
                        usedIds[slime.uniqueId] = true
                        table.insert(toEquip, slime.uniqueId)
                    end
                end

                -- Check if current equipped matches desired
                local needsChange = false
                local equippedSet = {}
                for _, uid in pairs(equipped) do
                    if uid and uid ~= "" then equippedSet[uid] = true end
                end
                local desiredSet = {}
                for _, uid in ipairs(toEquip) do desiredSet[uid] = true end

                for uid in pairs(desiredSet) do
                    if not equippedSet[uid] then needsChange = true break end
                end
                if not needsChange then
                    for uid in pairs(equippedSet) do
                        if not desiredSet[uid] then needsChange = true break end
                    end
                end

                if needsChange and #toEquip > 0 then
                    -- Fast unequip: fire all unequip requests in parallel (no wait between)
                    local unequipThreads = {}
                    for slot, uid in pairs(equipped) do
                        if uid and uid ~= "" then
                            table.insert(unequipThreads, task.spawn(function()
                                if InventoryRemote then
                                    pcall(function() InventoryRemote:InvokeServer("requestUnequip", slot) end)
                                else
                                    netFetch("InventoryService", "requestUnequip", slot)
                                end
                            end))
                        end
                    end
                    task.wait(0.3) -- Wait for all unequips to process server-side

                    -- Equip desired slimes (sequential - server processes one at a time)
                    for _, uid in ipairs(toEquip) do
                        if InventoryRemote then
                            pcall(function() InventoryRemote:InvokeServer("requestEquip", uid) end)
                        else
                            netFetch("InventoryService", "requestEquip", uid)
                        end
                    end
                end
            end)
        end
        task.wait(S.AutoEquipBest and S.EquipMode ~= "Default" and 5 or 10)
    end
end)

-- Auto Rebirth
task.spawn(function()
    while true do
        if S.AutoRebirth then
            local ok = netFetch("RebirthService", "requestRebirth")
            if ok then SessionRebirths = SessionRebirths + 1 end
        end
        task.wait(S.AutoRebirth and 0.33 or 3)
    end
end)

-- Auto Buy Zone + Teleport
task.spawn(function()
    while true do
        if S.AutoBuyZone then
            netFetch("ZonesService", "requestPurchaseZone")
        end
        
        if S.AutoTeleportBestZone then
            local ownedMax = getData("maxZone") or getData("furthestZone") or 1
            local teleportTarget = math.min(ownedMax, S.MaxZoneLimit)
            local currentZone = getData("zone") or 1
            if currentZone ~= teleportTarget then
                netFetch("ZonesService", "requestTeleportZone", teleportTarget)
            end
        end
        task.wait((S.AutoBuyZone or S.AutoTeleportBestZone) and 0.33 or 3)
    end
end)

-- Auto Collect Loot
task.spawn(function()
    while true do
        if S.AutoCollectLoot then
            pcall(function()
                local lootFolder = Workspace:FindFirstChild("Loot")
                if lootFolder then
                    for _, loot in pairs(lootFolder:GetChildren()) do
                        if loot:GetAttribute("uniqueId") then
                            netFetch("LootService", "requestCollect", loot:GetAttribute("uniqueId"))
                        end
                    end
                end
            end)
        end
        task.wait(S.AutoCollectLoot and 0.1 or 3)
    end
end)

-- Auto Claim Index Rewards
task.spawn(function()
    local IndexRemote = nil
    pcall(function()
        IndexRemote = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"].networker._remotes.IndexService.RemoteFunction
    end)
    local categories = {"basic", "big", "huge", "shiny", "inverted"}
    while true do
        if S.AutoClaimIndex then
            pcall(function()
                for _, category in ipairs(categories) do
                    if IndexRemote then
                        pcall(function() IndexRemote:InvokeServer("requestClaimReward", category) end)
                    else
                        netFetch("IndexService", "requestClaimReward", category)
                    end
                end
            end)
        end
        task.wait(S.AutoClaimIndex and 10 or 30)
    end
end)

-- Auto Claim Offline Earnings
task.spawn(function()
    local OfflineRemote = nil
    pcall(function()
        OfflineRemote = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"].networker._remotes.OfflineEarningsService.RemoteFunction
    end)
    -- Claim once on startup, then periodically
    task.wait(3)
    while true do
        if S.AutoClaimOffline then
            pcall(function()
                if OfflineRemote then
                    OfflineRemote:InvokeServer("requestClaim")
                else
                    netFetch("OfflineEarningsService", "requestClaim")
                end
            end)
        end
        task.wait(S.AutoClaimOffline and 60 or 120)
    end
end)


--------------------------------------------------------------------------------
-- TAB: AUTOMATION > COMBAT
--------------------------------------------------------------------------------
do
    Tabs.Combat:Section({ Title = "Combat Movement", TextSize = 18 })

    Tabs.Combat:Dropdown({
        Title = "Methode",
        Flag = "dropdown_combat_methode",
        Desc = "How to move to enemies",
        Values = {"Teleport", "Tween", "Walk"},
        Value = "Walk",
        AllowNone = false,
        Callback = function(v) S.CombatMethod = v end
    })

    Tabs.Combat:Slider({
        Title = "Tween Distance",
        Flag = "slider_combat_tween_distance",
        Desc = "Height (studs) above enemy",
        Step = 10,
        Value = { Min = 10, Max = 500, Default = 10 },
        Callback = function(v) S.CombatTweenDistance = v end
    })

    Tabs.Combat:Slider({
        Title = "Multiplier Speed",
        Flag = "slider_combat_multiplier_speed",
        Desc = "Walk speed multiplier when moving",
        Step = 1,
        Value = { Min = 1, Max = 5, Default = 1 },
        Callback = function(v) S.CombatSpeed = v end
    })

    Tabs.Combat:Space({ Columns = 0.5 })
    Tabs.Combat:Toggle({
        Title = "Enable",
        Flag = "toggle_combat_enable",
        Value = false,
        Callback = function(v) S.CombatEnabled = v end
    })
end

-- Auto go to Enemy
task.spawn(function()
    local currentTarget = nil
    local tweenObj = nil
    local originalSpeed = nil
    
    while true do
        if S.CombatEnabled then
            pcall(function()
                -- Wait 5 seconds after zone teleport for enemies to spawn
                local lastTP = getgenv().__lastZoneTeleportTime or 0
                if os.time() - lastTP < 5 then return end
                
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                
                -- Save original speed
                if not originalSpeed then originalSpeed = hum.WalkSpeed end
                
                -- Disable fall animation for tween (keep character stable)
                if S.CombatMethod == "Tween" then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hrp.Velocity = Vector3.new(0, 0, 0)
                end
                
                -- Prevent fling: zero velocity on teleport/walk
                if S.CombatMethod == "Teleport" or S.CombatMethod == "Walk" then
                    if hrp.Velocity.Magnitude > 50 then
                        hrp.Velocity = Vector3.new(0, 0, 0)
                        hrp.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
                
                -- If we have a current target, stay near it until it's gone
                if currentTarget and currentTarget.Parent then
                    local targetPos = currentTarget:IsA("Model") and currentTarget:GetPivot().Position or currentTarget.Position
                    if S.CombatMethod == "Tween" then
                        -- Always stay above enemy (no delay, instant follow)
                        local floatPos = targetPos + Vector3.new(0, S.CombatTweenDistance, 0)
                        hrp.CFrame = CFrame.new(floatPos)
                        hrp.Velocity = Vector3.new(0, 0, 0)
                    elseif S.CombatMethod == "Walk" then
                        -- Restore speed when at target
                        hum.WalkSpeed = originalSpeed or 22
                    end
                    return -- Stay at current target until it dies
                end
                
                -- Target is gone, find new one
                currentTarget = nil
                if tweenObj then tweenObj:Cancel() tweenObj = nil end
                
                -- Restore speed after target dies (walk)
                if S.CombatMethod == "Walk" and originalSpeed then
                    hum.WalkSpeed = originalSpeed
                end
                
                local enemy, dist = getClosestEnemy()
                if enemy and dist then
                    currentTarget = enemy
                    local targetPos = enemy:IsA("Model") and enemy:GetPivot().Position or enemy.Position
                    
                    if S.CombatMethod == "Teleport" then
                        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
                        hrp.Velocity = Vector3.new(0, 0, 0)
                        hrp.RotVelocity = Vector3.new(0, 0, 0)
                    elseif S.CombatMethod == "Tween" then
                        -- Instant position above enemy
                        local floatPos = targetPos + Vector3.new(0, S.CombatTweenDistance, 0)
                        hrp.CFrame = CFrame.new(floatPos)
                        hrp.Velocity = Vector3.new(0, 0, 0)
                    elseif S.CombatMethod == "Walk" then
                        -- Apply speed multiplier only while moving to target
                        hum.WalkSpeed = (originalSpeed or 22) * S.CombatSpeed
                        hum:MoveTo(targetPos)
                    end
                end
            end)
        else
            -- Restore state when disabled
            if originalSpeed then
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.WalkSpeed = originalSpeed
                            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                        end
                    end
                end)
                originalSpeed = nil
            end
            currentTarget = nil
            if tweenObj then tweenObj:Cancel() tweenObj = nil end
        end
        task.wait(S.CombatEnabled and 0.05 or 1) -- Very fast loop for tween smoothness
    end
end)

-- Helpers for combat delay
task.spawn(function()
    if DataClient then
        pcall(function()
            DataClient:getChangedSignal("zone"):Connect(function()
                getgenv().__lastZoneTeleportTime = os.time()
            end)
        end)
    end
end)

--------------------------------------------------------------------------------
-- TAB: AUTOMATION > UPGRADE
--------------------------------------------------------------------------------
do
    Tabs.Upgrade:Section({ Title = "Auto Upgrade Skills", TextSize = 18 })

    Tabs.Upgrade:Dropdown({
        Title = "Upgrade Priority",
        Flag = "dropdown_upgrade_priority",
        Desc = "Select which upgrades to buy first (multi-select)",
        Values = UPGRADE_KEYS,
        Value = {},
        Multi = true,
        AllowNone = true,
        Callback = function(v) S.UpgradePriority = v end
    })

    Tabs.Upgrade:Toggle({
        Title = "Start Upgrading",
        Flag = "toggle_upgrade_enable",
        Value = false,
        Callback = function(v) S.UpgradeEnabled = v end
    })

    Tabs.Upgrade:Space({ Columns = 0.25 })
    Tabs.Upgrade:Section({ Title = "Status", TextSize = 15 })
    local UpgradeStatusParagraph = Tabs.Upgrade:Paragraph({
        Title = "Status: Idle",
        Desc = "Loading..."
    })

    -- Live update upgrade status
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not S.UpgradeEnabled then
                    UpgradeStatusParagraph:SetTitle("Status: Idle")
                    UpgradeStatusParagraph:SetDesc("Waiting for enabling...")
                    return
                end
                local upgrades = getData("upgrades") or {}
                local priority = S.UpgradePriority
                if #priority == 0 then priority = UPGRADE_KEYS end

                local lines = {}
                table.insert(lines, "Priority:")
                for i, key in ipairs(priority) do
                    if i > 8 then break end -- Show max 8
                    local owned = upgrades[key] and "Owned" or "Not owned"
                    -- Get current level
                    local level = 0
                    local keyLen = string.len(key)
                    for k, v in pairs(upgrades) do
                        if v and string.sub(k, 1, keyLen) == key then
                            local suffix = string.sub(k, keyLen + 1)
                            local num = tonumber(suffix)
                            if num and num > level then level = num end
                            if k == key then level = math.max(level, 1) end
                        end
                    end
                    local displayName = key:sub(1,1):upper() .. key:sub(2)
                    table.insert(lines, i .. ". " .. displayName .. " Lv." .. tostring(level))
                end
                UpgradeStatusParagraph:SetTitle("Status: Running")
                UpgradeStatusParagraph:SetDesc(table.concat(lines, "\n"))
            end)
        end
    end)
end

-- Auto Upgrade Skills
task.spawn(function()
    local UpgradeRemote = nil
    pcall(function()
        UpgradeRemote = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"].networker._remotes.UpgradeService.RemoteFunction
    end)

    local function tryUnlock(upgradeKey)
        if UpgradeRemote then
            local ok, result = pcall(function()
                return UpgradeRemote:InvokeServer("requestUnlock", upgradeKey)
            end)
            return ok and result
        else
            return netFetch("UpgradeService", "requestUnlock", upgradeKey)
        end
    end

    local function getNextUpgradeKey(baseKey)
        local upgrades = getData("upgrades") or {}
        -- Find current level
        local currentLevel = 0
        if upgrades[baseKey] then currentLevel = 1 end
        local keyLen = string.len(baseKey)
        for k, v in pairs(upgrades) do
            if v and string.sub(k, 1, keyLen) == baseKey then
                local suffix = string.sub(k, keyLen + 1)
                local num = tonumber(suffix)
                if num and num > currentLevel then
                    currentLevel = num
                end
            end
        end
        -- Next level key
        local nextLevel = currentLevel + 1
        if nextLevel == 1 then
            return baseKey
        else
            return baseKey .. tostring(nextLevel)
        end
    end

    while true do
        if S.UpgradeEnabled then
            local priority = S.UpgradePriority
            if #priority == 0 then priority = UPGRADE_KEYS end
            for _, baseKey in ipairs(priority) do
                if not S.UpgradeEnabled then break end
                local nextKey = getNextUpgradeKey(baseKey)
                tryUnlock(nextKey)
                task.wait(5) -- 5 second delay between each upgrade attempt
            end
        end
        task.wait(S.UpgradeEnabled and 3 or 5)
    end
end)


--------------------------------------------------------------------------------
-- TAB: AUTOMATION > CRAFT
--------------------------------------------------------------------------------
do
    Tabs.Craft:Section({ Title = "Auto Crafting Slime", TextSize = 18 })

    Tabs.Craft:Dropdown({
        Title = "Select Recipe",
        Flag = "dropdown_craft_recipe",
        Values = RECIPES,
        Value = "crafty",
        AllowNone = false,
        Callback = function(v) S.CraftRecipe = v end
    })

    Tabs.Craft:Slider({
        Title = "Craft Amount",
        Flag = "slider_craft_amount",
        Desc = "0 = Unlimited",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = 0 },
        Callback = function(v) S.CraftAmount = v end
    })

    Tabs.Craft:Space({ Columns = 0.5 })
    Tabs.Craft:Dropdown({
        Title = "Mutation Selection",
        Flag = "dropdown_craft_mutation",
        Desc = "Stop when these mutations are obtained (Base = no mutation)",
        Values = MUTATIONS,
        Value = MUTATIONS,
        Multi = true,
        AllowNone = true,
        Callback = function(v) S.CraftMutationFilter = v end
    })

    Tabs.Craft:Toggle({
        Title = "Stop on Mutations",
        Flag = "toggle_craft_stop_mutation",
        --Desc = "Stops crafting when selected mutation is rolled",
        Value = false,
        Callback = function(v) S.CraftStopOnMutation = v end
    })

    Tabs.Craft:Toggle({
        Title = "Start Crafting",
        Flag = "toggle_craft_start",
        Value = false,
        Callback = function(v)
            S.CraftEnabled = v
            if v then
                S.CraftCount = 0
                S.CraftObtainedMutations = {}

                -- Pre-check inventory for already obtained mutations of this recipe
                pcall(function()
                    local recipeId = S.CraftRecipe
                    local inv = getData("inventory") or {}
                    -- Inventory key format:
                    -- Base:     "-geode"
                    -- Big:      "big_-geode"
                    -- Shiny:    "shiny_-geode"
                    -- Big+Shiny: "big_shiny_-geode"
                    for invKey, invVal in pairs(inv) do
                        local dashPos = string.find(invKey, "-")
                        if dashPos then
                            local slimeId = string.sub(invKey, dashPos + 1)
                            if slimeId == recipeId then
                                local mutPart = string.sub(invKey, 1, dashPos - 1)
                                if mutPart == "" then
                                    -- Base (no mutation)
                                    S.CraftObtainedMutations["Base"] = true
                                else
                                    -- Parse mutations from prefix: "big_shiny_" -> {big, shiny}
                                    for _, m in ipairs(string.split(mutPart, "_")) do
                                        if m ~= "" then
                                            S.CraftObtainedMutations[m] = true
                                        end
                                    end
                                end
                            end
                        end
                        -- Also check leveled slimes (table value)
                        if type(invVal) == "table" and invVal.id == recipeId then
                            local muts = invVal.mutations
                            if muts then
                                local hasMut = false
                                for k, val in pairs(muts) do
                                    if val == true then
                                        S.CraftObtainedMutations[k] = true
                                        hasMut = true
                                    end
                                end
                                if not hasMut then
                                    S.CraftObtainedMutations["Base"] = true
                                end
                            else
                                S.CraftObtainedMutations["Base"] = true
                            end
                        end
                    end
                end)
            end
        end
    })

    Tabs.Craft:Space({ Columns = 0.25 })
    Tabs.Craft:Section({ Title = "Status", TextSize = 15 })
    local CraftStatusParagraph = Tabs.Craft:Paragraph({
        Title = "Status: Idle",
        Desc = "Waiting for enabling..."
    })

    -- Hardcoded recipe ingredients for display
    local CRAFT_RECIPE_INPUTS = {
        crafty          = {"lucky", "rocky", "mushy"},
        thorn           = {"orbit", "icy", "stump"},
        geode           = {"ninja", "guest", "aegis"},
        slimeSlimeSlime = {"slimeSlime", "slimeSlime", "slimeSlime"},
        puffy           = {"unicorn", "flour", "derpy"},
        astro           = {"ufo", "blackhole", "bomber"},
        sunny           = {"pumpkin", "ouchy", "ember"},
        melly           = {"monke", "waxie", "germy"},
    }

    -- Helper: count how many of a slime ID exist in inventory
    local function countSlimeInInventory(inv, slimeId)
        local total = 0
        for invKey, invVal in pairs(inv) do
            if type(invVal) == "number" and invVal > 0 then
                local dashPos = string.find(invKey, "-")
                if dashPos then
                    local sid = string.sub(invKey, dashPos + 1)
                    if sid == slimeId then total = total + invVal end
                end
            elseif type(invVal) == "table" and invVal.id == slimeId then
                total = total + 1
            end
        end
        return total
    end

    -- Live status update
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                if not S.CraftEnabled then
                    CraftStatusParagraph:SetTitle("Status: Idle")
                    CraftStatusParagraph:SetDesc("Waiting for enabling...")
                    return
                end

                local inv = getData("inventory") or {}
                local recipeId = S.CraftRecipe
                local lines = {}

                -- Recipe name
                local recipeName = recipeId:sub(1,1):upper() .. recipeId:sub(2)
                table.insert(lines, "Recipe: " .. recipeName)

                -- Ingredients with counts
                local requiredIds = CRAFT_RECIPE_INPUTS[recipeId]
                if requiredIds then
                    local ingredientParts = {}
                    local hasEnough = true
                    -- Deduplicate ingredients (e.g. slimeSlimeSlime needs 3x slimeSlime)
                    local idCounts = {}
                    local idOrder = {}
                    for _, id in ipairs(requiredIds) do
                        if not idCounts[id] then
                            idCounts[id] = 0
                            table.insert(idOrder, id)
                        end
                        idCounts[id] = idCounts[id] + 1
                    end
                    for _, id in ipairs(idOrder) do
                        local owned = countSlimeInInventory(inv, id)
                        local needed = idCounts[id]
                        local displayName = id:sub(1,1):upper() .. id:sub(2)
                        if needed > 1 then
                            table.insert(ingredientParts, displayName .. ": x" .. tostring(owned) .. " (need " .. tostring(needed) .. ")")
                        else
                            table.insert(ingredientParts, displayName .. ": x" .. tostring(owned))
                        end
                        if owned < needed then hasEnough = false end
                    end
                    table.insert(lines, "Ingredients: " .. table.concat(ingredientParts, " | "))

                    if not hasEnough then
                        table.insert(lines, "!! Not enough ingredients !!")
                    end
                end

                -- Amount
                if S.CraftAmount > 0 then
                    table.insert(lines, "Amount: " .. tostring(S.CraftCount) .. "/" .. tostring(S.CraftAmount))
                else
                    table.insert(lines, "Amount: " .. tostring(S.CraftCount))
                end

                -- Mutation tracking
                if S.CraftStopOnMutation and #S.CraftMutationFilter > 0 then
                    table.insert(lines, "")
                    table.insert(lines, "Mutation:")
                    for _, mut in ipairs(S.CraftMutationFilter) do
                        local obtained = S.CraftObtainedMutations[mut] == true
                        local displayName = mut == "Base" and "None" or (mut:sub(1,1):upper() .. mut:sub(2))
                        local status = obtained and "Obtained" or "Not Obtained"
                        table.insert(lines, "- " .. displayName .. ": " .. status)
                    end
                end

                CraftStatusParagraph:SetTitle("Status: Running")
                CraftStatusParagraph:SetDesc(table.concat(lines, "\n"))
            end)
        end
    end)
end

-- Auto Craft Slime from Recipes
task.spawn(function()
    -- Use Networker client (proper way to call remotes)
    local CraftNet = nil
    pcall(function()
        local Networker = require(ReplicatedStorage.Packages.Networker)
        CraftNet = Networker.client.new("CraftingService", {})
    end)
    
    -- Actual recipe ingredients (extracted from runtime)
    local RECIPE_INPUTS = {
        crafty          = {"lucky", "rocky", "mushy"},
        thorn           = {"orbit", "icy", "stump"},
        geode           = {"ninja", "guest", "aegis"},
        slimeSlimeSlime = {"slimeSlime", "slimeSlime", "slimeSlime"},
        puffy           = {"unicorn", "flour", "derpy"},
        astro           = {"ufo", "blackhole", "bomber"},
        sunny           = {"pumpkin", "ouchy", "ember"},
        melly           = {"monke", "waxie", "germy"},
    }
    
    -- Find inventory key for a given slime ID
    local function findIngredientKeys(inv, requiredIds)
        local result = {}
        local usedKeys = {} -- track used keys to avoid double-using same stack
        
        for _, reqId in ipairs(requiredIds) do
            local foundKey = nil
            
            -- First pass: find stackable (base, no mutation) slimes - cheapest to sacrifice
            for invKey, invVal in pairs(inv) do
                if type(invVal) == "number" and invVal > 0 then
                    local dashPos = string.find(invKey, "-")
                    if dashPos then
                        local slimeId = string.sub(invKey, dashPos + 1)
                        local mutPart = string.sub(invKey, 1, dashPos - 1)
                        if slimeId == reqId and mutPart == "" then
                            -- Check if we haven't used all copies
                            local usedCount = usedKeys[invKey] or 0
                            if usedCount < invVal then
                                foundKey = invKey
                                usedKeys[invKey] = usedCount + 1
                                break
                            end
                        end
                    end
                end
            end
            
            -- Second pass: find stackable with mutations
            if not foundKey then
                for invKey, invVal in pairs(inv) do
                    if type(invVal) == "number" and invVal > 0 then
                        local dashPos = string.find(invKey, "-")
                        if dashPos then
                            local slimeId = string.sub(invKey, dashPos + 1)
                            if slimeId == reqId then
                                local usedCount = usedKeys[invKey] or 0
                                if usedCount < invVal then
                                    foundKey = invKey
                                    usedKeys[invKey] = usedCount + 1
                                    break
                                end
                            end
                        end
                    end
                end
            end
            
            -- Third pass: find leveled slimes (table value with .id)
            if not foundKey then
                for invKey, invVal in pairs(inv) do
                    if type(invVal) == "table" and invVal.id == reqId then
                        if not usedKeys[invKey] then
                            foundKey = invKey
                            usedKeys[invKey] = 1
                            break
                        end
                    end
                end
            end
            
            if not foundKey then
                return nil -- Missing ingredient
            end
            table.insert(result, foundKey)
        end
        
        return result
    end

    while true do
        if S.CraftEnabled then
            pcall(function()
                local inv = getData("inventory") or {}
                local recipeId = S.CraftRecipe
                
                -- Look up required slime IDs for this recipe
                local requiredIds = RECIPE_INPUTS[recipeId]
                if not requiredIds then
                    notify("Craft", "Unknown recipe: " .. recipeId, "x", 3)
                    S.CraftEnabled = false
                    return
                end
                
                -- Find matching inventory keys for each required ingredient
                local ingredients = findIngredientKeys(inv, requiredIds)
                if not ingredients then
                    -- Not enough ingredients - stop crafting
                    S.CraftEnabled = false
                    notify("Craft", "Not enough ingredients for " .. recipeId .. "! Stopping.", "x", 5)
                    return
                end
                
                -- Get machine ID from workspace (find closest crafting machine)
                local machineId = nil
                pcall(function()
                    local gpFolder = getGameplayFolder()
                    if gpFolder then
                        local machines = gpFolder:FindFirstChild("CraftingMachines")
                        if machines then
                            local first = machines:GetChildren()[1]
                            if first then machineId = tostring(first:GetAttribute("id") or first.Name) end
                        end
                    end
                end)
                
                -- Craft via Networker fetch
                local success, errorMsg, craftData
                if CraftNet then
                    success, errorMsg, craftData = CraftNet:fetch("requestCraftRecipe", recipeId, ingredients, machineId)
                else
                    success, errorMsg, craftData = netFetch("CraftingService", "requestCraftRecipe", recipeId, ingredients, machineId)
                end
                
                if success then
                    S.CraftCount = S.CraftCount + 1
                    
                    -- Track and check mutations
                    if S.CraftStopOnMutation and #S.CraftMutationFilter > 0 then
                        local resultMuts = nil
                        if craftData and type(craftData) == "table" then
                            resultMuts = craftData.mutations
                        end
                        
                        -- Determine what mutation this craft result has
                        local hasMutation = false
                        if resultMuts then
                            for k, v in pairs(resultMuts) do
                                if v == true then hasMutation = true break end
                            end
                        end
                        
                        -- Mark obtained mutations
                        for _, targetMut in ipairs(S.CraftMutationFilter) do
                            if targetMut == "Base" and not hasMutation then
                                if not S.CraftObtainedMutations["Base"] then
                                    S.CraftObtainedMutations["Base"] = true
                                    notify("Craft", "Got Base (no mutation) " .. recipeId .. "!", "sparkles", 5)
                                end
                            elseif targetMut ~= "Base" and resultMuts and resultMuts[targetMut] == true then
                                if not S.CraftObtainedMutations[targetMut] then
                                    S.CraftObtainedMutations[targetMut] = true
                                    notify("Craft", "Got " .. targetMut .. " " .. recipeId .. "!", "sparkles", 5)
                                end
                            end
                        end
                        
                        -- Check if ALL selected mutations have been obtained
                        local allObtained = true
                        for _, targetMut in ipairs(S.CraftMutationFilter) do
                            if not S.CraftObtainedMutations[targetMut] then
                                allObtained = false
                                break
                            end
                        end
                        if allObtained then
                            S.CraftEnabled = false
                            notify("Craft", "All selected mutations obtained for " .. recipeId .. "! Stopping.", "check", 5)
                        end
                    end
                    
                    -- Check amount limit
                    if S.CraftAmount > 0 and S.CraftCount >= S.CraftAmount then
                        S.CraftEnabled = false
                        notify("Craft", "Completed " .. S.CraftCount .. " crafts!", "check")
                    end
                end
            end)
        end
        task.wait(S.CraftEnabled and 0.1 or 5)
    end
end)


--------------------------------------------------------------------------------
-- TAB: AUTOMATION > FEED
--------------------------------------------------------------------------------
do
    Tabs.Feed:Section({ Title = "Auto Feed Slime", TextSize = 18 })

    Tabs.Feed:Dropdown({
        Title = "Select Food",
        Flag = "dropdown_feed_food",
        Desc = "Which foods to use (smallest XP used first)",
        Values = FOODS,
        Value = FOODS,
        Multi = true,
        AllowNone = true,
        Callback = function(v) S.FeedFood = v end
    })

    Tabs.Feed:Slider({
        Flag = "slider_feed_target_level",
        Title = "Target Level",
        Desc = "0 = Unlimited (feed until no food left)",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = 0 },
        Callback = function(v) S.FeedTargetLevel = v end
    })

    -- Build equipped slime list for target dropdown
    local feedEquippedList = {}
    local feedEquippedMap = {} -- display -> uniqueId
    
    local function refreshFeedTargetList()
        feedEquippedList = {}
        feedEquippedMap = {}
        pcall(function()
            local equipped = getData("equipped") or {}
            local inv = getData("inventory") or {}
            local SlimesModule = safeRequire(ReplicatedStorage.Source.Game.Items.Slimes)
            for slot, uniqueId in pairs(equipped) do
                if uniqueId and uniqueId ~= "" then
                    local slimeId, mutations, level = nil, {}, 1
                    local invVal = inv[uniqueId]
                    if type(invVal) == "table" and invVal.id then
                        slimeId = invVal.id
                        mutations = invVal.mutations or {}
                        level = invVal.level or 1
                    elseif type(invVal) == "number" or invVal == nil then
                        local dashPos = string.find(uniqueId, "-")
                        if dashPos then
                            slimeId = string.sub(uniqueId, dashPos + 1)
                            local mutPart = string.sub(uniqueId, 1, dashPos - 1)
                            if mutPart ~= "" then
                                for _, m in ipairs(string.split(mutPart, "_")) do
                                    if m ~= "" then mutations[m] = true end
                                end
                            end
                        end
                    end
                    if slimeId then
                        local mutNames = {}
                        for k, v in pairs(mutations) do
                            if v == true then table.insert(mutNames, k:sub(1,1):upper() .. k:sub(2)) end
                        end
                        local displayName = ""
                        if #mutNames > 0 then displayName = table.concat(mutNames, " ") .. " " end
                        displayName = displayName .. slimeId:sub(1,1):upper() .. slimeId:sub(2)
                        displayName = displayName .. " [Lv." .. tostring(level) .. "]"
                        displayName = displayName .. " (Slot " .. tostring(slot) .. ")"
                        table.insert(feedEquippedList, displayName)
                        feedEquippedMap[displayName] = uniqueId
                    end
                end
            end
        end)
        return feedEquippedList
    end
    
    -- Initial load
    refreshFeedTargetList()

    local FeedTargetDropdown = Tabs.Feed:Dropdown({
        Title = "Target Slime",
        Flag = "dropdown_feed_target_slime",
        Desc = "Select from currently equipped slimes",
        Values = feedEquippedList,
        Value = nil,
        AllowNone = true,
        Callback = function(v)
            S.FeedTargetSlime = v and feedEquippedMap[v] or nil
        end
    })

    Tabs.Feed:Button({
        Title = "Refresh Target List",
        Desc = "Update equipped slimes list",
        Callback = function()
            local newList = refreshFeedTargetList()
            FeedTargetDropdown:SetValues(newList)
            notify("Feed", "Target list refreshed (" .. tostring(#newList) .. " slimes)", "refresh-cw", 2)
        end
    })

    Tabs.Feed:Toggle({
        Title = "Start Feeding",
        Flag = "toggle_feed_start",
        Value = false,
        Callback = function(v) S.FeedEnabled = v end
    })

    Tabs.Feed:Space({ Columns = 0.25 })
    Tabs.Feed:Section({ Title = "Status", TextSize = 15 })
    local FeedStatusParagraph = Tabs.Feed:Paragraph({
        Title = "Status: Idle",
        Desc = "Select a slime and enable to start feeding."
    })

    -- Live status update
    task.spawn(function()
        local FOOD_XP = {apple=75, carrot=100, cherries=125, grapes=150, banana=175, watermelon=200, pizza=225, chicken=250, drumstick=275}
        while task.wait(2) do
            pcall(function()
                if not S.FeedEnabled then
                    FeedStatusParagraph:SetTitle("Status: Idle")
                    FeedStatusParagraph:SetDesc("Select a slime and enable to start feeding.")
                    return
                end
                if not S.FeedTargetSlime then
                    FeedStatusParagraph:SetTitle("Status: No target")
                    FeedStatusParagraph:SetDesc("Select a target slime from dropdown.")
                    return
                end

                local inv = getData("inventory") or {}
                local items = getData("items") or {}
                local targetData = inv[S.FeedTargetSlime]

                -- Get slime level/xp info
                local level, xp = 1, 0
                if type(targetData) == "table" then
                    level = targetData.level or 1
                    xp = targetData.xp or 0
                end
                local xpReq = level * 100

                -- Show available food
                local lines = {}
                table.insert(lines, "Target Level: " .. (S.FeedTargetLevel == 0 and "Unlimited" or tostring(S.FeedTargetLevel)))

                -- Target slime display
                local targetDisplay = "Unknown"
                for display, uid in pairs(feedEquippedMap) do
                    if uid == S.FeedTargetSlime then targetDisplay = display break end
                end
                table.insert(lines, "Slime: " .. targetDisplay)
                table.insert(lines, "Level: " .. tostring(level) .. " | XP: " .. tostring(xp) .. "/" .. tostring(xpReq))

                -- Food inventory
                local foodLines = {}
                for _, food in ipairs(FOODS) do
                    local amount = items[food] or 0
                    if amount > 0 then
                        local selected = false
                        for _, sel in ipairs(S.FeedFood) do
                            if sel == food then selected = true break end
                        end
                        if selected then
                            table.insert(foodLines, food:sub(1,1):upper()..food:sub(2) .. ": " .. tostring(amount) .. "x (" .. tostring(FOOD_XP[food]) .. " XP)")
                        end
                    end
                end
                if #foodLines > 0 then
                    table.insert(lines, "Food: " .. table.concat(foodLines, ", "))
                else
                    table.insert(lines, "Food: None available")
                end

                -- XP needed for target
                if S.FeedTargetLevel > 0 and level < S.FeedTargetLevel then
                    -- Calculate total XP needed: sum of (lvl * 100) for each level from current to target
                    local totalXpNeeded = 0
                    for lv = level, S.FeedTargetLevel - 1 do
                        totalXpNeeded = totalXpNeeded + (lv * 100)
                    end
                    totalXpNeeded = totalXpNeeded - xp
                    table.insert(lines, "XP Needed: " .. formatNumber(math.max(totalXpNeeded, 0)))
                end

                FeedStatusParagraph:SetTitle("Status: Running")
                FeedStatusParagraph:SetDesc(table.concat(lines, "\n"))
            end)
        end
    end)
end

-- Auto Feed Slime with Food
task.spawn(function()
    local FeedRemote = nil
    pcall(function()
        FeedRemote = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"].networker._remotes.InventoryService.RemoteFunction
    end)
    
    local FOOD_XP = {apple=75, carrot=100, cherries=125, grapes=150, banana=175, watermelon=200, pizza=225, chicken=250, drumstick=275}
    local FOOD_EFFICIENT_ORDER = {"apple", "carrot", "cherries", "grapes", "banana", "watermelon", "pizza", "chicken", "drumstick"}
    
    while true do
        if S.FeedEnabled and S.FeedTargetSlime then
            pcall(function()
                local items = getData("items") or {}
                local inv = getData("inventory") or {}
                local targetData = inv[S.FeedTargetSlime]
                
                -- Get current level/xp
                local level, xp = 1, 0
                if type(targetData) == "table" then
                    level = targetData.level or 1
                    xp = targetData.xp or 0
                end
                
                -- Check if target level reached
                if S.FeedTargetLevel > 0 and level >= S.FeedTargetLevel then
                    S.FeedEnabled = false
                    notify("Feed", "Target level " .. S.FeedTargetLevel .. " reached!", "check", 5)
                    return
                end
                
                -- Calculate XP needed for target level
                local xpNeeded = math.huge
                if S.FeedTargetLevel > 0 then
                    -- Total XP needed from current state to target level
                    local totalNeeded = 0
                    for lv = level, S.FeedTargetLevel - 1 do
                        totalNeeded = totalNeeded + (lv * 100)
                    end
                    xpNeeded = totalNeeded - xp
                    if xpNeeded <= 0 then
                        S.FeedEnabled = false
                        notify("Feed", "Target level " .. S.FeedTargetLevel .. " reached!", "check", 5)
                        return
                    end
                end
                
                -- Build allowed food list (filtered by user selection, sorted smallest XP first)
                local allowedFoods = {}
                for _, food in ipairs(FOOD_EFFICIENT_ORDER) do
                    local isSelected = false
                    for _, sel in ipairs(S.FeedFood) do
                        if sel == food then isSelected = true break end
                    end
                    if isSelected then
                        local amount = items[food] or 0
                        if amount > 0 then
                            table.insert(allowedFoods, {name = food, xp = FOOD_XP[food], amount = amount})
                        end
                    end
                end
                
                if #allowedFoods == 0 then return end -- No food available
                
                -- Pick food: use smallest XP food first to avoid waste
                local foodToUse = nil
                local feedAmount = 1
                
                if xpNeeded < math.huge then
                    -- Smart selection: find the best food that doesn't overshoot too much
                    for _, foodInfo in ipairs(allowedFoods) do
                        local maxCanUse = math.min(foodInfo.amount, 99)
                        local neededCount = math.ceil(xpNeeded / foodInfo.xp)
                        feedAmount = math.min(maxCanUse, math.max(neededCount, 1))
                        foodToUse = foodInfo.name
                        break -- Use smallest available food
                    end
                else
                    -- Unlimited: use smallest food first (use all)
                    foodToUse = allowedFoods[1].name
                    feedAmount = math.min(allowedFoods[1].amount, 99)
                end
                
                if not foodToUse then return end
                
                -- Feed
                if FeedRemote then
                    pcall(function()
                        FeedRemote:InvokeServer("requestUseFood", foodToUse, S.FeedTargetSlime, feedAmount)
                    end)
                else
                    netFetch("InventoryService", "requestUseFood", foodToUse, S.FeedTargetSlime, feedAmount)
                end
            end)
        end
        task.wait(S.FeedEnabled and 1 or 3)
    end
end)


--------------------------------------------------------------------------------
-- TAB: AUTOMATION > POTION
--------------------------------------------------------------------------------
do
    Tabs.Potion:Section({ Title = "Auto Using Potion", TextSize = 18 })

    Tabs.Potion:Dropdown({
        Title = "Select Potion",
        Flag = "dropdown_potion_selection",
        Desc = "Choose boost potions to use",
        Values = BOOST_KINDS,
        Value = {},
        Multi = true,
        AllowNone = true,
        Callback = function(v) S.PotionSelection = v end
    })

    Tabs.Potion:Slider({
        Title = "Potion Amount",
        Flag = "slider_potion_amount",
        Desc = "0 = Unlimited (use all)",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = 0 },
        Callback = function(v) S.PotionAmount = v end
    })

    Tabs.Potion:Space({ Columns = 0.5 })
    Tabs.Potion:Dropdown({
        Title = "Usage Method",
        Flag = "dropdown_potion_method",
        Values = {"Bulk Use", "Using after Expired"},
        Value = "Bulk Use",
        AllowNone = false,
        Callback = function(v) S.PotionMethod = v end
    })

    Tabs.Potion:Toggle({
        Title = "Start Using",
        Flag = "toggle_potion_start",
        Value = false,
        Callback = function(v) S.PotionEnabled = v end
    })

    Tabs.Potion:Space({ Columns = 0.25 })
    Tabs.Potion:Section({ Title = "Status", TextSize = 15 })
    Tabs.Potion:Paragraph({
        Title = "Status: Idle",
        Desc = "Loading..."
    })
end

-- Auto using Potion
task.spawn(function()
    while true do
        if S.PotionEnabled and #S.PotionSelection > 0 then
            for _, kind in ipairs(S.PotionSelection) do
                netFetch("BoostService", "requestUseBoost", kind)
            end
        end
        task.wait(S.PotionMethod == "Using after Expired" and 180 or 0.1)
    end
end)


--------------------------------------------------------------------------------
-- TAB: AUTOMATION > DICE
--------------------------------------------------------------------------------
do
    Tabs.Dice:Section({ Title = "Stack Special Roll", TextSize = 18 })

    Tabs.Dice:Dropdown({
        Title = "Special Roll Collection",
        Flag = "dropdown_dice_save_rolls",
        Desc = "Select which special rolls to stack",
        Values = SPECIAL_ROLLS,
        Value = {"void", "diamond", "golden"},
        Multi = true,
        AllowNone = true,
        Callback = function(v) S.DiceSaveRolls = v end
    })

    Tabs.Dice:Toggle({
        Title = "Stack Special Rolls",
        Flag = "toggle_dice_stacker",
        --Desc = "Pauses selected rolls at 0, then unpauses all together",
        Value = false,
        Callback = function(v) S.DiceEnabled = v end
    })

    Tabs.Dice:Space({ Columns = 0.5 })
    Tabs.Dice:Dropdown({
        Title = "Dice Item Priority",
        Flag = "dropdown_dice_selection",
        Desc = "Priority: first is used first until depleted, then next",
        Values = DICE_TYPES,
        Value = {},
        Multi = true,
        AllowNone = true,
        Callback = function(v) S.DiceSelection = v end
    })

    Tabs.Dice:Toggle({
        Title = "Use Dice on Unpause",
        Flag = "toggle_dice_use_on_unpause",
        --Desc = "Arms dice item before unpausing (uses priority order)",
        Value = false,
        Callback = function(v) S.DiceUseOnUnpause = v end
    })

    Tabs.Dice:Space({ Columns = 0.25 })
    Tabs.Dice:Section({ Title = "Status", TextSize = 15 })
    local DiceStatusParagraph = Tabs.Dice:Paragraph({
        Title = "Status: Idle",
        Desc = "Enable to start stacking special rolls."
    })

    -- Live status update
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not S.DiceEnabled then
                    DiceStatusParagraph:SetTitle("Status: Idle")
                    DiceStatusParagraph:SetDesc("Enable 'Stack Special Rolls' to start.")
                    return
                end
                
                -- Use realtime cache if available, fallback to getData
                local progression = getgenv().__specialRollProgressionCache or getData("specialRollProgression") or {}
                local items = getData("items") or {}
                local armed = getData("armedSpecialDice") or {}
                local lines = {}
                
                -- Priority order for display
                local PRIORITY_DISPLAY = {"void", "diamond", "golden"}
                
                -- Show selected special rolls info (in priority order)
                local selectedSet = {}
                for _, v in ipairs(S.DiceSaveRolls) do selectedSet[v] = true end
                
                if #S.DiceSaveRolls > 0 then
                    table.insert(lines, "Special Roll:")
                    for _, kind in ipairs(PRIORITY_DISPLAY) do
                        if selectedSet[kind] then
                            local prog = progression[kind]
                            local rollsLeft = prog and prog.rollsUntilNext or "?"
                            local paused = prog and prog.paused
                            local checkmark = (paused and (rollsLeft == 0 or rollsLeft == "?")) and " done" or ""
                            local status
                            if S._diceStackBusy and paused then
                                status = "Ready"
                            elseif paused and rollsLeft == 0 then
                                status = "Paused"
                            elseif paused then
                                status = tostring(rollsLeft) .. " left | Paused"
                            else
                                status = tostring(rollsLeft) .. " left | Running"
                            end
                            table.insert(lines, "- " .. kind:sub(1,1):upper()..kind:sub(2) .. ": " .. status .. checkmark)
                        end
                    end
                end
                
                -- Show selected dice items info
                if S.DiceUseOnUnpause and #S.DiceSelection > 0 then
                    table.insert(lines, "")
                    table.insert(lines, "Dice Item (priority):")
                    for _, dice in ipairs(S.DiceSelection) do
                        local owned = items[dice] or 0
                        local armedCount = 0
                        for _, a in ipairs(armed) do
                            if a == dice then armedCount = armedCount + 1 end
                        end
                        local displayName = dice:sub(1,1):upper() .. dice:sub(2)
                        table.insert(lines, "- " .. displayName .. ": " .. tostring(owned) .. " owned | " .. tostring(armedCount) .. " armed")
                    end
                end
                
                -- Determine overall status with phase info
                local totalSelected = #S.DiceSaveRolls
                local phase = S._diceStackPhase or 0
                
                if S._diceStackBusy then
                    DiceStatusParagraph:SetTitle("Status: Unpausing all + arming dice...")
                elseif #S.DiceSaveRolls == 0 then
                    DiceStatusParagraph:SetTitle("Status: No special rolls selected")
                elseif phase >= totalSelected then
                    DiceStatusParagraph:SetTitle("Status: All stacked! Preparing unpause...")
                else
                    DiceStatusParagraph:SetTitle("Status: Stacking (Phase " .. tostring(phase) .. "/" .. tostring(totalSelected) .. ")")
                end
                
                DiceStatusParagraph:SetDesc(table.concat(lines, "\n"))
            end)
        end
    end)
end

-- Dice Stacker - Realtime Listener for specialRollProgression
task.spawn(function()
    local DataServiceEvent = nil
    pcall(function()
        -- Try both networker versions
        local path1 = ReplicatedStorage.Packages._Index:FindFirstChild("leifstout_networker@0.3.1")
        local path2 = ReplicatedStorage.Packages._Index:FindFirstChild("leifstout_networker@0.2.1")
        
        if path1 and path1:FindFirstChild("networker") then
            DataServiceEvent = path1.networker._remotes.DataService.RemoteEvent
        elseif path2 and path2:FindFirstChild("networker") then
            DataServiceEvent = path2.networker._remotes.DataService.RemoteEvent
        end
    end)
    
    if DataServiceEvent then
        -- Cache untuk specialRollProgression realtime
        getgenv().__specialRollProgressionCache = {}
        
        -- Listen untuk update dari server
        DataServiceEvent.OnClientEvent:Connect(function(updateType, key, value)
            pcall(function()
                -- Update type 1 = data update
                if updateType == 1 and key == "specialRollProgression" and type(value) == "table" then
                    getgenv().__specialRollProgressionCache = value
                    
                    -- Debug log (optional, bisa dihapus nanti)
                    if S.DiceEnabled then
                        local lines = {}
                        for rollType, data in pairs(value) do
                            table.insert(lines, rollType .. ": " .. tostring(data.rollsUntilNext) .. " left | " .. (data.paused and "Paused" or "Running"))
                        end
                        -- print("[Dice Listener] " .. table.concat(lines, " | "))
                    end
                end
            end)
        end)
        
        print("[.petrixhub] Dice Stacker: Realtime listener active")
    else
        warn("[.petrixhub] Dice Stacker: Could not find DataService RemoteEvent")
    end
end)

-- Dice Stacker - Task 1: Auto Pause Special Rolls at 0
task.spawn(function()
    local RemoteFunction = nil
    pcall(function()
        RemoteFunction = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"].networker._remotes.RollService.RemoteFunction
    end)
    
    local function pauseRoll(kind, paused)
        if RemoteFunction then
            pcall(function()
                RemoteFunction:InvokeServer("requestSetSpecialRollPaused", kind, paused)
            end)
        else
            netFetch("RollService", "requestSetSpecialRollPaused", kind, paused)
        end
    end
    
    -- Priority order (highest first)
    local PRIORITY = {"void", "diamond", "golden"}
    
    local function getSelectedByPriority()
        local result = {}
        for _, kind in ipairs(PRIORITY) do
            for _, selected in ipairs(S.DiceSaveRolls) do
                if kind == selected then
                    table.insert(result, kind)
                    break
                end
            end
        end
        return result
    end
    
    while task.wait(0.5) do
        if S.DiceEnabled and #S.DiceSaveRolls > 0 and not S._diceStackBusy then
            pcall(function()
                -- Use realtime cache if available, fallback to getData
                local progression = getgenv().__specialRollProgressionCache or getData("specialRollProgression") or {}
                local ordered = getSelectedByPriority()
                
                -- Priority-based pause: pause at 0, but only if higher priority already paused
                local currentPhase = 0
                
                for i, kind in ipairs(ordered) do
                    local prog = progression[kind]
                    local rollsLeft = prog and prog.rollsUntilNext or 999
                    local isPaused = prog and prog.paused or false
                    
                    -- Check if all higher priority rolls are paused at 0
                    local canPause = true
                    for j = 1, i - 1 do
                        local higherKind = ordered[j]
                        local higherProg = progression[higherKind]
                        local higherPaused = higherProg and higherProg.paused or false
                        local higherRolls = higherProg and higherProg.rollsUntilNext or 999
                        
                        -- Higher priority must be paused at 0 before we can pause this one
                        if not (higherPaused and higherRolls == 0) then
                            canPause = false
                            break
                        end
                    end
                    
                    if rollsLeft == 0 and not isPaused and canPause then
                        -- This roll is at 0, pause it now
                        pauseRoll(kind, true)
                        task.wait(0.2) -- Small delay to let pause register
                    end
                    
                    if isPaused and rollsLeft == 0 then
                        currentPhase = i
                    end
                end
                
                S._diceStackPhase = currentPhase
            end)
        else
            S._diceStackPhase = 0
        end
    end
end)

-- Dice Stacker - Task 2: Unpause + Arm Dice when All Ready
task.spawn(function()
    local RemoteFunction = nil
    pcall(function()
        RemoteFunction = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"].networker._remotes.RollService.RemoteFunction
    end)
    
    local function pauseRoll(kind, paused)
        if RemoteFunction then
            pcall(function()
                RemoteFunction:InvokeServer("requestSetSpecialRollPaused", kind, paused)
            end)
        else
            netFetch("RollService", "requestSetSpecialRollPaused", kind, paused)
        end
    end
    
    -- Priority order (highest first)
    local PRIORITY = {"void", "diamond", "golden"}
    
    local function getSelectedByPriority()
        local result = {}
        for _, kind in ipairs(PRIORITY) do
            for _, selected in ipairs(S.DiceSaveRolls) do
                if kind == selected then
                    table.insert(result, kind)
                    break
                end
            end
        end
        return result
    end
    
    while task.wait(1) do
        if S.DiceEnabled and #S.DiceSaveRolls > 0 and not S._diceStackBusy then
            pcall(function()
                -- Use realtime cache if available, fallback to getData
                local progression = getgenv().__specialRollProgressionCache or getData("specialRollProgression") or {}
                local items = getData("items") or {}
                local ordered = getSelectedByPriority()
                
                -- Check if ALL selected rolls are paused at 0
                local allAtZero = true
                for _, kind in ipairs(ordered) do
                    local prog = progression[kind]
                    local rollsLeft = prog and prog.rollsUntilNext or 999
                    local isPaused = prog and prog.paused or false
                    
                    if rollsLeft ~= 0 or not isPaused then
                        allAtZero = false
                        break
                    end
                end
                
                -- ALL at 0 and paused → synchronized unpause sequence
                if allAtZero then
                    -- Cooldown check: prevent immediate re-trigger after unpause
                    local timeSinceLastUnpause = os.time() - (S._diceLastUnpauseTime or 0)
                    if timeSinceLastUnpause < 5 then
                        -- Too soon after last unpause, skip this cycle
                        return
                    end
                    
                    -- STEP 1: Pause auto-roll (block any new rolls)
                    S._diceStackBusy = true
                    task.wait(0.3) -- Let any in-flight roll finish
                    
                    -- STEP 2: Arm dice item (if enabled, priority order)
                    if S.DiceUseOnUnpause and #S.DiceSelection > 0 then
                        local armed = getData("armedSpecialDice") or {}
                        local alreadyArmed = false
                        
                        -- Check if any priority dice is already armed
                        for _, dice in ipairs(S.DiceSelection) do
                            for _, armedItem in ipairs(armed) do
                                if armedItem == dice then
                                    alreadyArmed = true
                                    break
                                end
                            end
                            if alreadyArmed then break end
                        end
                        
                        -- Only arm if nothing is armed yet
                        if not alreadyArmed then
                            for _, dice in ipairs(S.DiceSelection) do
                                local owned = items[dice] or 0
                                if owned > 0 then
                                    netFetch("InventoryService", "requestUseItem", dice)
                                    task.wait(0.5) -- Wait for arm to register
                                    break -- Priority: only use first available
                                end
                            end
                        end
                    end
                    
                    -- STEP 3: Unpause void, diamond, golden (rapid fire, no delay)
                    for _, kind in ipairs(ordered) do
                        pauseRoll(kind, false)
                    end
                    
                    -- Mark unpause time
                    S._diceLastUnpauseTime = os.time()
                    
                    -- Small delay for server to process all unpauses
                    task.wait(0.5)
                    
                    -- STEP 4: Resume auto-roll (next roll will trigger all specials + dice)
                    S._diceStackBusy = false
                    
                    -- Wait for the roll to happen and cycle to restart
                    task.wait(5)
                end
            end)
        else
            S._diceStackBusy = false
        end
    end
end)


--------------------------------------------------------------------------------
-- TAB: BYPASS > TUTORIAL SKIP
--------------------------------------------------------------------------------
do
    Tabs.Tutorial:Section({ Title = "Tutorial Skip", TextSize = 18 })

    Tabs.Tutorial:Button({
        Title = "Skip / Bypass Tutorial",
        Desc = "Attempts to bypass all tutorial locks on actions",
        Callback = function()
            -- Try to complete tutorial steps
            local net = getNet("TutorialService")
            if net then
                pcall(net.fetch, net, "requestCompleteTutorial")
                pcall(net.fetch, net, "requestSkipTutorial")
            end
            notify("Tutorial", "Bypass attempted - try actions now", "skip-forward")
        end
    })
end


--------------------------------------------------------------------------------
-- TAB: BYPASS > GAMEPASS SPOOF
--------------------------------------------------------------------------------
do
    Tabs.Gamepass:Section({ Title = "Gamepass Spoof [Client-Side]", TextSize = 18 })

    Tabs.Gamepass:Toggle({
        Title = "Double Roll",
        Flag = "toggle_gamepass_double_roll",
        --Desc = "Spoofs doubleRoll ownership (2 columns per roll)",
        Value = false,
        Callback = function(v) S.GamepassDoubleRoll = v end
    })

    Tabs.Gamepass:Toggle({
        Title = "Fast Roll",
        Flag = "toggle_gamepass_fast_roll",
        --Desc = "Spoofs fastRoll speed boost",
        Value = false,
        Callback = function(v) S.GamepassFastRoll = v end
    })

    Tabs.Gamepass:Toggle({
        Title = "Lucky Rolls",
        Flag = "toggle_gamepass_lucky_rolls",
        --Desc = "Spoofs luckyRolls luck multiplier",
        Value = false,
        Callback = function(v) S.GamepassLuckyRolls = v end
    })

    Tabs.Gamepass:Toggle({
        Title = "VIP!",
        Flag = "toggle_gamepass_vip",
        --Desc = "Spoofs VIP (1.1x coins + luck bonus)",
        Value = false,
        Callback = function(v) S.GamepassVIP = v end
    })

    Tabs.Gamepass:Toggle({
        Title = "Auto Collect",
        Flag = "toggle_gamepass_auto_collect",
        --Desc = "Spoofs autoCollect gamepass",
        Value = false,
        Callback = function(v) S.GamepassAutoCollect = v end
    })

    Tabs.Gamepass:Toggle({
        Title = "+1 Equip",
        Flag = "toggle_gamepass_extra_equip",
        --Desc = "Spoofs extraEquip slot",
        Value = false,
        Callback = function(v) S.GamepassExtraEquip = v end
    })

    Tabs.Gamepass:Toggle({
        Title = "More Loot",
        Flag = "toggle_gamepass_more_loot",
        --Desc = "Spoofs moreDrops (1.33x loot chance)",
        Value = false,
        Callback = function(v) S.GamepassMoreLoot = v end
    })
end


--------------------------------------------------------------------------------
-- TAB: BYPASS > MANIPULATION
--------------------------------------------------------------------------------
do
    Tabs.Manipulation:Section({ Title = "RNG System", TextSize = 18 })

    Tabs.Manipulation:Toggle({
        Title = "Force Rare on Roll",
        Flag = "toggle_manip_force_rare",
        --Desc = "Hooks math.random to bias rare outcomes",
        Value = false,
        Callback = function(v)
            S.ForceRare = v
            if v then
                if not getgenv().__origRandom then getgenv().__origRandom = math.random end
                math.random = function(a, b)
                    if a and b then return a end
                    if a then return 1 end
                    return 0.0001
                end
            else
                if getgenv().__origRandom then math.random = getgenv().__origRandom end
            end
        end
    })

    Tabs.Manipulation:Toggle({
        Title = "Force Mutation Target on Roll",
        Flag = "toggle_manip_force_mutation",
        --Desc = "Biases mutation rolls towards rare mutations",
        Value = false,
        Callback = function(v) S.ForceMutation = v end
    })

    Tabs.Manipulation:Toggle({
        Title = "Force Special Roll to 1",
        Flag = "toggle_manip_force_special",
        --Desc = "Continuously forces all special roll progression to 1 roll remaining",
        Value = false,
        Callback = function(v)
            S.ForceSpecialRoll = v
            if v then
                notify("Special Roll", "Forcing all overdrives to 1/1...", "dice-5")
            end
        end
    })

    Tabs.Manipulation:Section({ Title = "Data Override", TextSize = 18 })

    Tabs.Manipulation:Toggle({
        Title = "Fake Luck (Override to Max)",
        Flag = "toggle_manip_fake_luck",
        Desc = "Continuously overrides luck display to maximum (loops every tick)",
        Value = false,
        Callback = function(v)
            S.FakeLuck = v
            if v then
                notify("Fake Luck", "Luck override loop started!", "clover")
            end
        end
    })

    Tabs.Manipulation:Section({ Title = "Game Bypass", TextSize = 18 })

    Tabs.Manipulation:Toggle({
        Title = "Disable Rejoin",
        Flag = "toggle_manip_disable_rejoin",
        Desc = "Disables game's built-in auto-rejoin (14 min idle timer)",
        Value = true,
        Callback = function(v)
            S.DisableRejoin = v
            pcall(function()
                local AutoRejoinService = safeRequire(ReplicatedStorage.Source.Features.AutoRejoin.AutoRejoinServiceClient)
                if AutoRejoinService then
                    if v then
                        AutoRejoinService:disable()
                    else
                        AutoRejoinService:enable()
                    end
                end
            end)
        end
    })
end

-- Force Special Roll
task.spawn(function()
    while true do
        if S.ForceSpecialRoll then
            pcall(function()
                -- Unpause all special rolls
                for _, kind in ipairs(SPECIAL_ROLLS) do
                    netFetch("RollService", "requestSetSpecialRollPaused", kind, false)
                end
                -- Override client-side progression data
                if DataClient then
                    local prog = DataClient:get("specialRollProgression")
                    if prog then
                        for _, kind in ipairs(SPECIAL_ROLLS) do
                            if prog[kind] then
                                prog[kind].rollsUntilNext = 1
                                prog[kind].paused = false
                            else
                                prog[kind] = { rollsUntilNext = 1, paused = false }
                            end
                        end
                    end
                end
            end)
        end
        task.wait(S.ForceSpecialRoll and 1 or 3)
    end
end)

-- Fake Luck
task.spawn(function()
    while true do
        if S.FakeLuck then
            pcall(function()
                local RollSlice = safeRequire(ReplicatedStorage.Source.Features.Roll.RollSlice)
                if RollSlice and RollSlice.actions and RollSlice.actions.setResolvedRollStats then
                    local maxLuck = 100 * 1000 * 1000 * 1000 * 1000
                    RollSlice.actions.setResolvedRollStats({
                        luck = maxLuck,
                        maxLuck = maxLuck,
                        luckOverridden = true,
                        rollTime = 0.01
                    })
                end
            end)
        end
        task.wait(0.01)
    end
end)

-- Disable Rejoin from Game
task.spawn(function()
    if S.DisableRejoin then
        pcall(function()
            local AutoRejoinService = safeRequire(ReplicatedStorage.Source.Features.AutoRejoin.AutoRejoinServiceClient)
            if AutoRejoinService then
                AutoRejoinService:disable()
            end
        end)
    end
end)


--------------------------------------------------------------------------------
-- TAB: BYPASS > ENEMIES
--------------------------------------------------------------------------------
do
    Tabs.Enemy:Section({ Title = "Enemies", TextSize = 18 })

    Tabs.Enemy:Toggle({
        Title = "Bring Enemy",
        Flag = "toggle_enemy_bring",
        Desc = "Brings all enemies to your position for faster targeting",
        Value = false,
        Callback = function(v) S.BringEnemy = v end
    })

    Tabs.Enemy:Toggle({
        Title = "1-Hit Kill",
        Flag = "toggle_enemy_one_hit",
        Desc = "Stacks slimes on enemies to maximize attack rate",
        Value = false,
        Callback = function(v) S.OneHitKill = v end
    })
end

-- Bring Enemy
task.spawn(function()
    while true do
        if S.BringEnemy then
            pcall(function()
                local enemies = getEnemiesFolder()
                if not enemies then return end
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local playerPos = hrp.Position
                local lookDir = hrp.CFrame.LookVector
                local bringCenter = playerPos + lookDir * S.BringDistance
                
                local enemyList = enemies:GetChildren()
                for i, enemy in pairs(enemyList) do
                    if enemy:IsA("Model") then
                    
                    -- Spread enemies in a small circle to avoid overlap
                    local angle = (i / math.max(#enemyList, 1)) * math.pi * 2
                    local spread = Vector3.new(math.cos(angle) * 2, 0, math.sin(angle) * 2)
                    local targetPos = bringCenter + spread
                    
                    -- Move the entire model via PivotTo
                    pcall(function()
                        enemy:PivotTo(CFrame.new(targetPos))
                    end)
                    
                    -- Also move RootPart directly (in case PivotTo doesn't work)
                    pcall(function()
                        local rootPart = enemy:FindFirstChild("RootPart")
                        if rootPart and rootPart:IsA("BasePart") then
                            rootPart.CFrame = CFrame.new(targetPos)
                            rootPart.Velocity = Vector3.zero
                            rootPart.AssemblyLinearVelocity = Vector3.zero
                        end
                    end)
                    end -- close if enemy:IsA("Model")
                end -- close for loop
            end)
        end
        
        if S.OneHitKill then
            pcall(function()
                local gpFolder = getGameplayFolder()
                if not gpFolder then return end
                local slimeFolder = gpFolder:FindFirstChild("Slimes")
                local enemiesFolder = gpFolder:FindFirstChild("Enemies")
                if not slimeFolder or not enemiesFolder then return end
                
                local enemies = enemiesFolder:GetChildren()
                if #enemies == 0 then return end
                
                local targetEnemy = enemies[1]
                if not targetEnemy:IsA("Model") then return end
                
                local enemyPos = nil
                pcall(function()
                    enemyPos = targetEnemy:GetPivot().Position
                end)
                if not enemyPos then
                    local rp = targetEnemy:FindFirstChild("RootPart")
                    if rp then enemyPos = rp.Position end
                end
                if not enemyPos then return end
                
                for _, slime in pairs(slimeFolder:GetChildren()) do
                    if slime:IsA("Model") then
                        pcall(function()
                            -- Move slime right next to enemy (within attack range)
                            local offset = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
                            slime:PivotTo(CFrame.new(enemyPos + offset))
                        end)
                        pcall(function()
                            local slimeRoot = slime:FindFirstChild("RootPart")
                            if slimeRoot then
                                slimeRoot.CFrame = CFrame.new(enemyPos + Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)))
                                slimeRoot.Velocity = Vector3.zero
                            end
                        end)
                    end
                end
            end)
        end
        task.wait((S.BringEnemy or S.OneHitKill) and 0.1 or 1)
    end
end)


--------------------------------------------------------------------------------
-- TAB: NOTIFICATION > OBTAINS
--------------------------------------------------------------------------------
do
    Tabs.Obtains:Section({ Title = "Notification Mutation", TextSize = 18 })

    Tabs.Obtains:Dropdown({
        Title = "Mutation Filter",
        Flag = "dropdown_obtains_mutation_filter",
        Desc = "Only notify for these mutations",
        Values = {"Any", "big", "huge", "shiny", "inverted"},
        Value = "Any",
        AllowNone = false,
        Callback = function(v) S.NotifyMutationFilter = v end
    })

    Tabs.Obtains:Toggle({
        Title = "Enable Notification",
        Flag = "toggle_obtains_mutation",
        Desc = "Alerts: Slime Name (1/odds) | Rarity | Mutation types",
        Value = true,
        Callback = function(v) S.NotifyMutation = v end
    })

    Tabs.Obtains:Section({ Title = "Notification Rarity", TextSize = 18 })

    Tabs.Obtains:Dropdown({
        Title = "Minimum Rarity",
        Flag = "dropdown_obtains_min_rarity",
        Desc = "Only notify for this rarity tier or above",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Celestial", "Exotic", "Divine"},
        Value = "Rare",
        AllowNone = false,
        Callback = function(v) S.NotifyMinRarity = v end
    })

    Tabs.Obtains:Toggle({
        Title = "Enable Notification",
        Flag = "toggle_obtains_rarity",
        Desc = "Alerts: Slime Name (1/odds) | Rarity tier | Mutations if any",
        Value = true,
        Callback = function(v) S.NotifyRarity = v end
    })

    Tabs.Obtains:Section({ Title = "Notification Looting", TextSize = 18 })

    Tabs.Obtains:Toggle({
        Title = "Enable Notification",
        Flag = "toggle_obtains_looting",
        Desc = "Alerts on loot pickup: Food/Potion name",
        Value = true,
        Callback = function(v) S.NotifyLoot = v end
    })
end

-- Notifier - Mutation & Rarity
task.spawn(function()
    local lastMutNotif = ""
    local lastRarityNotif = ""
    
    -- Try to get slime odds data from game module
    local SlimesModule = safeRequire(ReplicatedStorage.Source.Game.Items.Slimes)
    local function getSlimeOdds(slimeId)
        if SlimesModule and SlimesModule.getSlime then
            local ok, slime = pcall(SlimesModule.getSlime, slimeId)
            if ok and slime then
                return slime.odds or slime.rarity or nil
            end
        end
        return nil
    end
    
    local function getRarityFromOdds(odds)
        if not odds or type(odds) ~= "number" or odds <= 0 then return "Common", 1 end
        local denom = 1 / odds -- e.g. odds=0.001 -> denom=1000
        if denom >= 10000000000 then return "Divine", 10
        elseif denom >= 1000000000 then return "Exotic", 9
        elseif denom >= 100000000 then return "Celestial", 8
        elseif denom >= 10000000 then return "Secret", 7
        elseif denom >= 1000000 then return "Mythic", 6
        elseif denom >= 100000 then return "Legendary", 5
        elseif denom >= 10000 then return "Epic", 4
        elseif denom >= 1000 then return "Rare", 3
        elseif denom >= 100 then return "Uncommon", 2
        else return "Common", 1 end
    end
    
    local RARITY_ORDER = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Secret=7, Celestial=8, Exotic=9, Divine=10}
    
    -- Monitor daily rarest roll which changes more frequently
    local lastDailyRoll = nil
    
    while true do
        pcall(function()
            local stats = getData("stats")
            if not stats then return end
            
            -- Use dailyRarestRoll as it updates per session, or rarestRoll
            local sd = nil
            local dailyData = stats.dailyRarestRoll
            local rarestData = stats.rarestRoll and stats.rarestRoll.slimeData
            
            -- Detect new roll by checking if dailyRarestRoll changed
            if dailyData and dailyData.slimeData then
                local newKey = tostring(dailyData.slimeData.id) .. tostring(dailyData.timestamp or "")
                if newKey ~= lastDailyRoll then
                    lastDailyRoll = newKey
                    sd = dailyData.slimeData
                end
            elseif rarestData then
                sd = rarestData
            end
            
            if not sd then
                -- Fallback: use rarestRoll but only notify once
                if rarestData and rarestData.id then
                    sd = rarestData
                else
                    return
                end
            end
            
            local slimeId = sd.id
            if not slimeId then return end
            
            -- Get odds for this slime
            local odds = getSlimeOdds(slimeId)
            local rarityName, rarityLevel = getRarityFromOdds(odds)
            local oddsStr = odds and ("1/" .. formatNumber(math.floor(1/odds))) or "?"
            
            -- Mutation notification (full info)
            if S.NotifyMutation and sd.mutations then
                local muts = {}
                for k, v in pairs(sd.mutations) do
                    if v == true then table.insert(muts, k) end
                end
                local key = slimeId .. table.concat(muts) .. tostring(odds)
                if key ~= lastMutNotif and #muts > 0 then
                    local shouldNotify = (S.NotifyMutationFilter == "Any")
                    if not shouldNotify then
                        for _, m in ipairs(muts) do
                            if m == S.NotifyMutationFilter then shouldNotify = true end
                        end
                    end
                    if shouldNotify then
                        lastMutNotif = key
                        local slimeName = slimeId:sub(1,1):upper() .. slimeId:sub(2)
                        local mutStr = table.concat(muts, ", ")
                        local msg = slimeName .. " (" .. oddsStr .. ")\nRarity: " .. rarityName .. "\nMutation: " .. mutStr
                        notify("MUTATION!", msg, "sparkles", 6)
                    end
                end
            end
            
            -- Rarity notification (only triggers on actual new data)
            if S.NotifyRarity and slimeId then
                local mutHash = ""
                if sd.mutations then
                    for k, v in pairs(sd.mutations) do
                        if v == true then mutHash = mutHash .. k end
                    end
                end
                local key = slimeId .. mutHash .. tostring(odds)
                if key ~= lastRarityNotif then
                    local minLevel = RARITY_ORDER[S.NotifyMinRarity] or 3
                    if rarityLevel >= minLevel then
                        lastRarityNotif = key
                        local slimeName = slimeId:sub(1,1):upper() .. slimeId:sub(2)
                        local msg = slimeName .. " (" .. oddsStr .. ")\nRarity: " .. rarityName
                        if sd.mutations then
                            local muts = {}
                            for k, v in pairs(sd.mutations) do
                                if v == true then table.insert(muts, k) end
                            end
                            if #muts > 0 then
                                msg = msg .. "\nMutation: " .. table.concat(muts, ", ")
                            end
                        end
                        notify("RARE SLIME!", msg, "gem", 6)
                    end
                end
            end
        end)
        task.wait(2)
    end
end)

-- Notifier - Loot
task.spawn(function()
    local knownLoot = {}
    
    -- Food/Potion name lookup
    local LOOT_NAMES = {
        apple = "Apple", carrot = "Carrot", cherries = "Cherries", grapes = "Grapes",
        banana = "Banana", watermelon = "Watermelon", pizza = "Pizza", chicken = "Chicken", drumstick = "Drumstick",
        luckPotion = "Luck Potion", ultraLuckPotion = "Ultra Luck Potion",
        coinPotion = "Coin Potion", rollSpeedPotion = "Roll Speed Potion"
    }
    
    while true do
        if S.NotifyLoot then
            pcall(function()
                local lootFolder = Workspace:FindFirstChild("Loot")
                if lootFolder then
                    for _, loot in pairs(lootFolder:GetChildren()) do
                        local id = tostring(loot) .. tostring(loot:GetDebugId())
                        if not knownLoot[id] then
                            knownLoot[id] = true
                            local lootName = nil
                            
                            -- Method 1: Find the actual model child (food/potion model)
                            if loot:IsA("Model") then
                                for _, child in pairs(loot:GetChildren()) do
                                    if child:IsA("Model") or child:IsA("MeshPart") or child:IsA("Part") then
                                        if not child:IsA("Highlight") and child.Name ~= "LootBillboard" then
                                            local mapped = LOOT_NAMES[child.Name]
                                            if mapped then
                                                lootName = mapped
                                                break
                                            elseif not string.match(child.Name, "^%x%x%x%x%x%x%x%x") then
                                                -- Not a UUID pattern
                                                lootName = child.Name:sub(1,1):upper() .. child.Name:sub(2)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- Method 2: BillboardGui text (may load later)
                            if not lootName then
                                task.delay(0.5, function()
                                    local bb = loot:FindFirstChild("LootBillboard") or loot:FindFirstChildWhichIsA("BillboardGui")
                                    if bb then
                                        local tl = bb:FindFirstChild("TextLabel")
                                        if tl and tl.Text ~= "" then
                                            notify("Loot!", tl.Text, "package", 3)
                                        end
                                    end
                                end)
                            end
                            
                            -- Method 3: Lookup from LOOT_NAMES by model name
                            if not lootName then
                                lootName = LOOT_NAMES[loot.Name] or nil
                            end
                            
                            if lootName then
                                notify("Loot!", lootName, "package", 3)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)


--------------------------------------------------------------------------------
-- TAB: NOTIFICATION > WEBHOOK
--------------------------------------------------------------------------------
do
    Tabs.Webhook:Section({ Title = "Config", TextSize = 18 })

    Tabs.Webhook:Input({
        Title = "Webhook URL",
        Flag = "input_webhook_url",
        Placeholder = "Discord webhook URL",
        Callback = function(v) S.WebhookURL = v end
    })

    Tabs.Webhook:Toggle({
        Title = "Enable Webhook",
        Flag = "toggle_webhook_enable",
        Value = false,
        Callback = function(v) S.WebhookEnabled = v end
    })

    Tabs.Webhook:Slider({
        Title = "Interval (seconds)",
        Flag = "slider_webhook_interval",
        Desc = "Summary send interval",
        Step = 30,
        Value = { Min = 60, Max = 1800, Default = 300 },
        Callback = function(v) S.WebhookInterval = v end
    })

    Tabs.Webhook:Toggle({
        Title = "Ping @everyone",
        Flag = "toggle_webhook_ping",
        Value = false,
        Callback = function(v) S.WebhookPingEveryone = v end
    })

    local WebhookGroup = Tabs.Webhook:Group({})

    WebhookGroup:Button({
        Title = "Send Summary Now",
        Callback = function()
            if S.WebhookURL == "" then notify("Webhook", "Set URL first!", "x") return end
            local payload = HttpService:JSONEncode({
                content = S.WebhookPingEveryone and "@everyone" or nil,
                embeds = {{
                    title = "Slime RNG - Summary",
                    color = 0xFF69B4,
                    fields = {
                        {name = "Player", value = LocalPlayer.Name, inline = true},
                        {name = "Session", value = tostring(os.time() - SessionStart) .. "s", inline = true},
                        {name = "Rolls", value = tostring(SessionRolls), inline = true},
                        {name = "Rebirths", value = tostring(SessionRebirths), inline = true},
                        {name = "Zone", value = tostring(getData("furthestZone") or 1), inline = true},
                    },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
            sendWebhook(S.WebhookURL, payload)
            notify("Webhook", "Summary sent!", "check")
        end
    })

    WebhookGroup:Button({
        Title = "Send Inventory Now",
        Callback = function()
            if S.WebhookURL == "" then notify("Webhook", "Set URL first!", "x") return end
            local inv = getData("inventory") or {}
            local count = 0
            for _ in pairs(inv) do count = count + 1 end
            local payload = HttpService:JSONEncode({
                embeds = {{
                    title = "Slime RNG - Inventory",
                    description = "Total unique slimes: " .. tostring(count),
                    color = 0x87CEEB,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
            sendWebhook(S.WebhookURL, payload)
            notify("Webhook", "Inventory sent!", "check")
        end
    })

    WebhookGroup:Button({
        Title = "Send Equipped Now",
        Callback = function()
            if S.WebhookURL == "" then notify("Webhook", "Set URL first!", "x") return end
            local equipped = getData("equipped") or {}
            local lines = {}
            for slot, data in pairs(equipped) do
                if data and data.id then
                    table.insert(lines, slot .. ": " .. data.id)
                end
            end
            local payload = HttpService:JSONEncode({
                embeds = {{
                    title = "Slime RNG - Equipped",
                    description = #lines > 0 and table.concat(lines, "\n") or "None equipped",
                    color = 0x98FB98,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
            sendWebhook(S.WebhookURL, payload)
            notify("Webhook", "Equipped sent!", "check")
        end
    })

    WebhookGroup:Button({
        Title = "Send Test",
        Callback = function()
            if S.WebhookURL == "" then notify("Webhook", "Set URL first!", "x") return end
            sendWebhook(S.WebhookURL, HttpService:JSONEncode({content = ".petrixhub Slime RNG - Webhook Test"}))
            notify("Webhook", "Test sent!", "check")
        end
    })

    Tabs.Webhook:Section({ Title = "Customize - Obtained", TextSize = 18 })

    Tabs.Webhook:Toggle({
        Title = "Send on Obtained Slime",
        Flag = "toggle_webhook_send_obtained",
        Value = false,
        Callback = function(v) S.WebhookSendOnObtained = v end
    })

    Tabs.Webhook:Input({
        Title = "Minimum Odds",
        Flag = "input_webhook_min_odds",
        Desc = "Only send if rarity >= this (0 = any)",
        Placeholder = "0",
        Callback = function(v) S.WebhookMinOdds = tonumber(v) or 0 end
    })

    Tabs.Webhook:Dropdown({
        Title = "Mutation Filter",
        Flag = "dropdown_webhook_mutation_filter",
        Values = {"Any", "big", "huge", "shiny", "inverted", "None"},
        Value = "Any",
        AllowNone = false,
        Callback = function(v) S.WebhookMutationFilter = v end
    })

    Tabs.Webhook:Input({
        Title = "Must Have Slimes",
        Flag = "input_webhook_must_have",
        Desc = "Only send for specific slime IDs (comma separated)",
        Placeholder = "---",
        Callback = function(v) S.WebhookMustHaveSlime = v end
    })

    Tabs.Webhook:Section({ Title = "Fields - Obtained", TextSize = 16 })
    Tabs.Webhook:Toggle({ Title = "Odds", Flag = "toggle_webhook_field_odds", Value = true, Callback = function(v) S.WebhookFieldOdds = v end })
    Tabs.Webhook:Toggle({ Title = "Stats", Flag = "toggle_webhook_field_stats", Value = true, Callback = function(v) S.WebhookFieldStats = v end })
    Tabs.Webhook:Toggle({ Title = "Mutations", Flag = "toggle_webhook_field_mutations", Value = true, Callback = function(v) S.WebhookFieldMutations = v end })
    Tabs.Webhook:Toggle({ Title = "Level", Flag = "toggle_webhook_field_level", Value = true, Callback = function(v) S.WebhookFieldLevel = v end })

    Tabs.Webhook:Section({ Title = "Customize - Summary", TextSize = 18 })

    Tabs.Webhook:Toggle({
        Title = "Send Summary on Interval",
        Flag = "toggle_webhook_summary",
        Value = false,
        Callback = function(v) S.WebhookSummaryEnabled = v end
    })

    Tabs.Webhook:Section({ Title = "Fields - Summary", TextSize = 16 })
    Tabs.Webhook:Toggle({ Title = "Player", Flag = "toggle_webhook_field_player", Value = true, Callback = function(v) S.WebhookFieldPlayer = v end })
    Tabs.Webhook:Toggle({ Title = "Session", Flag = "toggle_webhook_field_session", Value = true, Callback = function(v) S.WebhookFieldSession = v end })
    Tabs.Webhook:Toggle({ Title = "Currency", Flag = "toggle_webhook_field_currency", Value = true, Callback = function(v) S.WebhookFieldCurrency = v end })
    Tabs.Webhook:Toggle({ Title = "Zones", Flag = "toggle_webhook_field_zones", Value = true, Callback = function(v) S.WebhookFieldZones = v end })
    Tabs.Webhook:Toggle({ Title = "Attributes", Flag = "toggle_webhook_field_attributes", Value = true, Callback = function(v) S.WebhookFieldAttributes = v end })
    Tabs.Webhook:Toggle({ Title = "Equipped Slimes", Flag = "toggle_webhook_field_equipped", Value = true, Callback = function(v) S.WebhookFieldEquipped = v end })
    Tabs.Webhook:Toggle({ Title = "Inventory Slimes", Flag = "toggle_webhook_field_inventory", Value = true, Callback = function(v) S.WebhookFieldInventory = v end })
    Tabs.Webhook:Toggle({ Title = "Top Owned Slimes", Flag = "toggle_webhook_field_top_owned", Value = false, Callback = function(v) S.WebhookFieldTopOwned = v end })
    Tabs.Webhook:Toggle({ Title = "Items", Flag = "toggle_webhook_field_items", Value = true, Callback = function(v) S.WebhookFieldItems = v end })
    Tabs.Webhook:Toggle({ Title = "Boosts", Flag = "toggle_webhook_field_boosts", Value = true, Callback = function(v) S.WebhookFieldBoosts = v end })
    Tabs.Webhook:Toggle({ Title = "Upgrades", Flag = "toggle_webhook_field_upgrades", Value = true, Callback = function(v) S.WebhookFieldUpgrades = v end })
    Tabs.Webhook:Toggle({ Title = "Index", Flag = "toggle_webhook_field_index", Value = true, Callback = function(v) S.WebhookFieldIndex = v end })
    Tabs.Webhook:Toggle({ Title = "Recent Obtained", Flag = "toggle_webhook_field_recent", Value = true, Callback = function(v) S.WebhookFieldRecent = v end })
end

-- Notifier - Webhook
task.spawn(function()
    while true do
        task.wait(S.WebhookInterval)
        if S.WebhookEnabled and S.WebhookSummaryEnabled and S.WebhookURL ~= "" then
            local fields = {}
            if S.WebhookFieldPlayer then table.insert(fields, {name="Player", value=LocalPlayer.Name, inline=true}) end
            if S.WebhookFieldSession then table.insert(fields, {name="Session", value=tostring(os.time()-SessionStart).."s", inline=true}) end
            if S.WebhookFieldCurrency then
                local coins = getData("coins") or 0
                table.insert(fields, {name="Coins", value=formatNumber(coins), inline=true})
            end
            if S.WebhookFieldZones then table.insert(fields, {name="Zone", value=tostring(getData("furthestZone") or 1), inline=true}) end
            local payload = HttpService:JSONEncode({
                content = S.WebhookPingEveryone and "@everyone" or nil,
                embeds = {{title=".petrixhub Summary", color=0xFF69B4, fields=fields, timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}
            })
            sendWebhook(S.WebhookURL, payload)
        end
    end
end)


--------------------------------------------------------------------------------
-- TAB: MISC & CONFIG > LOCALPLAYER
--------------------------------------------------------------------------------
do
    Tabs.LocalPlayer:Section({ Title = "Protection", TextSize = 18 })
    local antiAFKConnection = nil
    local networkPaused = nil

    Tabs.LocalPlayer:Toggle({
        Title = "Anti AFK",
        Value = true,
        Callback = function(v)
            if v then
                if antiAFKConnection then
                    antiAFKConnection:Disconnect()
                end
                antiAFKConnection = LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            else
                if antiAFKConnection then
                    antiAFKConnection:Disconnect()
                    antiAFKConnection = nil
                end
            end
        end
    })

    Tabs.LocalPlayer:Toggle({
        Title = "Anti Gameplay Paused",
        Value = true,
        Callback = function(v)
            if v then
                if networkPaused then
                    networkPaused:Disconnect()
                end
                networkPaused = CoreGui.RobloxGui.ChildAdded:Connect(function(obj)
                    if obj.Name == "CoreScripts/NetworkPause" then
                        obj:Destroy()
                    end
                end)
                CoreGui.RobloxGui["CoreScripts/NetworkPause"]:Destroy()
            else
                if networkPaused then
                    networkPaused:Disconnect()
                    networkPaused = nil
                end
            end
        end
    })

    Tabs.LocalPlayer:Section({ Title = "Movement", TextSize = 18 })
    local infiniteJumpConn = nil
    Tabs.LocalPlayer:Slider({
        Title = "Walk Speed",
        Step = 1,
        Value = { Min = 16, Max = 200, Default = 16 },
        Callback = function(v)
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = v end
                end
            end)
        end
    })

    Tabs.LocalPlayer:Slider({
        Title = "Jump Power",
        Step = 1,
        Value = { Min = 50, Max = 200, Default = 50 },
        Callback = function(v)
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.JumpPower = v end
                end
            end)
        end
    })

    Tabs.LocalPlayer:Toggle({
        Title = "Infinite Jump",
        Value = false,
        Callback = function(v)
            if v then
                if not infiniteJumpConn then
                    infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
                        pcall(function()
                            local char = LocalPlayer.Character
                            if char then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                            end
                        end)
                    end)
                end
            else
                if infiniteJumpConn then
                    infiniteJumpConn:Disconnect()
                    infiniteJumpConn = nil
                end
            end
        end
    })

    Tabs.LocalPlayer:Section({ Title = "Collision", TextSize = 18 })
    local noclipConn = nil
    local origOcclusion = nil
    local origMaxZoom = nil
    local origMinZoom = nil
    Tabs.LocalPlayer:Toggle({
        Title = "Noclip Character",
        Value = false,
        Callback = function(v)
            if v then
                if not noclipConn then
                    noclipConn = RunService.Stepped:Connect(function()
                        local char = LocalPlayer.Character
                        if not char then return end
                        for _, p in pairs(char:GetDescendants()) do
                            if p:IsA("BasePart") and p.CanCollide then
                                p.CanCollide = false
                            end
                        end
                    end)
                end
            else
                if noclipConn then
                    noclipConn:Disconnect()
                    noclipConn = nil
                end
            end
        end
    })

    Tabs.LocalPlayer:Toggle({
        Title = "Noclip Camera",
        Value = false,
        Callback = function(v)
            local sc = (debug and debug.setconstant) or setconstant
            local gc = (debug and debug.getconstants) or getconstants
            
            if sc and getgc and gc then
                -- IY Methode
                local pop = LocalPlayer.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
                for _, fn in pairs(getgc()) do
                    if type(fn) == "function" and pcall(function() return getfenv(fn).script == pop end) then
                        for i, val in pairs(gc(fn)) do
                            if v then
                                if tonumber(val) == 0.25 then sc(fn, i, 0) end
                            else
                                if tonumber(val) == 0 then sc(fn, i, 0.25) end
                            end
                        end
                    end
                end
            else
                -- Fallback Methode
                if v then
                    if not origOcclusion then
                        origOcclusion = LocalPlayer.DevCameraOcclusionMode
                    end
                    LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
                else
                    if origOcclusion then
                        LocalPlayer.DevCameraOcclusionMode = origOcclusion
                        origOcclusion = nil
                    end
                end
            end
        end
    })

    Tabs.LocalPlayer:Toggle({
        Title = "Unlimited Zoom",
        Value = false,
        Callback = function(v)
            if v then
                if not origMaxZoom then
                    origMaxZoom = LocalPlayer.CameraMaxZoomDistance
                end
                if not origMinZoom then
                    origMinZoom = LocalPlayer.CameraMinZoomDistance
                end
                LocalPlayer.CameraMaxZoomDistance = 3000
                LocalPlayer.CameraMinZoomDistance = 0.5
            else
                if origMaxZoom then
                    LocalPlayer.CameraMaxZoomDistance = origMaxZoom
                    origMaxZoom = nil
                end
                if origMinZoom then
                    LocalPlayer.CameraMinZoomDistance = origMinZoom
                    origMinZoom = nil
                end
            end
        end
    })
end


--------------------------------------------------------------------------------
-- TAB: MISC & CONFIG > ESP
--------------------------------------------------------------------------------
do
    Tabs.ESP:Section({ Title = "ESP Options", TextSize = 18 })

    Tabs.ESP:Toggle({
        Title = "ESP Another Player",
        Desc = "Highlights other players",
        Value = false,
        Callback = function(v) S.ESPPlayers = v end
    })

    Tabs.ESP:Toggle({
        Title = "ESP Recipe",
        Desc = "Highlights recipe claim locations",
        Value = false,
        Callback = function(v) S.ESPRecipe = v end
    })

    Tabs.ESP:Toggle({
        Title = "ESP Loot",
        Desc = "Highlights loot drops",
        Value = false,
        Callback = function(v) S.ESPLoot = v end
    })
end

-- ESP
task.spawn(function()
    -- ESP Helper: Create name billboard
    local function createESPBillboard(parent, text, color)
        local existing = parent:FindFirstChild("_ESPBillboard")
        if existing then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "_ESPBillboard"
        bb.AlwaysOnTop = true
        bb.Size = UDim2.fromOffset(200, 30)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.LightInfluence = 0
        bb.Parent = parent
        local tl = Instance.new("TextLabel")
        tl.Name = "Label"
        tl.Size = UDim2.fromScale(1, 1)
        tl.BackgroundTransparency = 1
        tl.TextColor3 = color or Color3.new(1, 1, 1)
        tl.TextStrokeTransparency = 0
        tl.TextStrokeColor3 = Color3.new(0, 0, 0)
        tl.Font = Enum.Font.GothamBold
        tl.TextScaled = true
        tl.Text = text
        tl.Parent = bb
    end
    
    local function removeESP(obj)
        local h = obj:FindFirstChild("_ESP")
        if h then h:Destroy() end
        local bb = obj:FindFirstChild("_ESPBillboard")
        if bb then bb:Destroy() end
    end
    
    while true do
        pcall(function()
            -- Player ESP
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local existing = player.Character:FindFirstChild("_ESP")
                    if S.ESPPlayers and not existing then
                        local h = Instance.new("Highlight")
                        h.Name = "_ESP"
                        h.FillColor = Color3.fromRGB(255, 100, 100)
                        h.FillTransparency = 0.6
                        h.OutlineTransparency = 0
                        h.Parent = player.Character
                        createESPBillboard(player.Character, player.DisplayName or player.Name, Color3.fromRGB(255, 150, 150))
                    elseif not S.ESPPlayers and existing then
                        removeESP(player.Character)
                    end
                end
            end
            -- Loot ESP
            local lootFolder = Workspace:FindFirstChild("Loot")
            if lootFolder then
                for _, loot in pairs(lootFolder:GetChildren()) do
                    local existing = loot:FindFirstChild("_ESP")
                    if S.ESPLoot and not existing then
                        local h = Instance.new("Highlight")
                        h.Name = "_ESP"
                        h.FillColor = Color3.fromRGB(255, 255, 0)
                        h.FillTransparency = 0.5
                        h.Parent = loot
                        -- Get loot name for label
                        local lootName = "Loot"
                        local bb = loot:FindFirstChild("LootBillboard")
                        if bb then
                            local tl = bb:FindFirstChild("TextLabel")
                            if tl then lootName = tl.Text end
                        else
                            for _, child in pairs(loot:GetChildren()) do
                                if (child:IsA("Model") or child:IsA("MeshPart")) and not string.match(child.Name, "^%x%x%x%x") then
                                    lootName = child.Name:sub(1,1):upper() .. child.Name:sub(2)
                                    break
                                end
                            end
                        end
                        createESPBillboard(loot, lootName, Color3.fromRGB(255, 255, 100))
                    elseif not S.ESPLoot and existing then
                        removeESP(loot)
                    end
                end
            end
            -- Recipe ESP
            if S.ESPRecipe then
                local gp = getGameplayFolder()
                if gp then
                    local recipes = gp:FindFirstChild("Recipes") or gp:FindFirstChild("RecipeInstances")
                    if recipes then
                        for _, recipe in pairs(recipes:GetChildren()) do
                            local existing = recipe:FindFirstChild("_ESP")
                            if not existing then
                                local h = Instance.new("Highlight")
                                h.Name = "_ESP"
                                h.FillColor = Color3.fromRGB(100, 255, 100)
                                h.FillTransparency = 0.4
                                h.Parent = recipe
                                createESPBillboard(recipe, recipe.Name, Color3.fromRGB(150, 255, 150))
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0)
    end
end)


--------------------------------------------------------------------------------
-- TAB: MISC & CONFIG > MISC
--------------------------------------------------------------------------------
do
    Tabs.Misc:Section({ Title = "Reconnect", TextSize = 18 })
    local AutoReconnect = true
    local AutoExecute = true

    Tabs.Misc:Toggle({
        Title = "Auto Reconnect on Teleport",
        Desc = "Rejoins if teleported/disconnected",
        Value = false,
        Callback = function(v)
            AutoReconnect = v
        end
    })

    Tabs.Misc:Toggle({
        Title = "Auto Execute on Teleport",
        Desc = "Re-executes script after rejoin",
        Value = false,
        Callback = function(v)
            AutoExecute = v
        end
    })

    Tabs.Misc:Section({ Title = "Performance", TextSize = 18 })
    local origSettings = {}

    Tabs.Misc:Slider({
        Title = "Max FPS",
        Step = 1,
        Value = { Min = 30, Max = 9999, Default = 60 },
        Callback = function(v)
            pcall(function() setfpscap(v) end)
        end
    })

    Tabs.Misc:Toggle({
        Title = "Hide GUI",
        Value = false,
        Callback = function(v)
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    for _, gui in pairs(pg:GetChildren()) do
                        if gui:IsA("ScreenGui") and gui.Name ~= "WindUI" then
                            gui.Enabled = not v
                        end
                    end
                end
            end)
        end
    })

    Tabs.Misc:Toggle({
        Title = "Disable Rendering",
        Value = false,
        Callback = function(v)
            pcall(function()
                RunService:Set3dRenderingEnabled(not v)
            end)
        end
    })

    local function saveLowGraphicOriginal()
        if Terrain then
            origSettings.WaterWaveSize = Terrain.WaterWaveSize
            origSettings.WaterWaveSpeed = Terrain.WaterWaveSpeed
            origSettings.WaterReflectance = Terrain.WaterReflectance
            origSettings.WaterTransparency = Terrain.WaterTransparency
        end
        if Lighting then
            origSettings.GlobalShadows = Lighting.GlobalShadows
            origSettings.FogStart = Lighting.FogStart
            origSettings.FogEnd = Lighting.FogEnd
            if Lighting:FindFirstChild("Atmosphere") then
                origSettings.AtmDensity = Lighting.Atmosphere.Density
                origSettings.AtmGlare = Lighting.Atmosphere.Glare
                origSettings.AtmHaze = Lighting.Atmosphere.Haze
            end
        end
        pcall(function()
            origSettings.EnableFRM = settings().Rendering.EnableFRM
            origSettings.MeshPartDetailLevel = settings().Rendering.MeshPartDetailLevel
            origSettings.QualityLevel = settings().Rendering.QualityLevel
        end)
    end

    local function restoreLowGraphic()
        if Terrain then
            Terrain.WaterWaveSize = origSettings.WaterWaveSize or 0
            Terrain.WaterWaveSpeed = origSettings.WaterWaveSpeed or 0
            Terrain.WaterReflectance = origSettings.WaterReflectance or 0
            Terrain.WaterTransparency = origSettings.WaterTransparency or 0
        end
        if Lighting then
            Lighting.GlobalShadows = origSettings.GlobalShadows ~= nil and origSettings.GlobalShadows or true
            Lighting.FogStart = origSettings.FogStart or 0
            Lighting.FogEnd = origSettings.FogEnd or 0
            if Lighting:FindFirstChild("Atmosphere") then
                Lighting.Atmosphere.Density = origSettings.AtmDensity or 0.395
                Lighting.Atmosphere.Glare = origSettings.AtmGlare or 0
                Lighting.Atmosphere.Haze = origSettings.AtmHaze or 0
            end
        end
        pcall(function()
            if origSettings.EnableFRM ~= nil then
                settings().Rendering.EnableFRM = origSettings.EnableFRM
            end
            if origSettings.MeshPartDetailLevel then
                settings().Rendering.MeshPartDetailLevel = origSettings.MeshPartDetailLevel
            end
            if origSettings.QualityLevel then
                settings().Rendering.QualityLevel = origSettings.QualityLevel
            end
        end)
    end

    local function lowGraphic()
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
            if Terrain:FindFirstChild("Clouds") then
                Terrain.Clouds:Destroy()
            end
        end

        if Lighting then
            Lighting.GlobalShadows = false
            Lighting.FogStart = 9e9
            Lighting.FogEnd = 9e9
            if Lighting:FindFirstChild("Atmosphere") then
                Lighting.Atmosphere.Density = 0.01
                Lighting.Atmosphere.Glare = 0
                Lighting.Atmosphere.Haze = 0
            end
            if Lighting:FindFirstChild("LightingProfiles") then
                Lighting.LightingProfiles:Destroy()
            end
            if Lighting:FindFirstChild("OG") then
                Lighting.OG:Destroy()
            end
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or
                    effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") then
                    effect:Destroy()
                end
            end
        end

        if MaterialService then
            for _, material in pairs(MaterialService:GetChildren()) do
                if material:IsA("MaterialVariant") then
                    material:Destroy()
                end
            end
        end

        pcall(function()
            settings().Rendering.EnableFRM = false
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        local function optimization(object)
            if object:IsA("BasePart") then
                object.CastShadow = false
                object.Reflectance = 0
                object.Material = Enum.Material.Plastic
                object.BackSurface = Enum.SurfaceType.SmoothNoOutlines
                object.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
                object.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
                object.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
                object.RightSurface = Enum.SurfaceType.SmoothNoOutlines
                object.TopSurface = Enum.SurfaceType.SmoothNoOutlines
            end
            if object:IsA("Decal") or object:IsA("Texture") then
                object.Transparency = 1
                object.Texture = ""
            end
            if object:IsA("SurfaceAppearance") then
                object.ColorMap = ""
                object.MetalnessMap = ""
                object.NormalMap = ""
                object.RoughnessMap = ""
                object.TexturePack = ""
            end
            if object:IsA("ParticleEmitter") or object:IsA("Smoke") or object:IsA("Fire") or object:IsA("Sparkles") then
                object.Enabled = false
            end
            if object:IsA("Trail") or object:IsA("Beam") then
                object.Enabled = false
            end
            if object:IsA("MeshPart") then
                object.Material = Enum.Material.SmoothPlastic
                object.TextureID = ""
            end
            if object:IsA("SpecialMesh") then
                if object.Parent and object.Parent.Name == "Head" then return end
                object.MeshId = ""
                object.TextureId = ""
            end
        end

        local count = 0
        local interval = isMobile and 25 or 100
        for _, object in pairs(game:GetDescendants()) do
            optimization(object)
            count = count + 1
            if count % interval == 0 then
                task.wait()
            end
        end

        workspace.DescendantAdded:Connect(function(child)
            task.spawn(function()
                optimization(child)
            end)
        end)
    end

    Tabs.Misc:Toggle({
        Title = "Low Graphic",
        Value = false,
        Callback = function(v)
            if v then
                saveLowGraphicOriginal()
                lowGraphic()
            else
                restoreLowGraphic()
            end
        end
    })

    -- Auto Reconnect & Auto Execute
    task.spawn(function()
        local TeleportService = cloneref(game:GetService("TeleportService"))
        local PLACE_ID = game.PlaceId
        local JOB_ID = game.JobId
        local EXEC_SOURCE = 'loadstring(game:HttpGet("https://github.com/petrixbot/roblox-hub/blob/main/loader"))()'
        local queueFn = queue_on_teleport or (syn and syn.queue_on_teleport) or nil
        
        local function doReconnect()
            if AutoReconnect then
                task.wait(3)
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, JOB_ID, LocalPlayer)
                end)
            end
        end
        
        local function queueExec()
            if AutoExecute and queueFn then
                pcall(function()
                    queueFn(EXEC_SOURCE)
                end)
            end
        end
        
        -- When teleport starting (switching servers)
        LocalPlayer.OnTeleport:Connect(function(teleportState)
            if teleportState == Enum.TeleportState.Started then
                queueExec()
            end
        end)
        
        -- Teleporting failed
        pcall(function()
            TeleportService.TeleportInitFailed:Connect(function()
                doReconnect()
            end)
        end)
        
        -- Kicked / Disconnected from server
        pcall(function()
            LocalPlayer.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    queueExec()
                    doReconnect()
                end
            end)
        end)
        
        -- Character deleted (kick via character)
        LocalPlayer.CharacterRemoving:Connect(function()
            task.wait(3)
            if not LocalPlayer.Character then
                doReconnect()
            end
        end)
    end)
end


--------------------------------------------------------------------------------
-- TAB: MISC & CONFIG > CONFIGURATION
--------------------------------------------------------------------------------
do
    local needRefresh = false
    local ConfigManager = Window.ConfigManager
    local ConfigName = nil
    local ConfigLoad = nil
    local ConfigList = ConfigManager:AllConfigs()
    local AutoLoadRegistryPath = ConfigManager.Path .. "__autoload.txt"

    local function getAutoLoadConfig()
        if not isfile or not isfile(AutoLoadRegistryPath) then return nil end
        local ok, result = pcall(readfile, AutoLoadRegistryPath)
        if ok and result and result ~= "" then return result end
        return nil
    end

    local function saveAutoLoadConfig(name)
        if not writefile then return end
        pcall(writefile, AutoLoadRegistryPath, name)
    end

    local function clearAutoLoadConfig()
        if not writefile then return end
        pcall(writefile, AutoLoadRegistryPath, "")
    end

    Tabs.Config:Section({ Title = "Create Config", TextSize = 18 })

    local ConfigInput = Tabs.Config:Input({
        Title = "Config Name",
        Placeholder = "config_name",
        Callback = function(value) ConfigName = value end
    })

    Tabs.Config:Button({
        Title = "Create Config",
        Icon = "plus", IconAlign = "Left", Justify = "Center",
        Callback = function()
            if not ConfigName or ConfigName == "" then
                return Window:Dialog({ Title = "Failed", Content = "Input Config Name first!", Buttons = {{Title = "OK", Variant = "Primary"}} })
            end
            if ConfigManager:GetConfig(ConfigName) then
                return Window:Dialog({ Title = "Failed", Content = "Config already exists!", Buttons = {{Title = "OK", Variant = "Primary"}} })
            end
            local ok, err = pcall(function() ConfigManager:CreateConfig(ConfigName):Save() end)
            needRefresh = true
            notify(ok and "Config" or "Error", ok and ("Created " .. ConfigName) or tostring(err), ok and "check" or "x")
        end
    })

    Tabs.Config:Section({ Title = "Select Config", TextSize = 18 })

    local ConfigDropdown = Tabs.Config:Dropdown({
        Title = "Select Config",
        Values = ConfigList, Value = nil, AllowNone = true,
        Callback = function(value)
            ConfigName = value
            ConfigInput:Set(ConfigName or "")
            ConfigLoad = value and (ConfigManager:GetConfig(value) or ConfigManager:CreateConfig(value)) or nil
        end
    })

    Tabs.Config:Button({
        Title = "Refresh", Icon = "refresh-ccw", IconAlign = "Left", Justify = "Center",
        Callback = function() needRefresh = true end
    })

    local CfgGroup = Tabs.Config:Group({})
    CfgGroup:Button({ Title = "Load", Icon = "folder", IconAlign = "Left", Justify = "Center",
        Callback = function()
            if not ConfigLoad then return Window:Dialog({ Title = "Failed", Content = "Select config first!", Buttons = {{Title = "OK", Variant = "Primary"}} }) end
            local ok, err = pcall(function() ConfigLoad:Load() end)
            notify(ok and "Loaded" or "Error", ok and ConfigName or tostring(err), ok and "check" or "x")
        end
    })
    CfgGroup:Button({ Title = "Save", Icon = "save", IconAlign = "Left", Justify = "Center",
        Callback = function()
            if not ConfigLoad then return Window:Dialog({ Title = "Failed", Content = "Select config first!", Buttons = {{Title = "OK", Variant = "Primary"}} }) end
            local ok, err = pcall(function() ConfigLoad:Save() end)
            notify(ok and "Saved" or "Error", ok and ConfigName or tostring(err), ok and "check" or "x")
        end
    })
    CfgGroup:Button({ Title = "Delete", Icon = "trash-2", IconAlign = "Left", Justify = "Center",
        Callback = function()
            if not ConfigLoad then return Window:Dialog({ Title = "Failed", Content = "Select config first!", Buttons = {{Title = "OK", Variant = "Primary"}} }) end
            if getAutoLoadConfig() == ConfigName then clearAutoLoadConfig() end
            pcall(function() ConfigManager:DeleteConfig(ConfigName) end)
            needRefresh = true
            notify("Deleted", ConfigName, "trash-2")
        end
    })

    Tabs.Config:Section({ Title = "Auto-Load", TextSize = 18 })
    local ALGroup = Tabs.Config:Group({})
    ALGroup:Button({ Title = "Enable", Icon = "circle-play", IconAlign = "Left", Justify = "Center",
        Callback = function()
            if not ConfigLoad then return Window:Dialog({ Title = "Failed", Content = "Select config first!", Buttons = {{Title = "OK", Variant = "Primary"}} }) end
            saveAutoLoadConfig(ConfigName)
            notify("Auto-Load", ConfigName .. " set as auto-load", "check")
        end
    })
    ALGroup:Button({ Title = "Disable", Icon = "circle-pause", IconAlign = "Left", Justify = "Center",
        Callback = function()
            if getAutoLoadConfig() ~= ConfigName then return end
            clearAutoLoadConfig()
            notify("Auto-Load", "Disabled", "trash-2")
        end
    })

    -- Auto-load on startup
    task.spawn(function()
        task.wait(1)
        local name = getAutoLoadConfig()
        if not name then return end
        local path = ConfigManager.Path .. name .. ".json"
        if not isfile or not isfile(path) then clearAutoLoadConfig() return end
        local cfg = ConfigManager:GetConfig(name) or ConfigManager:CreateConfig(name)
        local ok = pcall(function() cfg:Load() end)
        if ok then
            ConfigName = name
            ConfigLoad = cfg
            ConfigInput:Set(name)
            ConfigDropdown:Select(name)
            notify("Auto-Load", "Loaded " .. name, "check")
        end
    end)

    -- Refresh loop
    task.spawn(function()
        while task.wait(0.5) do
            if needRefresh then
                needRefresh = false
                ConfigName = nil
                ConfigLoad = nil
                ConfigInput:Set("")
                ConfigDropdown:Select(nil)
                ConfigDropdown:Refresh(ConfigManager:AllConfigs())
            end
        end
    end)
end


--------------------------------------------------------------------------------
-- FINAL
--------------------------------------------------------------------------------
getgenv().PETRIXHUB_LOADED = true
print("[.petrixhub] Script loaded successfully!")

Window:OnDestroy(function()
    getgenv().PETRIXHUB_LOADED = false
    if getgenv().__origRandom then math.random = getgenv().__origRandom end
end)