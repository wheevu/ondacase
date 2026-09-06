:- use_module(case).
:- use_module(api).
:- ensure_loaded(server).

:- begin_tests(case_001).

core_evidence([toxicology, pharmacy_footage, cup_lid, tape_fiber, draft_email, service_log]).
three_exclusions([delivery_photo, sasha_voicemail, panel_log]).

discover_all(List) :- maplist(case:discover_evidence, List).

complete_case :-
    case:clear_player,
    core_evidence(Core), three_exclusions(Exclusions),
    append(Core, Exclusions, Evidence),
    discover_all(Evidence).

complete_inventory :-
    case:clear_player,
    case:discover_evidence(receipt_004), case:record_statement(mira_left_1910),
    findall(Id, case:evidence(Id), Evidence), discover_all(Evidence).

full_argument(_{
    motive:["draft_email"],
    method:["pharmacy_footage", "toxicology", "cup_lid", "tape_fiber"],
    opportunity:["service_log", "toxicology"],
    evidence:["toxicology", "pharmacy_footage", "cup_lid", "tape_fiber", "draft_email",
              "service_log", "delivery_photo", "sasha_voicemail", "panel_log"]
}).

test(authored_truth_has_one_culprit) :-
    findall(Person, case:culprit(Person), Culprits),
    assertion(Culprits == [arin]).

test(hidden_truth_is_not_exported) :-
    module_property(case, exports(Exports)),
    assertion(\+ memberchk(culprit/1, Exports)),
    assertion(\+ memberchk(true_event/1, Exports)),
    assertion(\+ memberchk(evidence_fact/2, Exports)),
    assertion(\+ memberchk(deception/2, Exports)).

test(named_api_has_no_truth_operation, [fail]) :-
    api:request(ground_truth, _, _).

test(all_five_suspects_are_modeled) :-
    findall(Person, case:person(Person), People),
    assertion(People == [mira, arin, jo, sasha, dan]).

test(all_thirteen_evidence_records_are_modeled) :-
    findall(Id, case:evidence(Id), Evidence),
    length(Evidence, 13),
    forall(member(Id, Evidence), once(case:evidence_title(Id, _))).

test(times_are_normalized_minutes) :-
    case:minute_of_day(19, 4, 1144),
    case:evidence_fact(receipt_004, receipt_in_person(mira, cafe, ReceiptTime)),
    case:evidence_fact(toxicology, death_window(eli, Start, End)),
    maplist(integer, [ReceiptTime, Start, End]),
    case:before(ReceiptTime, End),
    case:within(1165, Start, End),
    assertion(\+ case:within(1164, Start, End)).

test(discovery_is_idempotent) :-
    case:clear_player,
    case:discover_evidence(receipt_004),
    case:discover_evidence(receipt_004),
    findall(receipt_004, case:player_evidence(receipt_004), Found),
    assertion(Found == [receipt_004]).

test(mira_statement_requires_receipt_confrontation) :-
    case:clear_player,
    assertion(\+ case:discover_evidence(mira_statement)),
    case:discover_evidence(receipt_004),
    assertion(\+ case:discover_evidence(mira_statement)),
    case:record_statement(mira_left_1910),
    case:discover_evidence(mira_statement).

test(receipt_places_mira_without_implying_guilt) :-
    case:clear_player,
    case:discover_evidence(receipt_004),
    case:infer(mira_present_1922),
    assertion(\+ case:infer(arin_case_proven)),
    case:possible_suspect(mira).

test(contradiction_requires_statement_and_evidence, [nondet]) :-
    case:clear_player,
    case:discover_evidence(receipt_004),
    assertion(\+ case:contradiction(mira_left_1910, _, _)),
    case:record_statement(mira_left_1910),
    case:contradiction(mira_left_1910, receipt_004, purchase_requires_presence).

test(receipt_does_not_contradict_arin) :-
    case:clear_player,
    case:discover_evidence(receipt_004),
    case:record_statement(arin_cough_drops),
    assertion(\+ case:contradiction(arin_cough_drops, receipt_004, _)).

