%{

#include <stdio.h>
#include <stdlib.h>
#include "tds.h"
#include "quad.h"
#include "constants.h"

FILE *yyin;

struct scope *cur_scope = NULL;

int yyerror(char *s);

%}

%union {
	struct code_fragment {
		struct scope *sc;
		quad* code;
		quad* truelist;
		quad* falselist;
	} code_fragment;
	struct scope *scope;
	struct symbol *symbol;
	struct type type;
	enum scope_type scope_type;
	enum scalar scalar;
	char* id;
	int intval;
}

%token <scope_type> TK_CONST TK_INPUT TK_OUTPUT TK_GLOBAL TK_LOCAL
%token TK_BLK TK_ENDINST TK_LEFT TK_FOR TK_WHILE TK_IF TK_EIF TK_REPEAT
%token TK_EMPTY TK_IN TK_TO TK_MBOX
%token TK_BOOLVAL TK_TIMES TK_DIV TK_FALSE TK_TRUE TK_NOT TK_AND TK_OR
%token TK_BOOLOP
%token <scalar> TK_TYPE
%token <intval> TK_NUMBER
%token <id> TK_IDENT

%type <code_fragment> Affectation
%type <code_fragment> Expression ExpressionOr ExpressionAnd ExpressionRel
%type <code_fragment> ExpressionAdd ExpressionMult ExpressionUnary
%type <scope> Declarations Declarations_List
%type <symbol> Parameter ExpressionPrimary
%type <type> Type
/*%type <data> Expression*/

%start Algos

%%

Algos:
	Algos Algo
	| {printf("Done\n");}
	;

Algo:
	Const Input Output Global Local Blankline Code {
		/* TODO: Faire un truc plus intelligent pour garder les globales */
		while (cur_scope != NULL) {
			struct scope *sc = cur_scope->parent;
			scope_free(cur_scope);
			cur_scope = sc;
		}
	}
	;

Const:
	TK_CONST {
		cur_scope = scope_create(cur_scope);
	}
		'{' '$' Declarations '$' '}' {printf("Constant found\n");}
	| {printf("No Constant found\n");}
	;

Input:
	TK_INPUT {
		cur_scope = scope_create(cur_scope);
	}
		'{' '$' Declarations '$' '}' {printf("Input found\n");}
	;

Output:
	TK_OUTPUT {
		cur_scope = scope_create(cur_scope);
	}
		'{' '$' Declarations '$' '}' {printf("Output found\n");}
	;

Global:
	TK_GLOBAL {
		cur_scope = scope_create(cur_scope);
	}
		'{' '$' Declarations '$' '}' {printf("Global found\n");}
	;

Local:
	TK_LOCAL {
		cur_scope = scope_create(cur_scope);
	}
		'{' '$' Declarations '$' '}' {printf("Local found\n");}
	;

Blankline:
	TK_BLK {printf("Blankline found\n");}
	;

Declarations:
	TK_EMPTY {
		$$ = cur_scope;
	}
	| Declarations_List {
		$$ = $1;
	}
	;

Declarations_List:
	Declarations_List ',' Parameter {
		$$ = scope_add_symbol($1, $3);
	}
	| Parameter {
		$$ = scope_add_symbol(cur_scope, $1);
	}
	;

Parameter:
	TK_IDENT TK_IN Type {$$ = symbol_create($1, $3, FALSE, 0);}
	;

Type:
	TK_TYPE {
		$$.is_scalar = TRUE;
		$$.stype = $1;
	}
	| TK_TYPE '^' '{' TK_NUMBER '}' {
		$$.is_scalar = FALSE;
		$$.stype = $1;
		$$.size = $4;
	}
	;

TableValue:
	'_' '{' Expression '}'
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
	'$' TK_IDENT TableValue TK_LEFT Expression '$' {
		/* TODO */
		$$ = $5;
	}
	| '$' TK_IDENT TK_LEFT Expression '$' {
		struct type t = quad_res_type(&$4.code->res->type, NULL, AFFEC);
		struct symbol *sym = scope_lookup(cur_scope, $2);
		if (!same_type(t, sym->type)) {
			fprintf(stderr, "Can't assign a variable with a different type\n");
			exit(EXIT_FAILURE);
		}
		$$.code = quad_put($4.code, $4.code->res, NULL, sym, AFFEC);
	}
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
	ExpressionOr {
		$$ = $1;
	}
	;

