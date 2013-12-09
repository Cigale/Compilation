#ifndef QUAD_H__
#define QUAD_H__

#include "tds.h"

#define AFFEC                   1
#define AFFEC_UNARY_MINUS       2
#define AFFEC_UNARY_NOT         3
#define AFFEC_BINARY_PLUS       4
#define AFFEC_BINARY_MINUS      5
#define AFFEC_BINARY_MULT       6
#define AFFEC_BINARY_DIV        7

#define BRANCHMENT_UNCOND       8
#define BRANCHMENT_COND         9

#define PROC_PARAM              10
#define PROC_CALL               11

#define TAB_LEFT                12
#define TAB_RIGHT               13

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
void quad_complete(quad *t, char *value);
void mips_gen(quad **q);
void mips_write(quad* t, FILE *file);

#endif
