
all: 
	yacc -d latex.y
	lex latex.l
	gcc *.c -lfl -g

exec: 
	./a.out

run: all exec
