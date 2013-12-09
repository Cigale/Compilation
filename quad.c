#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tds.h"
#include "quad.h"

int next_quad = 0;

quad* quad_put(quad *t, struct symbol *op1, struct symbol *op2, struct symbol *res, char* op) {

	quad *element = malloc(sizeof(quad));
	if(!element) exit(-1);

	element->label = (char*) malloc(sizeof(char) * 10);
	sprintf(element->label, "%d", next_quad);
	element->operande1 = op1;
	element->operande2 = op2;
	element->res = res;
	element->operateur = op;

	if(!t) {
		t = element;
		element->next = NULL;
	} else {
		t->last->next = element;
		element->next = NULL;
	}
	t->last = element;
	next_quad++;

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
	q1->last->next = q2;

	return q1;
}

quad* quad_take(quad **p) {
	quad *res;
	quad *tmp;
	if(!*p) return NULL;     /* Retourne -1 si la pile est vide. */
	res = *p;
	tmp = (*p)->next;
	free(*p);
	*p = tmp;
	return res;
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
		printf("Label : %s\n\n",t->label);
		t = t->next;
	}
}

void quad_complete(quad *t, long value) {
	t->res->value = value;
}

void mips_gen(quad **q) {

	FILE* file = NULL;

	file = fopen("res.s", "w+");

	if(file != NULL) {

		// TODO: enregistrer les symboles dans la pile du programme MIPS

		quad* current = quad_take(q);

		while(current) {
			mips_write(current, file);
			current = quad_take(q);
		}

		fclose(file);
	} else {
		printf("Impossible d'ouvrir le fichier MIPS\n");
		exit(-1);
	}
}

void mips_write(quad *t, FILE *file) {

		// Pour charger / enregistrer une variable de la pile au registre :

		// lw $t0 (8$sp)
		// lw : load valeur de la pile
		// $t0 position dans le registre
		// 8 : position dans la pile (multiples de 4)
		// $sp : Représente la pile

		// sw $t0 (8$sp)

		switch(t->quad_type) {
			case AFFEC_UNARY_MINUS :
				if(t->operande1->isConstant) {
					fprintf(file, "neg %s, %d", t->res->id, t->operande1->value);
				} else {
					fprintf(file, "neg %s, %d", t->res->id, t->operande1->id);
				}
			break;

			case AFFEC_UNARY_NOT : fprintf(file, "not %s, %s", t->res->id, t->operande1->id);
			break;

			case AFFEC_BINARY_PLUS :
				if(t->operande1->isConstant) {
					if(t->operande2->isConstant) {
						fprintf(file, "add %s, %d, %d", t->res->id, t->operande1->value, t->operande2->value);
					} else {
						fprintf(file, "add %s, %d, %s", t->res->id, t->operande1->value, t->operande2->id);
					}
				} else {
					if(t->operande2->isConstant) {
						fprintf(file, "add %s, %s, %d", t->res->id, t->operande1->id, t->operande2->value);
					} else {
						fprintf(file, "add %s, %s, %s", t->res->id, t->operande1->id, t->operande2->id);
					}
				}
			break;

			case AFFEC_BINARY_MINUS :
				if(t->operande1->isConstant) {
					if(t->operande2->isConstant) {
						fprintf(file, "sub %s, %d, %d", t->res->id, t->operande1->value, t->operande2->value);
					} else {
						fprintf(file, "sub %s, %d, %s", t->res->id, t->operande1->value, t->operande2->id);
					}
				} else {
					if(t->operande2->isConstant) {
						fprintf(file, "sub %s, %s, %d", t->res->id, t->operande1->id, t->operande2->value);
					} else {
						fprintf(file, "sub %s, %s, %s", t->res->id, t->operande1->id, t->operande2->id);
					}
				}
			break;

			case AFFEC_BINARY_MULT :
				if(t->operande1->isConstant) {
					if(t->operande2->isConstant) {
						fprintf(file, "mult %s, %d, %d", t->res->id, t->operande1->value, t->operande2->value);
					} else {
						fprintf(file, "mult %s, %d, %s", t->res->id, t->operande1->value, t->operande2->id);
					}
				} else {
					if(t->operande2->isConstant) {
						fprintf(file, "mult %s, %s, %d", t->res->id, t->operande1->id, t->operande2->value);
					} else {
						fprintf(file, "mult %s, %s, %s", t->res->id, t->operande1->id, t->operande2->id);
					}
				}
			break;

			case AFFEC_BINARY_DIV :
				if(t->operande1->isConstant) {
					if(t->operande2->isConstant) {
						fprintf(file, "div %s, %d, %d", t->res->id, t->operande1->value, t->operande2->value);
					} else {
						fprintf(file, "div %s, %d, %s", t->res->id, t->operande1->value, t->operande2->id);
					}
				} else {
					if(t->operande2->isConstant) {
						fprintf(file, "div %s, %s, %d", t->res->id, t->operande1->id, t->operande2->value);
					} else {
						fprintf(file, "div %s, %s, %s", t->res->id, t->operande1->id, t->operande2->id);
					}
				}
			break;
		}
}


