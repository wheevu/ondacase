% Case 001: The Iced Americano at 7:22
% Only player-safe predicates are exported. Authored truth stays private.

:- module(case, [
    person/1, location/1, evidence/1, evidence_title/2,
    statement/1, statement_title/2, inference/1,
    clear_player/0, discover_evidence/1, record_statement/1,
    player_evidence/1, player_statement/2,
    infer/1, proof/2, contradiction/3, statement_status/2, statement_semantic/2,
    knowledge/2, possible_suspect/1, impossible_suspect/1,
    accusation/2, accusation/3, api/2,
    evaluate_evidence/2, evaluate_hypothesis/2, possible_alternatives/1,
    evidence_meaning/2, consistent/1, circular_reasoning/1
]).

:- dynamic player_statement/2, player_evidence/1.

person(mira). person(arin). person(jo). person(sasha). person(dan).
location(cafe). location(alley). location(store). location(apartment).

evidence(receipt_004).
evidence(camera_log).
evidence(toxicology).
evidence(pharmacy_footage).
evidence(cup_lid).
evidence(tape_fiber).
evidence(draft_email).
evidence(service_log).
evidence(mira_statement).
evidence(delivery_photo).
evidence(sasha_voicemail).
evidence(panel_log).
evidence(jo_statement).

evidence_title(receipt_004, "Receipt #004").
evidence_title(camera_log, "West camera log").
evidence_title(toxicology, "Toxicology report").
evidence_title(pharmacy_footage, "Pharmacy footage").
evidence_title(cup_lid, "Cup lid").
evidence_title(tape_fiber, "Blue tape fiber").
evidence_title(draft_email, "Eli's draft email").
evidence_title(service_log, "Service-door log").
evidence_title(mira_statement, "Mira's follow-up statement").
evidence_title(delivery_photo, "Delivery-bike photo and tracker").
evidence_title(sasha_voicemail, "Sasha's voicemail").
evidence_title(panel_log, "Till and camera-panel log").
evidence_title(jo_statement, "Jo's statement").

statement(mira_left_1910).
statement(arin_cough_drops).
statement(jo_saw_cup_1921).
statement(jo_identified_mira).
statement(sasha_never_argued).
statement(dan_never_inside).
statement(dan_route_recollection).

statement_title(mira_left_1910, "Mira said she left at 19:10").
statement_title(arin_cough_drops, "Arin called the purchase cough drops").
statement_title(jo_saw_cup_1921, "Jo saw someone carrying Eli's cup").
statement_title(jo_identified_mira, "Jo identified the person as Mira").
statement_title(sasha_never_argued, "Sasha said she never raised her voice").
statement_title(dan_never_inside, "Dan said he never went inside the cafe").
statement_title(dan_route_recollection, "Dan recalled leaving by 19:19").

% Canonical truth and raw evidence facts are intentionally not module exports.
culprit(arin).
victim(eli).
true_event(dosed_cup(arin, 1160)).
true_event(drank(eli, 1164)).
true_event(death_window(eli, 1165, 1168)).

% All times are integer minutes after midnight. No lexical atom comparison.
minute_of_day(Hour, Minute, Value) :-
    integer(Hour), integer(Minute), between(0, 23, Hour), between(0, 59, Minute),
    Value is Hour * 60 + Minute.
before(A, B) :- integer(A), integer(B), A < B.
within(Time, Start, End) :- integer(Time), Time >= Start, Time =< End.

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

clear_player :-
    retractall(player_statement(_, _)),
    retractall(player_evidence(_)).

discover_evidence(Id) :-
    evidence(Id),
    evidence_available(Id),
    ( player_evidence(Id) -> true ; assertz(player_evidence(Id)) ).

evidence_available(mira_statement) :- !,
    player_evidence(receipt_004),
    player_statement(mira_left_1910, heard).
evidence_available(_).

record_statement(Id) :-
    statement(Id),
    ( player_statement(Id, heard) -> true ; assertz(player_statement(Id, heard)) ).

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
    first_three(Found, Exclusions),
    append(Core, Exclusions, Evidence),
    maplist(as_evidence_requirement, Evidence, Requirements).

inference(arin_case_proven).
inference(Name) :-
    inference(Name, _, _),
    Name \= arin_case_proven.

first_three([A, B, C|_], [A, B, C]).
as_evidence_requirement(Id, evidence(Id)).

infer(Name) :-
    inference(Name, Requirements, _),
    requirements_met(Requirements).

requirements_met([]).
requirements_met([Requirement|Rest]) :-
    requirement_met(Requirement),
    requirements_met(Rest).

