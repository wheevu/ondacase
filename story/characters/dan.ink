=== dan ===
DAN: I never went inside the café. # speaker:dan

He says inside carefully. His delivery route puts him in the service alley at 19:19. He speaks in short practical sentences, as if conserving charge.

* [Where were you at 19:19?] # intent:direct
    DAN: In the service alley, under the awning. Heavy box, wet handle.
    You ask why his tracker pauses there.
    DAN: Because I paused there. The app draws a line through a building. I followed the line.
    -> dan
* [You said you never went inside. That sounds like a boundary you chose.] # intent:accuse_lying
    DAN: I stood under the awning. My shoes stayed outside. That is the sentence I can sign.
    You ask whether his hand crossed the threshold.
    DAN: That is a different question. My hand moved a pharmacy bag so I could put down a box.
    # outcome:misunderstood
    -> dan
* [You are hiding why your route paused.] # intent:confrontational
    DAN: I am hiding a stolen parcel. Eli's misdelivered parcel, under my jacket at 19:19. That pause is documented theft, not murder.
    You ask what was inside.
    DAN: A phone charger and socks. Small crime, excellent documentation.
    -> dan
* [Ask about the route gap] # intent:neutral
    DAN: The app sent me behind the buildings. It does that when it thinks a wall is a road.
    You ask why his route pauses by the service door.
    DAN: Heavy box. Wet handle. Pick whichever ordinary reason sounds least criminal.
    -> dan
* [Ask whether he entered the café] # intent:direct
    DAN: No. I stood under the service awning. The door opened. My shoes stayed outside.
    You ask whether his hand crossed the threshold.
    DAN: That is a different question.
    -> dan
* [Ask about the service alley] # intent:neutral
    DAN: There was a pharmacy bag on the cart. I moved it so I could put down a box.
    You ask where the bag went.
    DAN: I put it back. Probably. The alley was full of bags.
    -> dan
* [Show the delivery-bike photo] # intent:present_evidence
    ~ discover_evidence("delivery_photo")
    The bike camera catches Dan at 19:19 with Eli's misdelivered parcel under his jacket. His tracker places him two blocks away by 19:24.
    DAN: I stole the parcel. I saw the return label and made a bad decision with excellent documentation.
    You ask what was inside.
    DAN: A phone charger and socks. I committed a very small crime beside a much larger one.
    # evidence:delivery_photo
    # outcome:supporting
    -> dan
* {pharmacy_footage} [Ask about the pharmacy bag again] # intent:present_evidence
    DAN: Arin carried it out of the night-store pharmacy. White paper, green stamp. He set it on my cart while he answered his phone, then took it toward the café.
    You ask why Dan first made the bag sound ownerless.
    DAN: Because I was already explaining one thing on my cart that did not belong to me.
    # evidence:pharmacy_footage
    # outcome:supporting
    -> dan
* [Show him the condiment sachets] # intent:present_evidence
    DAN: Plum sauce for my grandmother. Two per delivery, not four. It proves I am a grandson, not a murderer.
    You note the sachets are unrelated to the poisoning method.
    # outcome:unrelated
    -> dan
* [Ask him to walk the route again] # intent:direct
    DAN: 19:19 alley, 19:21 bus depot camera, 19:24 two blocks east. Same minutes, same jacket theft.
    You note the repeat adds no new location, only confirmation.
    -> dan
* {delivery_photo} [Walk his route minute by minute] # intent:confrontational
    At 19:19 Dan is in the alley with the parcel. At 19:21 he passes the bus depot camera. At 19:24 his tracker is two blocks east.
    DAN: So I am a thief with an alibi.
    The theft explains his lie. The route excludes him from altering the cup before Eli drinks.
    # outcome:dan_excluded
    -> dan
* [Ask about the condiment sachets] # intent:change_subject
    DAN: My grandmother likes the plum sauce from the noodle place. They never put enough in her order.
    You let him keep the small dignity, then return to the alley.
    -> dan
* [Ask one ordinary question] # intent:flavor
    -> dan_personal
* [Leave] # intent:leave
    -> END

=== dan_personal ===
Dan empties his jacket pocket onto the table. Transit card, bike light, and six condiment sachets sorted by color.

* [Ask about the card] # intent:flavor
    DAN: My grandmother gave me the case. The card is mine. The bend is from a bicycle accident and not, as my manager says, poor planning.
    -> dan_personal
* [Ask about the route app] # intent:neutral
    DAN: The app thinks the world is a collection of lines. People are the things that get in the way of lines.
    -> dan_personal
* [Ask about the condiment sachets] # intent:neutral
    DAN: My grandmother likes the plum sauce from the noodle place. They never put enough in her order.
    You ask whether he takes them from every delivery.
    DAN: I take two. She says four. We have an arrangement based on mutual disappointment.
    -> dan_personal
* [Return to the case] # intent:change_subject
    -> dan
