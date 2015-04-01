%{
	#include <stdlib.h>
	#include <stdio.h>
	#include <unistd.h>
	#include <string.h>
	#include <ctype.h>
	#include <stdbool.h>
	#include "Symboles_table/Symboles_table.h"
	#include "Instructions_stack/Instructions_stack.h"
	int yylex(void);
	void yyerror (char const *msg);
	extern FILE *yyin;
	FILE * temp_file;
	extern int yylineno;
	llist * symboles_table;
	llist * instructions_stack;
	unsigned int ui_next_instruction_address = 0;
	unsigned int ui_compilation_errors_nb = 0;
	unsigned int ui_if_clause_nb = 0;
%}

%union { int nb; char * var; }

%token tMAIN tPRINTF tNEWLINE
%token tOPENED_BRACKET tCLOSED_BRACKET tOPENED_PARENTHESIS tCLOSED_PARENTHESIS
%token tIF tELSE tWHILE
%token tCOMMA tSEMICOLON
%token tCONST tINT 
%token tADD tMINUS tMUL tDIV tEQUAL
%token tGREATERTHAN tLOWERTHAN tNOT
%token tINTEGER_EXP_FORM tINTEGER_DEC_FORM
%token tID
%token tERROR

%type <nb> tINTEGER_EXP_FORM tINTEGER_DEC_FORM calculation_value integer calculation 
%type <nb> affectation_in_affection_and_id_list_declaration
%type <nb> affectation_in_affectation_list_declaration
%type <nb> affectation_in_affectation_list_instruction id_in_affectation_in_affectation_list_instruction
%type <var> tID calculation_variable operator


%left tADD tMINUS
%left tMUL tDIV

%start start

%%

/**********************************PROGRAM*************************************/

start:											declaration_list main
												;



/**********************************MAIN***************************************/

main:											tINT tMAIN tOPENED_PARENTHESIS tCLOSED_PARENTHESIS tOPENED_BRACKET 
													{ 
														fprintf(temp_file, "main :\n"); 
													}
												declaration_list instruction_list 
												tCLOSED_BRACKET
												;




/*******************************DECLARATIONS**********************************/


declaration_list:								/* Nothing */
												|declaration_list declaration 
												;


declaration:									declaration_constante 
												|declaration_integer 
			 									;


declaration_constante:							tCONST tINT affectation_list_declaration tSEMICOLON	
												;


declaration_integer:							tINT affection_and_id_list_declaration tSEMICOLON
												;










/*******************************INSTRUCTIONS**********************************/


instruction_list:								
					/* Nothing */
					|instruction instruction_list
					;


