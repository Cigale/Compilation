#ifndef QUAD_H__
#define QUAD_H__

#include "tds.h"

enum quad_type {
	AFFEC = 0,
	AFFEC_UNARY_MINUS = 1,
	AFFEC_UNARY_NOT = 2,
	AFFEC_BINARY_PLUS = 3,
	AFFEC_BINARY_MINUS = 4,
	AFFEC_BINARY_MULT = 5,
	AFFEC_BINARY_DIV = 6,
	AFFEC_BINARY_OR = 7,
	AFFEC_BINARY_AND = 8,
	BRANCHMENT_UNCOND = 9,
	BRANCHMENT_COND_EQ = 10,
	BRANCHMENT_COND_NEQ = 11,
	BRANCHMENT_COND_LT = 12,
	BRANCHMENT_COND_LTEQ = 13,
	BRANCHMENT_COND_GT = 14,
	BRANCHMENT_COND_GTEQ = 15,
	PROC_PARAM = 16,
	PROC_CALL = 17,
	TAB_LEFT = 18,
	TAB_RIGHT = 19
};

typedef struct quad {
	char *label;
	struct symbol *operande1;
	struct symbol *operande2;
	struct symbol *res;
	int quad_type;
	struct quad *next;
	struct quad *last;
} quad;

struct type quad_res_type(const struct type *type1, const struct type *type2, enum quad_type type);
quad *quad_put(quad *t, struct symbol *op1, struct symbol *op2, struct symbol *res, enum quad_type type);
quad *quad_add(quad *t, quad *q);
quad *quad_concat(quad *q1, quad *q2);
quad *quad_take(quad **p);
void quad_clear(quad **t);
void quad_print(quad *t);
void quad_complete(quad *t, long value);
void mips_gen(quad **q, struct symbol *t);
void mips_vars(struct symbol* s, FILE* f);
void mips_write(quad* t, FILE *file);

#endif
