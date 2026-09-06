:- initialization(main, main).
:- use_module(library(http/json)).
:- use_module(case).
:- use_module(case_data, []).
:- use_module(manifest).
:- dynamic validation_failure/1.
:- dynamic manifest_file/1.
:- prolog_load_context(directory, LogicDirectory),
   directory_file_path(LogicDirectory, '../cases/001-americano/case.json', ManifestPath),
   assertz(manifest_file(ManifestPath)).

main :-
    retractall(validation_failure(_)),
    validate(unique_authored_culprit, unique_authored_culprit),
    validate(five_suspects, five_suspects),
    validate(complete_evidence_catalogue, complete_evidence_catalogue),
    validate(hidden_truth_not_exported, hidden_truth_not_exported),
    validate(normalized_prolog_times, normalized_prolog_times),
    validate(manifest_matches_logic, manifest_matches_logic),
    validate(manifest_matches_generated, manifest_matches_generated),
    validate(normalized_manifest_timeline, normalized_manifest_timeline),
    validate(all_evidence_reachable, all_evidence_reachable),
    validate(all_inferences_have_proofs, all_inferences_have_proofs),
    validate(early_case_is_ambiguous, early_case_is_ambiguous),
    validate(core_alone_is_insufficient, core_alone_is_insufficient),
    validate(any_two_exclusions_are_insufficient, any_two_exclusions_are_insufficient),
    validate(any_three_exclusions_are_sufficient, any_three_exclusions_are_sufficient),
    validate(single_records_never_prove_guilt, single_records_never_prove_guilt),
    validate(red_herrings_do_not_prove_culprit, red_herrings_do_not_prove_culprit),
    validate(receipt_contradiction_not_guilt, receipt_contradiction_not_guilt),
    validate(tape_fiber_meaning_after_cup_lid, tape_fiber_meaning_after_cup_lid),
    validate(alternatives_before_after, alternatives_before_after),
    validate(every_conclusion_has_proof, every_conclusion_has_proof),
    validate(ending_states, ending_states),
    validate(no_premature_proof, no_premature_proof),
    validate(minimum_proof_set, minimum_proof_set),
    validate(every_ending_reachable, every_ending_reachable),
    validate(no_useless_evidence, no_useless_evidence),
    validate(every_statement_resolvable, every_statement_resolvable),
    validate(discovery_order_independent, discovery_order_independent),
    validate(every_accusation_explained, every_accusation_explained),
    validate(explanation_titles_complete, explanation_titles_complete),
    validate(no_redundant_core_evidence, no_redundant_core_evidence),
    findall(Name, validation_failure(Name), Failures),
    ( Failures == [] -> writeln('validator=pass'), halt(0)
    ; format('validator=FAIL failures=~w~n', [Failures]), halt(1)
    ).

validate(Name, Goal) :-
    catch((once(call(Goal)) -> Passed = true ; Passed = false), Error,
        (message_to_string(Error, Message), format('~w=ERROR ~s~n', [Name, Message]), Passed = false)),
    ( Passed == true -> format('~w=pass~n', [Name])
    ; (validation_failure(Name) -> true ; assertz(validation_failure(Name))),
      format('~w=FAIL~n', [Name])
    ).

expected_people([mira, arin, jo, sasha, dan]).
expected_evidence([
    receipt_004, camera_log, toxicology, pharmacy_footage, cup_lid, tape_fiber,
    draft_email, service_log, mira_statement, delivery_photo, sasha_voicemail,
    panel_log, jo_statement
]).
core_evidence([toxicology, pharmacy_footage, cup_lid, tape_fiber, draft_email, service_log]).
exclusion_evidence([mira_statement, delivery_photo, sasha_voicemail, panel_log]).

unique_authored_culprit :-
    findall(Person, case:culprit(Person), Culprits),
    Culprits == [arin].

five_suspects :-
    findall(Person, case:person(Person), People),
    expected_people(People).

complete_evidence_catalogue :-
    findall(Id, case:evidence(Id), Evidence),
    expected_evidence(Evidence),
    forall(member(Id, Evidence), once(case:evidence_title(Id, _))).

hidden_truth_not_exported :-
    module_property(case, exports(Exports)),
    forall(member(Predicate, [culprit/1, true_event/1, evidence_fact/2, claims/3, deception/2]),
        \+ memberchk(Predicate, Exports)).

