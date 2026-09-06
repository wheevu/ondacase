% Case 001 authored content: The Iced Americano at 7:22.
% Every fact and rule below is specific to this case. Generic deduction
% machinery (player state, requirements, proofs, knowledge states,
% accusation evaluation) lives in engine.pl and reads these hooks.
% Hidden truth stays in this module and is never part of case exports.
:- module(case_content, [
    culprit/1, victim/1, true_event/1,
    statement/1, evidence_fact/2, claims/3, deception/2,
    person/1, location/1, evidence/1, evidence_title/2, statement_title/2,
    core_evidence/1, exclusion_record/1, exclusion_count/1,
    proof_threshold_inference/1,
    inference/3, inference/1,
    statement_status/2, has_supported_status/1, statement_semantic/2,
    contradiction/3, evidence_meaning/2,
    evidence_available/1, why_locked/2,
    directly_excluded/2, selected_directly_excluded/3,
    selected_contradiction/4, selected_threshold_gaps/3,
    dimension_requirements/4,
    circular_reasoning/1,
    exclusion_inference/2,
    player_evidence/1, player_statement/2
]).

:- use_module('../../logic/case_data', []).

% Player state belongs to the case: saves persist it, the engine mutates it.
:- dynamic player_evidence/1, player_statement/2.

% Catalog facts are authored once in case_data; content reads them here.
person(Id) :- case_data:person_detail(Id, _, _, _).
location(Id) :- case_data:location_detail(Id, _, _).
evidence(Id) :- case_data:evidence_meta(Id, _, _).
evidence_title(Id, Title) :- case_data:evidence_meta(Id, Title, _).
statement_title(Id, Title) :- case_data:statement_detail(Id, Title).

statement(mira_left_1910).
statement(arin_cough_drops).
statement(jo_saw_cup_1921).
statement(jo_identified_mira).
statement(sasha_never_argued).
statement(dan_never_inside).
statement(dan_route_recollection).

% Canonical truth and raw evidence facts are intentionally not module exports
% of the case facade. Tests may still address them through case_content.
culprit(arin).
victim(eli).
true_event(dosed_cup(arin, 1160)).
true_event(drank(eli, 1164)).
true_event(death_window(eli, 1165, 1168)).

evidence_fact(receipt_004, receipt_in_person(mira, cafe, 1162)).
evidence_fact(camera_log, camera_offline(cafe, 1158, 1169)).
evidence_fact(toxicology, poison_in_drink(aconite)).
evidence_fact(toxicology, death_window(eli, 1165, 1168)).
evidence_fact(pharmacy_footage, bought(arin, aconite, store, 1144)).
evidence_fact(cup_lid, poison_beneath_lid(aconite)).
evidence_fact(cup_lid, wiped_rim).
evidence_fact(tape_fiber, fiber_match(arin, blue_tape)).
evidence_fact(tape_fiber, fiber_beneath_lid(blue_tape)).
evidence_fact(draft_email, motive(arin, suppress_review_fraud_story)).
evidence_fact(service_log, service_door_entry(arin, 1157)).
evidence_fact(service_log, service_door_exit(arin, 1165)).
evidence_fact(mira_statement, saw(mira, arin, beside_elis_booth, 1163)).
evidence_fact(delivery_photo, placed(dan, alley, 1159)).
evidence_fact(delivery_photo, tracked(dan, two_blocks_away, 1164)).
evidence_fact(delivery_photo, concealed_theft(dan, parcel)).
evidence_fact(sasha_voicemail, live_call_outside(sasha, 1160, 1167)).
evidence_fact(panel_log, opened_camera_panel(jo, 1156)).
evidence_fact(panel_log, till_active(jo, 1156, 1164)).
evidence_fact(jo_statement, saw(jo, familiar_person_with_cup, 1161)).
evidence_fact(jo_statement, identified(jo, mira)).

