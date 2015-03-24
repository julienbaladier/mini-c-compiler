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
llist* create_symboles_table();

// Ajout d'un symbole dans la table des symboles
// Si constant est true initialised sera obligatoirement à 1
Symbole* add_symbole(llist * symboles_table, const char * name, bool constant, bool initialised);
Symbole* push_temp_symbole(llist * symboles_table);
Symbole* pop_temp_symbole(llist * symboles_table);
Symbole* find_symbole(llist symboles_table, const char * p_name);
int getIdTopStack(llist symboles_table);
void print_symboles_table(llist symboles_table);

#endif