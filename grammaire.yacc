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
	unsigned int ui_current_instruction_number = 0;
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

%type <nb> tINTEGER_EXP_FORM tINTEGER_DEC_FORM calculation_value integer 
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

								fprintf(new_temp_file, "%d\n", ui_current_instruction_number+1); // il faut sauter après le dernier jump pour poursuivre

								while( ( c = fgetc(temp_file) ) != EOF ){
									fputc(c, new_temp_file);
								}

								fclose(temp_file);

								temp_file = new_temp_file;


							}

							// on revient à la bonne position
							if(fseek (temp_file, 0, SEEK_END)){
								printf("fseek error\n");
							}
						}
					|while_structure
						{
							Instruction * instruction = pop_instruction(instructions_stack);

							ui_current_instruction_number++;
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

							fprintf(new_temp_file, "%d\n", ui_current_instruction_number+1); // il faut sauter après le dernier jump pour poursuivre

							while( ( c = fgetc(temp_file) ) != EOF ){
								fputc(c, new_temp_file);
							}

							fclose(temp_file);

							temp_file = new_temp_file;

							
								// on revient à la bonne position
							if(fseek (temp_file, 0, SEEK_END)){
								printf("fseek error\n");
							}

							instruction = pop_instruction(instructions_stack);
							//saut inconditionnel en haut de la condition du while
							
							fprintf(temp_file, "JMP %d\n", instruction->ui_number);

						}
					|tPRINTF tOPENED_PARENTHESIS tID tCLOSED_PARENTHESIS tSEMICOLON
						{	
							Symbole * symbole = find_symbole(*symboles_table, $3);
							if(symbole == NULL){
								yyerror("Utilisation d'une variable non déclarée !");
							}else if(symbole->initialised == false){
								yyerror("Utilisation d'une variable non initialisée !");
							}else{
								fprintf(temp_file, "\tPRI @%d\n", symbole->id);
								ui_current_instruction_number++;
							}
						}
					;





/***************************************IF*****************************************/




if_structure:		
					if_clause
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

							fprintf(new_temp_file, "%d\n", ui_current_instruction_number+1); // il faut sauter après le dernier jump pour poursuivre

							while( ( c = fgetc(temp_file) ) != EOF ){
								fputc(c, new_temp_file);
							}

							fclose(temp_file);

							temp_file = new_temp_file;

							
							// on revient à la bonne position
							if(fseek (temp_file, 0, SEEK_END)){
								printf("fseek error\n");
							}

							ui_current_instruction_number++;
							fprintf(temp_file, "JMP ");
							push_instruction(instructions_stack, ui_current_instruction_number, ftell(temp_file), false);
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
							// on fait un pop du résultat du calcul
							Symbole * symbole = pop_temp_symbole(symboles_table);
							if (symbole == NULL){
								yyerror("Condition du if incorrecte.");
							}else{
								ui_current_instruction_number++; /* on aura une instruction jump conditionnel ici */
								fprintf(temp_file, "JMF @%d ", symbole->id);
								push_instruction(instructions_stack, ui_current_instruction_number, ftell(temp_file), false);
								// @1 saut si la condition est fausse
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
					while_structure_beginning
					calculation tCLOSED_PARENTHESIS tOPENED_BRACKET
						{	
							// on fait un pop du résultat du calcul
							Symbole * symbole = pop_temp_symbole(symboles_table);
							if (symbole == NULL){
								yyerror("Condition du while incorrecte.");
							}else{
								ui_current_instruction_number++; /* on aura une instruction jump conditionnel ici */
								fprintf(temp_file, "JMF @%d ", symbole->id);
								push_instruction(instructions_stack, ui_current_instruction_number, ftell(temp_file), false);
								// @1 saut si la condition est fausse
							}
						}
					instruction_list tCLOSED_BRACKET
					|while_structure_beginning
					calculation_variable tCLOSED_PARENTHESIS tOPENED_BRACKET
						{	
							Symbole * symbole = find_symbole(*symboles_table, $2);
							if(symbole == NULL){
								yyerror("Utilisation d'une variable non déclarée, condition invalide.");
							}else if(symbole->initialised == false){
								yyerror("Utilisation d'une variable non initialisée, condition invalide.");
							}else{
								ui_current_instruction_number++;
								fprintf(temp_file, "JMF @%d ", symbole->id);
								push_instruction(instructions_stack, ui_current_instruction_number, ftell(temp_file), false);
							}


						}
					instruction_list 
					tCLOSED_BRACKET
					;


while_structure_beginning:	
					tWHILE tOPENED_PARENTHESIS
						{
							//on push prochaine ligne, c'est la qu'il faudra sauter pour reboucler
							push_instruction(instructions_stack, ui_current_instruction_number + 1, ftell(temp_file), true);

						}
					;


/*******************************AFFECTATIONS**********************************/


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
							add_symbole(symboles_table, $1, false, false);
						}else {
							yyerror("Déclaration d'un int déjà déclarée.");
						}
					}
					;




