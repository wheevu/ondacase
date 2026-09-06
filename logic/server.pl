:- initialization(main, main).
:- use_module(library(http/json)).
:- use_module(case).
:- discontiguous(dispatch_operation/3).
:- use_module(case_data, [case_id/1, case_title/1, victim/1, ending/1, lock_reason_text/2, evidence_meta/3, board_node/3]).

main :-
    set_stream(user_input, encoding(utf8)),
    set_stream(user_output, encoding(utf8)),
    loop.

loop :-
    read_line_to_string(user_input, Line),
    ( Line == end_of_file -> true
    ; handle_line(Line, Response),
      json_write_dict(current_output, Response, [width(0)]), nl, flush_output,
      loop
    ).

handle_line(Line, Response) :-
    atom_string(Atom, Line),
    catch(atom_json_dict(Atom, Request, []), Error, invalid_json_response(Error, Response)),
    ( var(Response) ->
        catch(dispatch(Request, Response), DispatchError, internal_error_response(DispatchError, Response))
    ; true
    ).

invalid_json_response(Error, Response) :-
    message_to_string(Error, Message),
    error_response(invalid_json, "Request must be one JSON object", _{detail:Message}, Response).

internal_error_response(Error, Response) :-
    message_to_string(Error, Message),
    error_response(internal_error, "The reasoning engine could not process the request", _{detail:Message}, Response).

error_response(Code, Message, Details, _{ok:false, error:Error}) :-
    put_dict(_{code:Code, message:Message}, Details, Error).

dispatch(Request, Response) :-
    ( is_dict(Request) -> dispatch_dict(Request, Response)
    ; error_response(invalid_request, "Request must be a JSON object", _{}, Response)
    ).

dispatch_dict(Request, Response) :-
    ( get_dict(operation, Request, Value) ->
        ( string(Value) -> atom_string(Operation, Value), dispatch_operation(Operation, Request, Response)
        ; error_response(invalid_type, "Field 'operation' must be a string", _{field:operation}, Response)
        )
    ; error_response(missing_field, "Missing required field 'operation'", _{field:operation}, Response)
    ).

dispatch_operation(reset, _, _{ok:true}) :- !,
    case:clear_player.
dispatch_operation(discover_evidence, Request, Response) :- !,
    do_discover_evidence(Request, Response).
dispatch_operation(record_statement, Request, Response) :- !,
    do_record_statement(Request, Response).
dispatch_operation(case_info, _, Response) :- !,
    case_id(Id), case_title(Title), victim(Victim),
    findall(Location, case:location(Location), Locations),
    findall(Ending, ending(Ending), Endings),
    Response = _{ok:true, id:Id, title:Title, victim:Victim, locations:Locations, endings:Endings}.
dispatch_operation(timeline, _, Response) :- !,
    findall(Entry, timeline_entry_dict(Entry), Entries),
    Response = _{ok:true, entries:Entries}.
dispatch_operation(available_evidence, _, Response) :- !,
    findall(Entry, evidence_availability_dict(Entry), Entries),
    Response = _{ok:true, evidence:Entries}.
dispatch_operation(why_locked, Request, Response) :- !,
    request_atom(Request, evidence, why_locked, Id, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:evidence(Id) ->
        error_response(unknown_evidence, "Evidence is not part of this case", _{operation:why_locked, field:evidence, value:Id}, Response)
    ; case:available_evidence(Id) ->
        Response = _{ok:true, evidence:Id, locked:false}
    ; case:why_locked(Id, Code), lock_reason_text(Code, Text) ->
        Response = _{ok:true, evidence:Id, locked:true, reason:Code, reason_title:Text}
    ; error_response(evidence_unavailable, "Evidence has not been unlocked", _{operation:why_locked, field:evidence, value:Id}, Response)
    ).
dispatch_operation(perform, Request, Response) :- !,
    ( get_dict(action, Request, ActionValue), string(ActionValue) ->
        atom_string(Action, ActionValue),
        perform_action(Action, Request, Response)
    ; get_dict(action, Request, _) ->
        error_response(invalid_type, "Field 'action' must be a string", _{operation:perform, field:action}, Response)
    ; error_response(missing_field, "Required field is missing", _{operation:perform, field:action}, Response)
    ).
