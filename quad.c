#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tds.h"
#include "quad.h"
#include "constants.h"

int next_label_id = 0;

struct type quad_res_type(const struct type *type1, const struct type *type2, enum quad_type type) {
	switch (type) {
		/* Unary operators */
		case AFFEC:
		case AFFEC_UNARY_MINUS:
		case AFFEC_UNARY_NOT:
			return *type1;

		/* Binary operators */
		case AFFEC_BINARY_PLUS:
		case AFFEC_BINARY_MINUS:
		case AFFEC_BINARY_MULT:
		case AFFEC_BINARY_DIV:
		case AFFEC_BINARY_OR:
		case AFFEC_BINARY_AND:
			/*
			 * No automatic type converstion
			 * both must be the same type
			 */

			if (!same_type(*type1, *type2)) {
				fprintf(stderr, "Can't apply an operator between two distinct types\n");
				exit(EXIT_FAILURE);
			}

			return *type1;

		default:
			fprintf(stderr, "No result type for this kind of quad\n");
			exit(EXIT_FAILURE);
	}
}


quad* quad_put(quad *t, struct symbol *op1, struct symbol *op2, struct symbol *res, enum quad_type type) {

	quad *element = malloc(sizeof(quad));
	if(!element) exit(-1);

	element->operande1 = op1;
	element->operande2 = op2;
	element->res = res;
	element->quad_type = type;
	element->label = NULL;

	if(!t) {
		t = element;
		element->next = NULL;
	} else {
		t->last->next = element;
		element->next = NULL;
	}
	t->last = element;

	return t;
}

quad* quad_add(quad *t, quad* q) {

	if(!t) {
		t = q;
		q->next = NULL;
	} else {
		t->last->next = q;
		q->next = t;
	}
	t->last = q;

	return t;
}

quad* quad_concat(quad* q1, quad* q2) {
	if (q1 == NULL)
		return q2;

	q1->last->next = q2;

	if (q2 != NULL)
		q1->last = q2->last;

	return q1;
}

quad *quad_last(quad *q) {
	return q->last;
}

struct symbol *quad_get_label(quad *q) {
	char *labelname;
	struct symbol *sym;
	struct type t;

	if (q->label != NULL)
		return q->label;

	labelname = malloc(16 * sizeof(char));
	if (!labelname) {
		perror("malloc");
		exit(EXIT_FAILURE);
	}

	snprintf(labelname, 14 * sizeof(char), "label_%d", next_label_id);
	next_label_id++;

	t.is_scalar = TRUE;
	t.stype = STYPE_ADDR;
	t.size = 0;

	sym = symbol_create(labelname, t, FALSE, 0);

	q->label = sym;

	return q->label;
}

void quad_clear(quad **t) {
	quad *tmp;
	while(*t) {
		tmp = (*t)->next;
		free(*t);
		*t = tmp;
	}
}

void quad_print(quad *t) {
	while(t) {
		printf("Label : OP %d\t",t->quad_type);

		if(t->operande1 != NULL) {
			printf("OPERANDE %s\t", t->operande1->id);
		} else {
			printf("OPERANDE \t");
		}
		if(t->operande2 != NULL) {
			printf("OPERANDE %s\t", t->operande2->id);
		} else {
			printf("OPERANDE \t");
		}
		if(t->res != NULL) {
			printf("RES %s\t", t->res->id);
		} else {
			printf("RES \t");
		}

		printf("\n");

		t = t->next;
	}

	printf("\n");
}

void quad_complete(quad *t, long value) {
	t->res->value = value;
}

void mips_gen(quad *q, struct symbol* s) {
	FILE* file = NULL;

	file = fopen("res.s", "w");

	if (file == NULL) {
		perror("res.s");
		exit(EXIT_FAILURE);
	}

	mips_vars(s, file);
	fprintf(file, "\n\t.text\nmain:\n");

	while(q) {
		quad *tmp;
		mips_write(q, file);
		tmp = q;
		q = q->next;
		free(tmp);
	}
	fprintf(file, "\n\tli $v0, 10\n\tsyscall\n\n");
	fclose(file);
}

