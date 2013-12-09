#ifndef __TDS__
#define __TDS__

	typedef struct tds {
		char* id;
		int isConstant;
		char* value;
		char* type;
		int memPos;
		struct tds* next;
	} tds;

	tds* tds_put(tds **t, char *id, int isConstant);
	tds* tds_lookup(tds **p, char* name);
	void tds_clear(tds **t);
	void tds_print(tds *t);
	
#endif
