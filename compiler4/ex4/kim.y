
%{

#define YYSTYPE_IS_DECLARED 1
typedef long YYSTYPE;
#include <stdio.h>
#include <stdlib.h>

%}

%start program

%token 
IDENTIFIER 
TYPE_IDENTIFIER 
AUTO_SYM 
BREAK_SYM 
CASE_SYM 
CONST_SYM 
CONTINUE_SYM 
DEFAULT_SYM 
DO_SYM 
ELSE_SYM 
ENUM_SYM 
EXTERN_SYM 
FOR_SYM 
GOTO_SYM 
IF_SYM 
RETURN_SYM 
REGISTER_SYM 
SIZEOF_SYM 
STATIC_SYM 
STRUCT_SYM 
SWITCH_SYM 
TYPEDEF_SYM 
UNION_SYM 
VOLATILE_SYM 
WHILE_SYM 
PLUSPLUS 
MINUSMINUS 
ARROW 
LSS 
GTR 
LSSLSS 
GTRGTR 
LEQ 
GEQ 
EQL 
NEQ 
AMPAMP 
BARBAR 
DOTDOTDOT 
LP 
RP 
LB 
RB 
LR 
RR 
COLON 
PERIOD 
COMMA 
EXCL 
STAR 
SLASH 
PERCENT 
AMP 
SEMICOLON 
PLUS 
MINUS 
ASSIGN 
QUESTION 
BAR 
HAT 
NOT 
INTEGER_CONSTANT 
FLOAT_CONSTANT 
STRING_LITERAL 
CHARACTER_CONSTANT

%%
program 
	: translation_unit {checkForwardReference(); root=makeNode(N_PROGRAM,0,$1,0);}
	;

translation_unit
	: external_declaration {$$=$1;}
	| translation_unit external_declaration {$$=linkDeclaratorList($1,$2);}
	;

external_declaration
	: funtion_definition {$$=$1;}
	| declaration {$$=$1;}
	;

struct_specifier
	: struct_or_union IDENTIFIER {$$=setTypeStructOrEnumIdentifier($1,$2,ID_STRUCT);} LR  {$$=current_id; current_level++;} struct_declaration_list RR {$$=setTypeField($3,$5); current_level--; $$=$5;}
	| struct_or_union {$$=makeType($1);} LR {$$=current_id; current_level++;} struct_declaration_list RR {$$=setTypeField($2,$4); current_level--; $$=$3;}
	| struct_or_union IDENTIFIER {$$=getTypeOfStructOrEnumIdentifier($1,$2,ID_STRUCT);}
	;

struct_or_union
	: STRUCT_SYM {$$=T_STRUCT;}
	| UNION_SYM {$$=T_UNION;}
	;

struct_declaration_list
	: struct_declaration {$$=$1;}
	| struct_declaration_list struct_declaration {$$=linkDeclaratorList($1,$2);}
	;

struct_declaration
	: type_specifier struct_declarator_list SEMICOLON {$$=setStructDeclaratorListSpecifier($2,$1);}
	;
struct_declarator_list
	: struct_declarator
	| struct_declarator_list COMMA struct_declarator {$$=linkDeclaratorList($1,$2);}
	;

struct_declarator
	: declarator {$$=$1;}
	;
direct_declarator
	: IDENTIFIER {$$=makeIdentifier($1);}
	| LP declarator RP {$$=$2;}
	| direct_declarator LB constant_expression_opt RB {$$=setDeclaratorElementType($1,setTypeExpr(makeType(T_ARRAY),$3));}
	| direct_declarator LP {$$=current_id; current_level++;} parameter_type_list_opt RP {checkForwardReference(); set_DeclaratorElementType($1,setTypeField(makeType(T_FUNC),$3)); current_level--; $$=$3;}
	;

compound_statement
	: LR {$$=current_id; current_level++;} declaration_list_opt statement_list_opt RR {checkForwardReference(); current_level--; $$=$2;}
	;

