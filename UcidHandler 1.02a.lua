-- %%% CREDITS %%%
-- JGi | Quéton 1-1
local SCRIPT_NAME="UCID Handler"
local VERSION="1.02a"
local PRE="UCID Handler"
local DEBUG_MODE=false

-- %%% DEPENDENCIES %%%
-- None, put this to Saved Games/DCS/Scripts/Hooks/

--[[ %%% CHANGELOG %%%
    1.02a
    - pcall protection on all dofile() calls to prevent crash on corrupted files
    - fallback to empty table if file load fails, server keeps running
    - WriteDatas() now logs file write errors
    - All Load functions now guarantee a non-nil table after execution
    1.01b
    - small changes
    1.01a
    - Add save to text file
    - refactor on some parts
    - add comment to user
    1.00
    - Initial
--]]

-- %%% SCRIPT OPTIONS %%%
--> Set to your needs
local RESTRICT_RED_SLOTS=true
local RESTRICT_BLUE_SLOTS=false
local ONLY_WHITELIST_CAN_SLOT=false
local USE_INTERNAL_LISTS=false
local WELCOME_MESSAGE="Bienvenue"
local ON_SLOT_MESSAGE="Fly Safe"
local ON_DENIED_SLOT="Accès refusé"
local ON_WHITELIST_MESSAGE = "Connexion impossible, serveur restreint."
local ON_BANNED_MESSAGE = "Connexion impossible, vous êtes ban !"
local MULTI_INSTANCE_SERVER_MODE=false

--? SLOT PRIORITY : Blacklist > Whitelist if activated > Blue/red slots if restricted

--> UCID internal lists, in case of emergency :
local INTERNAL_BLACKLIST={
    ["azerty00000000000000000000000000"] = "Example callsign",
}
local INTERNAL_WHITELIST={
    ["azerty00000000000000000000000000"] = "Example callsign",
}
local INTERNAL_REDLIST={
    ["azerty00000000000000000000000000"] = "Example callsign",
}
local INTERNAL_BLUELIST={
    ["azerty00000000000000000000000000"] = "Example callsign",
}

-- %%% LOCALS %%%
local lfs=require('lfs')
local io=require('io')
local SendChat=net.send_chat_to
local DoStringIn=net.dostring_in
local StringFormat=string.format
local WriteDir=lfs.writedir
local CurrentDir=lfs.currentdir
local MkDir=lfs.mkdir
local Attributes=lfs.attributes
local OpenFile=io.open

local UCID_HANDLER_FOLDER="DCS Multiplayer UcidHandler"
local PDIR=".."
if MULTI_INSTANCE_SERVER_MODE==true then PDIR="" end
local SAVE_DIR=WriteDir()..PDIR.."\\"..UCID_HANDLER_FOLDER.."\\"
local UCID_LOG_FILE = SAVE_DIR.."UCID log.lua"
local UCID_BLACKLIST_FILE = SAVE_DIR.."UCID blacklist.lua"
local UCID_WHITELIST_FILE = SAVE_DIR.."UCID whitelist.lua"
local UCID_REDLIST_FILE = SAVE_DIR.."UCID redlist.lua"
local UCID_BLUELIST_FILE = SAVE_DIR.."UCID bluelist.lua"

-- %%% CORE %%%
local function Log(t) local _log=net.log if t then return _log(PRE.." "..VERSION.." | "..t) end end
local player=net.get_player_info
local function BasicSerialize(data)
    if data == nil then
        return "\"\""
    else
        if ((type(data) == 'number') or (type(data) == 'boolean') or (type(data) == 'function') or (type(data) == 'table') or (type(data) == 'userdata') ) then
            return tostring(data)
        elseif type(data) == 'string' then
            return StringFormat('%q', data)
        end
    end