requirement_met(evidence(Id)) :- player_evidence(Id).
requirement_met(statement(Id)) :- player_statement(Id, heard).
requirement_met(inference(Name)) :- infer(Name).

proof(Name, proof(Name, Premises, Rule)) :-
    infer(Name),
    inference(Name, Requirements, Rule),
    proof_premises(Requirements, Premises).

proof_premises([], []).
proof_premises([evidence(Id)|Rest], [evidence(Id)|Premises]) :-
    proof_premises(Rest, Premises).
proof_premises([statement(Id)|Rest], [statement(Id)|Premises]) :-
    proof_premises(Rest, Premises).
proof_premises([inference(Name)|Rest], [inference(Name, Proof)|Premises]) :-
    proof(Name, Proof),
    proof_premises(Rest, Premises).

core_evidence([toxicology, pharmacy_footage, cup_lid, tape_fiber, draft_email, service_log]).
exclusion_record(mira_statement).
exclusion_record(delivery_photo).
exclusion_record(sasha_voicemail).
exclusion_record(panel_log).

exclusion_count(Count) :-
    findall(Id, (exclusion_record(Id), player_evidence(Id)), Found),
    length(Found, Count).

case_complete :- infer(arin_case_proven).

directly_excluded(mira, mira_excluded) :- infer(mira_excluded).
directly_excluded(sasha, sasha_excluded) :- infer(sasha_excluded).
directly_excluded(jo, jo_excluded) :- infer(jo_excluded).
directly_excluded(dan, dan_excluded) :- infer(dan_excluded).

impossible_suspect(Suspect) :-
    person(Suspect), Suspect \= arin,
    ( directly_excluded(Suspect, _) -> true ; case_complete ).

possible_suspect(Suspect) :-
    person(Suspect),
    \+ impossible_suspect(Suspect).

possible_alternatives(List) :-
    findall(Suspect, (possible_suspect(Suspect)), List).

knowledge(discovered, evidence(Id)) :- player_evidence(Id).
knowledge(discovered_fact, evidence(Id)) :- player_evidence(Id).
knowledge(inferred, Fact) :- infer(Fact).
knowledge(inferred_fact, Fact) :- infer(Fact).
knowledge(hypothesized, suspect(Suspect)) :- person(Suspect).
knowledge(hypothesis, suspect(Suspect)) :- person(Suspect).
knowledge(contradicted, statement(Statement)) :- contradiction(Statement, _, _).
knowledge(possible, suspect(Suspect)) :- possible_suspect(Suspect).
knowledge(impossible, suspect(Suspect)) :- impossible_suspect(Suspect).
knowledge(proven, suspect(arin)) :- case_complete.
knowledge(proven_concept, suspect(arin)) :- case_complete.

% evaluate evidence and hypothesis for player API
evaluate_evidence(Id, evaluation(Id, relevant, supports(Found))) :-
    evidence(Id), player_evidence(Id),
    findall(Inf, (inference(Inf, Reqs, _), member(evidence(Id), Reqs), infer(Inf)), Found).
evaluate_evidence(Id, evaluation(Id, pending, supports([]))) :-
    evidence(Id), \+ player_evidence(Id).
evaluate_evidence(Id, evaluation(Id, discovered_no_inference, supports([]))) :-
    evidence(Id), player_evidence(Id),
    \+ (inference(_, Reqs, _), member(evidence(Id), Reqs), infer(_)).

evaluate_hypothesis(suspect(Suspect), evaluation(Suspect, Status, Details)) :-
    person(Suspect),
    ( possible_suspect(Suspect) -> Status = viable ; Status = excluded ),
    findall(dimension(Name, DimStatus, Support, Missing),
        (member(Name, [motive, method, opportunity]), dimension_evaluation(Suspect, Name, DimStatus, Support, Missing)), Details).
evaluate_hypothesis(Suspect, Eval) :- person(Suspect), evaluate_hypothesis(suspect(Suspect), Eval).

consistent(Suspect) :-
    person(Suspect),
    \+ ignored_contradiction(Suspect, _).
circular_reasoning(Suspect) :- person(Suspect), fail. % no circular rules in this concrete case; always false

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

dimension_evaluation(Suspect, Dimension, Status, Support, Missing) :-
    dimension_requirements(Suspect, Dimension, Required, Maximum),
    partition_discovered(Required, Support, Missing),
    dimension_status(Suspect, Dimension, Maximum, Support, Missing, Status).

dimension_status(Suspect, _, _, _, _, contradicted) :-
    impossible_suspect(Suspect), !.
