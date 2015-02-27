blancs    [ \n\t]+

letter		[a-zA-Z]
digit		[0-9]
integer    {digit}+
exposant  [eE][+-]?{integer}


%%

main					printf("tMAIN\n");
printf					printf("tPRINTF\n");
"{"						printf("tOPENEDBRACKET\n");
"}"						printf("tCLOSEDBRACKET\n");
const					printf("tCONST\n");
int						printf("tINT\n");
"+"						printf("tADD\n");
"-"						printf("tMINUS\n");
"*"						printf("tMUL\n");
"/"						printf("tDIV\n");
"="						printf("tEQUAL\n");
"("						printf("tOPENEDPARENTHESIS\n");
")"						printf("tCLOSEDPARENTHESIS\n");
","						printf("tCOMMA\n");
"\\n"					printf("tNEWLINE\n");
";"						printf("tSEMICOLON\n");
{integer}{exposant}		printf("tINTEGER_EXP_FORM\n");

{integer}				printf("tINTEGER_DEC_FORM\n");

{letter}[a-zA-Z0-9_]*	printf("tID\n");

{blancs}				{}
.						printf("tERROR\n");

%%