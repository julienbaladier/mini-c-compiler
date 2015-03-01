#include "SymbolesTable.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


//int nameCmpSymbole(list_node * node, const char * id)
int idCmpSymbole(list_node * node, void * p_name){
	// printf("%s\n", (const char *)p_name);
	return strcmp (((Symbole *)node->data)->p_name, (const char *)p_name);
}

void printSymbole(void * data){
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

}




//Création de la fonction de comparaison
llist* Symboles_table_create(){
	return list_create(&idCmpSymbole, &printSymbole);
};


Symbole* ajouterSymbole(llist * symboles_table, const char * p_name, bool constant, bool initialised){
	Symbole * p_symbole = (Symbole *) malloc(sizeof(Symbole));
	list_node * node = list_insert_beginning(symboles_table, p_symbole);
	p_symbole->id = symboles_table->node_number; p_symbole->p_name = p_name; p_symbole->constant = constant; p_symbole->initialised = initialised;
	return (node ? (Symbole*)node->data : NULL);	 
}

void printSymbolesTable(llist* symboles_table){
	print_list(symboles_table);
}

bool symboleExist(llist* symboles_table, const char * p_name){
	if(list_find_by_data(symboles_table, (void *) p_name) != NULL){
		return true;
	}else{
		return false;
	}
}