dispatch_operation(why_not, Request, Response) :- !,
    request_atom(Request, fact, why_not, Fact, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:inference(Fact) ->
        error_response(unknown_proof, "Fact is not an authored inference", _{operation:why_not, field:fact, value:Fact}, Response)
    ; case:infer(Fact) ->
        Response = _{ok:true, fact:Fact, status:derivable, missing:[]}
    ; case:why_not(Fact, missing(Missing)) ->
        maplist(requirement_dict, Missing, MissingDicts),
        Response = _{ok:true, fact:Fact, status:blocked, missing:MissingDicts}
    ; error_response(proof_unavailable, "Required evidence or statements have not been discovered", _{operation:why_not, field:fact, value:Fact}, Response)
    ).
dispatch_operation(what_changed, Request, Response) :- !,
    request_atom(Request, evidence, what_changed, Id, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:evidence(Id) ->
        error_response(unknown_evidence, "Evidence is not part of this case", _{operation:what_changed, field:evidence, value:Id}, Response)
    ; case:what_changed(Id, consequences(Derivable, Pending)) ->
        maplist(inference_ref_dict, Derivable, DerivableDicts),
        maplist(inference_ref_dict, Pending, PendingDicts),
        Response = _{ok:true, evidence:Id, derivable:DerivableDicts, pending:PendingDicts}
    ; error_response(evaluation_unavailable, "Evidence evaluation not available", _{operation:what_changed, field:evidence, value:Id}, Response)
    ).
dispatch_operation(alternative_case, Request, Response) :- !,
    request_atom(Request, suspect, alternative_case, Suspect, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:person(Suspect) ->
        error_response(unknown_suspect, "Suspect is not part of this case", _{operation:alternative_case, field:suspect, value:Suspect}, Response)
    ; case:alternative_case(Suspect, explanation(Status, Unsupported)) ->
        maplist(unsupported_dimension_dict, Unsupported, UnsupportedDicts),
        person_name(Suspect, Name),
        Response = _{ok:true, suspect:Suspect, name:Name, status:Status, unsupported:UnsupportedDicts}
    ; error_response(evaluation_unavailable, "Alternative case not available", _{operation:alternative_case, field:suspect, value:Suspect}, Response)
    ).
dispatch_operation(board, _, Response) :- !,
    findall(Node, board_node_dict(Node), Nodes),
    findall(Edge, board_edge_dict_wrapper(Edge), Edges),
    Response = _{ok:true, nodes:Nodes, edges:Edges}.
dispatch_operation(minimal_proof, Request, Response) :- !,
    request_atom(Request, fact, minimal_proof, Fact, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:inference(Fact) ->
        error_response(unknown_proof, "Fact is not an authored inference", _{operation:minimal_proof, field:fact, value:Fact}, Response)
    ; case:minimal_proof_sets(Fact, [Leaves]) ->
        maplist(requirement_dict, Leaves, LeafDicts),
        Response = _{ok:true, fact:Fact, proof_set:LeafDicts}
    ; error_response(proof_unavailable, "No minimal proof set is computable from the current file", _{operation:minimal_proof, field:fact, value:Fact}, Response)
    ).
dispatch_operation(frontier, _, Response) :- !,
    findall(Entry, frontier_entry_dict_wrapper(Entry), Entries),
    Response = _{ok:true, frontier:Entries}.
dispatch_operation(hypothetical, Request, Response) :- !,
    request_atom(Request, suspect, hypothetical, Suspect, SuspectError),
    ( nonvar(SuspectError) -> Response = SuspectError
    ; \+ case:person(Suspect) ->
        error_response(unknown_suspect, "Suspect is not part of this case", _{operation:hypothetical, field:suspect, value:Suspect}, Response)
    ; request_known_evidence_array(Request, Extra, ExtraError),
      ( nonvar(ExtraError) -> Response = ExtraError
      ; case:hypothetical_accusation(Suspect, Extra, result(Evaluation, Selected)) ->
          result_dict(Evaluation, Selected, Result),
          Response = _{ok:true, suspect:Suspect, assumed:Extra, result:Result}
      ; error_response(evaluation_unavailable, "Hypothetical evaluation not available", _{operation:hypothetical, field:suspect, value:Suspect}, Response)
      )
    ).
dispatch_operation(why_possible, Request, Response) :- !,
    request_atom(Request, suspect, why_possible, Suspect, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:person(Suspect) ->
        error_response(unknown_suspect, "Suspect is not part of this case", _{operation:why_possible, field:suspect, value:Suspect}, Response)
    ; case:why_possible(Suspect, Reasons) ->
        person_name(Suspect, Name),
        Response = _{ok:true, suspect:Suspect, name:Name, viable:true, reasons:Reasons}
    ; person_name(Suspect, Name) ->
        Response = _{ok:true, suspect:Suspect, name:Name, viable:false, reasons:[]}
    ).
