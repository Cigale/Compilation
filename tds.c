#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tds.h"

int nbTmp = 0;

struct scope *scope_add_symbol(struct scope *sc, char *id, struct type t, int isConstant, char *value) {
	struct symbol *sym;

	if (id != NULL && scope_lookup(sc, id) != NULL) {
		fprintf(stderr, "Error, symbol %s declared twice\n", id);
		exit(EXIT_FAILURE);
	}

	if (isConstant && value != NULL) {
		fprintf(stderr, "Only constants can have a value\n");
		exit(EXIT_FAILURE);
	}

	sym = malloc(sizeof(*sym));
	if (!sym) {
		perror("malloc");
		exit(EXIT_FAILURE);
	}

	if (id == NULL) {
		id = malloc(sizeof(char) * 14);
		snprintf(id, 14, "TMP_%d", nbTmp);
		nbTmp++;
	}

	sym->id = id;
	sym->type = t;
	sym->isConstant = isConstant;
	sym->value = value;
	sym->next = sc->tds;

	sc->tds = sym;

	return sc;
}

struct symbol* scope_lookup(struct scope *sc, char *name) {
	struct symbol *sym;

	if (sc == NULL)
		return NULL;

	for (sym = sc->tds; sym->next != NULL; sym = sym->next) {
		if (strcmp(sym->id, name) == 0)
			return sym;
	}

	return scope_lookup(sc->parent, name);
}

void scope_clear(struct scope *sc) {
	struct symbol *tmp;

	while(sc->tds != NULL) {
		tmp = sc->tds->next;
		free(tmp);
		sc->tds = tmp;
	}
}

void scope_print(struct scope *sc) {
	struct symbol *sym;

	for (sym = sc->tds; sym->next != NULL; sym = sym->next) {
		if (sym->isConstant)
			printf("%s = %s\n", sym->id, sym->isConstant, sym->value);
		else
			printf("%s\n", sym->id);
	}
}
