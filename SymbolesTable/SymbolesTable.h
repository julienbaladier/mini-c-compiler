#ifndef _SYMBOLES_TABLE_H
#define _SYMBOLES_TABLE_H

#include <stdbool.h>
#include "../list/list.h"

typedef struct Symbole{
	int id;
	const char *p_name;
	bool constant;
	bool initialised;
} Symbole;

static const char * DEFAULT_TEMP_SYMBOLE_NAME = "";


//Création de la table des symboles
llist* symbolesTableCreate();

// Ajout d'un symbole dans la table des symboles
// Si constant est true initialised sera obligatoirement à 1
Symbole* ajouterSymbole(llist * symboles_table, const char * name, bool constant, bool initialised);
Symbole* pushTempSymbole(llist * symboles_table);
Symbole* popTempSymbole(llist * symboles_table);
Symbole* findSymbole(llist symboles_table, const char * p_name);
int getIdTopStack(llist symboles_table);
void printSymbolesTable(llist symboles_table);

#endif