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

%type <data> Condition Expression

%left '+' '-' TK_TIMES TK_DIV
%right TK_LEFT
%nonassoc MOINSU

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
	TK_WHILE '{' '$' Condition '$' '}' '{' Code '}'
	;

Repeat:
	TK_REPEAT '{' '$' Condition '$' '}' '{' Code '}'
	;

If:
	TK_IF '{' '$' Condition '$' '}' '{' Code '}'
	;

Eif:
	TK_EIF '{' '$' Condition '$' '}' '{' Code '}' '{' Code '}'
	;

For:
	TK_FOR '{' Affectation TK_TO '$' Expression '$' '}' '{' Code '}'
	;

Mbox:
	TK_MBOX '{' TK_IDENT '(' '$' Expression '$' ')' '}'
	| '$' TK_MBOX '{' TK_IDENT '(' '$' Expression '$' ')' '}' '$'
	;

Condition
	: Expression TK_OR Condition {
		printf("Mem : %d\n", $3);
		printf("Mem.code : %d\n", $3.code);
		printf("Mem.addr : %d\n", $3.addr);
		printf("Mem.code->label : %s\n", $3.code->label);
		quad_complete($1.falselist, $3.code->label);
		$$.truelist = quad_concat($1.truelist, $3.truelist);
		$$.falselist = $3.falselist;
		$$.code = NULL;
		quad_add($$.code, $1.code);
		quad_add($$.code, $3.code);
	}
	| Expression TK_AND Condition {
		quad_complete($1.truelist, $3.code->label);
		$$.falselist = quad_concat($1.falselist, $3.falselist);
		$$.truelist = $3.truelist;
		$$.code = NULL;
		quad_add($$.code, $1.code);
		quad_add($$.code, $3.code);
	}
	| TK_NOT Condition {
		$$.code = $2.code;
		$$.truelist = $2.falselist;
		$$.falselist = $2.truelist;
	}
	| '(' Condition ')' {
		$$.code = $2.code;
		$$.truelist = $2.truelist;
		$$.falselist = $2.falselist;
	}
	| Expression {
		$$.code = NULL;
		tds* t = tds_put(&symbols, "", 1);
		t->value = "0";
		t->type = "int";
		tds* t2 = tds_put(&symbols, "", 1);
		t2->value = "GOTO ?";
		t2->type = "char*";
		quad_put($$.code, $1.addr, t, t2, "!=");
	}
	| Expression TK_BOOLOP Condition {
		$$.code = NULL;
		tds* t = tds_put(&symbols, "", 1);
		t->value = "GOTO ?";
		t->type = "char*";
		quad* q = quad_put($$.code, $1.addr, $3.addr, t, (char*) $2);
		$$.truelist = quad_add(NULL, q);
		tds* t2 = tds_put(&symbols, "", 1);
		t2->value = "GOTO ?";
		t2->type = "char*";
		quad* q2 = quad_put($$.code, NULL, NULL, t2, "");
		$$.falselist = quad_add(NULL, q2);
	}
	;

Expression:
	Expression '+' Expression {
		$$.addr = tds_put(&symbols, "", FALSE);
		$$.code = quad_put(NULL, $1.addr, $3.addr, $$.addr, "+");
	}
	| '-' Expression %prec MOINSU {
		$$.addr = tds_put(&symbols, "", FALSE);
		$$.code = quad_put(NULL, $2.addr, NULL, $$.addr, "-");
	}
	| Expression '-' Expression {
		$$.addr = tds_put(&symbols, "", FALSE);
		$$.code = quad_put(NULL, $1.addr, $3.addr, $$.addr, "-");
	}
	| Expression TK_TIMES Expression {
		$$.addr = tds_put(&symbols, "", FALSE);
		$$.code = quad_put(NULL, $1.addr, $3.addr, $$.addr, "*");
	}
	| Expression TK_DIV Expression {
		$$.addr = tds_put(&symbols, "", FALSE);
		$$.code = quad_put(NULL, $1.addr, $3.addr, $$.addr, "/");
	}
	| Mbox { // Fonction
	}
	| TK_IDENT {
		$$.addr = tds_lookup(&symbols, $1);
		$$.code = NULL;
	}
	| TK_IDENT TableValue {
		$$.addr = tds_lookup(&symbols, $1);
		$$.code = NULL;
	}
	| TK_NUMBER {
		$$.addr = tds_put(&symbols, "", TRUE);
		$$.addr->value = $1;
		$$.code = NULL;
	}
	| TK_FALSE {
		$$.addr = tds_put(&symbols, "", TRUE);
		$$.addr->value = "0";
		$$.code = quad_put(NULL, $$.addr, NULL, $$.addr, "!=");
		$$.falselist = NULL;
		$$.truelist = NULL;
	}
	| TK_TRUE {
		$$.addr = tds_put(&symbols, "", TRUE);
		$$.addr->value = "1";
		$$.code = quad_put(NULL, $$.addr, NULL, $$.addr, "==");
		$$.falselist = NULL;
		$$.truelist = NULL;
		printf("Mem : %d\n", $$);
		printf("Mem.code : %d\n", $$.code);
		printf("Mem.addr : %d\n", $$.addr);
		printf("Mem.code->label : %s\n", $$.code->label);
	}
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
