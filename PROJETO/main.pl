% Rodrigo Freire, 106485
:- set_prolog_flag(answer_write_options,[max_depth(0)]). % para listas completas
:- ['dados.pl'], ['keywords.pl']. % ficheiros a importar.




% ----------------- QUALIDADE DOS DADOS -----------------------

eventosSemSalas(L) :-
    findall(Id, evento(Id, _, _, _, semSala), L_pre),
    sort(L_pre, L).

% ##############

isDay(Day, Id) :-
    horario(Id, X, _, _, _, _),
    Day = X.

eventosSemSalasDiaSemana(D, L) :-
    eventosSemSalas(Lpre),
    include(isDay(D), Lpre, L).

% #############

isPeriod(Period, Id) :-
    horario(Id, _, _, _, _, X),
    Period = X, !.

isPeriod(Period, Id) :-
    horario(Id, _, _, _, _, p1_2),
    (Period = p1; Period = p2), !.

isPeriod(Period, Id) :-
    horario(Id, _, _, _, _, p3_4),
    (Period = p3; Period = p4), !.


eventosSemSalasPeriodo([], []).

eventosSemSalasPeriodo([P|Ps], L) :-
    eventosSemSalas(Source),
    include(isPeriod(P), Source, Lp),
    eventosSemSalasPeriodo(Ps, J),
    append(J, Lp, Lpre),
    sort(Lpre, L).


% --------------------- PESQUISAS SIMPLES ---------------------


organizaEventos([], _, []).

organizaEventos([LstEventHEAD|LstEventTAIL], P, L) :-
    \+ isPeriod(P, LstEventHEAD),
    organizaEventos(LstEventTAIL, P, L),
    !.

organizaEventos([LstEventHEAD|LstEventTAIL], P, L) :-
    isPeriod(P, LstEventHEAD),
    organizaEventos(LstEventTAIL, P, Temp),
    append(Temp, [LstEventHEAD], Lpre),
    sort(Lpre, L).

% #################

eventosMenoresQue(Dur, ListEventsLessThan) :-
    findall(Id, (horario(Id, _, _, _, X, _), X =< Dur), List_pre),
    sort(List_pre, ListEventsLessThan).

% ################

eventosMenoresQueBool(Id, Dur) :-
    horario(Id, _, _, _, X, _),
    X =< Dur.

% ################

procuraDisciplinas(Curso, ListaDisciplinas) :-
    findall(C, (turno(Id, Curso, _, _), evento(Id, C, _, _, _)), List_pre),
    sort(List_pre, ListaDisciplinas).

% ###############

isSemesterOne(Id) :-
    isPeriod(p1, Id);
    isPeriod(p2, Id).

getSemester(Disc, Curso, Sem) :-
    turno(Id, Curso, _, _),
    evento(Id, Disc, _, _, _),
    isSemesterOne(Id), Sem is 1, !.

getSemester(Disc, Curso, Sem) :-
    turno(Id, Curso, _, _),
    evento(Id, Disc, _, _, _),
    \+ isSemesterOne(Id), Sem is 2, !.
    

organizaDisciplinas([], _, [[],[]]).

organizaDisciplinas([ListDiscHEAD|ListDiscTAIL], Curso, Semestres) :-
    getSemester(ListDiscHEAD, Curso, 1),
    organizaDisciplinas(ListDiscTAIL, Curso, [TempHEAD,TempTAIL]),
    append(TempHEAD, [ListDiscHEAD], Semestre1_pre),
    sort(Semestre1_pre, Semestre1),
    append([Semestre1], [TempTAIL], Semestres), !.

organizaDisciplinas([ListDiscHEAD|ListDiscTAIL], Curso, Semestres) :-
    getSemester(ListDiscHEAD, Curso, 2),
    organizaDisciplinas(ListDiscTAIL, Curso, [TempHEAD,TempTAIL]),
    append(TempTAIL, [ListDiscHEAD], Semestre2_pre),
    sort(Semestre2_pre, Semestre2),
    append([TempHEAD], [Semestre2], Semestres), !.

