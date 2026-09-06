-- generated from cases/001-americano/case.json by tools/build-case-manifest.lua; do not edit
return {
  timeline = {
    {time="18:52", event="Sasha arrives to recover her apartment key", status="claimed", requires={}},
    {time="18:58", event="Dan delivers café supplies", status="claimed", requires={}},
    {time="19:04", event="Arin visits the night-store pharmacy counter", status="confirmed", requires={"pharmacy_footage"}},
    {time="19:16", event="Jo opens the west-camera panel", status="confirmed", requires={"panel_log"}},
    {time="19:18", event="West café camera goes offline", status="confirmed", requires={"camera_log"}},
    {time="19:19", event="A delivery-bike photo places Dan in the alley", status="confirmed", requires={"delivery_photo"}},
    {time="19:21", event="Jo sees a familiar person carrying Eli's cup", status="claimed", requires={"jo_statement"}},
    {time="19:22", event="Mira makes an in-person purchase", status="confirmed", requires={"receipt_004"}},
    {time="19:23", event="Mira sees Arin beside Eli's booth", status="claimed", requires={"mira_statement"}},
    {time="19:24", event="Eli drinks the iced americano", status="confirmed", requires={"toxicology"}},
    {time="19:25", event="Arin's borrowed tag exits through the service door", status="confirmed", requires={"service_log"}},
    {time="19:29", event="West café camera returns", status="confirmed", requires={"camera_log"}},
    {time="19:34", event="Jo finds Eli", status="confirmed", requires={}},
    {time="19:25-19:28", event="Eli dies from aconite", status="confirmed", requires={"toxicology"}},
  },
  locations = {
    {id="cafe", name="CAFÉ LANTERN", note="The room is still open. Nobody is ordering anything.", evidence={
      {id="receipt_004", label="INSPECT RECEIPT #004"},
      {id="camera_log", label="CHECK CAMERA LOG"},
      {id="toxicology", label="READ TOXICOLOGY"},
      {id="cup_lid", label="INSPECT CUP LID"},
      {id="jo_statement", label="FILE JO'S ACCOUNT"},
      {id="panel_log", label="CHECK PANEL LOG"},
    }},
    {id="alley", name="SERVICE ALLEY", note="Wet concrete, a staff door, and a route that keeps moving.", evidence={
      {id="service_log", label="CHECK SERVICE-DOOR LOG"},
      {id="delivery_photo", label="CHECK BIKE PHOTO"},
    }},
    {id="store", name="NIGHT STORE", note="The pharmacy counter sees the bottle, the bag, and the time.", evidence={
      {id="pharmacy_footage", label="REVIEW PHARMACY FOOTAGE"},
    }},
    {id="apartment", name="ELI'S APARTMENT", note="The desk holds the story Eli meant to publish.", evidence={
      {id="draft_email", label="OPEN DRAFT EMAIL"},
      {id="sasha_voicemail", label="PLAY SAVED VOICEMAIL"},
    }},
  },
  people = {
    {id="mira", name="Mira Vale", role="Café manager"},
    {id="arin", name="Arin Ko", role="Food columnist"},
    {id="jo", name="Jo Bell", role="Barista"},
    {id="sasha", name="Sasha Reed", role="Eli's ex"},
    {id="dan", name="Dan Mott", role="Delivery rider"},
  },
  statements = {"mira_left_1910", "arin_cough_drops", "jo_saw_cup_1921", "jo_identified_mira", "sasha_never_argued", "dan_never_inside", "dan_route_recollection"},
}
