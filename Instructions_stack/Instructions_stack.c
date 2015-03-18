#include "Instructions_stack.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>



int cmp_instructions(list_node * node, void * instruction){
	return ((Instruction *)node->data)->i_instruction_number 
			== ((Instruction *)instruction)->i_instruction_number;
}

void print_instruction(void * data){
	printf("Instruction number : %d | Position : %ld | ", 
		((Instruction *)data)->i_instruction_number, ((Instruction *)data)->l_position);
	if (((Instruction *)data)->b_written){
		printf("Written");
	}else{
		printf("Not written");
	}
	printf("\n");
}


/* Création d'une pile contenant des lignes contenant chacune une instruction */
llist* create_instructions_stack(){
	return list_create(&cmp_instructions, &print_instruction);
};

/* Méthode qui permet d'afficher cette pile */
void print_instructions_stack(llist instructions_stack){
	list_print(instructions_stack);
}

/* Méthode qui permet d'empiler un élément */
Instruction  *push_instruction(llist * instructions_stack, int i_instruction_number, long l_position, bool b_written){
	Instruction *instruction = (Instruction *) malloc(sizeof(Instruction));
	instruction->i_instruction_number = i_instruction_number;
	instruction->l_position = l_position;
	instruction->b_written = b_written;
	list_node *node = list_insert_beginning(instructions_stack, instruction);
	return (node ? (Instruction*)node->data : NULL);	 
}

/* Méthode qui permet dépiler un élément */
Instruction *pop_instruction(llist * instructions_stack){
	return list_isempty(*instructions_stack) ? NULL : (Instruction*)list_pop(instructions_stack);
}