function_definition
	: declaration_specifier declarator {$$=setFunctionDeclaratorSpecifier($2,$1);} compound_statement {$$=setFunctionDeclaratorBody($3,$4);}
	| declarator {$$=setFunctionDeclaratorSpecifier($1,makeSpecifier(int_type,0));} compound_statement {$$=setFunctionDeclaratorBody($2,$3);}
	;

declaration
	: declaration_specifiers init_declarator_list_opt SEMICOLON {$$=setDeclarationListSpecifier($2,$1);}
	;

declaration_specifiers
	: type_specifiers {$$=makeSpecifier($1,0);}
	| storage_class_specifier {$$=makeSpecifier(0,$1);}
	| type_specifiers declaration_specifiers {$$=updateSpecifier($2,$1,0);}
	| storage_class_specifier declaration_specifiers {$$=updateSpecifier($2,0,$1);}
	;

storage_class_specifier
	: AUTO_SYM {$$=S_AUTO;}
	| STATIC_SYM {$$=S_STATIC;}
	| TYPEDEF_SYM {$$=S_TYPEDEF;}
	;

init_declarator_list_opt
	: /*empty*/ {$$=NIL;}
	| init_declarator_list {$$=$1;}
	;

init_declarator_list
	: init_declarator {$$=$1;}
	| init_declarator_list COMMA init_declarator {$$=linkDeclaratorList($1,$3);}
	;

init_declarator
	: declarator {$$=$1;}
	| declarator ASSIGN initializer {$$=setDeclaratorInit($1,$3);}
	;

initializer
	: constant_expression {$$=makeNode(N_INIT_LIST_ONE,0,$1,0);}
	| LR initializer_list RR {$$=$2;}
	;

initializer_list
	: initializer {$$=makeNode(N_INIT_LIST,$1,makeNode(N_INIT_LIST_NIL,0,0,0));}
	| initializer_list COMMA initializer {$$=makeNode(N_INIT_LIST,$1,$3)}
	;

type_specifier
	: struct_specifier {$$=$1;}
	| enum_specifier {$$=$1;}
	| TYPE_IDENTIFIER {$$=$1;}
	;

enum_specifier
	: ENUM_SYM IDENTIFIER {$$=setTypeStructOrEnumIdentifier(T_ENUM,$2,ID_ENUM);} LR enumerator_list RR {$$=setTypeField($3,$5);}
	| ENUM_SYM {$$=makeType(T_ENUM);} LR enumerator RR {$$=setTypeField($2,$4);}
	| ENUM_SYM IDENTIFIER {$$=getTypeOfStructOrEnumIdentifier(T_ENUM,$2,ID_ENUM);}
	;

enumerator_list
	: enumerator {$$=$1;}
	| enumerator_list COMMA enumerator {$$=linkDeclaratorList($1,$3);} 
	;

enumerator
	: IDENTIFIER {$$=setDeclaratorKind(makeIdentifier($1),ID_ENUM_LITERAL);}
	| IDENTIFIER {$$=setDeclaratorKind(makeIdentifier($1),ID_ENUM_LITERAL);} ASSIGN expression {$$=setDeclaratorInit($2,$4);}
	;

declarator
	: pointer direct_declarator {$$=setDeclaratorElementType($2,$1);}
	| direct_declarator {$$=$1;}
	;

pointer
	: STAR {$$=makeType(T_POINTER);}
	| STAR pointer {$$=setTypeElementType($2,makeType(T_POINTER));}
	;

parameter_type_list_opt
	: /*empty*/ {$$=NIL;}
	| parameter_type_list {$$=$1;}
	;

parameter_type_list
	: parameter_list {$$=$1;}
	| parameter_list COMMA DOTDOTDOT {$$=linkDeclaratorList($1,setDeclaratorKind(makeDummyIdentifier(),ID_PARM));}
	;

parameter_list
	: parameter_declaration {$$=setParameterDeclaratorSpecifier($2,$1);}
	| parameter_list COMMA parameter_declaration {$$=linkDeclaratorList($2,$1);}
	;

parameter_declaration
	: declaration_specifiers declarator {$$=setParameterDeclaratorSpecifier($2,$1);}
	| declaration_specifiers abstract_declarator_opt {$$=setParameterDeclaratorSpecifier(setDeclaratorType(makeDummyIdentifier(),$2),$1);}
	;

