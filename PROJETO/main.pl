% Rodrigo Freire, 106485
:- set_prolog_flag(answer_write_options,[max_depth(0)]). % full lists
:- ['dados.pl'], ['keywords.pl']. % imports




% --------------------------------- QUALIDADE DOS DADOS ---------------------------------

eventosSemSalas(EventosSemSala) :-
    /*
        eventosSemSalas eh verdade se EventosSemSala for a lista dos IDs de eventos sem
        salas
    */
    findall(ID, evento(ID, _, _, _, semSala), EventosSemSala_pre),
    sort(EventosSemSala_pre, EventosSemSala).



eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala) :-
    /*
        eventosSemSalasDiaSemana eh verdade se EventosSemSala for a lista dos IDs de
        eventos sem salas que acontecem no dia DiaDaSemana.
    */
    findall(
        ID,
        (evento(ID, _, _, _, semSala), horario(ID, DiaDaSemana, _, _, _, _)),
        EventosSemSala_pre
    ),

    sort(EventosSemSala_pre, EventosSemSala).



isPeriod(Period, ID) :-
    /* 
        Predicado Auxiliar que devolve o periodo de um evento com certo ID e no caso
        particular de eventos semestrais devolve os dois periodos associados
    */
    horario(ID, _, _, _, _, Period), !. % Caso 'normal' 

isPeriod(Period, ID) :-
    horario(ID, _, _, _, _, p1_2), % Caso semestral (p1_2)
    (Period = p1; Period = p2), !.

isPeriod(Period, ID) :-
    horario(ID, _, _, _, _, p3_4), % Caso semestral (p3_4)
    (Period = p3; Period = p4), !.



eventosSemSalasPeriodo([], []). % Caso Terminal

eventosSemSalasPeriodo([P|Ps], LstSemSala) :-
    /*
        eventosSemSalasPeriodo eh verdade se ListaSemSala for a lista dos IDs
        de eventos sem salas que acontecem nos periodos da lista [P|Ps]
    */
    eventosSemSalas(Source),
    include(isPeriod(P), Source, LstFiltrada), % Lista Filtrada de acordo com o periodo
    eventosSemSalasPeriodo(Ps, Temp),

    append(Temp, LstFiltrada, LstSemSala_pre),
    sort(LstSemSala_pre, LstSemSala).
    


% ---------------------------------- PESQUISAS SIMPLES ----------------------------------



organizaEventos([], _, []). % Caso Terminal

organizaEventos([EventLstH|EventLstT], Periodo, EventosPeriodo) :-
    /* 
        organizaEventos eh verdade se EventosNoPeriodo for a lista dos IDs dos eventos de
        ListEvents que acontecem no periodo Periodo. Caso 1: Periodo correto
    */
    isPeriod(Periodo, EventLstH), !,
    organizaEventos(EventLstT, Periodo, Temp),

    append(Temp, [EventLstH], EventosPeriodo_pre),
    sort(EventosPeriodo_pre, EventosPeriodo).

organizaEventos([_|EventLstT], Periodo, EventosPeriodo) :-
    /* Caso 2: Periodo errado */
    organizaEventos(EventLstT, Periodo, EventosPeriodo).



eventosMenoresQue(Duracao, LstEventosMenQue) :-
    /* 
        eventosMenoresQue eh verdade se ListaEventosMenoresQue for a lista de IDs dos
        eventos que teem duracao menor ou igual a Duracao
    */
    findall(Id, (horario(Id, _, _, _, X, _), X =< Duracao), Lst_pre),
    sort(Lst_pre, LstEventosMenQue).



eventosMenoresQueBool(ID, Duracao) :-
    /* 
        eventosMenoresQueBool eh verdade se o evento com id ID tiver duracao menor ou
        igual a Duaracao
    */
    horario(ID, _, _, _, X, _),
    X =< Duracao.



procuraDisciplinas(Curso, LstDisc) :-
    /* 
        procuraDisciplinas eh verdade se ListaDisciplinas for a lista das disciplinas
        do curso Curso
    */
    findall(Disc, (turno(ID, Curso, _, _), evento(ID, Disc, _, _, _)), LstDisc_pre),
    sort(LstDisc_pre, LstDisc).



isSemesterOne(ID) :-
    /* 
        Predicado Auxiliar: Eh verdade se o evento de dado ID ocorrer no primeiro
        semestre
    */
    isPeriod(p1, ID); isPeriod(p2, ID).

getSemester(Disciplina, Curso, Sem) :-
    /* 
        Predicado Auxiliar: Eh verdade se Sem for o numero correspondente ao semestre
        em que a disciplina Disciplina decorre.
    */
    turno(ID, Curso, _, _),
    evento(ID, Disciplina, _, _, _),
    isSemesterOne(ID), Sem = 1, !.

