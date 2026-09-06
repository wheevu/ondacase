local layout = require("src.layout")
local save_mod = require("src.save")
local prolog = require("src.prolog")
local ink = require("src.ink")
local spaces = require("src.spaces")
local case_manifest = require("src.case_manifest")
local palette = {ink = {0.89, 0.87, 0.79}, paper = {0.075, 0.085, 0.085}, panel = {0.12, 0.14, 0.145}, ["panel-warm"] = {0.16, 0.15, 0.12}, ["panel-cool"] = {0.13, 0.17, 0.18}, line = {0.36, 0.4, 0.4}, ["line-warm"] = {0.46, 0.43, 0.33}, rust = {0.76, 0.48, 0.35}, gold = {0.73, 0.63, 0.43}, muted = {0.61, 0.65, 0.64}, green = {0.51, 0.69, 0.57}, red = {0.76, 0.48, 0.35}, dust = {0.6, 0.65, 0.68}, ["paper-light"] = {0.1, 0.12, 0.12}}
local W = layout.W
local H = layout.H
local scale_state = {scale = 1, ox = 0, oy = 0}
local fonts = {}
local art = {}
local buttons = {}
local focus_index = 1
local focusable = {}
local hover_index = nil
local mouse_lx = -1
local mouse_ly = -1
local capture_name = os.getenv("ONDACASE_CAPTURE")
local capture_path = os.getenv("ONDACASE_CAPTURE_PATH")
local capture_done = false
local capture_requested = false
local evidence_data = {{id = "receipt_004", title = "RECEIPT 004", sub = "Iced americano / 19:22", body = "In-person purchase. Paid with Mira's card.", tag = "PLACES MIRA", color = "gold", discovered = "Found at the caf\195\169 register.", implication = "Mira was present at 19:22.", status = "Confirmed purchase record."}, {id = "camera_log", title = "CAMERA LOG", sub = "Blind spot / 19:18-19:29", body = "West camera offline eleven minutes.", tag = "CREATES OPPORTUNITY", color = "rust", discovered = "Caf\195\169 security panel.", implication = "A gap covered the poisoning window.", status = "Confirmed system log."}, {id = "toxicology", title = "TOXICOLOGY", sub = "Aconite / 19:25-19:28", body = "Poison in drink, not food.", tag = "ESTABLISHES METHOD", color = "green", discovered = "Lab report at the caf\195\169.", implication = "The drink was the delivery method.", status = "Confirmed lab result."}, {id = "pharmacy_footage", title = "PHARMACY FOOTAGE", sub = "Arin / 19:04 / aconite", body = "Arin bought aconite tincture.", tag = "LINKS ARIN TO POISON", color = "rust", discovered = "Night-store counter camera.", implication = "Arin obtained the poison used.", status = "Confirmed footage."}, {id = "cup_lid", title = "CUP LID", sub = "Cleaned badly", body = "Wiped lid, residue under rim.", tag = "PHYSICAL CONTRADICTION", color = "green", discovered = "Evidence table at the caf\195\169.", implication = "The cup was wiped to hide residue.", status = "Confirmed physical exam."}, {id = "tape_fiber", title = "BLUE TAPE FIBER", sub = "Fiber beneath lid", body = "Matches tape on Arin's finger.", tag = "CONTACT", color = "green", discovered = "Lab analysis of the lid.", implication = "Points to Arin's contact with the lid.", status = "Confirmed fiber match."}, {id = "draft_email", title = "DRAFT EMAIL", sub = "Eli / scheduled", body = "Article on Arin's review fraud.", tag = "MOTIVE", color = "gold", discovered = "Eli's apartment desk.", implication = "Arin had a reason to stop publication.", status = "Confirmed draft."}, {id = "service_log", title = "SERVICE LOG", sub = "Tag exit 19:25", body = "Borrowed tag opens service door.", tag = "OPPORTUNITY", color = "gold", discovered = "Service alley reader.", implication = "Arin's exit overlaps the death window.", status = "Confirmed door log."}, {id = "mira_statement", title = "MIRA STATEMENT", sub = "Saw Arin at 19:23", body = "Mira saw Arin beside booth.", tag = "EXCLUSION", color = "gold", discovered = "Confront Mira after the receipt.", implication = "Mira's correction shifts suspicion from herself.", status = "Claimed follow-up."}, {id = "delivery_photo", title = "DELIVERY PHOTO", sub = "Dan / 19:19", body = "Photo + tracker exclude Dan.", tag = "EXCLUSION", color = "muted", discovered = "Alley and tracker review.", implication = "Dan was not inside at the critical time.", status = "Confirmed image and tracker."}, {id = "sasha_voicemail", title = "SASHA VOICEMAIL", sub = "Live call 19:20-19:27", body = "Covers death window.", tag = "EXCLUSION", color = "muted", discovered = "Eli's apartment phone.", implication = "Sasha was on a live call outside.", status = "Confirmed call log."}, {id = "panel_log", title = "PANEL LOG", sub = "Jo at till", body = "Till activity excludes Jo.", tag = "EXCLUSION", color = "muted", discovered = "Caf\195\169 till and panel log.", implication = "Jo stayed at the till through the window.", status = "Confirmed system log."}, {id = "jo_statement", title = "JO'S STATEMENT", sub = "Person with cup 19:21", body = "Incomplete account.", tag = "MISSING WITNESS", color = "gold", discovered = "Interview note at the caf\195\169.", implication = "A familiar person was seen with the cup.", status = "Claimed, incomplete."}}
local statement_ids = case_manifest.statements
local location_data
do
  local out = {}
  for _, loc in ipairs(case_manifest.locations) do
    local routes = {}
    for _0, route in ipairs(loc.evidence) do
      table.insert(routes, {route.id, route.label})
    end
    out[loc.id] = {name = loc.name, note = loc.note, evidence = routes}
  end
  location_data = out
end
local suspect_tones = {mira = {0.47, 0.35, 0.25}, arin = {0.35, 0.42, 0.48}, jo = {0.41, 0.3, 0.35}, sasha = {0.33, 0.43, 0.34}, dan = {0.45, 0.38, 0.3}}
local suspects
do
  local out = {}
  for _, person in ipairs(case_manifest.people) do
    table.insert(out, {id = person.id, name = string.upper(person.name), role = person.role, tone = (suspect_tones[person.id] or {0.4, 0.4, 0.4})})
  end
  suspects = out
end
local state = {screen = "title", evidence = {}, clues = 0, ending = nil, accused = "arin", accusation = {suspect = "arin", motive = {}, method = {}, opportunity = {}, evidence = {}}, accusation_mode = "evidence", location = "cafe", toast = nil, toast_time = 0, current_person = "arin", ink_text = nil, ink_choices = {}, settings = {reducedMotion = false}, ink_state = nil, contradictions = {}, inferences = {}, inferred_facts = {}, alternatives = {}, proof_data = {}, ending_report = nil, dialogue_page = 1, inspected_objects = {}, visited_locations = {cafe = true}, heard_statements = {}, conversation_branches = {}, hypotheses = {}, timeline_entries = {}, presented_evidence = {}, accusation_attempts = {}, major_flags = {}, focus = 1, evidence_page = 1, evidence_detail = nil, prev_screen = nil, contradiction_seen = {}, timeline_page = 1, theory = {suspect = "arin", motive = {}, method = {}, opportunity = {}, evidence = {}, mode = "evidence"}, theory_report_page = 1, active_proof = nil, contradiction = false, ink_can_continue = false, logic_online = false}
local ui = {shadow = 4, hair = 1}
local console = {paper = palette.paper, panel = palette.panel, edge = palette.line, ink = palette.ink, muted = palette.muted, sodium = palette.gold}
local function clamp(v, a, b)
  return math.max(a, math.min(b, v))
end
local function hash2(a, b)
  return math.fmod(((a * 374761) + (b * 668265) + 14407), 2147483647)
end
local function set_font(size, mono)
  local font
  local or_1_ = (mono and fonts[("c" .. size)]) or (not mono and (size >= 22) and fonts[("d" .. size)])
  if not or_1_ then
    local _2_
    if mono then
      _2_ = "m"
    else
      _2_ = "s"
    end
    or_1_ = fonts[(_2_ .. size)]
  end
  font = (or_1_ or fonts.s18)
  local filter = "linear"
  font:setFilter(filter, filter)
  return love.graphics.setFont(font)
end
local function text_21(s, x, y, w, align, color)
  love.graphics.setColor((color or palette.ink))
  return love.graphics.printf(s, x, y, (w or 400), (align or "left"))
end
local function shadow_21(x, y, w, h)
  return nil
end
local function shadow_soft_21(x, y, w, h)
  return nil
end
local function panel_fill_21(x, y, w, h, fill)
  love.graphics.setColor((fill or palette.panel))
  return love.graphics.rectangle("fill", x, y, w, h)
end
local function hairline_21(x1, y1, x2, y2, col)
  love.graphics.setColor((col or palette.line))
  love.graphics.setLineWidth(1)
  return love.graphics.line(x1, y1, x2, y2)
end
local function ruled_21(x, y, w)
  hairline_21(x, y, (x + w), y, palette.line)
  return hairline_21(x, (y + 3), (x + w), (y + 3), {0.35, 0.36, 0.34, 0.35})
end
local function clipped_frame_21(x, y, w, h, stroke)
  if stroke then
    love.graphics.setColor(stroke)
    love.graphics.setLineWidth(1)
    return love.graphics.rectangle("line", x, y, w, h)
  else
    return nil
  end
end
local function grain_21(x, y, w, h, seed)
  return nil
end
local function rect_21(x, y, w, h, fill, stroke)
  panel_fill_21(x, y, w, h, fill)
  if stroke then
    clipped_frame_21(x, y, w, h, stroke)
    if ((w > 100) and (h > 60)) then
      clipped_frame_21((x + 4), (y + 4), (w - 8), (h - 8), {0.2, 0.23, 0.23})
      return hairline_21(x, y, (x + math.min(w, 64)), y, palette.gold)
    else
      return nil
    end
  else
    return nil
  end
end
local function ledger_rect_21(x, y, w, h, fill, stroke)
  panel_fill_21(x, y, w, h, (fill or palette.panel))
  if stroke then
    return clipped_frame_21(x, y, w, h, (stroke or palette.line))
  else
    return nil
  end
end
local function transcript_rect_21(x, y, w, h, fill, stroke)
  panel_fill_21(x, y, w, h, (fill or palette.panel))
  if stroke then
    return clipped_frame_21(x, y, w, h, stroke)
  else
    return nil
  end
end
local function pin_rect_21(x, y, w, h, fill, stroke)
  panel_fill_21(x, y, w, h, (fill or palette["paper-light"]))
  if stroke then
    return clipped_frame_21(x, y, w, h, stroke)
  else
    return nil
  end
end
local district_anchors = {cafe = {99, 79}, apartment = {146, 23}, store = {207, 105}, alley = {134, 96}}
local function district_art_21(x, y, w, h, location)
  panel_fill_21(x, y, w, h, palette["paper-light"])
  if art.district then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(art.district, x, y, 0, (w / 320), (h / 224))
  else
  end
  if (location and district_anchors[location]) then
    local point = district_anchors[location]
    local px = (x + (point[1] * (w / 320)))
    local py = (y + (point[2] * (h / 224)))
    return rect_21((px - 4), (py - 4), 8, 8, palette.gold, palette.ink)
  else
    return nil
  end
end
local function dotted_line_21(x1, y1, x2, y2)
  local dx = (x2 - x1)
  local dy = (y2 - y1)
  local len = math.sqrt(((dx * dx) + (dy * dy)))
  local ux = (dx / len)
  local uy = (dy / len)
  for distance = 0, len, 10 do
    local finish = math.min(len, (distance + 5))
    love.graphics.line((x1 + (ux * distance)), (y1 + (uy * distance)), (x1 + (ux * finish)), (y1 + (uy * finish)))
  end
  return nil
end
local function dotted_rect_21(x, y, w, h)
  dotted_line_21(x, y, (x + w), y)
  dotted_line_21((x + w), y, (x + w), (y + h))
  dotted_line_21((x + w), (y + h), x, (y + h))
  return dotted_line_21(x, (y + h), x, y)
end
local function stamp_21(label, x, y, w, h, col)
  love.graphics.setColor(col)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x, y, w, h)
  love.graphics.rectangle("line", (x + 2), (y + 2), (w - 4), (h - 4))
  set_font(10, true)
  return text_21(label, (x + 4), (y + 6), (w - 8), "center", col)
end
local function scanlines_21()
  love.graphics.setColor({1, 1, 1, 0.045})
  love.graphics.setLineWidth(1)
  for y = 0, H, 2 do
    love.graphics.line(0, y, W, y)
  end
  love.graphics.setColor({0, 0, 0, 0.25})
  love.graphics.rectangle("line", 0, 0, W, H)
  return love.graphics.rectangle("line", 2, 2, (W - 4), (H - 4))
end
local function ambiance_21()
  local warm = {0.54, 0.53, 0.46, 0.11}
  local cool = {0.68, 0.68, 0.64, 0.055}
  love.graphics.setColor(warm)
  for i = 1, 8 do
    local seed = math.abs(hash2(i, 97))
    local y = (72 + math.fmod(seed, 580))
    local x = (12 + math.fmod(math.abs(hash2(i, 131)), 26))
    love.graphics.rectangle("fill", x, y, 2, 2)
    love.graphics.rectangle("fill", (W - x - 4), y, 2, 2)
  end
  love.graphics.setColor(cool)
  love.graphics.line(18, 62, 42, 62)
  love.graphics.line((W - 42), 62, (W - 18), 62)
  love.graphics.line(18, (H - 30), 42, (H - 30))
  return love.graphics.line((W - 42), (H - 30), (W - 18), (H - 30))
