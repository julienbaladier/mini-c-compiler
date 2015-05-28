#ifndef _IF_CLAUSES_NB_STACK_H
#define _IF_CLAUSES_NB_STACK_H

#include "../list/list.h"


/* Création d'une pile contenant des lignes contenant chacune une instruction */
llist* create_if_clauses_nb_stack();

/* Méthode qui permet d'afficher cette pile */
void print_if_clauses_nb_stack(llist if_clauses_nb_stack);

/* Méthode qui permet d'empiler un élément */
unsigned int  *push_if_clauses_nb(llist * if_clauses_nb_stack);

/* Méthode qui permet dépiler un élément */
unsigned int *pop_if_clauses_nb(llist * if_clauses_nb_stack);

void increment_top_if_clauses_nb(llist * if_clauses_nb_stack);

#endif