%{
	#include <stdlib.h>
	#include <stdio.h>
	#include <unistd.h>
	#include <string.h>
	#include <ctype.h>
	#include <stdbool.h>
	#include "Symboles_table/Symboles_table.h"
	#include "Functions_table/Functions_table.h"
	#include "Instructions_stack/Instructions_stack.h"
	#include "If_clauses_nb_stack/If_clauses_nb_stack.h"

	int yylex(void);
	void yyerror (char const *msg); /* fonction qui s'excute en cas d'erreur */
	void display_help(); /* display help to use this compiler */
	extern FILE *yyin; /* fichier c */
	extern int yylineno; /* numéro de la ligne courante */
	int yydebug=1; /* debug mode ? */

	FILE * temp_file; /* fichier qui contient */
	
	llist * symboles_table; /* table des symboles */
	llist * functions_table; /* table qui garde en mémoire les fonctions déclarées */
	llist * instructions_stack; /* pile permettant de marquer des instructions comme complètes ou incomplètes (utile pour les jump) */
	llist * if_clauses_nb_stack;
	unsigned int ui_next_instruction_address = 0; /* adresse de la prochaine instruction à écrire */ 
	unsigned int ui_compilation_errors_nb = 0; /* nombre d'erreur détectées */

	/* offsets : 1 (@retour) + 0/1 (valeur retournée) + 0/n (nombre d'argument) */
	unsigned int ui_offset_symboles_table_addresses = 0; /* offset de la fonction appelante */
	unsigned int ui_called_function_offset_symboles_table_addresses = 0; /* offset de la fonction appellée */

	int const_declaration_context = 0; /* Permet de savoir si on est dans un context d'une déclaration de constante ou de variable */
	int const_argument_declaration_context = 0;
%}

%union { int nb; char * var; }

%token tMAIN tPRINTF tNEWLINE
%token tOPENED_BRACKET tCLOSED_BRACKET tOPENED_PARENTHESIS tCLOSED_PARENTHESIS
%token tIF tELSE tWHILE
%token tCOMMA tSEMICOLON
%token tCONST tINT tVOID
%token tADD tMINUS tMUL tDIV tEQUAL
%token tGREATERTHAN tLOWERTHAN tNOT
%token tINTEGER_EXP_FORM tINTEGER_DEC_FORM
%token tID
%token tERROR
%token tRETURN

%type <nb> tINTEGER_EXP_FORM tINTEGER_DEC_FORM calculation_value integer calculation 
%type <nb> affectation_in_variable_declaration
%type <nb> affectation_in_affectation_list_instruction id_in_affectation_in_affectation_list_instruction

%type <nb> calculation_list calculation_list_or_nothing function_call
%type <nb> declaration_function

%type <var> tID calculation_variable operator function_argument


%left tADD tMINUS
%left tMUL tDIV

%start start

%%

/**********************************PROGRAM*************************************/

start:											
					declaration_function_list main
					;



/**********************************MAIN***************************************/

main:											
					tINT tMAIN tOPENED_PARENTHESIS tCLOSED_PARENTHESIS tOPENED_BRACKET 
						{ 
							ui_offset_symboles_table_addresses = 2;
							fprintf(temp_file, "main :\n");
						}
					declaration_variable_list instruction_list 
					tCLOSED_BRACKET
					;



				

/*******************************DECLARATIONS**********************************/



// declaration_variable_and_function_list:								
// 					/* Nothing */
// 					|declaration_variable_and_function_list declaration_variable_and_function
// 					;

// declaration_variable_and_function:
// 		declaration_function
// 		|declaration_variable
// 		;



declaration_variable_list:								
					/* Nothing */
					|declaration_variable_list declaration_variable
					;

declaration_function_list:								
		/* Nothing */
		|declaration_function_list declaration_function
			{
				/* RET 0 */
				fprintf(temp_file, "%d:\tRET %d\n", ui_next_instruction_address, $2);
				ui_next_instruction_address++;

				print_symboles_table(*symboles_table);
				printf("\n");
				
				symboles_table_reset(symboles_table);
				fprintf(temp_file, "\n");
			}
		;


declaration_variable:								
		declaration_constante
		|declaration_integer
		;

declaration_constante:							
		tCONST 
			{
				const_declaration_context = 1;
			}
		tINT affection_and_id_list_in_variable_declaration tSEMICOLON	
		;