dispatch_operation(exclusion, Request, Response) :- !,
    request_atom(Request, suspect, exclusion, Suspect, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:person(Suspect) ->
        error_response(unknown_suspect, "Suspect is not part of this case", _{operation:exclusion, field:suspect, value:Suspect}, Response)
    ; case:exclusion_proof(Suspect, proved(Proof)) ->
        proof_dict(Proof, Tree),
        Response = _{ok:true, suspect:Suspect, status:excluded, proof:Tree}
    ; case:exclusion_proof(Suspect, blocked(Missing)) ->
        maplist(requirement_dict, Missing, MissingDicts),
        Response = _{ok:true, suspect:Suspect, status:unexcluded, missing:MissingDicts}
    ; error_response(evaluation_unavailable, "Exclusion evaluation not available", _{operation:exclusion, field:suspect, value:Suspect}, Response)
    ).
dispatch_operation(critical, _, Response) :- !,
    findall(Id, case:verdict_critical(Id), RawCritical),
    sort(RawCritical, Critical),
    maplist(evidence_ref_dict, Critical, Entries),
    Response = _{ok:true, critical:Entries}.
dispatch_operation(redundant, _, Response) :- !,
    findall(Id, case:verdict_redundant(Id), RawRedundant),
    sort(RawRedundant, Redundant),
    maplist(evidence_ref_dict, Redundant, Entries),
    Response = _{ok:true, redundant:Entries}.
dispatch_operation(strongest_alternative, Request, Response) :- !,
    request_atom(Request, suspect, strongest_alternative, Suspect, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:person(Suspect) ->
        error_response(unknown_suspect, "Suspect is not part of this case", _{operation:strongest_alternative, field:suspect, value:Suspect}, Response)
    ; case:ranked_alternatives(Suspect, Ranked) ->
        maplist(ranked_entry_dict, Ranked, RankedDicts),
        Response = _{ok:true, suspect:Suspect, ranked:RankedDicts}
    ; error_response(evaluation_unavailable, "Alternative ranking not available", _{operation:strongest_alternative, field:suspect, value:Suspect}, Response)
    ).
dispatch_operation(epistemic, _, Response) :- !,
    case:epistemic_status(Status),
    epistemic_dict(Status, Dict),
    Response = _{ok:true, epistemic:Dict}.
dispatch_operation(impact, Request, Response) :- !,
    request_atom(Request, evidence, impact, Id, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:evidence(Id) ->
        error_response(unknown_evidence, "Evidence is not part of this case", _{operation:impact, field:evidence, value:Id}, Response)
    ; case:evidence_impact(Id, impact(Gains, Triggers, Unlocks)) ->
        maplist(inference_ref_dict, Gains, GainDicts),
        maplist(impact_contradiction_dict, Triggers, TriggerDicts),
        maplist(evidence_ref_dict, Unlocks, UnlockDicts),
        Response = _{ok:true, evidence:Id, gains:GainDicts, triggers:TriggerDicts, unlocks:UnlockDicts}
    ; error_response(evaluation_unavailable, "Impact evaluation not available", _{operation:impact, field:evidence, value:Id}, Response)
    ).
dispatch_operation(director, Request, Response) :- !,
    request_atom(Request, suspect, director, Suspect, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:person(Suspect) ->
        error_response(unknown_suspect, "Suspect is not part of this case", _{operation:director, field:suspect, value:Suspect}, Response)
    ; case:available_topics(Suspect, Topics),
      case:interview_yield(Suspect, yield(NewClaims, Confrontations)),
      case:reaction_state(Suspect, Reaction),
      maplist(director_topic_dict, Topics, TopicDicts),
      person_name(Suspect, Name),
      Response = _{ok:true, suspect:Suspect, name:Name, reaction:Reaction,
                   topics:TopicDicts, new_claims:NewClaims, confrontations:Confrontations}
    ).
dispatch_operation(reactions, _, Response) :- !,
    findall(Entry, reaction_entry_dict(Entry), Entries),
    Response = _{ok:true, reactions:Entries}.

