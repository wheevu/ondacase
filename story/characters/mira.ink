=== mira ===
MIRA: I left at ten past seven. # speaker:mira

She folds the corner of the till roll into a bird no bigger than your thumbnail. Her voice is flat, café-manager steady, as if a correct tone could hold a false time in place.

{receipt_004: You have Receipt \#004, stamped 19:22.}

* [Ask who had her card] # intent:neutral
    MIRA: Eli did. He had a talent for making small invasions sound like favors.
    You ask when he last borrowed it.
    MIRA: Weeks ago. Maybe months. I did not keep a ledger of every irritating thing Eli did.
    The paper bird loses one wing under her thumb.
    -> mira
* [What time did you actually leave?] # intent:direct
    MIRA: I told you. Ten past.
    You ask her to check the clock on the till, not her memory.
    MIRA: The till says what the till says. I say what I need to say until you show me otherwise.
    -> mira
* [You are lying about 19:10.] # intent:accuse_lying
    MIRA: Then prove it without a receipt you have not shown me.
    You note the dare. She wants the confrontation to be about manners, not minutes.
    # outcome:valid_contradiction
    -> mira
* [Ask about Eli] # intent:neutral
    MIRA: He was going to publish something about me. Not the café. Me.
    You ask what he had to publish.
    MIRA: A private mistake. He thought privacy was what people called facts before he printed them.
    -> mira
* {receipt_004} [Show Receipt 004] # intent:present_evidence
    ~ record_statement("mira_left_1910")
    MIRA: Then somebody used my card.
    You put the receipt between you. In-person purchase. Iced americano. Manager card ending 4412.
    MIRA: Fine. I was still here. I met Eli. That does not make me the person who killed him.
    # evidence:receipt_004
    # outcome:valid_contradiction
    -> mira
* {receipt_004} [You said you left, but the receipt says you bought a drink at 19:22.] # intent:confrontational
    ~ record_statement("mira_left_1910")
    MIRA: Yes. I was here at 19:22. I already told you someone could have used my card, then I told you I stayed. Pick the version you earned.
    You ask which version explains why she folded a bird instead of answering.
    MIRA: Anxiety does not time-stamp itself. The receipt does.
    # evidence:receipt_004
    # outcome:valid_contradiction
    -> mira
* {receipt_004} [Ask what she was hiding] # intent:direct
    MIRA: We were seeing each other. Quietly, badly, and after both of us had agreed to stop.
    She unfolds the ruined bird and smooths the receipt flat.
    MIRA: I lied because I could already see the headline you would give the truth.
    -> mira
* {receipt_004} [Ask what she saw at 19:23] # intent:present_evidence
    ~ discover_evidence("mira_statement")
    MIRA: Arin was beside Eli's booth. One hand on the table, one below it. I thought he was moving the drink out of the way.
    You ask why she kept that out of her first statement.
    MIRA: Because saying where he stood meant saying where I stood.
    # evidence:mira_statement
    # outcome:supporting
    -> mira
* {draft_email} [Present Eli's draft email] # intent:present_evidence
    MIRA: That was the piece he wanted me to read. Invoices, paid reviews, Arin's name in the subject line.
    You ask whether Arin knew.
    MIRA: Eli made sure. He preferred a threat with a read receipt.
    # evidence:draft_email
    # outcome:supporting
    -> mira
* {receipt_004} [Ask again what she saw at 19:23] # intent:direct
    MIRA: I already told you. Arin beside the booth, hand below the rim. You want a different memory. I do not have one.
    You note the repetition. Same place, same hand, no new ornament. That is how a real second telling sounds.
    -> mira
* [Talk about the basil plant instead] # intent:change_subject
    MIRA: The basil is dying. I water it too much. Jo tells me often.
    You let her hold the other subject for a breath, then return.
    -> mira
* [Ask one ordinary question] # intent:flavor
    -> mira_personal
* [Leave the interview] # intent:leave
    -> END

=== mira_personal ===
Mira keeps a basil plant above the espresso machine. Half its leaves are brown. Beside it sits a row of tiny birds folded from spoiled till paper.

* [Ask about the plant] # intent:flavor
    MIRA: Jo says I overwater it. Jo says that about most things.
    You ask if she plans to replace it.
    MIRA: No. If it survives, it gets a story. If it does not, it gets compost.
    -> mira_personal
* [Ask about the café] # intent:neutral
    MIRA: The café was my mother's idea. She wanted a place where nobody had to explain why they were alone.
    You ask whether Eli understood that.
    MIRA: Eli understood everything five minutes after it stopped helping him.
    -> mira_personal
* [Return to the case] # intent:change_subject
    -> mira
