#include "Symboles_table.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>




//int nameCmpSymbole(list_node * node, const char * id)
int cmp_symbole(list_node * node, void * p_name){
	// printf("%s\n", (const char *)p_name);
	return (strcmp (((Symbole *)node->data)->p_name, (const char *)p_name) == 0);
}


void print_symbole(void * data){
	printf("%d\t\t%s\t\t", ((Symbole *)data)->ui_address, ((Symbole *)data)->p_name);
	if (((Symbole *)data)->b_constant){
		printf("      constant");
	}else{
		printf("not a constant");
	}

	printf("\t\t");

	if (((Symbole *)data)->b_initialised){
		printf("    initialised");
	}else{
		printf("not initialised");
	}
	printf("\n");
}




//Création de la fonction de comparaison
llist* create_symboles_table(){
	return list_create(&cmp_symbole, &print_symbole);
};


Symbole* add_symbole(llist * symboles_table, unsigned int ui_offset, const char * p_name, bool b_constant, bool b_initialised){
	Symbole * p_symbole = (Symbole *) malloc(sizeof(Symbole));
	list_node * node = list_insert_beginning(symboles_table, p_symbole);
	p_symbole->ui_address = symboles_table->node_number - 1 + ui_offset; p_symbole->p_name = p_name;
	p_symbole->b_constant = b_constant;
	if(p_symbole->b_constant){
		p_symbole->b_initialised = true;
	}else{
		p_symbole->b_initialised = b_initialised;
	}
	return (node ? (Symbole*)node->data : NULL);	 
}

Symbole* push_temp_symbole(llist * symboles_table, unsigned int ui_offset){
	Symbole * p_symbole = (Symbole *) malloc(sizeof(Symbole));
	list_node * node = list_insert_beginning(symboles_table, p_symbole);
	p_symbole->ui_address = symboles_table->node_number - 1 + ui_offset; p_symbole->p_name = DEFAULT_TEMP_SYMBOLE_NAME;
	p_symbole->b_constant = true;
	p_symbole->b_initialised = true;

	return (node ? (Symbole*)node->data : NULL);	 
}

Symbole* pop_temp_symbole(llist * symboles_table){
	Symbole * tmp_symbole = find_symbole(*symboles_table, DEFAULT_TEMP_SYMBOLE_NAME);

	if (tmp_symbole == NULL){
		return NULL;
	}else{
		return (Symbole*)list_pop(symboles_table);
	}
}


void print_symboles_table(llist symboles_table){
	list_print(symboles_table);
}

Symbole * find_symbole(llist symboles_table, const char * p_name){

	list_node * node = list_find_by_data(&symboles_table, (void *) p_name);

	if(node != NULL){
		return (Symbole *)node->data;
	}else{
		return NULL;
	}

}

unsigned int get_next_available_symbole_address(llist symboles_table, unsigned int ui_offset){
	return ui_offset + symboles_table.node_number;
}


void symboles_table_reset(llist * symboles_table){
	list_empty(symboles_table);
}





Symbole* remove_calculation_result(llist * symboles_table, unsigned int ui_address){
	Symbole * removed_symbole = NULL;
	if (!symboles_table) return NULL;
	if ((((Symbole *)symboles_table->node->data)->ui_address == ui_address) && cmp_symbole(symboles_table->node, (void *)DEFAULT_TEMP_SYMBOLE_NAME)){
		return pop_temp_symbole(symboles_table);
	}else{
		return NULL;
	}
}









