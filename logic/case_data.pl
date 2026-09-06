% Canonical Case 001 metadata. Single source for the player-safe manifest,
% display titles, timeline, locations, board layout data, and lock reasons.
% Hidden truth (culprit, raw facts, deception classes) lives in case_content.
:- module(case_data, [
    case_id/1, case_title/1, victim/1, time_basis/1,
    person_detail/4, location_detail/3, location_evidence/3,
    evidence_meta/3, evidence_supports/2,
    statement_detail/2,
    timeline_event/4,
    ending/1,
    board_node/3,
    person_name/2, inference_title/2, reason_title/2,
    lock_reason_text/2
]).

case_id('001-americano').
case_title("The iced americano at 7:22").
victim(eli).
time_basis(minutes_after_midnight).

% person_detail(Id, Name, Age, Role).
person_detail(mira, "Mira Vale", 31, "Café manager").
person_detail(arin, "Arin Ko", 34, "Food columnist").
person_detail(jo, "Jo Bell", 24, "Barista").
person_detail(sasha, "Sasha Reed", 30, "Eli's ex").
person_detail(dan, "Dan Mott", 27, "Delivery rider").

% location_detail(Id, Name, Note).
location_detail(cafe, "CAFÉ LANTERN",
    "The room is still open. Nobody is ordering anything.").
location_detail(alley, "SERVICE ALLEY",
    "Wet concrete, a staff door, and a route that keeps moving.").
location_detail(store, "NIGHT STORE",
    "The pharmacy counter sees the bottle, the bag, and the time.").
location_detail(apartment, "ELI'S APARTMENT",
    "The desk holds the story Eli meant to publish.").

% location_evidence(Location, Evidence, InspectLabel).
location_evidence(cafe, receipt_004, "INSPECT RECEIPT #004").
location_evidence(cafe, camera_log, "CHECK CAMERA LOG").
location_evidence(cafe, toxicology, "READ TOXICOLOGY").
location_evidence(cafe, cup_lid, "INSPECT CUP LID").
location_evidence(cafe, jo_statement, "FILE JO'S ACCOUNT").
location_evidence(cafe, panel_log, "CHECK PANEL LOG").
location_evidence(alley, service_log, "CHECK SERVICE-DOOR LOG").
location_evidence(alley, delivery_photo, "CHECK BIKE PHOTO").
location_evidence(store, pharmacy_footage, "REVIEW PHARMACY FOOTAGE").
location_evidence(apartment, draft_email, "OPEN DRAFT EMAIL").
location_evidence(apartment, sasha_voicemail, "PLAY SAVED VOICEMAIL").

% evidence_meta(Id, Title, Status).
evidence_meta(receipt_004, "Receipt #004", confirmed).
evidence_meta(camera_log, "West camera log", confirmed).
evidence_meta(toxicology, "Toxicology report", confirmed).
evidence_meta(pharmacy_footage, "Pharmacy footage", confirmed).
evidence_meta(cup_lid, "Cup lid", confirmed).
evidence_meta(tape_fiber, "Blue tape fiber", confirmed).
evidence_meta(draft_email, "Eli's draft email", confirmed).
evidence_meta(service_log, "Service-door log", confirmed).
evidence_meta(mira_statement, "Mira's follow-up statement", claimed).
evidence_meta(delivery_photo, "Delivery-bike photo and tracker", confirmed).
evidence_meta(sasha_voicemail, "Sasha's voicemail", confirmed).
evidence_meta(panel_log, "Till and camera-panel log", confirmed).
evidence_meta(jo_statement, "Jo's statement", claimed).

% evidence_supports(Evidence, Inference).
evidence_supports(receipt_004, mira_present_1922).
evidence_supports(receipt_004, mira_departure_conflict).
evidence_supports(receipt_004, mira_opportunity).
evidence_supports(camera_log, camera_gap_confirmed).
evidence_supports(camera_log, mira_opportunity).
evidence_supports(toxicology, death_window_established).
evidence_supports(toxicology, arin_means).
evidence_supports(toxicology, arin_delivery_method).
evidence_supports(toxicology, arin_opportunity).
evidence_supports(pharmacy_footage, arin_means).
evidence_supports(cup_lid, arin_delivery_method).
evidence_supports(cup_lid, arin_contact).
evidence_supports(tape_fiber, arin_contact).
evidence_supports(draft_email, arin_motive).
evidence_supports(service_log, arin_opportunity).
evidence_supports(mira_statement, mira_excluded).
evidence_supports(delivery_photo, dan_nearby_1919).
evidence_supports(delivery_photo, dan_excluded).
evidence_supports(sasha_voicemail, sasha_excluded).
evidence_supports(panel_log, jo_opportunity).
evidence_supports(panel_log, jo_excluded).