getSemester(Disciplina, Curso, Sem) :-
    turno(ID, Curso, _, _),
    evento(ID, Disciplina, _, _, _),
    Sem = 2.
    

organizaDisciplinas([], _, [[],[]]). % Caso Terminal.

organizaDisciplinas([LstDiscH|LstDiscT], Curso, Semestres) :-
    /* 
        organizaDisciplinas eh verdade se semestres for uma lista com duas sublistas
        em que cada uma corresponde ao conjunto de disciplinas de ListDisc do semestre
        (Lista1 -> Disciplinas de Semestre 1, Lista2 -> Disciplinas de Semestre 2)
        Caso 1: LstDiscH eh do semestre 1 
    */
    getSemester(LstDiscH, Curso, 1),
    organizaDisciplinas(LstDiscT, Curso, [TempH,TempT]),

    append(TempH, [LstDiscH], Semestre1_pre), % Adicionar disciplina a sub-lista 1
    sort(Semestre1_pre, Semestre1),
    append([Semestre1], [TempT], Semestres), !. % Obter a lista completa

organizaDisciplinas([LstDiscH|LstDiscT], Curso, Semestres) :-
    /* Caso 2: LstDiscH eh do semestre 2 */
    getSemester(LstDiscH, Curso, 2),
    organizaDisciplinas(LstDiscT, Curso, [TempH,TempT]),

    append(TempT, [LstDiscH], Semestre2_pre), % Adicionar disciplina a sub-lista 2
    sort(Semestre2_pre, Semestre2),
    append([TempH], [Semestre2], Semestres), !. % Obter a lista completa



% Predicado Auxiliar: eh verdade se Dur for a Duracao do evento de id ID
idToDuration(ID, Dur) :- horario(ID, _, _, _, Dur, _). 

% Predicado Auxiliar: eh verdade se S for a soma de X e Y
sum(X, Y, S) :- S is X + Y. 

filterIds(ID, P, Curso, A) :-
    /* 
        Predicado Auxiliar: eh verdade se um evento de id ID eh do curso Curso, ocorre
        no periodo P e no ano A
        Caso 1: Eventos do primeiro semestre
    */
    P \= p3, P \= p4, !,
    turno(ID, Curso, A, _),
    (horario(ID, _, _, _, _, P); horario(ID, _, _, _, _, p1_2)).

filterIds(ID, P, Curso, A) :-
    /* Caso 2: Eventos do segundo semestre */
    turno(ID, Curso, A, _),
    (horario(ID, _, _, _, _, P); horario(ID, _, _, _, _, p3_4)).

horasCurso(Periodo, Curso, Ano, TotalHours) :-
    /* 
        horasCurso eh verdade se TotalHoras for o numero de horas total dos eventos
        do curso Curso que occorrem no periodo Periodo e ano Ano
    */
    findall(ID, filterIds(ID, Periodo, Curso, Ano), ID_List_pre), % Lista de IDs filtrados
    sort(ID_List_pre, ID_List),
    maplist(idToDuration, ID_List, Dur_List), % transforma ID na Duracao correspondente
    foldl(sum, Dur_List, 0, TotalHours). % Soma todos os elementos da lista 


getEvolution(_, [], [], []) :- !. % Caso Terminal

getEvolution(Curso, [LstA_H|LstA_T], [LstP_H|LstP_T], Evolution) :-
    /* 
        Predicado Auxiliar: eh verdade se Evolution for a lista das horas totais
        dados a lista de anos ListA e lista de periodos ListP de um curso
        Curso
    */
    horasCurso(LstP_H, Curso, LstA_H, NumHoras),
    Info = [(LstA_H, LstP_H, NumHoras)], % Tuplo de informacao
    getEvolution(Curso, LstA_T, LstP_T, Temp),
    append(Temp, Info, Evolution).



evolucaoHorasCurso(Curso, Evolucao) :-
    /* 
        evolucaoHorasCurso eh verdade se Evolucao for a lista de tuplos
        (Ano, Periodo, NumHoras) e se NumHoras for as horas totais
        de o periodo Periodo do ano Ano do curso Curso
    */
    % Estas listas sao os pares Ano/Periodo utilizados no predicado auxiliar
    ListYears = [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3],
    ListPeriods = [p1, p2, p3, p4, p1, p2, p3, p4, p1, p2, p3, p4],

    getEvolution(Curso, ListYears, ListPeriods, Evolucao_pre),
    sort(Evolucao_pre, Evolucao).


% --------------------------------- OCUPACOES CRITICAS ----------------------------------


