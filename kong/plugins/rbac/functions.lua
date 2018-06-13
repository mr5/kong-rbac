local responses = require "kong.tools.responses"
local singletons = require "kong.singletons"
local _ = require "lodash"

local function load_consumer_resources(consumer_id)
  local cache = singletons.cache
  local dao = singletons.dao
  local role_cache_key = dao.rbac_role_consumers:cache_key(consumer_id)
  local roles, err = cache:get(role_cache_key, nil, (function(id)
    return dao.rbac_role_consumers:find_all({ consumer_id = id })
  end), consumer_id)
  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end
  if table.getn(roles) < 1 then
    return {}
  end
  local resources = {}
  _.forEach(roles, (function(role)
    local role_resource_cache_key = dao.rbac_role_resources:cache_key(role.role_id)
    local role_resources, role_resource_err = cache:get(role_resource_cache_key, nil, (function(role_id)
      return dao.rbac_role_resources:find_all({ role_id = role_id })
    end), role.role_id)
    if role_resource_err then
      return responses.send_HTTP_INTERNAL_SERVER_ERROR(role_resource_err)
    end
    resources = _.union(resources, role_resources)
  end))
  return resources
end

return {
  load_consumer_resources = load_consumer_resources
}