declaration_integer:							
		tINT 
			{
				const_declaration_context = 0;
			}
		affection_and_id_list_in_variable_declaration tSEMICOLON
		;



declaration_function:
					tINT tID tOPENED_PARENTHESIS 
						{
							ui_offset_symboles_table_addresses = 2;
						}
					function_argument_list_or_nothing tCLOSED_PARENTHESIS tOPENED_BRACKET 
						{ 
							fprintf(temp_file, "%s :\n", $2);

							// Ajout de la fonction dans la table des fonctions
							Function * function = add_function(functions_table, $2, ui_next_instruction_address, symboles_table->node_number, 1);

						}
					declaration_variable_list instruction_list 
					tCLOSED_BRACKET
						{
							$$ = 1;
						}

					|tVOID tID tOPENED_PARENTHESIS 
						{
							ui_offset_symboles_table_addresses = 1;
						}
					 function_argument_list_or_nothing tCLOSED_PARENTHESIS tOPENED_BRACKET 
						{ 
							fprintf(temp_file, "%s :\n", $2);

							// Ajout de la fonction dans la table des fonctions
							Function * function = add_function(functions_table, $2, ui_next_instruction_address, symboles_table->node_number, 0);

						}
					declaration_variable_list instruction_list 
					tCLOSED_BRACKET
						{
							$$ = 0;
						}
					;



function_argument_list_or_nothing: 
					/* nothing */
					|function_argument_list
					;

function_argument_list:
					argument_in_function_argument_list
					|argument_in_function_argument_list tCOMMA function_argument_list
					;

argument_in_function_argument_list: 
					function_argument
						{

							// On regarde si le symbole existe déjà
							Symbole * symbole = find_symbole(*symboles_table, $1);

							// Si oui il y a erreur car ce nom est déjà utilisé par un autre argument
							if(symbole != NULL){
								yyerror("Multiple arguments with the same name.");

							// Sinon on l'ajoute à la table des symboles
							}else{

								Symbole * symbole = add_symbole(symboles_table, ui_offset_symboles_table_addresses, $1, const_argument_declaration_context, true);
							}

						}
					;


function_argument:
					tINT tID
						{
							const_argument_declaration_context = 0;
							$$ = $2;
						}
					|tCONST tINT tID
						{
							const_argument_declaration_context = 1;
							$$ = $3;
						}
					;



















/*******************************INSTRUCTIONS**********************************/


instruction_list:								
					/* Nothing */
					|instruction instruction_list
					;


