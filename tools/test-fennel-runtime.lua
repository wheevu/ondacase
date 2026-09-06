-- generated Fennel module and bootstrap contracts
local noop=function() end
local current_font={getHeight=function() return 11 end}
local image={getWidth=function() return 1280 end,getHeight=function() return 720 end,setFilter=noop}
local font_calls={}
love={
  window={setMode=noop,setTitle=noop},mouse={getX=function() return 0 end,getY=function() return 0 end},keyboard={isDown=function() return false end},
  filesystem={_data={["assets/cafe-lantern.png"]=true,["assets/cafe/composed.png"]=true,["assets/suspects-sheet.png"]=true,["assets/suspects/mira.png"]=true,["assets/suspects/arin.png"]=true,["assets/suspects/jo.png"]=true,["assets/suspects/sasha.png"]=true,["assets/suspects/dan.png"]=true,["assets/locations-sheet.png"]=true,["assets/fonts/Newsreader16pt-Regular.ttf"]=true,["assets/fonts/IBMPlexMono-Medium.ttf"]=true,["assets/fonts/VT323-Regular.ttf"]=true,["assets/fonts/ShareTechMono-Regular.ttf"]=true},getInfo=function(a,b) local k=b or a; return type(k)=="string" and love.filesystem._data[k] and {} or nil end,write=function(a,b,c) local k,v;if c then k=b;v=c else k=a;v=b end;love.filesystem._data[k]=v;return true end,read=function(a,b)return love.filesystem._data[b or a]end},
  graphics={newFont=function(a,b) local size=b or a; if type(a)=="string" then table.insert(font_calls,{path=a,size=b}) else table.insert(font_calls,{path=nil,size=a}) end return{setFilter=noop,getHeight=function()return size end,getWidth=function(_,text)return #tostring(text)*size*0.6 end}end,newImage=function()return image end,newQuad=function()return{}end,getDimensions=function()return 720,720 end,clear=noop,setColor=noop,setDefaultFilter=noop,rectangle=noop,setFont=function(font) current_font=font end,getFont=function()return current_font end,printf=noop,line=function(...) assert(select("#",...)>=4 and select("#",...)%2==0,"line vertices must be coordinate pairs") end,setLineWidth=noop,setLineStyle=noop,circle=noop,draw=noop,push=noop,pop=noop,scale=noop,translate=noop,setScissor=noop,setDefaultFilter=noop}
}
package.path=package.path..";./src/?.lua;./?.lua"

local prolog_module=require("src.prolog")
local ink_module=require("src.ink")
assert(type(prolog_module)=="table" and type(prolog_module.request)=="function","Prolog bridge must return a module table")
assert(type(ink_module)=="table" and type(ink_module.request)=="function","Ink bridge must return a module table")

package.loaded["src.prolog"]={request=function(operation,payload)
  if operation=="query_state" then return {ok=true,inferences={},inference_details={},contradictions={},knowledge={hypothesized={},proven={}}} end
  if operation=="possible_alternatives" then return {ok=true,alternatives={}} end
  return {ok=true}
end}
package.loaded["src.ink"]={request=function() return {ok=true,state="stub",text="stub",choices={},callbacks={},can_continue=false} end}
require("src.main")
love.load()
do
  local seen_mono,seen_serif=false,false
  local sizes={}
  for _,c in ipairs(font_calls) do
    if c.path=="assets/fonts/IBMPlexMono-Medium.ttf" then seen_mono=true end
    if c.path=="assets/fonts/Newsreader16pt-Regular.ttf" then seen_serif=true end
    if c.size then sizes[c.size]=true end
  end
  assert(seen_mono and seen_serif,"both bundled fonts must be discovered and passed to newFont")
  for _,s in ipairs({10,11,12,13,14,15,16,18,19,22,24,27,28,29,30,32,42,48,58}) do assert(sizes[s],"bundled font size missing: "..tostring(s)) end
  assert(love.filesystem.getInfo("assets/cafe-lantern.png") and love.filesystem.getInfo("assets/suspects-sheet.png") and love.filesystem.getInfo("assets/locations-sheet.png"),"raster assets must remain")
end
do
  local saved={}
  for k,v in pairs(love.filesystem._data) do saved[k]=v end
  love.filesystem._data["assets/fonts/Newsreader16pt-Regular.ttf"]=nil
  love.filesystem._data["assets/fonts/IBMPlexMono-Medium.ttf"]=nil
  love.filesystem._data["assets/fonts/VT323-Regular.ttf"]=nil
  love.filesystem._data["assets/fonts/ShareTechMono-Regular.ttf"]=nil
  love.filesystem._data["assets/cafe-lantern.png"]=nil
  font_calls={}
  local ok,err=pcall(love.load)
  assert(ok,"love.load fallback when fonts missing: "..tostring(err))
  local fallback=false
  for _,c in ipairs(font_calls) do if c.path==nil and c.size then fallback=true end end
  assert(fallback,"fallback newFont(size) when fonts missing")
  local ok2,err2=pcall(function() _G.ondacase_state.screen="title"; love.draw() end)
  assert(ok2,"hero draw without assets: "..tostring(err2))
  love.filesystem._data=saved
  font_calls={}
  assert(pcall(love.load),"reload with bundled assets must succeed")
  font_calls={}
  for _,s in ipairs({"title","case_select","investigate","location","people","dialogue","evidence","evidence_detail","timeline","contradiction","proof","board","theory","accuse","ending","pause","settings","load_record"}) do
    _G.ondacase_state.screen=s
    if s=="evidence_detail" then _G.ondacase_state.evidence_detail="receipt_004" end
    if s=="dialogue" then _G.ondacase_state.current_person="arin"; _G.ondacase_state.ink_text="Test dialogue line that must wrap safely without overflow." end
    if s=="contradiction" then _G.ondacase_state.prev_screen="investigate" end
    local ok3,err3=pcall(love.draw)
    assert(ok3,"hero screen still renders: "..s.." "..tostring(err3))
  end
end
print("bundled_fonts=pass")
print("hero_screens_draw=pass")

local layout=require("src.layout")
local function approx(a,b)return math.abs(a-b)<0.01 end
assert(layout.W==720 and layout.H==720,"reference canvas must stay square")
local a=layout.calc(720,720);assert(approx(a.scale,1)and approx(a.ox,0)and approx(a.oy,0))
local b=layout.calc(1920,1080);assert(approx(b.scale,1.5)and approx(b.ox,420)and approx(b.oy,0))

local save=require("src.save")
local st=_G.ondacase_state
st.screen="accuse";st.evidence={pharmacy_footage=true};st.clues=1
st.inspected_objects={pharmacy_footage=true};st.visited_locations={store=true};st.heard_statements={arin_cough_drops=true}
local parsed=save.parse(save.serialize(st))
assert(parsed.screen=="accuse" and parsed.evidence.pharmacy_footage and parsed.inspected_objects.pharmacy_footage and parsed.visited_locations.store and parsed.heard_statements.arin_cough_drops)
-- new screens round-trip
st.screen="theory"; st.theory={suspect="mira",motive={},method={},opportunity={},evidence={},mode="evidence"}
st.evidence.receipt_004=true
st.heard_statements.mira_left_1910=true
st.evidence_page=2; st.evidence_detail="receipt_004"; st.prev_screen="investigate"; st.contradiction_seen={receipt_mira=true}
local parsed2=save.parse(save.serialize(st))
assert(parsed2.screen=="theory" and parsed2.evidence_detail=="receipt_004" and parsed2.evidence_page==2 and parsed2.contradiction_seen.receipt_mira==true)
-- theory evaluate path exists
assert(type(ondacase_runtime.evaluate_theory)=="function" and type(ondacase_runtime.maybe_contradiction)=="function")

local src=assert(io.open("src/main.lua","r")):read("*a")
assert(not src:find("swipl"),"main must not call Prolog directly")
assert(not src:find("ink%-host"),"main must not call Ink directly")
assert(src:find('require%("src%.prolog"%)') and src:find('require%("src%.ink"%)'),"main requires both named bridges")
local boot=assert(io.open("main.lua","r")):read("*a")
assert(boot:find("src%.main") and #boot<300,"bootstrap stays tiny")
print("fennel_runtime=pass")