ocupaSlot(HiniDada, HfimDada, HiniEvt, HfimEvt, Horas) :-
    /* 
        ocupaSlot eh verdade se Horas for o num de horas sobrespostas entre
        o evento que vai de HiniEvt e acaba em HfinEvt e o slot que vai de HiniDada e
        acaba em HfinDada
        Caso 1: Evento totalmente contido no slot
    */
    (HiniDada =< HiniEvt), (HfimDada >= HiniEvt),
    (HiniDada =< HfimEvt), (HfimDada >= HfimEvt),
    Horas is HfimEvt - HiniEvt, !.

ocupaSlot(HiniDada, HfimDada, HiniEvt, HfimEvt, Horas) :-
    /* Caso 2: Slot totalmente contido no evento */
    (HiniDada >= HiniEvt), (HfimDada >= HiniEvt),
    (HiniDada =< HfimEvt), (HfimDada =< HfimEvt),
    Horas is HfimDada - HiniDada, !.

ocupaSlot(HiniDada, HfimDada, HiniEvt, HfimEvt, Horas) :-
    /* Caso 3: sobreposicao no inicio do evento */
    (HiniDada =< HiniEvt), (HfimDada >= HiniEvt),
    (HiniDada =< HfimEvt), (HfimDada =< HfimEvt),
    Horas is HfimDada - HiniEvt, !.

ocupaSlot(HiniDada, HfimDada, HiniEvt, HfimEvt, Horas) :-
    /* Caso 4: sobreposicao no fim do evento */
    (HiniDada >= HiniEvt), (HfimDada >= HiniEvt),
    (HiniDada =< HfimEvt), (HfimDada >= HfimEvt),
    Horas is HfimEvt - HiniDada, !.



getEventIds(Periodo, TipoSala, DiaSemana, Hini, Hfim, Duracao) :-
    /* 
        Predicado Auxiliar: eh verdade se Duracao for a duracao de um evento que
        aconteca numa sala do tipo TipoSala, durante Hini->Hfim no dia DiaSemana
        e no periodo Periodo
    */
    horario(Id, DiaSemana, Hini_, Hfim_, _, _),
    ocupaSlot(Hini_, Hfim_, Hini, Hfim, Duracao),
    evento(Id, _, _, _, Room),
    salas(TipoSala, Salas),
    memberchk(Room, Salas), % Ver se a sala do evento eh uma sala do tipo certo 
    isPeriod(Periodo, Id).


numHorasOcupadas(Periodo, TipoSala, DiaSemana, Hini, Hfim, SomaHoras) :-
    /* 
        numHorasOcupadas eh verdade se SomaHoras for a soma de horas ocupadas
        nas salas do tipo de sala TipoSala durante o tempo Hini->Hfim no dia
        DiaSemana e no periodo Periodo
    */
    findall(
        Duracao,
        getEventIds(Periodo, TipoSala, DiaSemana, Hini, Hfim, Duracao),
        DuracaoList
    ),

    foldl(sum, DuracaoList, 0, SomaHoras). % Somar todas as duracoes da lista



ocupacaoMax(TipoSala, Hini, Hfim, Max) :-
    /* 
        ocupacaoMax eh verdade se Max for o numero de horas possiveis de serem
        ocupadas por salas do tipo TipoSala durante Hini->Hfim
    */
    Delta is Hfim - Hini,
    salas(TipoSala, Salas),
    length(Salas, Len), % Obter o numero de elementos da lista Salas
    Max is Delta * Len.



percentagem(SomaHoras, Max, Percentagem) :-
    /*
        percentagem eh verdade se Percentagem for o quociente entre SomaHoras e Max
        multiplicado por 100
    */
    Percentagem is 100 * (SomaHoras / Max).



allDays(D) :-
    /* Predicado Auxiliar: eh verdade se D for um dia da semana valido */
    D = segunda-feira; D = terca-feira; D = quarta-feira;
    D = quinta-feira; D = sexta-feira.

allPeriods(P) :-
    /* Predicado Auxiliar: eh verdade se P for um periodo valido */
    P = p1; P = p2; P = p3; P = p4. 

ocupacaoCritica_Aux(Hini, Hfim, Thold, Result_Dia, Result_Sala, Result_Percent) :-
    /* 
        Predicado Auxiliar: eh verdade Result_percent for maior que o threshold Thold
        ocupacao de uma tal sala Result_Room e tal dia Result_Day durante Hini->Hfim
    */
    salas(Result_Sala, _),
    allDays(Result_Dia), allPeriods(AllPeriods),

    numHorasOcupadas(AllPeriods, Result_Sala, Result_Dia, Hini, Hfim, SumH),
    ocupacaoMax(Result_Sala, Hini, Hfim, Max),
    percentagem(SumH, Max, Result_Raw), Result_Raw > Thold,
    Result_Percent is ceiling(Result_Raw).