claims(mira, left(cafe, 1150), mira_left_1910).
claims(arin, bought(store, cough_drops, 1144), arin_cough_drops).
claims(jo, saw(familiar_person_with_cup, 1161), jo_saw_cup_1921).
claims(jo, person_with_cup_was(mira), jo_identified_mira).
claims(sasha, never_raised_voice_to(eli), sasha_never_argued).
claims(dan, never_entered(cafe), dan_never_inside).
claims(dan, left_area_at(1159), dan_route_recollection).

% Authored deception classes. They become player-visible only when supported.
deception(mira_left_1910, direct_falsehood).
deception(arin_cough_drops, direct_falsehood).
deception(jo_saw_cup_1921, incomplete).
deception(jo_identified_mira, mistaken).
deception(sasha_never_argued, technically_true_misleading).
deception(dan_never_inside, technically_true_misleading).
deception(dan_route_recollection, mistaken).

% The proof threshold is a named inference so the engine stays generic.
proof_threshold_inference(arin_case_proven).

core_evidence([toxicology, pharmacy_footage, cup_lid, tape_fiber, draft_email, service_log]).
exclusion_record(mira_statement).
exclusion_record(delivery_photo).
exclusion_record(sasha_voicemail).
exclusion_record(panel_log).

exclusion_count(Count) :-
    findall(Id, (exclusion_record(Id), player_evidence(Id)), Found),
    length(Found, Count).

evidence_available(mira_statement) :- !,
    player_evidence(receipt_004),
    player_statement(mira_left_1910, heard).
evidence_available(_).

statement_status(mira_left_1910, direct_falsehood) :-
    player_statement(mira_left_1910, heard), player_evidence(receipt_004).
statement_status(arin_cough_drops, direct_falsehood) :-
    player_statement(arin_cough_drops, heard), player_evidence(pharmacy_footage).
statement_status(jo_saw_cup_1921, incomplete) :-
    player_statement(jo_saw_cup_1921, heard), player_evidence(jo_statement).
statement_status(jo_identified_mira, mistaken) :-
    player_statement(jo_identified_mira, heard),
    player_evidence(cup_lid), player_evidence(tape_fiber), player_evidence(mira_statement).
statement_status(sasha_never_argued, technically_true_misleading) :-
    player_statement(sasha_never_argued, heard), player_evidence(sasha_voicemail).
statement_status(dan_never_inside, technically_true_misleading) :-
    player_statement(dan_never_inside, heard), player_evidence(delivery_photo).
statement_status(dan_route_recollection, mistaken) :-
    player_statement(dan_route_recollection, heard), player_evidence(delivery_photo).
% uncertainty when heard but no other classification applies
statement_status(Id, uncertainty) :-
    statement(Id), player_statement(Id, heard),
    \+ has_supported_status(Id).

has_supported_status(mira_left_1910) :- player_statement(mira_left_1910, heard), player_evidence(receipt_004).
has_supported_status(arin_cough_drops) :- player_statement(arin_cough_drops, heard), player_evidence(pharmacy_footage).
has_supported_status(jo_saw_cup_1921) :- player_statement(jo_saw_cup_1921, heard), player_evidence(jo_statement).
has_supported_status(jo_identified_mira) :- player_statement(jo_identified_mira, heard), player_evidence(cup_lid), player_evidence(tape_fiber), player_evidence(mira_statement).
has_supported_status(sasha_never_argued) :- player_statement(sasha_never_argued, heard), player_evidence(sasha_voicemail).
has_supported_status(dan_never_inside) :- player_statement(dan_never_inside, heard), player_evidence(delivery_photo).
has_supported_status(dan_route_recollection) :- player_statement(dan_route_recollection, heard), player_evidence(delivery_photo).

% semantic classification for brief: false, misleading, incomplete, mistaken, uncertainty
statement_semantic(Id, false) :- statement_status(Id, direct_falsehood).
statement_semantic(Id, misleading) :- statement_status(Id, technically_true_misleading).
statement_semantic(Id, incomplete) :- statement_status(Id, incomplete).
statement_semantic(Id, mistaken) :- statement_status(Id, mistaken).
statement_semantic(Id, uncertainty) :- statement_status(Id, uncertainty).