normalized_prolog_times :-
    findall(Fact, case:evidence_fact(_, Fact), Facts),
    forall((member(Fact, Facts), term_integer(Fact, Value)),
        (integer(Value), between(0, 1439, Value))),
    case:evidence_fact(toxicology, death_window(eli, Start, End)),
    Start < End,
    case:evidence_fact(receipt_004, receipt_in_person(mira, cafe, ReceiptTime)),
    ReceiptTime =:= 1162.

term_integer(Term, Term) :- integer(Term).
term_integer(Term, Value) :-
    compound(Term),
    compound_name_arguments(Term, _, Arguments),
    member(Argument, Arguments),
    term_integer(Argument, Value).

read_manifest(Dict) :-
    manifest_file(Path),
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        json_read_dict(Stream, Dict, [value_string_as(atom)]),
        close(Stream)
    ).

manifest_matches_logic :-
    read_manifest(Dict),
    \+ get_dict(culprit, Dict, _),
    \+ get_dict(killer, Dict, _),
    get_dict(people, Dict, PeopleEntries),
    maplist(dict_id, PeopleEntries, People),
    expected_people(People),
    get_dict(evidence, Dict, EvidenceEntries),
    maplist(dict_id, EvidenceEntries, Evidence),
    expected_evidence(Evidence),
    forall(member(Entry, EvidenceEntries), manifest_evidence_valid(Entry)).

dict_id(Dict, Id) :- get_dict(id, Dict, Id).

manifest_evidence_valid(Entry) :-
    get_dict(id, Entry, Id),
    get_dict(title, Entry, ManifestTitle),
    case:evidence_title(Id, LogicTitle),
    atom_string(ManifestTitle, LogicTitle),
    get_dict(supports, Entry, Supports),
    forall(member(Inference, Supports), case:inference(Inference)).

% The checked-in manifest must equal the generated canonical manifest.
% Comparison runs on canonical JSON so key order and whitespace cannot drift.
manifest_matches_generated :-
    manifest:manifest_dict(Generated),
    canonical_json(Generated, Canonical),
    read_manifest(FileDict),
    canonical_json(FileDict, Canonical).

canonical_json(Dict, Canonical) :-
    with_output_to(atom(Canonical), json_write_dict(current_output, Dict, [width(0)])).

normalized_manifest_timeline :-
    read_manifest(Dict),
    get_dict(time_basis, Dict, minutes_after_midnight),
    get_dict(timeline, Dict, Timeline),
    Timeline \= [],
    forall(member(Entry, Timeline), normalized_timeline_entry(Entry)).

normalized_timeline_entry(Entry) :-
    get_dict(time, Entry, DisplayTime),
    ( get_dict(minute, Entry, Minute) ->
        valid_minute(Minute), display_minute(DisplayTime, Minute)
    ; get_dict(start_minute, Entry, Start), get_dict(end_minute, Entry, End),
      valid_minute(Start), valid_minute(End), Start =< End,
      display_range(DisplayTime, Start, End)
    ).

valid_minute(Value) :- integer(Value), between(0, 1439, Value).

display_minute(Display, Minute) :-
    atomic_list_concat([HourAtom, MinuteAtom], ':', Display),
    atom_number(HourAtom, Hour), atom_number(MinuteAtom, MinutePart),
    Minute =:= Hour * 60 + MinutePart.

display_range(Display, Start, End) :-
    atomic_list_concat([StartDisplay, EndDisplay], '-', Display),
    display_minute(StartDisplay, Start),
    display_minute(EndDisplay, End).

all_evidence_reachable :-
    expected_evidence(Evidence),
    forall(member(Id, Evidence), evidence_reachable(Id)).

evidence_reachable(mira_statement) :- !,
    case:clear_player,
    case:discover_evidence(receipt_004),
    case:record_statement(mira_left_1910),
    case:discover_evidence(mira_statement).
evidence_reachable(Id) :-
    case:clear_player,
    case:discover_evidence(Id).

discover_set(Ids) :-
    case:clear_player,
    ( memberchk(mira_statement, Ids) ->
        case:discover_evidence(receipt_004), case:record_statement(mira_left_1910)
    ; true
    ),
    maplist(case:discover_evidence, Ids).