test(receipt_contradiction_does_not_imply_guilt, [nondet]) :-
    case:clear_player,
    case:discover_evidence(receipt_004), case:record_statement(mira_left_1910),
    case:contradiction(mira_left_1910, receipt_004, _),
    assertion(\+ case:infer(arin_case_proven)),
    case:possible_suspect(mira),
    assertion(\+ case:impossible_suspect(mira)).

test(deception_classes_remain_distinct, [nondet]) :-
    case:clear_player,
    discover_all([receipt_004, pharmacy_footage, jo_statement, sasha_voicemail, delivery_photo]),
    maplist(case:record_statement, [mira_left_1910, arin_cough_drops, jo_saw_cup_1921,
        sasha_never_argued, dan_never_inside, dan_route_recollection]),
    case:statement_status(mira_left_1910, direct_falsehood),
    case:statement_status(arin_cough_drops, direct_falsehood),
    case:statement_status(jo_saw_cup_1921, incomplete),
    case:statement_status(sasha_never_argued, technically_true_misleading),
    case:statement_status(dan_never_inside, technically_true_misleading),
    case:statement_status(dan_route_recollection, mistaken).

test(semantic_classifications_include_uncertainty, [nondet]) :-
    case:clear_player,
    case:record_statement(sasha_never_argued),
    case:statement_semantic(sasha_never_argued, uncertainty),
    case:discover_evidence(sasha_voicemail),
    case:statement_semantic(sasha_never_argued, misleading).

test(unrelated_secrets_do_not_prove_case) :-
    case:clear_player,
    discover_all([delivery_photo, sasha_voicemail, panel_log]),
    assertion(\+ case:infer(arin_case_proven)),
    case:possible_suspect(arin).

test(proof_is_unavailable_before_its_premises, [fail]) :-
    case:clear_player,
    case:proof(arin_method, _).

test(no_premature_proof_core_only) :-
    case:clear_player,
    core_evidence(Core), discover_all(Core),
    assertion(\+ case:proof(arin_case_proven, _)).

test(proof_is_a_nested_structured_tree, [nondet]) :-
    case:clear_player,
    discover_all([pharmacy_footage, toxicology, cup_lid, tape_fiber]),
    case:proof(arin_method, proof(arin_method, Premises, _)),
    member(inference(arin_means, proof(arin_means, MeansPremises, _)), Premises),
    member(evidence(pharmacy_footage), MeansPremises),
    member(inference(arin_contact, _), Premises).

test(every_visible_inference_has_a_proof) :-
    complete_case,
    forall(case:infer(Name), once(case:proof(Name, proof(Name, _, _)))).

test(minimum_proof_set_required) :-
    case:clear_player,
    core_evidence(Core), discover_all(Core),
    assertion(\+ case:infer(arin_case_proven)),
    case:discover_evidence(delivery_photo),
    assertion(\+ case:infer(arin_case_proven)),
    case:discover_evidence(sasha_voicemail),
    assertion(\+ case:infer(arin_case_proven)),
    case:discover_evidence(panel_log),
    assertion(case:infer(arin_case_proven)).

test(core_evidence_without_exclusions_is_not_unique, [nondet]) :-
    case:clear_player,
    core_evidence(Core), discover_all(Core),
    case:accusation(arin, evaluation(
        sufficient_evidence(false), unique_solution(false),
        ending(lucky_idiot), _, unsupported(Gaps), alternatives(Alternatives), _)),
    member(gap(exclusion_records, 3), Gaps),
    member(alternative(mira, possible, _), Alternatives).

test(two_exclusions_are_still_insufficient) :-
    case:clear_player,
    core_evidence(Core), append(Core, [delivery_photo, sasha_voicemail], Evidence),
    discover_all(Evidence),
    case:accusation(arin, evaluation(sufficient_evidence(false), unique_solution(false), _, _, unsupported(Gaps), _, _)),
    member(gap(exclusion_records, 1), Gaps).

test(complete_argument_is_unique_and_supported, [nondet]) :-
    complete_case,
    case:accusation(arin, evaluation(
        sufficient_evidence(true), unique_solution(true),
        ending(conviction), dimensions(Dimensions), unsupported([]), _, _)),
    member(dimension(motive, supported, _, []), Dimensions),
    member(dimension(method, supported, _, []), Dimensions),
    member(dimension(opportunity, supported, _, []), Dimensions).