affectation_in_affection_and_id_list_declaration:			
					tID tEQUAL calculation 
					{	

						// On regarde si calcul a bien généré un résultat
						// Il doit se retrouver au sommet de la pile avec comme nom DEFAULT_TEMP_SYMBOLE_NAME
						Symbole * symbole = pop_temp_symbole(symboles_table);

						if(symbole != NULL){
							// on a  un résultat

							// On ajoute ce int (initialisé) à la table des symboles s'il n'a pas encore été déclaré
							// on le met à l'addresse de la varibale temporere du résultat
							Symbole * new_symbole = find_symbole(*symboles_table, $1);
							if(new_symbole == NULL){
								//on ajoute ici à la place du résultat du calcul, pas besoin d'instruction asm
								new_symbole = add_symbole(symboles_table, $1, false, true);

								//no asm sinon COP @x @x


							}else {
								yyerror("Déclaration d'un int déjà déclarée.");
							}

						}else {
							yyerror("Affectation impossible car erreur lors du calcul.");
						}

					}

				|tID tEQUAL calculation_value
					{
						// On ajoute ce int (initialisé) à la table des symboles s'il n'a pas encore été déclaré
						Symbole * symbole = find_symbole(*symboles_table, $1);
						if(symbole == NULL){
							symbole = add_symbole(symboles_table, $1, false, true);
							//On copie calculation_value à dans l'espace mémoire qu'on vient d'alouer
							fprintf(temp_file, "AFC @%d %d\n", symbole->id, $3);
							ui_current_instruction_number++;
						}else {
							yyerror("Déclaration d'un int déjà déclarée.");
						}
						
					}

				|tID tEQUAL calculation_variable
					{
						//on vérifie que calculation_variable existe bien
						Symbole * calc_symbole = find_symbole(*symboles_table, $3);
						if(calc_symbole == NULL){
							yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
						}else if(calc_symbole->initialised == false){
							yyerror("Utilisation d'une variable non initialisée, affectation impossible.");
						}else{
							//on teste si tID n'a pas déjà été déclaré
							Symbole * id_symbole = find_symbole(*symboles_table, $1);
							if(id_symbole == NULL){
								//on est bon, il a pas déjà été déclaré
								id_symbole = add_symbole(symboles_table, $1, false, true);
								//On copie la valeur à l'adresse calculation_value à dans l'espace mémoire qu'on vient d'alouer
								fprintf(temp_file, "COP @%d @%d\n", id_symbole->id, calc_symbole->id);
								ui_current_instruction_number++;
							}else{
								yyerror("Déclaration d'un int déjà déclarée.");
							}
						}

					} 
				;










affectation_list_declaration:							
					affectation_in_affectation_list_declaration
					|affectation_in_affectation_list_declaration tCOMMA affectation_list_declaration
					;


