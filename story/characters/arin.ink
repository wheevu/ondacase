=== arin ===
ARIN: I was at the night store pharmacy. I bought cough drops. # speaker:arin

He peels the label from an empty tonic bottle. Blue tape circles a cut on his left index finger. His sentences arrive polished, unhurried, as if he is filing the afternoon into a column.

{pharmacy_footage:
The night-store pharmacist's footage says aconite.
}

* [Ask why he went to the night-store pharmacy] # intent:neutral
    ARIN: A column. A review. The sort of work that pays in invitations and makes landlords suspicious.
    You ask for the assignment.
    ARIN: It was still becoming an assignment.
    The bottle label comes away in one clean strip.
    -> arin
* {pharmacy_footage} [What exactly did you buy at 19:04?] # intent:direct
    ARIN: Cough drops. The kind that come in a white paper bag with a green stamp. You have seen one. You are holding the idea of one.
    You ask why the register lists aconite.
    ARIN: Registers list what the typist believes. Mine believed in accuracy. Yours believes in accusation.
    -> arin
* {pharmacy_footage} [That cough-drop story is false.] # intent:accuse_lying
    ARIN: Then the night-store camera is a novelist. It films hands, not intentions.
    You tell him the camera also films labels on bottles.
    ARIN: Labels are optimistic. The purchase is what it is.
    # outcome:valid_contradiction
    -> arin
* [You wanted Eli silent before morning.] # intent:confrontational
    ARIN: I wanted an editor. Not a corpse. The difference pays differently.
    You ask what Eli's draft would have cost him.
    ARIN: A season of assignments. Not a life. You are pricing grief as motive.
    -> arin
* [Ask about Eli's column] # intent:neutral
    ARIN: Eli had emails. He liked collecting them. People mistake collection for courage.
    You ask if the emails were real.
    ARIN: Real emails can support a stupid conclusion.
    -> arin
* {pharmacy_footage} [Present the pharmacy footage] # intent:present_evidence
    ~ discover_evidence("pharmacy_footage")
    You name the bottle, the price, and 19:04 at the night-store counter.
    ARIN: Fine. Aconite. I called it cough drops because "regulated poison" tends to end a conversation before the useful part.
    You ask what the useful part was.
    ARIN: I am still waiting to hear it.
    # evidence:pharmacy_footage
    # outcome:valid_contradiction
    -> arin
* {camera_log} [Present the camera gap] # intent:present_evidence
    ARIN: Eleven minutes is not a person. You will need more than a hole in a recording.
    He is right. The gap gives everyone nearby the same dark room.
    # evidence:camera_log
    # outcome:inconclusive
    -> arin
* [Present the service-door log] # intent:present_evidence
    ~ discover_evidence("service_log")
    The loaned staff tag opens the service door at 19:17 and records an exit at 19:25.
    ARIN: Mira lends that tag to half the block.
    You ask which half left with a night-store pharmacy bag.
    He starts peeling the label into narrower strips.
    # evidence:service_log
    # outcome:supporting
    -> arin
* [Present Eli's scheduled email] # intent:present_evidence
    ~ discover_evidence("draft_email")
    The draft names Arin and attaches invoices for favorable reviews.
    ARIN: Restaurants pay consultants. Eli changed the noun because fraud fit better in a subject line.
    You ask why he needed Eli silent before morning.
    ARIN: I needed an editor. Not a corpse.
    # evidence:draft_email
    # outcome:supporting
    -> arin
* {cup_lid} [Set the cup lid beside his hand] # intent:present_evidence
    ARIN: A café is full of lids.
    You turn it over. The wiped rim shines. A blue fiber remains caught beneath it.
    His taped finger closes into his palm.
    ARIN: Blue tape is not rare.
    # evidence:cup_lid
    # outcome:inconclusive
    -> arin
* {cup_lid} [Compare the blue fiber] # intent:present_evidence
    ~ discover_evidence("tape_fiber")
    The fiber beneath the lid matches the adhesive tape around his cut. It sat where an ordinary touch could not put it.
    ARIN: Matching is not the same as unique.
    You agree. It is contact with the concealed underside, not a verdict by color.
    # evidence:tape_fiber
    # outcome:supporting
    -> arin
* {pharmacy_footage && service_log && draft_email && tape_fiber} [Ask for one sequence that fits all four records] # intent:confrontational
    Arin looks at the bottle label scattered between you.
    ARIN: You already have a sequence you like.
    You ask for another.
    He says nothing. Silence does not complete the proof, but it does not repair his story.
    # outcome:arin_cornered
    -> arin
* {pharmacy_footage} [Ask again why he said cough drops] # intent:direct
    ARIN: Because you asked about a purchase and I offered the answer that would let us keep talking. It was false and it was tactical.
    You note the second version. False story, same purchase. The repetition narrows his defense.
    -> arin
* [Talk about his spreadsheet] # intent:change_subject
    ARIN: The spreadsheet is private. Restaurant names, train times, apologies I have not sent.
    You let him keep the digression, then return to the pharmacy bag.
    -> arin
* [Ask one ordinary question] # intent:flavor
    -> arin_personal
* [Stop] # intent:leave
    -> END

=== arin_personal ===
Arin has a spreadsheet open on his phone. It contains restaurant names, train times, and a column titled "things to apologize for."

* [Ask about the spreadsheet] # intent:flavor
    ARIN: It is a private system.
    You ask whether the apologies are sent.
    ARIN: Some are. Most improve with age, like bad cheese.
    -> arin_personal
* [Ask about his father] # intent:neutral
    ARIN: My father thinks criticism is a form of paying rent. He is wrong, but he has held that opinion for forty years.
    -> arin_personal
* [Return to the case] # intent:change_subject
    -> arin