discover_everything :-
    expected_evidence(Evidence),
    discover_set(Evidence),
    forall(case:statement(Statement), case:record_statement(Statement)).

all_inferences_have_proofs :-
    discover_everything,
    forall(case:infer(Name), once(case:proof(Name, proof(Name, _, _)))).

early_case_is_ambiguous :-
    discover_set([receipt_004]),
    findall(Suspect, case:possible_suspect(Suspect), Possible),
    length(Possible, Count), Count >= 4,
    case:accusation(arin, evaluation(sufficient_evidence(false), unique_solution(false), _, _, _, _, _)).

core_alone_is_insufficient :-
    core_evidence(Core), discover_set(Core),
    \+ case:infer(arin_case_proven),
    case:accusation(arin, evaluation(sufficient_evidence(false), unique_solution(false), _, _, unsupported(Gaps), _, _)),
    member(gap(exclusion_records, 3), Gaps).

any_two_exclusions_are_insufficient :-
    core_evidence(Core), exclusion_evidence(Exclusions),
    forall(combination(2, Exclusions, Selected),
        (append(Core, Selected, Evidence), discover_set(Evidence), \+ case:infer(arin_case_proven))).

any_three_exclusions_are_sufficient :-
    core_evidence(Core), exclusion_evidence(Exclusions),
    forall(combination(3, Exclusions, Selected),
        ( append(Core, Selected, Evidence), discover_set(Evidence),
          case:proof(arin_case_proven, proof(arin_case_proven, Premises, _)),
          forall(member(Id, Selected), memberchk(evidence(Id), Premises)),
          case:accusation(arin, evaluation(sufficient_evidence(true), unique_solution(true), ending(conviction), _, unsupported([]), _, _))
        )).

combination(0, _, []) :- !.
combination(N, [Head|Tail], [Head|Rest]) :-
    N > 0, Next is N - 1, combination(Next, Tail, Rest).
combination(N, [_|Tail], Rest) :-
    N > 0, combination(N, Tail, Rest).

single_records_never_prove_guilt :-
    expected_evidence(Evidence),
    forall(member(Id, Evidence),
        (discover_set([Id]), \+ case:infer(arin_case_proven))).

red_herrings_do_not_prove_culprit :-
    forall(member(Id, [receipt_004, camera_log, jo_statement, delivery_photo, sasha_voicemail, panel_log]),
        ( discover_set([Id]),
          case:accusation(arin, evaluation(sufficient_evidence(false), unique_solution(false), _, _, _, _, _)),
          \+ case:knowledge(proven, suspect(_))
        )).

receipt_contradiction_not_guilt :-
    discover_set([receipt_004]), case:record_statement(mira_left_1910),
    case:contradiction(mira_left_1910, receipt_004, _),
    \+ case:infer(arin_case_proven), case:possible_suspect(mira).

tape_fiber_meaning_after_cup_lid :-
    case:clear_player, case:discover_evidence(tape_fiber),
    case:evidence_meaning(tape_fiber, lint),
    case:discover_evidence(cup_lid),
    case:evidence_meaning(tape_fiber, contact_with_concealed_surface).

alternatives_before_after :-
    core_evidence(Core), discover_set(Core),
    findall(S, case:possible_suspect(S), Before), member(mira, Before),
    discover_everything,
    findall(S2, case:possible_suspect(S2), After), After == [arin].

every_conclusion_has_proof :-
    discover_everything,
    forall(case:infer(Name), once(case:proof(Name, proof(Name, _, _)))).

ending_states :-
    core_evidence(Core), discover_set(Core),
    case:accusation(arin, evaluation(sufficient_evidence(false), unique_solution(false), ending(lucky_idiot), _, _, _, _)),
    discover_everything,
    case:accusation(arin, evaluation(sufficient_evidence(true), unique_solution(true), ending(conviction), _, _, _, _)),
    discover_set([receipt_004, camera_log, toxicology]),
    case:accusation(mira, evaluation(_, _, ending(beautiful_theory), _, _, _, _)).

no_premature_proof :-
    case:clear_player, \+ case:proof(arin_case_proven, _),
    core_evidence(Core), discover_set(Core), \+ case:proof(arin_case_proven, _).