affectation_in_affectation_list_declaration:
					tID tEQUAL calculation 
					{	

						// On regarde si calcul a bien généré un résultat
						// Il doit se retrouver au sommet de la pile avec comme nom DEFAULT_TEMP_SYMBOLE_NAME
						Symbole * calc_symbole = pop_temp_symbole(symboles_table);

						if(calc_symbole != NULL){
							// on a  un résultat

							// On ajoute ce const int à la table des symboles s'il n'a pas encore été déclaré
							// on le met à l'addresse de la varibale temporere du résultat
							Symbole * new_symbole = find_symbole(*symboles_table, $1);
							if(new_symbole == NULL){
								//on ajoute ici à la place du résultat du calcul, pas besoin d'instruction asm
								new_symbole = add_symbole(symboles_table, $1, true, true);

							}else {
								yyerror("Déclaration d'un const int déjà déclarée.");
							}

						}else {
							yyerror("Affectation impossible car erreur lors du calcul.");
						}

					}

					|tID tEQUAL calculation_value
						{
							// On ajoute ce const int à la table des symboles s'il n'a pas encore été déclaré
							Symbole * symbole = find_symbole(*symboles_table, $1);
							if(symbole == NULL){
								symbole = add_symbole(symboles_table, $1, true, true);
								//On copie calculation_value à dans l'espace mémoire qu'on vient d'alouer
								fprintf(temp_file, "AFC @%d %d\n", symbole->id, $3);
								ui_current_instruction_number++;
							}else {
								yyerror("Déclaration d'un const int déjà déclarée.");
							}
							
						}

					|tID tEQUAL calculation_variable
						{
							//on vérifie que calculation_variable existe bien
							Symbole * calc_symbole = find_symbole(*symboles_table, $3);
							if(calc_symbole == NULL){
								yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
							}else if(calc_symbole->initialised == false){
								yyerror("Utilisation d'une variable non initialisée, affectation impossible.");
							}else{
								//on teste si tID n'a pas déjà été déclaré
								Symbole * id_symbole = find_symbole(*symboles_table, $1);
								if(id_symbole == NULL){
									//on est bon, il a pas déjà été déclaré
									id_symbole = add_symbole(symboles_table, $1, true, true);
									//On copie la valeur à l'adresse calculation_value à dans l'espace mémoire qu'on vient d'alouer
									fprintf(temp_file, "COP @%d @%d\n", id_symbole->id, calc_symbole->id);
									ui_current_instruction_number++;
								}else{
									yyerror("Déclaration d'un const int déjà déclarée.");
								}
							}

						} 
					;










affectation_list_instruction:							
					affectation_in_affectation_list_instruction 
					|affectation_in_affectation_list_instruction tCOMMA affectation_list_instruction
					;