do_discover_evidence(Request, Response) :-
    request_atom(Request, evidence, discover_evidence, Id, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:evidence(Id) ->
        error_response(unknown_evidence, "Evidence is not part of this case", _{operation:discover_evidence, field:evidence, value:Id}, Response)
    ; case:discover_evidence(Id) ->
        current_inferences(Inferences, InferenceDetails),
        current_contradictions(Contradictions),
        Response = _{ok:true, evidence:Id, inferences:Inferences, inference_details:InferenceDetails, contradictions:Contradictions}
    ; error_response(evidence_unavailable, "Evidence has not been unlocked", _{operation:discover_evidence, field:evidence, value:Id}, Response)
    ).

do_record_statement(Request, Response) :-
    request_atom(Request, statement, record_statement, Statement, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:statement(Statement) ->
        error_response(unknown_statement, "Statement is not part of this case", _{operation:record_statement, field:statement, value:Statement}, Response)
    ; case:record_statement(Statement),
      current_contradictions(Contradictions),
      Response = _{ok:true, statement:Statement, contradictions:Contradictions}
    ).

perform_action(inspect, Request, Response) :- !,
    do_discover_evidence(Request, Inner),
    put_dict(performed, Inner, _{action:inspect}, Response).
perform_action(hear, Request, Response) :- !,
    do_record_statement(Request, Inner),
    put_dict(performed, Inner, _{action:hear}, Response).
perform_action(Action, _, Response) :-
    Action \= inspect, Action \= hear,
    error_response(unknown_operation, "Perform action is not supported", _{operation:perform, action:Action}, Response).

timeline_entry_dict(_{time:Time, event:Event, status:Status, requires:Requires, visible:Visible}) :-
    case:case_timeline(Time, Event, Status, Requires),
    ( forall(member(Requirement, Requires), case:player_evidence(Requirement)) ->
        Visible = true
    ; Visible = false
    ).

evidence_availability_dict(_{id:Id, title:Title, status:Status, available:Available}) :-
    case:evidence(Id),
    case:evidence_title(Id, Title),
    evidence_status(Id, Status),
    ( case:available_evidence(Id) -> Available = true ; Available = false ).

evidence_status(Id, Status) :-
    case_data:evidence_meta(Id, _, Status).

requirement_dict(evidence(Id), _{type:evidence, id:Id, title:Title}) :-
    case:evidence_title(Id, Title).
requirement_dict(statement(Id), _{type:statement, id:Id, title:Title}) :-
    case:statement_title(Id, Title).
requirement_dict(inference(Name), _{type:inference, id:Name, title:Title}) :-
    inference_title(Name, Title).

inference_ref_dict(Name, _{id:Name, title:Title}) :-
    inference_title(Name, Title).

unsupported_dimension_dict(dimension(Name, Status, Missing), _{name:Name, status:Status, missing:MissingDicts}) :-
    maplist(evidence_ref_dict, Missing, MissingDicts).

board_node_dict(_{id:Node, kind:Kind, status:Status, active:Active}) :-
    case:board_node_status(Node, Kind, Status),
    board_node_active(Node, Kind, Status, Active).

board_node_active(Node, contradiction, visible, true) :-
    case_data:board_node(Node, _, Requires),
    member(Statement, Requires),
    case:contradiction(Statement, _, _), !.
board_node_active(_, _, _, false).

board_edge_dict_wrapper(Dict) :-
    case:board_graph(Graph),
    Graph = graph(_, Edges),
    member(Edge, Edges),
    board_edge_dict(Edge, Dict).

board_edge_dict(edge(From, To, Relation, Active),
        _{from:FromDict, to:ToDict, relation:Relation, active:Active}) :-
    board_endpoint_dict(From, FromDict),
    board_endpoint_dict(To, ToDict).

board_endpoint_dict(evidence(Id), _{type:evidence, id:Id}).
board_endpoint_dict(statement(Id), _{type:statement, id:Id}).
board_endpoint_dict(inference(Id), _{type:inference, id:Id}).
board_endpoint_dict(suspect(Id), _{type:suspect, id:Id}).

frontier_entry_dict_wrapper(Dict) :-
    case:frontier(Entries),
    member(frontier(Inference, Missing), Entries),
    inference_title(Inference, Title),
    requirement_dict(Missing, MissingDict),
    Dict = _{inference:Inference, title:Title, missing:MissingDict}.

ranked_entry_dict(rank(Other, Score), _{suspect:Other, name:Name, score:Score}) :-
    person_name(Other, Name).