ocupacaoCritica(Hini, Hfim, Threshold, Resultados) :-
    /* 
        ocupacaoCritica eh verdade se Resultados for uma lista de tuplos de
        casosCriticos(DiaSemana, TipoSala, Percentagem)
        Onde DiaSemana eh um dia da semana, TipoSala um tipo de sala e Percentagem eh
        a percentagem de ocupacao do dado TipoSala e DiaSemana durante o intervalo
        Hini->Hfim
    */
    findall(
        casosCriticos(RDia,RRoom,RPercent),
        ocupacaoCritica_Aux(Hini, Hfim, Threshold, RDia, RRoom, RPercent),
        Resultados_pre
    ),
    sort(Resultados_pre, Resultados).


% ------------------------------------ OCUPACAO MESA ------------------------------------ 

cab1_(Name1, X4) :- X4 = Name1. % Predicado Auxiliar: Determina quem fica na cabeceira 1
cab2_(Name1, X5) :- X5 = Name1. % Predicado Auxiliar: Determina quem fica na cabeceira 2

honra_(Name1, Name2, X3, X4, X5, X6) :-
    /* Predicado Auxiliar: Determina quem fica ah direita da cabaceira */
    (cab1_(Name1, X4), X4 = Name1, X6 = Name2);
    (cab2_(Name1, X5), X5 = Name1, X3 = Name2).

lado_(Name1, Name2, X1, X2, X3, X6, X7, X8) :-
    /* Predicado Auxiliar: Determina quem fica lado a lado */
    (X1 = Name1, X2 = Name2); (X1 = Name2, X2 = Name1);
    (X2 = Name1, X3 = Name2); (X2 = Name2, X3 = Name1);
    (X6 = Name1, X7 = Name2); (X6 = Name2, X7 = Name1);
    (X7 = Name1, X8 = Name2); (X7 = Name2, X8 = Name1).

naoLado_(Name1, Name2, X1, X2, X3, X6, X7, X8) :-
    /* Predicado Auxiliar: Determina quem nao pode ficar lado a lado*/
    \+ lado_(Name1, Name2, X1, X2, X3, X6, X7, X8).

frente_(Name1, Name2, X1, X2, X3, X6, X7, X8) :-
    /* Predicado Auxiliar: Determina quem fica frente a frente */
    (X1 = Name1, X6 = Name2); (X1 = Name2, X6 = Name1);
    (X2 = Name1, X7 = Name2); (X2 = Name2, X7 = Name1);
    (X3 = Name1, X8 = Name2); (X3 = Name2, X8 = Name1).

naoFrente_(Name1, Name2, X1, X2, X3, X6, X7, X8) :-
    /* Predicado Auxiliar: Determina quem nao pode ficar frente a frente */
    \+ frente_(Name1, Name2, X1, X2, X3, X6, X7, X8).



getRestrictions([], _, _, _, _, _, _, _, _). % Caso Terminal

getRestrictions([RestHEAD|RestTAIL], X1, X2, X3, X4, X5, X6, X7, X8) :-
    /* 
        Predicado Auxiliar: Determina as restricoes impostas pela a lista [RestHEAD|RestTAIL]
    */
    ((RestHEAD = lado(Name1, Name2), lado_(Name1, Name2, X1, X2, X3, X6, X7, X8));
    (RestHEAD = naoLado(Name1, Name2), naoLado_(Name1, Name2, X1, X2, X3, X6, X7, X8));
    (RestHEAD = frente(Name1, Name2), frente_(Name1, Name2, X1, X2, X3, X6, X7, X8));
    (RestHEAD = naoFrente(Name1, Name2), naoFrente_(Name1, Name2, X1, X2, X3, X6, X7, X8));
    (RestHEAD = honra(Name1, Name2), honra_(Name1, Name2, X3, X4, X5, X6));
    (RestHEAD = cab1(Name1), cab1_(Name1, X4));
    (RestHEAD = cab2(Name2), cab2_(Name2, X5))),

    getRestrictions(RestTAIL, X1, X2, X3, X4, X5, X6, X7, X8).



ocupacaoMesa(ListaNomes, ListaRest, OcupMesa) :-
    /* 
        ocupacaoMesa eh verdade se OcupMesa for uma lista da forma
        [[X1, X2, X3], [X4, X5], [X6, X7, X8]] que determina a posicao dos
        nomes da lista ListaNomes sentadas ah mesa dada as restricoes impostas
        pela lista ListaRest
    */
    
    % Obter todas as permutacoes dos lugares   
    permutation(ListaNomes, [X1, X2, X3, X4, X5, X6, X7, X8]),
    getRestrictions(ListaRest, X1, X2, X3, X4, X5, X6, X7, X8), % Aplicar as restricoes

    OcupMesa = [[X1, X2, X3], [X4, X5], [X6, X7, X8]], !.  % Solucao