void mips_vars(struct symbol* s, FILE* f) {


	if(s == NULL) return;

	struct symbol *sym;

	for (sym = s; sym != NULL; sym = sym->next) {
		if (sym->type.stype == STYPE_INT) {
			fprintf(f, "%s:\t.word %d\n", sym->id, (int)sym->value);
		} else if (sym->type.stype == STYPE_REAL) {
			fprintf(f, "%s:\t.double %f\n", sym->id, sym->value);
		} else if (sym->type.stype == STYPE_BOOL) {
			fprintf(f, "%s:\t.word %d\n", sym->id, (int)sym->value);
		}
	}
}

void mips_write(quad *t, FILE *file) {

	int proc_param_nb = 0;

	if (t->label != NULL)
		fprintf(file, "%s:\n", t->label->id);

	switch(t->quad_type) {
		case NOP:
			fprintf(file, "\tnop\n\n");
			break;

		case AFFEC:
			fprintf(file, "\tlw $a0, %s\n\tsw $a0, %s\n\n", t->operande1->id, t->res->id);
			break;

		case AFFEC_UNARY_MINUS:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tneg $a0, $a0\n");
			fprintf(file, "\tsw $a0 %s\n\n", t->res->id);
			break;

		case AFFEC_UNARY_NOT:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tnot $a0 $a0\n");
			fprintf(file, "\tsw $a0 %s\n\n", t->res->id);
			break;

		case AFFEC_BINARY_PLUS:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tadd $a0, $a0, $a1\n");
			fprintf(file, "\tsw $a0 %s\n\n", t->res->id);
			break;

		case AFFEC_BINARY_MINUS:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tsub $a0, $a0, $a1\n");
			fprintf(file, "\tsw $a0 %s\n\n", t->res->id);
			break;

		case AFFEC_BINARY_MULT:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tmul $a0, $a0, $a1\n");
			fprintf(file, "\tsw $a0 %s\n\n", t->res->id);
			break;

		case AFFEC_BINARY_DIV:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tdiv $a0, $a0, $a1\n");
			fprintf(file, "\tsw $a0 %s\n\n", t->res->id);
			break;

		case AFFEC_BINARY_AND:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tand $a0, $a0, $a1\n");
			fprintf(file, "\tsw $a0 %s\n\n", t->res->id);
			break;

		case AFFEC_BINARY_OR:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tor $a0, $a0, $a1\n");
			fprintf(file, "\tsw $a0 %s\n\n", t->res->id);
			break;

		case BRANCHMENT_UNCOND:
			fprintf(file, "\tj %s\n\n", t->res->id);
			break;

		case BRANCHMENT_COND_EQ:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tbeq $a0, $a1, %s\n\n", t->res->id);
			break;

		case BRANCHMENT_COND_NEQ:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tbne $a0, $a1, %s\n\n", t->res->id);
			break;

		case BRANCHMENT_COND_LT:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tblt $a0, $a1, %s\n\n", t->res->id);
			break;

		case BRANCHMENT_COND_LTEQ:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tble $a0, $a1, %s\n\n", t->res->id);
			break;

		case BRANCHMENT_COND_GT:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tbgt $a0, $a1, %s\n\n", t->res->id);
			break;

		case BRANCHMENT_COND_GTEQ:
			fprintf(file, "\tlw $a0 %s\n", t->operande1->id);
			fprintf(file, "\tlw $a1 %s\n", t->operande2->id);
			fprintf(file, "\tbge $a0, $a1, %s\n\n", t->res->id);
			break;

		case PROC_PARAM:
			switch(proc_param_nb) {
				case 0:
					fprintf(file, "\tlw $a0 (%s%%sp )\n", t->res->id);
					proc_param_nb++;
					break;

				case 1:
					fprintf(file, "\tlw $a0 (%s%%sp )\n", t->res->id);
					proc_param_nb++;
					break;

				case 2:
					fprintf(file, "\tlw $a0 (%s%%sp )\n", t->res->id);
					proc_param_nb++;
					break;

				case 3:
					fprintf(file, "\tlw $a0 (%s%%sp )\n", t->res->id);
					proc_param_nb++;
					break;

				default:
					// Enregistrer les paramètres suivants dans la pile ?
					break;
			}
			break;

		case PROC_CALL:
			fprintf(file, "\tjal %s\n\n", t->res->id);
			proc_param_nb = 0;
			break;

		case TAB_LEFT:
			break;

		case TAB_RIGHT:
			break;

		default:
			fprintf(stderr, "Quad %d not currently supported\n", t->quad_type);
		}
}
