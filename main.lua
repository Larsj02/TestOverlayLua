local specToClass = {
    [250] = "DEATH_KNIGHT", -- Blood
    [251] = "DEATH_KNIGHT", -- Frost
    [252] = "DEATH_KNIGHT", -- Unholy
    [1455] = "DEATH_KNIGHT", -- Initial

    [577] = "DEMON_HUNTER", -- Havoc
    [581] = "DEMON_HUNTER", -- Vengeance
    [1456] = "DEMON_HUNTER", -- Initial

    [102] = "DRUID", -- Balance
    [103] = "DRUID", -- Feral
    [104] = "DRUID", -- Guardian
    [105] = "DRUID", -- Restoration
    [1447] = "DRUID", -- Initial

    [1467] = "EVOKER", -- Devastation
    [1468] = "EVOKER", -- Preservation
    [1473] = "EVOKER", -- Augmentation
    [1465] = "EVOKER", -- Initial

    [253] = "HUNTER", -- Beast Mastery
    [254] = "HUNTER", -- Marksmanship
    [255] = "HUNTER", -- Survival
    [1448] = "HUNTER", -- Initial

    [62] = "MAGE", -- Arcane
    [63] = "MAGE", -- Fire
    [64] = "MAGE", -- Frost
    [1449] = "MAGE", -- Initial

    [268] = "MONK", -- Brewmaster
    [270] = "MONK", -- Mistweaver
    [269] = "MONK", -- Windwalker
    [1450] = "MONK", -- Initial

    [65] = "PALADIN", -- Holy
    [66] = "PALADIN", -- Protection
    [70] = "PALADIN", -- Retribution
    [1451] = "PALADIN", -- Initial

    [256] = "PRIEST", -- Discipline
    [257] = "PRIEST", -- Holy
    [258] = "PRIEST", -- Shadow
    [1452] = "PRIEST", -- Initial

    [259] = "ROGUE", -- Assassination
    [260] = "ROGUE", -- Outlaw
    [261] = "ROGUE", -- Subtlety
    [1453] = "ROGUE", -- Initial

    [262] = "SHAMAN", -- Elemental
    [263] = "SHAMAN", -- Enhancement
    [264] = "SHAMAN", -- Restoration
    [1444] = "SHAMAN", -- Initial

    [265] = "WARLOCK", -- Affliction
    [266] = "WARLOCK", -- Demonology
    [267] = "WARLOCK", -- Destruction
    [1454] = "WARLOCK", -- Initial

    [71] = "WARRIOR", -- Arms
    [72] = "WARRIOR", -- Fury
    [73] = "WARRIOR", -- Protection
    [1446] = "WARRIOR", -- Initial
}

local classColors = {
    ["DEATH_KNIGHT"] = "#C41E3A",
    ["DEMON_HUNTER"] = "#A330C9",
    ["DRUID"] = "#FF7C0A",
    ["EVOKER"] = "#33937F",
    ["HUNTER"] = "#AAD372",
    ["MAGE"] = "#3FC7EB",
    ["MONK"] = "#00FF98",
    ["PALADIN"] = "#F48CBA",
    ["PRIEST"] = "#FFFFFF",
    ["ROGUE"] = "#FFF468",
    ["SHAMAN"] = "#0070DD",
    ["WARLOCK"] = "#8788EE",
    ["WARRIOR"] = "#C69B6D",
}

DataProcess = {
    fileDir = "C:\\Program Files (x86)\\World of Warcraft\\_retail_\\Logs",
    logFile = nil,
    lastFileSize = 0,
    activeAuras = {},
    groupData = {}
}