epistemic_dict(epistemic(proven, Threshold), _{status:proven, threshold:Threshold}).
epistemic_dict(epistemic(conflicted, Count), _{status:conflicted, open_contradictions:Count}).
epistemic_dict(epistemic(open, evidence(Count)), _{status:open, discovered:Count}).
epistemic_dict(epistemic(fresh, none), _{status:fresh}).

impact_contradiction_dict(contradiction(Statement, Evidence),
        _{statement:Statement, statement_title:StatementTitle,
          evidence:Evidence, evidence_title:EvidenceTitle}) :-
    case:statement_title(Statement, StatementTitle),
    case:evidence_title(Evidence, EvidenceTitle).

director_topic_dict(claim(Statement), _{kind:claim, id:Statement, title:Title}) :-
    case:statement_title(Statement, Title).
director_topic_dict(confront(Statement), _{kind:confront, id:Statement, title:Title}) :-
    case:statement_title(Statement, Title).

reaction_entry_dict(_{suspect:Suspect, name:Name, reaction:Reaction}) :-
    case:person(Suspect),
    person_name(Suspect, Name),
    case:reaction_state(Suspect, Reaction).

dispatch_operation(query_state, _, Response) :- !,
    current_inferences(Inferences, InferenceDetails),
    current_contradictions(Contradictions),
    knowledge_dict(Knowledge),
    Response = _{ok:true, inferences:Inferences, inference_details:InferenceDetails, contradictions:Contradictions, knowledge:Knowledge}.
dispatch_operation(proof, Request, Response) :- !,
    request_atom(Request, fact, proof, Fact, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:inference(Fact) ->
        error_response(unknown_proof, "Fact is not an authored inference", _{operation:proof, field:fact, value:Fact}, Response)
    ; case:proof(Fact, Raw) ->
        proof_dict(Raw, Tree),
        get_dict(premises, Tree, Steps),
        Response = _{ok:true, fact:Fact, proof:Tree, steps:Steps}
    ; error_response(proof_unavailable, "Required evidence or statements have not been discovered", _{operation:proof, field:fact, value:Fact}, Response)
    ).
dispatch_operation(evaluate_evidence, Request, Response) :- !,
    request_atom(Request, evidence, evaluate_evidence, Id, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:evidence(Id) ->
        error_response(unknown_evidence, "Evidence is not part of this case", _{operation:evaluate_evidence, field:evidence, value:Id}, Response)
    ; case:evaluate_evidence(Id, Raw) ->
        evaluate_evidence_dict(Raw, Dict),
        Response = _{ok:true, evidence:Id, evaluation:Dict}
    ; error_response(evaluation_unavailable, "Evidence evaluation not available", _{operation:evaluate_evidence, field:evidence, value:Id}, Response)
    ).
dispatch_operation(evaluate_hypothesis, Request, Response) :- !,
    request_atom(Request, suspect, evaluate_hypothesis, Suspect, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:person(Suspect) ->
        error_response(unknown_suspect, "Suspect is not part of this case", _{operation:evaluate_hypothesis, field:suspect, value:Suspect}, Response)
    ; accusation_has_argument(Request) ->
        accusation_request(Request, Suspect, Raw, Selected, ArgumentError),
        ( nonvar(ArgumentError) -> Response = ArgumentError
        ; hypothesis_result_dict(Suspect, Raw, Selected, Evaluation),
          Response = _{ok:true, suspect:Suspect, evaluation:Evaluation}
        )
    ; case:evaluate_hypothesis(Suspect, Raw) ->
        evaluate_hypothesis_dict(Raw, Dict),
        Response = _{ok:true, suspect:Suspect, evaluation:Dict}
    ; error_response(evaluation_unavailable, "Hypothesis evaluation not available", _{operation:evaluate_hypothesis, field:suspect, value:Suspect}, Response)
    ).
dispatch_operation(possible_alternatives, _, Response) :- !,
    findall(Dict, (case:possible_suspect(S), person_name(S, Name), Dict = _{id:S, name:Name, status:possible}), Alternatives),
    Response = _{ok:true, alternatives:Alternatives}.
dispatch_operation(accusation, Request, Response) :- !,
    request_atom(Request, suspect, accusation, Suspect, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:person(Suspect) ->
        error_response(unknown_suspect, "Suspect is not part of this case", _{operation:accusation, field:suspect, value:Suspect}, Response)
    ; accusation_request(Request, Suspect, Raw, Selected, ArgumentError),
      ( nonvar(ArgumentError) -> Response = ArgumentError
      ; result_dict(Raw, Selected, Result),
        Response = _{ok:true, suspect:Suspect, result:Result}
      )
    ).
