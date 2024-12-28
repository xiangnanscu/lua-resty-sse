local sse = require('./lib/resty/sse')

local function my_cleanup()
  -- need config lua_check_client_abort on;
  ngx.log(ngx.NOTICE, "onabort exit 499")
  ngx.exit(499)
end

local ok, err0 = ngx.on_abort(my_cleanup)
if not ok then
  ngx.log(ngx.ERR, "failed to register the on_abort callback: ", err0)
end

local conn, err = sse.new()
if not conn then
  ngx.log(ngx.ERR, "failed to get connection: ", err)
  return
end
--conn:set_timeout(50000)
local path = 'http://127.0.0.1:8080/events/123'

local res, err2, is_sse_resp = conn:request_uri(path, {
  -- headers = req_headers,
  ssl_verify = false
})
if not res then
  ngx.log(ngx.ERR, "failed to request: ", err2)
  return
end

conn:transfer_encoding_is_chunked() --process Transfer-Encoding:chunked
for k, v in pairs(res.headers) do
  ngx.header[k] = v
end

while is_sse_resp
do
  local event, err3 = conn:receive()
  if err3 then
    ngx.log(ngx.ERR, "sse request over" .. err3)
    return ngx.exit(ngx.HTTP_OK)
  end
  if event then
    ngx.log(ngx.NOTICE, "sse received success, event=" .. event)
    ngx.print(event)
    ngx.flush() -- must flush
  end
end
ngx.say(res.body)
return ngx.exit(ngx.status)