function DataProcess:New(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    obj:RefreshFilePath()
    return obj
end

function DataProcess:ColorString(text, hexColor)
    local escapeCode = string.format("\27[38;2;%d;%d;%dm",
        tonumber(hexColor:sub(2, 3), 16),
        tonumber(hexColor:sub(4, 5), 16),
        tonumber(hexColor:sub(6, 7), 16))
    local resetCode = "\27[0m"
    return escapeCode .. text .. resetCode
end

function DataProcess:RefreshFilePath()
    local lfs = require "lfs"
    local lastModificationTime = 0
    for file in lfs.dir(self.fileDir) do
        local fullPath = string.format("%s\\%s",self.fileDir, file)
        local attr = lfs.attributes(fullPath)
        if attr and attr.mode == "file" and file:match("^WoWCombatLog") and attr.modification > lastModificationTime then
            self.logFile = file
            lastModificationTime = attr.modification
        end
    end
    print(string.format("Log Found! (%s)", self.logFile))
end

function DataProcess:ChangeDir(dir)
    self.fileDir = dir
    self:RefreshFilePath()
end

function DataProcess:ProcessCombatant(combatantLine)
    local function parseNestedData(input)
        local parsedTbl = {}
        local inLevel = 0
        local currentString = ""

        for char in input:gmatch(".") do
            if char == "(" or char == "[" then inLevel = inLevel + 1
            elseif char == ")" or char == "]" then inLevel = inLevel - 1 end

            if (char == "," or char == ")" or char == "]") and inLevel == 0 then
                if currentString ~= "" then
                    if char == ")" or char == "]" then
                        ---@diagnostic disable-next-line: cast-local-type
                        currentString = parseNestedData(currentString:sub(2))
                    end
                    table.insert(parsedTbl, currentString)
                    currentString = ""
                end
            else
                currentString = currentString .. char
            end
        end

        return parsedTbl
    end
    local parsedPlayerData = parseNestedData(combatantLine)
    self.groupData[parsedPlayerData[2]] = {
        rawData = parsedPlayerData,
        color = classColors[specToClass[tonumber(parsedPlayerData[25])]]
    }
end

function DataProcess:Cleu(line)
end


function DataProcess:ReadFile()
    local file = io.open(string.format("%s\\%s",self.fileDir, self.logFile), "r")
    if file then
        local currentFileSize = file:seek("end")
        if self.lastFileSize == 0 then self.lastFileSize = currentFileSize end
        if currentFileSize > self.lastFileSize then
            file:seek("set", self.lastFileSize)
            self.lastFileSize = currentFileSize

            local newContent = file:read("*a")
            for line in newContent:gmatch("[^\r\n]+") do
                self:Cleu(line)
            end
        end
        file:close()
    else
        print("Error opening the file.")
    end
end

local cL = DataProcess:New()
cL:ReadFile()
local eventData = "8/9 22:30:08.346  COMBATANT_INFO,Player-3674-0B2AE8A0,1,921,1419,27722,13224,0,0,0,1186,1186,1186,0,325,6406,6406,6406,0,1593,4940,4940,4940,2410,63,[(62091,80147,1),(62092,80148,1),(62094,80150,1),(62098,80155,1),(62099,80156,2),(62102,80159,1),(62104,80161,1),(62105,80163,1),(62107,80165,2),(62112,80170,2),(62113,80171,1),(62114,80173,2),(62115,80174,1),(62118,80177,1),(62120,80179,1),(62122,80181,1),(62123,80182,2),(62124,80183,1),(62127,80187,1),(62190,80256,2),(62192,80258,1),(62195,80261,1),(62196,80262,1),(62198,80265,1),(62201,80269,1),(62202,80270,2),(62203,80271,1),(62205,80273,1),(62207,80275,1),(62208,80276,1),(62209,80277,1),(62210,80278,1),(62212,80280,1),(62213,80281,1),(62214,80282,1),(62215,80283,1),(62216,80284,1),(62217,80285,1),(62218,80286,1),(62219,80287,1),(62220,80288,1),(93524,115877,1),(62119,80178,1),(62083,80139,1),(62095,80152,1),(62096,80153,2),(62101,80158,2),(62126,80186,1),(62188,80254,1),(62194,80260,1),(62197,80264,1),(62206,80274,1),(62211,80279,1)],(0,0,0,203284),[(193523,447,(),(8836,8840,8902),()),(201759,447,(),(8836,8840,8902,9477,8782),(192985,415,192948,415,192948,415)),(202549,450,(),(6652,9227,9410,9383,1507,8767),()),(98087,1,(),(),()),(202554,447,(6625,0,0),(6652,9231,9382,1498,8767),()),(193516,447,(6904,0,5953),(8836,8840,8902),(192948,415)),(202550,447,(6541,0,0),(6652,9228,9410,9382,1504,8767),()),(193519,447,(6613,0,0),(8836,8840,8902),()),(193510,447,(6580,0,0),(8836,8840,8902),(192948,415)),(202552,447,(),(6652,9230,9382,1498,8767),()),(192999,447,(6562,0,0),(8836,8840,8902,8780),(192948,415)),(193000,447,(6562,0,0),(8836,8840,8902,8780),(192948,415)),(203729,447,(),(9410,6652,9382,1501,8767),()),(202615,447,(),(9410,6652,9382,1504,8767),()),(204465,441,(6598,0,0),(6652,7979,9334,1482,8767),()),(190511,447,(6643,6518,0),(8836,8840,8902),()),(194879,447,(),(8836,8840,8902),()),(103636,33,(),(),())],[Player-3674-0B2AE8A0,371172,Player-3674-0B2AE8A0,416715,Player-3674-0B2AE8A0,383886,Player-3674-0B2AE8A0,384033,Player-3674-0B2AE8A0,383810,Player-3674-0B2AE8A0,416714,Player-3674-0B239E37,389684,Player-3674-0B239E37,389685,Player-3674-0B2AE8A0,411537,Player-3674-0B18B930,1126,Player-3391-0C514EB7,6673,Player-3674-0B2352D4,381750,Player-3674-0B0F78EE,41635,Player-3674-0B245903,21562,Player-3674-0B2AE8A0,396092,Player-3674-0B2579E2,1459],99,0,0,0"
cL:ProcessCombatant(eventData)
for _, playerTbl in pairs(cL.groupData) do
    print(cL:ColorString("testText", playerTbl.color))
end