% ####################

idToDuration(Id, Dur) :- horario(Id, _, _, _, Dur, _).

sum(X, Y, S) :- S is X + Y. 

filterIds(Id, P, Curso, A) :-
    P \= p3, P \= p4,
    turno(Id, Curso, A, _),
    (horario(Id, _, _, _, _, P); horario(Id, _, _, _, _, p1_2)).

filterIds(Id, P, Curso, A) :-
    P \= p1, P \= p2,
    turno(Id, Curso, A, _),
    (horario(Id, _, _, _, _, P); horario(Id, _, _, _, _, p3_4)).

horasCurso(P, Curso, A, TotHours) :-
    findall(Id, filterIds(Id, P, Curso, A), CursoIds),
    sort(CursoIds, CursoIdsSorted),
    maplist(idToDuration, CursoIdsSorted, DurList),
    foldl(sum, DurList, 0, TotHours).

% ######################

getEvolution(_, [], [], []) :- !.

getEvolution(Curso, [L_A_HEAD|L_A_TAIL], [L_P_HEAD|L_P_TAIL], Evolution) :-
    horasCurso(L_P_HEAD, Curso, L_A_HEAD, TotHours),
    Info = [(L_A_HEAD, L_P_HEAD, TotHours)],
    getEvolution(Curso, L_A_TAIL, L_P_TAIL, Temp),
    append(Temp, Info, Evolution).


evolucaoHorasCurso(Curso, Evolucao) :-
    ListYears = [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3],
    ListPeriods = [p1, p2, p3, p4, p1, p2, p3, p4, p1, p2, p3, p4],
    getEvolution(Curso, ListYears, ListPeriods, Evolucao_pre),
    sort(Evolucao_pre, Evolucao).


% -------------------------- OCUPACOES CRITICAS ------------------------


ocupaSlot(HiniDada, HfinDada, HiniEvt, HfinEvt, Horas) :-
    (HiniDada =< HiniEvt), (HfinDada >= HiniEvt),
    (HiniDada =< HfinEvt), (HfinDada >= HfinEvt),
    Horas is HfinEvt - HiniEvt, !.

ocupaSlot(HiniDada, HfinDada, HiniEvt, HfinEvt, Horas) :-
    (HiniDada >= HiniEvt), (HfinDada >= HiniEvt),
    (HiniDada =< HfinEvt), (HfinDada =< HfinEvt),
    Horas is HfinDada - HiniDada, !.

ocupaSlot(HiniDada, HfinDada, HiniEvt, HfinEvt, Horas) :-
    (HiniDada =< HiniEvt), (HfinDada >= HiniEvt),
    (HiniDada =< HfinEvt), (HfinDada =< HfinEvt),
    Horas is HfinDada - HiniEvt, !.

ocupaSlot(HiniDada, HfinDada, HiniEvt, HfinEvt, Horas) :-
    (HiniDada >= HiniEvt), (HfinDada >= HiniEvt),
    (HiniDada =< HfinEvt), (HfinDada >= HfinEvt),
    Horas is HfinEvt - HiniDada, !.

% #######################

getEventIds(Period, RoomType, Day, Hini, Hfim, Duration) :-
    horario(Id, Day, Hini_, Hfim_, _, _),
    ocupaSlot(Hini_, Hfim_, Hini, Hfim, Duration),
    evento(Id, _, _, _, Room),
    salas(RoomType, R),
    memberchk(Room, R),
    isPeriod(Period, Id).


numHorasOcupadas(Period, RoomType, Day, Hini, Hfim, SumH) :-
    findall(Duration, getEventIds(Period, RoomType, Day, Hini, Hfim, Duration), DurationList),
    foldl(sum, DurationList, 0, SumH).
