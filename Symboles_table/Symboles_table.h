#ifndef _SYMBOLES_TABLE_H
#define _SYMBOLES_TABLE_H

#include <stdbool.h>
#include "../list/list.h"

typedef struct Symbole{
	unsigned int ui_address;
	const char *p_name;
	bool b_constant;
	bool b_initialised;
} Symbole;

static const char * DEFAULT_TEMP_SYMBOLE_NAME = "";


//Création de la table des symboles
llist* create_symboles_table();

// Ajout d'un symbole dans la table des symboles
// Si constant est true initialised sera obligatoirement à 1
Symbole* add_symbole(llist * symboles_table, unsigned int ui_offset, const char * name, bool b_constant, bool b_initialised);
Symbole* push_temp_symbole(llist * symboles_table, unsigned int ui_offset);
Symbole* pop_temp_symbole(llist * symboles_table);

/* Permet de supprimer un résultats de calculs à l'addresse ui_address*/
Symbole* remove_calculation_result(llist * symboles_table, unsigned int ui_address);

Symbole* find_symbole(llist symboles_table, const char * p_name);
void print_symboles_table(llist symboles_table);
unsigned int get_next_available_symbole_address(llist symboles_table, unsigned int ui_offset);
void symboles_table_reset(llist * symboles_table);

#endif