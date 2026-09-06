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
local function copy_payload(payload)
  local out = {}
  for k, v in pairs((payload or {})) do
    if ((k ~= "known_evidence") and (k ~= "known_statements")) then
      out[k] = v
    else
    end
  end
  return out
end
local function line_for(operation, payload)
  local function _4_()
    local tmp_9_ = copy_payload(payload)
    tmp_9_["operation"] = operation
    return tmp_9_
  end
  return json.encode(_4_())
end
local function request(operation, payload)
  local payload0 = (payload or {})
  local lines = {line_for("reset", {})}
  for _, statement in ipairs((payload0.known_statements or {})) do
    table.insert(lines, line_for("record_statement", {statement = statement}))
  end
  for _, evidence in ipairs((payload0.known_evidence or {})) do
    table.insert(lines, line_for("discover_evidence", {evidence = evidence}))
  end
  table.insert(lines, line_for(operation, payload0))
  local input = (table.concat(lines, "\n") .. "\n")
  local command = ("printf '%s' " .. shell_quote(input) .. " | swipl -q -s logic/server.pl")
  local pipe = io.popen(command, "r")
  local output = (pipe and pipe:read("*a"))
  if pipe then
    pipe:close()
  else
  end
  if output then
    local responses = {}
    for line in string.gmatch(output, "[^\r\n]+") do
      local decoded = json.decode(line)
      table.insert(responses, decoded)
    end
    return (responses[#responses] or {error = "logic engine returned no response", ok = false})
  else
    return {error = "logic engine unavailable", ok = false}
  end
end
local module = {request = request}
_G["ondacase_prolog"] = module
return module
