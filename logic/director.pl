% Narrative-director layer. Ink owns prose and branching text; Prolog decides
% whether a topic, confrontation, or reaction is logically justified by
% player knowledge. Every predicate here derives from live engine state, so
% no dialogue condition is authored twice.
:- module(director, [
    confrontation_grounds/4, reaction_state/2,
    interview_yield/2, available_topics/2
]).

:- use_module(engine).

% Live contradictions on a suspect's own claims justify confrontation.
confrontation_grounds(Suspect, Statement, Evidence, Reason) :-
    person(Suspect),
    claims(Suspect, _, Statement),
    contradiction(Statement, Evidence, Reason).

% How a suspect should play in conversation, given what the file holds.
reaction_state(Suspect, case_proven) :-
    person(Suspect),
    knowledge(proven, suspect(Suspect)), !.
reaction_state(Suspect, exonerated) :-
    person(Suspect),
    impossible_suspect(Suspect), !.
reaction_state(Suspect, cornered) :-
    person(Suspect),
    confrontation_grounds(Suspect, _, _, _), !.
reaction_state(Suspect, open) :-
    person(Suspect).

% What an interview can still yield: unheard claims and open confrontations.
interview_yield(Suspect, yield(NewClaims, Confrontations)) :-
    person(Suspect),
    findall(Statement,
        (claims(Suspect, _, Statement), \+ player_statement(Statement, heard)),
        NewClaims),
    findall(Statement,
        confrontation_grounds(Suspect, Statement, _, _),
        Confrontations).

% Topics justified right now: fresh claims first, confrontations second.
available_topics(Suspect, Topics) :-
    interview_yield(Suspect, yield(NewClaims, Confrontations)),
    findall(claim(Statement), member(Statement, NewClaims), ClaimTopics),
    findall(confront(Statement), member(Statement, Confrontations), ConfrontTopics),
    append(ClaimTopics, ConfrontTopics, Topics).
