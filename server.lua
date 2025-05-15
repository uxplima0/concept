local http = require("coro-http")
local json = require("json")
local url = require("url")
local server = require("coro-net").createServer

local PORT = 8080
local AUTH_KEY = "c4294bd5-df1f-4fd5-8241-1dc7cd8f8c5f"

local function log(msg)
  print("📨 " .. msg)
end

server("0.0.0.0", PORT, function(read, write)
  local req = {}
  req.method, req.path, req.version, req.headers, req.body = http.readRequest(read)

  if req.method == "POST" and req.path == "/ServicesMessage" then
    local success, bodyData = pcall(json.decode, req.body)
    if not success or not bodyData or bodyData.key ~= AUTH_KEY then
      http.writeResponse(write, 403, {
        ["Content-Type"] = "application/json"
      }, json.encode({ error = "Invalid or missing key." }))
      return
    end

    log("Message sent to channel " .. bodyData.channelId)
    log(json.stringify(bodyData.message, 2))

    http.writeResponse(write, 200, {
      ["Content-Type"] = "application/json"
    }, json.encode({ status = "Message received and accepted." }))

  elseif req.method == "GET" and req.path:match("^/trello%-perms") then
    local parsedUrl = url.parse(req.path, true)
    local query = parsedUrl.query or {}

    if query["key"] ~= AUTH_KEY then
      http.writeResponse(write, 401, {
        ["Content-Type"] = "application/json"
      }, json.encode({ error = "Invalid key" }))
      return
    end

    local perms = {
      IsGCPS = { "716314370" },
      GCPSFirearm = { "716314370" },
      GCPSZipcuffs = { "716314370" },
      GCPSElevatedFirearm = { "716314370" },
      IsINSE = { "716314370" }
    }

    http.writeResponse(write, 200, {
      ["Content-Type"] = "application/json"
    }, json.encode(perms))

  else
    http.writeResponse(write, 404, {
      ["Content-Type"] = "application/json"
    }, json.encode({ error = "Not found." }))
  end
end)

print("✅ GCPS API running at http://localhost:" .. PORT)
