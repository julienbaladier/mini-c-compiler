#include "SymbolesTable/SymbolesTable.h"
#include <stdio.h>
#include <string.h>


int main(int argc, char const *argv[]){

	llist * symboles_table = Symboles_table_create();

	ajouterSymbole(symboles_table, "symbole1", false, false);
	ajouterSymbole(symboles_table, "symbole2", false, true);
	ajouterSymbole(symboles_table, "symbole3", true, false);

	printSymbolesTable(symboles_table);

	if (symboleExist(symboles_table, "symbole2")){
		printf("Championnnnnn !!!!\n");
	}

	return 0;
}