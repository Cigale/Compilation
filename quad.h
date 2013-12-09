#ifndef QUAD_H__
#define QUAD_H__

#include "tds.h"

enum quad_type {
	AFFEC,
	AFFEC_UNARY_MINUS,
	AFFEC_UNARY_NOT,
	AFFEC_BINARY_PLUS,
	AFFEC_BINARY_MINUS,
	AFFEC_BINARY_MULT,
	AFFEC_BINARY_DIV,
	AFFEC_BINARY_OR,
	AFFEC_BINARY_AND,
	BRANCHMENT_UNCOND,
	BRANCHMENT_COND_EQ,
	BRANCHMENT_COND_NEQ,
	BRANCHMENT_COND_LT,
	BRANCHMENT_COND_LTEQ,
	BRANCHMENT_COND_GT,
	BRANCHMENT_COND_GTEQ,
	PROC_PARAM,
	PROC_CALL,
	TAB_LEFT,
	TAB_RIGHT
};

typedef struct quad {
	char *label;
	struct symbol *operande1;
	struct symbol *operande2;
	struct symbol *res;
	char *operateur;
	int quad_type;
	struct quad *next;
	struct quad *last;
} quad;

quad *quad_put(quad *t, struct symbol *op1, struct symbol *op2, struct symbol *res, char *op);
quad *quad_add(quad *t, quad *q);
quad *quad_concat(quad *q1, quad *q2);
quad *quad_take(quad **p);
void quad_clear(quad **t);
void quad_print(quad *t);
void quad_complete(quad *t, long value);
void mips_gen(quad **q, struct symbol *t);
void mips_write(quad* t, FILE *file);

#endif
