#ifndef QUAD_H__
#define QUAD_H__

#include "tds.h"

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
