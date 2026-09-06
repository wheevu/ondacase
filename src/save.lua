local json = require("dkjson")
local utf8 = require("utf8")
local SAVE_VERSION = 2
local SUPPORTED_VERSIONS = {[2] = true}
local MAX_PAYLOAD = 200000
local MAX_OUTER = 250000
local valid_screens = {title = true, case_select = true, investigate = true, location = true, people = true, dialogue = true, evidence = true, evidence_detail = true, timeline = true, contradiction = true, proof = true, board = true, theory = true, accuse = true, ending = true, pause = true, settings = true, load_record = true}
local valid_suspects = {mira = true, arin = true, jo = true, sasha = true, dan = true}
local valid_locations = {cafe = true, alley = true, store = true, apartment = true}
local valid_evidence = {receipt_004 = true, camera_log = true, toxicology = true, pharmacy_footage = true, cup_lid = true, tape_fiber = true, draft_email = true, service_log = true, mira_statement = true, delivery_photo = true, sasha_voicemail = true, panel_log = true, jo_statement = true}
local valid_statements = {mira_left_1910 = true, arin_cough_drops = true, jo_saw_cup_1921 = true, jo_identified_mira = true, sasha_never_argued = true, dan_never_inside = true, dan_route_recollection = true}
local valid_endings = {conviction = true, lucky_idiot = true, beautiful_theory = true, insufficient_evidence = true, detective = true, everybody_goes_home = true}
local function clean_set(value, allowed)
  local out = {}
  if (type(value) == "table") then
    for k, v in pairs(value) do
      if ((v == true) and allowed[k]) then
        out[k] = true
      else
      end
    end
  else
  end
  return out
end
local function clean_flags(value)
  local out = {}
  if (type(value) == "table") then
    for k, v in pairs(value) do
      if ((type(k) == "string") and (type(v) == "boolean")) then
        out[k] = v
      else
      end
    end
  else
  end
  return out
end
local function clean_accusation(value, allowed)
  local source
  if (type(value) == "table") then
    source = value
  else
    source = {}
  end
  local suspect
  if valid_suspects[source.suspect] then
    suspect = source.suspect
  else
    suspect = "arin"
  end
  local selected = clean_set(source.evidence, (allowed or valid_evidence))
  return {suspect = suspect, motive = clean_set(source.motive, selected), method = clean_set(source.method, selected), opportunity = clean_set(source.opportunity, selected), evidence = selected}
