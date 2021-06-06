local here = arg[1]
package.path = package.path .. ';'..here..'/?.lua;'..here..'/deps/alloui/lib/pl/lua/?.lua'
local json = require "json"
local tablex = require"pl.tablex"

function createLock()
    local buildss = readfile(here.."/builds.json")
    local buildsj = json.decode(buildss)
    local latestId = tostring(buildsj["value"][1]["id"])
    print("Latest Allonet build ID is " .. latestId)
    writefile(here.."/allonet.lock", latestId)
end

--------------------------------------------------------------

function fetch(targetVersion)
    local cachefilepath = here.."/lib/allonet.cache"
    local currentVersion = trim(readfile(cachefilepath))
    local plats = {
        ["Allonet-Linux-x64"]=   { path="Allonet-Linux-x64/build/liballonet.so", dest="lib/linux64/liballonet.so" },
        ["Allonet-Windows-x64"]= { path="Allonet-Windows-x64/build/Release/allonet.dll", dest="lib/win64/liballonet.dll"},
        ["Allonet-Mac-x64"]=     { path="Allonet-Mac-x64/build/liballonet.dylib", dest="lib/osx64/liballonet.dylib"}
    }
    if 
        currentVersion == targetVersion and 
        all(tablex.values(plats), function(plat) return file_exists(here.."/"..plat.dest) end)
    then
        print("Not fetching allonet "..targetVersion.."; already up to date.")
        return
    end
    print("Fetching allonet "..targetVersion)
    for artifactName, desc in pairs(plats) do
        fetchSingle(targetVersion, artifactName, desc.path, desc.dest)
    end
    writefile(cachefilepath, targetVersion)
end

function fetchSingle(targetVersion, artifactName, path, relDestination)
    local destination = here .. "/" .. relDestination
    local destinationFolder = system("dirname "..destination)
    print("Fetching "..artifactName.."#"..targetVersion)
    local tempFilename = system("basename "..path)
    local renameMe = destinationFolder.."/"..tempFilename
    
    local buildlisturl = "https://dev.azure.com/alloverse/allonet/_apis/build/builds/" .. targetVersion .. "/artifacts?artifactName=" .. artifactName .. "&api-version=5.0"
    local jsons = system("curl -fsSL \""..buildlisturl.."\"")
    local json = json.decode(jsons)
    local artifactUrl = json["resource"]["downloadUrl"]
    local tmpDest = here.."/out.zip"
    system("curl -fsSL \""..artifactUrl.."\" > "..tmpDest)
    system("unzip -oj "..tmpDest.." "..path.." -d "..destinationFolder)
    system("mv "..renameMe.." "..destination)
    system("rm "..tmpDest)
end

function system(cmd)
    --print("system("..cmd..")")
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return trim(result)
end

function readfile(path)
    local f = io.open(path, "r")
    if f == nil then
        return ""
    end
    local s = f:read("*a")
    f:close()
    return s
end

function writefile(path, content)
    local f = io.open(path, "w")
    f:write(content)
    f:close()
end

function file_exists(path)
    local f=io.open(path,"r")
    if f~=nil then 
        io.close(f)
        return true
    else 
        return false
    end
end

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function all(t, f)
    for k, v in ipairs(t) do
        if f(v) == false then
            return false
        end
    end
    return true
end

--------------------------------------------------------------
--------------------------------------------------------------

if arg[2] == "create-lock" then
    createLock()
elseif arg[2] == "fetch" then
    local ver = arg[3]
    fetch(ver)
end
