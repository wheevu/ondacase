=== sasha ===
SASHA: I never raised my voice to Eli that night. # speaker:sasha

She says it while looking at the table where the argument happened. Her radio-tote sits on the chair, canvas repaired with careful blue thread. She speaks precisely, as if each word could be quoted.

SASHA: If you mean did we argue, ask that.

* [What happened between you and Eli?] # intent:neutral
    SASHA: He lent me rent money, then treated the loan as a character reference.
    You ask when you last spoke.
    SASHA: That night. Outside. Quietly.
    -> sasha
* [You argued that night, didn't you?] # intent:direct
    SASHA: Yes. He said I was borrowing time. I said he was selling it.
    You ask whether you raised your voice.
    SASHA: No. Eli could cut a person open at library volume. I learned to answer him there.
    -> sasha
* [You want "I never raised my voice" to sound like "we didn't argue."] # intent:accuse_lying
    SASHA: I want words to mean what they mean. We argued. I did not shout. Those are different failures.
    You note the dodge: technically true, meant to mislead.
    # outcome:misunderstood
    -> sasha
* [You came to get the key, not to talk.] # intent:confrontational
    SASHA: I came to take my key back from the blue dish by the till. He kept it because he liked having a reason to call me.
    You ask if the key opened the service door.
    SASHA: The front and the stockroom. Not the staff reader. Old metal, old locks, no clever light.
    -> sasha
* [Ask about the debt] # intent:direct
    SASHA: I owed him money. He knew. That is not the same as wanting him dead.
    You ask how much.
    SASHA: Enough that he stopped calling it a loan and started calling it evidence about me.
    -> sasha
* [Ask why she came] # intent:neutral
    SASHA: To get my key back. He kept it in the blue dish by the till because he enjoyed small ceremonies.
    You ask if the key opened the service door.
    SASHA: The front and the stockroom. Not the staff reader. Old metal, old locks, no clever little light.
    -> sasha
* [Press her on the argument] # intent:confrontational
    ~ record_statement("sasha_never_argued")
    SASHA: Yes. We argued. He said I was borrowing time. I said he was selling it.
    You point out that she wanted "no raised voices" to sound like "no argument."
    SASHA: Eli could cut a person open at library volume. I learned to answer him there.
    -> sasha
* [Play the saved voicemail] # intent:present_evidence
    ~ discover_evidence("sasha_voicemail")
    Her sister's voicemail begins at 19:20. Sasha answers from the pavement outside. Traffic passes behind her until 19:27.
    SASHA: I called because I needed somebody to stop me going back in.
    You ask why she withheld an alibi.
    SASHA: Because the first four minutes are me describing exactly how much I hated him.
    # evidence:sasha_voicemail
    # outcome:supporting
    -> sasha
* {service_log} [Compare the metal key with the service log] # intent:present_evidence
    The staff reader records a loaned access tag, not Sasha's key. Her missing key could admit her through the front, but it did not make the 19:25 service-door record.
    SASHA: Eli loved replacing ordinary objects with systems. For once, one of them can speak for me.
    # evidence:service_log
    # outcome:unrelated
    -> sasha
* [Present the café loyalty card] # intent:present_evidence
    SASHA: That is mine. Three stamps. It proves I buy coffee.
    You note the card is unrelated to the poisoning sequence.
    # outcome:unrelated
    -> sasha
* [Play the voicemail again, about the bell] # intent:direct
    SASHA: The bell is at 19:25 on the recording. I heard it while saying something unforgivable. I did not look.
    You note the repeat. Same bell, same traffic, no new claim.
    -> sasha
* {sasha_voicemail} [Ask what she heard from outside] # intent:direct
    SASHA: The service-door bell at about 19:25. Then a bicycle chain. I did not look around. I was busy saying something unforgivable about a dead man who was not dead yet.
    The call fixes her outside through the death window. It also fixes the bell in the sequence.
    # outcome:sasha_excluded
    -> sasha
* [Ask about the repaired radio] # intent:change_subject
    SASHA: Burned capacitor, dead left channel. Both honest faults. I repair them because broken things should at least be specific.
    You let the subject change settle, then return to 19:20.
    -> sasha
* [Ask one ordinary question] # intent:flavor
    -> sasha_personal
* [Leave] # intent:leave
    -> END

=== sasha_personal ===
Sasha carries a pocket radio with its back plate held on by two different screws. The canvas tote beside it is repaired with blue thread.

* [Ask about the tote] # intent:flavor
    SASHA: I stole it from Eli's office. He had six.
    You ask if that was the worst thing she stole.
    SASHA: No. But it was the most useful.
    -> sasha_personal
* [Ask about the radio] # intent:neutral
    SASHA: Dead channel in the left speaker. Burned capacitor. Both honest faults.
    You ask if she repairs them for work.
    SASHA: No. I repair them because broken things should at least have the decency to be specific.
    -> sasha_personal
* [Ask about the debt] # intent:direct
    SASHA: It was rent money. He lent it, then began treating the loan as a character reference.
    -> sasha_personal
* [Return to the case] # intent:change_subject
    -> sasha
