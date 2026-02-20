:- use_module(library(pce)).

start_loan_expert_system :-
    new(D, dialog('Smart Loan Assessment System')),
    send(D, background, colour(white)),

    % ──────────────── Client Information ────────────────
    send(D, append, label(title1, '--- Client Information ---')),

    send(D, append, new(Emp, menu('Employment Status:', cycle))),
    send_list(Emp, append, ['Employed', 'Unemployed']),
    send(Emp, selection, 'Employed'),

    send(D, append, new(Age, menu('Age Group:', cycle))),
    send_list(Age, append, ['Below 18', '18-65', 'Above 65']),
    send(Age, selection, '18-65'),

    send(D, append, new(CS, menu('Credit Score:', cycle))),
    send_list(CS, append, ['Below 600', '600-699', '700 and above']),
    send(CS, selection, '700 and above'),

    send(D, append, new(Salary, int_item('Monthly Income:'))),
    send(Salary, length, 12),
    send(Salary, reference, point(0,0)),

    send(D, append, new(Expenses, int_item('Monthly Expenses:'))),
    send(Expenses, length, 12),

    send(D, append, new(Debt, int_item('Existing Monthly Debt:'))),
    send(Debt, length, 12),

    send(D, append, new(ReqLoan, int_item('Requested Loan Amount:'))),
    send(ReqLoan, length, 12),

    send(D, append, new(Period, int_item('Loan Repayment Period (months):'))),
    send(Period, length, 12),

    send(D, append, label(spacer1, '')),

    % ──────────────── Buttons ────────────────
    send(D, append,
         button(evaluate,
                message(@prolog, evaluate_pressed,
                        Emp?selection, Age?selection, CS?selection,
                        Salary?selection, Expenses?selection, Debt?selection,
                        ReqLoan?selection, Period?selection,
                        D))),

    send(D, append,
         button('Clear / Next',
                message(@prolog, clear_pressed,
                        Emp, Age, CS, Salary, Expenses, Debt, ReqLoan, Period, D))),

    send(D, append, label(spacer2, '')),

    % ──────────────── Result Area ────────────────
    send(D, append, label(title2, '--- Assessment Result ---')),
    send(D, append, new(Result, editor)),
    send(Result, name, result_editor),
    send(Result, height, 10),
    send(Result, editable, @off),
    send(Result, background, colour(black)),
    send(Result, colour, colour(yellow)),

    send(D, open).


% ──────────────── Clear / Next Client ────────────────
clear_pressed(Emp, Age, CS, Salary, Expenses, Debt, ReqLoan, Period, D) :-
    send(Emp,      selection, 'Employed'),
    send(Age,      selection, '18-65'),
    send(CS,       selection, '700 and above'),
    send(Salary,   selection, 0),
    send(Expenses, selection, 0),
    send(Debt,     selection, 0),
    send(ReqLoan,  selection, 0),
    send(Period,   selection, 0),

    get(D, member, result_editor, Editor),
    send(Editor, clear).


% ──────────────── Evaluate button logic ────────────────
evaluate_pressed(EmpStatus, AgeGroup, CreditGroup, Salary, Expenses, Debt, ReqLoan, Period, D) :-

    % Basic input validation
    (   Salary =< 0
    ->  Msg = 'Error: Monthly Income must be greater than zero!'
    ;   ReqLoan =< 0
    ->  Msg = 'Error: Requested Loan Amount must be greater than zero!'
    ;   Period =< 0
    ->  Msg = 'Error: Loan Repayment Period must be greater than zero!'
    ;   fail
    ), !,
    show_result(D, Msg).

evaluate_pressed('Unemployed', _, _, _, _, _, _, _, D) :- !,
    show_result(D, 'Decision: Rejected\nReason: No stable income (Unemployed)').

evaluate_pressed('Employed', 'Below 18', _, _, _, _, _, _, D) :- !,
    show_result(D, 'Decision: Rejected\nReason: Age below legal lending age').

evaluate_pressed('Employed', 'Above 65', _, _, _, _, _, _, D) :- !,
    show_result(D, 'Decision: Rejected\nReason: Age above standard lending limit').

evaluate_pressed('Employed', '18-65', 'Below 600', _, _, _, _, _, D) :- !,
    show_result(D, 'Decision: Rejected\nReason: Poor credit score (< 600)').

evaluate_pressed('Employed', '18-65', '600-699', _, _, _, _, _, D) :- !,
    show_result(D, 'Decision: Further Review Required\nReason: Medium credit risk (600 - 699)').

% Main approval logic (for high credit score)
evaluate_pressed('Employed', '18-65', '700 and above', Salary, Expenses, Debt, ReqLoan, Period, D) :-

    % Simple monthly payment calculation (no interest for this example; in reality, use formula with rate)
    MonthlyPayment is ReqLoan / Period,

    % Total monthly obligations
    TotalOutgo is Expenses + Debt + MonthlyPayment,

    % Debt-to-Income Ratio (DTI) including all outgo
    DTI is (TotalOutgo / Salary) * 100,

    % Existing Debt Ratio
    ExistingDebtRatio is (Debt / Salary) * 100,

    % Loan-to-Income Ratio (total loan relative to annual income, for long-term check)
    AnnualIncome is Salary * 12,
    LTI is (ReqLoan / AnnualIncome) * 100,

    % Decision rules (based on common lending standards; adjust as needed)
    (   DTI > 50
    ->  Decision = 'Rejected - DTI > 50% (Unaffordable)'
    ;   DTI > 36
    ->  Decision = 'Conditionally Approved - High DTI (monitor or require collateral)'
    ;   ExistingDebtRatio > 20
    ->  Decision = 'Conditionally Approved - High existing debt burden'
    ;   LTI > 300  % e.g., loan > 3x annual income
    ->  Decision = 'Conditionally Approved - High Loan-to-Income ratio (reduce amount or extend period)'
    ;   Decision = 'Approved - Full Amount'
    ),

    format(atom(Text),
           'Debt-To-Income Ratio (DTI) ... ~2f %~nExisting Debt Ratio ..... ~2f %~nLoan-to-Income (LTI) .... ~2f %~nMonthly Loan Payment .... ~2f~n~nDecision:~n~w',
           [DTI, ExistingDebtRatio, LTI, MonthlyPayment, Decision]),

    show_result(D, Text).


% ──────────────── Helper ────────────────
show_result(Dialog, Text) :-
    get(Dialog, member, result_editor, Editor),
    send(Editor, clear),
    send(Editor, insert, Text),
    send(Editor, caret, 0).


% Quick start
:- start_loan_expert_system.