VAR receipt_004 = false
VAR camera_log = false
VAR toxicology = false
VAR pharmacy_footage = false
VAR cup_lid = false
VAR jo_statement = false
VAR tape_fiber = false
VAR draft_email = false
VAR service_log = false
VAR mira_statement = false
VAR delivery_photo = false
VAR sasha_voicemail = false
VAR panel_log = false

=== reconstruction ===
The café's ordinary objects start disagreeing with the people around them.

* [Review the pharmacy footage]
    ~ discover_evidence("pharmacy_footage")
    Arin's cough drops become aconite. He has a reason to dislike the correction.
    -> reconstruction
* [Inspect the cup lid]
    ~ discover_evidence("cup_lid")
    The residue under the rim survived the wipe.
    -> reconstruction
* [Read the toxicology report]
    ~ discover_evidence("toxicology")
    Aconite in the drink. Death between 19:25 and 19:28.
    -> reconstruction
* [Ask Jo what she saw]
    ~ discover_evidence("jo_statement")
    Jo saw a person with the cup. She did not see a face.
    -> reconstruction
* [Go to the pressure interview]
    -> pressure

=== reconstruct_motive ===
The motive board is less dramatic than the word motive suggests. It contains overdue invoices, a draft email, and a loyalty card with three stamps left before a free pastry.

