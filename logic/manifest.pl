% Player-safe manifest builder. The checked-in case.json is generated from
% case_data through manifest_dict/1; the validator enforces parity.
:- module(manifest, [manifest_dict/1]).
:- use_module(case_data, []).

manifest_dict(Manifest) :-
    case_data:case_id(Id),
    case_data:case_title(Title),
    case_data:victim(Victim),
    case_data:time_basis(Basis),
    findall(Location, location_entry(Location), Locations),
    findall(Entry, timeline_entry(Entry), Timeline),
    findall(Person, person_entry(Person), People),
    findall(Evidence, evidence_entry(Evidence), Evidence),
    findall(Ending, case_data:ending(Ending), Endings),
    findall(Statement, statement_entry(Statement), Statements),
    Manifest = _{
        id: Id, title: Title, victim: Victim, locations: Locations,
        time_basis: Basis, timeline: Timeline, people: People,
        evidence: Evidence, endings: Endings, statements: Statements
    }.

location_entry(_{id:Id, name:Name, note:Note, evidence:Routes}) :-
    case_data:location_detail(Id, Name, Note),
    findall(_{id:Evidence, label:Label},
        case_data:location_evidence(Id, Evidence, Label),
        Routes).

timeline_entry(_{time:Time, minute:Minute, event:Event, status:Status, requires:Requires}) :-
    case_data:timeline_event(Time, Event, Status, Requires),
    \+ sub_atom(Time, _, _, _, '-'),
    display_minute(Time, Minute).
timeline_entry(_{time:Time, start_minute:Start, end_minute:End, event:Event, status:Status, requires:Requires}) :-
    case_data:timeline_event(Time, Event, Status, Requires),
    atomic_list_concat([StartDisplay, EndDisplay], '-', Time),
    display_minute(StartDisplay, Start),
    display_minute(EndDisplay, End).

display_minute(Display, Minute) :-
    atomic_list_concat([HourAtom, MinuteAtom], ':', Display),
    atom_number(HourAtom, Hour), atom_number(MinuteAtom, MinutePart),
    Minute is Hour * 60 + MinutePart.

person_entry(_{id:Id, name:Name, age:Age, role:Role}) :-
    case_data:person_detail(Id, Name, Age, Role).

evidence_entry(_{id:Id, title:Title, status:Status, supports:Supports}) :-
    case_data:evidence_meta(Id, Title, Status),
    findall(Inference, case_data:evidence_supports(Id, Inference), Supports).

statement_entry(_{id:Id, title:Title}) :-
    case_data:statement_detail(Id, Title).