ExpressionOr:
	ExpressionOr TK_OR ExpressionAnd {
		/* TODO */
	}
	| ExpressionAnd {
		$$ = $1;
	}
	;

ExpressionAnd:
	ExpressionAnd TK_AND ExpressionRel {
		/* TODO */
	}
	| ExpressionRel {
		$$ = $1;
	}
	;

ExpressionRel:
	ExpressionAdd TK_BOOLOP ExpressionAdd {
		/* TODO */
	}
	| ExpressionAdd {
		$$ = $1;
	}
	;

ExpressionAdd:
	ExpressionAdd '+' ExpressionMult {
		struct type t = quad_res_type(&$1.code->res->type, &$3.code->res->type, AFFEC_BINARY_PLUS);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, $1.code->res, $3.code->res, sym, AFFEC_BINARY_PLUS);
	}
	| ExpressionAdd '-' ExpressionMult {
		struct type t = quad_res_type(&$1.code->res->type, &$3.code->res->type, AFFEC_BINARY_MINUS);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, $1.code->res, $3.code->res, sym, AFFEC_BINARY_MINUS);
	}
	| ExpressionMult {
		$$ = $1;
	}
	;

ExpressionMult:
	ExpressionMult TK_TIMES ExpressionUnary {
		struct type t = quad_res_type(&$1.code->res->type, &$3.code->res->type, AFFEC_BINARY_MULT);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, $1.code->res, $3.code->res, sym, AFFEC_BINARY_MULT);
	}
	| ExpressionMult TK_DIV ExpressionUnary {
		struct type t = quad_res_type(&$1.code->res->type, &$3.code->res->type, AFFEC_BINARY_DIV);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, $1.code->res, $3.code->res, sym, AFFEC_BINARY_DIV);
	}
	| ExpressionUnary {
		$$ = $1;
	}
	;

ExpressionUnary:
	TK_NOT ExpressionUnary {
		struct type t = quad_res_type(&$2.code->res->type, NULL, AFFEC_UNARY_NOT);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_put($2.code, $2.code->res, NULL, sym, AFFEC_UNARY_NOT);
	}
	| '-' ExpressionUnary {
		struct type t = quad_res_type(&$2.code->res->type, NULL, AFFEC_UNARY_MINUS);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_put($2.code, $2.code->res, NULL, sym, AFFEC_UNARY_MINUS);
	}
	| '(' Expression ')' {
		$$ = $2;
	}
	| Mbox {
		/* TODO replace that dummy code */
		printf("Unsupported Mbox\n");
		struct type t;
		struct symbol *sym;
		t.is_scalar = TRUE;
		t.stype = STYPE_INT;
		t.size = 0;
		sym = symbol_create(NULL, t, TRUE, 0);
		$$.code = quad_put(NULL, sym, NULL, sym, AFFEC);
	}
	| TK_IDENT TableValue {
		/* TODO replace that dummy code */
		printf("Unsupported TableValue\n");
		struct type t;
		struct symbol *sym;
		t.is_scalar = TRUE;
		t.stype = STYPE_INT;
		t.size = 0;
		sym = symbol_create(NULL, t, TRUE, 0);
		$$.code = quad_put(NULL, sym, NULL, sym, AFFEC);
	}
	| ExpressionPrimary {
		struct type t = quad_res_type(&$1->type, NULL, AFFEC);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_put(NULL, $1, NULL, sym, AFFEC);
	}
	;

ExpressionPrimary:
	TK_NUMBER {
		struct type t;
		t.is_scalar = TRUE;
		t.stype = STYPE_INT;
		t.size = 0;
		$$ = symbol_create(NULL, t, TRUE, $1);
	}
	| TK_IDENT {
		$$ = scope_lookup(cur_scope, $1);
		if ($$ == NULL) {
			fprintf(stderr, "Symbol %s undefined\n", $1);
			exit(EXIT_FAILURE);
		}
	}
	| TK_TRUE {
		struct type t;
		t.is_scalar = TRUE;
		t.stype = STYPE_BOOL;
		t.size = 0;
		$$ = symbol_create(NULL, t, TRUE, TRUE);
	}
	| TK_FALSE {
		struct type t;
		t.is_scalar = TRUE;
		t.stype = STYPE_BOOL;
		t.size = 0;
		$$ = symbol_create(NULL, t, TRUE, TRUE);
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