abstract_declarator_opt
	: /*empty*/ {$$=0;}
	| abstract_declarator {$$=$1;}
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator {$$=$1;}
	| pointer direct_abstract_declarator {$$=setTypeElementType($2,makeType(T_POINTER);}
	;

direct_abstract_declarator
	: LP abstract_declarator RP {$$=$2;}
	| LB constant_expression_opt RB {$$=setTypeExpr(makeType(T_ARRAY),$2);}
	| direct_abstract_declarator LB constant_expression_opt RB {$$=setTypeElementType($1,setTypeExpr(T_ARRAY),$3);}
	| LP parameter_type_list_opt RP {$$=$2;}
	| direct_abstract_declarator LP parameter_type_list_opt RP {$$=setTypeElementField($1,setTypeExpr(T_FUNC),$3);}
	;

primary_expression
	: IDENTIFIER {$$=makeNode(N_EXP_IDENT,0,getIdentifierDeclared($1),0);}
	| INTEGER_CONSTANT {$$=makeNode(N_EXP_INT_CONST,0,$1,0}
	| FLOAT_CONSTANT {$$=makeNode(N_EXP_FLOAT_CONST,0,$1,0);}
	| CHARACTER_CONSTANT {$$=makeNode(N_EXP_CHAR_CONST,0,$1,0);}
	| STRING_LITERAL {$$=makeNode(N_EXP_STRING_LITERAL,0,$1,0);}
	| LP expression RP {$$=$2;}
	;

postfix_expression
	: primary_expression {$$=$1;}
	| postfix_expression LB expression RB {$$=makeNode(N_EXP_ARRAY,$1,0,$3);}
	| postfix_expression LP arg_expression_list_opt RP {$$=makeNode(N_EXP_FUNCTION_CALL,$1,0,$3);}
	| postfix_expression PERIOD IDENTIFIER {$$=makeNode(N_EXP_STRUCT,$1,0,$3);}
	| postfix_expression ARROW IDENTIFIER {$$=makeNode(N_EXP_ARROW,$1,0,$3);}
	| postfix_expression PLUSPLUS {$$=makeNode(N_EXP_POST_INC,0,$1,0);}
	| postfix_expression MINUSMINUS {$$=makeNode(N_EXP_POST_DEC,0,$1,0);}
	;

arg_expression_list_opt
	: /* empty */ {$$=makeNode(N_ARG_LIST_NIL,0,0,0);}
	| arg_expression_list {$$=$1;}
	;

arg_expression_list
	: assignment_expression {$$=makeNode(N_ARG_LIST,$1,0,makeNode(N_ARG_NIL,0,0,0));}
	| argt_expression_list COMMA assignment_expression {$$=makeNodeList(N_ARG_LIST,$1,$3);}
	;

unary_expression
	: postfix_expression {$$=$1;}
	| PLUSPLUS unary_expression {$$=makeNode(N_EXP_PRE_INC,0,$2,0);}
	| MINUSMINUS unary_expression {$$=makeNode(N_EXP_PRE_DEC,0,$2,0);}
	| AMP cast_expression {$$=makeNode(N_EXP_AMP,0,$2,0);}
	| STAR cast_expression {$$=makeNode(N_EXP_STAR,0,$2,0);}
	| EXCL cast_expression {$$=makeNode(N_EXP_NOT,0,$2,0);}
	| MINUS cast_expression {$$=makeNode(N_EXP_MINUS,0,$2,0);}
	| PLUS cast_expression {$$=$1;}
	| SIZEOF_SYM unary_expression {$$=makeNode(N_EXP_SIZE_EXP,0,$2,0);}
	| SIZEOF_SYM LP type_name RP {$$=makeNode(N_EXP_SIZE_TYPE,0,$3,0);}
	;

cast_expression
	: unary_expression {$$=$1;}
	| LP type_name RP cast_expression {$$=makeNode(N_EXP_CAST,$2,0,$4);}
	;

type_name
	: declaration_specifiers abstract_declarator_opt {$$=setTypeNameSpecifier($2,$1);}
	;

multiplicative_expression
	: cast_expression {$$=$1;}
	| multiplicative_expression STAR cast_expression {$$=makeNode(N_EXP_MUL,$1,0,$3);}
	| multiplicative_expression SLASH cast_expression {$$= makeNode(N_EXP_DIV,$1,0,$3);}
	| multiplicative_expression PERCENT cast_expression {$$= makeNode(N_EXP_MOD,$1,0,$3);}
	;

additive_expression
	: multiplicative_expression {$$=$1;}
	| additive_expression PLUS multiplicative_expression {$$=makeNode(N_EXP_ADD,$1,0,$3);}
	| additive_expression MINUS multiplicative_expression {$$=makeNode(N_EXP_SUB,$1,0,$3);}	
	;

relational_expression
	: additive_expression {$$=$1;}
	| relational_expression LSS additive_expression {$$=makeNode(N_EXP_LSS,$1,0,$3);}
	| relational_expression GTR additive_expression {$$=makeNode(N_EXP_GTR,$1,0,$3);}
	| relational_expression LEQ additive_expression {$$=makeNode(N_EXP_LEQ,$1,0,$3);}
	| relational_expression GEQ additive_expression {$$=makeNode(N_EXP_GEQ,$1,0,$3);}
	;

equality_expression
	: relational_expression {$$=$1;}
	| equality_expression EQL relational_expression {$$=makeNode(N_EXP_EQL,$1,0,$3);}
	| equality_expression NEQ relational_expression {$$=makeNode(N_EXP_NEQ,$1,0,$3);}
	;

logical_and_expression
	: equality_expression {$$=$1;}
	| logical_and_expression AMPAMP equality_expression {$$=makeNode(N_EXP_AND,$1,0,$3);}
	;

logical_or_expression
	: logical_and_expression {$$=$1;}
	| logical_or_expression BARBAR logical_and_expression {$$=makeNode(N_EXP_OR,$1,0,$3);}
	;

constant_expression
	: logical_or_expression {$$=$1;}
	;

expression
	: constant_expression {$$=$1;}
	| unary_expression ASSIGN expression {$$=makeNode(N_EXP_ASSIGN,$1,0,$3);}
	;

statement
	: labeled_statement {$$=$1;}
	| compound_statement {$$=$1;}
	| expression_statement {$$=$1;}
	| selection_statement {$$=$1;}
	| iteration_statement {$$=$1;}
	| jump_statement {$$=$1;}
	;

labeled_statement
	: CASE_SYM constant_expression COLON statement {$$=makeNode(N_STMT_LABEL_CASE,$2,0,$4);}
	| DEFAULT_SYM COLON statement {$$=makeNode(N_STMT_LABEL_DEFAULT,0,$3,0);}
	;

compound_statement
	: LR declaration_list_opt statement_list_opt RR {$$=makeNode(N_STMT_COMPOUND,$2,0,$3); }
	;

declaration_list_opt
	: /* empty */ {$$=0;}
	| declaration_list {$$=$1;}
	;

declaration_list
	: declaration {$$=$1;}
	| declaration_list declaration {$$=linkDeclaratorList($1,$2);}
	;

statement_list_opt
	: /* empty */ {$$=makeNode(N_STMT_LIST_NIL,0,0,0);}
	| statement_list {$$=$1;}
	;

statement_list
	: statement {$$=makeNode(N_STMT_LIST,$1,0,makeNode(N_STMT_LIST_NIL,0,0,0));}
	| statement_list statement {$$=makeNodeList(N_STMT_LIST,$1,$2);}
	;

expression_statement
	: SEMICOLON {$$=makeNode(N_STMT_EMPTY,0,0,0);}
	| expression SEMICOLON {$$=makeNode(N_STMT_EXPRESSION,0,$1,0);}
	;

selection_statement
	: IF_SYM LP expression RP statement {$$=makeNode(N_STMT_IF,$3,0,$5);}
	| IF_SYM LP expression RP statement ELSE_SYM statement {$$=makeNode(N_STMT_IF_ELSE,$3,$5,$7);} 
	| SWITCH_SYM LP expression RP statement {$$=makeNode(N_STMT_SWITCH,$3,0,$5);}
	;

iteration_statement
	: WHILE_SYM LP expression RP statement {$$=makeNode(N_STMT_WHILE,$3,0,$5);}
	| DO_SYM statement WHILE_SYM LP expression RP SEMICOLON {$$=makeNode(N_STMT_DO,$2,0,$5);}
	| FOR_SYM LP for_expression RP statement {$$=makeNode(N_STMT_FOR,$3,0,$5);}
	;

for_expression
	: expression_opt SEMICOLON expression_opt SEMICOLON expression_opt {$$=makeNode(N_FOR_EXP,$1,$3,$5);}
	;

expression_opt
	: /* empty */ {$$=0;}
	| expression {$$=$1;}
	;

jump_statement
	| RETURN_SYM expression_opt SEMICOLON {$$=makeNode(N_STMT_RETURN,0,$2,0);}
	| CONTINUE_SYM SEMICOLON {$$=makeNode(N_STMT_CONTINUE,0,0,0);}
	| BREAK_SYM SEMICOLON {$$=makeNode(N_STMT_BREAK,0,0,0);}
	;

%%

int current_level=0;

extern char *yytext;
extern int line_no;

A_NODE *makeNode(NODE_NAME n, A_NODE *a, A_NODE *b, A_NODE *c);
/*{
	A_NODE *p ;
	p = (A_NODE *)malloc(sizeof(A_NODE);
	p>name = n;
	p>llink = a;
	p>clink = b;
	p>rlink = c;
	return p;
}*/

A_ID *makeIdentifier(har *s); 
/*{
	A_ID *id;
	id = malloc(sizeof(A_ID));
	id->name=s;
	id->level=current_level;
	id->prev=current_id;
	current_id=id;
	return(id);
*/
void checkForwardReference();
A_ID *linkDeclaratorList(A_ID *id1, A_ID *id2);
A_ID *setFunctionDeclaratorSpecifier(A_ID *id, A_SPECIFIER *p);
A_ID *setFunctionDeclaratorBody(A_ID *id, A_NODE *node);
A_SPECIFIER *makeSpecifier(A_TYPE *t, S_KIND s) ;
A_ID *setDeclaratorListSpecifier(A_ID *id, A_SPECIFIER *p);
A_SPECIFIER *updateSpecifier(A_SPECIFIER *p, A_TYPE *t, S_KIND s);
A_ID *setDeclaratorInit(A_ID *id, A_NODE *node);
A_NODE *makeNodeList (NODE_NAME name, A_NODE *a, A_NODE *b, A_NODE *c);
A_TYPE *setTypeStructOrEnumIdentifier(T_KIND tk, char *s, ID_KIND ik);
A_TYPE *setTypeField(A_TYPE *t, A_ID *id);
A_ID *setStructDeclaratorListSpecifier(A_ID *id, A_TYPE *t);
A_TYPE *getTypeStructOrEnumIdentifier(T_KIND tk, char*s, ID_KIND ik);
A_TYPE *makeType(T_KIND k);
A_ID *setDeclaratorKind(A_ID *id, ID_KIND k);
A_ID *setDeclaratorElementType(A_ID *id, A_TYPE *t);
A_TYPE *setTypeElementType(A_TYPE *t1, A_TYPE *t2);
A_TYPE *setTypeExpr(A_TYPE *t, A_NODE *node);
A_ID *makeDummyIdentifier ( );
A_ID *setParameterDeclaratorSpecifier(A_ID *id, A_TYPE *t);
A_ID *setDeclaratorType(A_ID *id, A_TYPE *t);
A_ID *getIdentifierDeclared(char *s);
A_ID *setTypeNameSpecifier(A_TYPE *t, A_SPECIFIER *p);

int yyerror(char *s){
	printf("%s line_no:%d near %s",s,line_no, yytext);	
	exit(1);
}
int yywrap(){
	return 1;
}
void main () { 
	yyparse(); 
	printf("success.\n");
}
