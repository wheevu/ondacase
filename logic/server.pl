:- initialization(main, main).
:- use_module(library(http/json)).
:- use_module(case).

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
dispatch_operation(record_statement, Request, Response) :- !,
    request_atom(Request, statement, record_statement, Statement, Error),
    ( nonvar(Error) -> Response = Error
    ; \+ case:statement(Statement) ->
        error_response(unknown_statement, "Statement is not part of this case", _{operation:record_statement, field:statement, value:Statement}, Response)
    ; case:record_statement(Statement),
      current_contradictions(Contradictions),
      Response = _{ok:true, statement:Statement, contradictions:Contradictions}
    ).
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