test(wrong_accusation_reports_dimensions_and_ignored_exclusion, [nondet]) :-
    complete_case,
    case:accusation(jo, evaluation(
        sufficient_evidence(false), unique_solution(false),
        _, dimensions(Dimensions), unsupported(Gaps), _, ignored_contradictions(Ignored))),
    member(dimension(method, contradicted, _, _), Dimensions),
    member(gap(dimension, method, contradicted, _), Gaps),
    member(exclusion(jo, jo_excluded), Ignored),
    member(stronger_supported_case(arin), Ignored).

test(alternatives_before_and_after_exclusions) :-
    case:clear_player,
    core_evidence(Core), discover_all(Core),
    findall(S, case:possible_suspect(S), Before),
    assertion(member(mira, Before)),
    assertion(member(jo, Before)),
    complete_case,
    findall(S2, case:possible_suspect(S2), After),
    assertion(After == [arin]).

test(tape_fiber_meaning_after_cup_lid) :-
    case:clear_player,
    case:discover_evidence(tape_fiber),
    case:evidence_meaning(tape_fiber, lint),
    case:discover_evidence(cup_lid),
    case:evidence_meaning(tape_fiber, contact_with_concealed_surface),
    assertion(\+ case:evidence_meaning(tape_fiber, lint)).

test(evaluate_evidence_api, [nondet]) :-
    case:clear_player,
    case:discover_evidence(toxicology),
    case:evaluate_evidence(toxicology, evaluation(toxicology, relevant, _)).

test(evaluate_hypothesis_api, [nondet]) :-
    case:clear_player,
    case:evaluate_hypothesis(arin, evaluation(arin, viable, _)),
    complete_case,
    case:evaluate_hypothesis(jo, evaluation(jo, excluded, _)).

test(structured_hypothesis_evaluates_selected_argument_without_truth_fields) :-
    complete_case,
    user:dispatch(_{
        operation:"evaluate_hypothesis", suspect:"arin",
        motive:["draft_email"],
        method:["pharmacy_footage", "toxicology", "cup_lid", "tape_fiber"],
        opportunity:["service_log", "toxicology"],
        evidence:["toxicology", "pharmacy_footage", "cup_lid", "tape_fiber", "draft_email", "service_log", "delivery_photo", "sasha_voicemail", "panel_log"]
    }, Response),
    assertion(Response.ok == true),
    assertion(Response.evaluation.status == coherent),
    assertion(Response.evaluation.consistency == consistent),
    assertion(\+ get_dict(ending, Response.evaluation, _)),
    assertion(\+ get_dict(sufficient_evidence, Response.evaluation, _)),
    assertion(\+ get_dict(unique_solution, Response.evaluation, _)),
    term_string(Response, Text),
    assertion(\+ sub_string(Text, _, _, _, "ground_truth")),
    assertion(\+ sub_string(Text, _, _, _, "culprit")).

test(structured_weak_hypothesis_reports_missing_links) :-
    case:clear_player,
    discover_all([receipt_004, camera_log, toxicology]),
    user:dispatch(_{
        operation:"evaluate_hypothesis", suspect:"mira",
        motive:[], method:["toxicology"], opportunity:["receipt_004", "camera_log", "toxicology"],
        evidence:["receipt_004", "camera_log", "toxicology"]
    }, Response),
    assertion(Response.ok == true),
    assertion(Response.evaluation.status == under_supported),
    assertion(Response.evaluation.unsupported \= []).

test(structured_hypothesis_rejects_undiscovered_evidence) :-
    case:clear_player,
    user:dispatch(_{
        operation:"evaluate_hypothesis", suspect:"arin",
        motive:["draft_email"], method:[], opportunity:[], evidence:["draft_email"]
    }, Response),
    assertion(Response.error.code == undiscovered_evidence).

test(possible_alternatives_api) :-
    case:clear_player,
    case:possible_alternatives(L1), assertion(member(mira, L1)),
    complete_case,
    case:possible_alternatives(L2), assertion(L2 == [arin]).

