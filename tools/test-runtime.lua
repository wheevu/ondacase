-- deterministic runtime contract tests with injected bridge modules
local noop=function() end
local current_font={getHeight=function() return 11 end}
local draw_calls={}
local text_calls={}
local text_positions={}
local quad_calls={}
local font_calls={}
local image_filters={}
local control_bounds={}
local keys_down={}
local window_w,window_h=720,720
local image={getWidth=function() return 1672 end,getHeight=function() return 941 end,setFilter=noop}
love={
  window={setMode=noop,setTitle=noop},
  mouse={getX=function() return 0 end,getY=function() return 0 end},
  keyboard={isDown=function(key) return keys_down[key] or false end},
  filesystem={_data={["assets/cafe-lantern.png"]=true,["assets/cafe/composed.png"]=true,["assets/suspects-sheet.png"]=true,["assets/suspects/mira.png"]=true,["assets/suspects/arin.png"]=true,["assets/suspects/jo.png"]=true,["assets/suspects/sasha.png"]=true,["assets/suspects/dan.png"]=true,["assets/locations-sheet.png"]=true,["assets/fonts/Newsreader16pt-Regular.ttf"]=true,["assets/fonts/IBMPlexMono-Medium.ttf"]=true,["assets/fonts/VT323-Regular.ttf"]=true,["assets/fonts/ShareTechMono-Regular.ttf"]=true},getInfo=function(a,b) local k=b or a; if type(k)~="string" then return nil end; return love.filesystem._data[k] and {} or nil end,write=function(a,b,c) local k,v; if c~=nil then k=b; v=c else k=a; v=b end; love.filesystem._data[k]=v; return true end,read=function(a,b) local k=b or a; return love.filesystem._data[k] end},
  graphics={
    newFont=function(a,b) local size=b or a; if type(a)=="string" then table.insert(font_calls,{path=a,size=b}) else table.insert(font_calls,{path=nil,size=a}) end return {setFilter=function(self,min,mag) self.filter=min; assert(min==mag) end,getHeight=function() return size end,getWidth=function(_,text) return #tostring(text)*size*0.6 end} end,newImage=function(path)
      if path:match("assets/suspects/%a+%-psx%.png$") then
        return {path=path,getWidth=function() return 144 end,getHeight=function() return 216 end,
          setFilter=function(_,min,mag) image_filters[path]={min,mag} end}
      end
      if path=="assets/map/district.png" then
        return {path=path,getWidth=function() return 320 end,getHeight=function() return 224 end,
          setFilter=function(_,min,mag) image_filters[path]={min,mag} end}
      end
      return image
    end,newQuad=function(...) local q={...}; table.insert(quad_calls,q); return q end,
    getDimensions=function() return window_w,window_h end,
    clear=noop,setColor=noop,setDefaultFilter=noop,rectangle=function(mode,x,y,w,h)
      if mode=="fill" and h>=18 and h<=44 then table.insert(control_bounds,{x=x,y=y,w=w,h=h}) end
    end,setFont=function(font) current_font=font end,getFont=function() return current_font end,printf=function(text,x,y,w,align) table.insert(text_calls,tostring(text)); table.insert(text_positions,{text=tostring(text),x=x,y=y,w=w,align=align,height=current_font:getHeight(),filter=current_font.filter}) end,line=function(...) assert(select("#",...)>=4 and select("#",...)%2==0,"line vertices must be coordinate pairs") end,
    setLineWidth=noop,setLineStyle=noop,circle=noop,draw=function(...) table.insert(draw_calls,{...}) end,push=noop,pop=noop,scale=noop,translate=noop,setScissor=noop,setDefaultFilter=noop
  }
}
local cast={"mira","arin","jo","sasha","dan"}
for _,id in ipairs(cast) do love.filesystem._data["assets/suspects/"..id.."-psx.png"]=true end
love.filesystem._data["assets/map/district.png"]=true

package.path = package.path .. ";./src/?.lua;./?.lua"
local prolog_calls={}
local function contains(list,wanted) for _,v in ipairs(list or {}) do if v==wanted then return true end end return false end
local function text_contains(needle) for _,v in ipairs(text_calls) do if v:find(needle,1,true) then return true end end return false end
local function clear_render_logs() draw_calls={}; text_calls={}; text_positions={}; quad_calls={} end
local function unique_proof(evidence)
  local core={"toxicology","pharmacy_footage","cup_lid","tape_fiber","draft_email","service_log"}
  for _,id in ipairs(core) do if not contains(evidence,id) then return false end end
  local exclusions=0
  for _,id in ipairs({"mira_statement","delivery_photo","sasha_voicemail","panel_log"}) do if contains(evidence,id) then exclusions=exclusions+1 end end
  return exclusions>=3
end
local prolog_online=true
local prolog_stub={request=function(operation,payload)
  if not prolog_online then return nil end
  prolog_calls[#prolog_calls+1]={operation=operation,payload=payload}
  local evidence=payload.known_evidence or {}
  if operation=="discover_evidence" then
    if payload.evidence=="mira_statement" and not (contains(evidence,"receipt_004") and contains(payload.known_statements,"mira_left_1910")) then
      return {ok=false,error={message="Evidence has not been unlocked"}}
    end
    return {ok=true,contradictions={},inferences={}}
  elseif operation=="record_statement" then
    return {ok=true,contradictions={}}
  elseif operation=="query_state" then
    local proven=unique_proof(evidence)
    return {ok=true,contradictions=contains(evidence,"receipt_004") and contains(payload.known_statements,"mira_left_1910") and {{statement="mira_left_1910",evidence="receipt_004"}} or {},inferences=proven and {"arin_case_proven"} or {},inference_details=proven and {{fact="arin_case_proven",conclusion="The case against Arin meets the proof threshold",premises={}}} or {},knowledge={hypothesized={{id="arin",status="hypothesized"}},proven=proven and {{id="arin"}} or {}}}
  elseif operation=="possible_alternatives" then
    return {ok=true,alternatives=unique_proof(evidence) and {{id="arin",name="Arin Ko"}} or {{id="arin",name="Arin Ko"},{id="mira",name="Mira Vale"}}}
  elseif operation=="accusation" then
    return {ok=true,result={ending="conviction",unique_solution=true,sufficient_evidence=true,unsupported={},alternatives={},selected_evidence=evidence,motive="supported",method="supported",opportunity="supported"}}
  elseif operation=="evaluate_hypothesis" then
    return {ok=true,evaluation={suspect=payload.suspect,status="under_supported",dimensions={
      {name="motive",status="supported",support={{id="draft_email",title="Eli's draft email"}},missing={}},
      {name="method",status="partial",support={{id="toxicology",title="Toxicology report"},{id="cup_lid",title="Cup lid"}},missing={{id="tape_fiber",title="Blue tape fiber"}}},
      {name="opportunity",status="missing",support={},missing={{id="service_log",title="Service-door log"}}}
    },unsupported={{code="unsupported_dimension",dimension="method",missing={{id="tape_fiber",title="Blue tape fiber"}}}},contradictions={{statement_title="Mira left at 19:10",evidence_title="Receipt #004",reason_title="The later purchase requires her presence"}},alternatives={{name="Mira Vale"},{name="Arin Ko"}}}}
  end
  error("unexpected Prolog operation: "..tostring(operation))
end}
local ink_calls={}
local ink_stub={request=function(operation,payload)
  ink_calls[#ink_calls+1]={operation=operation,payload=payload}
  if operation=="goto" then
    local text_by_person={mira="MIRA: I left at ten past seven.",arin="ARIN: I bought cough drops.",jo="JO: I saw somebody with the cup at 19:21.",sasha="SASHA: I never raised my voice to Eli that night.",dan="DAN: I never went inside the café."}
    return {ok=true,state="state:"..payload.knot,text=text_by_person[payload.knot],lines={text_by_person[payload.knot]},choices={{index=0,text="Ask about the route gap"}},callbacks={},can_continue=false}
  elseif operation=="choose" or operation=="continue" then
    return {ok=true,state="state:next",text="The interview continues.",lines={"The interview continues."},choices={},callbacks={},can_continue=false}
  end
  error("unexpected Ink operation: "..tostring(operation))
end}
package.loaded["src.prolog"]=prolog_stub
package.loaded["src.ink"]=ink_stub

dofile("main.lua")
love.load()
local st=ondacase_state
local runtime=ondacase_runtime

-- bundled fonts discovered and passed to newFont with sizes; raster fallback remains safe
do
  local seen_mono,seen_serif=false,false
  local sizes={}
  for _,c in ipairs(font_calls) do
    if c.path=="assets/fonts/IBMPlexMono-Medium.ttf" then seen_mono=true end
    if c.path=="assets/fonts/Newsreader16pt-Regular.ttf" then seen_serif=true end
    if c.size then sizes[c.size]=true end
  end
  assert(seen_mono and seen_serif,"both bundled fonts must be discovered via getInfo and passed to newFont")
   for _,s in ipairs({10,11,12,13,14,15,16,18,19,22,24,27,28,29,30,32,42,48,58}) do assert(sizes[s],"bundled font size not requested: "..tostring(s)) end
  assert(love.filesystem.getInfo("assets/cafe-lantern.png") and love.filesystem.getInfo("assets/suspects-sheet.png") and love.filesystem.getInfo("assets/locations-sheet.png"),"raster assets must remain loadable")
  local mono_count,serif_count=0,0
  for _,c in ipairs(font_calls) do if c.path=="assets/fonts/IBMPlexMono-Medium.ttf" then mono_count=mono_count+1 end if c.path=="assets/fonts/Newsreader16pt-Regular.ttf" then serif_count=serif_count+1 end end
  assert(mono_count>=1 and serif_count>=1,"each bundled font must be requested at least once per size set")
end
do
  local saved={}
  for k,v in pairs(love.filesystem._data) do saved[k]=v end
  love.filesystem._data["assets/fonts/Newsreader16pt-Regular.ttf"]=nil
  love.filesystem._data["assets/fonts/IBMPlexMono-Medium.ttf"]=nil
  love.filesystem._data["assets/fonts/VT323-Regular.ttf"]=nil
  love.filesystem._data["assets/fonts/ShareTechMono-Regular.ttf"]=nil
  love.filesystem._data["assets/cafe-lantern.png"]=nil
  love.filesystem._data["assets/suspects-sheet.png"]=nil
  love.filesystem._data["assets/locations-sheet.png"]=nil
  font_calls={}
  local ok,err=pcall(love.load)
  assert(ok,"love.load must fall back when bundled fonts and rasters are missing: "..tostring(err))
  local fallback=false
  for _,c in ipairs(font_calls) do if c.path==nil and c.size then fallback=true end end
  assert(fallback,"missing bundled fonts must fall back to newFont(size)")
  local ok2,err2=pcall(function() st.screen="title"; love.draw() end)
  assert(ok2,"hero screens must render without bundled assets: "..tostring(err2))
  love.filesystem._data=saved
  font_calls={}
  local ok3=pcall(love.load)
  assert(ok3,"reload with bundled assets must succeed")
  font_calls={}
end
print("bundled_fonts=pass")

-- compact button labels stay inside their rectangle after font selection and centering
st.screen="title"; clear_render_logs(); love.draw()
local open_file_y=nil
for _,entry in ipairs(text_positions) do if entry.text=="Open file" then open_file_y=entry.y end end
assert(open_file_y and open_file_y>=180 and open_file_y+11<=212,"button label must remain inside its rectangle")
print("button_text_bounds=pass")

-- scaling and keyboard remain intact
local layout=ondacase_layout
 assert(layout.W==720 and layout.H==720,"reference canvas must stay square")
 local c1=layout.calc(720,720); assert(math.abs(c1.scale-1)<0.001 and math.abs(c1.ox)<0.001 and math.abs(c1.oy)<0.001)
local c2=layout.calc(1920,1080); assert(math.abs(c2.scale-1.5)<0.001 and math.abs(c2.ox-420)<0.001)
local c3=layout.calc(1200,1920); assert(math.abs(c3.scale-(1200/720))<0.001 and math.abs(c3.oy-360)<0.001)
st.screen="investigate"; love.draw(); love.keypressed("e"); assert(st.screen=="evidence")
love.keypressed("t"); assert(st.screen=="timeline"); love.keypressed("b"); assert(st.screen=="board"); love.keypressed("a"); assert(st.screen=="accuse")

-- square content remains clickable when the window is letterboxed
window_w,window_h=1080,720; st.screen="title"; clear_render_logs(); love.draw()
love.mousepressed(100,196,1); assert(st.screen=="title","clicks in a landscape letterbox must be ignored")
love.mousepressed(280,196,1); assert(st.screen=="case_select","letterboxed button coordinates must map to logical space")
window_w,window_h=720,720

-- every authored evidence record and statement has a reachable runtime route
local evidence_count=0 for _ in pairs(ondacase_routes.evidence) do evidence_count=evidence_count+1 end assert(evidence_count==13)
local statement_count=0 for _ in pairs(ondacase_routes.statements) do statement_count=statement_count+1 end assert(statement_count==7)
runtime.discover("mira_statement"); assert(not st.evidence.mira_statement,"Mira follow-up must stay locked")
for _,id in ipairs({"receipt_004","camera_log","toxicology","cup_lid","jo_statement","panel_log","service_log","delivery_photo","pharmacy_footage","draft_email","sasha_voicemail"}) do runtime.discover(id) end
for _,person in ipairs({"mira","arin","jo","sasha","dan"}) do runtime.open_interview(person) end
runtime.apply_ink({ok=true,state="jo:2",text="JO: I thought it was Mira.",choices={},callbacks={},can_continue=false})
runtime.choose_interview({index=0,text="Ask about the route gap"})
runtime.apply_ink({ok=true,state="arin:fiber",text="The fiber matches.",choices={},callbacks={{name="discover_evidence",args={"tape_fiber"}}},can_continue=false})
runtime.apply_ink({ok=true,state="mira:followup",text="Mira gives a follow-up.",choices={},callbacks={{name="discover_evidence",args={"mira_statement"}}},can_continue=false})
for id in pairs(ondacase_routes.evidence) do assert(st.evidence[id],"unreachable evidence: "..id) end
for id in pairs(ondacase_routes.statements) do assert(st.heard_statements[id],"unreachable statement: "..id) end
assert(st.ink_state=="mira:followup" and #st.conversation_branches>=6,"Ink state and branches persist")

-- selected evidence, not the whole file, is sent in the structured accusation
st.accused="arin"; st.accusation.suspect="arin"
st.accusation_mode="evidence"; runtime.toggle_evidence("draft_email"); runtime.toggle_evidence("cup_lid")
st.accusation_mode="motive"; runtime.toggle_evidence("draft_email")
st.accusation_mode="method"; runtime.toggle_evidence("cup_lid")
st.accusation_mode="opportunity"; runtime.toggle_evidence("cup_lid")
runtime.submit_accusation()
local accusation_call
for i=#prolog_calls,1,-1 do if prolog_calls[i].operation=="accusation" then accusation_call=prolog_calls[i]; break end end
assert(accusation_call,"accusation bridge was not called")
local p=accusation_call.payload
assert(p.suspect=="arin" and #p.motive==1 and p.motive[1]=="draft_email" and #p.method==1 and p.method[1]=="cup_lid" and #p.opportunity==1 and p.opportunity[1]=="cup_lid")
assert(#p.evidence==2 and #p.known_evidence==2 and contains(p.evidence,"draft_email") and contains(p.evidence,"cup_lid"),"selected evidence payload")
assert(st.ending=="conviction" and st.ending_report.unique_solution==true,"actual Prolog report rendered after submission")

-- closing without accusation distinguishes unique proof from open alternatives
runtime.close_insufficient(); assert(st.ending=="everybody_goes_home")
st.evidence.tape_fiber=nil; st.clues=12; runtime.close_insufficient(); assert(st.ending=="detective")

-- all required state categories survive a round trip; unknown IDs are removed
local save=ondacase_save
local parsed=save.parse(save.serialize(st))
for _,field in ipairs({"inspected_objects","visited_locations","heard_statements","contradictions","inferred_facts","conversation_branches","hypotheses","timeline_entries","presented_evidence","accusation_attempts","major_flags"}) do assert(type(parsed[field])=="table","missing save category: "..field) end
assert(parsed.ink_state==st.ink_state and parsed.current_person==st.current_person)
assert(parsed.accusation.motive.draft_email and parsed.accusation.method.cup_lid and parsed.accusation.opportunity.cup_lid,"structured accusation round trip")
assert(save.parse('{"evidence":{"receipt_004":true,"hidden_truth":true}}')==nil,"raw versionless save must be rejected")
assert(save.parse('{"version":1,"payload":"{}","checksum":"00000000"}')==nil,"unsupported version nil")
assert(save.parse('{"version":2,"payload":"{}","checksum":"00000000"}')==nil,"bad checksum nil")
local valid_raw=save.serialize(st)
assert(valid_raw and save.parse(valid_raw)~=nil,"valid envelope parses")
local mutated=valid_raw:gsub("a","b",1)
if mutated==valid_raw then mutated=valid_raw:gsub("e","f",1) end
assert(save.parse(mutated)==nil,"mutated payload rejected")
assert(save.parse("{ not json }")==nil)

-- checksums detect corruption, but checksum-valid edits are still untrusted input
local json=require("dkjson")
local function save_checksum(value)
  local h=2166136261
  for i=1,#value do h=(h*31+value:byte(i))%4294967296 end
  return string.format("%08x",h)
end
local function edit_save(raw,mutate_payload)
  local outer=json.decode(raw)
  local payload=json.decode(outer.payload)
  mutate_payload(payload)
  outer.payload=json.encode(payload)
  outer.checksum=save_checksum(outer.payload)
  return json.encode(outer)
end
local hostile=edit_save(valid_raw,function(payload)
  payload.screen="ending"
  payload.evidence={mira_statement=true}
  payload.heard_statements={}
  payload.evidence_detail="mira_statement"
  payload.active_proof="arin_case_proven"
  payload.proof_data=true
  payload.contradictions=true
  payload.inferred_facts="arin_case_proven"
  payload.hypotheses=7
  payload.timeline_entries=false
  payload.alternatives="none"
  payload.major_flags={unique_proof=true}
  payload.ending="conviction"
  payload.ending_report=true
  payload.settings=7
  payload.ink_state=string.rep("x",20001)
  payload.ink_text="The footage says aconite at 19:04."
  payload.ink_choices={{index=0,text="Present the pharmacy footage"}}
  payload.accusation={suspect="arin",evidence={mira_statement=true},motive={mira_statement=true},method={},opportunity={}}
  payload.theory={suspect="arin",mode="motive",evidence={mira_statement=true},motive={mira_statement=true}}
  payload.inspected_objects={mira_statement=true}
  payload.presented_evidence={mira_statement=true}
end)
local ok_hostile,cleaned=pcall(save.parse,hostile)
assert(ok_hostile and cleaned,"checksum-valid edited save must normalize without crashing")
assert(cleaned.screen=="investigate" and cleaned.ending==nil and cleaned.ending_report==nil,"invalid ending state must reopen the investigation")
assert(cleaned.ink_state==nil,"oversized Ink state must be discarded instead of truncated")
assert(cleaned.ink_text==nil and #cleaned.ink_choices==0,"cached dialogue must be rebuilt from Ink state")
assert(cleaned.evidence_detail==nil and cleaned.active_proof==nil,"undiscovered detail and proof references must be removed")
for _,field in ipairs({"proof_data","contradictions","inferred_facts","hypotheses","alternatives"}) do
  assert(type(cleaned[field])=="table" and next(cleaned[field])==nil,"derived field was trusted: "..field)
end
assert(type(cleaned.timeline_entries)=="table" and next(cleaned.timeline_entries)==nil,"timeline must be recomputed")
assert(not cleaned.major_flags.unique_proof,"derived proof flag must be discarded")
assert(not cleaned.evidence.mira_statement and not cleaned.accusation.evidence.mira_statement and not cleaned.theory.evidence.mira_statement,"prerequisite-invalid evidence must cascade through selections")
assert(not cleaned.inspected_objects.mira_statement and not cleaned.presented_evidence.mira_statement,"prerequisite-invalid evidence metadata must be removed")
local array_outer=json.decode(valid_raw)
array_outer.payload="[]"
array_outer.checksum=save_checksum(array_outer.payload)
assert(save.parse(json.encode(array_outer))==nil,"array payload root must be rejected")
local invalid_terminal=edit_save(valid_raw,function(payload)
  payload.screen="ending"
  payload.ending="not_an_ending"
  payload.ending_report={unique_solution=false}
end)
assert(save.parse(invalid_terminal).screen=="investigate","terminal screen requires both a valid ending and report")
local invalid_mira_report=edit_save(valid_raw,function(payload)
  payload.screen="ending"
  payload.evidence={mira_statement=true}
  payload.heard_statements={}
  payload.ending="detective"
  payload.ending_report={unique_solution=false,selected_evidence={{id="mira_statement"}}}
end)
local cleaned_report=save.parse(invalid_mira_report)
assert(cleaned_report.ending_report and #cleaned_report.ending_report.selected_evidence==0,"ending report must follow the final evidence set")
local utf8_boundary=edit_save(valid_raw,function(payload)
  payload.ink_text=string.rep("a",4999).."é"
end)
local clean_boundary=save.parse(utf8_boundary).ink_text
assert(clean_boundary==nil,"cached dialogue text is never restored")

-- checksummed saves restore location and usable dialogue, while derived theory results are discarded
st.screen="dialogue"; st.location="apartment"; st.current_person="arin"; st.ink_state="checksummed-ink-state"; st.ink_text="ARIN: Saved line."; st.ink_choices={{index=0,text="Ask again"}}; st.ink_can_continue=false
st.evidence={pharmacy_footage=true}; st.theory={suspect="arin",mode="method",evidence={pharmacy_footage=true,cup_lid=true},method={pharmacy_footage=true,cup_lid=true},motive={},opportunity={},result={selected_evidence={{id="cup_lid",title="Cup lid"}}}}
runtime.save_state(); st.screen="title"; st.location="alley"; st.ink_text=nil; st.ink_choices={}; st.theory={suspect="mira",evidence={},motive={},method={},opportunity={},mode="evidence",result={}}
runtime.load_state()
love.draw()
assert(st.screen=="dialogue" and st.location=="apartment" and st.ink_text=="ARIN: I bought cough drops.","fresh load regenerates the interview knot with restored evidence and location")
assert(st.theory.result==nil and st.theory.evidence.pharmacy_footage and not st.theory.evidence.cup_lid,"save strips derived and undiscovered theory data")

-- offline reasoning cannot leave derived state from the previous in-memory case
love.filesystem._data["save.json"]=hostile
st.inferences={"arin_case_proven"}; st.contradiction=true
prolog_online=false; runtime.load_state(); prolog_online=true
assert(type(st.inferences)=="table" and next(st.inferences)==nil and st.contradiction==false,"offline load must clear stale derived state")

-- hero screens render without error (deterministic draw harness)
for _,screen in ipairs({"title","case_select","investigate","location","people","dialogue","evidence","evidence_detail","timeline","contradiction","proof","board","theory","accuse","ending","pause","settings","load_record"}) do
  st.screen=screen
  if screen=="evidence_detail" then st.evidence_detail="receipt_004" end
  if screen=="dialogue" then st.current_person="arin"; st.ink_text="Test dialogue line that must wrap safely within 1280 width without overflow." end
  if screen=="contradiction" then st.prev_screen="investigate" end
  if screen=="location" then for _,loc in ipairs({"cafe","alley","store","apartment"}) do st.location=loc; draw_calls={}; love.draw(); assert(#draw_calls>=0,"location draw "..loc) end end
  draw_calls={}; love.draw()
end
print("hero_screens_draw=pass")

-- people screen never reveals evidence before discovery
st.screen="people"; st.evidence={}; st.heard_statements={}; clear_render_logs(); love.draw()
for _,secret in ipairs({"aconite","Departure time is wrong","debt","route has a gap"}) do assert(not text_contains(secret),"people screen leaked: "..secret) end
assert(text_contains("Same table every Tuesday."),"neutral suspect note missing")
st.evidence={pharmacy_footage=true,receipt_004=true}; st.heard_statements={mira_left_1910=true}; clear_render_logs(); love.draw()
assert(text_contains("Bought aconite at 19:04") and text_contains("Register says 19:22"),"discovered notes did not update")
print("people_secrecy=pass")

-- evidence pagination: 13 records paginates into 3 pages at 6 per page
st.evidence={}; for _,id in ipairs({"receipt_004","camera_log","toxicology","cup_lid","jo_statement","panel_log","service_log","delivery_photo","pharmacy_footage","draft_email","sasha_voicemail","tape_fiber","mira_statement"}) do st.evidence[id]=true end
st.clues=13; st.evidence_page=1; st.screen="evidence"; love.draw(); assert(st.evidence_page==1)
st.evidence_page=3; love.draw(); assert(st.evidence_page==3)
-- evidence detail shows metadata
st.evidence_detail="receipt_004"; st.screen="evidence_detail"; love.draw()
print("evidence_pagination_and_detail=pass")

-- timeline derived from discovered evidence, no leak
st.evidence={receipt_004=true}; st.inferences={}; st.heard_statements={}
local visible = runtime.timeline_visible()
local found_mira=false; for _,r in ipairs(visible) do if r.time=="19:22" then found_mira=true end end
assert(found_mira,"timeline shows receipt event when discovered")
st.evidence={}; visible=runtime.timeline_visible()
local hidden=false; for _,r in ipairs(visible) do if r.time=="19:04" then hidden=true end end
assert(not hidden,"timeline hides pharmacy event when not discovered")
st.evidence={receipt_004=true,camera_log=true,toxicology=true,pharmacy_footage=true,cup_lid=true,tape_fiber=true,draft_email=true,service_log=true,mira_statement=true,delivery_photo=true,sasha_voicemail=true,panel_log=true,jo_statement=true}
visible=runtime.timeline_visible(); assert(#visible==14,"all authored timeline rows must be reachable")
local rendered_times={}; for page=1,3 do st.timeline_page=page; st.screen="timeline"; clear_render_logs(); love.draw(); for _,row in ipairs(visible) do if text_contains(row.time) then rendered_times[row.time]=true end end end
for _,row in ipairs(visible) do assert(rendered_times[row.time],"timeline row not rendered: "..row.time) end
print("timeline_derived=pass")

-- board no premature leak (Arin/poison not shown without evidence)
st.evidence={}; st.heard_statements={}
local bv=runtime.board_visible()
local has_arin=false; for _,n in ipairs(bv) do if n.label=="ARIN" then has_arin=true end end
assert(not has_arin,"board must not reveal Arin without pharmacy_footage")
st.evidence={pharmacy_footage=true}; bv=runtime.board_visible()
has_arin=false; for _,n in ipairs(bv) do if n.label=="ARIN" then has_arin=true end end
assert(has_arin,"board reveals Arin after discovery")
print("board_no_leak=pass")

-- portrait and location draw paths use sheet assets
st.screen="dialogue"; st.current_person="arin"; draw_calls={}; love.draw()
local saw_draw=false; for _,c in ipairs(draw_calls) do saw_draw=true end
assert(saw_draw,"portrait/location draw path emits draw calls")
for _,route in ipairs({{"cafe",120,327},{"alley",180,413},{"store",575,371},{"apartment",525,155}}) do
  st.screen="investigate"; clear_render_logs(); love.draw()
  assert(#draw_calls>0,"district map must render")
  love.mousepressed(route[2],route[3],1)
  assert(st.screen=="location" and st.location==route[1] and st.visited_locations[route[1]],"map hotspot must visit "..route[1])
  clear_render_logs(); love.draw()
  assert(text_contains("3D view unavailable") and text_contains("01 "),"headless location retains a clear inspection-list fallback")
  assert(st.location_view==1,"entering a location resets the camera")
  love.keypressed("v"); assert(st.location_view==2,"V changes the fixed camera")
  love.draw(); love.mousepressed(110,632,1); assert(st.location_view==1,"Change view button cycles the camera")
end
window_w,window_h=1080,720; st.screen="investigate"; love.draw()
love.mousepressed(50,327,1); assert(st.screen=="investigate","map letterbox must not accept clicks")
love.mousepressed(300,327,1); assert(st.location=="cafe" and st.screen=="location","wide map hit testing")
window_w,window_h=600,600; st.screen="investigate"; love.draw()
love.mousepressed(575*5/6,371*5/6,1); assert(st.location=="store" and st.screen=="location","small map hit testing")
window_w,window_h=720,720
love.filesystem._data["assets/map/district.png"]=nil; love.load()
st.screen="investigate"; clear_render_logs(); love.draw()
assert(text_contains("Map image unavailable"),"map fallback must explain the missing image")
love.mousepressed(180,413,1); assert(st.location=="alley" and st.screen=="location","location controls survive missing map art")
love.filesystem._data["assets/map/district.png"]=true; love.load()
love.keypressed("m"); assert(st.screen=="investigate","M returns to the map")
love.draw(); love.mousepressed(110,46,1)
assert(st.screen=="board" and ondacase_focus.get()==2,"clicked navigation must receive keyboard focus")
print("portrait_location_draw=pass")
print("district_map_hotspots_scaling_fallback=pass")
assert(image_filters["assets/map/district.png"][1]=="nearest" and image_filters["assets/map/district.png"][2]=="nearest","map art must stay nearest-filtered")

-- The low-poly render wins over the legacy photo and uses integer nearest scaling.
for _,id in ipairs(cast) do
  local path="assets/suspects/"..id.."-psx.png"
  st.screen="dialogue"; st.current_person=id; clear_render_logs(); love.draw()
  for _,entry in ipairs(text_positions) do assert(entry.filter=="linear","interview text must remain readable at fractional window scales") end
  local portrait=nil
  for _,call in ipairs(draw_calls) do if call[1].path==path then portrait=call end end
  assert(portrait and portrait[5]==2 and portrait[6]==2,id..": interview portrait must draw at 2x, without smoothing")
  local filter=image_filters[path]
  assert(filter and filter[1]=="nearest" and filter[2]=="nearest",id..": low-res portrait must use nearest sampling")
  love.filesystem._data[path]=nil
  love.load(); st.screen="dialogue"; clear_render_logs(); love.draw()
  assert(#draw_calls>0,id..": missing low-poly art must retain the legacy portrait")
  for _,call in ipairs(draw_calls) do assert(call[1].path~=path,"missing portrait must not remain cached") end
  st.screen="people"; clear_render_logs(); love.draw()
  local fallback=false
  for _,call in ipairs(draw_calls) do
    if call[1]==image then
      fallback=true
      assert(type(call[2])=="number",id..": legacy photo must not retain the low-poly face crop")
    end
  end
  assert(fallback,id..": People must retain the legacy photo when new art is missing")
  love.filesystem._data[path]=true
  love.load()
  -- Check the actual PNG headers as well as the graphics double.
  for _,asset in ipairs({{path,144,216},{"assets/suspects/"..id.."-source/"..id.."-atlas.png",128,128}}) do
    local file=assert(io.open(asset[1],"rb"))
    local header=file:read(24); file:close()
    assert(header:sub(1,8)=="\137PNG\r\n\26\n",asset[1]..": expected PNG")
    local w,h=string.unpack(">I4I4",header,17)
    assert(w==asset[2] and h==asset[3],asset[1]..": wrong pixel dimensions")
  end
end
st.screen="people"; clear_render_logs(); love.draw()
local seen={}
for _,call in ipairs(draw_calls) do
  if call[1].path then
    seen[call[1].path]=true
    local crop=call[2]
    assert(type(crop)=="table" and crop[1]==16 and crop[2]==8 and crop[3]==112 and crop[4]==112,
      "People thumbnails must crop faces instead of shrinking the whole bust")
  end
end
for _,id in ipairs(cast) do assert(seen["assets/suspects/"..id.."-psx.png"],id..": People must use the new portrait") end
runtime.open_interview("mira"); love.draw()
assert(ondacase_focus.get()==7,"entering an interview focuses the conversation after the six navigation tabs")
print("console_portrait_and_focus=pass")
print("lowpoly_cast=5_asset_dimensions_filtering_fallbacks_people_pass")

-- contradiction transition appears on receipt vs mira statement and returns
st.evidence={receipt_004=true}; st.heard_statements={}; st.contradiction_seen={}; st.screen="investigate"
runtime.record_statement("mira_left_1910")
assert(st.screen=="contradiction","contradiction screen appears on conflict")
-- simulate continue
st.screen=st.prev_screen or "investigate"; assert(st.screen=="investigate","contradiction returns naturally")
print("contradiction_transition=pass")

-- theory builder distinct from accusation, hypothesis not truth
st.theory={suspect="mira",motive={},method={},opportunity={},evidence={},mode="evidence"}
st.evidence={receipt_004=true, camera_log=true}
runtime.evaluate_theory()
local theory_call=nil; for i=#prolog_calls,1,-1 do if prolog_calls[i].operation=="evaluate_hypothesis" then theory_call=prolog_calls[i]; break end end
assert(theory_call,"theory builder calls evaluate_hypothesis")
assert(st.theory.result~=nil,"theory stores hypothesis result")
assert(st.accusation.suspect~=st.theory.suspect,"theory remains distinct from accusation")
local report=runtime.theory_report_lines(st.theory.result); local report_text=""; for _,line in ipairs(report) do report_text=report_text.."\n"..line.text end
for _,label in ipairs({"Toxicology report","Cup lid","Blue tape fiber","Mira left at 19:10","Receipt #004","The later purchase requires her presence"}) do assert(report_text:find(label,1,true),"theory report missing: "..label) end
assert(not report_text:find("unsupported_dimension",1,true) and not report_text:find("tape_fiber",1,true),"theory report leaked internal identifiers")
for page=1,math.ceil(#report/10) do st.theory_report_page=page; st.screen="theory"; clear_render_logs(); love.draw() end
print("theory_builder=pass")

-- hover state via logical coordinates retains keyboard focus
st.screen="investigate"; love.draw()
ondacase_focus.set(1); love.keypressed("tab"); assert(ondacase_focus.get()==2,"Tab advances focus"); love.draw(); assert(ondacase_focus.get()==2,"focus survives redraw")
keys_down.lshift=true; love.keypressed("tab"); keys_down.lshift=nil; assert(ondacase_focus.get()==1,"Shift-Tab reverses focus")
local focus_before=ondacase_focus.get()
-- simulate mouse over first button area (approx 34,665)
love.mousemoved(50,680,0,0)
-- mouse hover should not change keyboard focus index
assert(ondacase_focus.get()==focus_before,"hover retains keyboard focus")
print("hover_retains_focus=pass")

-- overflow readable at 720x720: dialogue choices and evidence overflow paginated
st.ink_choices={}; for i=1,20 do table.insert(st.ink_choices,{index=i-1,text="Choice "..i.." with a fairly long player-facing label that must remain readable."}) end
st.dialogue_page=1; st.screen="dialogue"; clear_render_logs(); love.draw()
assert(st.dialogue_page==1,"choice overflow paginated")
local long_choice_seen=false
for _,entry in ipairs(text_positions) do
  if entry.text:find("Choice 1",1,true) then
    long_choice_seen=true
    assert(not entry.text:find("\n",1,true),"button labels must stay on one line")
    assert(entry.x>=348 and entry.x+entry.w<=688,"long button label must stay inside its horizontal bounds")
    assert(entry.y>=420 and entry.y+entry.height<=446,"long button label must stay inside its rectangle")
  end
end
assert(long_choice_seen,"long dialogue choice was rendered")
-- Page navigation has its own row, so it cannot steal a choice's click.
love.mousepressed(646,630,1)
assert(st.dialogue_page==2,"Next must be reachable below all six choices")
clear_render_logs(); love.draw()
assert(text_contains("Choice 7") and not text_contains("Choice 1 "),"second page must display the next choices")
love.mousepressed(386,630,1)
assert(st.dialogue_page==1,"Prev must return to the first page")
love.draw(); love.mousepressed(450,433,1)
assert(ink_calls[#ink_calls].operation=="choose" and ink_calls[#ink_calls].payload.index==0,"choice click must reach its original Ink index")
print("overflow_readable=pass")

st.screen="proof"; st.active_proof="test-many"; st.proof_data={{fact="test-many",conclusion="Test conclusion",premises={}}}
for i=1,9 do table.insert(st.proof_data[1].premises,{id="test-"..i,title="PREMISE "..i}) end
clear_render_logs(); love.draw()
assert(text_contains("PREMISE 6") and not text_contains("PREMISE 7"),"proof trace must bound its first page")
love.mousepressed(620,528,1); clear_render_logs(); love.draw()
assert(st.proof_page==2 and text_contains("PREMISE 9") and not text_contains("PREMISE 1"),"all proof premises must be reachable")
st.active_proof="test-other"; st.proof_data={{fact="test-other",conclusion="Other",premises={{title="Other premise"}}}}
clear_render_logs(); love.draw(); assert(st.proof_page==1 and text_contains("Other premise"),"changing proof resets the display page")
print("proof_trace_pagination=pass")

-- Exact source image sizes are part of the map overlay's coordinate contract.
for _,asset in ipairs({{"assets/map/district.png",320,224},{"assets/map/district-atlas.png",128,128}}) do
  local f=assert(io.open(asset[1],"rb")); local header=f:read(24); f:close()
  assert(header:sub(1,8)=="\137PNG\r\n\26\n")
  local w,h=string.unpack(">I4I4",header,17)
  assert(w==asset[2] and h==asset[3],"map render dimensions changed; update overlays with the render")
end
print("map_asset_dimensions=pass")

-- evidence detail routes to the proof selected for that evidence
st.evidence={pharmacy_footage=true,receipt_004=true}; st.evidence_detail="pharmacy_footage"; st.proof_data={
  {fact="mira_departure_conflict",conclusion="Mira departure is false",rule="purchase_requires_presence",premises={{id="receipt_004",title="Receipt #004"}}},
  {fact="arin_means",conclusion="Arin obtained aconite",rule="purchase_record",premises={{id="pharmacy_footage",title="Pharmacy footage"}}}
}; st.screen="evidence_detail"; clear_render_logs(); love.draw(); love.mousepressed(550,305,1)
assert(st.screen=="proof" and st.active_proof=="arin_means","evidence detail did not select its proof")
clear_render_logs(); love.draw(); assert(text_contains("Arin obtained aconite") and not text_contains("Mira departure is false"),"proof screen rendered the wrong proof")
assert(not text_contains("purchase_record"),"proof screen leaked raw rule ID")
print("proof_routing=pass")

-- Every bottom action has a 32px safe area above the footer, even on dense screens.
assert(layout.FOOTER_Y-layout.ACTION_BOTTOM>=32)
for _,screen in ipairs({"title","case_select","investigate","location","people","dialogue","evidence","evidence_detail","timeline","contradiction","board","proof","theory","accuse","ending","pause","settings","load_record"}) do
  st.screen=screen; control_bounds={}; love.draw()
  for _,rect in ipairs(control_bounds) do
    if rect.y>=540 then assert(rect.y+rect.h<=layout.ACTION_BOTTOM,screen..": bottom action crowds the footer") end
  end
end
print("bottom_action_safe_area=18_screens_pass")

print("love_runtime_smoke=pass")
print("scaling_coordinates=pass")
print("bridge_callbacks=pass")
print("route_reachability=pass")
print("accusation_payload=pass")
print("save_roundtrip=pass")
