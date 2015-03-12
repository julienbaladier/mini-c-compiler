%{
	#include <stdlib.h>
	#include <stdio.h>
	#include "SymbolesTable/SymbolesTable.h"
	int yylex(void);
	void yyerror (char const *msg);
	extern FILE *yyin;
	extern int yylineno;
	llist * symboles_table;
%}

%union { int nb; char * var; }

%token tMAIN tPRINTF tNEWLINE
%token tOPENED_BRACKET tCLOSED_BRACKET tOPENED_PARENTHESIS tCLOSED_PARENTHESIS
%token tCOMMA tSEMICOLON
%token tCONST tINT 
%token tADD tMINUS tMUL tDIV tEQUAL
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
													{ printf("main :\n"); }
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


instruction_list:								/* Nothing */
												|instruction instruction_list
												;


instruction:									affectation_list_instruction tSEMICOLON
												|tPRINTF tOPENED_PARENTHESIS tID tCLOSED_PARENTHESIS tSEMICOLON
													{	
														Symbole * symbole = findSymbole(*symboles_table, $3);
														if(symbole == NULL){
															yyerror("Utilisation d'une variable non déclarée !");
														}else if(symbole->initialised == false){
															yyerror("Utilisation d'une variable non initialisée !");
														}else{
															printf("\tPRI @%d\n", symbole->id);
														}
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
						Symbole * symbole = findSymbole(*symboles_table, $1);
						if(symbole == NULL){
							ajouterSymbole(symboles_table, $1, false, false);
						}else {
							yyerror("Déclaration d'un int déjà déclarée.");
						}
					}
					;

//----


