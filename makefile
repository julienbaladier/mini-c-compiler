all: g--

g--: lexique.l grammaire.yacc list/list.c If_clauses_nb_stack/If_clauses_nb_stack.c Symboles_table/Symboles_table.c Functions_table/Functions_table.c Instructions_stack/Instructions_stack.c
	yacc -d grammaire.yacc
	flex lexique.l
	gcc -c list/list.c
	gcc -o Symboles_table.o -c Symboles_table/Symboles_table.c
	gcc -o Functions_table.o -c Functions_table/Functions_table.c
	gcc -o Instructions_stack.o -c Instructions_stack/Instructions_stack.c
	gcc -o If_clauses_nb_stack.o -c If_clauses_nb_stack/If_clauses_nb_stack.c
	gcc -c y.tab.c
	gcc -c lex.yy.c
	gcc list.o Symboles_table.o Functions_table.o If_clauses_nb_stack.o Instructions_stack.o y.tab.o lex.yy.o -ll -o g--

clean:
	rm -rf *.o */*.o y.tab.c lex.yy.c

mrproper: clean
	rm -rf compiler
