%{

#include <stdio.h>
#include "tds.h"
#include "quad.h"
#include "constants.h"

FILE* yyin;
tds* symbols;

int yyerror(char *s);

%}

%union {
	struct data {
		tds* addr;
		quad* code;
		quad* truelist;
		quad* falselist;
	} data;
	char* id;
}

%token <data> TK_CONST TK_INPUT TK_OUTPUT TK_GLOBAL TK_LOCAL TK_BLK
%token <data> TK_ENDINST TK_LEFT TK_FOR TK_WHILE TK_IF TK_EIF TK_REPEAT
%token <data> TK_EMPTY TK_IN TK_TYPE TK_TO TK_MBOX
%token <data> TK_BOOLVAL TK_TIMES TK_DIV TK_FALSE TK_TRUE TK_NOT TK_AND TK_OR
%token <id> TK_BOOLOP TK_NUMBER TK_IDENT

/*%type <data> Expression*/

%left '+' '-' TK_TIMES TK_DIV
%right TK_LEFT

%start Algos

%%

Algos:
	Algos Algo
	| {printf("Done\n");}
	;

Algo:
	Const Input Output Global Local Blankline Code
	;

Const:
	TK_CONST '{' '$' Declarations '$' '}' {printf("Constant found\n");}
	| {printf("No Constant found\n");}
	;

Input:
	TK_INPUT '{' '$' Declarations '$' '}' {printf("Input found\n");}
	;

Output:
	TK_OUTPUT '{' '$' Declarations '$' '}' {printf("Output found\n");}
	;

Global:
	TK_GLOBAL '{' '$' Declarations '$' '}' {printf("Global found\n");}
	;

Local:
	TK_LOCAL '{' '$' Declarations '$' '}' {printf("Local found\n");}
	;

Blankline:
	TK_BLK {printf("Blankline found\n");}
	;

Declarations:
	TK_EMPTY
	| Declarations_List
	;

Declarations_List:
	Declarations_List ',' Parameter
	| Parameter
	;

Parameter:
	TK_IDENT TK_IN TK_TYPE Table
	;

Table:
	'^' '{' TK_NUMBER '}'
	|
	;

TableValue:
	'_' '{' TK_NUMBER '}'
	| '_' '{' TK_IDENT '}'
	;

Code:
	Code Instruction
	|
	;

Instruction:
	Affectation TK_ENDINST {printf("Affectation found\n");}
	| While {printf("While found\n");}
	| Repeat {printf("Repeat found\n");}
	| If {printf("If found\n");}
	| Eif {printf("eIf found\n");}
	| For {printf("For found\n");}
	| Mbox TK_ENDINST {printf("Mbox found\n");}
	;

Affectation:
	'$' TK_IDENT TableValue TK_LEFT Expression '$'
	| '$' TK_IDENT TK_LEFT Expression '$'
	;

While:
	TK_WHILE '{' '$' Expression '$' '}' '{' Code '}'
	;

Repeat:
	TK_REPEAT '{' '$' Expression '$' '}' '{' Code '}'
	;

If:
	TK_IF '{' '$' Expression '$' '}' '{' Code '}'
	;

Eif:
	TK_EIF '{' '$' Expression '$' '}' '{' Code '}' '{' Code '}'
	;

For:
	TK_FOR '{' Affectation TK_TO '$' Expression '$' '}' '{' Code '}'
	;

Mbox:
	TK_MBOX '{' TK_IDENT '(' '$' Expression '$' ')' '}'
	| '$' TK_MBOX '{' TK_IDENT '(' '$' Expression '$' ')' '}' '$'
	;

Expression:
	ExpressionOr
	;

ExpressionOr:
	ExpressionOr TK_OR ExpressionAnd
	| ExpressionAnd
	;

ExpressionAnd:
	ExpressionAnd TK_AND ExpressionRel
	| ExpressionRel
	;

ExpressionRel:
	ExpressionAdd TK_BOOLOP ExpressionAdd
	| ExpressionAdd
	;

ExpressionAdd:
	ExpressionAdd '+' ExpressionMult
	| ExpressionAdd '-' ExpressionMult
	| ExpressionMult
	;

ExpressionMult:
	ExpressionMult TK_TIMES ExpressionUnary
	| ExpressionMult TK_DIV ExpressionUnary
	| ExpressionUnary
	;

ExpressionUnary:
	TK_NOT ExpressionUnary
	| '-' ExpressionUnary
	| ExpressionPrimary
	;

ExpressionPrimary:
	TK_NUMBER
	| TK_IDENT
	| TK_IDENT TableValue
	| TK_TRUE
	| TK_FALSE
	| Mbox
	| '(' Expression ')'
	;

%%

int yyerror(char *s) {
	printf("Grammar nazi says: %s\n", s);
	return 1;
}

int main(int argc, char **argv) {
	if (argc > 1)
		yyin = fopen(argv[1], "r");
	else
		yyin = stdin;

	return yyparse();
}