affectation_in_affection_and_id_list_declaration:			
					tID tEQUAL calculation 
					{	

						// On regarde si calcul a bien généré un résultat
						// Il doit se retrouver au sommet de la pile avec comme nom DEFAULT_TEMP_SYMBOLE_NAME
						Symbole * symbole = popTempSymbole(symboles_table);

						if(symbole != NULL){
							// on a  un résultat

							// On ajoute ce int (initialisé) à la table des symboles s'il n'a pas encore été déclaré
							// on le met à l'addresse de la varibale temporere du résultat
							Symbole * new_symbole = findSymbole(*symboles_table, $1);
							if(new_symbole == NULL){
								//on ajoute ici à la place du résultat du calcul, pas besoin d'instruction asm
								new_symbole = ajouterSymbole(symboles_table, $1, false, true);

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
						Symbole * symbole = findSymbole(*symboles_table, $1);
						if(symbole == NULL){
							symbole = ajouterSymbole(symboles_table, $1, false, true);
							//On copie calculation_value à dans l'espace mémoire qu'on vient d'alouer
							printf("\tAFC @%d %d\n", symbole->id, $3);
						}else {
							yyerror("Déclaration d'un int déjà déclarée.");
						}
						
					}

				|tID tEQUAL calculation_variable
					{
						//on vérifie que calculation_variable existe bien
						Symbole * calc_symbole = findSymbole(*symboles_table, $3);
						if(calc_symbole == NULL){
							yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
						}else if(calc_symbole->initialised == false){
							yyerror("Utilisation d'une variable non initialisée, affectation impossible.");
						}else{
							//on teste si tID n'a pas déjà été déclaré
							Symbole * id_symbole = findSymbole(*symboles_table, $1);
							if(id_symbole == NULL){
								//on est bon, il a pas déjà été déclaré
								id_symbole = ajouterSymbole(symboles_table, $1, false, true);
								//On copie la valeur à l'adresse calculation_value à dans l'espace mémoire qu'on vient d'alouer
								printf("\tCOP @%d @%d\n", id_symbole->id, calc_symbole->id);
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
						Symbole * calc_symbole = popTempSymbole(symboles_table);

						if(calc_symbole != NULL){
							// on a  un résultat

							// On ajoute ce const int à la table des symboles s'il n'a pas encore été déclaré
							// on le met à l'addresse de la varibale temporere du résultat
							Symbole * new_symbole = findSymbole(*symboles_table, $1);
							if(new_symbole == NULL){
								//on ajoute ici à la place du résultat du calcul, pas besoin d'instruction asm
								new_symbole = ajouterSymbole(symboles_table, $1, true, true);

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
							Symbole * symbole = findSymbole(*symboles_table, $1);
							if(symbole == NULL){
								symbole = ajouterSymbole(symboles_table, $1, true, true);
								//On copie calculation_value à dans l'espace mémoire qu'on vient d'alouer
								printf("\tAFC @%d %d\n", symbole->id, $3);
							}else {
								yyerror("Déclaration d'un const int déjà déclarée.");
							}
							
						}

					|tID tEQUAL calculation_variable
						{
							//on vérifie que calculation_variable existe bien
							Symbole * calc_symbole = findSymbole(*symboles_table, $3);
							if(calc_symbole == NULL){
								yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
							}else if(calc_symbole->initialised == false){
								yyerror("Utilisation d'une variable non initialisée, affectation impossible.");
							}else{
								//on teste si tID n'a pas déjà été déclaré
								Symbole * id_symbole = findSymbole(*symboles_table, $1);
								if(id_symbole == NULL){
									//on est bon, il a pas déjà été déclaré
									id_symbole = ajouterSymbole(symboles_table, $1, true, true);
									//On copie la valeur à l'adresse calculation_value à dans l'espace mémoire qu'on vient d'alouer
									printf("\tCOP @%d @%d\n", id_symbole->id, calc_symbole->id);
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
						Symbole * id_symbole = findSymbole(*symboles_table, $1);
						if(id_symbole == NULL){
							yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
						}else if(id_symbole->constant == true){
							yyerror("Affectation pour une constante impossible.");
						}else{

							//on supprime le résultat du sommet de la pile
							Symbole * calc_symbole = popTempSymbole(symboles_table);

							if(calc_symbole != NULL){
								//on a un résultat de calcul, on peut faire l'affectation

								if (id_symbole->initialised == false){
									id_symbole->initialised = true;
								}
								
								printf("\tCOP @%d @%d\n", id_symbole->id, calc_symbole->id);

							}else {
								yyerror("Affectation impossible car erreur lors du calcul.");
							}


						}
					}

					|tID tEQUAL calculation_value
							{

								Symbole * symbole = findSymbole(*symboles_table, $1);
								if(symbole == NULL){
									yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
								}else if(symbole->constant == true){
									yyerror("Affectation pour une constante impossible.");
								}else{

									if (symbole->initialised == false){
										symbole->initialised = true;
									}

									//On copie calculation_value à dans l'espace mémoire qui été déjà aloué
									printf("\tAFC @%d %d\n", symbole->id, $3);

								}
								
							}
					|tID tEQUAL calculation_variable
						{


							Symbole * id_symbole = findSymbole(*symboles_table, $1);
								if(id_symbole == NULL){
									yyerror("Utilisation d'une variable non déclarée, affectation impossible.");
								}else if(id_symbole->constant == true){
									yyerror("Affectation pour une constante impossible.");
								}else{

									Symbole * calc_symbole = findSymbole(*symboles_table, $3);
									if(calc_symbole == NULL){
										yyerror("Utilisation d'une variable non déclarée, affectation impossible !");
									}else if(calc_symbole->initialised == false){
										yyerror("Utilisation d'une variable non initialisée.");
									}else{
										
										if (id_symbole->initialised == false){
											id_symbole->initialised = true;
										}

										//calculation_variable existe bien
										printf("\tCOP @%d @%d\n", id_symbole->id, calc_symbole->id);
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
							Symbole * symbole = findSymbole(*symboles_table, $1);
							if(symbole == NULL){
								yyerror("Utilisation d'une variable non déclarée !");
							}else if(symbole->initialised == false){
								yyerror("Utilisation d'une variable non initialisée !");
							}else{
								//On push le symbole !!!!
								Symbole * tmp_symbole = pushTempSymbole(symboles_table);
								printf("\tCOP @%d @%d\n", tmp_symbole->id, symbole->id);
							}
						}

					|calculation_value
						{
							//On push le symbole !!!!
							Symbole * tmp_symbole = pushTempSymbole(symboles_table);
							printf("\tAFC @%d %d\n", tmp_symbole->id, $1);
						}

		 			|tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS
		 			|calculation operator calculation 
		 		   		{

		 		   			Symbole * tmp_symbole_top = popTempSymbole(symboles_table);
		 		   			if (tmp_symbole_top == NULL){
		 		   				yyerror("Erreur sur calcul.");
		 		   			}else{
		 		   				Symbole * tmp_symbole_bottom = findSymbole(*symboles_table, DEFAULT_TEMP_SYMBOLE_NAME);
		 		   				if (tmp_symbole_bottom == NULL){
		 		   					yyerror("Erreur sur calcul.");
		 		   				}else{
		 		   					//on est bon, on avait bien deux éléments empilé
		 		   					printf("\t%s @%d @%d @%d\n", $2, tmp_symbole_bottom->id, tmp_symbole_bottom->id, tmp_symbole_top->id);
		 		   				}
		 		   			}
		 		   			
		 		   		}
		 			|tMINUS calculation
		 		   		{
		 		   			Symbole * tmp_symbole = findSymbole(*symboles_table, DEFAULT_TEMP_SYMBOLE_NAME);
		 		   			if (tmp_symbole == NULL){
		 		   				yyerror("Erreur sur calcul.");
		 		   			}else{
		 		   				Symbole * symbole = pushTempSymbole(symboles_table);
					   				printf("\tAFC @%d 0\n", symbole->id);

					   				printf("\tSOU @%d @%d @%d\n", tmp_symbole->id, tmp_symbole->id, symbole->id);
					   				symbole = popTempSymbole(symboles_table);
		 		   			}
					   			
					   		}
		 		   ;



%%

int main(int argc, char *argv[]){

	yyin = fopen(argv[1], "r");
	symboles_table = symbolesTableCreate();

	switch (yyparse()){
		case 0 :
		 printf("Parsing was successful !!\n");
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

	printf("\nTable des symboles :\n");
	printSymbolesTable(*symboles_table);

    return 0;
}




void yyerror(char const *s) {
	printf("%d : %s\n", yylineno, s);
	exit(1);
}

