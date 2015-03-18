#ifndef _INSTRUCTIONS_STACK_H
#define _INSTRUCTIONS_STACK_H

#include <stdbool.h>
#include "../list/list.h"


typedef struct Instruction{
	int i_instruction_number;
	long l_position;
	bool b_written;
} Instruction;


/* Création d'une pile contenant des lignes contenant chacune une instruction */
llist* create_instructions_stack();

/* Méthode qui permet d'afficher cette pile */
void print_instructions_stack(llist instructions_stack);

/* Méthode qui permet d'empiler un élément */
Instruction  *push_instruction(llist * instructions_stack, int i_instruction_number, long l_position, bool b_written);

/* Méthode qui permet dépiler un élément */
Instruction *pop_instruction(llist * instructions_stack);

#endif