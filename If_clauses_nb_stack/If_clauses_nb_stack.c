#include "If_clauses_nb_stack.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>



int cmp_if_clauses_nb(list_node * node, void * if_clauses_nb){
	return ((unsigned int *)node->data) == ((unsigned int *)if_clauses_nb);
}

void print_if_clauses_nb(void * data){
	printf("If clause nb : %d\n", *((unsigned int *)data));
}


/* Création d'une pile contenant des lignes contenant chacune une instruction */
llist* create_if_clauses_nb_stack(){
	return list_create(&cmp_if_clauses_nb, &print_if_clauses_nb);
};

/* Méthode qui permet d'afficher cette pile */
void print_if_clauses_nb_stack(llist if_clauses_nb_stack){
	list_print(if_clauses_nb_stack);
}

/* Méthode qui permet d'empiler un élément */
unsigned int  *push_if_clauses_nb(llist * if_clauses_nb_stack){
	unsigned int * ui_if_clauses_nb = (unsigned int *)malloc(sizeof(unsigned int));
	*ui_if_clauses_nb = 0;
	list_node *node = list_insert_beginning(if_clauses_nb_stack, ui_if_clauses_nb);
	return (node ? (unsigned int *)node->data : NULL);	 
}

/* Méthode qui permet dépiler un élément */
unsigned int *pop_if_clauses_nb(llist * if_clauses_nb_stack){
	return list_isempty(*if_clauses_nb_stack) ? NULL : (unsigned int*)list_pop(if_clauses_nb_stack);
}

void increment_top_if_clauses_nb(llist * if_clauses_nb_stack){
	printf("plop\n");
	(*((unsigned int *)if_clauses_nb_stack->node->data))++;
	
}


