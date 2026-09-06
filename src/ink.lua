local json = require("dkjson")
local encode_json
local function _1_(value)
  return json.encode(value)
end
encode_json = _1_
local shell_quote
local function _2_(value)
  return ("'" .. string.gsub(value, "'", "'\\''") .. "'")
end
shell_quote = _2_
local request
local function _3_(operation, payload)
  local body
  do
    local tmp_9_ = (payload or {})
    tmp_9_["operation"] = operation
    body = tmp_9_
  end
  local encoded = encode_json(body)
  local command = ("printf '%s\\n' " .. shell_quote(encoded) .. " | node tools/ink-host.mjs")
  local pipe = io.popen(command, "r")
  local line = (pipe and pipe:read("*l"))
  local result = (line and json.decode(line))
  if pipe then
    pipe:close()
  else
  end
  return (result or {error = "Ink runtime unavailable", ok = false})
end
request = _3_
local module = {request = request}
_G["ondacase_ink"] = module
return module