minimum_proof_set :-
    core_evidence(Core), exclusion_evidence(Excls),
    discover_set(Core), \+ case:infer(arin_case_proven),
    forall(combination(2, Excls, Two), (append(Core, Two, E2), discover_set(E2), \+ case:infer(arin_case_proven))),
    forall(combination(3, Excls, Three), (append(Core, Three, E3), discover_set(E3), case:infer(arin_case_proven))).

% Every manifest ending is producible. The decline-to-accuse ending is a
% Fennel path covered by the runtime suite; Prolog owns the other four.
every_ending_reachable :-
    read_manifest(Dict),
    get_dict(endings, Dict, [conviction, lucky_idiot, beautiful_theory, insufficient_evidence, everybody_goes_home]),
    core_evidence(Core), discover_set(Core),
    case:accusation(arin, evaluation(_, _, ending(lucky_idiot), _, _, _, _)),
    discover_everything,
    case:accusation(arin, evaluation(_, _, ending(conviction), _, _, _, _)),
    case:clear_player,
    case:accusation(sasha, evaluation(_, _, ending(insufficient_evidence), _, _, _, _)),
    case:clear_player,
    discover_set([receipt_004, camera_log, toxicology]),
    case:accusation(mira, evaluation(_, _, ending(beautiful_theory), _, _, _, _)).

% Every record either supports an inference or gates timeline progression.
no_useless_evidence :-
    expected_evidence(Evidence),
    forall(member(Id, Evidence), evidence_contributes(Id)).

evidence_contributes(Id) :- case_data:evidence_supports(Id, _).
evidence_contributes(Id) :-
    case_data:timeline_event(_, _, _, Requires), memberchk(Id, Requires).

% Every heard statement resolves to a real classification, never bare uncertainty.
every_statement_resolvable :-
    findall(Statement, case:statement(Statement), Statements),
    forall(member(Statement, Statements),
        (discover_everything, case:record_statement(Statement),
         case:statement_status(Statement, Status), Status \= uncertainty)).

% Final knowledge must not depend on the order the player filed records.
discovery_order_independent :-
    expected_evidence(Evidence),
    reverse(Evidence, Reversed),
    discover_eventually(Evidence, Forward),
    discover_eventually(Reversed, Backward),
    discover_statements_first(Evidence, StatementsFirst),
    Forward == Backward, Backward == StatementsFirst,
    case:clear_player,
    discover_eventually(Evidence, _),
    case:infer(arin_case_proven).

discover_eventually(EvidenceOrder, SortedInferences) :-
    case:clear_player,
    forall(member(Id, EvidenceOrder), (case:discover_evidence(Id) -> true ; true)),
    forall(case:statement(Statement), case:record_statement(Statement)),
    forall(member(Id, EvidenceOrder), (case:discover_evidence(Id) -> true ; true)),
    findall(Inference, case:infer(Inference), Inferences),
    sort(Inferences, SortedInferences).

discover_statements_first(EvidenceOrder, SortedInferences) :-
    case:clear_player,
    forall(case:statement(Statement), case:record_statement(Statement)),
    forall(member(Id, EvidenceOrder), (case:discover_evidence(Id) -> true ; true)),
    forall(member(Id, EvidenceOrder), (case:discover_evidence(Id) -> true ; true)),
    findall(Inference, case:infer(Inference), Inferences),
    sort(Inferences, SortedInferences).

% Every accusation verdict carries dimensions, alternatives, and gaps.
every_accusation_explained :-
    expected_people(People),
    discover_everything,
    forall(member(Suspect, People),
        (case:accusation(Suspect, evaluation(_, _, ending(_),
            dimensions(Dimensions), unsupported(_),
            alternatives(Alternatives), ignored_contradictions(_))),
         length(Dimensions, 3), length(Alternatives, 4))).

% Every inference and contradiction reason has a display title.
explanation_titles_complete :-
    forall(case:inference(Name), case_data:inference_title(Name, _)),
    discover_everything,
    forall(case:contradiction(_, _, Reason), case_data:reason_title(Reason, _)).

% Dropping any single core record breaks the proof threshold.
no_redundant_core_evidence :-
    core_evidence(Core),
    forall((member(Dropped, Core), subtract(Core, [Dropped], Remaining)),
        (discover_set(Remaining), \+ case:infer(arin_case_proven))).