instruction:									
		affectation_list_instruction tSEMICOLON
		|tIF 
			{
				// ajout de l'élément dans la liste
				push_if_clauses_nb(if_clauses_nb_stack);
			}
		 if_structure_end
			{
				// on fait un pop de la strucutre if
				unsigned int * ui_if_clause_nb = pop_if_clauses_nb(if_clauses_nb_stack);

				for (int i = *ui_if_clause_nb; i > 0; --i){
					
					print_symboles_table(*instructions_stack);
					Instruction * instruction = pop_instruction(instructions_stack);

					FILE * new_temp_file = tmpfile();

					rewind(temp_file);

					int c = 0;

					for (long i = 0; i < instruction->l_position; ++i){
						c = fgetc(temp_file);
						fputc(c, new_temp_file);
					}

					fprintf(new_temp_file, "%d\n", ui_next_instruction_address); // il faut sauter après le dernier jump pour poursuivre

					while( ( c = fgetc(temp_file) ) != EOF ){
						fputc(c, new_temp_file);
					}
					fclose(temp_file);

					temp_file = new_temp_file;
				}
			}

		|while_structure
			{
				Instruction * instruction_incomplete = pop_instruction(instructions_stack);

				// On place le curseur au bon endroit
				if(fseek (temp_file, instruction_incomplete->l_position, SEEK_SET)){
					printf("fseek error\n");
				}


				FILE * new_temp_file = tmpfile();
				rewind(temp_file);
				int c = 0;
				for (long i = 0; i < instruction_incomplete->l_position; ++i){
					c = fgetc(temp_file);
					fputc(c, new_temp_file);
				}

				fprintf(new_temp_file, "%d\n", ui_next_instruction_address+1); // il faut sauter après le dernier jump pour poursuivre

				while( ( c = fgetc(temp_file) ) != EOF ){
					fputc(c, new_temp_file);
				}

				fclose(temp_file);

				temp_file = new_temp_file;

				
				// On revient à la bonne position dans le fichier
				fseek (temp_file, 0, SEEK_END);


				Instruction * instruction_complete = pop_instruction(instructions_stack);

				// Saut inconditionnel juste avant la condition du while
				fprintf(temp_file, "%d:\tJMP %d\n", ui_next_instruction_address, instruction_complete->ui_address);
				ui_next_instruction_address++;

			}
		|tPRINTF tOPENED_PARENTHESIS calculation_variable tCLOSED_PARENTHESIS tSEMICOLON
			{	
				// On vérifie que la variable existe bien

				Symbole * symbole = find_symbole(*symboles_table, $3);
				// Si elle n'existe pas => erreur

				if(symbole == NULL){
					yyerror("Utilisation d'une variable non déclarée !");

				// Si elle n'est pas initialisée => erreur
				}else if(symbole->b_initialised == false){
					yyerror("Utilisation d'une variable non initialisée !");

				}else{
					/* PRI @var */
					fprintf(temp_file, "%d:\tPRI %d\n", ui_next_instruction_address, symbole->ui_address);
					ui_next_instruction_address++;
				}
			}
		|function_call tSEMICOLON
		|tRETURN calculation tSEMICOLON
			{

				remove_calculation_result(symboles_table, (unsigned int)$2);

				// Copie du résultat à l'addresse de retour

				fprintf(temp_file, "%d:\tCOP %d %d\n", ui_next_instruction_address, 0, $2);
				ui_next_instruction_address++;

				// RET à l'address précisé à l'address 0
				fprintf(temp_file, "%d:\tRET %d\n", ui_next_instruction_address, 1);
				ui_next_instruction_address++;
			}
		;












/***************************************IF*****************************************/




if_structure_end:
		if_clause_end
			{
				Instruction * instruction = pop_instruction(instructions_stack);
				

				FILE * new_temp_file = tmpfile();
				rewind(temp_file);
				int c = 0;

				for (long i = 0; i < instruction->l_position; ++i){
					c = fgetc(temp_file);
					fputc(c, new_temp_file);
				}

				fprintf(new_temp_file, "%d\n", ui_next_instruction_address); // il faut sauter après le dernier jump que l'on ajoute par la suite


				while( ( c = fgetc(temp_file) ) != EOF ){
					fputc(c, new_temp_file);
				}

				fclose(temp_file);

				temp_file = new_temp_file;
				
			}
		|if_clause_end 
			{
				Instruction * instruction = pop_instruction(instructions_stack);

				increment_top_if_clauses_nb(if_clauses_nb_stack);

				FILE * new_temp_file = tmpfile();
				rewind(temp_file);
				int c = 0;

				for (long i = 0; i < instruction->l_position; ++i){
					c = fgetc(temp_file);
					fputc(c, new_temp_file);
				}

				fprintf(new_temp_file, "%d\n", ui_next_instruction_address+1); // il faut sauter après le dernier jump que l'on ajoute par la suite


				while( ( c = fgetc(temp_file) ) != EOF ){
					fputc(c, new_temp_file);
				}

				fclose(temp_file);

				temp_file = new_temp_file;

				fprintf(temp_file, "%d:\tJMP ", ui_next_instruction_address);
				push_instruction(instructions_stack, ui_next_instruction_address, ftell(temp_file), false);
				ui_next_instruction_address++;
			}
		 else_structures
		;


else_structures:
		tELSE tIF if_structure_end
		|else_clause
		;

		

if_clause_end:			
					tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS tOPENED_BRACKET
						{
							if ($2 == -1){
								yyerror("Condition du if incorrecte.");
							}else{

								// On supprime un éventuel résultat
								remove_calculation_result(symboles_table, (unsigned int)$2);

								// On souhaite sauter au prochain if si la condition est fausse
								/* JMF @cond @prochain_bloc_conditionnel */
								fprintf(temp_file, "%d:\tJMF %d ", ui_next_instruction_address, $2);

								//  Ajout d'une instruction incomplète
								push_instruction(instructions_stack, ui_next_instruction_address, ftell(temp_file), false);

								ui_next_instruction_address++;
							}
						}
					instruction_list
					tCLOSED_BRACKET
					;