dispatch_operation(Operation, _, Response) :-
    error_response(unknown_operation, "Operation is not supported", _{operation:Operation}, Response).

request_atom(Request, Field, Operation, Atom, Error) :-
    ( get_dict(Field, Request, Value) ->
        ( string(Value) -> atom_string(Atom, Value)
        ; error_response(invalid_type, "Required field must be a string", _{operation:Operation, field:Field}, Error)
        )
    ; error_response(missing_field, "Required field is missing", _{operation:Operation, field:Field}, Error)
    ).

accusation_request(Request, Suspect, Raw, Selected, Error) :-
    ( accusation_has_argument(Request) ->
        request_evidence_array(Request, motive, Motive, Error),
        request_evidence_array(Request, method, Method, Error),
        request_evidence_array(Request, opportunity, Opportunity, Error),
        request_evidence_array(Request, evidence, Selected, Error),
        ( var(Error) ->
            validate_selected_premises([motive-Motive, method-Method, opportunity-Opportunity], Selected, Error)
        ; true
        ),
        ( var(Error) -> case:accusation(Suspect, argument(Motive, Method, Opportunity, Selected), Raw) ; true )
    ; findall(Id, case:player_evidence(Id), Selected),
      case:accusation(Suspect, Raw)
    ).

accusation_has_argument(Request) :-
    member(Field, [motive, method, opportunity, evidence]), get_dict(Field, Request, _), !.

% Hypothetical extras may be undiscovered by design; only shape, known
% ids, and duplicates are validated here.
request_known_evidence_array(Request, Ids, Error) :-
    ( get_dict(evidence, Request, Values) ->
        ( is_list(Values) -> validate_known_evidence_values(Values, Ids, Error)
        ; error_response(invalid_type, "Field 'evidence' must be an array", _{operation:hypothetical, field:evidence}, Error)
        )
    ; error_response(missing_field, "Required field is missing", _{operation:hypothetical, field:evidence}, Error)
    ).

validate_known_evidence_values(Values, Ids, Error) :-
    ( member(Value, Values), \+ string(Value) ->
        error_response(invalid_type, "Evidence IDs must be strings", _{operation:hypothetical, field:evidence, value:Value}, Error)
    ; maplist(atom_string, Ids, Values),
      ( member(Id, Ids), \+ case:evidence(Id) ->
          error_response(unknown_evidence, "Evidence is not part of this case", _{operation:hypothetical, field:evidence, value:Id}, Error)
      ; duplicate_id(Ids, Duplicate) ->
          error_response(duplicate_evidence, "Evidence IDs must not be duplicated", _{operation:hypothetical, field:evidence, value:Duplicate}, Error)
      ; true
      )
    ).

request_evidence_array(_, _, _, Error) :- nonvar(Error), !.
request_evidence_array(Request, Field, Ids, Error) :-
    ( get_dict(Field, Request, Values) ->
        ( is_list(Values) -> validate_evidence_values(Values, Field, Ids, Error)
        ; error_response(invalid_type, "Accusation evidence field must be an array", _{operation:accusation, field:Field}, Error)
        )
    ; error_response(missing_field, "Structured accusation field is missing", _{operation:accusation, field:Field}, Error)
    ).

validate_evidence_values(Values, Field, Ids, Error) :-
    ( member(Value, Values), \+ string(Value) ->
        error_response(invalid_type, "Accusation evidence IDs must be strings", _{operation:accusation, field:Field, value:Value}, Error)
    ; maplist(atom_string, Ids, Values),
      ( member(Id, Ids), \+ case:evidence(Id) ->
          error_response(unknown_evidence, "Evidence is not part of this case", _{operation:accusation, field:Field, value:Id}, Error)
      ; duplicate_id(Ids, Duplicate) ->
          error_response(duplicate_evidence, "Evidence IDs must not be duplicated within a field", _{operation:accusation, field:Field, value:Duplicate}, Error)
      ; member(Id, Ids), \+ case:player_evidence(Id) ->
          error_response(undiscovered_evidence, "Selected evidence has not been discovered", _{operation:accusation, field:Field, value:Id}, Error)
      ; true
      )
    ).

duplicate_id([Id|Rest], Id) :- memberchk(Id, Rest), !.
duplicate_id([_|Rest], Id) :- duplicate_id(Rest, Id).

