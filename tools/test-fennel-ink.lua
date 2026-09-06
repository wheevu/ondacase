local story=dofile("/tmp/ondacase-ink.lua")
assert(type(story)=="table" and type(story.request)=="function","Ink bridge returns a module table")
local reply=story.request("start",{variables={receipt_004=false}})
assert(reply.ok and reply.text:find("café") and type(reply.state)=="string")
for _=1,20 do
  if #reply.choices>0 or not reply.can_continue then break end
  reply=story.request("continue",{state=reply.state,variables=reply.variables})
end
assert(reply.ok and #reply.choices>0,"serialized state reaches Ink choices")
local receipt
for _,choice in ipairs(reply.choices) do if choice.text=="Inspect the receipt" then receipt=choice break end end
assert(receipt,"receipt route is available")
local chosen=story.request("choose",{index=receipt.index,state=reply.state,variables=reply.variables})
assert(chosen.ok and chosen.state~=reply.state)
assert(chosen.callbacks and chosen.callbacks[1].name=="discover_evidence" and chosen.callbacks[1].args[1]=="receipt_004")
assert(chosen.variables.receipt_004==true,"known evidence variables persist")
print("fennel_ink_bridge=pass")