else_clause:		
					tELSE tOPENED_BRACKET
					instruction_list 
					tCLOSED_BRACKET
					;
















/***************************************WHILE*****************************************/


while_structure:	
		tWHILE tOPENED_PARENTHESIS
			{
				// On push prochaine ligne, c'est la qu'il faudra sauter pour reboucler
				push_instruction(instructions_stack, ui_next_instruction_address, ftell(temp_file), true);

			}
		calculation tCLOSED_PARENTHESIS tOPENED_BRACKET
			{	
				// on récupère une éventuelle erreur sur le calcul
				if ($4 == -1){
					yyerror("Condition du while incorrecte.");
				}else{

					// On supprime un éventuel résultat
					remove_calculation_result(symboles_table, (unsigned int)$4);

					
					// JMF @resultat_calcul @fin_du_while
					fprintf(temp_file, "%d:\tJMF %d ", ui_next_instruction_address, $4);

					// Ajout de l'instruction à compléter
					push_instruction(instructions_stack, ui_next_instruction_address, ftell(temp_file), false);

					ui_next_instruction_address++;
				}
			}
		instruction_list tCLOSED_BRACKET
		;
























/*******************************FUNCTION******************************************/

function_call: 
		tID tOPENED_PARENTHESIS
			{
				// Si la fonction $1 n'a pas été déclarée => erreur
				Function * p_used_function = find_function(*functions_table, $1);

				if (p_used_function == NULL){
					yyerror("Utilisation d'une fonction non déclarée.");
				}else{

					// Copie des arguments pour la fonction
					if (p_used_function->return_value){
						ui_called_function_offset_symboles_table_addresses = 2;
					}else{
						ui_called_function_offset_symboles_table_addresses = 1;
					}

				}

			}
		calculation_list_or_nothing tCLOSED_PARENTHESIS
				{
					// Si la fonction $1 n'a pas été déclarée => erreur
					Function * p_used_function = find_function(*functions_table, $1);

					if (p_used_function != NULL){
						if(p_used_function->ui_argument_number != $4){
							// Si le nombre d'argument n'est pas le bon $4 => erreur
							yyerror("Le nombre d'argument donné à la fonction est invalide");
							$$ = -1;

						}else{

							// Suppression des arguments ajoutés par calculation_list_or_nothing
							while(pop_temp_symbole(symboles_table) != NULL);
							ui_called_function_offset_symboles_table_addresses = 0;

							/* INC nombre d'élément dans la pile */
							fprintf(temp_file, "%d:\tINC %d\n", ui_next_instruction_address, get_next_available_symbole_address(*symboles_table, ui_offset_symboles_table_addresses));
							ui_next_instruction_address++;

							/* AFC 0/1 +3 */
							fprintf(temp_file, "%d:\tAFC %d %d\n", ui_next_instruction_address, p_used_function->return_value, ui_next_instruction_address+2);
							ui_next_instruction_address++;


							/* CALL @function */
							fprintf(temp_file, "%d:\tCALL %d\n", ui_next_instruction_address, p_used_function->ui_implementation_address);
							ui_next_instruction_address++;


							/* DEC nombre d'élément dans la pile */
							fprintf(temp_file, "%d:\tDEC %d\n", ui_next_instruction_address, get_next_available_symbole_address(*symboles_table, ui_offset_symboles_table_addresses));
							ui_next_instruction_address++;

							// On retourne l'addresse +1 absolue = 0 en relatif si la fonction à une valeur de retour

							if (p_used_function->return_value){
								printf("pooop : %d\n", get_next_available_symbole_address(*symboles_table, ui_offset_symboles_table_addresses));
								$$ = get_next_available_symbole_address(*symboles_table, ui_offset_symboles_table_addresses);
							}else{
								$$ = -1;
							}
						
						}
					}else{
						$$ = -1;
					}

				}
		;



























/*************************************AFFECTATIONS**********************************/



affection_and_id_list_in_variable_declaration:					
		affectation_in_variable_declaration //pour terminer
		|id_in_affection_and_id_list_in_variable_declaration //pour terminer
		|affectation_in_variable_declaration tCOMMA affection_and_id_list_in_variable_declaration //recursivité
		|id_in_affection_and_id_list_in_variable_declaration tCOMMA affection_and_id_list_in_variable_declaration //recursivité
		;