test(accusation_reports_consistency_and_circular) :-
    complete_case,
    user:dispatch(_{operation:"accusation", suspect:"arin"}, Resp),
    assertion(Resp.result.consistency == consistent),
    assertion(Resp.result.circular_reasoning == false),
    assertion(Resp.result.selected_evidence = [_, _, _, _, _, _, _, _, _]).

test(complete_inventory_does_not_rescue_weak_selected_argument) :-
    complete_inventory,
    findall(Id, case:player_evidence(Id), Before),
    user:dispatch(_{operation:"accusation", suspect:"arin", motive:["draft_email"],
        method:["cup_lid"], opportunity:["service_log"],
        evidence:["draft_email", "cup_lid", "service_log"]}, Resp),
    assertion(Resp.result.ending == lucky_idiot),
    assertion(Resp.result.sufficient_evidence == false),
    assertion(Resp.result.method == partial),
    assertion(Resp.result.unique_solution == false),
    assertion(Resp.result.selected_evidence = [_, _, _]),
    findall(Id, case:player_evidence(Id), After), assertion(After == Before).

test(wrong_dimension_label_cannot_convict) :-
    complete_inventory, full_argument(Argument),
    put_dict(_{operation:"accusation", suspect:"arin",
        motive:["draft_email", "toxicology"]}, Argument, Request),
    user:dispatch(Request, Resp),
    assertion(Resp.result.ending == lucky_idiot),
    assertion(Resp.result.consistency == inconsistent),
    member(Gap, Resp.result.unsupported), assertion(Gap.code == unsupported_premise).

test(undiscovered_selected_evidence_errors) :-
    case:clear_player,
    user:dispatch(_{operation:"accusation", suspect:"arin", motive:[], method:[],
        opportunity:[], evidence:["toxicology"]}, Resp),
    assertion(Resp.error.code == undiscovered_evidence),
    assertion(Resp.error.value == toxicology).

test(duplicate_selected_ids_are_rejected) :-
    case:clear_player, case:discover_evidence(draft_email),
    user:dispatch(_{operation:"accusation", suspect:"arin", motive:["draft_email", "draft_email"],
        method:[], opportunity:[], evidence:["draft_email"]}, Resp),
    assertion(Resp.error.code == duplicate_evidence),
    assertion(Resp.error.field == motive).

test(structured_accusation_validates_array_types_and_ids) :-
    user:dispatch(_{operation:"accusation", suspect:"arin", motive:"draft_email",
        method:[], opportunity:[], evidence:[]}, TypeResp),
    assertion(TypeResp.error.code == invalid_type),
    user:dispatch(_{operation:"accusation", suspect:"arin", motive:["not_evidence"],
        method:[], opportunity:[], evidence:["not_evidence"]}, IdResp),
    assertion(IdResp.error.code == unknown_evidence),
    user:dispatch(_{operation:"accusation", suspect:"arin", motive:[]}, MissingResp),
    assertion(MissingResp.error.code == missing_field).

test(full_selected_proof_convicts) :-
    complete_inventory, full_argument(Argument),
    put_dict(_{operation:"accusation", suspect:"arin"}, Argument, Request),
    user:dispatch(Request, Resp),
    assertion(Resp.result.ending == conviction),
    assertion(Resp.result.sufficient_evidence == true),
    assertion(Resp.result.unique_solution == true),
    assertion(Resp.result.motive == supported),
    assertion(Resp.result.method == supported),
    assertion(Resp.result.opportunity == supported),
    assertion(Resp.result.unsupported == []).

test(ending_states) :-
    case:clear_player,
    core_evidence(Core), discover_all(Core),
    case:accusation(arin, evaluation(sufficient_evidence(false), unique_solution(false), ending(lucky_idiot), _, unsupported(_), _, _)),
    complete_case,
    case:accusation(arin, evaluation(sufficient_evidence(true), unique_solution(true), ending(conviction), _, _, _, _)),
    case:clear_player,
    discover_all([receipt_004, camera_log, toxicology]),
    case:accusation(mira, evaluation(_, _, ending(beautiful_theory), _, _, _, _)).