end
local function SmartSerialize(name, value, saved)
    local Serialize = function (data)
        if type(data) == "number" then
            return tostring(data)
        elseif type(data) == "boolean" then
            return tostring(data)
        else
            return BasicSerialize(data)
        end
    end
    local t_str = {}
    saved = saved or {}
    if ((type(value) == 'string') or (type(value) == 'number') or (type(value) == 'table') or (type(value) == 'boolean')) then
        table.insert(t_str, name .. " = ")
        if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
            table.insert(t_str, Serialize(value) ..  "\n")
        else
            if saved[value] then
                table.insert(t_str, saved[value] .. "\n")
            else
                saved[value] = name
                table.insert(t_str, "{}\n")
                    for k,v in pairs(value) do
                        local fieldname = StringFormat("%s[%s]", name, Serialize(k))
                        table.insert(t_str, SmartSerialize(fieldname, v, saved))
                    end
            end
        end
        return table.concat(t_str)
    else
        return ""
    end
end
local function FileExists(fileToTest)
    if Attributes(fileToTest) then return true else return false end
end
local function IsDir(path)
    return lfs.attributes(path, "mode") == "directory"
end

local function WriteDatas(data, file)
    local _saveFile, err = OpenFile(file, "w")
    if _saveFile then
        _saveFile:write(data)
        _saveFile:close()
    else
        Log("ERREUR écriture fichier : " .. tostring(err) .. " -> " .. tostring(file))
    end
end
local function LoadUcidLog()
    ucid_log = nil
    if FileExists(UCID_LOG_FILE) then
        local ok, err = pcall(dofile, UCID_LOG_FILE)
        if not ok then
            Log("ERREUR lecture UCID log : " .. tostring(err))
        end
    end
    if ucid_log == nil then ucid_log = {} end
end
local function LoadUcidBlackList()
    ucid_blacklist = nil
    if FileExists(UCID_BLACKLIST_FILE) then
        local ok, err = pcall(dofile, UCID_BLACKLIST_FILE)
        if not ok then
            Log("ERREUR lecture blacklist : " .. tostring(err))
        end
    end
    if ucid_blacklist == nil then ucid_blacklist = {} end
end
local function LoadUcidWhiteList()
    ucid_whitelist = nil
    if FileExists(UCID_WHITELIST_FILE) then
        local ok, err = pcall(dofile, UCID_WHITELIST_FILE)
        if not ok then
            Log("ERREUR lecture whitelist : " .. tostring(err))
        end
    end
    if ucid_whitelist == nil then ucid_whitelist = {} end
end
local function LoadUcidRedList()
    ucid_redlist = nil
    if FileExists(UCID_REDLIST_FILE) then
        local ok, err = pcall(dofile, UCID_REDLIST_FILE)
        if not ok then
            Log("ERREUR lecture redlist : " .. tostring(err))
        end
    end
    if ucid_redlist == nil then ucid_redlist = {} end
end
local function LoadUcidBlueList()
    ucid_bluelist = nil
    if FileExists(UCID_BLUELIST_FILE) then
        local ok, err = pcall(dofile, UCID_BLUELIST_FILE)
        if not ok then
            Log("ERREUR lecture bluelist : " .. tostring(err))
        end
    end
    if ucid_bluelist == nil then ucid_bluelist = {} end
end
local function SaveUcidLog()
    local datas = SmartSerialize("ucid_log", ucid_log)
    WriteDatas(datas, UCID_LOG_FILE)
end
local function SaveBlacklist()
    local datas = SmartSerialize("ucid_blacklist", ucid_blacklist)
    WriteDatas(datas, UCID_BLACKLIST_FILE)
end
local function SaveWhitelist()
    local datas = SmartSerialize("ucid_whitelist", ucid_whitelist)
    WriteDatas(datas, UCID_WHITELIST_FILE)
end
local function SaveRedlist()
    local datas = SmartSerialize("ucid_redlist", ucid_redlist)
    WriteDatas(datas, UCID_REDLIST_FILE)
end
local function SaveBluelist()
    local datas = SmartSerialize("ucid_bluelist", ucid_bluelist)
    WriteDatas(datas, UCID_BLUELIST_FILE)