id_in_affection_and_id_list_in_variable_declaration:					
		tID
			{	
				// On ajoute ce int (non initialisé) à la table des symboles s'il n'a pas encore été déclaré
				Symbole * symbole = find_symbole(*symboles_table, $1);
				if(symbole == NULL && const_declaration_context == 0){
					symbole = add_symbole(symboles_table, ui_offset_symboles_table_addresses, $1, false, false);
				}else if(const_declaration_context){
					yyerror("Déclaration d'une constante non initialisée impossible.");
				}else {
					yyerror("Non initialized int declaration impossible because its name is already used.");
				}
			}
		;



affectation_in_variable_declaration:
		tID tEQUAL calculation 
			{	

				// On supprime un éventuel résultat
				remove_calculation_result(symboles_table, (unsigned int)$3);

				Symbole * symbole = find_symbole(*symboles_table, $1); /* on cherche un symbole qui a le nom tID */

				if(symbole != NULL){ /* si le symbole/la variable existe déjà */
					yyerror("Declaration impossible because name already in use.");
				}else if($3 == -1){ /* si on a eu une erreur lors du calcul */
					yyerror("Declaration impossible because of a calculation error.");
				}else{
					Symbole * symbole = add_symbole(symboles_table, ui_offset_symboles_table_addresses, $1, const_declaration_context, true); /* on ajoute le symbole à la table des symboles */
					if (symbole->ui_address != $3){ /* si le resultat de notre calcul se trouve déjà à l'emplacement réservé à notre variable, pas besoin de copie */
						fprintf(temp_file, "%d:\tCOP %d %d\n", ui_next_instruction_address, symbole->ui_address, $3);
						ui_next_instruction_address++;
					}
				}

			}
		;













affectation_list_instruction:							
		affectation_in_affectation_list_instruction 
		|affectation_in_affectation_list_instruction tCOMMA affectation_list_instruction
		;


affectation_in_affectation_list_instruction:
		id_in_affectation_in_affectation_list_instruction tEQUAL calculation_value
			{
				if($1 == -1){ /* on affecte bien sur un int qui existe */
					yyerror("Affectation impossible.");
					$$ = -1;
				}else{
					fprintf(temp_file, "%d:\tAFC %d %d\n", ui_next_instruction_address, $1, $3);
					ui_next_instruction_address++;
					$$ = $1;
				}
				
			}

		|id_in_affectation_in_affectation_list_instruction tEQUAL calculation operator calculation
			{
				// on vérifie qu'il n'y ait pas d'erreur sur aucune des opérande
		   			if ($1 == -1){
		   				yyerror("Affectation impossible.");
		   				$$ = -1;

		   			}else if(($3 == -1) || ($5 == -1)){
		   				yyerror("Erreur sur calcul.");
		   				$$ = -1;
		   			}else{

		   				// On supprime d'éventuel résultat de calcul au sommet de la pile
		   				remove_calculation_result(symboles_table, (unsigned int)$5);
		   				remove_calculation_result(symboles_table, (unsigned int)$3);
		   				
		   				// On crée la commande assembleur
		   				fprintf(temp_file, "%d:\t%s %d %d %d\n", ui_next_instruction_address, $4, $1, $3, $5);
		   				ui_next_instruction_address++;
		   				
		   				// on retourne l'addresse ou est stocké le résultat de l'opération
		   				$$ = $1;

		   			}
				
			}


		|id_in_affectation_in_affectation_list_instruction tEQUAL tMINUS calculation
			{
		   			// On vérifie que calculation nous a pas retourné une erreur
		   			if($1 == -1){
		   				yyerror("Affectation impossible.");
		   				$$ = -1;
		   			}else if ($4 == -1){
		   				yyerror("Erreur sur calcul.");
		   				$$ = -1;
		   			}else{
		   				// On supprime le résultat éventuel au sommet de la table des symboles
		   				Symbole * calculation_result_symbole = remove_calculation_result(symboles_table, (unsigned int)$4);
		   				int afc_zero_address;

		   				// On crée un symbole temporaire pour le resultat
		   				Symbole * tmp_symbole = push_temp_symbole(symboles_table, ui_offset_symboles_table_addresses+ui_called_function_offset_symboles_table_addresses);


		   				// S'il le résultat était au sommet de la table des symboles
		   				if (calculation_result_symbole != NULL){
		   					afc_zero_address = get_next_available_symbole_address(*symboles_table, ui_offset_symboles_table_addresses+ui_called_function_offset_symboles_table_addresses);
		   				}else{
		   					afc_zero_address = tmp_symbole->ui_address;
		   				}

		   				// On écrit des instructions assembleur
		   				fprintf(temp_file, "%d:\tAFC %d 0\n", ui_next_instruction_address, afc_zero_address);
		   				ui_next_instruction_address++;
		   				fprintf(temp_file, "%d:\tSOU %d %d %d\n", ui_next_instruction_address, $1, afc_zero_address, $4);
		   				ui_next_instruction_address++;

		   				pop_temp_symbole(symboles_table);

		   				// On retourne l'addresse du résultat du calcul
		   				$$ = $1;

		   			}
				
			}


		|id_in_affectation_in_affectation_list_instruction tEQUAL calculation 
			{ 

				// On supprime un éventuel résultat
				remove_calculation_result(symboles_table, (unsigned int)$3);

				if(($3 == -1) || ($1 == -1)){ 
					yyerror("Affectation impossible.");
					$$ = -1;
				}else{ /* on a un résultat de calcul et on affecte bien sur un int qui existe */
					fprintf(temp_file, "%d:\tCOP %d %d\n", ui_next_instruction_address, $1, $3);
					ui_next_instruction_address++;
					$$ = $1;
				}

			}
		;




