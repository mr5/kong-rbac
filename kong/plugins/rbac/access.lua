local responses = require "kong.tools.responses"
local constants = require "kong.constants"
local singletons = require "kong.singletons"
local router = require "kong.plugins.rbac.router"

local routers = router.new()
local ignore_router = router.new()
local ngx_set_header = ngx.req.set_header

local _realm = 'Key realm="RBAC"'

local _M = {}

local function set_consumer(consumer, credential)
  ngx_set_header(constants.HEADERS.CONSUMER_ID, consumer.id)
  ngx_set_header(constants.HEADERS.CONSUMER_CUSTOM_ID, consumer.custom_id)
  ngx_set_header(constants.HEADERS.CONSUMER_USERNAME, consumer.username)
  ngx.ctx.authenticated_consumer = consumer
  if credential then
    ngx_set_header(constants.HEADERS.CREDENTIAL_USERNAME, credential.username)
    ngx.ctx.authenticated_credential = credential
    ngx_set_header(constants.HEADERS.ANONYMOUS, nil) -- in case of auth plugins concatenation
  else
    ngx_set_header(constants.HEADERS.ANONYMOUS, true)
  end
end

local function load_credential(key)
  local creds, err = singletons.dao.rbac_credentials:find_all {
    key = key
  }
  
  if not creds then
    return nil, err
  end
  return creds[1]
end

local function load_consumer(consumer_id, anonymous)
  local result, err = singletons.dao.consumers:find {id = consumer_id}
  if not result then
    if anonymous and not err then
      err = 'anonymous consumer "' .. consumer_id .. '" not found'
    end
    return nil, err
  end
  return result
end

local function load_role_consumer(consumer_id)
  local result, err = singletons.dao.rbac_role_consumers:find_all {
    consumer_id = consumer_id
  }

  if not result then
    return nil, err
  end

  local role_ids = {}
  for k, v in ipairs(result) do
    table.insert(role_ids, v.role_id)
  end

  return role_ids
end

local function load_roles_resources(role_id)
  local result, err = singletons.dao.rbac_role_resources:find_all {
    role_id = role_id
  }

  if not result then
    return nil, err
  end

  local resources_ids = {}
  for k, v in ipairs(result) do
    table.insert(resources_ids, v.resource_id)
  end

  return resources_ids
end

local function load_resources(resources_id)
  local result, err = singletons.dao.rbac_resources:find_all {
    id = resources_id
  }

  if not result then
    return nil, err
  end

  return result
end

local function update_key_expired(credential, expired)
  if not expired then
    expired = 1800
  end
  credential.expired_at = (os.time() * 1000) + (expired * 1000)
  singletons.dao.rbac_credentials:update(credential, credential, {full = true})
end

local function load_public_resource(visibility)
  local result, err = singletons.dao.rbac_resources:find_all {
    visibility = visibility
  }

  if err or not result then
    return nil, err
  end

  return result
end

local function anonymous (anonymous)
  local consumer_cache_key = singletons.dao.consumers:cache_key(anonymous)
  return singletons.cache:get(consumer_cache_key, nil, load_consumer, anonymous, true)
end

function _M.execute(key, conf)
  local cache = singletons.cache
  local dao = singletons.dao

  local credential_cache_key = dao.rbac_credentials:cache_key(key)
  local credential, err = cache:get(credential_cache_key, nil, load_credential, key)
  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  -- no credential in DB, for this key, it is invalid, HTTP 401
  if not credential then
    return false, {status = 401, message = "Invalid authentication credentials"}
  end

  -- check anonymous 
  if conf.anonymous ~= "" then
    if conf.anonymous == credential.consumer_id then
      local consumer, err = anonymous(conf.anonymous)
      if err or next(consumer) == nil then
        return false, {status = 403, message = "Invalid anonymous"}
      end

      set_consumer(consumer, nil)
      return true
    end
  end

  -- credential expired.
  if credential.expired_at and credential.expired_at <= (os.time() * 1000) then
    return false, {status = 401, message = "Invalid Expired certificate"}
  end

  -----------------------------------------
  -- Success, this request is authenticated
  -----------------------------------------

  -- retrieve the consumer linked to this API key, to set appropriate headers

  -- get role id by consumer id
  local role_consumer_key = dao.rbac_role_consumers:cache_key(credential.consumer_id)
  local role_consumer, err = cache:get(role_consumer_key, nil, load_role_consumer, credential.consumer_id)
  if err then
    return false, {status = 403, message = "Forbidden"}
  end
  
  -- local params = ngx.req.get_uri_args()
  for i, v in ipairs(role_consumer) do
    local role_resources_key = dao.rbac_role_resources:cache_key(v)
    local role_resources, err = cache:get(role_resources_key, nil, load_roles_resources, v)
    if err == nil and next(role_resources) ~= nil then
      for k, val in ipairs(role_resources) do
        local resources_key = dao.rbac_resources:cache_key(val)
        local resources, err = cache:get(resources_key, nil, load_resources, val)
        if err == nil and next(resources) ~= nil then
          for key, value in ipairs(resources) do
            routers:match(value.method, value.upstream_path, function(params)
              return params
            end)
          end
        end
      end
    end
  end

  local ok, errmsg = routers:execute(
        ngx.var.request_method,
        ngx.var.uri,
        ngx.req.get_uri_args(),
        ngx.req.read_body())

  if not ok then
    return false, {status = 403, message = "Forbidden"}
  end

  local consumer_cache_key = dao.consumers:cache_key(credential.consumer_id)
  local consumer, err = cache:get(consumer_cache_key, nil, load_consumer, credential.consumer_id)
  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  set_consumer(consumer, credential)
  update_key_expired(credential, conf.key_expired)
  return true
end

function _M.ignoreAeecss()
  local visibility = "public"
  local resource_key = singletons.dao.rbac_resources:cache_key(visibility)
  local resource, err = singletons.cache:get(resource_key, nil, load_public_resource, visibility)
  if not err and next(resource) ~= nil then
    for k, v in ipairs(resource) do
      ignore_router:match(v.method, v.upstream_path, function(params)
        return params
      end)
    end

    local ok, errmsg = ignore_router:execute(
      ngx.var.request_method,
      ngx.var.uri,
      ngx.req.get_uri_args(),
      ngx.req.read_body())

    if ok then
      return true
    end

    return false, errmsg
  end
end

return _M