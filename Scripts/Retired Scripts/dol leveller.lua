-- Ideally used with The Road to 90 buff, otherwise it will take double the amount for everything
-- You need approx 2m gil per character you wish to level through this with The Road to 90, probably 4mil with no buff (no clue, you won't have the double xp though)
-- You likely only need around 20-30 per item it asks for, fish 2-3, very unlikely you need more than that, don't spend more than 20k or try not to
-- Maybe don't bother doing Fisher, mb prices get too high around level 50 onwards. Probably better to just do Ocean Fishing if you value gil.
-- This is not a full automated script (yet, maybe maybe not)
-- It will teleport you to a market board, you are required to purchase the items the GC asks for, after that it will auto turnin and log off, you will need to start the script again for additional characters
-- If the market board does not have the item you need, stop the script and go to another world, start the script again
-- Closing the market board early doesn't matter either, cancel the tp and buy items, then /tp limsa
-- You should use the Yes Already plugin to bypass the capped seals warning or it will break the script

--###########
--# CONFIGS #
--###########

-- this toggle allows you to run the script on as many characters as you'd like, it'll rotate between them
MULTICHAR = false

CharList = "CharList.lua"

--#####################################
--#  DON'T TOUCH ANYTHING BELOW HERE  #
--# UNLESS YOU KNOW WHAT YOU'RE DOING #
--#####################################

SNDConfigFolder = os.getenv("appdata") .. "\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\"
LoadFunctionsFileLocation = os.getenv("appdata") .. "\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\vac_functions.lua"
LoadFunctions = loadfile(LoadFunctionsFileLocation)
LoadFunctions()
LoadFileCheck()

--##############
--  DOL STUFF
--##############

function DOL()
    OpenTimers()
    Teleporter("Ul'dah", "tp")
    ZoneTransitions()
    yield("/li mb")
    ZoneTransitions()
    MarketBoardChecker() -- should probably add auto buying here or something
    Teleporter("Limsa", "tp")
    ZoneTransitions()
    yield("/li Aftcastle")
    ZoneTransitions()
    Movement(93.00, 40.27, 75.60)
    OpenGcSupplyWindow(1)
    GcProvisioningDeliver(3)
    CloseGcSupplyWindow()
    LogOut()
end

--###############
--# MAIN SCRIPT #
--###############

function Main()
    DOL()
end

if MULTICHAR then
    for _, char in ipairs(character_list) do
        if GetCharacterName(true) == char then
            -- continue, no relogging needed
        else
            RelogCharacter(char)
            Sleep(15.0)
            LoginCheck()
        end
        repeat
            Sleep(0.1)
        until IsPlayerAvailable()
        Main()
    end
else
    Main()
end