id_in_affectation_in_affectation_list_instruction: 
		tID
			{
				Symbole * symbole = find_symbole(*symboles_table, $1);
				
				if(symbole == NULL){
					yyerror("Utilisation d'une variable non déclarée.");
					$$ = -1;
				}else if(symbole->b_constant == true){
					yyerror("Affectation pour une constante impossible.");
					$$ = -1;
				}else{
					if (symbole->b_initialised == false){
						symbole->b_initialised = true;
					}
					$$ = symbole->ui_address;
				}

			}
		;


























/**********************************MATH*************************************/


operator: 										
		tADD { $$ = "ADD"; }
		|tMINUS { $$ = "SOU"; }
		|tMUL { $$ = "MUL"; }
		|tDIV { $$ = "DIV"; }
		|tEQUAL tEQUAL { $$ = "EQU"; }
		|tLOWERTHAN { $$ = "INF"; }
		|tGREATERTHAN { $$ = "SUP"; }
		;


calculation_variable: 			   				
		tID { $$ = $1; }
		|tADD tID { $$ = $2; }
		;


integer:										
		tINTEGER_DEC_FORM { $$ = $1; }
		| tINTEGER_EXP_FORM { $$ = $1; }
		;

calculation_value:		 						
		integer { $$ = $1; }
		|tADD integer { $$ = $2; }
		;


calculation_list_or_nothing: 
		/* nothing */
			{
				$$ = 0;
			}
		|calculation_list
			{
				$$ = $1;
			}
		;

calculation_list:
		calculation_in_calculation_list
			{
				$$ = 1;
			}
		|calculation_in_calculation_list tCOMMA calculation_list
			{
				$$ = 1 + $3;
			}
		;


calculation_in_calculation_list: 
		calculation
			{

				if($1 == -1){
					yyerror("Erreur sur calcul.");
				}else{

					// on supprime un éventuel résultat de calcul au sommet de la table des symboles
					Symbole * calculation_result_symbole = remove_calculation_result(symboles_table, (unsigned int)$1);

					// on crée un espace pour l'argument de la fonction qui va être appellé
					Symbole * tmp_symbole = push_temp_symbole(symboles_table, ui_offset_symboles_table_addresses+ui_called_function_offset_symboles_table_addresses);

					// Si le résultat du calcul n'est pas bien placé il faut faire un COP pour le placer au bon endroit
					if($1 != tmp_symbole->ui_address){
						fprintf(temp_file, "%d:\tCOP %d %d\n", ui_next_instruction_address, tmp_symbole->ui_address, $1);
						ui_next_instruction_address++;
		   			}
				
				}

			}
		;




