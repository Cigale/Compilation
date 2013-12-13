%{

#include <stdio.h>
#include <stdlib.h>
#include "tds.h"
#include "quad.h"
#include "constants.h"

FILE *yyin;

struct scope *cur_scope = NULL;
struct scope *last_scope = NULL;

int yyerror(char *s);

%}

%union {
	quad *algos;
	struct {
		struct scope *sc;
		quad *code;
	} algo;
	struct {
		quad *code;
		quad *truejump;
		quad *falsejump;
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
%token TK_BOOLINF TK_BOOLINFEQ TK_BOOLSUP TK_BOOLSUPEQ TK_BOOLEQ TK_BOOLNEQ
%token <scalar> TK_TYPE
%token <intval> TK_NUMBER
%token <id> TK_IDENT

%type <algos> Algos
%type <algo> Algo
%type <code_fragment> Code Instruction
%type <code_fragment> Affectation While Repeat If Eif For Mbox
%type <code_fragment> Expression ExpressionOr ExpressionAnd ExpressionRel
%type <code_fragment> ExpressionAdd ExpressionMult ExpressionUnary
%type <scope> Declarations Declarations_List
%type <symbol> Parameter ExpressionPrimary
%type <type> Type

%start AllAlgos

%%

AllAlgos:
	Algos {
		printf("\nImpression des différents quads générés :\n");
		quad_print($1);
		printf("\nGénération de code...");
		mips_gen($1, get_all_symbols());
		printf("Done.\n");
	}
	;

Algos:
	Algos Algo {
		$$ = quad_concat($1, $2.code);
		cur_scope = NULL;
		/* TODO libérer les scopes et les quad */
	}
	| {
		$$ = NULL;
	}
	;

Algo:
	Const Input Output Global Local Blankline Code {
		$$.code = $7.code;
		$$.sc = cur_scope;

		/* Damn people ending their code with a loop / if */
		if ($7.truejump != NULL || $7.falsejump != NULL) {
			struct symbol *sym;
			$$.code = quad_put($$.code, NULL, NULL, NULL, NOP);

			sym = quad_get_label(quad_last($7.code));

			if ($7.truejump != NULL)
				$7.truejump->res = sym;

			if ($7.falsejump != NULL)
				$7.falsejump->res = sym;
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
	Code Instruction {
		$$.code = quad_concat($1.code, $2.code);
		/* If a jump is still in-flight, make it land ASAP!
		 * It's probably an end of If or end of loop that needs the
		 * next statement to land on.
		 */
		if ($1.truejump != NULL || $1.falsejump != NULL) {
			struct symbol *sym = quad_get_label(quad_last($2.code));

			if ($1.truejump != NULL)
				$1.truejump->res = sym;

			if ($1.falsejump != NULL)
				$1.falsejump->res = sym;
		}

		$$.truejump = $2.truejump;
		$$.falsejump = $2.falsejump;
	}
	| {
		$$.code = NULL;
	}
	;

Instruction:
	Affectation TK_ENDINST {
		printf("Affectation found\n");
		$$ = $1;
	}
	| While {
		printf("While found\n");
		$$ = $1;
	}
	| Repeat {
		printf("Repeat found\n");
		$$ = $1;
	}
	| If {
		printf("If found\n");
		$$ = $1;
	}
	| Eif {
		printf("eIf found\n");
		$$ = $1;
	}
	| For {
		printf("For found\n");
		$$ = $1;
	}
	| Mbox TK_ENDINST {
		printf("Mbox found\n");
		$$ = $1;
	}
	;

Affectation:
	'$' TK_IDENT TableValue TK_LEFT Expression '$' {
		/* TODO */
		$$ = $5;
	}
	| '$' TK_IDENT TK_LEFT Expression '$' {
		struct symbol *sym = scope_lookup(cur_scope, $2);

		if ($4.truejump == NULL && $4.falsejump == NULL) {
			/* Normal assignment (Integer, Real) */
			struct quad *ql = quad_last($4.code);
			struct type t = quad_res_type(&ql->res->type, NULL, AFFEC);
			if (!same_type(t, sym->type)) {
				fprintf(stderr, "Can't assign a variable with a different type\n");
				exit(EXIT_FAILURE);
			}
			$$.code = quad_put($4.code, ql->res, NULL, sym, AFFEC);
		} else {
			/*
			 * Boolean assignment.
			 * There should always be a truejump AND a falsejump as
			 * it is implemented like :
			 * if (cond) a = 1 else a = 0
			 */
			struct symbol *symtrue, *symfalse;
			struct type t;
			t.is_scalar = TRUE;
			t.stype = STYPE_BOOL;
			t.size = 0;

			symtrue = symbol_create(NULL, t, TRUE, TRUE);
			symfalse = symbol_create(NULL, t, TRUE, FALSE);

			/* If cond is true, we'll jump on the assigment to 1 */
			$$.code = quad_put($4.code, symtrue, NULL, sym, AFFEC);
			$4.truejump->res = quad_get_label(quad_last($$.code));

			/* Don't execute the second assigment below. We need to
			 * jump to the instruction just below the end of the
			 * if. */
			$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
			$$.truejump = quad_last($$.code);
			$$.falsejump = quad_last($$.code);

			/* If cond is false, we'll jump on the assigment to 0 */
			$$.code = quad_put($$.code, symfalse, NULL, sym, AFFEC);
			$4.falsejump->res = quad_get_label(quad_last($$.code));
		}
	}
	;

While:
	TK_WHILE '{' '$' Expression '$' '}' '{' Code '}' {
		/* TODO */
		$$ = $8;
	}
	;

Repeat:
	TK_REPEAT '{' '$' Expression '$' '}' '{' Code '}' {
		/* TODO */
		$$ = $8;
	}
	;

If:
	TK_IF '{' '$' Expression '$' '}' '{' Code '}' {
		if ($4.truejump != NULL) {
			struct symbol *sym = quad_get_label($8.code);
			$4.truejump->res = sym;
		}
		$$.code = quad_concat($4.code, $8.code);
		$$.truejump = NULL;
		$$.falsejump = $4.falsejump;
	}
	;

Eif:
	TK_EIF '{' '$' Expression '$' '}' '{' Code '}' '{' Code '}' {
		/* TODO */
		$$ = $8;
	}
	;

For:
	TK_FOR '{' Affectation TK_TO '$' Expression '$' '}' '{' Code '}' {
		/* TODO */
		$$ = $6;
	}
	;

Mbox:
	TK_MBOX '{' TK_IDENT '(' '$' Expression '$' ')' '}' {
		/* TODO */
		$$ = $6;
	}
	| '$' TK_MBOX '{' TK_IDENT '(' '$' Expression '$' ')' '}' '$' {
		/* TODO */
		$$ = $7;
	}
	;

Expression:
	ExpressionOr {
		$$ = $1;
	}
	;

ExpressionOr:
	ExpressionOr TK_OR ExpressionAnd {
		struct symbol *sym;
		$$.code = quad_concat($1.code, $3.code);

		if ($1.falsejump != NULL) {
			/* Left expression can be false? Go check the right part! */
			sym = quad_get_label(quad_last($3.code));
			$1.falsejump->res = sym;
		}

		/*
		 * Left expression can be true? Go to the same point as if the
		 * right expression is true so that we always only have one
		 * JUMP to fix.
		 */
		if ($1.truejump != NULL && $3.truejump != NULL) {
			$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
			$$.truejump = quad_last($$.code);

			sym = quad_get_label(quad_last($$.code));
			$1.truejump->res = sym;
			$3.truejump->res = sym;

		} else if ($1.truejump != NULL) {
			$$.truejump = $1.truejump;

		} else if ($3.truejump != NULL) {
			$$.truejump = $3.truejump;
		}

		/*
		 * A lazy-evaluated OR may be false only if the right hand side
		 * is false.
		 */
		$$.falsejump = $3.falsejump;
	}
	| ExpressionAnd {
		$$ = $1;
	}
	;

ExpressionAnd:
	ExpressionAnd TK_AND ExpressionRel {
		struct symbol *sym;
		$$.code = quad_concat($1.code, $3.code);

		if ($1.truejump != NULL) {
			/* Left expression is true? Go check the right part! */
			sym = quad_get_label(quad_last($3.code));
			$1.truejump->res = sym;
		}

		/*
		 * Left expression is false? Go to the same point as if the
		 * right expression is false so that we always only have one
		 * JUMP to fix.
		 */
		if ($1.falsejump != NULL && $3.truejump != NULL) {
			$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
			$$.falsejump = quad_last($$.code);

			sym = quad_get_label(quad_last($$.code));
			$1.falsejump->res = sym;
			$3.falsejump->res = sym;

		} else if ($1.falsejump != NULL) {
			$$.falsejump = $1.falsejump;

		} else if ($3.falsejump != NULL) {
			$$.falsejump = $3.falsejump;
		}

		/*
		 * A lazy-evaluated AND may be true only if the right hand side
		 * is true.
		 */
		$$.truejump = $3.truejump;
	}
	| ExpressionRel {
		$$ = $1;
	}
	;

ExpressionRel:
	ExpressionAdd TK_BOOLINF ExpressionAdd {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		if (!same_type(ql1->res->type, ql2->res->type)) {
			fprintf(stderr, "Can't compare two different types\n");
			exit(EXIT_FAILURE);
		}
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, NULL, BRANCHMENT_COND_LT);
		$$.truejump = quad_last($$.code);
		$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
		$$.falsejump = quad_last($$.code);
	}
	| ExpressionAdd TK_BOOLINFEQ ExpressionAdd {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		if (!same_type(ql1->res->type, ql2->res->type)) {
			fprintf(stderr, "Can't compare two different types\n");
			exit(EXIT_FAILURE);
		}
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, NULL, BRANCHMENT_COND_LTEQ);
		$$.truejump = quad_last($$.code);
		$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
		$$.falsejump = quad_last($$.code);
	}
	| ExpressionAdd TK_BOOLSUP ExpressionAdd {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		if (!same_type(ql1->res->type, ql2->res->type)) {
			fprintf(stderr, "Can't compare two different types\n");
			exit(EXIT_FAILURE);
		}
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, NULL, BRANCHMENT_COND_GT);
		$$.truejump = quad_last($$.code);
		$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
		$$.falsejump = quad_last($$.code);
	}
	| ExpressionAdd TK_BOOLSUPEQ ExpressionAdd {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		if (!same_type(ql1->res->type, ql2->res->type)) {
			fprintf(stderr, "Can't compare two different types\n");
			exit(EXIT_FAILURE);
		}
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, NULL, BRANCHMENT_COND_GTEQ);
		$$.truejump = quad_last($$.code);
		$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
		$$.falsejump = quad_last($$.code);
	}
	| ExpressionAdd TK_BOOLEQ ExpressionAdd {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		if (!same_type(ql1->res->type, ql2->res->type)) {
			fprintf(stderr, "Can't compare two different types\n");
			exit(EXIT_FAILURE);
		}
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, NULL, BRANCHMENT_COND_EQ);
		$$.truejump = quad_last($$.code);
		$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
		$$.falsejump = quad_last($$.code);
	}
	| ExpressionAdd TK_BOOLNEQ ExpressionAdd {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		if (!same_type(ql1->res->type, ql2->res->type)) {
			fprintf(stderr, "Can't compare two different types\n");
			exit(EXIT_FAILURE);
		}
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, NULL, BRANCHMENT_COND_NEQ);
		$$.truejump = quad_last($$.code);
		$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
		$$.falsejump = quad_last($$.code);
	}
	| ExpressionAdd {
		$$ = $1;
	}
	;