test(knowledge_states_are_not_collapsed) :-
    complete_case,
    case:knowledge(discovered, evidence(toxicology)),
    case:knowledge(inferred, arin_method),
    case:knowledge(hypothesized, suspect(mira)),
    case:knowledge(impossible, suspect(jo)),
    case:knowledge(proven, suspect(arin)),
    assertion(\+ case:knowledge(discovered, arin_method)).

test(structured_missing_field_error) :-
    user:dispatch(_{}, Response),
    get_dict(error, Response, Error),
    assertion(Error.code == missing_field),
    assertion(Error.field == operation).

test(structured_invalid_type_error) :-
    user:dispatch(_{operation:"discover_evidence", evidence:7}, Response),
    get_dict(error, Response, Error),
    assertion(Error.code == invalid_type),
    assertion(Error.field == evidence).

test(structured_unavailable_proof_error) :-
    case:clear_player,
    user:dispatch(_{operation:"proof", fact:"arin_method"}, Response),
    get_dict(error, Response, Error),
    assertion(Error.code == proof_unavailable).

test(structured_invalid_json_error) :-
    user:handle_line("{", Response),
    get_dict(error, Response, Error),
    assertion(Error.code == invalid_json),
    assertion(string(Error.message)).

test(structured_unknown_operation_error) :-
    user:dispatch(_{operation:"unknown_op"}, Response),
    get_dict(error, Response, Error),
    assertion(Error.code == unknown_operation).

test(query_state_does_not_serialize_hidden_truth) :-
    case:clear_player,
    user:dispatch(_{operation:"query_state"}, Response),
    term_string(Response, Text),
    assertion(\+ sub_string(Text, _, _, _, "culprit")),
    assertion(\+ sub_string(Text, _, _, _, "true_event")),
    assertion(\+ sub_string(Text, _, _, _, "ground_truth")).

test(accusation_does_not_serialize_hidden_truth) :-
    complete_case,
    user:dispatch(_{operation:"accusation", suspect:"arin"}, Response),
    term_string(Response, Text),
    assertion(\+ sub_string(Text, _, _, _, "culprit")),
    assertion(\+ sub_string(Text, _, _, _, "ground_truth")),
    assertion(Response.result.ending == conviction).

test(server_proof_is_structured_json_data, [nondet]) :-
    case:clear_player,
    discover_all([pharmacy_footage, toxicology, cup_lid, tape_fiber]),
    user:dispatch(_{operation:"proof", fact:"arin_method"}, Response),
    get_dict(proof, Response, Tree),
    assertion(Tree.status == inferred),
    assertion(is_list(Tree.premises)),
    member(Premise, Tree.premises),
    assertion(is_dict(Premise)).

test(server_evaluate_evidence_json, [nondet]) :-
    case:clear_player,
    case:discover_evidence(toxicology),
    user:dispatch(_{operation:"evaluate_evidence", evidence:"toxicology"}, Response),
    assertion(Response.ok == true),
    assertion(string(Response.evaluation.relevance) ; atom(Response.evaluation.relevance)).

test(server_possible_alternatives_json) :-
    case:clear_player,
    user:dispatch(_{operation:"possible_alternatives"}, Response),
    assertion(Response.ok == true),
    assertion(is_list(Response.alternatives)).

test(case_info_reports_manifest_metadata) :-
    user:dispatch(_{operation:"case_info"}, Response),
    assertion(Response.ok == true),
    assertion(Response.id == '001-americano'),
    assertion(Response.victim == eli),
    assertion(member(cafe, Response.locations)),
    assertion(Response.endings == [conviction, lucky_idiot, beautiful_theory, insufficient_evidence, everybody_goes_home]).

test(timeline_visibility_follows_discovery) :-
    case:clear_player,
    user:dispatch(_{operation:"timeline"}, Empty),
    assertion(Empty.ok == true),
    \+ (member(Hidden, Empty.entries),
        Hidden.event == "Mira makes an in-person purchase", Hidden.visible == true),
    case:discover_evidence(receipt_004),
    user:dispatch(_{operation:"timeline"}, Filed),
    once((member(Shown, Filed.entries),
        Shown.event == "Mira makes an in-person purchase", Shown.visible == true)).

