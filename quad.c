#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tds.h"
#include "quad.h"

int next_quad = 0;

quad* quad_put(quad *t, tds *op1, tds *op2, tds *res, char* op) {

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
	*p = tmp;       /* Le pointeur pointe sur le dernier élément. */
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

void quad_complete(quad *t, char* value) {
	t->res->value = value;
}
