.PHONY: all
all: compiler

compiler: y.tab.c lex.yy.c quad.c tds.c
	gcc $^ -o $@ -lfl -ggdb

y.tab.h y.tab.c: latex.y
	yacc -d $<

lex.yy.c: latex.l
	lex $<


.PHONY: clean mrproper
clean:
	rm -f y.tab.h y.tab.c
	rm -f lex.yy.c

mrproper: clean
	rm -f compiler

.PHONY: exec run
exec:
	./compiler

run: all exec