ExpressionAdd:
	ExpressionAdd '+' ExpressionMult {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		struct type t = quad_res_type(&ql1->res->type, &ql2->res->type, AFFEC_BINARY_PLUS);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, sym, AFFEC_BINARY_PLUS);
	}
	| ExpressionAdd '-' ExpressionMult {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		struct type t = quad_res_type(&ql1->res->type, &ql2->res->type, AFFEC_BINARY_MINUS);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, sym, AFFEC_BINARY_MINUS);
	}
	| ExpressionMult {
		$$ = $1;
	}
	;

ExpressionMult:
	ExpressionMult TK_TIMES ExpressionUnary {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		struct type t = quad_res_type(&ql1->res->type, &ql2->res->type, AFFEC_BINARY_MULT);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, sym, AFFEC_BINARY_MULT);
	}
	| ExpressionMult TK_DIV ExpressionUnary {
		struct quad *ql1 = quad_last($1.code);
		struct quad *ql2 = quad_last($3.code);
		struct type t = quad_res_type(&ql1->res->type, &ql2->res->type, AFFEC_BINARY_DIV);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_concat($1.code, $3.code);
		$$.code = quad_put($$.code, ql1->res, ql2->res, sym, AFFEC_BINARY_DIV);
	}
	| ExpressionUnary {
		$$ = $1;
	}
	;

