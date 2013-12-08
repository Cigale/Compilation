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
	union {
		enum scalar stype;
		struct {
			enum scalar stype;
			int size;
		} vector;
	} v;
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

struct scope *scope_add_symbol(struct scope *sc, char *id, struct type t, int isConstant, char *value);
struct symbol *scope_lookup(struct scope *sc, char* name);


/*void tds_clear(tds **t);
void tds_print(tds *t);*/

#endif
