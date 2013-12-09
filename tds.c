#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tds.h"

void scope_clear(struct scope *sc);

int nbTmp = 0;

struct symbol *symbol_create(char *id, struct type t, int isConstant, long value) {
	struct symbol *sym;

	sym = malloc(sizeof(*sym));
	if (!sym) {
		perror("malloc");
		exit(EXIT_FAILURE);
	}

	memset(sym, 0, sizeof(*sym));

	if (id == NULL) {
		id = malloc(sizeof(char) * 14);
		snprintf(id, 14, "TMP_%d", nbTmp);
		nbTmp++;
	}

	sym->id = id;
	sym->type = t;
	sym->isConstant = isConstant;
	sym->value = value;

	return sym;
}

struct scope *scope_create(struct scope *parent) {
	struct scope *sc = malloc(sizeof(*sc));

	if (sc == NULL) {
		perror("malloc");
		exit(EXIT_FAILURE);
	}
	memset(sc, 0, sizeof(*sc));

	sc->parent = parent;

	return sc;
}

struct scope *scope_add_symbol(struct scope *sc, struct symbol *sym) {
	if (sc == NULL)
		sc = scope_create(NULL);

	if (sym->id != NULL && scope_lookup(sc, sym->id) != NULL) {
		fprintf(stderr, "Error, symbol %s declared twice\n", sym->id);
		exit(EXIT_FAILURE);
	}

	sym->next = sc->tds;
	sc->tds = sym;

	return sc;
}

struct scope *scope_import(struct scope *sc, struct scope *sci) {
	struct symbol *sym;

	for (sym = sci->tds; sym != NULL; sym = sym->next)
		scope_add_symbol(sc, sym);

	scope_free(sci);

	return sc;
}

struct symbol* scope_lookup(struct scope *sc, char *name) {
	struct symbol *sym;

	if (sc == NULL)
		return NULL;

	for (sym = sc->tds; sym != NULL; sym = sym->next) {
		if (strcmp(sym->id, name) == 0)
			return sym;
	}

	return scope_lookup(sc->parent, name);
}

void scope_clear(struct scope *sc) {
	while(sc->tds != NULL) {
		struct symbol *tmp = sc->tds->next;
		free(tmp);
		sc->tds = tmp;
	}
}

void scope_free(struct scope *sc) {
	scope_clear(sc);
	free(sc);
}

void scope_print(struct scope *sc) {
	struct symbol *sym;

	for (sym = sc->tds; sym != NULL; sym = sym->next) {
		if (sym->isConstant)
			printf("%s = %s\n", sym->id, sym->value);
		else
			printf("%s\n", sym->id);
	}
}

void scope_print_all(struct scope *sc) {
	while (sc) {
		scope_print(sc);
		sc = sc->parent;
	}
}