end
local function cafe_vignette_21(x, y, w, h)
  if art.cafe_composed then
    local image = art.cafe_composed
    local iw = image:getWidth()
    local ih = image:getHeight()
    local crop_x = 68
    local crop_y = 45
    local crop_w = 1022
    local crop_h = 673
    local floor_h = math.max(30, math.floor((h * 0.24)))
    local image_h = (h - floor_h)
    local floor_y = (y + image_h)
    local quad = love.graphics.newQuad(crop_x, crop_y, crop_w, crop_h, iw, ih)
    love.graphics.setColor({0.045, 0.045, 0.043})
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor({1, 1, 1, 0.78})
    love.graphics.draw(image, quad, x, y, 0, (w / crop_w), (image_h / crop_h))
    love.graphics.setColor({0.075, 0.075, 0.07})
    love.graphics.rectangle("fill", x, floor_y, w, floor_h)
    love.graphics.setColor({0.02, 0.02, 0.018, 0.8})
    love.graphics.rectangle("fill", (x + (w * 0.06)), (floor_y - 2), (w * 0.38), 5)
    love.graphics.rectangle("fill", (x + (w * 0.39)), (floor_y - 2), (w * 0.2), 5)
    love.graphics.rectangle("fill", (x + (w * 0.77)), (floor_y - 2), (w * 0.18), 5)
    love.graphics.setColor({0.12, 0.12, 0.11, 0.92})
    love.graphics.rectangle("fill", (x + (w * 0.08)), (y + (image_h * 0.07)), 5, (floor_y - (y + (image_h * 0.07))))
    love.graphics.rectangle("fill", ((x + (w * 0.92)) - 5), (y + (image_h * 0.07)), 5, (floor_y - (y + (image_h * 0.07))))
    love.graphics.setColor({0.54, 0.53, 0.46, 0.48})
    love.graphics.line((x + (w * 0.08)), (y + (image_h * 0.07)), (x + (w * 0.92)), (y + (image_h * 0.07)))
    love.graphics.rectangle("fill", (x + (w * 0.06)), (floor_y - 4), (w * 0.08), 6)
    love.graphics.rectangle("fill", (x + (w * 0.86)), (floor_y - 4), (w * 0.08), 6)
    love.graphics.setLineWidth(2)
    love.graphics.line((x + (w * 0.23)), (floor_y - (floor_h * 0.45)), (x + (w * 0.18)), (floor_y + 1))
    love.graphics.line((x + (w * 0.3)), (floor_y - (floor_h * 0.4)), (x + (w * 0.36)), (floor_y + 1))
    love.graphics.line((x + (w * 0.43)), (floor_y - (floor_h * 0.35)), (x + (w * 0.4)), (floor_y + 1))
    love.graphics.setLineWidth(1)
    love.graphics.setColor({0.54, 0.53, 0.46, 0.42})
    love.graphics.setLineWidth(1)
    love.graphics.line(x, floor_y, (x + w), floor_y)
    love.graphics.line(x, (floor_y + (floor_h * 0.48)), (x + w), (floor_y + (floor_h * 0.48)))
    love.graphics.line(x, (y + h + -1), (x + w), (y + h + -1))
    love.graphics.setColor({0.45, 0.45, 0.43, 0.5})
    love.graphics.line((x + (w * 0.24)), floor_y, (x + (w * 0.08)), (y + h + -1))
    love.graphics.line((x + (w * 0.62)), floor_y, (x + (w * 0.46)), (y + h + -1))
    love.graphics.line((x + (w * 0.96)), floor_y, (x + (w * 0.8)), (y + h + -1))
    love.graphics.setColor({0, 0, 0, 0.22})
    return love.graphics.rectangle("fill", x, y, w, 4)
  else
    return nil
  end
end
local function exhibit_tag_21(x, y, label)
  love.graphics.setColor({0.06, 0.06, 0.06})
  love.graphics.rectangle("fill", x, y, 150, 20)
  love.graphics.setColor(palette.gold)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x, y, 150, 20)
  love.graphics.circle("line", (x + 9), (y + 10), 3)
  set_font(10, true)
  return text_21(label, (x + 18), (y + 5), 126, "left", palette.gold)
end
local function scene_sketch_21(x, y, s, marker)
  local stroke = palette.line
  local dim = palette["line-warm"]
  local fx
  local function _13_(v)
    return (x + (v * s))
  end
  fx = _13_
  local fy
  local function _14_(v)
    return (y + (v * s))
  end
  fy = _14_
  love.graphics.setLineWidth(1)
  panel_fill_21(x, y, (200 * s), (140 * s), palette["paper-light"])
  for row = 0, 7 do
    hairline_21(x, fy((row * 20)), fx(200), fy((row * 20)), {0.17, 0.2, 0.2})
  end
  for col = 0, 10 do
    hairline_21(fx((col * 20)), y, fx((col * 20)), fy(140), {0.17, 0.2, 0.2})
  end
  panel_fill_21(fx(12), fy(16), (92 * s), (18 * s), palette["line-warm"])
  panel_fill_21(fx(138), fy(16), (50 * s), (30 * s), palette["panel-cool"])
  panel_fill_21(fx(138), fy(92), (50 * s), (30 * s), palette["panel-cool"])
  love.graphics.setColor(stroke)
  love.graphics.rectangle("line", fx(0), fy(0), (200 * s), (140 * s))
  love.graphics.setColor({0.05, 0.05, 0.05})
  love.graphics.rectangle("fill", fx(8), fy(128), (26 * s), (12 * s))
  love.graphics.setColor(stroke)
  love.graphics.line(fx(8), fy(128), fx(22), fy(114))
  love.graphics.rectangle("line", fx(12), fy(16), (92 * s), (18 * s))
  love.graphics.setColor(dim)
  love.graphics.line(fx(16), fy(25), fx(100), fy(25))
  love.graphics.setColor(stroke)
  love.graphics.rectangle("line", fx(138), fy(16), (50 * s), (30 * s))
  love.graphics.rectangle("line", fx(138), fy(92), (50 * s), (30 * s))
  love.graphics.circle("line", fx(60), fy(70), (14 * s))
  love.graphics.circle("line", fx(100), fy(100), (12 * s))
  if (marker == "register") then
    love.graphics.setColor(palette.gold)
    love.graphics.circle("fill", fx(60), fy(25), (4 * s))
    set_font(10, true)
    text_21("1", fx(68), fy(19), 40, "left", palette.gold)
  else
  end
  love.graphics.setColor(dim)
  return love.graphics.line(fx(0), fy(152), fx(200), fy(152))
end
local function conflict_diagram_21(x, y)
  rect_21(x, y, 222, 104, palette["paper-light"], palette.line)
  rect_21((x + 338), y, 222, 104, palette["paper-light"], palette.line)
  set_font(12, true)
  text_21("STATEMENT / MIRA", (x + 12), (y + 12), 198, "left", palette.muted)
  text_21("RECEIPT / REGISTER", (x + 350), (y + 12), 198, "left", palette.gold)
  set_font(32, false)
  text_21("19:10", (x + 12), (y + 38), 198, "left", palette.ink)
  text_21("19:22", (x + 350), (y + 38), 198, "left", palette.ink)
  set_font(12, true)
  text_21("Claimed departure", (x + 12), (y + 78), 198, "left", palette.muted)
  text_21("In-person purchase", (x + 350), (y + 78), 198, "left", palette.muted)
  hairline_21((x + 222), (y + 50), (x + 265), (y + 50), palette.rust)
  hairline_21((x + 295), (y + 50), (x + 338), (y + 50), palette.rust)
  hairline_21((x + 272), (y + 42), (x + 288), (y + 58), palette.rust)
  hairline_21((x + 288), (y + 42), (x + 272), (y + 58), palette.rust)
  set_font(11, true)
  return text_21("CONFLICT", (x + 230), (y + 76), 100, "center", palette.rust)
end
local function case_rule_21(x, y, w)
  return ruled_21(x, y, w)
end
local function has_3f(id)
  return (state.evidence[id] ~= nil)
end
local function contradiction_on_3f(statement_id)
  local found = false
  for _, c in ipairs(state.contradictions) do
    if (c.statement == statement_id) then
      found = true
    else
    end
  end
  return found
end
local function suspect_note(id)
  if (id == "mira") then
    if contradiction_on_3f("mira_left_1910") then
      return "Said 19:10. Register says 19:22. I kept both."
    else
      return "Ran the late shift. Says she left early."
    end
  elseif (id == "arin") then
    if state.inferences.arin_means then
      return "Bought aconite at 19:04. Camera saw the bottle."
    else
      return "Food columnist. Same table every Tuesday."
    end
  elseif (id == "jo") then
    return "On till all evening. Saw a familiar hand with the cup, not the face."
  elseif (id == "sasha") then
    return "Came after close to get her key. Did not stay long."
  elseif (id == "dan") then
    return "Ran the alley route that night. Timing has to be checked."
  else
    return ""
  end
end
local function toast_21(msg)
  state["toast"] = msg
  state["toast_time"] = 3
  return nil
end
local function copy_table(source)
  local out = {}
  for k, v in pairs((source or {})) do
    out[k] = v
  end
  return out
end
local function known_evidence(extra)
  local out = {}
  for _, item in ipairs(evidence_data) do
    if (has_3f(item.id) or (item.id == extra)) then
      table.insert(out, item.id)
    else
    end
  end
  return out
end
local function known_statements(extra)
  local out = {}
  for _, id in ipairs(statement_ids) do
    if (state.heard_statements[id] or (id == extra)) then
      table.insert(out, id)
    else
    end
  end
  return out
end
local function logic_request(operation, payload, evidence_override, statement_extra)
  local body = copy_table(payload)
  body["known_evidence"] = (evidence_override or known_evidence())
  body["known_statements"] = known_statements(statement_extra)
  return prolog.request(operation, body)