dimension_status(_, _, missing, _, _, missing) :- !.
dimension_status(_, _, Maximum, _, [], Maximum) :- !.
dimension_status(_, _, _, [], _, missing) :- !.
dimension_status(_, _, _, _, _, partial).

partition_discovered([], [], []).
partition_discovered([Id|Rest], [Id|Found], Missing) :-
    player_evidence(Id), !,
    partition_discovered(Rest, Found, Missing).
partition_discovered([Id|Rest], Found, [Id|Missing]) :-
    partition_discovered(Rest, Found, Missing).

accusation(Suspect, evaluation(
    sufficient_evidence(Sufficient),
    unique_solution(Unique),
    ending(Ending),
    dimensions(Dimensions),
    unsupported(Unsupported),
    alternatives(Alternatives),
    ignored_contradictions(Ignored)
)) :-
    findall(Id, player_evidence(Id), Selected),
    findall(Id, (dimension_requirements(Suspect, motive, Required, _), member(Id, Required), memberchk(Id, Selected)), Motive),
    findall(Id, (dimension_requirements(Suspect, method, Required, _), member(Id, Required), memberchk(Id, Selected)), Method),
    findall(Id, (dimension_requirements(Suspect, opportunity, Required, _), member(Id, Required), memberchk(Id, Selected)), Opportunity),
    accusation(Suspect, argument(Motive, Method, Opportunity, Selected), evaluation(
        sufficient_evidence(Sufficient), unique_solution(Unique), ending(Ending),
        dimensions(Dimensions), unsupported(Unsupported), alternatives(Alternatives),
        ignored_contradictions(Ignored))).

accusation(Suspect, argument(Motive, Method, Opportunity, Selected), evaluation(
    sufficient_evidence(Sufficient),
    unique_solution(Unique),
    ending(Ending),
    dimensions(Dimensions),
    unsupported(Unsupported),
    alternatives(Alternatives),
    ignored_contradictions(Ignored)
)) :-
    person(Suspect),
    append([Motive, Method, Opportunity], SubmittedPremises),
    subset(SubmittedPremises, Selected),
    maplist(player_evidence, Selected),
    truth_value(culprit(Suspect), Correct),
    findall(dimension(Name, Status, Support, Missing),
        (argument_dimension(Name, Motive, Method, Opportunity, Submitted),
         selected_dimension_evaluation(Suspect, Name, Submitted, Selected, Status, Support, Missing)), Dimensions),
    accusation_gaps(Suspect, Dimensions, argument(Motive, Method, Opportunity, Selected), Unsupported),
    truth_value((Suspect == arin, selected_case_complete(Selected)), Unique),
    truth_value((Unique == true, dimensions_supported(Dimensions), \+ member(gap(unsupported_premise, _, _), Unsupported)), Sufficient),
    accusation_ending(Correct, Sufficient, Suspect, Dimensions, Ending),
    findall(alternative(Other, Status, Reason),
        selected_accusation_alternative(Suspect, Selected, Other, Status, Reason), Alternatives),
    findall(Item, selected_ignored_contradiction(Suspect, Selected, Item), Ignored).

argument_dimension(motive, Motive, _, _, Motive).
argument_dimension(method, _, Method, _, Method).
argument_dimension(opportunity, _, _, Opportunity, Opportunity).

selected_dimension_evaluation(Suspect, Dimension, Submitted, Selected, Status, Support, Missing) :-
    dimension_requirements(Suspect, Dimension, Required, Maximum),
    intersection(Required, Submitted, Support),
    subtract(Required, Support, Missing),
    selected_dimension_status(Suspect, Selected, Maximum, Support, Missing, Status).

selected_dimension_status(Suspect, Selected, _, _, _, contradicted) :-
    selected_impossible_suspect(Suspect, Selected), !.
selected_dimension_status(_, _, missing, _, _, missing) :- !.
selected_dimension_status(_, _, Maximum, _, [], Maximum) :- !.
selected_dimension_status(_, _, _, [], _, missing) :- !.
selected_dimension_status(_, _, _, _, _, partial).

dimensions_supported(Dimensions) :-
    forall(member(dimension(_, Status, _, _), Dimensions), Status == supported).

selected_case_complete(Selected) :-
    core_evidence(Core), subset(Core, Selected),
    findall(Id, (exclusion_record(Id), memberchk(Id, Selected)), Exclusions),
    length(Exclusions, Count), Count >= 3.

selected_directly_excluded(mira, Selected, mira_excluded) :- subset([mira_statement, cup_lid, tape_fiber], Selected).
selected_directly_excluded(sasha, Selected, sasha_excluded) :- subset([sasha_voicemail, toxicology], Selected).
selected_directly_excluded(jo, Selected, jo_excluded) :- subset([panel_log, cup_lid, tape_fiber], Selected).
selected_directly_excluded(dan, Selected, dan_excluded) :- subset([delivery_photo, toxicology], Selected).