end
local function clean_ink_state(v)
  if ((type(v) == "string") and (#v <= 20000) and utf8.len(v)) then
    return v
  else
    return nil
  end
end
local function clean_timeline_page(v)
  if ((type(v) == "number") and (v >= 1) and (v <= 100)) then
    return math.floor(v)
  else
    return 1
  end
end
local function clean_string_list(value)
  local out = {}
  if (type(value) == "table") then
    for _, item in ipairs(value) do
      if ((#out < 200) and (type(item) == "string") and (#item <= 500) and utf8.len(item)) then
        table.insert(out, item)
      else
      end
    end
  else
  end
  return out
end
local valid_dimension_status = {supported = true, partial = true, missing = true, unsupported = true, contradicted = true}
local valid_gap_codes = {unsupported_dimension = true, unsupported_premise = true, required_evidence_missing = true, contradiction_ignored = true}
local function clean_report_evidence(value, allowed)
  local out = {}
  local seen = {}
  if (type(value) == "table") then
    for _, item in ipairs(value) do
      local id
      if (type(item) == "string") then
        id = item
      elseif (type(item) == "table") then
        id = item.id
      else
        id = nil
      end
      if (id and allowed[id] and not seen[id] and (#out < 20)) then
        seen[id] = true
        table.insert(out, {id = id})
      else
      end
    end
  else
  end
  return out
end
local function clean_report_gaps(value)
  local out = {}
  if (type(value) == "table") then
    for _, item in ipairs(value) do
      if ((type(item) == "table") and (#out < 50)) then
        local gap = {}
        local code
        if ((type(item.code) == "string") and valid_gap_codes[item.code]) then
          code = item.code
        else
          code = nil
        end
        local dimension
        if ((type(item.dimension) == "string") and ({motive = true, method = true, opportunity = true})[item.dimension]) then
          dimension = item.dimension
        else
          dimension = nil
        end
        if code then
          gap["code"] = code
        else
        end
        if dimension then
          gap["dimension"] = dimension
        else
        end
        table.insert(out, gap)
      else
      end
    end
  else
  end
  return out
end
local function clean_ending_report(value, allowed)
  if ((type(value) == "table") and (type(value.unique_solution) == "boolean")) then
    local out = {unique_solution = value.unique_solution, selected_evidence = clean_report_evidence(value.selected_evidence, allowed), unsupported = clean_report_gaps(value.unsupported)}
    for _, field in ipairs({"motive", "method", "opportunity"}) do
      local status = value[field]
      if ((type(status) == "string") and valid_dimension_status[status]) then
        out[field] = status
      else
      end
    end
    return out
  else
    return nil
  end
end
local function clean_theory(value, allowed)
  local src
  if (type(value) == "table") then
    src = value
  else
    src = {}
  end
  local sus
  if valid_suspects[src.suspect] then
    sus = src.suspect
  else
    sus = "arin"
  end
  local mode
  if (src.mode == "motive") then
    mode = "motive"
  elseif (src.mode == "method") then
    mode = "method"
  elseif (src.mode == "opportunity") then
    mode = "opportunity"
  else
    mode = "evidence"
  end
  return {suspect = sus, motive = clean_set(src.motive, (allowed or valid_evidence)), method = clean_set(src.method, (allowed or valid_evidence)), opportunity = clean_set(src.opportunity, (allowed or valid_evidence)), evidence = clean_set(src.evidence, (allowed or valid_evidence)), mode = mode}
end
local function sanitize_theory_after_parse(theory, evidence_set)
  local base = clean_theory(theory, evidence_set)
  local ev = (base.evidence or {})
  for k, _ in pairs(ev) do
    if not evidence_set[k] then
      ev[k] = nil
    else
    end
  end
  for k, _ in pairs(base.motive) do
    if (not evidence_set[k] or not ev[k]) then
      base.motive[k] = nil
    else
    end
  end
  for k, _ in pairs(base.method) do
    if (not evidence_set[k] or not ev[k]) then
      base.method[k] = nil
    else
    end
  end
  for k, _ in pairs(base.opportunity) do
    if (not evidence_set[k] or not ev[k]) then
      base.opportunity[k] = nil
    else
    end
  end
  return base
end
local function checksum(s)
  local h = 2166136261
  for i = 1, #s do
    h = (((h * 31) + string.byte(s, i)) % 4294967296)
  end
  return string.format("%08x", h)
end
local function json_object_3f(value)
  local and_29_ = (type(value) == "table")
  if and_29_ then
    local meta = getmetatable(value)
    and_29_ = not (meta and (meta.__jsontype == "array"))
  end
  return and_29_
end
local function validate(data)
  if not json_object_3f(data) then
    return nil, 'not an object'
  else
  end
  if (data.version and not SUPPORTED_VERSIONS[data.version]) then
    return nil, 'unsupported version'
  else
  end
  return true
end
local function serialize(state)
  local clean_ev = clean_set(state.evidence, valid_evidence)
  local inner
  local _33_
  if clean_ev[state.evidence_detail] then
    _33_ = state.evidence_detail
  else
    _33_ = nil
  end
  inner = {screen = state.screen, evidence = clean_ev, clues = state.clues, accused = state.accused, accusation = clean_accusation(state.accusation, clean_ev), location = state.location, settings = state.settings, ink_state = clean_ink_state(state.ink_state), dialogue_page = state.dialogue_page, timeline_page = state.timeline_page, ending = state.ending, ending_report = clean_ending_report(state.ending_report, clean_ev), current_person = state.current_person, inspected_objects = clean_set(state.inspected_objects, clean_ev), visited_locations = clean_set(state.visited_locations, valid_locations), heard_statements = clean_set(state.heard_statements, valid_statements), conversation_branches = clean_string_list(state.conversation_branches), presented_evidence = clean_set(state.presented_evidence, clean_ev), evidence_page = state.evidence_page, evidence_detail = _33_, prev_screen = state.prev_screen, contradiction_seen = clean_flags(state.contradiction_seen), theory = clean_theory(state.theory, clean_ev)}
  local payload_str = json.encode(inner)
  if (#payload_str > MAX_PAYLOAD) then
    return nil, 'payload too large'
  else
  end
  local cs = checksum(payload_str)
  local outer = {version = SAVE_VERSION, payload = payload_str, checksum = cs}
  local outer_str = json.encode(outer)
  return outer_str
end
local function parse(raw)
  if (not raw or (raw == "")) then
    return nil, 'empty'
  else
  end
  if (#raw > MAX_OUTER) then
    return nil, 'too large'
  else
  end
  local ok, data = pcall(json.decode, raw)
  if not ok then
    return nil, 'json error'
  else
  end
  if not data then
    return nil, 'nil data'
  else
  end
  if not json_object_3f(data) then
    return nil, 'not an object'
  else
  end
  if (data.version ~= SAVE_VERSION) then
    return nil, 'bad version'
  else
  end
  if (type(data.payload) ~= "string") then
    return nil, 'bad payload'
  else
  end
  if (type(data.checksum) ~= "string") then
    return nil, 'bad checksum'
  else
  end
  if ((#data.payload > MAX_PAYLOAD) or (#data.checksum ~= 8)) then
    return nil, 'bad envelope'
  else
  end
  if (checksum(data.payload) ~= data.checksum) then
    return nil, 'checksum mismatch'
  else
  end
  local ok2, inner = pcall(json.decode, data.payload)
  if not ok2 then
    return nil, 'payload json error'
  else
  end
  if not inner then
    return nil, 'nil payload'
  else
  end
  if not json_object_3f(inner) then
    return nil, 'payload not an object'
  else
  end
  local data0 = inner
  local clean_ev = clean_set(data0.evidence, valid_evidence)
  local screen_ok = (data0.screen and valid_screens[data0.screen])
  local accused_ok = (data0.accused and valid_suspects[data0.accused])
  local report = clean_ending_report(data0.ending_report, clean_ev)
  local ending
  if (report and (type(data0.ending) == "string") and valid_endings[data0.ending]) then
    ending = data0.ending
  else
    ending = nil
  end
  local out
  local _50_
  if screen_ok then
    _50_ = data0.screen
  else
    _50_ = "title"
  end
  local _52_
  if accused_ok then
    _52_ = data0.accused
  else
    _52_ = "arin"
  end
  local _54_
  if valid_locations[data0.location] then
    _54_ = data0.location
  else
    _54_ = "cafe"
  end
  local _56_
  do
    local v = data0.dialogue_page
    if ((type(v) == "number") and (v >= 1) and (v <= 100)) then
      _56_ = math.floor(v)
    else
      _56_ = 1
    end
  end
  local _58_
  if valid_suspects[data0.current_person] then
    _58_ = data0.current_person
  else
    _58_ = "arin"
  end
  local _60_
  do
    local v = data0.evidence_page
    if ((type(v) == "number") and (v >= 1) and (v <= 100)) then
      _60_ = math.floor(v)
    else
      _60_ = 1
    end
  end
  local _62_
  if ((type(data0.evidence_detail) == "string") and clean_ev[data0.evidence_detail]) then
    _62_ = data0.evidence_detail
  else
    _62_ = nil
  end
  local _64_
  if (data0.prev_screen and valid_screens[data0.prev_screen]) then
    _64_ = data0.prev_screen
  else
    _64_ = nil
  end
  out = {screen = _50_, evidence = clean_ev, clues = (data0.clues or 0), accused = _52_, accusation = clean_accusation(data0.accusation, clean_ev), location = _54_, settings = {reducedMotion = false}, ink_state = clean_ink_state(data0.ink_state), ink_text = nil, ink_choices = {}, dialogue_page = _56_, timeline_page = clean_timeline_page(data0.timeline_page), ending = ending, ending_report = report, current_person = _58_, inspected_objects = clean_set(data0.inspected_objects, clean_ev), visited_locations = clean_set(data0.visited_locations, valid_locations), heard_statements = clean_set(data0.heard_statements, valid_statements), inferences = {}, contradictions = {}, inferred_facts = {}, conversation_branches = clean_string_list(data0.conversation_branches), hypotheses = {}, timeline_entries = {}, presented_evidence = clean_set(data0.presented_evidence, clean_ev), accusation_attempts = {}, major_flags = {}, alternatives = {}, proof_data = {}, evidence_page = _60_, evidence_detail = _62_, prev_screen = _64_, contradiction_seen = {}, theory = sanitize_theory_after_parse(data0.theory, clean_ev), active_proof = nil, contradiction = false, ink_can_continue = false}
  if ((type(data0.settings) == "table") and (data0.settings.reducedMotion == true)) then
    out.settings["reducedMotion"] = true
  else
  end
  if (out.evidence.mira_statement and (not out.evidence.receipt_004 or not out.heard_statements.mira_left_1910)) then
    out.evidence["mira_statement"] = nil
    out.accusation.evidence["mira_statement"] = nil
    out.accusation.motive["mira_statement"] = nil
    out.accusation.method["mira_statement"] = nil
    out.accusation.opportunity["mira_statement"] = nil
    out.inspected_objects["mira_statement"] = nil
    out.presented_evidence["mira_statement"] = nil
    out.theory.evidence["mira_statement"] = nil
    out.theory.motive["mira_statement"] = nil
    out.theory.method["mira_statement"] = nil
    out.theory.opportunity["mira_statement"] = nil
    if (out.evidence_detail == "mira_statement") then
      out["evidence_detail"] = nil
    else
    end
    if out.ending_report then
      out["ending_report"] = clean_ending_report(out.ending_report, out.evidence)
    else
    end
  else
  end
  if (out.evidence.receipt_004 and out.heard_statements.mira_left_1910 and (type(data0.contradiction_seen) == "table") and (data0.contradiction_seen.receipt_mira == true)) then
    out.contradiction_seen["receipt_mira"] = true
  else
  end
  if ((out.screen == "evidence_detail") and not out.evidence_detail) then
    out["screen"] = "evidence"
  else
  end
  if (out.screen == "proof") then
    out["screen"] = "evidence"
  else
  end
  if ((out.screen == "contradiction") and (not out.evidence.receipt_004 or not out.heard_statements.mira_left_1910)) then
    out["screen"] = "investigate"
  else
  end
  if not out.ending then
    out["ending_report"] = nil
  else
  end
  if ((out.screen == "ending") and (not out.ending or not out.ending_report)) then
    out["screen"] = "investigate"
  else
  end
  local c = 0
  for _, _0 in pairs(out.evidence) do
    c = (c + 1)
  end
  out["clues"] = c
  return out
end
return {serialize = serialize, parse = parse, validate = validate, ["SAVE-VERSION"] = SAVE_VERSION}
