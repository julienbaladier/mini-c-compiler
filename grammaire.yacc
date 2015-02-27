%{
	#include <stdlib.h>
	#include <stdio.h>
	int yylex(void);
	void yyerror (char const *msg);
	extern FILE *yyin;
	extern int yylineno;
%}

%union { int nb; char * var; }

%token tMAIN tPRINTF tNEWLINE
%token tOPENED_BRACKET tCLOSED_BRACKET tOPENED_PARENTHESIS tCLOSED_PARENTHESIS
%token tCOMMA tSEMICOLON
%token tCONST tINT 
%token tADD tMINUS tMUL tDIV tEQUAL
%token tERROR

%token <nb> tINTEGER_EXP_FORM
%token <nb> tINTEGER_DEC_FORM
%token <var> tID

// priorité des opérateurs %left %right
%left tADD tMINUS
%left tMUL tDIV

%start start

%%

/**********************************PROGRAM*************************************/

start:					declaration_list main
						;



/**********************************MAIN***************************************/

main:					tINT tMAIN tOPENED_PARENTHESIS tCLOSED_PARENTHESIS tOPENED_BRACKET { printf("Debut MAIN !\n"); }
						declaration_list instruction_list 
						tCLOSED_BRACKET { printf("Fin MAIN !\n"); }
						;




/*******************************DECLARATIONS**********************************/


declaration_list:		/* Nothing */
						|declaration_list declaration 
						;


declaration:			declaration_constante 
						|declaration_integer 
			 			;


declaration_constante:	tCONST tINT affectation_list	tSEMICOLON { printf("Déclaration CONSTANTE!\n"); }	
						;


declaration_integer:	tINT affection_and_id_list tSEMICOLON { printf("Déclaration VARIABLE!\n"); }
						;





/*******************************AFFECTATIONS**********************************/

affection_and_id_list:	affectation
						| tID { printf("ID!\n"); }
						| affectation tCOMMA affection_and_id_list 
						| tID tCOMMA affection_and_id_list { printf("Plusieurs\n"); } 
						;

affectation_list:		affectation 
						|affectation tCOMMA affectation_list { printf("Plusieurs\n"); } 
						;

affectation:			tID tEQUAL calculation { printf("AFFECTATION!\n"); }
						;


/*******************************INSTRUCTIONS**********************************/


instruction_list:		/* Nothing */
						|instruction instruction_list
						;


instruction:			affectation tSEMICOLON
						|tPRINTF tOPENED_PARENTHESIS tID tCLOSED_PARENTHESIS tSEMICOLON { printf("PRINTF!\n"); }
						;





/**********************************MATH*************************************/


operator: 			   tADD { printf("+"); }
		  			   |tMINUS { printf("-"); }
		  			   |tMUL { printf("*"); }
		  			   |tDIV { printf("/"); }
		  			   ;

operand: 			   tID { printf("%s", yylval.var ); }
		 			   |tINTEGER_EXP_FORM { printf("%d", yylval.nb ); }
		 			   |tINTEGER_DEC_FORM 
		 			   |tMINUS tINTEGER_EXP_FORM
		 			   |tMINUS tINTEGER_DEC_FORM
		 			   |tADD tINTEGER_EXP_FORM
		 			   |tADD tINTEGER_DEC_FORM
		 			   ;

calculation: 		   operand
			 		   |tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS { printf("\n"); }
			 		   |calculation operator calculation
			 		   ;


%%

int main(int argc, char *argv[]){

	yyin = fopen(argv[1], "r");

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

    return 0;
}




void yyerror(char const *s) {
	printf("%d : %s\n", yylineno, s);
}

