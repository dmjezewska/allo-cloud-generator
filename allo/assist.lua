local here = arg[1]
local g_here = here
local g_branchname = "main"
local g_platform = None

package.path = package.path .. ';'..here..'/?.lua;'..here..'/deps/alloui/lib/pl/lua/?.lua'
local json = require "json"
local tablex = require"pl.tablex"


local g_platform_file_map = {
    ["linux-x64"] =   { file = "liballonet.so" },
    ["windows-x64"] = { file = "allonet.dll" },
    ["mac-universal"] = { file = "liballonet.dylib" }
}

--------------------------------------------------------------

local s3_root = "http://alloverse-downloads-prod.s3-eu-north-1.amazonaws.com/allonet" --alloverse-downloads-prod/allonet/"

--- Check lock file and download binaries for that version
-- If lockfile is empty do upgrade
function fetch(version)
    version = version or get_locked_version()
    if not version then 
        return print("Could not determine version to fetch")
    end

    print("Downloading Allonet " .. version)

    local file = g_platform_file_map[g_platform].file
    download(s3_root .. "/" .. version .. "/" .. g_platform .. "/" .. file, g_here .. "/lib/" .. file)
    save_current_version(version)
    save_locked_version(version)
end

--- Download the latest meta. If versions differ then save version to lock file, fetch the version
function upgrade()
    local latest_version = get_latest_version()
    
    if not latest_version then
        return print("Failed to read latest version.")
    end

    local current_version = get_current_version()

    if not current_version or (current_version ~= latest_version) then
        print("Found new version.")
        fetch(latest_version)
        return
    end

    print("You are already on the latest version (" .. latest_version .. ")")
end

function download(url, dest)
    system("curl -fsSL \"" .. url .. "\" > " .. dest)
end

-------------------------------------------------------------------

local g_lockfile = here .. "/allonet.lock"
function save_locked_version(version)
    writefile(g_lockfile, version)
end

function get_locked_version()
    return trim(readfile(g_lockfile))
end

local g_cachefilepath = here .. "/lib/allonet.cache"
function get_current_version()
    return trim(readfile(g_cachefilepath))
end

function save_current_version(version)
    writefile(g_cachefilepath, version)
end

--- Returns the meta json for the latest available build
-- {
--     "version": "${VERSION}",
--     "platform": "${PLATFORM}",
--     "branch": "${BUILD_SOURCEBRANCHNAME}",
--     "buildid": "${BUILD_BUILDID}",
--     "buildnumber": "${BUILD_BUILDNUMBER}",
--     "githash": "${BUILD_SOURCEVERSION}",
--     "changemsg": "${BUILD_SOURCEVERSIONMESSAGE}"
-- }
function get_latest_json(branch)
    local path = "latest_" .. (branch or g_branchname) .. "_" .. g_platform .. ".json"
    local url = s3_root .. "/" .. path
    local jsons = system("curl -fsSL \"" .. url .. "\"")
    local json = json.decode(jsons)
    return json
end

function get_latest_version(branch)
    local latest = get_latest_json(branch)
    if latest then 
        return latest["version"]
    end
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

function get_current_platform()
    local uname = system("uname -s")
    if uname == "Darwin" then
        return "mac-universal"
    elseif uname == "Linux" then
        return "linux-x64"
    elseif uname == "CYGWIN" or uname == "MINGW" then
        return "windows-x64"
    else
        return None
    end
end

function isversionstring(str)
    return str:match("%d+%.%d+%.%d+%.g[a-z0-9]+") ~= nil
end

--------------------------------------------------------------
--------------------------------------------------------------

g_platform = get_current_platform()
if not g_platform then
    print("Could not determine your platform. Please reach out to us via email or our Discord. Details on alloverse.com")
    return
end

print("Current platform: " .. g_platform)

if arg[2] == "fetch" then
    fetch()
elseif arg[2] == "upgrade" then
    local version_or_branch = arg[3]
    if version_or_branch and version_or_branch ~= "" then
        if isversionstring(version_or_branch) then
            print("Requested version " .. version_or_branch)
            fetch(version_or_branch)
        else
            print("Requested branch " .. version_or_branch)
            fetch(get_latest_version(version_or_branch))
        end
    else 
        upgrade()
    end
end
