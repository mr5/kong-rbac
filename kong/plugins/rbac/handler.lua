local responses = require "kong.tools.responses"
local public_tools = require "kong.tools.public"
local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.rbac.access"

local ngx_get_headers = ngx.req.get_headers
local set_uri_args = ngx.req.set_uri_args
local get_uri_args = ngx.req.get_uri_args
local clear_header = ngx.req.clear_header
local ngx_req_read_body = ngx.req.read_body
local ngx_req_set_body_data = ngx.req.set_body_data
local ngx_encode_args = ngx.encode_args
local get_method = ngx.req.get_method
local type = type

local _realm = 'Key realm="RBAC"'

local RBACAuthHandler = BasePlugin:extend()

RBACAuthHandler.PRIORITY = 1003
RBACAuthHandler.VERSION = "0.1.0"

function RBACAuthHandler:new()
  RBACAuthHandler.super.new(self, "rbac")
end

local function do_authentication(conf)
  if type(conf.key_names) ~= "table" then
    return false, {status = 500, message = "Invalid plugin configuration"}
  end

  local ok, err = access.ignoreAeecss()
  if ok then
    return ok
  end

  local key
  local headers = ngx_get_headers()
  local uri_args = get_uri_args()
  local body_data

  -- read in the body if we want to examine POST args
  if conf.key_in_body then
    ngx_req_read_body()
    body_data = public_tools.get_body_args()
  end

  -- search in headers & querystring
  for i = 1, #conf.key_names do
    local name = conf.key_names[i]
    local v
    if conf.key_in_header then
      v = headers[name]
    end
    if not v and conf.key_in_query then
      -- search in querystring
      v = uri_args[name]
    end

    -- search the body, if we asked to
    if not v and conf.key_in_body then
      v = body_data[name]
    end

    if type(v) == "string" then
      key = v
      if conf.hide_credentials then
        uri_args[name] = nil
        set_uri_args(uri_args)
        clear_header(name)

        if conf.key_in_body then
          body_data[name] = nil
          ngx_req_set_body_data(ngx_encode_args(body_data))
        end
      end
      break
    elseif type(v) == "table" then
      -- duplicate API key, HTTP 401
      return false, {status = 401, message = "Duplicate API key found"}
    end
  end

  -- this request is missing an API key, HTTP 401
  if not key then
    ngx.header["WWW-Authenticate"] = _realm
    return false, {status = 401, message = "No API key found in request"}
  end

  return access.execute(key, conf)
end

function RBACAuthHandler:access(conf)
  RBACAuthHandler.super.access(self)

  -- check if preflight request and whether it should be authenticated
  if not conf.run_on_preflight and get_method() == "OPTIONS" then
    return
  end

  if ngx.ctx.authenticated_credential and conf.anonymous ~= "" then
    -- we're already authenticated, and we're configured for using anonymous,
    -- hence we're in a logical OR between auth methods and we're already done.
    return
  end

  local ok, err = do_authentication(conf)
  if not ok then
      return responses.send(err.status, err.message)
  end
end

return RBACAuthHandler