calculation: 									
		calculation_variable
			{
				// On vérifie que la variable existe bien
				Symbole * symbole = find_symbole(*symboles_table, $1);

				// Si elle n'existe pas on génère une erreur
				if(symbole == NULL){
					yyerror("Utilisation d'une variable non déclarée !");
					$$ = -1;

				// Si elle n'est pas initialisée on génère une erreur également
				}else if(symbole->b_initialised == false){
					yyerror("Utilisation d'une variable non initialisée !");
					$$ = -1;

				// Sinon on retourne son adresse
				}else{
					$$ = symbole->ui_address;
				}
			}

		|calculation_value
			{
				// On ajoute une variable temporaire pour stocker le résultat du calcul
				Symbole * tmp_symbole = push_temp_symbole(symboles_table, ui_offset_symboles_table_addresses+ui_called_function_offset_symboles_table_addresses);
				
				// On crée la commande assembleur
				fprintf(temp_file, "%d:\tAFC %d %d\n", ui_next_instruction_address, tmp_symbole->ui_address, $1);
				ui_next_instruction_address++;

				// On retourne l'adresse ou est stocké le résultat de l'opération
				$$ = tmp_symbole->ui_address;
			}

			|tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS
				{
					// On retourne l'adresse ou est stocké le résultat de calculation
					$$ = $2;
				}
			|calculation operator calculation 
		   		{
		   			// on vérifie qu'il n'y ait pas d'erreur sur aucune des opérande
		   			if (($1 == -1) || ($3 == -1)){
		   				yyerror("Erreur sur calcul.");
		   				$$ = -1;

		   			}else{

		   				// On supprime d'éventuel résultat de calcul au sommet de la pile
		   				remove_calculation_result(symboles_table, (unsigned int)$3);
		   				remove_calculation_result(symboles_table, (unsigned int)$1);
		   			
		   				
		   				
		   				// On ajoute une variable temporaire pour stocker le résultat du calcul
		   				Symbole * tmp_symbole = push_temp_symbole(symboles_table, ui_offset_symboles_table_addresses+ui_called_function_offset_symboles_table_addresses); /* on ajoute une variable temporaire pour stocker le résultat */
		   				
		   				// On crée la commande assembleur
		   				fprintf(temp_file, "%d:\t%s %d %d %d\n", ui_next_instruction_address, $2, tmp_symbole->ui_address, $1, $3);
		   				ui_next_instruction_address++;
		   				
		   				// on retourne l'addresse ou est stocké le résultat de l'opération
		   				$$ = tmp_symbole->ui_address;

		   			}
		   		}
			|tMINUS calculation
		   		{
		   			// On vérifie que calculation nous a pas retourné une erreur
		   			if ($2 == -1){
		   				yyerror("Erreur sur calcul.");
		   				$$ = -1;

		   			}else{
		   				// On supprime le résultat éventuel au sommet de la table des symboles
		   				Symbole * calculation_result_symbole = remove_calculation_result(symboles_table, (unsigned int)$2);
		   				int afc_zero_address;

		   				// On crée un symbole temporaire pour le resultat
		   				Symbole * tmp_symbole = push_temp_symbole(symboles_table, ui_offset_symboles_table_addresses+ui_called_function_offset_symboles_table_addresses);


		   				// S'il le résultat était au sommet de la table des symboles
		   				if (calculation_result_symbole != NULL){
		   					afc_zero_address = get_next_available_symbole_address(*symboles_table, ui_offset_symboles_table_addresses+ui_called_function_offset_symboles_table_addresses);
		   				}else{
		   					afc_zero_address = tmp_symbole->ui_address;
		   				}

		   				// On écrit des instructions assembleur
		   				fprintf(temp_file, "%d:\tAFC %d 0\n", ui_next_instruction_address, afc_zero_address);
		   				ui_next_instruction_address++;
		   				fprintf(temp_file, "%d:\tSOU %d %d %d\n", ui_next_instruction_address, tmp_symbole->ui_address, afc_zero_address, $2);
		   				ui_next_instruction_address++;

		   				// On retourne l'addresse du résultat du calcul
		   				$$ = tmp_symbole->ui_address;

		   			}	
			}
		|function_call
			{
				if ($1 == -1){
					yyerror("Cette fonction ne retourne rien, impossible de l'utiliser dans des calculs.");
					$$ = -1;
				}else{
					Symbole * tmp_symbole = push_temp_symbole(symboles_table, ui_offset_symboles_table_addresses+ui_called_function_offset_symboles_table_addresses);
					$$ = $1;
				}
			}
			;