* [Read Eli's draft email]
    Eli planned to publish a column about fabricated reviews. Arin's name appears in the margin, circled twice.
    -> reconstruct_motive
* [Compare the pharmacy receipt]
    ~ discover_evidence("pharmacy_footage")
    The pharmacy purchase is real. The cough drops are not.
    -> reconstruct_motive
* [Ask whether motive proves murder]
    A motive explains why a person might want an outcome. It does not place poison in a cup.
    -> reconstruct_motive
* [Move to the opportunity board]
    -> opportunity_board

=== opportunity_board ===
The times refuse to line up neatly. That is useful. A neat timeline would be suspicious in its own way.

* [Place the camera gap]
    ~ discover_evidence("camera_log")
    The blind spot begins before the death window and ends after it.
    -> opportunity_board
* [Place the death window]
    ~ discover_evidence("toxicology")
    Eli drank at 19:24. The cup had to be altered before then.
    -> opportunity_board
* [Ask what the receipt changes]
    The receipt makes Mira's story false. It does not make the camera gap belong to her.
    -> opportunity_board
* [Apply pressure]
    -> pressure
* [Open the final case file]
    -> accusation

=== late_interview ===
The second interview is quieter. People have learned which words make the detective look down at the file.

* [Ask Mira about Eli's draft]
    MIRA: He was going to turn my private life into a footnote. I wanted him embarrassed. I did not want him dead.
    -> late_interview
* [Ask Jo about the camera panel]
    JO: I opened it because the screen froze. I did not touch the recording. Those are different kinds of stupid.
    -> late_interview
* [Ask Sasha about the key]
    SASHA: The key was mine. Eli kept it because he liked being needed. That was his least expensive vice.
    -> late_interview
* [Leave the room]
    -> reconstruction

=== contradiction_review ===
You sort the statements into four piles. False. Misleading. Incomplete. Merely embarrassing.

Mira's departure time is false because an in-person purchase puts her in the café after she says she left. Her affair with Eli explains the lie without explaining the poison.

Arin's cough-drop story is false because the pharmacy record names aconite and lists no cough drops. His reason for buying it may be innocent. The lie is not.

Jo's description is incomplete. She saw the cup, not the face. Her silence about the camera panel protects her from losing a job. It does not protect a killer.

Sasha's claim that she and Eli never argued is technically tidy and practically useless. She means they did not argue in the way she defines arguing. The debt gives her a reason to lie about the volume of the conversation.

Dan's route memory is mistaken. His app sent him through the service alley. He was near the café, but the delivery cart makes him visible on the street during most of the death window.

* [Test Mira's statement]
    ~ discover_evidence("receipt_004")
    The receipt contradicts the departure time. You write down only that. The temptation to write "therefore guilty" is crossed out.
    -> contradiction_review
* [Test Arin's statement]
    ~ discover_evidence("pharmacy_footage")
    The pharmacy footage contradicts the cough-drop story. It gives Arin means, not yet the complete sequence.
    -> contradiction_review
* [Test Jo's statement]
    ~ discover_evidence("jo_statement")
    Jo's statement remains compatible with more than one person. Compatibility is not identification.
    -> contradiction_review
* [Open the alternatives]
    -> alternatives
* [Continue to the final file]
    -> accusation
* [Lay out the physical evidence]
    -> evidence_room

=== alternatives ===
The first theory is that Mira poisoned Eli after their private argument. It explains the lie and the access. It does not explain aconite in her possession.

The second theory is that Sasha poisoned Eli over the debt. It explains the argument and the missing key. It does not explain the pharmacy purchase or place her inside the camera gap.

The third theory is that Arin used the camera gap to put aconite under the lid. It explains the purchase, the wiped residue, and the death window. The theory still needs the cup's path and a reason for his false pharmacy story.

* [Keep Mira as possible]
    Mira remains possible while the case has only the receipt and the camera gap. Her false time is a contradiction, not a solution.
    -> alternatives
* [Keep Sasha as possible]
    Sasha remains possible while the case has motive and a missing key but no physical link to poison.
    -> alternatives
* [Keep Arin as possible]
    Arin remains possible because the pharmacy record is not a murder confession. It becomes stronger only when combined with the lid and toxicology.
    -> alternatives
* [Ask what eliminates a theory]
    A theory is eliminated by a conflict it cannot survive, not by the detective disliking it.
    -> alternatives
* [Return to the contradiction review]
    -> contradiction_review
* [Write the final argument]
    -> accusation

=== evidence_room ===
You clear the table. Each record gets one job. A receipt can place a person. A voicemail can exclude one. Neither gets to become a murder weapon because the room wants an answer.

The order matters. If you begin with Arin, every later clue becomes an accusation. If you begin with the evidence, Arin becomes a person who must be placed in a sequence.

* [Start with the receipt]
    ~ discover_evidence("receipt_004")
    You read Receipt \#004 aloud. Mira was present at 19:22. Her departure claim cannot remain true.
    Mira stops folding the till paper. Sasha looks at her, then away. The fact changes the interview and proves no more than presence.
    # evidence:receipt_004
    # outcome:valid_contradiction
    -> evidence_room
* [Add the camera log]
    ~ discover_evidence("camera_log")
    The camera outage covers 19:18 to 19:29. It creates a space in which an action could happen. It does not name the action or the actor.
    Jo presses her thumbnail into the edge of her horticulture notebook. Everyone else looks briefly relieved.
    # evidence:camera_log
    # outcome:inconclusive
    -> evidence_room
* [Add toxicology]
    ~ discover_evidence("toxicology")
    Aconite was in the drink. Eli died between 19:25 and 19:28. The drink must have been prepared or altered before he finished it.
    Nobody argues with the report. For the first time, the room is quiet for the same reason.
    # evidence:toxicology
    -> evidence_room
* [Add the pharmacy footage]
    ~ discover_evidence("pharmacy_footage")
    Arin bought aconite at the night-store pharmacy at 19:04 and lied about buying cough drops. This gives him access to the method and a reason to conceal the purchase.
    Arin peels at the tape on his finger. He calls the purchase research. The footage establishes means, not use.
    # evidence:pharmacy_footage
    # outcome:valid_contradiction
    -> evidence_room
* [Add the lid]
    ~ discover_evidence("cup_lid")
    The wiped rim matters because a person tried to remove a trace. The residue matters because the attempt failed. Means and concealment now point in the same direction.
    Arin says every person in the café touched a lid that night. Jo says not underneath one.
    # evidence:cup_lid
    -> evidence_room
* {cup_lid} [Lift the blue fiber from beneath the lid]
    ~ discover_evidence("tape_fiber")
    Before the lid was examined, the blue strand was ordinary lint. Beneath a wiped rim, matched to the tape on Arin's cut finger, it establishes contact with the concealed surface.
    Arin studies his hand. Jo studies Arin.
    # evidence:tape_fiber
    -> evidence_room
* [Read Eli's scheduled article]
    ~ discover_evidence("draft_email")
    The email names Arin. Attached invoices show restaurants paying for favorable reviews. Its scheduled publication gives Arin a reason to stop Eli before morning.
    Mira says Eli sent Arin the draft. Arin says motive is not action. You write down both.
    # evidence:draft_email
    -> evidence_room
* [Read the service-door log]
    ~ discover_evidence("service_log")
    A staff-loaned access tag opens the service door at 19:17 and records an exit at 19:25. The tag was signed out to Arin.
    Sasha remembers the bell at 19:25. Arin asks whether a borrowed tag can identify the borrower. It can identify the route and narrow who must explain it.
    # evidence:service_log
    -> evidence_room
* {receipt_004} [Take Mira's second statement]
    ~ discover_evidence("mira_statement")
    Confronted with the receipt, Mira admits the affair and places Arin beside Eli's cup at 19:23.
    Her first lie made her the strongest alternative. Her second statement does not erase it. It gives the lie a private purpose and the cup a witness.
    # evidence:mira_statement
    -> evidence_room
* [Develop the delivery-bike photo]
    ~ discover_evidence("delivery_photo")
    The photo catches Dan stealing Eli's parcel in the alley at 19:19. His tracker puts him two blocks away by 19:24.
    Dan admits the theft with visible relief. The record explains his evasions and excludes him from the cup when Eli drinks.
    # evidence:delivery_photo
    -> evidence_room
* [Play Sasha's voicemail]
    ~ discover_evidence("sasha_voicemail")
    The live call keeps Sasha outside from 19:20 through 19:27. Her anger is audible. So are traffic, the service-door bell, and her distance from the booth.
    Sasha asks you not to confuse an ugly alibi with a weak one.
    # evidence:sasha_voicemail
    -> evidence_room
* [Compare the panel and till log]
    ~ discover_evidence("panel_log")
    Jo opened the camera panel at 19:16. Her till login records uninterrupted orders through 19:24.
    The same record that explains the outage excludes her from carrying Eli's cup. Her mistake created opportunity shared by somebody else.
    # evidence:panel_log
    -> evidence_room
* {toxicology && pharmacy_footage && cup_lid && tape_fiber && draft_email && service_log} [Present the complete sequence]
    Arin buys aconite at 19:04. His borrowed tag opens the service door at 19:17. During the camera gap, he puts the tincture beneath Eli's lid and wipes the rim. The hidden fiber preserves contact. Eli drinks at 19:24. Arin exits at 19:25.
    Means, motive, method, contact, and opportunity now agree. The sequence still needs the alternatives tested rather than ignored.
    # outcome:complete_sequence
    -> evidence_room
* {(mira_statement && delivery_photo && sasha_voicemail) || (mira_statement && delivery_photo && panel_log) || (mira_statement && sasha_voicemail && panel_log) || (delivery_photo && sasha_voicemail && panel_log)} [Test the alternatives]
    Three independent exclusion records, joined to the physical chain, are enough to test the other accounts rather than wave them away. Mira's private lie lacks poison and contact. Dan leaves before Eli drinks. Sasha remains outside. Jo remains at the till.
    Their lesser wrongs remain in the file. None supplies an alternative sequence that survives the records on the table.
    # outcome:alternatives_excluded
    -> evidence_room
* [Ask what still needs proving]
    The answer depends on what is already on the table. Means without contact is suspicion. Contact without motive leaves alternatives. A complete sequence without exclusions is still only the best story in the room.
    # outcome:proof_gap
    -> evidence_room
* [Move to the confrontation]
    -> confrontation

=== confrontation ===
Arin sits with both hands around an empty glass. He has stopped making jokes. That is not evidence. It is a change in weather.

ARIN: You have the pharmacy footage.

You place the receipt beside it. Not the café receipt. The pharmacy receipt.

ARIN: I told you. It was for an article.

You place the toxicology report beside the pharmacy receipt.

ARIN: Aconite is used in articles about aconite.

You ask why the pharmacy record lists aconite and not cough drops.

ARIN: Because the pharmacist was in a hurry.

You ask whether the pharmacist was also in a hurry when he remembered the paper bag.

ARIN: People remember the shape of a bag because it is easier than remembering what was inside.

You place the cup lid down last.

ARIN: That is not mine.

You do not ask whether he touched it. You ask whether he understands why somebody wiped it.

ARIN: To remove a fingerprint.

The answer is too quick, then too quiet.

* [Ask about the blind spot]
    ARIN: I was not at the café during the outage.
    You ask whether he can prove that.
    ARIN: No. Nobody can prove a negative in a room with a broken camera.
    You write down that he understands the shape of the gap.
    -> confrontation
* [Ask about Eli's draft]
    ARIN: He was going to call the reviews fake.
    You ask whether they were.
    ARIN: The reviews were enthusiastic. There is a difference.
    You ask whether Eli was blackmailing him.
    ARIN: He called it an editorial conversation.
    -> confrontation
* [Ask why he lied]
    ARIN: Because the truth sounded worse.
    You ask whether it was worse than murder.
    ARIN: I did not murder him.
    This is the first direct answer he has given you.
    -> confrontation
* [Show the residue]
    ARIN: You cannot tell who held a cup from a little powder.
    You agree. The residue does not identify a hand. The pharmacy purchase, the timing, the camera gap, and the lie form the argument around it.
    -> confrontation
* [End the confrontation]
    -> evidence_room