affectation_in_affectation_list_instruction:		
					tID tEQUAL calculation 
					{ 

						//on supprime le résultat du sommet de la pile
						Symbole * calc_symbole = pop_temp_symbole(symboles_table);

						if(calc_symbole != NULL){
							//on a un résultat de calcul, on peut faire l'affectation

							Symbole * id_symbole = find_symbole(*symboles_table, $1);
							if(id_symbole == NULL){
								yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
							}else if(id_symbole->constant == true){
								yyerror("Affectation pour une constante impossible.");
							}else{

								if (id_symbole->initialised == false){
									id_symbole->initialised = true;
								}
							
								fprintf(temp_file, "COP @%d @%d\n", id_symbole->id, calc_symbole->id);
								ui_current_instruction_number++;
							}

						}else {
							yyerror("Affectation impossible car erreur lors du calcul.");
						}


					}

					|tID tEQUAL calculation_value
							{

								Symbole * symbole = find_symbole(*symboles_table, $1);
								if(symbole == NULL){
									yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
								}else if(symbole->constant == true){
									yyerror("Affectation pour une constante impossible.");
								}else{

									if (symbole->initialised == false){
										symbole->initialised = true;
									}

									//On copie calculation_value à dans l'espace mémoire qui été déjà aloué
									fprintf(temp_file, "AFC @%d %d\n", symbole->id, $3);
									ui_current_instruction_number++;

								}
								
							}
					|tID tEQUAL calculation_variable
						{


							Symbole * id_symbole = find_symbole(*symboles_table, $1);
								if(id_symbole == NULL){
									yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
								}else if(id_symbole->constant == true){
									yyerror("Affectation pour une constante impossible.");
								}else{

									Symbole * calc_symbole = find_symbole(*symboles_table, $3);
									if(calc_symbole == NULL){
										yyerror("Utilisation d'une variable non déclarée, affectation impossible !");
									}else if(calc_symbole->initialised == false){
										yyerror("Utilisation d'une variable non initialisée.");
									}else{
										
										if (id_symbole->initialised == false){
											id_symbole->initialised = true;
										}

										//calculation_variable existe bien
										fprintf(temp_file, "COP @%d @%d\n", id_symbole->id, calc_symbole->id);
										ui_current_instruction_number++;
									}
										

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
							}else if(symbole->initialised == false){
								yyerror("Utilisation d'une variable non initialisée !");
							}else{
								//On push le symbole !!!!
								Symbole * tmp_symbole = push_temp_symbole(symboles_table);
								fprintf(temp_file, "COP @%d @%d\n", tmp_symbole->id, symbole->id);
								ui_current_instruction_number++;
							}
						}

					|calculation_value
						{
							//On push le symbole !!!!
							Symbole * tmp_symbole = push_temp_symbole(symboles_table);
							fprintf(temp_file, "AFC @%d %d\n", tmp_symbole->id, $1);
							ui_current_instruction_number++;
						}

		 			|tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS
		 			|calculation operator calculation 
		 		   		{

		 		   			Symbole * tmp_symbole_top = pop_temp_symbole(symboles_table);
		 		   			if (tmp_symbole_top == NULL){
		 		   				yyerror("Erreur sur calcul.");
		 		   			}else{
		 		   				Symbole * tmp_symbole_bottom = find_symbole(*symboles_table, DEFAULT_TEMP_SYMBOLE_NAME);
		 		   				if (tmp_symbole_bottom == NULL){
		 		   					yyerror("Erreur sur calcul.");
		 		   				}else{
		 		   					//on est bon, on avait bien deux éléments empilé
		 		   					fprintf(temp_file, "%s @%d @%d @%d\n", $2, tmp_symbole_bottom->id, tmp_symbole_bottom->id, tmp_symbole_top->id);
		 		   					ui_current_instruction_number++;
		 		   				}
		 		   			}
		 		   			
		 		   		}
		 			|tMINUS calculation
		 		   		{
		 		   			Symbole * tmp_symbole = find_symbole(*symboles_table, DEFAULT_TEMP_SYMBOLE_NAME);
		 		   			if (tmp_symbole == NULL){
		 		   				yyerror("Erreur sur calcul.");
		 		   			}else{
		 		   				Symbole * symbole = push_temp_symbole(symboles_table);
					   				fprintf(temp_file, "AFC @%d 0\n", symbole->id);
					   				ui_current_instruction_number++;

					   				fprintf(temp_file, "SOU @%d @%d @%d\n", tmp_symbole->id, tmp_symbole->id, symbole->id);
					   				ui_current_instruction_number++;
					   				symbole = pop_temp_symbole(symboles_table);
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

		fclose(temp_file);
		fclose(yyin);

	}
	

    return 0;
}



void yyerror(char const *s) {
	if (ui_compilation_errors_nb == 0){
		fclose(temp_file);
	}
	ui_compilation_errors_nb++;
	printf("%d : %s\n", yylineno, s);
}

