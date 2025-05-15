local http = require("coro-http")
local json = require("json")
local app = require("http-codec").server

local key = "c4294bd5-df1f-4fd5-8241-1dc7cd8f8c5f" -- shared key for verification

-- Main request handler
local function handleRequest(req, body)
  local method = req.method
  local path = req.path

  if method == "POST" and path == "/ServicesMessage" then
    local success, payload = pcall(function()
      return json.parse(body)
    end)

    if not success or not payload then
      return {
        code = 400,
        headers = { ["Content-Type"] = "application/json" },
        body = json.stringify({ message = "Invalid JSON body", status = "error" })
      }
    end

    if payload.key ~= key then
      return {
        code = 403,
        headers = { ["Content-Type"] = "application/json" },
        body = json.stringify({ message = "Unauthorized", status = "forbidden" })
      }
    end

    print("[ServiceMessage] Forwarded to Discord channel:", payload.channelId)
    print(json.stringify(payload.message, true))

    return {
      code = 200,
      headers = { ["Content-Type"] = "application/json" },
      body = json.stringify({ message = "Message forwarded", status = "ok" })
    }
  end

  return {
    code = 404,
    headers = { ["Content-Type"] = "application/json" },
    body = json.stringify({ message = "Not found", status = "error" })
  }
end

require("coro-net").createServer("0.0.0.0", 8080, function(raw)
  local req, body = app.decode(raw:read())
  local res = handleRequest(req, body or "")
  raw:write(app.encodeHead(res.code, res.headers))
  raw:write(res.body)
end)

print("✅ GCPS API running at http://localhost:8080")