contradiction(mira_left_1910, receipt_004, purchase_requires_presence) :-
    statement_status(mira_left_1910, direct_falsehood).
contradiction(arin_cough_drops, pharmacy_footage, purchase_was_aconite) :-
    statement_status(arin_cough_drops, direct_falsehood).
contradiction(jo_identified_mira, tape_fiber, concealed_surface_contact_points_to_arin) :-
    statement_status(jo_identified_mira, mistaken).
contradiction(dan_route_recollection, delivery_photo, tracker_disagrees_with_recollection) :-
    statement_status(dan_route_recollection, mistaken).

% evidence meaning: tape fiber before cup lid is just lint
evidence_meaning(tape_fiber, lint) :-
    player_evidence(tape_fiber), \+ player_evidence(cup_lid).
evidence_meaning(tape_fiber, contact_with_concealed_surface) :-
    player_evidence(tape_fiber), player_evidence(cup_lid).
evidence_meaning(receipt_004, presence_not_guilt) :- player_evidence(receipt_004).
evidence_meaning(Id, supports_inference) :- player_evidence(Id), evidence(Id).

why_locked(mira_statement, need_receipt) :-
    \+ player_evidence(receipt_004).
why_locked(mira_statement, need_confrontation) :-
    player_evidence(receipt_004),
    \+ player_statement(mira_left_1910, heard).

% inference(Name, Requirements, Human-readable authored rule).
inference(mira_present_1922, [evidence(receipt_004)],
    "An in-person purchase places Mira in the cafe at 19:22").
inference(mira_departure_conflict, [statement(mira_left_1910), evidence(receipt_004)],
    "A 19:22 in-person purchase contradicts a 19:10 departure").
inference(camera_gap_confirmed, [evidence(camera_log)],
    "The west camera was offline from 19:18 through 19:29").
inference(death_window_established, [evidence(toxicology)],
    "Toxicology places death between 19:25 and 19:28").
inference(arin_means, [evidence(pharmacy_footage), evidence(toxicology)],
    "Arin bought the same poison found in Eli's drink").
inference(arin_delivery_method, [evidence(toxicology), evidence(cup_lid)],
    "Aconite beneath the wiped lid explains how the drink was dosed").
inference(arin_contact, [evidence(cup_lid), evidence(tape_fiber)],
    "The matching tape fiber places Arin in contact with the concealed surface").
inference(arin_motive, [evidence(draft_email)],
    "Eli's scheduled fraud story gave Arin a reason to stop publication").
inference(arin_opportunity, [evidence(service_log), evidence(toxicology)],
    "Arin's 19:25 service-door exit overlaps the death window").
inference(arin_method, [inference(arin_means), inference(arin_delivery_method), inference(arin_contact)],
    "Means, delivery method, and physical contact establish Arin's method").
inference(mira_opportunity, [evidence(receipt_004), evidence(camera_log), evidence(toxicology)],
    "Mira was present during the shared camera gap and death window").
inference(jo_opportunity, [evidence(panel_log), evidence(toxicology)],
    "Jo remained at the till through the start of the death window").
inference(dan_nearby_1919, [evidence(delivery_photo)],
    "The delivery photo places Dan in the alley at 19:19").
inference(mira_excluded, [evidence(mira_statement), evidence(cup_lid), evidence(tape_fiber)],
    "Mira's sighting and the matching fiber point away from Mira").
inference(sasha_excluded, [evidence(sasha_voicemail), evidence(toxicology)],
    "The live outside call covers the poisoning and death window").
inference(jo_excluded, [evidence(panel_log), evidence(cup_lid), evidence(tape_fiber)],
    "Till activity and the matching fiber point away from Jo").
inference(dan_excluded, [evidence(delivery_photo), evidence(toxicology)],
    "Dan was two blocks away before Eli drank").
