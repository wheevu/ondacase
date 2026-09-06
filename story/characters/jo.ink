=== jo ===
JO: I saw somebody with the cup at 19:21. # speaker:jo

Her municipal horticulture notes are open beside the till. Root rot on one page. Camera wiring on the next. She speaks quickly, hands checking the till as if counting could steady the story.

You ask if she means Mira.

JO: I thought it was Mira. I saw a shoulder, not a face.

* [What were you doing exactly at 19:16?] # intent:direct
    JO: Opening the panel. The screen froze. I have opened it wrong twice this month.
    You ask why she left that out of her first answer.
    JO: Mira already thinks I break everything I touch. I wanted one disaster to arrive without my name on it.
    -> jo
* [You are sure it was Mira?] # intent:accuse_lying
    JO: I was sure for a day. Now I am sure I was mistaken.
    You ask what changed.
    JO: You asked me to describe a face. I had only a shoulder and a floor dip I recognized.
    # outcome:misunderstood
    -> jo
* [You opened the camera panel and did not tell anyone.] # intent:confrontational
    JO: Yes. I opened it at 19:16 because the feed froze. I did not kill eleven minutes on purpose. The panel sticks when the weather turns.
    You ask whether hiding it felt safer.
    JO: It felt smaller. Then it became larger.
    -> jo
* [Ask what she was doing by the camera panel] # intent:neutral
    JO: Fixing it. Badly. The panel sticks when the weather turns.
    You ask why she left that out.
    JO: Mira already thinks I break everything I touch. I wanted one disaster to arrive without my name on it.
    -> jo
* [Ask about Mira] # intent:neutral
    JO: Mira was still here. She was angry, which is different from dangerous.
    You ask what made the silhouette look like her.
    JO: It moved as if it knew where the floor dipped. Everyone who works here does that. Arin does too.
    -> jo
* [Ask her to describe the cup] # intent:direct
    ~ discover_evidence("jo_statement")
    JO: Clear plastic. Black straw. Citrus sticker. There are not many mysteries in the beverage fridge.
    You ask about the hand carrying it.
    JO: Left hand. Something blue around one finger. I thought it was a ring until you asked me to slow down.
    # evidence:jo_statement
    # outcome:supporting
    -> jo
* [Describe the cup again, slower] # intent:direct
    JO: Same cup. Clear, straw, sticker. Left hand, blue on the finger. I did not see tape. I saw color moving.
    You note the second telling lands in the same place without sharpening. The mistake stays, the observation holds.
    -> jo
* [Present the panel and till log] # intent:present_evidence
    ~ discover_evidence("panel_log")
    The maintenance panel opened under Jo's code at 19:16. Her till login records orders through 19:24.
    JO: I opened the panel. I did not kill the feed on purpose.
    You tell her the same record that proves the mistake keeps her at the till when the cup was moved.
    JO: That is a generous way for a log to ruin my week.
    # evidence:panel_log
    # outcome:supporting
    -> jo
* {tape_fiber} [Show her the blue fiber] # intent:present_evidence
    JO: Mine is a hair clip. Plastic, no adhesive. Arin had tape on his finger. He kept picking at it and dropping bits by the sugar jars.
    You note the distinction. Loose tape near the till explains blue lint. It does not explain a matching fiber beneath a wiped lid.
    # evidence:tape_fiber
    # outcome:unrelated
    -> jo
* [Show her a receipt from another night] # intent:present_evidence
    JO: That is from Tuesday. Different handwriting, different order. It proves Tuesday.
    You note the unrelated record answers a question nobody asked.
    # outcome:unrelated
    -> jo
* {panel_log && jo_statement} [Separate her mistake from what she witnessed] # intent:confrontational
    Jo caused the blind spot by opening a faulty panel. Her till record keeps her at the register. Her description of the cup remains useful, but her first guess at the carrier does not.
    JO: I can live with being wrong. I would like not to be useful to him because of it.
    # outcome:jo_excluded
    -> jo
* [Talk about the horticulture course] # intent:change_subject
    JO: Night classes. Municipal planting, soil chemistry, trees that can survive people locking bicycles to them.
    You let her breathe, then return to 19:21.
    -> jo
* [Ask one ordinary question] # intent:flavor
    -> jo_personal
* [Leave] # intent:leave
    -> END

=== jo_personal ===
Jo has a bright yellow hair clip shaped like a tiny fish. She wears it on days when she expects a difficult shift.

* [Ask about the clip] # intent:flavor
    JO: My little sister gave it to me. She says it makes me look less like I am about to quit.
    -> jo_personal
* [Ask about the job] # intent:neutral
    JO: I like the coffee. I dislike the part where people leave their emotional weather on the counter.
    You ask if Eli did that.
    JO: Eli brought a whole season.
    -> jo_personal
* [Ask about the horticulture course] # intent:flavor
    JO: Night classes. Municipal planting, soil chemistry, trees that can survive people locking bicycles to them.
    She closes the notebook over the camera diagram.
    JO: Plants are easier. They wilt before they blame you.
    -> jo_personal
* [Return to the case] # intent:change_subject
    -> jo