test(locked_evidence_explains_itself) :-
    case:clear_player,
    user:dispatch(_{operation:"why_locked", evidence:"mira_statement"}, MissingReceipt),
    assertion(MissingReceipt.locked == true),
    assertion(MissingReceipt.reason == need_receipt),
    assertion(string(MissingReceipt.reason_title)),
    case:discover_evidence(receipt_004),
    user:dispatch(_{operation:"why_locked", evidence:"mira_statement"}, MissingConfrontation),
    assertion(MissingConfrontation.reason == need_confrontation),
    case:record_statement(mira_left_1910),
    user:dispatch(_{operation:"why_locked", evidence:"mira_statement"}, Unlocked),
    assertion(Unlocked.locked == false).

test(available_evidence_excludes_locked_records) :-
    case:clear_player,
    user:dispatch(_{operation:"available_evidence"}, Response),
    assertion(Response.ok == true),
    findall(LockedId, (member(Entry, Response.evidence),
        Entry.available == false, LockedId = Entry.id), Locked),
    assertion(Locked == [mira_statement]).

test(perform_inspect_matches_discover) :-
    case:clear_player,
    user:dispatch(_{operation:"perform", action:"inspect", evidence:"toxicology"}, Response),
    assertion(Response.ok == true),
    assertion(Response.performed.action == inspect),
    assertion(Response.evidence == toxicology),
    case:player_evidence(toxicology).

test(perform_hear_matches_record) :-
    case:clear_player,
    user:dispatch(_{operation:"perform", action:"hear", statement:"dan_never_inside"}, Response),
    assertion(Response.ok == true),
    case:player_statement(dan_never_inside, heard).

test(perform_rejects_unknown_actions) :-
    user:dispatch(_{operation:"perform", action:"bribe", evidence:"toxicology"}, Response),
    assertion(Response.error.code == unknown_operation).

test(why_not_names_missing_premises) :-
    case:clear_player,
    case:discover_evidence(toxicology),
    user:dispatch(_{operation:"why_not", fact:"arin_means"}, Response),
    assertion(Response.status == blocked),
    once((member(Missing, Response.missing),
        Missing.id == pharmacy_footage, string(Missing.title))).

test(why_not_reports_derivable_facts) :-
    case:clear_player,
    case:discover_evidence(toxicology),
    user:dispatch(_{operation:"why_not", fact:"death_window_established"}, Response),
    assertion(Response.status == derivable),
    assertion(Response.missing == []).

test(what_changed_tracks_evidence_consequences) :-
    case:clear_player,
    user:dispatch(_{operation:"what_changed", evidence:"toxicology"}, Before),
    assertion(Before.ok == true),
    once((member(Pending, Before.pending),
        Pending.id == death_window_established)),
    case:discover_evidence(toxicology),
    user:dispatch(_{operation:"what_changed", evidence:"toxicology"}, After),
    once((member(Derivable, After.derivable),
        Derivable.id == death_window_established)).

test(alternative_case_explains_missing_proof) :-
    case:clear_player,
    discover_all([receipt_004, camera_log, toxicology]),
    user:dispatch(_{operation:"alternative_case", suspect:"mira"}, Response),
    assertion(Response.ok == true),
    assertion(Response.name == "Mira Vale"),
    once((member(Unsupported, Response.unsupported),
        is_list(Unsupported.missing))).

test(board_reports_visible_and_locked_nodes) :-
    case:clear_player,
    case:discover_evidence(pharmacy_footage),
    user:dispatch(_{operation:"board"}, Response),
    assertion(Response.ok == true),
    once((member(Visible, Response.nodes),
        Visible.id == arin_means, Visible.status == visible)),
    once((member(Locked, Response.nodes),
        Locked.id == cup_lid, Locked.status == locked)).

test(board_flags_active_contradictions) :-
    case:clear_player,
    case:discover_evidence(receipt_004),
    case:record_statement(mira_left_1910),
    user:dispatch(_{operation:"board"}, Response),
    once((member(Node, Response.nodes),
        Node.id == mira_conflict, Node.status == visible, Node.active == true)).

test(named_api_covers_new_operations) :-
    case:clear_player,
    api:request(available_evidence, _, available(Available)),
    assertion(\+ member(mira_statement, Available)),
    api:request(board_state, _, board(Nodes)),
    assertion(is_list(Nodes)),
    case:discover_evidence(toxicology),
    api:request(what_changed, toxicology, consequences(toxicology, Derivable, _)),
    assertion(member(death_window_established, Derivable)).

