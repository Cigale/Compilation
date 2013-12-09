#ifndef SYMBOLS__
#define SYMBOLS__

enum scalar {
	STYPE_BOOL,
	STYPE_INT,
	STYPE_CPLX,
	STYPE_REAL
};

struct type {
	int is_scalar;
	enum scalar stype;
	int size; /* Meaningless if is_scalar is set */
};

struct symbol {
	struct symbol *next;

	char *id;
	struct type type;
	int isConstant;
	char *value; /* Must be NULL for non-constant symbol */
};

struct scope {
	struct symbol *tds;
	struct scope *parent;
};

struct symbol *symbol_create(char *id, struct type t, int isConstant, char *value);
struct scope *scope_create(struct scope *parent);
struct scope *scope_add_symbol(struct scope *sc, struct symbol *sym);
struct scope *scope_import(struct scope *sc, struct scope *sci);
struct symbol *scope_lookup(struct scope *sc, char* name);
void scope_free(struct scope *sc);
void scope_print(struct scope *sc);
void scope_print_all(struct scope *sc);

#endif
