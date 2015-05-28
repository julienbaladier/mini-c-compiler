#include "Functions_table.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


int cmp_function(list_node * node, void * p_name){
	return strcmp (((Function *)node->data)->p_name, (const char *)p_name);
}


void print_function(void * data){
	printf("%s\t\t%d arguments\t\t", ((Function *)data)->p_name, ((Function *)data)->ui_argument_number);
	if (((Function *)data)->ui_implementation_address == -1){
		printf("not implemented");
	}else{
		printf("implemented line %d", ((Function *)data)->ui_implementation_address);
	}
	printf("\n");
}



//Création de la fonction de comparaison
llist* create_functions_table(){
	return list_create(&cmp_function, &print_function);
};

Function* add_function(llist * functions_table, const char * p_name, unsigned int ui_implementation_address, unsigned int ui_argument_number, bool return_value){
	Function * p_function = (Function *) malloc(sizeof(Function));
	list_node * node = list_insert_beginning(functions_table, p_function);
	p_function->p_name = p_name;
	p_function->ui_implementation_address = ui_implementation_address;
	p_function->ui_argument_number = ui_argument_number;
	p_function->return_value = return_value;
	return (node ? (Function*)node->data : NULL);	
}



void print_functions_table(llist functions_table){
	list_print(functions_table);
}

Function * find_function(llist functions_table, const char * p_name){

	list_node * node = list_find_by_data(&functions_table, (void *) p_name);

	if(node != NULL){
		return (Function *)node->data;
	}else{
		return NULL;
	}

}

//INC 3
//on empiler les a'guments addresses de reotur.....
//CALL
//DEC 3