inference(arin_case_proven, Requirements,
    "The core records and three independent exclusions meet the proof threshold") :-
    core_evidence(Core),
    findall(Id, (exclusion_record(Id), player_evidence(Id)), Found),
    engine:first_three(Found, Exclusions),
    append(Core, Exclusions, Evidence),
    maplist(engine:as_evidence_requirement, Evidence, Requirements).

inference(arin_case_proven).
inference(Name) :-
    inference(Name, _, _),
    Name \= arin_case_proven.

directly_excluded(mira, mira_excluded) :- engine:infer(mira_excluded).
directly_excluded(sasha, sasha_excluded) :- engine:infer(sasha_excluded).
directly_excluded(jo, jo_excluded) :- engine:infer(jo_excluded).
directly_excluded(dan, dan_excluded) :- engine:infer(dan_excluded).

% Maps each non-culprit to the inference that exonerates them.
exclusion_inference(mira, mira_excluded).
exclusion_inference(sasha, sasha_excluded).
exclusion_inference(jo, jo_excluded).
exclusion_inference(dan, dan_excluded).

selected_directly_excluded(mira, Selected, mira_excluded) :- subset([mira_statement, cup_lid, tape_fiber], Selected).
selected_directly_excluded(sasha, Selected, sasha_excluded) :- subset([sasha_voicemail, toxicology], Selected).
selected_directly_excluded(jo, Selected, jo_excluded) :- subset([panel_log, cup_lid, tape_fiber], Selected).
selected_directly_excluded(dan, Selected, dan_excluded) :- subset([delivery_photo, toxicology], Selected).

selected_contradiction(mira_left_1910, receipt_004, purchase_requires_presence, Selected) :-
    player_statement(mira_left_1910, heard), memberchk(receipt_004, Selected).
selected_contradiction(arin_cough_drops, pharmacy_footage, purchase_was_aconite, Selected) :-
    player_statement(arin_cough_drops, heard), memberchk(pharmacy_footage, Selected).
selected_contradiction(jo_identified_mira, tape_fiber, concealed_surface_contact_points_to_arin, Selected) :-
    player_statement(jo_identified_mira, heard), subset([cup_lid, tape_fiber, mira_statement], Selected).
selected_contradiction(dan_route_recollection, delivery_photo, tracker_disagrees_with_recollection, Selected) :-
    player_statement(dan_route_recollection, heard), memberchk(delivery_photo, Selected).

selected_threshold_gaps(arin, argument(_, _, _, Selected), Gaps) :- !,
    core_evidence(Core),
    subtract(Core, Selected, MissingCore),
    findall(Id, (exclusion_record(Id), memberchk(Id, Selected)), Exclusions),
    length(Exclusions, Count),
    Needed is max(0, 3 - Count),
    findall(Gap,
        ( (member(Id, MissingCore), Gap = gap(required_evidence, Id))
        ; (Needed > 0, Gap = gap(exclusion_records, Needed))
        ), Gaps).
selected_threshold_gaps(_, _, []).

dimension_requirements(arin, motive, [draft_email], supported).
dimension_requirements(arin, method, [pharmacy_footage, toxicology, cup_lid, tape_fiber], supported).
dimension_requirements(arin, opportunity, [service_log, toxicology], supported).
dimension_requirements(mira, motive, [mira_statement], partial).
dimension_requirements(mira, method, [toxicology, cup_lid], partial).
dimension_requirements(mira, opportunity, [receipt_004, camera_log, toxicology], supported).
dimension_requirements(jo, motive, [], missing).
dimension_requirements(jo, method, [cup_lid], partial).
dimension_requirements(jo, opportunity, [panel_log, toxicology], supported).
dimension_requirements(sasha, motive, [], missing).
dimension_requirements(sasha, method, [], missing).
dimension_requirements(sasha, opportunity, [], missing).
dimension_requirements(dan, motive, [delivery_photo], partial).
dimension_requirements(dan, method, [], missing).
dimension_requirements(dan, opportunity, [delivery_photo], partial).

circular_reasoning(Suspect) :- person(Suspect), fail. % no circular rules in this concrete case; always false
