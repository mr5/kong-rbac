package = "kong-plugin-rbac"
version = "1.0.0-0"
local pluginName = package:match("^kong%-plugin%-(.+)$")  -- "kong-plugin-rbac"

supported_platforms = {"linux", "macosx"}
source = {
  url = "git://github.com/hhy5861/kong-rbac",
  tag = "1.0.0"
}

description = {
  summary = "Kong-rbac is a rbac plugin for in Kong",
  homepage = "https://github.com/hhy5861/kong-rbac",
  license = "MIT"
}

dependencies = {
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".migrations.cassandra"] = "kong/plugins/"..pluginName.."/migrations/cassandra.lua",
    ["kong.plugins."..pluginName..".migrations.postgres"] = "kong/plugins/"..pluginName.."/migrations/postgres.lua",
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    ["kong.plugins."..pluginName..".router"] = "kong/plugins/"..pluginName.."/router.lua",
    ["kong.plugins."..pluginName..".access"] = "kong/plugins/"..pluginName.."/access.lua",
    ["kong.plugins."..pluginName..".api"] = "kong/plugins/"..pluginName.."/api.lua",
    ["kong.plugins."..pluginName..".daos"] = "kong/plugins/"..pluginName.."/daos.lua",
  }
}
