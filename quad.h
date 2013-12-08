#ifndef __QUAD__
#define __QUAD__

	typedef struct quad {
		char* label;
		tds* operande1;
		tds* operande2;
		tds* res;
		char* operateur;
		struct quad* next;
		struct quad* last;
	} quad;

	quad* quad_put(quad *t, tds *op1, tds *op2, tds* res, char* op);
	quad* quad_add(quad *t, quad* q);
	quad* quad_concat(quad* q1, quad* q2);
	quad* quad_take(quad **p);
	void quad_clear(quad **t);
	void quad_print(quad *t);
	void quad_complete(quad *t, char* value);
	
#endif