test(minimal_proof_sets_name_transitive_leaves) :-
    case:clear_player,
    case:minimal_proof_sets(arin_means, [Leaves]),
    assertion(Leaves == [evidence(pharmacy_footage), evidence(toxicology)]).

test(frontier_lists_single_gap_conclusions) :-
    case:clear_player,
    case:discover_evidence(toxicology),
    case:frontier(Entries),
    once(member(frontier(arin_means, evidence(pharmacy_footage)), Entries)).

test(hypothetical_infer_leaves_state_untouched) :-
    case:clear_player,
    case:discover_evidence(toxicology),
    case:hypothetical_infer([pharmacy_footage], [], arin_means),
    assertion(\+ case:player_evidence(pharmacy_footage)),
    assertion(\+ case:infer(arin_means)).

test(hypothetical_accusation_reports_assumed_argument) :-
    complete_case,
    case:hypothetical_accusation(arin, [], result(Evaluation, Selected)),
    Evaluation = evaluation(_, _, ending(conviction), _, _, _, _),
    length(Selected, 9).

test(why_possible_explains_open_suspects) :-
    case:clear_player,
    case:discover_evidence(receipt_004),
    case:why_possible(mira, Reasons),
    assertion(member(unexcluded, Reasons)),
    assertion(member(case_open, Reasons)).

test(exclusion_proof_blocks_then_proves) :-
    case:clear_player,
    case:exclusion_proof(sasha, blocked(Missing)),
    assertion(Missing \= []),
    complete_inventory,
    case:exclusion_proof(sasha, proved(Proof)),
    Proof = proof(sasha_excluded, _, _).

test(verdict_critical_matches_core_evidence) :-
    findall(Id, case:verdict_critical(Id), Critical),
    sort(Critical, Sorted),
    assertion(Sorted == [cup_lid, draft_email, pharmacy_footage, service_log, tape_fiber, toxicology]).

test(verdict_redundant_keeps_conviction) :-
    findall(Id, case:verdict_redundant(Id), Redundant),
    assertion(member(delivery_photo, Redundant)),
    core_evidence(Core),
    forall(member(Id, Redundant), \+ memberchk(Id, Core)).

test(ranked_alternatives_orders_by_support) :-
    case:clear_player,
    discover_all([receipt_004, camera_log, toxicology]),
    case:ranked_alternatives(arin, [rank(First, _)|_]),
    assertion(First == mira).

test(epistemic_status_tracks_investigation) :-
    case:clear_player,
    case:epistemic_status(epistemic(fresh, none)),
    case:discover_evidence(toxicology),
    case:epistemic_status(epistemic(open, evidence(1))),
    case:clear_player,
    case:discover_evidence(receipt_004),
    case:record_statement(mira_left_1910),
    case:epistemic_status(epistemic(conflicted, 1)),
    complete_case,
    case:epistemic_status(epistemic(proven, arin_case_proven)).

test(evidence_impact_reports_gains_triggers_unlocks) :-
    case:clear_player,
    case:record_statement(mira_left_1910),
    case:evidence_impact(receipt_004, impact(Gains, Triggers, Unlocks)),
    assertion(member(mira_present_1922, Gains)),
    assertion(member(contradiction(mira_left_1910, receipt_004), Triggers)),
    assertion(member(mira_statement, Unlocks)).

test(board_graph_edges_carry_provenance) :-
    complete_inventory,
    case:board_graph(Graph),
    Graph = graph(Nodes, Edges),
    assertion(length(Nodes, 7)),
    once(member(edge(evidence(toxicology), inference(death_window_established), supports, true), Edges)),
    once(member(edge(statement(mira_left_1910), evidence(receipt_004), contradicts, true), Edges)),
    once(member(edge(inference(_), suspect(_), excludes, true), Edges)).

