%{
#include <stdlib.h>
#include "tds.h"
#include "quad.h"
#include "constants.h"
#include "y.tab.h"
%}

%s ALGO

letter          [a-zA-Z]
number          [0-9]+
space           [\t\n ]+
identifier      {letter}({letter}|{number})*

cmdConst        "\\Constant"
cmdInput        "\\Input"
cmdOutput       "\\Output"
cmdGlobal       "\\Global"
cmdLocal        "\\Local"
cmdBlk          "\\BlankLine"
cmdEmpty        "\\emptyset"
cmdIn           "\\in"
cmdType         "\\Integer"|"\\Real"|"\\Complex"|"\\Boolean"
cmdLeft         "\\leftarrow"
cmdWhile        "\\While"
cmdRepeat       "\\Repeat"
cmdFor          "\\For"
cmdIf           "\\If"
cmdEif          "\\eIf"
cmdTo           "\\KwTo"
cmdMbox         "\\mbox"
endInst         "\\;"
booleanOp       "\\geq"|"\\leq"|"\\neq"
booleanNOT      "\\neg"
booleanOR       "\\vee"
booleanAND      "\\wedge"
booleanF        "\\false"
booleanT        "\\true"
multOp          "\\times"
divOp           "\\div"

%%

<INITIAL>{
	"\\begin{algo}{"([^}])*"}" {
		printf("Beginning of algo %s\n", yytext);
		BEGIN(ALGO);
	}
	(.|\n)                     {}
}

<ALGO>{
	{cmdConst}          yylval.scope_type = SCOPE_CONST; return TK_CONST;
	{cmdInput}          yylval.scope_type = SCOPE_INPUT; return TK_INPUT;
	{cmdOutput}         yylval.scope_type = SCOPE_OUTPUT; return TK_OUTPUT;
	{cmdGlobal}         yylval.scope_type = SCOPE_GLOBAL; return TK_GLOBAL;
	{cmdLocal}          yylval.scope_type = SCOPE_LOCAL; return TK_LOCAL;
	{cmdBlk}            return TK_BLK;
	{cmdEmpty}          return TK_EMPTY;
	{cmdLeft}           return TK_LEFT;
	{cmdIn}             return TK_IN;
	{cmdType}           return TK_TYPE;
	{cmdWhile}          return TK_WHILE;
	{cmdRepeat}         return TK_REPEAT;
	{cmdFor}            return TK_FOR;
	{cmdIf}             return TK_IF;
	{cmdEif}            return TK_EIF;
	{cmdTo}             return TK_TO;
	{cmdMbox}           return TK_MBOX;
	{identifier}        yylval.id = strdup(yytext); return TK_IDENT;
	{number}            yylval.intval = atoi(yytext); return TK_NUMBER;
	{endInst}           return TK_ENDINST;
	{booleanOp}         return TK_BOOLOP;
	{booleanNOT}        return TK_NOT;
	{booleanOR}         return TK_OR;
	{booleanAND}        return TK_AND;
	{booleanF}          return TK_FALSE;
	{booleanT}          return TK_TRUE;
	{multOp}            return TK_TIMES;
	{divOp}             return TK_DIV;
	"\\end{algo}"   {
		printf("End of algo\n");
		BEGIN(INITIAL);
	}
	","                 return yytext[0];
	"^"                 return yytext[0];
	"$"                 return yytext[0];
	"-"                 return yytext[0];
	"+"                 return yytext[0];
	"("                 return yytext[0];
	"{"                 return yytext[0];
	")"                 return yytext[0];
	"}"                 return yytext[0];
	"_"                 return yytext[0];
	{space}             {}
}
