#ifndef _FUNCTIONS_TABLE_H
#define _FUNCTIONS_TABLE_H

#include "../list/list.h"
#include <stdbool.h>

typedef struct Function{
	const char *p_name;
	unsigned int ui_implementation_address;
	unsigned int ui_argument_number;
	bool return_value;
} Function;

//Création de la table des functions
llist* create_functions_table();

Function* add_function(llist * functions_table, const char * p_name, unsigned int ui_implementation_address, unsigned int ui_argument_number, bool return_value);
Function* find_function(llist functions_table, const char * p_name);
void print_functions_table(llist functions_table);

#endif