package = "kong-plugin-rbac"  -- TODO: rename, must match the info in the filename of this rockspec!
                              -- as a convention; stick to the prefix: `kong-plugin-`
version = "1.0.0-1"           -- TODO: renumber, must match the info in the filename of this rockspec!
-- The version '1.0.0' is the source code version, the trailing '1' is the version of this rockspec.
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.

-- TODO: This is the name to set in the Kong configuration `custom_plugins` setting.
-- Here we extract it from the package name.
local pluginName = package:match("^kong%-plugin%-(.+)$")  -- "kong-plugin-rbac"

supported_platforms = {"linux", "macosx"}
source = {
  -- these are initially not required to make it work
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
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
  }
}