test(director_grounds_confrontations_in_contradictions) :-
    case:clear_player,
    case:available_topics(mira, EarlyTopics),
    assertion(EarlyTopics == [claim(mira_left_1910)]),
    case:reaction_state(mira, open),
    case:discover_evidence(receipt_004),
    case:record_statement(mira_left_1910),
    case:confrontation_grounds(mira, mira_left_1910, receipt_004, purchase_requires_presence),
    case:reaction_state(mira, cornered),
    case:available_topics(mira, LateTopics),
    assertion(member(confront(mira_left_1910), LateTopics)),
    case:interview_yield(mira, yield([], [mira_left_1910])).

test(server_minimal_proof_and_frontier_json) :-
    complete_inventory,
    user:dispatch(_{operation:"minimal_proof", fact:"arin_means"}, ProofResp),
    assertion(ProofResp.ok == true),
    assertion(length(ProofResp.proof_set, 2)),
    case:clear_player,
    case:discover_evidence(toxicology),
    user:dispatch(_{operation:"frontier"}, FrontierResp),
    assertion(FrontierResp.ok == true),
    once((member(Entry, FrontierResp.frontier),
        Entry.inference == arin_means, Entry.missing.id == pharmacy_footage)).

test(server_hypothetical_and_why_possible_json) :-
    case:clear_player,
    case:discover_evidence(toxicology),
    user:dispatch(_{operation:"hypothetical", suspect:"arin", evidence:["pharmacy_footage"]}, HypResp),
    assertion(HypResp.ok == true),
    assertion(HypResp.result.sufficient_evidence == false),
    user:dispatch(_{operation:"why_possible", suspect:"mira"}, WhyResp),
    assertion(WhyResp.viable == true),
    assertion(member(unexcluded, WhyResp.reasons)).

test(server_exclusion_and_ranking_json) :-
    complete_inventory,
    user:dispatch(_{operation:"exclusion", suspect:"sasha"}, ExclResp),
    assertion(ExclResp.status == excluded),
    assertion(is_dict(ExclResp.proof)),
    user:dispatch(_{operation:"strongest_alternative", suspect:"arin"}, RankResp),
    assertion(RankResp.ok == true),
    assertion(length(RankResp.ranked, 4)).

test(server_epistemic_impact_director_json) :-
    case:clear_player,
    user:dispatch(_{operation:"epistemic"}, EpistemicResp),
    assertion(EpistemicResp.epistemic.status == fresh),
    case:discover_evidence(receipt_004),
    user:dispatch(_{operation:"impact", evidence:"toxicology"}, ImpactResp),
    assertion(ImpactResp.ok == true),
    once((member(Gain, ImpactResp.gains), Gain.id == death_window_established)),
    user:dispatch(_{operation:"director", suspect:"mira"}, DirectorResp),
    assertion(DirectorResp.reaction == open),
    user:dispatch(_{operation:"reactions"}, ReactionsResp),
    assertion(length(ReactionsResp.reactions, 5)).

test(server_board_carries_graph_edges) :-
    complete_inventory,
    user:dispatch(_{operation:"board"}, Response),
    assertion(is_list(Response.edges)),
    once((member(Edge, Response.edges), Edge.relation == contradicts)).

test(server_critical_and_redundant_json) :-
    user:dispatch(_{operation:"critical"}, CriticalResp),
    assertion(CriticalResp.ok == true),
    assertion(length(CriticalResp.critical, 6)),
    user:dispatch(_{operation:"redundant"}, RedundantResp),
    assertion(RedundantResp.ok == true),
    once((member(Entry, RedundantResp.redundant), Entry.id == delivery_photo)).

test(named_api_covers_analysis_and_director) :-
    case:clear_player,
    api:request(frontier, _, frontier(Entries)),
    assertion(is_list(Entries)),
    api:request(epistemic_status, _, epistemic(fresh, none)),
    api:request(reaction_state, mira, reaction(mira, open)).

test(new_operations_do_not_serialize_hidden_truth) :-
    complete_inventory,
    forall(member(Request, [_{operation:"case_info"}, _{operation:"timeline"},
            _{operation:"available_evidence"}, _{operation:"board"}]),
        (user:dispatch(Request, Response),
         term_string(Response, Text),
         assertion(\+ sub_string(Text, _, _, _, "culprit")),
         assertion(\+ sub_string(Text, _, _, _, "true_event")))).

:- end_tests(case_001).