validate_selected_premises(Dimensions, Selected, Error) :-
    ( member(Field-Ids, Dimensions), member(Id, Ids), \+ memberchk(Id, Selected) ->
        error_response(unselected_premise, "Dimension evidence must also appear in 'evidence'", _{operation:accusation, field:Field, value:Id}, Error)
    ; true
    ).

current_inferences(Names, Details) :-
    findall(Name, case:infer(Name), RawNames),
    sort(RawNames, Names),
    findall(Tree, (member(Name, Names), case:proof(Name, Proof), proof_dict(Proof, Tree)), Details).

current_contradictions(List) :-
    findall(Dict,
        ( case:contradiction(Statement, Evidence, Reason),
          case:statement_title(Statement, StatementTitle),
          case:evidence_title(Evidence, EvidenceTitle),
          reason_title(Reason, ReasonTitle),
          Dict = _{status:contradicted, statement:Statement, statement_title:StatementTitle,
                   evidence:Evidence, evidence_title:EvidenceTitle, reason:Reason, reason_title:ReasonTitle}
        ), List).

knowledge_dict(_{
    discovered:Discovered,
    inferred:Inferred,
    hypothesized:Hypothesized,
    contradicted:Contradicted,
    possible:Possible,
    impossible:Impossible,
    proven:Proven
}) :-
    findall(_{id:Id, title:Title, status:discovered},
        (case:knowledge(discovered, evidence(Id)), case:evidence_title(Id, Title)), Discovered),
    findall(Tree,
        (case:knowledge(inferred, Name), case:proof(Name, Proof), proof_dict(Proof, Tree)), Inferred),
    findall(Person, case:knowledge(hypothesized, Person), HypothesisTerms),
    maplist(suspect_term_dict(hypothesized), HypothesisTerms, Hypothesized),
    current_contradictions(Contradicted),
    findall(Person, case:knowledge(possible, Person), PossibleTerms),
    maplist(suspect_term_dict(possible), PossibleTerms, Possible),
    findall(Person, case:knowledge(impossible, Person), ImpossibleTerms),
    maplist(suspect_term_dict(impossible), ImpossibleTerms, Impossible),
    findall(Person, case:knowledge(proven, Person), ProvenTerms),
    maplist(suspect_term_dict(proven), ProvenTerms, Proven).

suspect_term_dict(Status, suspect(Id), _{id:Id, name:Name, status:Status}) :-
    person_name(Id, Name).

proof_dict(proof(Name, Premises, Rule), _{fact:Name, conclusion:Title, status:inferred, rule:Rule, premises:PremiseDicts}) :-
    inference_title(Name, Title),
    maplist(proof_premise_dict, Premises, PremiseDicts).

proof_premise_dict(evidence(Id), _{type:evidence, id:Id, title:Title, status:discovered}) :-
    case:evidence_title(Id, Title).
proof_premise_dict(statement(Id), _{type:statement, id:Id, title:Title, status:heard}) :-
    case:statement_title(Id, Title).
proof_premise_dict(inference(Name, Proof), _{type:inference, id:Name, title:Title, proof:Tree}) :-
    inference_title(Name, Title),
    proof_dict(Proof, Tree).

evaluate_evidence_dict(evaluation(Id, Relevance, supports(Infs)), _{evidence:Id, relevance:Relevance, supports:Infs}).
evaluate_hypothesis_dict(evaluation(Suspect, Status, Dimensions), _{suspect:Suspect, status:Status, dimensions:DimDicts}) :-
    maplist(dim_eval_dict, Dimensions, DimDicts).

hypothesis_result_dict(Suspect, evaluation(
    sufficient_evidence(_), unique_solution(_), ending(_),
    dimensions(Dimensions), unsupported(Unsupported),
    alternatives(Alternatives), ignored_contradictions(Ignored)
), SelectedIds, _{
    suspect:Suspect,
    status:Status,
    consistency:Consistency,
    circular_reasoning:false,
    dimensions:DimensionDicts,
    unsupported:UnsupportedDicts,
    contradictions:IgnoredDicts,
    alternatives:AlternativeDicts,
    selected_evidence:Selected
}) :-
    maplist(dimension_dict, Dimensions, DimensionDicts),
    maplist(gap_dict, Unsupported, UnsupportedDicts),
    maplist(ignored_dict, Ignored, IgnoredDicts),
    maplist(alternative_dict, Alternatives, AlternativeDicts),
    maplist(evidence_ref_dict, SelectedIds, Selected),
    hypothesis_status(Dimensions, Unsupported, Ignored, Status),
    ( Ignored == [], \+ member(gap(unsupported_premise, _, _), Unsupported) ->
        Consistency = consistent
    ; Consistency = inconsistent
    ).