%%


















int main(int argc, char *argv[]){


	/******************************** Argument handeling ********************************/


	int oc;	/* option character */
	char * output_file_name = NULL; /* space to store output file name pointer */
	opterr= 0; /* disable default error messages */

	while ((oc = getopt(argc, argv, ":ho:")) != -1) {
		switch (oc) {
			case 'o':
				output_file_name = optarg;
			break;
			case 'h':
				display_help();
				exit(EXIT_SUCCESS);
			break;
			case ':':
				printf("%s : option '-%c' requires an argument -> ignored.\n", argv[0], optopt); /* missing option argument */
				break;
		    case '?':
				if (isprint (optopt))
					printf ("%s : unknown option `-%c' -> ignored.\n", argv[0], optopt);
		        else
					printf ("%s : unknown option character `\\x%x' -> ignored.\n", argv[0], optopt);
				break;
		    default:
		        printf("%s : option '-%c' is invalid -> ignored\n", argv[0], optopt); /* invalid option */
		}
	}


	if(optind != argc - 1){
		printf("%s : compilation failed | nombre d'argument invalide.\n", argv[0]);
	}else{

		if (output_file_name == NULL){
			output_file_name = strdup("a.out");
		}


		/******************************** Création/ouverture des fichiers nécessaires ********************************/

		yyin = fopen(argv[optind], "r");
		if (yyin == NULL){
			printf("%s : compilation failed | impossible d'ouvrir le fichier %s\n", argv[0], argv[optind]);
			exit(EXIT_FAILURE);
		}

		temp_file = tmpfile();

		if (temp_file == NULL){
			printf("%s : compilation failed | impossible de créer un fichier temporaire.\n", argv[0]);
			exit(EXIT_FAILURE);
		}

		symboles_table = create_symboles_table(); /* initialisation de la table des symboles */
		functions_table = create_functions_table();  /* initialisation de la table des functions */
		instructions_stack = create_instructions_stack(); /* initialisation de la pile utilisé pour traduire les structures en asm */
		if_clauses_nb_stack = create_if_clauses_nb_stack(); /* initialisation de la pile utilisé pour traduire les structures en asm */


		/***************************************** Compilation ********************************************/


		switch (yyparse()){
			case 0 : /* Parsing was successfull */

			 if (ui_compilation_errors_nb != 0){
			 	printf("%s : compilation failed | %d errors.\n", argv[0], ui_compilation_errors_nb);
			 	exit(EXIT_FAILURE);
			 }

			 /************************* Copie du contenu du fichier temporaire dans le fichier de sortie **************************/

			 FILE * output_file = fopen(output_file_name, "w+");
			 int c; 

			 if(output_file == NULL){
			 	fclose(temp_file);
			    printf("%s : compilation failed | an error occured when creating output file.\n", argv[0]);
			    exit(EXIT_FAILURE);
			 }

			 rewind(temp_file);
			 while( ( c = fgetc(temp_file) ) != EOF ){
			 	fputc(c, output_file);
			 }
			 
			 printf("%s : compilation success | tempFile properly copied into output file.\n", argv[0]);

			 fclose(temp_file);
			 fclose(output_file);

			 printf("Table des symboles du main:\n");
			 print_symboles_table(*symboles_table);

			 printf("\n");

			 printf("Table des functions :\n");
			 print_symboles_table(*functions_table);

			 break;

			case 1 :
			 printf("%s : Parsing failed because of invalid input !!\n", argv[0]);
			 break;

			case 2 :
			 printf("%s : Parsing failed due to memory exhaustion !! \n", argv[0]);
			 break;

			default: 
			 printf("%s : Parsing failed due to an unknown error !!\n", argv[0]);
		}

		fclose(yyin);

	}
	

    return 0;
}


void display_help(){
	printf("usage: g-- [options] [source.c]\n");
	printf("options: -o output_file_name.asm\n");
	printf("         -h (for help)\n");
}


void yyerror(char const *s) {

	// Si c'est la première erreur de compilation
	if (ui_compilation_errors_nb == 0){
		// On prends la décision de ne plus écrire dans le fichier temporaire car aucun fichier ne sera généré en sortie
		//fclose(temp_file);
	}
	ui_compilation_errors_nb++;

	// On affiche un message d'erreur
	printf("%d : %s\n", yylineno, s);
}







