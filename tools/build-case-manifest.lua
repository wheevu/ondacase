-- Builds src/case_manifest.lua from cases/001-americano/case.json.
-- Run with `make manifest`. Output must stay deterministic: every table is
-- emitted by iterating the manifest arrays in file order.
package.path = package.path .. ";./vendor/share/lua/5.5/?.lua"
local json = require("dkjson")

local function read_json(path)
  local file = assert(io.open(path, "r"))
  local raw = assert(file:read("*a"))
  file:close()
  local data = assert(json.decode(raw))
  return data
end

local function q(value)
  return string.format("%q", value)
end

local function emit_strings(out, list)
  for index, value in ipairs(list or {}) do
    if index > 1 then table.insert(out, ", ") end
    table.insert(out, q(value))
  end
end

local function emit_timeline(out, timeline)
  table.insert(out, "  timeline = {\n")
  for _, row in ipairs(timeline) do
    table.insert(out, "    {time=" .. q(row.time) .. ", event=" .. q(row.event)
      .. ", status=" .. q(row.status) .. ", requires={")
    emit_strings(out, row.requires)
    table.insert(out, "}},\n")
  end
  table.insert(out, "  },\n")
end

local function emit_locations(out, locations)
  table.insert(out, "  locations = {\n")
  for _, location in ipairs(locations) do
    table.insert(out, "    {id=" .. q(location.id) .. ", name=" .. q(location.name)
      .. ", note=" .. q(location.note) .. ", evidence={\n")
    for _, route in ipairs(location.evidence) do
      table.insert(out, "      {id=" .. q(route.id) .. ", label=" .. q(route.label) .. "},\n")
    end
    table.insert(out, "    }},\n")
  end
  table.insert(out, "  },\n")
end

local function emit_people(out, people)
  table.insert(out, "  people = {\n")
  for _, person in ipairs(people) do
    table.insert(out, "    {id=" .. q(person.id) .. ", name=" .. q(person.name)
      .. ", role=" .. q(person.role) .. "},\n")
  end
  table.insert(out, "  },\n")
end

local function emit_statements(out, statements)
  table.insert(out, "  statements = {")
  local ids = {}
  for _, statement in ipairs(statements) do ids[#ids + 1] = statement.id end
  emit_strings(out, ids)
  table.insert(out, "},\n")
end

local manifest = read_json("cases/001-americano/case.json")
local out = {
  "-- generated from cases/001-americano/case.json by tools/build-case-manifest.lua; do not edit\n",
  "return {\n",
}
emit_timeline(out, manifest.timeline)
emit_locations(out, manifest.locations)
emit_people(out, manifest.people)
emit_statements(out, manifest.statements)
table.insert(out, "}\n")

local target = assert(io.open("src/case_manifest.lua", "w"))
target:write(table.concat(out))
target:close()
print("case_manifest=pass")