instruction:									
					affectation_list_instruction tSEMICOLON
					|if_structure
						{
							for (unsigned int i = ui_if_clause_nb; i > 0; --i){
		
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
							Instruction * instruction = pop_instruction(instructions_stack);

							//On place le curseur au bon endroit
							if(fseek (temp_file, instruction->l_position, SEEK_SET)){
								printf("fseek error\n");
							}


							FILE * new_temp_file = tmpfile();
							rewind(temp_file);
							int c = 0;
							for (long i = 0; i < instruction->l_position; ++i){
								c = fgetc(temp_file);
								fputc(c, new_temp_file);
							}

							fprintf(new_temp_file, "%d\n", ui_next_instruction_address+1); // il faut sauter après le dernier jump pour poursuivre

							while( ( c = fgetc(temp_file) ) != EOF ){
								fputc(c, new_temp_file);
							}

							fclose(temp_file);

							temp_file = new_temp_file;

							
							// on revient à la bonne position
							if(fseek (temp_file, 0, SEEK_END)){
								printf("fseek error\n");
							}

							//saut inconditionnel en haut de la condition du while
							
							fprintf(temp_file, "%d:\tJMP %d\n", ui_next_instruction_address, instruction->ui_address);
							ui_next_instruction_address++;

						}
					|tPRINTF tOPENED_PARENTHESIS calculation_variable tCLOSED_PARENTHESIS tSEMICOLON
						{	
							Symbole * symbole = find_symbole(*symboles_table, $3);
							if(symbole == NULL){
								yyerror("Utilisation d'une variable non déclarée !");
							}else if(symbole->initialised == false){
								yyerror("Utilisation d'une variable non initialisée !");
							}else{
								fprintf(temp_file, "%d:\tPRI %d\n", ui_next_instruction_address, symbole->id);
								ui_next_instruction_address++;
							}
						}
					;





/***************************************IF*****************************************/




if_structure:		
					if_clause
						{
							Instruction * instruction = pop_instruction(instructions_stack);

							FILE * new_temp_file = tmpfile();
							rewind(temp_file);
							int c = 0;
							for (long i = 0; i < instruction->l_position; ++i){
								c = fgetc(temp_file);
								fputc(c, new_temp_file);
							}

							fprintf(new_temp_file, "%d\n", ui_next_instruction_address); // il faut sauter après la dernière instruction

							while( ( c = fgetc(temp_file) ) != EOF ){
								fputc(c, new_temp_file);
							}

							fclose(temp_file);

							temp_file = new_temp_file;
						}

					|if_clause 
						{
							ui_if_clause_nb++;

							Instruction * instruction = pop_instruction(instructions_stack);


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
							ui_next_instruction_address++;
							push_instruction(instructions_stack, ui_next_instruction_address, ftell(temp_file), false);
						}
					 else_structure
					;


else_structure:
					tELSE if_structure
					|else_clause
					;

if_clause:			
					tIF tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS tOPENED_BRACKET
						{
							pop_temp_symbole(symboles_table); /* on dépile le résultat du calcul s'il existe */
							if ($3 == -1){
								yyerror("Condition du if incorrecte.");
							}else{
								fprintf(temp_file, "%d:\tJMF %d ", ui_next_instruction_address, $3); /* on souhaite sauter au prochain if si la condition est fausse */
								ui_next_instruction_address++; /* on aura une instruction jump conditionnel ici */
								push_instruction(instructions_stack, ui_next_instruction_address, ftell(temp_file), false); /* ajout d'une instruction incomplète */
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
							//on push prochaine ligne, c'est la qu'il faudra sauter pour reboucler
							push_instruction(instructions_stack, ui_next_instruction_address + 1, ftell(temp_file), true);

						}
					calculation tCLOSED_PARENTHESIS tOPENED_BRACKET
						{	
							pop_temp_symbole(symboles_table); /* on supprime le résultat du calcul s'il existe */

							if ($4 == -1){
								yyerror("Condition du while incorrecte.");
							}else{
								push_instruction(instructions_stack, ui_next_instruction_address, ftell(temp_file), false);
								fprintf(temp_file, "%d:\tJMF %d ", ui_next_instruction_address, $4);
								ui_next_instruction_address++; /* on aura une instruction jump conditionnel ici */
							}
						}
					instruction_list tCLOSED_BRACKET
					;



/*************************************AFFECTATIONS**********************************/


affection_and_id_list_declaration:					
					affectation_in_affection_and_id_list_declaration //pour terminer
					|id_in_affection_and_id_list_declaration //pour terminer
					|affectation_in_affection_and_id_list_declaration tCOMMA affection_and_id_list_declaration //recursivité
					|id_in_affection_and_id_list_declaration tCOMMA affection_and_id_list_declaration //recursivité
					;




id_in_affection_and_id_list_declaration:					
					tID
						{	
							// On ajoute ce int (non initialisé) à la table des symboles s'il n'a pas encore été déclaré
							Symbole * symbole = find_symbole(*symboles_table, $1);
							if(symbole == NULL){
								symbole = add_symbole(symboles_table, $1, false, false);
							}else {
								yyerror("Non initialized int declaration impossible because its name is already used.");
							}
						}
					;



affectation_in_affection_and_id_list_declaration:
					tID tEQUAL calculation_value
						{
							Symbole * symbole = find_symbole(*symboles_table, $1);

							if(symbole != NULL){
								yyerror("initialized int declaration impossible because its name is already used.");
							}else {
								Symbole * symbole = add_symbole(symboles_table, $1, false, true);
								fprintf(temp_file, "%d:\tAFC %d %d\n", ui_next_instruction_address, symbole->id, $3);
								ui_next_instruction_address++;
							}	
						} 			
					|tID tEQUAL calculation 
						{	
							pop_temp_symbole(symboles_table);
							Symbole * symbole = find_symbole(*symboles_table, $1);

							if(symbole != NULL){
								yyerror("initialized int declaration impossible because its name is already used.");
							}else if($3 == -1){
								yyerror("int initializion failed.");
							}else{
								Symbole * symbole = add_symbole(symboles_table, $1, false, true);
								if (symbole->id != $3){
									fprintf(temp_file, "%d:\tCOP %d %d\n", ui_next_instruction_address, symbole->id, $3);
									ui_next_instruction_address++;
								}
							}

						}
					;








affectation_list_declaration:							
					affectation_in_affectation_list_declaration
					|affectation_in_affectation_list_declaration tCOMMA affectation_list_declaration
					;


affectation_in_affectation_list_declaration:
					tID tEQUAL calculation_value
						{
							Symbole * symbole = find_symbole(*symboles_table, $1); /* on cherche un symbole qui a le nom tID */

							if(symbole != NULL){ /* si le symbole/la variable existe déjà */
								yyerror("const int declaration impossible because its name is already used.");

							}else {
								Symbole * symbole = add_symbole(symboles_table, $1, true, true); /* on ajoute le symbole à la table des symboles */
								fprintf(temp_file, "%d:\tAFC %d %d\n", ui_next_instruction_address, symbole->id, $3);
								ui_next_instruction_address++;
							}
							
						}
					|tID tEQUAL calculation 
						{	
							pop_temp_symbole(symboles_table); /* on dépile au cas où l'on aurait un résultat de calcul au sommet de la pile */
							Symbole * symbole = find_symbole(*symboles_table, $1); /* on cherche un symbole qui a le nom tID */

							if(symbole != NULL){ /* si le symbole/la variable existe déjà */
								yyerror("const int declaration impossible because its name is already used.");
							}else if($3 == -1){ /* si on a eu une erreur lors du calcul */
								yyerror("const int declaration impossible because of a calculation error.");
							}else {
								Symbole * symbole = add_symbole(symboles_table, $1, true, true); /* on ajoute le symbole à la table des symboles */

								if (symbole->id != $3){ /* si le resultat de notre calcul se trouve déjà à l'emplacement réservé à notre variable, pas besoin de copie */
									
									fprintf(temp_file, "%d:\tCOP %d %d\n", ui_next_instruction_address, symbole->id, $3);
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
								printf("Affectation impossible.\n");
								$$ = -1;
							}else{
								fprintf(temp_file, "%d:\tAFC %d %d\n", ui_next_instruction_address, $1, $3);
								ui_next_instruction_address++;
								$$ = $1;
							}
							
						}

					|id_in_affectation_in_affectation_list_instruction tEQUAL calculation 
						{ 
							pop_temp_symbole(symboles_table);
							if(($3 == -1) || ($1 != -1)){ 
								printf("Affectation impossible.\n");
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
							}else if(symbole->constant == true){
								yyerror("Affectation pour une constante impossible.");
								$$ = -1;
							}else{
								if (symbole->initialised == false){
									symbole->initialised = true;
								}
								$$ = symbole->id;
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




calculation: 									
					calculation_variable
						{
							Symbole * symbole = find_symbole(*symboles_table, $1);
							if(symbole == NULL){
								yyerror("Utilisation d'une variable non déclarée !");
								$$ = -1;
							}else if(symbole->initialised == false){
								yyerror("Utilisation d'une variable non initialisée !");
								$$ = -1;
							}else{
								$$ = symbole->id;
							}
						}

					|calculation_value
						{
							//On push le symbole !!!!
							Symbole * tmp_symbole = push_temp_symbole(symboles_table);
							fprintf(temp_file, "%d:\tAFC %d %d\n", ui_next_instruction_address, tmp_symbole->id, $1);
							ui_next_instruction_address++;
							//tmp_symbole = pop_temp_symbole(symboles_table);
							$$ = tmp_symbole->id;
						}

		 			|tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS
		 				{
		 					$$ = $2;
		 				}
		 			|calculation operator calculation 
		 		   		{
		 		   			if (($1 == -1) || ($3 == -1)){
		 		   				yyerror("Erreur sur calcul.");
		 		   				$$ = -1;
		 		   			}else{
		 		   				while(pop_temp_symbole(symboles_table) != NULL); /* on vide la pile d'éventuelle variable temporaires */
		 		   				Symbole * tmp_symbole = push_temp_symbole(symboles_table); /* on ajoute une variable temporaire pour stocker le résultat */
		 		   				fprintf(temp_file, "%d:\t%s %d %d %d\n", ui_next_instruction_address, $2, tmp_symbole->id, $1, $3);
		 		   				ui_next_instruction_address++;
		 		   				$$ = tmp_symbole->id;
		 		   			}
		 		   		}
		 			|tMINUS calculation
		 		   		{
		 		   			if ($2 == -1){
		 		   				yyerror("Erreur sur calcul.");
		 		   				$$ = -1;
		 		   			}else{
		 		   				Symbole * tmp_symbole = find_symbole(*symboles_table, DEFAULT_TEMP_SYMBOLE_NAME);
		 		   				Symbole * tmp_symbole_top = push_temp_symbole(symboles_table);
		 		   				// Si on est sur le résultat de calculation il faut enpiler encore une fois pour ne pas écraser des données
		 		   				if (tmp_symbole != NULL){
		 		   					fprintf(temp_file, "%d:\tAFC %d 0\n", ui_next_instruction_address, tmp_symbole_top->id);
		 		   					ui_next_instruction_address++;
		 		   					fprintf(temp_file, "%d:\tSOU %d %d %d\n", ui_next_instruction_address, tmp_symbole->id, tmp_symbole_top->id, tmp_symbole->id);
		 		   					ui_next_instruction_address++;
		 		   					tmp_symbole_top = pop_temp_symbole(symboles_table);
		 		   					$$ = tmp_symbole->id;
		 		   				}else{
		 		   					fprintf(temp_file, "%d:\tAFC %d 0\n", ui_next_instruction_address, tmp_symbole_top->id);
		 		   					ui_next_instruction_address++;
		 		   					fprintf(temp_file, "%d:\tSOU %d %d %d\n", ui_next_instruction_address, tmp_symbole_top->id, tmp_symbole_top->id, $2);
		 		   					ui_next_instruction_address++;
		 		   					$$ = tmp_symbole_top->id;
		 		   				}

		 		   			}	
						}
		 			;




%%



void display_help(){
	printf("usage: g-- [options] source.c\n");
	printf("options: -o output_file_name.asm\n");
}

int main(int argc, char *argv[]){


	/******************************** Argument handeling ********************************/


	int oc;	/* option character */
	char * output_file_name = NULL; /* space to store output file name pointer */
	opterr= 0; /* disable default error messages */

	while ((oc = getopt(argc, argv, ":o:")) != -1) {
		switch (oc) {
			case 'o':
				output_file_name = optarg;
			break;
			case ':':
				printf("%s : option '-%c' requires an argument\n", argv[0], optopt); /* missing option argument */
				break;
		    case '?':
				if (isprint (optopt))
					printf ("%s : unknown option `-%c'.\n", argv[0], optopt);
		        else
					printf ("%s : unknown option character `\\x%x'.\n", argv[0], optopt);
				break;
		    default:
		        printf("%s : option '-%c' is invalid: ignored\n", argv[0], optopt); /* invalid option */
		}
	}


	if(optind != argc - 1){
		printf("%s : nombre d'argument invalide.\n", argv[0]);
		display_help();
	}else{

		if (output_file_name == NULL){
			output_file_name = strdup("a.out");
		}


		/******************************** Création/ouverture des fichiers nécessaires ********************************/

		yyin = fopen(argv[optind], "r");
		if (yyin == NULL){
			printf("%s : impossible d'ouvrir le fichier %s\n", argv[0], argv[optind]);
			exit(EXIT_FAILURE);
		}

		temp_file = tmpfile();

		if (temp_file == NULL){
			printf("%s : impossible de créer un fichier temporaire.\n", argv[0]);
			exit(EXIT_FAILURE);
		}

		symboles_table = create_symboles_table(); /* initialisation de la table des symboles */
		instructions_stack = create_instructions_stack(); /* initialisation de la pile utilisé pour traduire les structures en asm */



		/***************************************** Compilation ********************************************/


		switch (yyparse()){
			case 0 :
			 //Parsing was sucessfull 
			 if (ui_compilation_errors_nb != 0){
			 	printf("compilation failed | %d errors.\n", ui_compilation_errors_nb);
			 	exit(EXIT_FAILURE);
			 }

			 /************************* Copie du contenu du fichier temporaire dans le fichier de sortie **************************/

			 FILE * output_file = fopen(output_file_name, "w+");
			 int c; 

			 if(output_file == NULL){
			 	fclose(temp_file);
			    printf("compilation failed | an error occured when creating output file.\n");
			    exit(EXIT_FAILURE);
			 }

			 rewind(temp_file);
			 while( ( c = fgetc(temp_file) ) != EOF ){
			 	fputc(c, output_file);
			 }
			 
			 printf("compilation success | tempFile properly copied into output file.\n");

			 fclose(temp_file);
			 fclose(output_file);

			 printf("Table des symboles :\n");
			 print_symboles_table(*symboles_table);
			 break;

			case 1 :
			 printf("Parsing failed because of invalid input !!\n");
			 break;

			case 2 :
			 printf("Parsing failed due to memory exhaustion !! \n");
			 break;

			default: 
			 printf("Parsing failed due to an unknown error !!\n");
		}

		fclose(yyin);

	}
	

    return 0;
}


// int fprintf( FILE * fic,const char * format [argument,...]);



void yyerror(char const *s) {
	if (ui_compilation_errors_nb == 0){
		fclose(temp_file);
	}
	ui_compilation_errors_nb++;
	printf("%d : %s\n", yylineno, s);
}







