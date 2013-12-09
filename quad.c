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

void quad_complete(quad *t, char *value) {
	t->res->value = value;
}

void mips_gen(quad **q, struct symbol* s) {

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
		
		int proc_param_nb = 0;
		
		switch(t->quad_type) {
			case AFFEC_UNARY_MINUS : fprintf(file, "neg %d, %d", t->res->memPos, t->operande1->memPos);
			break;
			
			case AFFEC_UNARY_NOT : fprintf(file, "not %d, %d", t->res->memPos, t->operande1->memPos);
			break;
			
			case AFFEC_BINARY_PLUS : fprintf(file, "add %d, %d, %d", t->res->memPos, t->operande1->memPos, t->operande2->memPos);
			break;
			
			case AFFEC_BINARY_MINUS : fprintf(file, "sub %d, %d, %d", t->res->memPos, t->operande1->memPos, t->operande2->memPos);
			break;
			
			case AFFEC_BINARY_MULT : fprintf(file, "mult %d, %d, %d", t->res->memPos, t->operande1->memPos, t->operande2->memPos);
			break;
			
			case AFFEC_BINARY_DIV : fprintf(file, "div %d, %d, %d", t->res->memPos, t->operande1->memPos, t->operande2->memPos);
			break;
			
			case AFFEC_BINARY_AND : fprintf(file, "and %d, %d, %d", t->operande1->memPos, t->operande2->memPos, t->res->memPos);
			break;
			
			case AFFEC_BINARY_OR : fprintf(file, "or %d, %d, %d", t->operande1->memPos, t->operande2->memPos, t->res->memPos);
			break;
			
			case BRANCHMENT_UNCOND : fprintf(file, "j %d", t->res->memPos);
			break;
			
			case BRANCHMENT_COND_EQ : fprintf(file, "beq %d, %d, %d", t->operande1->memPos, t->operande2->memPos, t->res->memPos);
			break;
			
			case BRANCHMENT_COND_NEQ : fprintf(file, "bne %d, %d, %d", t->operande1->memPos, t->operande2->memPos, t->res->memPos);
			break;
			
			case BRANCHMENT_COND_LT : fprintf(file, "blt %d, %d, %d", t->operande1->memPos, t->operande2->memPos, t->res->memPos);
			break;
			
			case BRANCHMENT_COND_LTEQ : fprintf(file, "ble %d, %d, %d", t->operande1->memPos, t->operande2->memPos, t->res->memPos);
			break;
			
			case BRANCHMENT_COND_GT : fprintf(file, "bgt %d, %d, %d", t->operande1->memPos, t->operande2->memPos, t->res->memPos);
			break;
			
			case BRANCHMENT_COND_GTEQ : fprintf(file, "bge %d, %d, %d", t->operande1->memPos, t->operande2->memPos, t->res->memPos);
			break;
			
			case PROC_PARAM : switch(proc_param_nb) {
				case 0 : fprintf(file, "lw $a0 (%d%%sp )", t->res->memPos);
				proc_param_nb++;
				break;
				
				case 1 : fprintf(file, "lw $a0 (%d%%sp )", t->res->memPos);
				proc_param_nb++;
				break;
				
				case 2 : fprintf(file, "lw $a0 (%d%%sp )", t->res->memPos);
				proc_param_nb++;
				break;
				
				case 3 : fprintf(file, "lw $a0 (%d%%sp )", t->res->memPos);
				proc_param_nb++;
				break;
				
				default : // Enregistrer les paramètres suivants dans la pile ?
				break;
			}
			break;
			
			case PROC_CALL : fprintf(file, "jal %d", t->res->memPos);
				proc_param_nb = 0;
			break;
			
			case TAB_LEFT :
			break;
			
			case TAB_RIGHT :
			break;
			
			
		}
}


