%option yylineno
%{
	#include <stdio.h>
	#include "y.tab.h"
%}


blancs    [ \n\t]+

letter		[a-zA-Z]
digit		[0-9]
integer    {digit}+
exposant  [eE][+-]?{integer}


%%

main					{return tMAIN;}
printf					{return tPRINTF;}
"{"						{return tOPENED_BRACKET;}
"}"						{return tCLOSED_BRACKET;}
const					{return tCONST;}
int						{return tINT;}
"+"						{return tADD;}
"-"						{return tMINUS;}
"*"						{return tMUL;}
"/"						{return tDIV;}
"="						{return tEQUAL;}
"("						{return tOPENED_PARENTHESIS;}
")"						{return tCLOSED_PARENTHESIS;}
","						{return tCOMMA;}
"\\n"					{return tNEWLINE;}
";"						{return tSEMICOLON;}
{integer}{exposant}		{
							yylval.nb = (int) atof(yytext);
							return tINTEGER_EXP_FORM;
						}

{integer}				{
							yylval.nb = atoi(yytext);
							return tINTEGER_DEC_FORM;
						}

{letter}[a-zA-Z0-9_]*	{
							yylval.var = malloc(sizeof(yyleng));
							strcpy(yytext, yylval.var);
							return tID;
						}

{blancs}				{};
.						{return tERROR;}

%%