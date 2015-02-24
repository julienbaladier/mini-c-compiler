%{
	#include <stdlib.h>
	#include <stdio.h>
	int yylex(void);
	void yyerror (char const *msg);
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


%start start

%%

/**********************************PROGRAM*************************************/

start: 			   	   declaration_list 
		 			   |main
					   ;



/**********************************MAIN***************************************/

main: 				   tINT tMAIN tOPENED_PARENTHESIS tCLOSED_PARENTHESIS tOPENED_BRACKET 
					   declaration_list instruction_list 
					   tCLOSED_BRACKET {}
	  				   ;




/*******************************DECLARATIONS**********************************/


declaration_list:	   /* Nothing */
					   |declaration declaration_list
				  	   ;


declaration: 		   declaration_constante
					   |declaration_integer
			 		   ;


declaration_constante: tCONST tINT affectation_list
					   ;


declaration_integer:   tINT affectation_list
					   ;





/*******************************AFFECTATIONS**********************************/


affectation_list: 	   affectation tSEMICOLON
				  	   |affectation tCOMMA affectation_list tSEMICOLON
				  	   ;

affectation: 	  	   tID tEQUAL calculation
			 	  	   ;



/*******************************INSTRUCTIONS**********************************/


instruction_list: 	   /* Nothing */
				  	   |instruction instruction_list
				  	   ;


instruction: 		   affectation tSEMICOLON
			 		   |tPRINTF tOPENED_PARENTHESIS tID tCLOSED_PARENTHESIS tSEMICOLON
			 		   ;





/**********************************MATH*************************************/

operator: 			   tADD 
		  			   |tMINUS 
		  			   |tMUL 
		  			   |tDIV
		  			   ;

operand: 			   tID
		 			   |tINTEGER_EXP_FORM
		 			   |tINTEGER_DEC_FORM
		 			   ;

calculation: 		   operand
			 		   |tOPENED_PARENTHESIS calculation tCLOSED_PARENTHESIS
			 		   |operand operator operand
			 		   ;


%%

int main(int argc, char *argv[]){
	yylex();
    return 0;
}

void yyerror(char const *s){
	printf("Une erreur est survenue !");
}