ExpressionUnary:
	TK_NOT ExpressionUnary {
		struct quad *ql = quad_last($2.code);
		struct type t = quad_res_type(&ql->res->type, NULL, AFFEC_UNARY_NOT);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_put($2.code, ql->res, NULL, sym, AFFEC_UNARY_NOT);
	}
	| '-' ExpressionUnary {
		struct quad *ql = quad_last($2.code);
		struct type t = quad_res_type(&ql->res->type, NULL, AFFEC_UNARY_MINUS);
		struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
		$$.code = quad_put($2.code, ql->res, NULL, sym, AFFEC_UNARY_MINUS);
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
		if ($1->type.is_scalar && $1->type.stype == STYPE_BOOL) {
			/* With bools, we branch */
			struct symbol *symtrue = symbol_create(NULL, $1->type, TRUE, TRUE);
			$$.code = quad_put(NULL, $1, symtrue, NULL, BRANCHMENT_COND_EQ);
			$$.truejump = quad_last($$.code);
			$$.code = quad_put($$.code, NULL, NULL, NULL, BRANCHMENT_UNCOND);
			$$.falsejump = quad_last($$.code);
		} else {
			/* With other values, we just assign a symbol */
			struct type t = quad_res_type(&$1->type, NULL, AFFEC);
			struct symbol *sym = symbol_create(NULL, t, FALSE, 0);
			$$.code = quad_put(NULL, $1, NULL, sym, AFFEC);
			$$.truejump = NULL;
			$$.falsejump = NULL;
		}
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
		$$ = symbol_create(NULL, t, TRUE, FALSE);
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
