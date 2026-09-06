=== arrival ===
The victim's name is Eli Venn. The room's first version of the truth is simple: he drank something, he died, and everyone nearby has a reason to prefer a different version.

You open the case file.

* [Inspect the receipt]
    ~ discover_evidence("receipt_004")
    The receipt says 19:22. Mira says she left at 19:10.
    -> arrival
* [Ask about the camera]
    ~ discover_evidence("camera_log")
    Eleven minutes have gone missing from the west camera.
    -> arrival
* [Talk to Mira]
    -> mira
* [Talk to Arin]
    -> arin
* [Talk to Jo]
    -> jo
* [Talk to Sasha]
    -> sasha
* [Talk to Dan]
    -> dan
* [Open the reconstruction file]
    -> reconstruction
* [Visit the service alley]
    -> alley
* [Visit the night store]
    -> pharmacy
* [Visit Eli's apartment]
    -> apartment
* [Leave the café]
    -> END