% statement_detail(Id, Title).
statement_detail(mira_left_1910, "Mira said she left at 19:10").
statement_detail(arin_cough_drops, "Arin called the purchase cough drops").
statement_detail(jo_saw_cup_1921, "Jo saw someone carrying Eli's cup").
statement_detail(jo_identified_mira, "Jo identified the person as Mira").
statement_detail(sasha_never_argued, "Sasha said she never raised her voice").
statement_detail(dan_never_inside, "Dan said he never went inside the cafe").
statement_detail(dan_route_recollection, "Dan recalled leaving by 19:19").

% timeline_event(DisplayTime, Event, Status, RequiresEvidence).
timeline_event('18:52', "Sasha arrives to recover her apartment key", claimed, []).
timeline_event('18:58', "Dan delivers café supplies", claimed, []).
timeline_event('19:04', "Arin visits the night-store pharmacy counter", confirmed, [pharmacy_footage]).
timeline_event('19:16', "Jo opens the west-camera panel", confirmed, [panel_log]).
timeline_event('19:18', "West café camera goes offline", confirmed, [camera_log]).
timeline_event('19:19', "A delivery-bike photo places Dan in the alley", confirmed, [delivery_photo]).
timeline_event('19:21', "Jo sees a familiar person carrying Eli's cup", claimed, [jo_statement]).
timeline_event('19:22', "Mira makes an in-person purchase", confirmed, [receipt_004]).
timeline_event('19:23', "Mira sees Arin beside Eli's booth", claimed, [mira_statement]).
timeline_event('19:24', "Eli drinks the iced americano", confirmed, [toxicology]).
timeline_event('19:25', "Arin's borrowed tag exits through the service door", confirmed, [service_log]).
timeline_event('19:25-19:28', "Eli dies from aconite", confirmed, [toxicology]).
timeline_event('19:29', "West café camera returns", confirmed, [camera_log]).
timeline_event('19:34', "Jo finds Eli", confirmed, []).

ending(conviction).
ending(lucky_idiot).
ending(beautiful_theory).
ending(insufficient_evidence).
ending(everybody_goes_home).

% board_node(Id, Kind, Requires). Requires name evidence or statement ids.
% Layout coordinates and display labels stay in the Fennel presentation layer.
board_node(mira_conflict, contradiction, [receipt_004, mira_left_1910]).
board_node(arin_means, proven, [pharmacy_footage]).
board_node(eli_victim, proven, []).
board_node(camera_gap, proven, [camera_log]).
board_node(cup_lid, proven, [cup_lid]).
board_node(tape_fiber, proven, [cup_lid, tape_fiber]).
board_node(motive_note, hypothesis, [draft_email]).

person_name(mira, "Mira Vale").
person_name(arin, "Arin Ko").
person_name(jo, "Jo Bell").
person_name(sasha, "Sasha Reed").
person_name(dan, "Dan Mott").

inference_title(mira_present_1922, "Mira was present at 19:22").
inference_title(mira_departure_conflict, "Mira's departure claim is contradicted").
inference_title(camera_gap_confirmed, "The west camera gap is confirmed").
inference_title(death_window_established, "The death window is established").
inference_title(arin_means, "Arin had access to aconite").
inference_title(arin_delivery_method, "The poison was placed beneath the lid").
inference_title(arin_contact, "Arin contacted the concealed surface").
inference_title(arin_motive, "Arin had a motive to stop publication").
inference_title(arin_opportunity, "Arin had the required opportunity").
inference_title(arin_method, "Arin's method is established").
inference_title(mira_opportunity, "Mira shared the opportunity window").
inference_title(jo_opportunity, "Jo shared the opportunity window").
inference_title(dan_nearby_1919, "Dan was nearby at 19:19").
inference_title(mira_excluded, "The evidence excludes Mira").
inference_title(sasha_excluded, "The evidence excludes Sasha").
inference_title(jo_excluded, "The evidence excludes Jo").
inference_title(dan_excluded, "The evidence excludes Dan").
inference_title(arin_case_proven, "The case against Arin meets the proof threshold").

reason_title(purchase_requires_presence, "The later in-person purchase requires Mira's presence").
reason_title(purchase_was_aconite, "The recorded purchase was aconite, not cough drops").
reason_title(concealed_surface_contact_points_to_arin, "The matching fiber points to Arin, not Mira").
reason_title(tracker_disagrees_with_recollection, "Dan's tracker contradicts his route recollection").

lock_reason_text(need_receipt, "File Receipt #004 first.").
lock_reason_text(need_confrontation, "Confront Mira about 19:10 first.").
