#ifndef _INSTRUCTIONS_STACK_H
#define _INSTRUCTIONS_STACK_H

#include <stdbool.h>
#include "../list/list.h"


typedef struct Instruction{
	unsigned int ui_address;
	long l_position;
	bool b_incomplete;
} Instruction;


/* Création d'une pile contenant des lignes contenant chacune une instruction */
llist* create_instructions_stack();

/* Méthode qui permet d'afficher cette pile */
void print_instructions_stack(llist instructions_stack);

/* Méthode qui permet d'empiler un élément */
Instruction  *push_instruction(llist * instructions_stack, int ui_address, long l_position, bool b_incomplete);

/* Méthode qui permet dépiler un élément */
Instruction *pop_instruction(llist * instructions_stack);

#endif