selected_impossible_suspect(Suspect, Selected) :-
    Suspect \= arin,
    ( selected_directly_excluded(Suspect, Selected, _) -> true ; selected_case_complete(Selected) ).

truth_value(Goal, true) :- call(Goal), !.
truth_value(_, false).

accusation_ending(true, true, _, _, conviction) :- !.
accusation_ending(true, false, _, _, lucky_idiot) :- !.
accusation_ending(false, _, _, Dimensions, beautiful_theory) :-
    memberchk(dimension(opportunity, Status, _, _), Dimensions),
    memberchk(Status, [supported, partial]), !.
accusation_ending(false, _, _, _, insufficient_evidence).

accusation_gaps(Suspect, Dimensions, Argument, Gaps) :-
    findall(gap(dimension, Name, Status, Missing),
        (member(dimension(Name, Status, _, Missing), Dimensions), Status \= supported), DimensionGaps),
    findall(gap(unsupported_premise, Name, Id),
        (argument_dimension(Name, Argument, Submitted), dimension_requirements(Suspect, Name, Required, _),
         member(Id, Submitted), \+ memberchk(Id, Required)), PremiseGaps),
    selected_threshold_gaps(Suspect, Argument, ThresholdGaps),
    append([DimensionGaps, PremiseGaps, ThresholdGaps], Gaps).

argument_dimension(Name, argument(Motive, Method, Opportunity, _), Values) :-
    argument_dimension(Name, Motive, Method, Opportunity, Values).

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

accusation_alternative(Accused, Other, possible, not_excluded) :-
    person(Other), Other \= Accused, possible_suspect(Other).
accusation_alternative(Accused, Other, impossible, Rule) :-
    person(Other), Other \= Accused, impossible_suspect(Other),
    ( directly_excluded(Other, Rule) -> true ; Rule = complete_case_threshold ).

selected_accusation_alternative(Accused, Selected, Other, possible, not_excluded) :-
    person(Other), Other \= Accused, \+ selected_impossible_suspect(Other, Selected).
selected_accusation_alternative(Accused, Selected, Other, impossible, Rule) :-
    person(Other), Other \= Accused, selected_impossible_suspect(Other, Selected),
    ( selected_directly_excluded(Other, Selected, Rule) -> true ; Rule = complete_case_threshold ).

ignored_contradiction(Suspect, contradiction(Statement, Evidence, Reason)) :-
    claims(Suspect, _, Statement), contradiction(Statement, Evidence, Reason).
ignored_contradiction(Suspect, exclusion(Suspect, Rule)) :-
    directly_excluded(Suspect, Rule).
ignored_contradiction(Suspect, stronger_supported_case(arin)) :-
    Suspect \= arin, infer(arin_case_proven).

selected_ignored_contradiction(Suspect, Selected, contradiction(Statement, Evidence, Reason)) :-
    claims(Suspect, _, Statement), selected_contradiction(Statement, Evidence, Reason, Selected).
selected_ignored_contradiction(Suspect, Selected, exclusion(Suspect, Rule)) :-
    selected_directly_excluded(Suspect, Selected, Rule).
selected_ignored_contradiction(Suspect, Selected, stronger_supported_case(arin)) :-
    Suspect \= arin, selected_case_complete(Selected).

selected_contradiction(mira_left_1910, receipt_004, purchase_requires_presence, Selected) :-
    player_statement(mira_left_1910, heard), memberchk(receipt_004, Selected).
selected_contradiction(arin_cough_drops, pharmacy_footage, purchase_was_aconite, Selected) :-
    player_statement(arin_cough_drops, heard), memberchk(pharmacy_footage, Selected).
selected_contradiction(jo_identified_mira, tape_fiber, concealed_surface_contact_points_to_arin, Selected) :-
    player_statement(jo_identified_mira, heard), subset([cup_lid, tape_fiber, mira_statement], Selected).
selected_contradiction(dan_route_recollection, delivery_photo, tracker_disagrees_with_recollection, Selected) :-
    player_statement(dan_route_recollection, heard), memberchk(delivery_photo, Selected).

api(discover_evidence, Id) :- discover_evidence(Id).
api(query_contradictions, List) :-
    findall(contradiction(S, E, R), contradiction(S, E, R), List).
api(query_inferences, List) :- findall(F, infer(F), List).
api(query_proof, Fact) :- proof(Fact, _).
api(evaluate_accusation, Person) :- accusation(Person, _).
