#include "Symboles_table.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>




//int nameCmpSymbole(list_node * node, const char * id)
int cmp_symbole(list_node * node, void * p_name){
	// printf("%s\n", (const char *)p_name);
	return strcmp (((Symbole *)node->data)->p_name, (const char *)p_name);
}

void print_symbole(void * data){
	printf("%d\t\t%s\t\t", ((Symbole *)data)->id, ((Symbole *)data)->p_name);
	if (((Symbole *)data)->constant){
		printf("      constant");
	}else{
		printf("not a constant");
	}

	printf("\t\t");

	if (((Symbole *)data)->initialised){
		printf("    initialised");
	}else{
		printf("not initialised");
	}
	printf("\n");
}

int getIdTopStack(llist symboles_table){
	return symboles_table.node_number;
}



//Création de la fonction de comparaison
llist* create_symboles_table(){
	return list_create(&cmp_symbole, &print_symbole);
};


Symbole* add_symbole(llist * symboles_table, const char * p_name, bool constant, bool initialised){
	Symbole * p_symbole = (Symbole *) malloc(sizeof(Symbole));
	list_node * node = list_insert_beginning(symboles_table, p_symbole);
	p_symbole->id = symboles_table->node_number; p_symbole->p_name = p_name;
	p_symbole->constant = constant;
	if(p_symbole->constant){
		p_symbole->initialised = true;
	}else{
		p_symbole->initialised = initialised;
	}
	return (node ? (Symbole*)node->data : NULL);	 
}

Symbole* push_temp_symbole(llist * symboles_table){
	Symbole * p_symbole = (Symbole *) malloc(sizeof(Symbole));
	list_node * node = list_insert_beginning(symboles_table, p_symbole);
	p_symbole->id = symboles_table->node_number; p_symbole->p_name = DEFAULT_TEMP_SYMBOLE_NAME;
	p_symbole->constant = true;
	p_symbole->initialised = true;

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




