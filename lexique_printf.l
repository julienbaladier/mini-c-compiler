%{
#include <stdio.h>
%}


blancs    [ \t]+

letter		[a-zA-Z]
chiffre		[0-9]
entier    {chiffre}+
exposant  [eE][+-]?{entier}

reel    {entier}("."{entier})?{exposant}?


%%

main					printf("tMAIN\n");
printf					printf("tPRINTF\n");
{						printf("tOPENEDBRACKET\n");
}						printf("tCLOSEDBRACKET\n");
const					printf("tCONST\n");
int						printf("tINT\n");
"+"						printf("tADD\n");
"-"						printf("tMINUS\n");
"*"						printf("tMUL\n");
"/"						printf("tSLASH\n");
"="						printf("tEQUAL\n");
"("						printf("tOPENEDPARENTHESIS\n");
")"						printf("tCLOSEDPARENTHESIS\n");
" "						printf("tSPACE\n");
","						printf("tCOMMA\n");
\t 						printf("tTAB\n");
\n 						printf("tNEWLINE\n");
";"						printf("tSEMICOLON\n");
{letter}[a-zA-Z0-9_]*	printf("tID\n");


%%