hypothesis_status(_, _, [_|_], contradicted) :- !.
hypothesis_status(Dimensions, _, _, contradicted) :-
    member(dimension(_, contradicted, _, _), Dimensions), !.
hypothesis_status(Dimensions, Unsupported, [], coherent) :-
    Unsupported == [],
    forall(member(dimension(_, DimensionStatus, _, _), Dimensions), DimensionStatus == supported), !.
hypothesis_status(_, _, _, under_supported).

dim_eval_dict(dimension(Name, Status, Support, Missing), _{name:Name, status:Status, support:Support, missing:Missing}).

result_dict(evaluation(
    sufficient_evidence(Sufficient), unique_solution(Unique),
    ending(Ending), dimensions(Dimensions), unsupported(Unsupported),
    alternatives(Alternatives), ignored_contradictions(Ignored)
), SelectedIds, _{
    sufficient_evidence:Sufficient,
    unique_solution:Unique,
    ending:Ending,
    motive:Motive,
    method:Method,
    opportunity:Opportunity,
    dimensions:DimensionDicts,
    unsupported:UnsupportedDicts,
    alternatives:AlternativeDicts,
    ignored_contradictions:IgnoredDicts,
    consistency:Consistency,
    circular_reasoning:Circular,
    selected_evidence:Selected,
    uniqueness:Unique
}) :-
    maplist(dimension_dict, Dimensions, DimensionDicts),
    dimension_status_from_list(motive, Dimensions, Motive),
    dimension_status_from_list(method, Dimensions, Method),
    dimension_status_from_list(opportunity, Dimensions, Opportunity),
    maplist(gap_dict, Unsupported, UnsupportedDicts),
    maplist(alternative_dict, Alternatives, AlternativeDicts),
    maplist(ignored_dict, Ignored, IgnoredDicts),
    maplist(evidence_ref_dict, SelectedIds, Selected),
    ( Ignored == [], \+ member(gap(unsupported_premise, _, _), Unsupported) -> Consistency = consistent ; Consistency = inconsistent ),
    Circular = false.

dimension_status_from_list(Name, Dimensions, Status) :-
    memberchk(dimension(Name, Status, _, _), Dimensions).

dimension_dict(dimension(Name, Status, Support, Missing), _{
    name:Name, status:Status, support:SupportDicts, missing:MissingDicts
}) :-
    maplist(evidence_ref_dict, Support, SupportDicts),
    maplist(evidence_ref_dict, Missing, MissingDicts).

evidence_ref_dict(Id, _{id:Id, title:Title}) :- case:evidence_title(Id, Title).

gap_dict(gap(dimension, Name, Status, Missing), _{code:unsupported_dimension, dimension:Name, status:Status, missing:MissingDicts}) :-
    maplist(evidence_ref_dict, Missing, MissingDicts).
gap_dict(gap(required_evidence, Id), _{code:required_evidence_missing, evidence:Evidence}) :-
    evidence_ref_dict(Id, Evidence).
gap_dict(gap(exclusion_records, Count), _{code:exclusion_records_missing, count:Count}).
gap_dict(gap(unsupported_premise, Dimension, Id), _{code:unsupported_premise, dimension:Dimension, evidence:Evidence}) :-
    evidence_ref_dict(Id, Evidence).

alternative_dict(alternative(Id, Status, Reason), _{id:Id, name:Name, status:Status, reason:Reason}) :-
    person_name(Id, Name).

ignored_dict(contradiction(Statement, Evidence, Reason), _{
    type:contradiction, statement:Statement, statement_title:StatementTitle,
    evidence:Evidence, evidence_title:EvidenceTitle, reason:Reason, reason_title:ReasonTitle
}) :-
    case:statement_title(Statement, StatementTitle),
    case:evidence_title(Evidence, EvidenceTitle),
    reason_title(Reason, ReasonTitle).
ignored_dict(exclusion(Id, Rule), _{type:exclusion, suspect:Id, name:Name, reason:Rule}) :-
    person_name(Id, Name).
ignored_dict(stronger_supported_case(Id), _{type:stronger_supported_case, suspect:Id, name:Name}) :-
    person_name(Id, Name).

% Display titles are authored once in case_data and re-exported through case.
