#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tds.h"

int nbTmp = 0;

tds* tds_put(tds **t, char *id, int isConstant) {
	tds *element = malloc(sizeof(tds));
	if(!element) exit(EXIT_FAILURE);

	if(strcmp(id, "") == 0) {
		id = (char*) malloc(sizeof(char) * 14);
		strcat(id, "TMP_");
		char* s = (char*) malloc(sizeof(char) * 10);
		sprintf(s, "%d", nbTmp);
		nbTmp++;
		strcat(id, s);
	}

	element->id = id;
	element->isConstant = isConstant;
	element->next = *t;
	*t = element;

	return element;
}

tds* tds_lookup(tds **p, char* name) {
	tds *res = NULL;
	tds *tmp = *p;
	if(!*p) return NULL;
	if(!name) return NULL;
		
	while(strcmp((*p)->id, name) != 0 && (*p)->next != NULL) {
		*p = (*p)->next;
	}

	if(strcmp((*p)->id, name) != 0) {
		res = *p;
	}

	*p = tmp;
	return res;
}

void tds_clear(tds **t) {
	tds *tmp;
	while(*t) {
		 tmp = (*t)->next;
		 free(*t);
		 *t = tmp;
	}
}

void tds_print(tds *t) {
	while(t) {
		 printf("%s\t%d\t%s\n",t->id, t->isConstant, t->value);
		 t = t->next;
	  }
}
