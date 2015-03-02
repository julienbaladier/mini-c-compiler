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

%type <nb> tINTEGER_EXP_FORM tINTEGER_DEC_FORM
%type <var> tID affection_and_id_list affectation


%left tADD tMINUS
%left tMUL tDIV

%start start

%%

/**********************************PROGRAM*************************************/

start:					declaration_list main
						;



/**********************************MAIN***************************************/

main:					tINT tMAIN tOPENED_PARENTHESIS tCLOSED_PARENTHESIS tOPENED_BRACKET
						declaration_list instruction_list 
						tCLOSED_BRACKET
						;




/*******************************DECLARATIONS**********************************/


declaration_list:		/* Nothing */
						|declaration_list declaration 
						;


declaration:			declaration_constante 
						|declaration_integer 
			 			;


declaration_constante:	tCONST tINT affectation_list_declaration tSEMICOLON	
						;
						//si elle existe grosse erreur
						//sinon on l'a crée


declaration_integer:	tINT affection_and_id_list tSEMICOLON
						;





/*******************************AFFECTATIONS**********************************/

affection_and_id_list:				affectation
										{
											Symbole * symbole = findSymbole(*symboles_table, $1);
											if(symbole == NULL){
												ajouterSymbole(symboles_table, $1, false, true);
											}else {
												yyerror("Déclaration d'un int déjà déclarée !");
											}
										}
									|tID
										{
											Symbole * symbole = findSymbole(*symboles_table, $1);
											if(symbole == NULL){
												ajouterSymbole(symboles_table, $1, false, false);
											}else {
												yyerror("Déclaration d'un int déjà déclarée !");
											}
										}
									|affectation tCOMMA affection_and_id_list
										{
											Symbole * symbole = findSymbole(*symboles_table, $1);
											if(symbole == NULL){
												ajouterSymbole(symboles_table, $1, false, true);
											}else {
												yyerror("Déclaration d'un int déjà déclarée !");
											}
										} 
									|tID tCOMMA affection_and_id_list
										{
											Symbole * symbole = findSymbole(*symboles_table, $1);
											if(symbole == NULL){
												ajouterSymbole(symboles_table, $1, false, false);
											}else {
												yyerror("Déclaration d'un int déjà déclarée !");
											}
										}
									;





affectation_list_declaration:		affectation 
										{
											Symbole * symbole = findSymbole(*symboles_table, $1);
											if(symbole == NULL){
												ajouterSymbole(symboles_table, $1, true, true);
											}else {
												yyerror("Déclaration d'un const int déjà déclarée !");
											}
										}
									|affectation tCOMMA affectation_list_declaration
										{
											Symbole * symbole = findSymbole(*symboles_table, $1);
											if(symbole == NULL){
												ajouterSymbole(symboles_table, $1, true, true);
											}else {
												yyerror("Déclaration d'un const int déjà déclarée !");
											}
										}
									;




affectation_list_instruction:		affectation 
										{
											Symbole * symbole = findSymbole(*symboles_table, $1);
											if(symbole == NULL){
												yyerror("Utilisation d'une variable non déclarée !");
											}else if(symbole->constant == true){
												yyerror("Affectation pour une constante pas possible neguaa !");
											}else if(symbole->initialised == false){
												symbole->initialised = true;
											}
										}
									|affectation tCOMMA affectation_list_instruction
										{
											Symbole * symbole = findSymbole(*symboles_table, $1);
											if(symbole == NULL){
												yyerror("Utilisation d'une variable non déclarée !");
											}else if(symbole->constant == true){
												yyerror("Affectation pour une constante pas possible neguaa !");
											}else if(symbole->initialised == false){
												symbole->initialised = true;
											}
										}
									;



affectation:						tID tEQUAL calculation { $$ = $1; }
									;


/*******************************INSTRUCTIONS**********************************/


instruction_list:		/* Nothing */
						|instruction instruction_list
						;


instruction:			affectation_list_instruction tSEMICOLON
						|tPRINTF tOPENED_PARENTHESIS tID tCLOSED_PARENTHESIS tSEMICOLON
							{	
								Symbole * symbole = findSymbole(*symboles_table, $3);
								if(symbole == NULL){
									yyerror("Utilisation d'une variable non déclarée !");
								}else if(symbole->initialised == false){
									yyerror("Utilisation d'une variable non initialisée !");
								}
							}
						;





/**********************************MATH*************************************/


operator: 			   tADD
		  			   |tMINUS
		  			   |tMUL
		  			   |tDIV
		  			   ;

operand: 			   tID 
							{ 
								Symbole * symbole = findSymbole(*symboles_table, $1);
								if(symbole == NULL){
									yyerror("Utilisation d'une variable non déclarée !");
								}else if(symbole->initialised == false){
									yyerror("Utilisation d'une variable non initialisée !");
								}
							}

		 			   |tINTEGER_EXP_FORM
		 			   |tINTEGER_DEC_FORM
		 			   |tMINUS tINTEGER_EXP_FORM
		 			   |tMINUS tINTEGER_DEC_FORM
		 			   |tADD tINTEGER_EXP_FORM
		 			   |tADD tINTEGER_DEC_FORM
		 			   ;

calculation: 		   operand
			 		   |tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS
			 		   |calculation operator calculation
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

	printSymbolesTable(*symboles_table);

    return 0;
}




void yyerror(char const *s) {
	printf("%d : %s\n", yylineno, s);
	// ajouter des | error
}

