#include "list.h"
#include <stdio.h>
#include <string.h>

typedef struct Symbole{
	int id;
	const char *p_name;
	unsigned int constant : 1;
	unsigned int initialised : 1;
} Symbole;

//Création de la fonction de comparaison

//int nameCmpSymbole(list_node * node, const char * id)
int idCmpSymbole(list_node * node, void * p_name){
	printf("%s\n", (const char *)p_name);
	return strcmp (((Symbole *)node->data)->p_name, (const char *)p_name);
}


//Création de la table des symboles
llist * symboles_table = list_create(&idCmpSymbole, NULL);