end
local function absorb_logic_21(result)
  if (result and result.ok) then
    state["logic_online"] = true
    if result.contradictions then
      state["contradictions"] = result.contradictions
      state["contradiction"] = (#result.contradictions > 0)
    else
    end
    if result.inferences then
      state["inferred_facts"] = result.inferences
      state["inferences"] = {}
      for _, id in ipairs(result.inferences) do
        state.inferences[id] = true
        state.timeline_entries[id] = true
      end
    else
    end
    if result.inference_details then
      state["proof_data"] = result.inference_details
    else
    end
    if result.knowledge then
      state["hypotheses"] = (result.knowledge.hypothesized or {})
      state.major_flags["unique_proof"] = (#(result.knowledge.proven or {}) > 0)
    else
    end
    return true
  else
    return nil
  end
end
local function maybe_trigger_contradiction_21()
  if (has_3f("receipt_004") and state.heard_statements.mira_left_1910) then
    if not state.contradiction_seen.receipt_mira then
      state.contradiction_seen["receipt_mira"] = true
      if (state.screen ~= "contradiction") then
        state["prev_screen"] = state.screen
        state["screen"] = "contradiction"
        return nil
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function logic_sync()
  local snapshot = logic_request("query_state", {})
  if absorb_logic_21(snapshot) then
    local alternatives = logic_request("possible_alternatives", {})
    if (alternatives and alternatives.ok) then
      state["alternatives"] = (alternatives.alternatives or {})
    else
    end
    maybe_trigger_contradiction_21()
    return snapshot
  else
    state["logic_online"] = false
    return snapshot
  end
end
local function logic_accusation(payload)
  return logic_request("accusation", payload, (payload.evidence or {}))
end
_G["ondacase_state"] = state
_G["ondacase_layout"] = layout
_G["ondacase_save"] = save_mod
local function hover_3f(entry)
  return ((hover_index == entry.action) or (focusable[focus_index] == entry.action))
end
local function add_button(label, x, y, w, h, action, kind)
  local entry = {x = x, y = y, w = w, h = h, action = action, label = label, kind = kind}
  local ordinal = (#focusable + 1)
  table.insert(buttons, entry)
  table.insert(focusable, action)
  local focused = (focus_index == ordinal)
  local hov = ((mouse_lx >= x) and (mouse_lx <= (x + w)) and (mouse_ly >= y) and (mouse_ly <= (y + h)))
  local cursor = (h >= 26)
  local selected = (focused or hov)
  local bg
  if focused then
    bg = console.sodium
  elseif hov then
    bg = {0.19, 0.22, 0.22}
  else
    bg = console.panel
  end
  local fg
  if focused then
    fg = console.paper
  elseif (kind == "accent") then
    fg = palette.gold
  else
    fg = console.ink
  end
  local stroke
  if (selected or (kind == "accent")) then
    stroke = console.sodium
  else
    stroke = console.edge
  end
  love.graphics.setColor(bg)
  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.setColor(stroke)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x, y, w, h)
  if (cursor and focused) then
    love.graphics.setColor(console.paper)
    love.graphics.line((x + 7), (y + (h / 2) + -4), (x + 11), (y + (h / 2)), (x + 7), (y + (h / 2) + 4))
  else
  end
  local _36_
  if cursor then
    _36_ = 13
  else
    _36_ = 11
  end
  set_font(_36_, true)
  local raw = tostring(label)
  local inset
  if cursor then
    inset = 18
  else
    inset = 8
  end
  local max_width = (w - inset - 8)
  local initial_font = love.graphics.getFont()
  local font
  if (initial_font:getWidth(raw) > max_width) then
    set_font(10, true)
    font = love.graphics.getFont()
  else
    font = initial_font
  end
  local suffix = "..."
  local shown
  if (font:getWidth(raw) <= max_width) then
    shown = raw
  else
    local clipped = raw
    while ((string.len(clipped) > 0) and (font:getWidth((clipped .. suffix)) > max_width)) do
      clipped = string.sub(clipped, 1, (string.len(clipped) - 1))
    end
    shown = (clipped .. suffix)
  end
  local line_height = font:getHeight()
  local text_y = (y + math.max(2, ((h - line_height) / 2)))
  return text_21(shown, (x + inset), text_y, max_width, "left", fg)
end
local function update_hover_21(sx, sy)
  local calc = layout.calc(love.graphics.getDimensions(), select(2, love.graphics.getDimensions()))
  local lx = ((sx - calc.ox) / calc.scale)
  local ly = ((sy - calc.oy) / calc.scale)
  mouse_lx = lx
  mouse_ly = ly
  if not layout["in-logical?"](lx, ly) then
    hover_index = nil
    return nil
  else
    local found = nil
    for _, b in ipairs(buttons) do
      if ((lx >= b.x) and (lx <= (b.x + b.w)) and (ly >= b.y) and (ly <= (b.y + b.h))) then
        found = b.action
      else
      end
    end
    hover_index = found
    return nil
  end
end
local function add_21(id)
  state.inspected_objects[id] = true
  if not has_3f(id) then
    local result = logic_request("discover_evidence", {evidence = id}, known_evidence(id))
    if (result and result.ok) then
      state.evidence[id] = true
      state["clues"] = (state.clues + 1)
      logic_sync()
      return toast_21("Evidence added to your file.")
    else
      local lock = logic_request("why_locked", {evidence = id}, known_evidence(id))
      return toast_21(((lock and lock.ok and lock.locked and lock.reason_title) or "Evidence is not available yet."))
    end
  else
    return nil
  end
end
local function record_statement_21(id)
  if not state.heard_statements[id] then
    local result = logic_request("record_statement", {statement = id}, nil, id)
    if (result and result.ok) then
      state.heard_statements[id] = true
      return logic_sync()
    else
      return toast_21("The statement could not be filed.")
    end
  else
    return nil
  end
end
local function known_ink_vars()
  local vars = {}
  for _, item in ipairs(evidence_data) do
    vars[item.id] = has_3f(item.id)
  end
  for _, c in ipairs(state.contradictions) do
    if c.statement then
      vars[("contradicts_" .. c.statement)] = true
    else
    end
  end
  vars["contradiction_open"] = (#state.contradictions > 0)
  vars["case_proven"] = (state.major_flags.unique_proof == true)
  return vars
end
local function hear_from_text_21(text)
  if (type(text) == "string") then
    if string.find(text, "left at ten past seven", 1, true) then
      record_statement_21("mira_left_1910")
    else
    end
    if string.find(text, "bought cough drops", 1, true) then
      record_statement_21("arin_cough_drops")
    else
    end
    if string.find(text, "saw somebody with the cup", 1, true) then
      record_statement_21("jo_saw_cup_1921")
    else
    end
    if string.find(text, "thought it was Mira", 1, true) then
      record_statement_21("jo_identified_mira")
    else
    end
    if string.find(text, "never raised my voice", 1, true) then
      record_statement_21("sasha_never_argued")
    else
    end
    if string.find(text, "never went inside", 1, true) then
      return record_statement_21("dan_never_inside")
    else
      return nil
    end
  else
    return nil
  end
end
local function selected_list(selected_set)
  local selected = {}
  for _, item in ipairs(evidence_data) do
    if selected_set[item.id] then
      table.insert(selected, item.id)
    else
    end
  end
  return selected
end
local function accusation_payload(suspect)
  local selected = selected_list(state.accusation.evidence)
  return {suspect = (suspect or state.accused), motive = selected_list(state.accusation.motive), method = selected_list(state.accusation.method), opportunity = selected_list(state.accusation.opportunity), evidence = selected}
end
local function finish_accusation_21(payload, result)
  if (result and result.ok and result.result) then
    table.insert(state.accusation_attempts, {payload = payload, result = result.result})
    state["ending"] = result.result.ending
    state["ending_report"] = result.result
    state.major_flags["submitted"] = true
    state["screen"] = "ending"
    return nil
  else
    return nil
  end
end
local function dispatch_ink_callback_21(callback)
  local name = callback.name
  local arg = (callback.args and callback.args[1])
  if (name == "discover_evidence") then
    return add_21(arg)
  elseif (name == "record_statement") then
    return record_statement_21(arg)
  elseif (name == "evaluate_accusation") then
    local payload = accusation_payload(arg)
    local result = logic_accusation(payload)
    return finish_accusation_21(payload, result)
  else
    return toast_21("Ink requested an unsupported operation.")
  end
end
local function apply_ink_21(result)
  if (result and result.ok) then
    state["ink_state"] = result.state
    state["ink_text"] = (result.text or (result.lines and table.concat(result.lines, "\n\n")) or "")
    state["ink_choices"] = (result.choices or {})
    state["ink_can_continue"] = (result.can_continue == true)
    state["dialogue_page"] = 1
    hear_from_text_21(state.ink_text)
    for _, callback in ipairs((result.callbacks or {})) do
      dispatch_ink_callback_21(callback)
    end
    return nil
  else
    return toast_21(((result and result.error) or "Dialogue runtime unavailable."))
  end
end
local function ink_request_21(operation, payload)
  local body = copy_table(payload)
  body["variables"] = known_ink_vars()
  if (state.ink_state and (operation ~= "start")) then
    body["state"] = state.ink_state
  else
  end
  local result = ink.request(operation, body)
  apply_ink_21(result)
  return result
end
local function open_interview_21(person)
  state["current_person"] = person
  state["screen"] = "dialogue"
  focus_index = 7
  table.insert(state.conversation_branches, ("goto:" .. tostring(person)))
  return ink_request_21("goto", {knot = tostring(person)})
end
local function continue_interview_21()
  table.insert(state.conversation_branches, "continue")
  return ink_request_21("continue", {})
end
local function choose_interview_21(choice)
  table.insert(state.conversation_branches, ("choice:" .. tostring(state.current_person) .. ":" .. tostring(choice.index)))
  if ((state.current_person == "dan") and ((choice.text == "Ask about the route gap") or (choice.text == "Ask him to walk the route again"))) then
    record_statement_21("dan_route_recollection")
  else
  end
  return ink_request_21("choose", {index = choice.index})
end
local function topbar_21(label, sub)
  love.graphics.setColor(palette.paper)
  love.graphics.rectangle("fill", 0, 0, W, 36)
  love.graphics.setColor(palette.line)
  love.graphics.line(0, 36, W, 36)
  love.graphics.setColor(palette.gold)
  love.graphics.rectangle("fill", 20, 13, 4, 4)
  set_font(11, true)
  text_21("ONDACASE 001", 30, 11, 150, "left", palette.gold)
  set_font(12, true)
  text_21(label, 160, 11, 500, "left", palette.ink)
  local badge = string.format("%02d FILED", state.clues)
  set_font(11, true)
  return text_21(badge, (W - 100), 11, 80, "right", palette.gold)
end
local function cafe_art_21(alpha)
  if art.cafe then
    love.graphics.setColor(1, 1, 1, (alpha or 1))
    love.graphics.draw(art.cafe, 0, 0, 0, (W / art.cafe:getWidth()), (H / art.cafe:getHeight()))
    return love.graphics.setColor(1, 1, 1, 1)
  else
    if art.cafe_composed then
      love.graphics.setColor(1, 1, 1, (0.42 * (alpha or 1)))
      love.graphics.draw(art.cafe_composed, 0, 0, 0, (W / art.cafe_composed:getWidth()), (H / art.cafe_composed:getHeight()))
      return love.graphics.setColor(1, 1, 1, 1)
    else
      return nil
    end
  end
end
local function location_art_21(loc, alpha)
  if (loc == "cafe") then
    return cafe_art_21((alpha or 0.56))
  else
    if art.locations then
      love.graphics.setColor(1, 1, 1, (alpha or 0.92))
      do
        local sw = art.locations:getWidth()
        local sh = art.locations:getHeight()
        local panel_w = (sw / 3)
        local idx
        if (loc == "alley") then
          idx = 0
        else
          if (loc == "store") then
            idx = 1
          else
            if (loc == "apartment") then
              idx = 2
            else
              idx = 0
            end
          end
        end
        local quad = love.graphics.newQuad((idx * panel_w), 0, panel_w, sh, sw, sh)
        love.graphics.draw(art.locations, quad, 0, 0, 0, (W / panel_w), (H / sh))
      end
      return love.graphics.setColor(1, 1, 1, 1)
    else
      return nil
    end
  end
end
local function suspect_portrait_21(person, x, y, w, h, full_bleed)
  local indiv = (art.portraits and art.portraits[person])
  local crop = ((h <= 64) and art.portrait_crops and art.portrait_crops[person])
  if indiv then
    if not full_bleed then
      rect_21(x, y, w, h, {0.18, 0.17, 0.16}, palette.line)
    else
    end
    local sw
    if crop then
      sw = 112
    else
      sw = indiv:getWidth()
    end
    local sh
    if crop then
      sh = 112
    else
      sh = indiv:getHeight()
    end
    local padding
    if full_bleed then
      padding = 0
    elseif crop then
      padding = 4
    else
      padding = 12
    end
    local scale = math.min(((w - padding) / sw), ((h - padding) / sh))
    local dw = (sw * scale)
    local dh = (sh * scale)
    local dx = (x + ((w - dw) / 2))
    local dy = (y + ((h - dh) / 2))
    love.graphics.setColor(1, 1, 1, 1)
    if crop then
      love.graphics.draw(indiv, crop, dx, dy, 0, scale, scale)
    else
      love.graphics.draw(indiv, dx, dy, 0, scale, scale)
    end
    return love.graphics.setColor(1, 1, 1, 1)
  else
    if art.suspects then
      rect_21(x, y, w, h, {0.18, 0.17, 0.16}, palette.line)
      local order = {mira = 0, arin = 1, jo = 2, sasha = 3, dan = 4}
      local idx = (order[person] or 0)
      local sw = art.suspects:getWidth()
      local sh = art.suspects:getHeight()
      local quad_w = (sw / 5)
      local quad_h = sh
      local scale = math.min(((w - 12) / quad_w), ((h - 12) / quad_h))
      local dw = (quad_w * scale)
      local dh = (quad_h * scale)
      local dx = (x + ((w - dw) / 2))
      local dy = (y + ((h - dh) / 2))
      love.graphics.setColor(1, 1, 1, 1)
      do
        local quad = love.graphics.newQuad((idx * quad_w), 0, quad_w, quad_h, sw, sh)
        love.graphics.draw(art.suspects, quad, dx, dy, 0, scale, scale)
      end
      return love.graphics.setColor(1, 1, 1, 1)
    else
      rect_21(x, y, w, h, {0.16, 0.17, 0.17}, palette.line)
      local init = string.upper(string.sub(tostring(person), 1, 2))
      set_font(48, false)
      text_21(init, (x + 10), (y + 90), (w - 20), "center", palette.muted)
      set_font(11, true)
      text_21(string.upper(tostring(person)), (x + 10), (y + 185), (w - 20), "center", palette.gold)
      set_font(10, true)
      return text_21("CONTACT PRINT", (x + 10), (y + 210), (w - 20), "center", palette.muted)
    end
  end
end
local function nav_21()
  local function _75_()
    state["screen"] = "evidence"
    return nil
  end
  add_button("FILE", 20, 36, 60, 20, _75_)
  local function _76_()
    state["screen"] = "board"
    return nil
  end
  add_button("BOARD", 85, 36, 60, 20, _76_)
  local function _77_()
    state["screen"] = "timeline"
    return nil
  end
  add_button("TIME", 150, 36, 60, 20, _77_)
  local function _78_()
    state["screen"] = "accuse"
    return nil
  end
  add_button("ACCUSE", 215, 36, 60, 20, _78_, "accent")
  local function _79_()
    state["screen"] = "pause"
    return nil
  end
  add_button("MENU", (W - 70), 36, 60, 20, _79_)
  local function _80_()
    state["screen"] = "investigate"
    return nil
  end
  add_button("MAP", 280, 36, 60, 20, _80_)
  local tab = (({evidence = 20, evidence_detail = 20, board = 85, proof = 85, theory = 85, timeline = 150, accuse = 215, investigate = 280, location = 280})[state.screen] or nil)
  if tab then
    return hairline_21(tab, 60, (tab + 60), 60, palette.gold)
  else
    return nil
  end
end
local function save_state_21()
  local s = save_mod.serialize(state)
  if s then
    love.filesystem.write("save.json", s)
    return toast_21("Case record saved.")
  else
    return toast_21("The case record is too large to save.")
  end
end
local function load_state_21()
  if not love.filesystem.getInfo("save.json") then
    toast_21("No case record found.")
    return
  else
  end
  local raw = love.filesystem.read("save.json")
  local parsed = save_mod.parse(raw)
  if parsed then
    state["screen"] = (parsed.screen or "investigate")
    state["evidence"] = (parsed.evidence or {})
    state["accused"] = (parsed.accused or "arin")
    state["accusation"] = (parsed.accusation or {suspect = "arin"})
    state["settings"] = (parsed.settings or {reducedMotion = false})
    state["ink_state"] = parsed.ink_state
    state["ending"] = parsed.ending
    state["ending_report"] = parsed.ending_report
    state["current_person"] = parsed.current_person
    state["inspected_objects"] = parsed.inspected_objects
    state["visited_locations"] = parsed.visited_locations
    state["heard_statements"] = parsed.heard_statements
    state["inferences"] = (parsed.inferences or {})
    state["contradictions"] = parsed.contradictions
    local _84_
    if (parsed.contradiction == true) then
      _84_ = true
    else
      _84_ = false
    end
    state["contradiction"] = _84_
    state["inferred_facts"] = parsed.inferred_facts
    state["conversation_branches"] = parsed.conversation_branches
    state["hypotheses"] = parsed.hypotheses
    state["timeline_entries"] = parsed.timeline_entries
    state["presented_evidence"] = parsed.presented_evidence
    state["accusation_attempts"] = parsed.accusation_attempts
    state["major_flags"] = parsed.major_flags
    state["alternatives"] = parsed.alternatives
    state["proof_data"] = parsed.proof_data
    state["evidence_page"] = (parsed.evidence_page or 1)
    state["timeline_page"] = (parsed.timeline_page or 1)
    state["ink_text"] = parsed.ink_text
    state["ink_choices"] = (parsed.ink_choices or {})
    state["ink_can_continue"] = (parsed.ink_can_continue or false)
    state["dialogue_page"] = (parsed.dialogue_page or 1)
    state["evidence_detail"] = parsed.evidence_detail
    state["prev_screen"] = parsed.prev_screen
    state["location"] = (parsed.location or "cafe")
    state["contradiction_seen"] = (parsed.contradiction_seen or {})
    state["theory"] = (parsed.theory or {suspect = "arin", motive = {}, method = {}, opportunity = {}, evidence = {}, mode = "evidence"})
    state["theory_report_page"] = 1
    state["active_proof"] = parsed.active_proof
    local c = 0
    for _, _0 in pairs(state.evidence) do
      c = (c + 1)
    end
    state["clues"] = c
    logic_sync()
    return toast_21("Case record reopened.")
  else
    state["evidence"] = {}
    state["clues"] = 0
    state["screen"] = "title"
    return toast_21("Save was damaged. Started fresh.")
  end
end
local function draw_title()
  panel_fill_21(0, 0, W, H, palette.paper)
  district_art_21(64, 228, 592, 414.4)
  set_font(13, true)
  text_21("ONDACASE / CASE 001", 60, 40, 500, "left", palette.gold)
  set_font(42, false)
  text_21("The iced americano at 7:22", 60, 72, 620, "left", palette.ink)
  set_font(13, true)
  text_21("I was called at 19:42. The cup was still warm.", 60, 137, 600, "left", palette.muted)
  local function _87_()
    state["screen"] = "case_select"
    return nil
  end
  add_button("Open file", 60, 180, 130, 32, _87_, "accent")
  add_button("Continue", 200, 180, 110, 32, load_state_21)
  local function _88_()
    state["screen"] = "settings"
    return nil
  end
  add_button("Settings", 320, 180, 90, 32, _88_)
  set_font(12, true)
  return text_21("CAFE LANTERN / 19:22", 64, 622, 500, "left", palette.gold)
end
local function draw_case_select()
  panel_fill_21(0, 0, W, H, palette.paper)
  love.graphics.setColor(palette.rust)
  love.graphics.rectangle("fill", 0, 0, 10, H)
  set_font(12, true)
  text_21("Files on my desk", 72, 72, 300, "left", palette.gold)
  set_font(42, false)
  text_21("One file tonight", 72, 112, 500, "left", palette.ink)
  set_font(14, false)
  text_21("One is enough when it is not yet closed.", 74, 180, 500, "left", palette.muted)
  rect_21(74, 245, 572, 220, palette.panel, palette.line)
  set_font(11, true)
  text_21("File 001 / open", 108, 280, 250, "left", palette.gold)
  set_font(29, false)
  text_21("The iced americano at 7:22", 108, 318, 560, "left", palette.ink)
  set_font(13, false)
  text_21("Cafe Lantern. Five names. One cup that should not have killed anyone.", 108, 368, 560, "left", palette.muted)
  local function _89_()
    state["screen"] = "investigate"
    return nil
  end
  add_button("Open it", 108, 500, 160, 44, _89_, "accent")
  set_font(12, true)
  return text_21("One case. Five accounts to check.", 74, 590, 570, "left", palette.muted)
end
local function visit_location_21(location)
  state["location"] = location
  state["location_view"] = 1
  state.visited_locations[location] = true
  state["screen"] = "location"
  return nil
end
local function draw_investigate()
  topbar_21("AREA MAP", "FOUR LOCATIONS")
  nav_21()
  set_font(13, true)
  text_21("Select a location", 40, 82, 400, "left", palette.ink)
  set_font(11, true)
  text_21("SCHEMATIC / NOT TO SCALE", 380, 84, 300, "right", palette.muted)
  district_art_21(40, 112, 640, 448)
  clipped_frame_21(40, 112, 640, 448, palette.line)
  if not art.district then
    set_font(13, true)
    text_21("Map image unavailable. Location controls still work.", 60, 520, 600, "left", palette.muted)
  else
  end
  for _, loc in ipairs({{id = "cafe", label = "Cafe Lantern", bx = 52, by = 312}, {id = "alley", label = "Service alley", bx = 104, by = 398}, {id = "store", label = "Night store", bx = 496, by = 356}, {id = "apartment", label = "Eli's apartment", bx = 450, by = 140}}) do
    local point = district_anchors[loc.id]
    local ax = (40 + (point[1] * 2))
    local ay = (112 + (point[2] * 2))
    local current = (state.location == loc.id)
    hairline_21(ax, ay, ax, (loc.by + 15), palette.gold)
    hairline_21(ax, (loc.by + 15), loc.bx, (loc.by + 15), palette.gold)
    rect_21((ax - 3), (ay - 3), 6, 6, palette.gold)
    local function _91_()
      return visit_location_21(loc.id)
    end
    local function _92_()
      if current then
        return "accent"
      else
        return nil
      end
    end
    add_button(loc.label, loc.bx, loc.by, 168, 30, _91_, _92_())
  end
  set_font(12, true)
  text_21("Places to visit, not a reconstruction of the crime.", 40, 580, 640, "left", palette.muted)
  local function _93_()
    state["screen"] = "people"
    return nil
  end
  add_button("People", 40, 608, 140, 34, _93_, "accent")
  local function _94_()
    state["screen"] = "evidence"
    return nil
  end
  return add_button("Evidence file", 192, 608, 156, 34, _94_)
end
local evidence_per_page = 6
local function filtered_evidence()
  local out = {}
  for _, e in ipairs(evidence_data) do
    if has_3f(e.id) then
      table.insert(out, e)
    else
    end
  end
  return out
end
local function draw_evidence()
  topbar_21("FILE", "WHAT I FILED")
  nav_21()
  rect_21(60, 90, 600, 460, palette.panel, palette.line)
  do
    local all = filtered_evidence()
    local total = #all
    local pages = math.max(1, math.ceil((math.max(total, 1) / evidence_per_page)))
    local page = math.max(1, math.min((state.evidence_page or 1), pages))
    local start = (1 + ((page - 1) * evidence_per_page))
    local finish = math.min(total, (start + evidence_per_page + -1))
    state["evidence_page"] = page
    if (total == 0) then
      set_font(12, true)
      text_21("Nothing filed yet.", 80, 120, 400, "left", palette.ink)
      set_font(11, true)
      text_21("Go look around.", 80, 140, 400, "left", palette.muted)
    else
      for idx = start, finish do
        local e = all[idx]
        local y = (110 + ((idx - start) * 58))
        rect_21(74, (y - 4), 572, 50, palette["paper-light"])
        set_font(12, true)
        text_21(e.title, 80, y, 300, "left", palette.ink)
        set_font(11, true)
        text_21(e.sub, 80, (y + 16), 300, "left", palette.muted)
        set_font(11, true)
        text_21(e.tag, 390, (y + 4), 156, "left", palette.gold)
        local function _96_()
          state["evidence_detail"] = e.id
          state["screen"] = "evidence_detail"
          return nil
        end
        add_button("Open", 560, y, 70, 30, _96_)
      end
    end
    if (pages > 1) then
      set_font(11, true)
      text_21(string.format("%d/%d", page, pages), 330, 500, 60, "center", palette.muted)
      local function _98_()
        state["evidence_page"] = math.max(1, (page - 1))
        return nil
      end
      add_button("Prev", 250, 495, 70, 26, _98_)
      local function _99_()
        state["evidence_page"] = math.min(pages, (page + 1))
        return nil
      end
      add_button("Next", 410, 495, 70, 26, _99_)
    else
    end
  end
  local function _101_()
    state["screen"] = "investigate"
    return nil
  end
  add_button("Back", 60, 580, 100, 30, _101_)
  if state.inferences.mira_departure_conflict then
    local function _102_()
      state["active_proof"] = "mira_departure_conflict"
      state["screen"] = "proof"
      return nil
    end
    return add_button("Why Mira fails", 170, 580, 140, 30, _102_, "accent")
  else
    return nil
  end
end
local function draw_evidence_detail()
  local detail_id = state.evidence_detail
  local found
  do
    local f = nil
    for _, e in ipairs(evidence_data) do
      if (e.id == detail_id) then
        f = e
      else
      end
    end
    found = f
  end
  topbar_21("FILE", ((found and found.title) or "RECORD"))
  nav_21()
  if not found then
    set_font(12, true)
    text_21("No record.", 60, 140, 400, "left", palette.ink)
    local function _105_()
      state["screen"] = "evidence"
      return nil
    end
    return add_button("Back", 60, 170, 100, 30, _105_)
  else
    rect_21(60, 110, 600, 420, palette.panel, palette.line)
    set_font(14, true)
    text_21(found.title, 80, 130, 560, "left", palette.ink)
    set_font(11, true)
    text_21(found.sub, 80, 150, 560, "left", palette.gold)
    set_font(14, false)
    text_21(found.body, 80, 175, 560, "left", palette.muted)
    set_font(11, true)
    text_21(("Found: " .. found.discovered), 80, 220, 560, "left", palette.muted)
    set_font(11, true)
    text_21(("Means: " .. found.implication), 80, 240, 560, "left", palette.muted)
    set_font(11, true)
    text_21(found.status, 80, 260, 560, "left", palette.muted)
    scene_sketch_21(390, 362, 0.95, "register")
    set_font(10, true)
    text_21("SCENE SKETCH / REGISTER", 390, 512, 260, "left", palette.muted)
    do
      local evidence_proof_map = {receipt_004 = "mira_departure_conflict", pharmacy_footage = "arin_means", cup_lid = "arin_delivery_method", tape_fiber = "arin_contact", draft_email = "arin_motive", service_log = "arin_opportunity", toxicology = "death_window_established", camera_log = "camera_gap_confirmed"}
      local target = (evidence_proof_map[found.id] or found.id)
      local proof
      do
        local p = nil
        for _, pr in ipairs((state.proof_data or {})) do
          local or_106_ = (pr.fact == found.id) or (pr.fact == target)
          if not or_106_ then
            local has = false
            for _0, prem in ipairs((pr.premises or {})) do
              if (prem.id == found.id) then
                has = true
              else
              end
            end
            or_106_ = has
          end
          if or_106_ then
            p = pr
          else
          end
        end
        proof = p
      end
      if proof then
        set_font(12, true)
        text_21(proof.conclusion, 80, 300, 390, "left", palette.ink)
        local function _109_()
          state["active_proof"] = proof.fact
          state["screen"] = "proof"
          return nil
        end
        add_button("View proof", 500, 290, 120, 30, _109_, "accent")
      elseif set_font(12, true) then
        text_21("No proof yet.", 80, 300, 400, "left", palette.muted)
      else
      end
    end
    do
      local ev = found.id
      local _111_
      if state.accusation.evidence[ev] then
        _111_ = "Remove"
      else
        _111_ = "Add"
      end
      local function _113_()
        if state.accusation.evidence[ev] then
          state.accusation.evidence[ev] = nil
          return nil
        else
          state.accusation.evidence[ev] = true
          state.presented_evidence[ev] = true
          return nil
        end
      end
      local function _115_()
        if state.accusation.evidence[ev] then
          return "accent"
        else
          return nil
        end
      end
      add_button(_111_, 500, 330, 120, 30, _113_, _115_())
    end
    local function _116_()
      state["screen"] = "evidence"
      return nil
    end
    add_button("Back", 60, 580, 100, 30, _116_)
    local function _117_()
      state["screen"] = "theory"
      return nil
    end
    return add_button("Theory", 170, 580, 100, 30, _117_)
  end
end
local timeline_defs
do
  local out = {}
  for _, row in ipairs(case_manifest.timeline) do
    table.insert(out, {time = row.time, event = row.event, status = row.status, requires = (row.requires or {})})
  end
  timeline_defs = out
end
local function timeline_visible()
  local out = {}
  for _, row in ipairs(timeline_defs) do
    local reqs = row.requires
    local ok
    do
      local v = true
      for _0, id in ipairs(reqs) do
        if not has_3f(id) then
          v = false
        else
        end
      end
      ok = v
    end
    if ((#reqs == 0) or ok) then
      table.insert(out, row)
    else
    end
  end
  return out
end
local function draw_timeline()
  topbar_21("TIME", "WHEN")
  nav_21()
  rect_21(60, 90, 600, 460, palette.panel, palette.line)
  set_font(11, true)
  text_21("Timeline - only what is filed shows.", 80, 110, 560, "left", palette.muted)
  do
    local rows = timeline_visible()
    local per_page = 6
    local total = #rows
    local pages = math.max(1, math.ceil((math.max(total, 1) / per_page)))
    local page = math.max(1, math.min((state.timeline_page or 1), pages))
    local start = (1 + ((page - 1) * per_page))
    local finish = math.min(total, (start + per_page + -1))
    state["timeline_page"] = page
    hairline_21(172, 136, 172, 464, palette.line)
    if (total == 0) then
      set_font(12, true)
      text_21("Nothing yet.", 80, 140, 400, "left", palette.muted)
    else
      for idx = start, finish do
        local row = rows[idx]
        local y = (136 + ((idx - start) * 56))
        local confirmed = (row.status == "confirmed")
        rect_21(192, (y - 4), 440, 48, palette["paper-light"])
        local _121_
        if confirmed then
          _121_ = palette.green
        else
          _121_ = palette.panel
        end
        local function _123_()
          if confirmed then
            return palette.green
          else
            return palette.dust
          end
        end
        rect_21(168, (y + 4), 8, 8, _121_, _123_())
        if not confirmed then
          love.graphics.setColor(palette.dust)
          dotted_line_21(176, (y + 8), 192, (y + 8))
        else
        end
        set_font(12, true)
        text_21(row.time, 80, (y + 4), 82, "left", palette.gold)
        set_font(12, true)
        text_21(row.event, 204, y, 302, "left", palette.ink)
        set_font(11, true)
        local function _125_()
          if confirmed then
            return palette.green
          else
            return palette.dust
          end
        end
        text_21(string.upper(row.status), 516, (y + 4), 104, "right", _125_())
      end
    end
    if (pages > 1) then
      local function _127_()
        state["timeline_page"] = math.max(1, (page - 1))
        return nil
      end
      add_button("Prev", 250, 500, 70, 26, _127_)
      local function _128_()
        state["timeline_page"] = math.min(pages, (page + 1))
        return nil
      end
      add_button("Next", 410, 500, 70, 26, _128_)
    else
    end
  end
  local function _130_()
    state["screen"] = "investigate"
    return nil
  end
  add_button("Back", 60, 580, 100, 30, _130_)
  if state.contradiction then
    local function _131_()
      state["prev_screen"] = "timeline"
      state["screen"] = "contradiction"
      return nil
    end
    return add_button("Conflict", 170, 580, 100, 30, _131_, "accent")
  else
    return nil
  end
end
local function draw_contradiction()
  topbar_21("CONFLICT", "RECEIPT vs MIRA")
  nav_21()
  rect_21(60, 90, 600, 380, palette.panel, palette.line)
  set_font(18, false)
  text_21("Mira said 19:10. Register says 19:22.", 80, 120, 560, "left", palette.ink)
  set_font(14, false)
  text_21("One is memory. One is paper. Both cannot be true.", 80, 155, 560, "left", palette.muted)
  set_font(11, true)
  text_21("This breaks the alibi. Not the murder.", 80, 190, 500, "left", palette.gold)
  conflict_diagram_21(80, 225)
  local function _133_()
    state["screen"] = (state.prev_screen or "investigate")
    return nil
  end
  add_button("Keep looking", 80, 400, 140, 30, _133_, "accent")
  local function _134_()
    state["active_proof"] = "mira_departure_conflict"
    state["screen"] = "proof"
    return nil
  end
  return add_button("See proof", 230, 400, 120, 30, _134_)
end
local board_nodes = {{id = "mira_conflict", label = "MIRA", sub = "timeline conflict", x = 210, y = 280, requires = {"receipt_004", "mira_left_1910"}, kind = "contradiction"}, {id = "arin_means", label = "ARIN", sub = "pharmacy / poison", x = 650, y = 220, requires = {"pharmacy_footage"}, kind = "proven"}, {id = "eli", label = "ELI", sub = "victim", x = 650, y = 500, requires = {}, kind = "proven"}, {id = "camera_gap", label = "CAMERA GAP", sub = "19:18 - 19:29", x = 1000, y = 290, requires = {"camera_log"}, kind = "proven"}, {id = "cup_lid", label = "CUP LID", sub = "residue", x = 330, y = 500, requires = {"cup_lid"}, kind = "proven"}, {id = "tape_fiber", label = "TAPE FIBER", sub = "Arin contact", x = 450, y = 360, requires = {"tape_fiber", "cup_lid"}, kind = "proven", alt_requires = {"tape_fiber"}}, {id = "m motive", label = "MOTIVE", sub = "draft email", x = 650, y = 360, requires = {"draft_email"}, kind = "hypothesis"}}
local function board_visible_nodes()
  local out = {}
  for _, n in ipairs(board_nodes) do
    local ok
    do
      local v = true
      for _0, id in ipairs(n.requires) do
        if ((id == "mira_left_1910") and not state.heard_statements[id]) then
          v = false
        else
        end
        if ((id ~= "mira_left_1910") and not has_3f(id)) then
          v = false
        else
        end
      end
      ok = v
    end
    if ok then
      table.insert(out, n)
    else
    end
  end
  return out
end
local function draw_board()
  topbar_21("BOARD", "WHAT HOLDS")
  nav_21()
  set_font(13, true)
  text_21("What the file supports", 40, 84, 500, "left", palette.ink)
  do
    local nodes = board_visible_nodes()
    for column, group in ipairs({{"proven", "HOLD", "green"}, {"hypothesis", "GUESS", "dust"}, {"contradiction", "CONFLICT", "rust"}}) do
      local x = (40 + ((column - 1) * 218))
      local col = palette[group[3]]
      rect_21(x, 120, 204, 438, palette.panel, palette.line)
      set_font(14, true)
      text_21(group[2], (x + 14), 138, 176, "left", col)
      hairline_21((x + 14), 162, (x + 190), 162, col)
      local row = 0
      for _, node in ipairs(nodes) do
        if (node.kind == group[1]) then
          local y = (178 + (row * 72))
          rect_21((x + 12), y, 180, 60, palette["paper-light"])
          love.graphics.setColor(col)
          if (node.kind == "hypothesis") then
            dotted_rect_21((x + 12), y, 180, 60)
          else
            clipped_frame_21((x + 12), y, 180, 60, col)
            panel_fill_21((x + 12), y, 3, 60, col)
          end
          set_font(13, true)
          text_21(node.label, (x + 24), (y + 9), 154, "left", palette.ink)
          set_font(12, true)
          text_21(node.sub, (x + 24), (y + 29), 154, "left", palette.muted)
          row = (row + 1)
        else
        end
      end
      if (row == 0) then
        set_font(12, true)
        text_21("No filed entries.", (x + 14), 185, 170, "left", palette.muted)
      else
      end
    end
  end
  set_font(12, true)
  text_21("Solid: holds   Dotted: hypothesis   Conflict: incompatible records", 40, 575, 640, "left", palette.muted)
  local function _141_()
    state["screen"] = "investigate"
    return nil
  end
  add_button("Map", 40, 608, 100, 32, _141_)
  local function _142_()
    state["screen"] = "theory"
    return nil
  end
  return add_button("Test a theory", 152, 608, 160, 32, _142_)
end
local function proof_for(fact)
  for _, proof in ipairs((state.proof_data or {})) do
    if (proof.fact == fact) then
      return proof
    else
    end
  end
  return nil
end
local function draw_proof()
  local headings = {mira_departure_conflict = "MIRA TIME", arin_means = "ARIN MEANS", arin_delivery_method = "DELIVERY", arin_contact = "CONTACT", arin_motive = "MOTIVE", arin_opportunity = "WHEN", death_window_established = "WINDOW", camera_gap_confirmed = "GAP", arin_case_proven = "CASE"}
  local fact = (state.active_proof or "mira_departure_conflict")
  local proof = (proof_for(fact) or ((#(state.proof_data or {}) > 0) and state.proof_data[1]))
  local heading = (headings[fact] or "PROOF")
  topbar_21("PROOF", heading)
  nav_21()
  set_font(12, true)
  text_21((heading .. " / PROOF TRACE"), 40, 84, 600, "left", palette.gold)
  local function _144_()
    if proof then
      return palette.green
    else
      return palette.line
    end
  end
  rect_21(60, 112, 600, 100, palette.panel, _144_())
  set_font(16, false)
  text_21(((proof and proof.conclusion) or "No proof has been filed for this claim."), 80, 137, 560, "left", palette.ink)
  if proof then
    if (state.proof_view_fact ~= fact) then
      state["proof_page"] = 1
      state["proof_view_fact"] = fact
    else
    end
    local premises = (proof.premises or {})
    local pages = math.max(1, math.ceil((#premises / 6)))
    local page = math.max(1, math.min((state.proof_page or 1), pages))
    local start = (1 + ((page - 1) * 6))
    local finish = math.min(#premises, (start + 5))
    state["proof_page"] = page
    if (#premises > 0) then
      hairline_21(360, 212, 360, 480, palette.green)
      hairline_21(354, 220, 360, 212, palette.green)
      hairline_21(366, 220, 360, 212, palette.green)
    else
    end
    for i = start, finish do
      local right = (math.fmod((i - start), 2) == 1)
      local x
      if right then
        x = 392
      else
        x = 60
      end
      local y = (248 + (math.floor(((i - start) / 2)) * 78))
      local premise = premises[i]
      local _148_
      if right then
        _148_ = 392
      else
        _148_ = 328
      end
      hairline_21(_148_, (y + 28), 360, (y + 28), palette.green)
      rect_21(x, y, 268, 58, palette.panel, palette.line)
      set_font(12, true)
      text_21((string.format("%02d / ", i) .. (premise.title or "Filed premise")), (x + 12), (y + 14), 244, "left", palette.ink)
    end
    if (pages > 1) then
      local function _150_()
        state["proof_page"] = math.max(1, (page - 1))
        return nil
      end
      add_button("Prev", 400, 514, 74, 28, _150_)
      set_font(12, true)
      text_21(string.format("%d / %d", page, pages), 480, 520, 90, "center", palette.muted)
      local function _151_()
        state["proof_page"] = math.min(pages, (page + 1))
        return nil
      end
      add_button("Next", 580, 514, 74, 28, _151_)
    else
    end
  else
  end
  set_font(12, true)
  local _154_
  if proof then
    _154_ = "Filed premises support the conclusion above."
  else
    _154_ = "Find records before a proof can be traced."
  end
  text_21(_154_, 60, 568, 600, "left", palette.muted)
  local function _156_()
    state["screen"] = "evidence"
    return nil
  end
  add_button("Back", 60, 616, 100, 32, _156_)
  local function _157_()
    state["screen"] = "accuse"
    return nil
  end
  return add_button("Accuse", 172, 616, 100, 32, _157_, "accent")
end
local function toggle_accusation_evidence_21(id)
  local mode = state.accusation_mode
  local selected_set = state.accusation[mode]
  if (mode == "evidence") then
    if selected_set[id] then
      selected_set[id] = nil
      state.accusation.motive[id] = nil
      state.accusation.method[id] = nil
      state.accusation.opportunity[id] = nil
      return nil
    else
      selected_set[id] = true
      state.presented_evidence[id] = true
      return nil
    end
  else
    if selected_set[id] then
      selected_set[id] = nil
      return nil
    else
      selected_set[id] = true
      state.accusation.evidence[id] = true
      state.presented_evidence[id] = true
      return nil
    end
  end
end
local function submit_accusation_21()
  local payload = accusation_payload()
  local result = logic_accusation(payload)
  if (result and result.ok) then
    return finish_accusation_21(payload, result)
  else
    return toast_21("The reasoning engine could not evaluate the case.")
  end
end
local function close_insufficient_21()
  local snapshot = logic_sync()
  if (snapshot and snapshot.ok) then
    local _162_
    if state.major_flags.unique_proof then
      _162_ = "everybody_goes_home"
    else
      _162_ = "detective"
    end
    state["ending"] = _162_
    state["ending_report"] = {alternatives = state.alternatives, unique_solution = state.major_flags.unique_proof}
    state.major_flags["closed_insufficient"] = true
    state["screen"] = "ending"
    return nil
  else
    return toast_21("The reasoning engine could not review the open alternatives.")
  end
end
local function toggle_theory_21(id)
  local mode = state.theory.mode
  local bucket = state.theory[mode]
  if (mode == "evidence") then
    if bucket[id] then
      bucket[id] = nil
      state.theory.motive[id] = nil
      state.theory.method[id] = nil
      state.theory.opportunity[id] = nil
      return nil
    else
      bucket[id] = true
      return nil
    end
  else
    if bucket[id] then
      bucket[id] = nil
      return nil
    else
      bucket[id] = true
      state.theory.evidence[id] = true
      return nil
    end
  end
end
local function evaluate_theory_21()
  local p = {suspect = tostring(state.theory.suspect), motive = selected_list(state.theory.motive), method = selected_list(state.theory.method), opportunity = selected_list(state.theory.opportunity), evidence = selected_list(state.theory.evidence)}
  local result = logic_request("evaluate_hypothesis", p)
  state.theory["result"] = ((result and result.evaluation) or result)
  state["theory_report_page"] = 1
  if result then
    return toast_21("Theory evaluated as hypothesis.")
  else
    return nil
  end
end
local function player_status(value)
  local s = tostring((value or "unresolved"))
  return string.upper(string.gsub(s, "_", " "))
end
local function case_structure_21(x, y, w)
  local stroke = palette.line
  love.graphics.setLineWidth(1)
  love.graphics.setColor(stroke)
  rect_21(x, y, w, 22, palette["panel-cool"], stroke)
  set_font(10, true)
  text_21(string.upper(tostring(state.accused)), (x + 6), (y + 6), (w - 12), "left", palette.ink)
  for i, row in ipairs({{"MOTIVE", "motive"}, {"METHOD", "method"}, {"OPPORTUNITY", "opportunity"}}) do
    local ry = (y + 38 + ((i - 1) * 26))
    local n = #selected_list(state.accusation[row[2]])
    local active = (n > 0)
    love.graphics.setColor(stroke)
    love.graphics.line((x + w + 8), (y + 22), (x + w + 8), ry)
    love.graphics.line((x + w), ry, (x + w + 8), ry)
    rect_21(x, (ry - 9), w, 20, palette["paper-light"], stroke)
    local function _169_()
      if active then
        return palette.gold
      else
        return palette.muted
      end
    end
    text_21((row[1] .. " / " .. n), (x + 6), (ry - 4), (w - 12), "left", _169_())
  end
  return nil
end
local function theory_map_21(x, y)
  local stroke = palette.line
  rect_21(x, y, 196, 24, palette["paper-light"], stroke)
  set_font(12, true)
  text_21("HYPOTHESIS INPUTS", (x + 8), (y + 5), 180, "left", palette.dust)
  for i, row in ipairs({{"FILE", "evidence"}, {"WHY", "motive"}, {"HOW", "method"}, {"WHEN", "opportunity"}}) do
    local col = math.fmod((i - 1), 2)
    local r = math.floor(((i - 1) / 2))
    local bx = (x + (col * 102))
    local by = (y + 34 + (r * 40))
    local active = (state.theory.mode == row[2])
    rect_21(bx, by, 94, 30, palette["paper-light"])
    local function _170_()
      if active then
        return palette.gold
      else
        return stroke
      end
    end
    love.graphics.setColor(_170_())
    dotted_rect_21(bx, by, 94, 30)
    local _171_
    if active then
      _171_ = "> "
    else
      _171_ = "  "
    end
    local function _173_()
      if active then
        return palette.gold
      else
        return palette.muted
      end
    end
    text_21((_171_ .. row[1]), (bx + 8), (by + 8), 78, "left", _173_())
  end
  return nil
end
local function verdict_chart_21(x, y, w)
  local r = (state.ending_report or {})
  local stroke = palette.line
  love.graphics.setLineWidth(1)
  love.graphics.setColor(stroke)
  rect_21(x, y, w, 22, palette["panel-cool"], stroke)
  set_font(10, true)
  text_21(string.upper(tostring(state.accused)), (x + 8), (y + 6), (w - 16), "left", palette.ink)
  love.graphics.line((x + 6), (y + 22), (x + 6), (y + 88))
  for i, row in ipairs({{"MOTIVE", "motive"}, {"METHOD", "method"}, {"OPPORTUNITY", "opportunity"}}) do
    local ry = (y + 36 + ((i - 1) * 26))
    local status = player_status(r[row[2]])
    local good = (status == "SUPPORTED")
    love.graphics.setColor(stroke)
    love.graphics.line((x + 6), ry, (x + 14), ry)
    love.graphics.rectangle("line", (x + 14), (ry - 4), 9, 9)
    if good then
      love.graphics.setColor(palette.green)
      love.graphics.rectangle("fill", (x + 16), (ry - 2), 5, 5)
    else
    end
    love.graphics.setColor(stroke)
    local function _175_()
      if good then
        return palette.ink
      else
        return palette.muted
      end
    end
    text_21((row[1] .. "  " .. status), (x + 30), (ry - 5), (w - 40), "left", _175_())
  end
  return nil
end
local function add_report_line_21(lines, tone, text)
  if (text and (text ~= "")) then
    return table.insert(lines, {tone = tone, text = text})
  else
    return nil
  end
end
local function theory_report_lines(res)
  local lines = {}
  if res then
    add_report_line_21(lines, "gold", ("RESULT / " .. player_status(res.status)))
    for _, dim in ipairs((res.dimensions or {})) do
      local name = string.upper(tostring((dim.name or dim.dimension or "link")))
      add_report_line_21(lines, "ink", (name .. " / " .. player_status(dim.status)))
      for _0, support in ipairs((dim.support or {})) do
        add_report_line_21(lines, "muted", ("Supports: " .. (support.title or support.evidence_title or "Filed record")))
      end
      for _0, missing in ipairs((dim.missing or {})) do
        add_report_line_21(lines, "gold", ("Missing: " .. (missing.title or missing.evidence_title or "Required record")))
      end
    end
    for _, gap in ipairs((res.unsupported or {})) do
      local evidence_title = ((gap.evidence and gap.evidence.title) or gap.evidence_title)
      if evidence_title then
        add_report_line_21(lines, "gold", ("Missing evidence: " .. evidence_title))
      else
      end
      for _0, missing in ipairs((gap.missing or {})) do
        add_report_line_21(lines, "gold", ("Needs: " .. (missing.title or "Required record")))
      end
    end
    for _, conflict in ipairs((res.contradictions or {})) do
      add_report_line_21(lines, "rust", ("Statement: " .. (conflict.statement_title or "Filed statement")))
      add_report_line_21(lines, "rust", ("Conflicts with: " .. (conflict.evidence_title or "Filed evidence")))
      add_report_line_21(lines, "rust", (conflict.reason_title or "The two records cannot both hold."))
    end
    add_report_line_21(lines, "muted", string.format("%d competing accounts remain.", #(res.alternatives or {})))
  else
  end
  return lines
end
local function draw_theory()
  topbar_21("THEORY", "TEST")
  nav_21()
  rect_21(60, 110, 600, 540, palette.panel, palette.line)
  set_font(16, false)
  text_21("Test a story.", 80, 130, 560, "left", palette.muted)
  if not state.theory.result then
    for i, s in ipairs(suspects) do
      local function _179_()
        state.theory["suspect"] = s.id
        return nil
      end
      local function _180_()
        if (state.theory.suspect == s.id) then
          return "accent"
        else
          return nil
        end
      end
      add_button(s.name, 80, (150 + ((i - 1) * 28)), 180, 24, _179_, _180_())
    end
  else
  end
  set_font(14, true)
  text_21(string.upper(tostring(state.theory.suspect)), 300, 155, 200, "left", palette.gold)
  local function _182_()
    state.theory["mode"] = "evidence"
    return nil
  end
  local function _183_()
    if (state.theory.mode == "evidence") then
      return "accent"
    else
      return nil
    end
  end
  add_button("File", 300, 185, 60, 24, _182_, _183_())
  local function _184_()
    state.theory["mode"] = "motive"
    return nil
  end
  local function _185_()
    if (state.theory.mode == "motive") then
      return "accent"
    else
      return nil
    end
  end
  add_button("Why", 365, 185, 50, 24, _184_, _185_())
  local function _186_()
    state.theory["mode"] = "method"
    return nil
  end
  local function _187_()
    if (state.theory.mode == "method") then
      return "accent"
    else
      return nil
    end
  end
  add_button("How", 420, 185, 50, 24, _186_, _187_())
  local function _188_()
    state.theory["mode"] = "opportunity"
    return nil
  end
  local function _189_()
    if (state.theory.mode == "opportunity") then
      return "accent"
    else
      return nil
    end
  end
  add_button("When", 475, 185, 60, 24, _188_, _189_())
  if state.theory.result then
    local lines = theory_report_lines(state.theory.result)
    local per_page = 10
    local pages = math.max(1, math.ceil((math.max(#lines, 1) / per_page)))
    local page = math.max(1, math.min((state.theory_report_page or 1), pages))
    local start = (1 + ((page - 1) * per_page))
    local finish = math.min(#lines, (start + per_page + -1))
    state["theory_report_page"] = page
    for i = start, finish do
      local line = lines[i]
      local y = (220 + ((i - start) * 22))
      set_font(11, (line.tone == "ink"))
      text_21(line.text, 80, y, 560, "left", (palette[line.tone] or palette.muted))
    end
    if (pages > 1) then
      local function _190_()
        state["theory_report_page"] = math.max(1, (page - 1))
        return nil
      end
      add_button("PREV", 250, 500, 72, 28, _190_)
      set_font(10, true)
      text_21(string.format("%d / %d", page, pages), 330, 508, 60, "center", palette.muted)
      local function _191_()
        state["theory_report_page"] = math.min(pages, (page + 1))
        return nil
      end
      add_button("NEXT", 410, 500, 72, 28, _191_)
    else
    end
  else
    set_font(11, true)
    text_21("Filed records", 300, 130, 300, "left", palette.muted)
    theory_map_21(80, 320)
    set_font(10, true)
    text_21("LENS MAP / PICK ONE ANGLE", 80, 440, 240, "left", palette.muted)
    local y = 220
    for _, item in ipairs(evidence_data) do
      if (has_3f(item.id) and (y < 520)) then
        local active = state.theory[state.theory.mode][item.id]
        local label
        local _193_
        if active then
          _193_ = "[x] "
        else
          _193_ = "[ ] "
        end
        label = (_193_ .. item.title)
        local function _195_()
          return toggle_theory_21(item.id)
        end
        local function _196_()
          if active then
            return "accent"
          else
            return nil
          end
        end
        add_button(label, 300, y, 300, 18, _195_, _196_())
        y = (y + 20)
      else
      end
    end
  end
  add_button("Test this story", 300, 560, 140, 36, evaluate_theory_21, "accent")
  local function _199_()
    state["screen"] = "accuse"
    return nil
  end
  add_button("Take it to accuse", 455, 560, 165, 36, _199_)
  local function _200_()
    state["screen"] = "board"
    return nil
  end
  add_button("Back to the board", 455, 612, 165, 28, _200_)
  if state.theory.result then
    local function _201_()
      state.theory["result"] = nil
      return nil
    end
    return add_button("Edit theory", 300, 612, 140, 28, _201_)
  else
    return nil
  end
end
local function draw_accuse()
  topbar_21("ACCUSE", "WHO")
  nav_21()
  rect_21(60, 110, 600, 530, palette.panel, palette.line)
  set_font(12, true)
  text_21("Who am I naming?", 80, 130, 200, "left", palette.muted)
  for i, s in ipairs(suspects) do
    local function _203_()
      state["accused"] = s.id
      state.accusation["suspect"] = s.id
      return nil
    end
    local function _204_()
      if (state.accused == s.id) then
        return "accent"
      else
        return nil
      end
    end
    add_button(s.name, 80, (150 + ((i - 1) * 32)), 190, 26, _203_, _204_())
  end
  set_font(22, false)
  text_21(string.upper(tostring(state.accused)), 300, 155, 300, "left", palette.gold)
  set_font(11, true)
  text_21("File for:", 300, 185, 100, "left", palette.muted)
  local function _205_()
    state["accusation_mode"] = "evidence"
    return nil
  end
  local function _206_()
    if (state.accusation_mode == "evidence") then
      return "accent"
    else
      return nil
    end
  end
  add_button("File", 300, 200, 80, 26, _205_, _206_())
  local function _207_()
    state["accusation_mode"] = "motive"
    return nil
  end
  local function _208_()
    if (state.accusation_mode == "motive") then
      return "accent"
    else
      return nil
    end
  end
  add_button("Why", 385, 200, 60, 26, _207_, _208_())
  local function _209_()
    state["accusation_mode"] = "method"
    return nil
  end
  local function _210_()
    if (state.accusation_mode == "method") then
      return "accent"
    else
      return nil
    end
  end
  add_button("How", 450, 200, 60, 26, _209_, _210_())
  local function _211_()
    state["accusation_mode"] = "opportunity"
    return nil
  end
  local function _212_()
    if (state.accusation_mode == "opportunity") then
      return "accent"
    else
      return nil
    end
  end
  add_button("When", 515, 200, 60, 26, _211_, _212_())
  set_font(11, true)
  text_21("Checked stays.", 300, 230, 300, "left", palette.muted)
  local y = 255
  for _, item in ipairs(evidence_data) do
    if (has_3f(item.id) and (y < 520)) then
      local active = state.accusation[state.accusation_mode][item.id]
      local label
      local _213_
      if active then
        _213_ = "[x] "
      else
        _213_ = "[ ] "
      end
      label = (_213_ .. item.title)
      local function _215_()
        return toggle_accusation_evidence_21(item.id)
      end
      local function _216_()
        if active then
          return "accent"
        else
          return nil
        end
      end
      add_button(label, 300, y, 320, 18, _215_, _216_())
      y = (y + 20)
    else
    end
  end
  set_font(10, true)
  text_21(string.format("%d in file / %d other accounts possible", state.clues, #state.alternatives), 80, 535, 190, "left", palette.muted)
  case_structure_21(80, 330, 180)
  set_font(11, true)
  text_21("Selections, not proof.", 80, 468, 190, "left", palette.muted)
  add_button("Submit", 300, 535, 120, 32, submit_accusation_21, "accent")
  local function _218_()
    state["screen"] = "investigate"
    return nil
  end
  add_button("Keep looking", 430, 535, 120, 32, _218_)
  add_button("Not enough", 300, 587, 120, 28, close_insufficient_21)
  local function _219_()
    state["screen"] = "theory"
    return nil
  end
  return add_button("Theory", 430, 587, 100, 28, _219_)
end
local function draw_ending()
  panel_fill_21(0, 0, W, H, palette.paper)
  local win = (state.ending == "conviction")
  local function _220_()
    if win then
      return palette.green
    else
      return palette.rust
    end
  end
  love.graphics.setColor(_220_())
  love.graphics.rectangle("fill", 0, 0, 10, H)
  set_font(13, true)
  text_21("CASE REPORT / 001", 72, 78, 300, "left", palette.gold)
  local titles = {conviction = "CASE PROVEN", lucky_idiot = "CORRECT SUSPECT\nCASE UNPROVEN", beautiful_theory = "GOOD THEORY\nWEAK EVIDENCE", insufficient_evidence = "NO CONVICTION", detective = "CASE REMAINS OPEN", everybody_goes_home = "NO CHARGE"}
  set_font(30, true)
  text_21((titles[state.ending] or "CASE REVIEW INCOMPLETE"), 72, 140, 360, "left", palette.ink)
  verdict_chart_21(460, 150, 200)
  district_art_21(460, 300, 200, 140)
  set_font(11, true)
  text_21("CASE AREA / SCHEMATIC", 460, 454, 210, "left", palette.muted)
  if state.ending_report then
    set_font(16, false)
    local _221_
    if state.ending_report.unique_solution then
      _221_ = "No viable alternative remains in the submitted proof."
    else
      _221_ = "The visible record still leaves another account open."
    end
    text_21(_221_, 74, 300, 360, "left", palette.muted)
    if state.ending_report.motive then
      text_21(("Motive: " .. tostring(state.ending_report.motive)), 74, 345, 360, "left", palette.ink)
      text_21(("Method: " .. tostring(state.ending_report.method)), 74, 368, 360, "left", palette.ink)
      text_21(("Opportunity: " .. tostring(state.ending_report.opportunity)), 74, 391, 360, "left", palette.ink)
    else
    end
    if state.ending_report.selected_evidence then
      text_21(string.format("%d selected records were evaluated.", #state.ending_report.selected_evidence), 74, 424, 360, "left", palette.gold)
    else
    end
    if state.ending_report.unsupported then
      text_21(string.format("%d unsupported parts in the submitted argument.", #state.ending_report.unsupported), 74, 447, 360, "left", palette.gold)
    else
    end
  else
  end
  local function _227_()
    state["screen"] = "title"
    state["evidence"] = {}
    state["clues"] = 0
    state["ending"] = nil
    return nil
  end
  return add_button("Back to title", 72, 604, 160, 40, _227_)
end
local function draw_pause()
  panel_fill_21(0, 0, W, H, palette.paper)
  topbar_21("PAUSE", "I STEPPED AWAY FROM THE FILE")
  rect_21(120, 200, 480, 320, palette.panel, palette.line)
  set_font(24, false)
  text_21("Paused. The cafe waits.", 150, 230, 420, "left", palette.ink)
  local function _228_()
    state["screen"] = "investigate"
    return nil
  end
  add_button("Go back", 150, 290, 180, 40, _228_, "accent")
  local function _229_()
    state["screen"] = "settings"
    return nil
  end
  add_button("Settings", 150, 335, 180, 40, _229_)
  add_button("Save this file", 150, 380, 180, 40, save_state_21)
  local function _230_()
    state["screen"] = "load_record"
    return nil
  end
  add_button("Open a saved file", 150, 425, 180, 40, _230_)
  local function _231_()
    state["screen"] = "title"
    return nil
  end
  return add_button("Close and go to title", 150, 470, 220, 40, _231_)
end
local function draw_settings()
  panel_fill_21(0, 0, W, H, palette.paper)
  topbar_21("SETTINGS", "MAKE THE FILE EASIER TO READ")
  rect_21(100, 180, 520, 400, palette.panel, palette.line)
  set_font(24, false)
  text_21("Less motion", 130, 220, 300, "left", palette.ink)
  set_font(13, false)
  text_21("I turn off grain and other movement that is not needed.", 130, 245, 440, "left", palette.muted)
  local _232_
  if state.settings.reducedMotion then
    _232_ = "On"
  else
    _232_ = "Off"
  end
  local function _234_()
    state.settings["reducedMotion"] = not state.settings.reducedMotion
    return nil
  end
  add_button(_232_, 130, 280, 100, 36, _234_)
  local function _235_()
    state["screen"] = "pause"
    return nil
  end
  return add_button("Back", 130, 520, 120, 36, _235_)
end
local function draw_load_record()
  panel_fill_21(0, 0, W, H, palette.paper)
  topbar_21("CASE RECORD", "KEEP OR REOPEN THE FILE")
  rect_21(100, 180, 520, 400, palette.panel, palette.line)
  set_font(24, false)
  text_21("My file on disk", 130, 220, 400, "left", palette.ink)
  set_font(12, false)
  text_21("Save keeps what I have filed. Load brings it back.", 130, 244, 440, "left", palette.muted)
  add_button("Save now", 130, 300, 140, 36, save_state_21, "accent")
  add_button("Load it", 290, 300, 140, 36, load_state_21)
  local function _236_()
    state["screen"] = "investigate"
    return nil
  end
  return add_button("Back to the cafe", 130, 500, 170, 36, _236_)
end
local function draw_people()
  topbar_21("PEOPLE", "FIVE NAMES")
  nav_21()
  rect_21(40, 90, 640, 500, palette.panel, palette.line)
  set_font(11, true)
  text_21("Talk to someone. Start anywhere.", 80, 110, 560, "left", palette.muted)
  for i, s in ipairs(suspects) do
    local y = (142 + ((i - 1) * 88))
    rect_21(56, (y - 4), 608, 76, palette["paper-light"])
    suspect_portrait_21(s.id, 64, y, 64, 64)
    set_font(24, false)
    text_21(s.name, 144, (y + 3), 200, "left", palette.ink)
    set_font(12, true)
    text_21(s.role, 144, (y + 31), 200, "left", palette.gold)
    set_font(12, true)
    text_21(suspect_note(s.id), 356, (y + 4), 192, "left", palette.muted)
    local function _237_()
      return open_interview_21(s.id)
    end
    add_button("Talk", 568, (y + 16), 80, 32, _237_, "accent")
  end
  local function _238_()
    state["screen"] = "investigate"
    return nil
  end
  return add_button("Map", 40, 612, 100, 32, _238_)
end
local function restore_dialogue_if_needed_21()
  if ((state.screen == "dialogue") and (not state.ink_text or (state.ink_text == "") or (#state.ink_choices == 0))) then
    do
      local payload = {knot = state.current_person, variables = known_ink_vars()}
      if state.ink_state then
        payload["state"] = state.ink_state
      else
      end
      local result = ink.request("goto", payload)
      if (result and result.ok) then
        apply_ink_21(result)
      else
      end
    end
    if (not state.ink_text or (state.ink_text == "")) then
      state["ink_text"] = (string.upper(tostring(state.current_person)) .. ": \226\128\166")
      if (#state.ink_choices == 0) then
        state["ink_choices"] = {{text = "LEAVE INTERVIEW", index = 0}}
        return nil
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function draw_dialogue()
  restore_dialogue_if_needed_21()
  panel_fill_21(0, 0, W, H, console.paper)
  panel_fill_21(32, 96, 296, 440, {0.105, 0.115, 0.11})
  panel_fill_21(44, 110, 268, 210, {0.18, 0.19, 0.175})
  for i = 0, 8 do
    local y = (116 + (i * 23))
    panel_fill_21(44, y, 268, 3, {0.09, 0.11, 0.105})
    hairline_21(44, (y + 3), 312, (y + 3), {0.26, 0.265, 0.23})
  end
  panel_fill_21(44, 318, 268, 16, {0.31, 0.28, 0.2})
  panel_fill_21(44, 334, 268, 186, {0.13, 0.15, 0.145})
  suspect_portrait_21(state.current_person, 36, 100, 288, 432, true)
  scanlines_21()
  clipped_frame_21(32, 96, 296, 440, console.edge)
  hairline_21(32, 96, 96, 96, console.sodium)
  hairline_21(32, 96, 32, 160, console.sodium)
  hairline_21(264, 536, 328, 536, console.sodium)
  hairline_21(328, 472, 328, 536, console.sodium)
  topbar_21("INTERVIEW", "CAFE")
  nav_21()
  for _, person in ipairs(suspects) do
    if (person.id == state.current_person) then
      if fonts.display then
        love.graphics.setFont(fonts.display)
      else
        set_font(32, false)
      end
      text_21(person.name, 36, 549, 288, "left", console.ink)
      set_font(13, true)
      text_21(person.role, 38, 585, 288, "left", console.sodium)
    else
    end
  end
  rect_21(348, 96, 340, 280, console.panel, console.edge)
  clipped_frame_21(352, 100, 332, 272, {0.2, 0.23, 0.23})
  set_font(12, true)
  text_21("STATEMENT", 368, 114, 296, "left", console.sodium)
  hairline_21(368, 139, 668, 139, console.edge)
  set_font(16, false)
  text_21((state.ink_text or "\226\128\166"), 368, 158, 300, "left", console.ink)
  set_font(12, true)
  text_21("ASK", 350, 394, 240, "left", console.muted)
  hairline_21(392, 400, 688, 400, console.edge)
  if state.ink_can_continue then
    add_button("Continue", 348, 420, 340, 26, continue_interview_21, "accent")
  elseif (#state.ink_choices > 0) then
    local page_size = 6
    local start = (1 + ((state.dialogue_page - 1) * page_size))
    local finish = math.min(#state.ink_choices, (start + page_size + -1))
    local pages = math.max(1, math.ceil((#state.ink_choices / page_size)))
    for i = start, finish do
      local choice = state.ink_choices[i]
      local function _246_()
        return choose_interview_21(choice)
      end
      add_button(choice.text, 348, (420 + ((i - start) * 30)), 340, 26, _246_)
    end
    if (pages > 1) then
      local function _247_()
        state["dialogue_page"] = math.max(1, (state.dialogue_page - 1))
        return nil
      end
      add_button("Prev", 348, 616, 80, 28, _247_)
      set_font(12, true)
      text_21(string.format("%d / %d", state.dialogue_page, pages), 464, 623, 108, "center", console.muted)
      local function _248_()
        state["dialogue_page"] = math.min(pages, (state.dialogue_page + 1))
        return nil
      end
      add_button("Next", 608, 616, 80, 28, _248_)
    else
    end
  else
    local function _250_()
      state["screen"] = "people"
      return nil
    end
    add_button("Leave", 348, 420, 340, 26, _250_, "accent")
  end
  local function _252_()
    state["screen"] = "people"
    return nil
  end
  add_button("Back", 36, 616, 100, 30, _252_)
  hairline_21(32, layout.FOOTER_Y, 688, layout.FOOTER_Y, console.edge)
  set_font(12, true)
  text_21("TAB  Move     ENTER  Select", 36, (layout.FOOTER_Y + 10), 370, "left", console.muted)
  return text_21("ESC  Pause", 508, (layout.FOOTER_Y + 10), 180, "right", console.muted)
end
local function change_view_21()
  local _253_
  if (state.location_view == 2) then
    _253_ = 1
  else
    _253_ = 2
  end
  state["location_view"] = _253_
  return nil
end
local function draw_location()
  local location
  if location_data[state.location] then
    location = state.location
  else
    location = "cafe"
  end
  local info = location_data[location]
  local view
  if (state.location_view == 2) then
    view = 2
  else
    view = 1
  end
  topbar_21(info.name, "INSPECTION")
  nav_21()
  set_font(13, false)
  text_21(info.note, 40, 92, 640, "left", palette.ink)
  panel_fill_21(40, 112, 640, 352, palette["paper-light"])
  do
    local ready = spaces.draw(location, view, 40, 112, 640, 352)
    clipped_frame_21(40, 112, 640, 352, palette.line)
    if not ready then
      set_font(16, false)
      text_21("3D view unavailable. Use the inspection list below.", 80, 260, 560, "center", palette.muted)
    else
    end
    for i, route in ipairs(info.evidence) do
      local id = route[1]
      local point = spaces.point(location, route[1])
      local p = (ready and point and spaces.project(location, view, point))
      local x = (40 + (math.fmod((i - 1), 2) * 328))
      local y = (486 + (math.floor(((i - 1) / 2)) * 38))
      if p then
        local function _258_()
          return add_21(id)
        end
        local function _259_()
          if has_3f(id) then
            return "accent"
          else
            return nil
          end
        end
        add_button(string.format("%02d", i), ((40 + (p[1] * 640)) - 14), ((112 + (p[2] * 352)) - 12), 28, 24, _258_, _259_())
      else
      end
      local _261_
      if has_3f(id) then
        _261_ = "[x] "
      else
        _261_ = "[ ] "
      end
      local function _263_()
        return add_21(id)
      end
      local function _264_()
        if has_3f(id) then
          return "accent"
        else
          return nil
        end
      end
      add_button((string.format("%02d ", i) .. _261_ .. route[2]), x, y, 312, 30, _263_, _264_())
    end
  end
  add_button("Change view", 40, 616, 160, 32, change_view_21)
  set_font(12, true)
  local _265_
  if (view == 1) then
    _265_ = "Right view"
  else
    _265_ = "Left view"
  end
  text_21(("V  /  " .. _265_), 216, 625, 280, "left", palette.muted)
  local function _267_()
    state["screen"] = "investigate"
    return nil
  end
  return add_button("Area map", 552, 616, 128, 32, _267_)
end
local function prepare_capture_21(name)
  local all_evidence = {}
  for _, item in ipairs(evidence_data) do
    all_evidence[item.id] = true
  end
  if (name == "title") then
    state["screen"] = "title"
  elseif (name == "location") then
    state["screen"] = "location"
    state["location"] = "cafe"
    state["location_view"] = 1
    focus_index = 7
  elseif (name == "dialogue") then
    state["screen"] = "dialogue"
    focus_index = 7
    state["evidence"] = {receipt_004 = true}
    state["current_person"] = "mira"
    state["ink_text"] = "MIRA: I left at ten past seven. If you have a later time, show me."
    state["ink_choices"] = {{index = 0, text = "Where did you go afterward?"}, {index = 1, text = "Present Receipt #004"}, {index = 2, text = "Leave the interview"}}
    state["ink_state"] = nil
  elseif (name == "evidence-detail") then
    state["screen"] = "evidence_detail"
    state["evidence"] = {receipt_004 = true}
    state["evidence_detail"] = "receipt_004"
    state["proof_data"] = {{fact = "mira_departure_conflict", conclusion = "Mira's departure claim is contradicted.", rule = "purchase_requires_presence", premises = {{id = "receipt_004", title = "Receipt #004"}}}}
  elseif (name == "contradiction") then
    state["screen"] = "contradiction"
    state["evidence"] = {receipt_004 = true}
    state.heard_statements["mira_left_1910"] = true
  elseif (name == "people") then
    state["screen"] = "people"
    state["evidence"] = all_evidence
    state["clues"] = 13
  elseif (name == "timeline") then
    state["screen"] = "timeline"
    state["evidence"] = all_evidence
    state["timeline_page"] = 2
    state["contradiction"] = true
  elseif (name == "board") then
    state["screen"] = "board"
    state["evidence"] = {receipt_004 = true, camera_log = true, cup_lid = true, pharmacy_footage = true, draft_email = true}
    state.heard_statements["mira_left_1910"] = true
  elseif (name == "accusation") then
    state["screen"] = "accuse"
    state["evidence"] = all_evidence
    state["clues"] = 13
    state.accusation["evidence"] = {toxicology = true, pharmacy_footage = true, cup_lid = true, draft_email = true, service_log = true}
    state.accusation["motive"] = {draft_email = true}
    state.accusation["method"] = {toxicology = true, pharmacy_footage = true, cup_lid = true}
    state.accusation["opportunity"] = {service_log = true}
  elseif (name == "case-report") then
    state["screen"] = "ending"
    state["ending"] = "lucky_idiot"
    state["ending_report"] = {motive = "supported", method = "partial", opportunity = "supported", selected_evidence = {{id = "draft_email"}}, unsupported = {{code = "required_evidence_missing"}}, unique_solution = false}
  else
    state["screen"] = "title"
  end
  local count = 0
  for _, _0 in pairs(state.evidence) do
    count = (count + 1)
  end
  state["clues"] = count
  return nil
end
love.load = function()
  love.window.setMode(W, H, {resizable = true, minwidth = 600, minheight = 600})
  love.window.setTitle("ondacase / Case 001")
  love.graphics.setDefaultFilter("nearest", "nearest")
  for _, s in ipairs({10, 11, 12, 13, 14, 15, 16, 18, 19, 22, 24, 27, 28, 29, 30, 32, 42, 48, 58}) do
    local mono_path = "assets/fonts/IBMPlexMono-Medium.ttf"
    local serif_path = "assets/fonts/Newsreader16pt-Regular.ttf"
    local mfont
    if love.filesystem.getInfo(mono_path) then
      mfont = love.graphics.newFont(mono_path, s)
    else
      mfont = love.graphics.newFont(s)
    end
    local sfont
    if love.filesystem.getInfo(serif_path) then
      sfont = love.graphics.newFont(serif_path, s)
    else
      sfont = love.graphics.newFont(s)
    end
    fonts[("m" .. s)] = mfont
    fonts[("s" .. s)] = sfont
    fonts[("c" .. s)] = nil
    fonts[("d" .. s)] = nil
    if love.filesystem.getInfo("assets/fonts/ShareTechMono-Regular.ttf") then
      fonts[("c" .. s)] = love.graphics.newFont("assets/fonts/ShareTechMono-Regular.ttf", s)
    else
    end
    if love.filesystem.getInfo("assets/fonts/VT323-Regular.ttf") then
      fonts[("d" .. s)] = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", s)
    else
    end
  end
  fonts["display"] = nil
  if love.filesystem.getInfo("assets/fonts/VT323-Regular.ttf") then
    fonts["display"] = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 38)
    fonts.display:setFilter("linear", "linear")
  else
  end
  if love.filesystem.getInfo("assets/cafe/composed.png") then
    art["cafe_composed"] = love.graphics.newImage("assets/cafe/composed.png")
    art.cafe_composed:setFilter("linear", "linear")
  else
  end
  art["district"] = nil
  if love.filesystem.getInfo("assets/map/district.png") then
    art["district"] = love.graphics.newImage("assets/map/district.png")
    art.district:setFilter("nearest", "nearest")
  else
  end
  if love.filesystem.getInfo("assets/cafe-lantern.png") then
    art["cafe"] = love.graphics.newImage("assets/cafe-lantern.png")
    art.cafe:setFilter("linear", "linear")
  else
  end
  art["portraits"] = {}
  art["portrait_crops"] = {}
  for _, id in ipairs({"mira", "arin", "jo", "sasha", "dan"}) do
    local psx_path = ("assets/suspects/" .. tostring(id) .. "-psx.png")
    local psx = love.filesystem.getInfo(psx_path)
    local path
    if psx then
      path = psx_path
    else
      path = ("assets/suspects/" .. tostring(id) .. ".png")
    end
    if love.filesystem.getInfo(path) then
      local img = love.graphics.newImage(path)
      local _278_
      if psx then
        _278_ = "nearest"
      else
        _278_ = "linear"
      end
      local function _280_()
        if psx then
          return "nearest"
        else
          return "linear"
        end
      end
      img:setFilter(_278_, _280_())
      if psx then
        art.portrait_crops[id] = love.graphics.newQuad(16, 8, 112, 112, img:getWidth(), img:getHeight())
      else
      end
      art.portraits[id] = img
    else
    end
  end
  if love.filesystem.getInfo("assets/suspects-sheet.png") then
    art["suspects"] = love.graphics.newImage("assets/suspects-sheet.png")
    art.suspects:setFilter("linear", "linear")
  else
  end
  if love.filesystem.getInfo("assets/locations-sheet.png") then
    art["locations"] = love.graphics.newImage("assets/locations-sheet.png")
    art.locations:setFilter("linear", "linear")
  else
  end
  logic_sync()
  spaces.load()
  if capture_name then
    return prepare_capture_21(capture_name)
  else
    return nil
  end
end
love.update = function(dt)
  if (state.toast_time > 0) then
    state["toast_time"] = (state.toast_time - dt)
    if (state.toast_time <= 0) then
      state["toast"] = nil
    else
    end
  else
  end
  if capture_done then
    return love.event.quit()
  else
    return nil
  end
end
love.draw = function()
  focusable = {}
  buttons = {}
  local dw = love.graphics.getDimensions()
  local dh = select(2, love.graphics.getDimensions())
  local calc = layout.calc(dw, dh)
  scale_state["scale"] = calc.scale
  scale_state["ox"] = calc.ox
  scale_state["oy"] = calc.oy
  love.graphics.clear({0.05, 0.05, 0.05})
  love.graphics.push()
  love.graphics.translate(calc.ox, calc.oy)
  love.graphics.scale(calc.scale, calc.scale)
  love.graphics.setScissor(calc.ox, calc.oy, calc.sw, calc.sh)
  panel_fill_21(0, 0, W, H, palette.paper)
  if (state.screen == "title") then
    draw_title()
  elseif (state.screen == "case_select") then
    draw_case_select()
  elseif (state.screen == "investigate") then
    draw_investigate()
  elseif (state.screen == "location") then
    draw_location()
  elseif (state.screen == "people") then
    draw_people()
  elseif (state.screen == "dialogue") then
    draw_dialogue()
  elseif (state.screen == "evidence") then
    draw_evidence()
  elseif (state.screen == "evidence_detail") then
    draw_evidence_detail()
  elseif (state.screen == "timeline") then
    draw_timeline()
  elseif (state.screen == "contradiction") then
    draw_contradiction()
  elseif (state.screen == "proof") then
    draw_proof()
  elseif (state.screen == "board") then
    draw_board()
  elseif (state.screen == "theory") then
    draw_theory()
  elseif (state.screen == "accuse") then
    draw_accuse()
  elseif (state.screen == "ending") then
    draw_ending()
  elseif (state.screen == "pause") then
    draw_pause()
  elseif (state.screen == "settings") then
    draw_settings()
  elseif (state.screen == "load_record") then
    draw_load_record()
  else
    draw_title()
  end
  if (#focusable > 0) then
    if (focus_index > #focusable) then
      focus_index = 1
    else
    end
    if (focus_index < 1) then
      focus_index = #focusable
    else
    end
  else
  end
  ambiance_21()
  if (state.toast and (state.toast_time > 0)) then
    local toast_x
    if (state.screen == "case_select") then
      toast_x = 300
    else
      toast_x = 190
    end
    local toast_y
    if (state.screen == "title") then
      toast_y = 250
    else
      if (state.screen == "case_select") then
        toast_y = 500
      else
        if (state.screen == "ending") then
          toast_y = 250
        else
          toast_y = 60
        end
      end
    end
    rect_21(toast_x, toast_y, 340, 28, palette.gold)
    set_font(12, true)
    text_21(state.toast, (toast_x + 15), (toast_y + 8), 310, "center", palette.paper)
  else
  end
  if (state.screen ~= "dialogue") then
    hairline_21(32, layout.FOOTER_Y, 688, layout.FOOTER_Y, palette.line)
    set_font(12, true)
    text_21("TAB  Move   ENTER  Select", 36, (layout.FOOTER_Y + 10), 350, "left", palette.muted)
    text_21("M  Map   ESC  Pause", 416, (layout.FOOTER_Y + 10), 270, "right", palette.muted)
  else
  end
  love.graphics.setScissor()
  love.graphics.pop()
  if (capture_name and capture_path and not capture_requested) then
    capture_requested = true
    local function _299_(image_data)
      local encoded = image_data:encode("png")
      local file = io.open(capture_path, "wb")
      if file then
        file:write(encoded:getString())
        file:close()
      else
      end
      capture_done = true
      return nil
    end
    return love.graphics.captureScreenshot(_299_)
  else
    return nil
  end
end
love.mousemoved = function(x, y, dx, dy)
  return update_hover_21(x, y)
end
love.mousepressed = function(x, y, b)
  if (b ~= 1) then
    return
  else
  end
  local dw = love.graphics.getDimensions()
  local dh = select(2, love.graphics.getDimensions())
  local calc = layout.calc(dw, dh)
  local lx = ((x - calc.ox) / calc.scale)
  local ly = ((y - calc.oy) / calc.scale)
  if not layout["in-logical?"](lx, ly) then
    return
  else
  end
  update_hover_21(x, y)
  for i, v in ipairs(buttons) do
    if ((lx >= v.x) and (lx <= (v.x + v.w)) and (ly >= v.y) and (ly <= (v.y + v.h))) then
      focus_index = i
      v.action()
      return
    else
    end
  end
  return nil
end
love.keypressed = function(k)
  do
    local ctrl = (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"))
    if ((k == "s") and ctrl) then
      save_state_21()
      return
    else
    end
    if ((k == "l") and ctrl) then
      load_state_21()
      return
    else
    end
  end
  if (k == "tab") then
    if (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
      focus_index = (focus_index - 1)
    else
      focus_index = (focus_index + 1)
    end
  elseif (k == "up") then
    focus_index = (focus_index - 1)
  elseif (k == "down") then
    focus_index = (focus_index + 1)
  elseif (k == "left") then
    focus_index = (focus_index - 1)
  elseif (k == "right") then
    focus_index = (focus_index + 1)
  elseif ((k == "return") or (k == "space") or (k == "kpenter")) then
    if (focusable and focus_index and focusable[focus_index]) then
      focusable[focus_index]()
    else
    end
  elseif (k == "escape") then
    if ((state.screen == "pause") or (state.screen == "settings") or (state.screen == "load_record") or (state.screen == "contradiction") or (state.screen == "evidence_detail")) then
      state["screen"] = (state.prev_screen or "investigate")
    elseif (state.screen ~= "title") then
      state["screen"] = "pause"
    else
    end
  elseif (k == "e") then
    state["screen"] = "evidence"
  elseif (k == "t") then
    state["screen"] = "timeline"
  elseif (k == "b") then
    state["screen"] = "board"
  elseif (k == "a") then
    state["screen"] = "accuse"
  elseif (k == "h") then
    state["screen"] = "theory"
  elseif (k == "m") then
    state["screen"] = "investigate"
  elseif ((k == "v") and (state.screen == "location")) then
    change_view_21()
  elseif (k == "p") then
    state["screen"] = "pause"
  else
  end
  if (#focusable > 0) then
    if (focus_index > #focusable) then
      focus_index = 1
    else
    end
    if (focus_index < 1) then
      focus_index = #focusable
      return nil
    else
      return nil
    end
  else
    return nil
  end
end
local function _314_()
  return focus_index
end
local function _315_(v)
  focus_index = v
  return nil
end
local function _316_()
  return #focusable
end
local function _317_()
  return hover_index
end
local function _318_(v)
  hover_index = v
  return nil
end
_G["ondacase_focus"] = {get = _314_, set = _315_, count = _316_, hover = _317_, set_hover = _318_}
local route_evidence
do
  local out = {tape_fiber = "arin_interview", mira_statement = "mira_interview"}
  for _, loc in ipairs(case_manifest.locations) do
    for _0, route in ipairs(loc.evidence) do
      out[route.id] = loc.id
    end
  end
  route_evidence = out
end
_G["ondacase_routes"] = {evidence = route_evidence, statements = {mira_left_1910 = "mira_interview", arin_cough_drops = "arin_interview", jo_saw_cup_1921 = "jo_interview", jo_identified_mira = "jo_interview", sasha_never_argued = "sasha_interview", dan_never_inside = "dan_interview", dan_route_recollection = "dan_interview"}}
_G["ondacase_runtime"] = {discover = add_21, record_statement = record_statement_21, logic_sync = logic_sync, open_interview = open_interview_21, continue_interview = continue_interview_21, choose_interview = choose_interview_21, apply_ink = apply_ink_21, visit = visit_location_21, toggle_evidence = toggle_accusation_evidence_21, accusation_payload = accusation_payload, submit_accusation = submit_accusation_21, close_insufficient = close_insufficient_21, evaluate_theory = evaluate_theory_21, theory_report_lines = theory_report_lines, save_state = save_state_21, load_state = load_state_21, maybe_contradiction = maybe_trigger_contradiction_21, timeline_visible = timeline_visible, board_visible = board_visible_nodes}
return nil
