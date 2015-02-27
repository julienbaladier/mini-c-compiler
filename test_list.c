#include "list.h"
#include <stdio.h>
#include <string.h>

typedef struct Symbole{
	int id;
	const char *p_name;
	unsigned int initialised : 1;
} Symbole;

//int nameCmpSymbole(list_node * node, int * id)
int idCmpSymbole(list_node * node, void * p_name){
	printf("%s\n", (const char *)p_name);
	return strcmp (((Symbole *)node->data)->p_name, (const char *)p_name);
}

//int strcmp (const char *s1, const char *s2);

int main(int argc, char const *argv[]){

	const char * symbole1name = "symbole1";
	const char * symbole2name = "symbole2";
	const char * symbole3name = "symbole3";

	Symbole symbole1 = { .id = 1, .p_name = symbole1name, .initialised = 0 };
	Symbole symbole2 = { .id = 2, .p_name = symbole2name, .initialised = 0 };
	Symbole symbole3 = { .id = 3, .p_name = symbole3name, .initialised = 0 };



	llist * my_liste = list_create(&idCmpSymbole);

	list_insert_end(my_liste, &symbole1);
	list_insert_end(my_liste, &symbole3);



	if(list_find_by_data(my_liste, (void *) symbole1.p_name) != NULL){
		printf("Existe!!!!\n");
	}else{
		printf("Existe passs !!!!\n");
	}


	// printf("%s\n", ((Var_mark *)my_liste->data)->p_name);


	return 0;
}