end
local function GetPlayer(id)
    local info=player(id)
    if info then return info end
    return nil
end

-- %%% MAIN %%%
if IsDir(SAVE_DIR)==false then 
    MkDir(SAVE_DIR)
end
LoadUcidLog()
LoadUcidBlackList()
LoadUcidWhiteList()
LoadUcidRedList()
LoadUcidBlueList()
Log("Script loaded - Credits : JGi | Quéton 1-1")
DCS.setUserCallbacks({
    onPlayerTryChangeSlot=function(playerID, side, slotID)
        LoadUcidBlackList()
        LoadUcidWhiteList()
        LoadUcidRedList()
        LoadUcidBlueList()
        local data=GetPlayer(playerID)
        if data and data.ucid and data.name then
            if ucid_blacklist[data.ucid] 
            or USE_INTERNAL_LISTS==true and INTERNAL_BLACKLIST[data.ucid] then
                SendChat(ON_DENIED_SLOT, playerID)
                Log("User Blacklisted : ".. data.ucid .." - "..data.name)
                return false
            end
            if ONLY_WHITELIST_CAN_SLOT==true and ucid_whitelist[data.ucid]==nil 
            or USE_INTERNAL_LISTS==true and ONLY_WHITELIST_CAN_SLOT==true and INTERNAL_WHITELIST[data.ucid]==nil then
                SendChat(ON_DENIED_SLOT, playerID)
                Log("Whitelist active, access denied : ".. data.ucid .." - "..data.name)
                return false
            end
            if RESTRICT_RED_SLOTS==true and side==1 and ucid_redlist[data.ucid]==nil 
            or USE_INTERNAL_LISTS==true and RESTRICT_RED_SLOTS==true and INTERNAL_REDLIST[data.ucid]==nil then
                SendChat(ON_DENIED_SLOT, playerID)
                Log("Redlist active, access denied : ".. data.ucid .." - "..data.name.." ("..side..")")
                return false
            end
            if RESTRICT_BLUE_SLOTS==true and side==2 and ucid_bluelist[data.ucid]==nil 
            or USE_INTERNAL_LISTS==true and RESTRICT_BLUE_SLOTS==true and INTERNAL_BLUELIST[data.ucid]==nil then
                SendChat(ON_DENIED_SLOT, playerID)
                Log("Bluelist active, access denied : ".. data.ucid .." - "..data.name.." ("..side..")")
                return false
            end
            local msg = ON_SLOT_MESSAGE.." ".. data.name
            SendChat(msg, playerID)
            DoStringIn('mission', StringFormat("trigger.action.outText('%s', 5)",msg))
            return true
        end
    end,
    onPlayerConnect = function(playerID)
        local data = GetPlayer(playerID)
        if data and data.ucid and data.name then
            ucid_log[data.ucid]=data.name
            local msg = WELCOME_MESSAGE.." ".. data.name
            SendChat(msg, playerID)
            DoStringIn('mission', StringFormat("trigger.action.outText('%s', 5)",msg))
            if io ~= nil and lfs ~= nil then SaveUcidLog() SaveBlacklist() SaveWhitelist() SaveRedlist() SaveBluelist() end
        end
    end,
    onPlayerTryConnect=function(addr, name, ucid, id)
        LoadUcidBlackList()
        LoadUcidWhiteList()
        if ucid_blacklist[ucid] 
        or USE_INTERNAL_LISTS==true and INTERNAL_BLACKLIST[ucid] then
            Log("User Blacklisted : ".. ucid .." - "..name)
            return false, ON_BANNED_MESSAGE
        end
        if ONLY_WHITELIST_CAN_SLOT==true and ucid_whitelist[ucid]==nil 
        or USE_INTERNAL_LISTS==true and ONLY_WHITELIST_CAN_SLOT==true and INTERNAL_WHITELIST[ucid] then
            Log("Whitelist active, access denied : ".. ucid .." - "..name)
            return false, ON_WHITELIST_MESSAGE
        end
    end,
})
