%option noyywrap

%x STRING
%x SINGLELINE_COMMENT
%x MULTILINE_COMMENT

%{
#include<bits/stdc++.h>
#include"1905097_symbol_table.cpp"

using namespace std;

ofstream logout;
ofstream tokenout;

int line_count=1;
int error_count=0;
int scopeTableID=0;
int bucketLength=10;

SymbolTable symbolTable;

map<char, string> escapeCharIdentifier={
	{'\'',"\'"},
	{'\"',"\""},
	{'n',"\n"},
	{'t',"\t"},
	{'\\',"\\"},
	{'a',"\a"},
	{'f',"\f"},
	{'r',"\r"},
	{'b', "\b"},
	{'v', "\v"},
	{'0', "\0"}
};

string str;
int strStart;

void printKeyword(string token, string keyword){
	logout<<"Line# "<<line_count<<": Token <"<<token<<"> Lexeme "<<keyword<<" found"<<endl;
	tokenout<<"<"<<token<<", "<<keyword<<">"<<endl;
}

void printOperatorPunctuator(string token, string operatorPunctuator){
	logout<<"Line# "<<line_count<<": Token <"<<token<<"> Lexeme "<<operatorPunctuator<<" found"<<endl;
	tokenout<<"<"<<token<<", "<<operatorPunctuator<<">"<<endl;
}

%}

WHITESPACE [ \t\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
EXPONENT [Ee][+-]?{DIGIT}+
NEWLINE (\r)?\n
CONST_INT {DIGIT}+
CONST_FLOAT {DIGIT}*(\.{DIGIT}+)?{EXPONENT}?
CONST_CHAR \'[^\'\\\n\r]\'
CONST_ESCAPE_CHAR \'\\[nt\\'afrbv0]\'
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
TOO_MANY_DECIMAL_POINTS {DIGIT}*(\.{DIGIT}*)+(\.{DIGIT}*)+{EXPONENT}?
ILLFORMED_NUMBER {DIGIT}*[Ee][+-]?{DIGIT}*(\.{DIGIT}*)+
INVALID_ID_SUFFIX_NUM_PREFIX {CONST_FLOAT}+{IDENTIFIER}+
MULTICHAR_CONST_CHAR \'[^\'\n\r][^\'\n\r]+\'
UNFINISHED_CONST_CHAR \'(\\\')?[^\'\n\r]?
EMPTY_CONST_CHAR \'\'

%%

{WHITESPACE} {}
{NEWLINE} {line_count++;}

"if"	{
			printKeyword("IF", "if");
		}
		
"else"	{
			printKeyword("ELSE", "else");
		}

"for"	{
			printKeyword("FOR", "for");
		}		

"while"	{
			printKeyword("WHILE", "while");
		}

"do"	{
			printKeyword("DO", "do");
		}

"break"	{
			printKeyword("BREAK", "break");
		}

"int"	{
			printKeyword("INT", "int");
		}

"char"	{
			printKeyword("CHAR", "char");
		}

"float"	{
			printKeyword("FLOAT", "float");
		}

"double" { 
			printKeyword("DOUBLE", "double");
		 }

"void"	{
			printKeyword("VOID", "void");
		}

"return" {
			printKeyword("RETURN", "return");
		 }

"switch" {
			printKeyword("SWITCH", "switch");
		 }

"case"	{
			printKeyword("CASE", "case");
		}

"default" {
			printKeyword("DEFAULT", "default");
		  }

"continue" {
			printKeyword("CONTINUE", "continue");
		   }

{CONST_INT} {
	         	logout<<"Line# "<<line_count<<": Token <CONST_INT> Lexeme "<<yytext<<" found"<<endl;
				tokenout<<"<CONST_INT, "<<yytext<<">"<<endl;
			}

{CONST_FLOAT}	{
					logout<<"Line# "<<line_count<<": Token <CONST_FLOAT> Lexeme "<<yytext<<" found"<<endl;
					tokenout<<"<CONST_FLOAT, "<<yytext<<">"<<endl;
				}

{CONST_CHAR}	{
					string str2="";
					str2 += yytext[1];
					logout<<"Line# "<<line_count<<": Token <CONST_CHAR> Lexeme "<<str2<<" found"<<endl;
					tokenout<<"<CONST_CHAR, "<<str2<<">"<<endl;
				}	

{CONST_ESCAPE_CHAR}	{
						string str2=escapeCharIdentifier[yytext[2]];
						logout<<"Line# "<<line_count<<": Token <CONST_CHAR> Lexeme "<<str2<<" found"<<endl;
						tokenout<<"<CONST_CHAR, "<<str2<<">"<<endl;
					}

[+-]	{
			printOperatorPunctuator("ADDOP", yytext);
		}

[*/%]	{
			printOperatorPunctuator("MULOP", yytext);
		}

"++"|"--"	{
				printOperatorPunctuator("INCOP", yytext);
			}

"<"|"<="|">"|">="|"=="|"!="	{
								printOperatorPunctuator("RELOP", yytext);
							}

\=	{
		printOperatorPunctuator("ASSIGNOP", yytext);
	}

"&&"|"||"	{
				printOperatorPunctuator("LOGICOP", yytext);
			}

"&"|"|"|"^"|"<<"|">>"	{
							printOperatorPunctuator("BITOP", yytext);
						}

\!	{
		printOperatorPunctuator("NOT", yytext);
	}

\(	{
		printOperatorPunctuator("LPAREN", yytext);
	}

\)	{
		printOperatorPunctuator("RPAREN", yytext);
	}																																						   																								

\{	{
		printOperatorPunctuator("LCURL", yytext);
		scopeTableID++;
		symbolTable.enterScope(scopeTableID, bucketLength, logout);
	}

\}	{
		printOperatorPunctuator("RCURL", yytext);
		symbolTable.exitScope(false, logout);
	}

\[	{
		printOperatorPunctuator("LSQUARE", yytext);
	}

\]	{
		printOperatorPunctuator("RSQUARE", yytext);
	}

\,	{
		printOperatorPunctuator("COMMA", yytext);
	}

\;	{
		printOperatorPunctuator("SEMICOLON", yytext);
	}

{IDENTIFIER}	{
					logout<<"Line# "<<line_count<<": Token <ID> Lexeme "<<yytext<<" found"<<endl;
					tokenout<<"<ID, "<<yytext<<">"<<endl;
					SymbolInfo* symbol = new SymbolInfo(yytext, "ID");

					if(symbolTable.insertKey(*symbol, logout)){
						symbolTable.printAll(logout);
					}
				}	

\"	{
		str=yytext;
		strStart=line_count;
		BEGIN STRING;
	}

<STRING>\\{NEWLINE} {
						str+=yytext;
						line_count++;
					}

<STRING>\\\"	{
					str+=yytext;
				}					

<STRING>[^\"\n\r]	{
						str+=yytext;
					}

<STRING>\"	{
				str+=yytext;

				if(strStart == line_count){
					logout<<"Line# "<<strStart<<": Token <SINGLE LINE STRING> Lexeme "<<str<<" found"<<endl;
				}
				else{
					logout<<"Line# "<<strStart<<": Token <MULTI LINE STRING> Lexeme "<<str<<" found"<<endl;
				}

				string str2="";

				for(int i=1; i<str.length()-1; i++){

					if(str[i] == '\\'){
						str2+=escapeCharIdentifier[str[i+1]];
						i++;
						continue;
					}
					str2+=str[i];
				}

				if(strStart == line_count){
					tokenout<<"<SINGLE LINE STRING, "<<str2<<">"<<endl;
				}
				else{
					tokenout<<"<MULTI LINE STRING, "<<str2<<">"<<endl;
				}

				BEGIN INITIAL;

			}

<STRING>{NEWLINE}	{
						str+=yytext;
						error_count++;
						logout<<"Error at line# "<<line_count<<": UNFINISHED_STRING "<<str;
						line_count++;
						BEGIN INITIAL;
					}

<STRING><<EOF>>	{
					//line_count--;
					error_count++;
					logout<<"Error at line# "<<line_count<<": UNFINISHED_STRING "<<str<<endl;
					symbolTable.printAll(logout);
					logout<<"Total lines: "<<line_count<<endl;
					logout<<"Total errors: "<<error_count<<endl;
					return 0;
				}					


"//"	{
			str=yytext;
			strStart=line_count;
			BEGIN SINGLELINE_COMMENT;
		}


<SINGLELINE_COMMENT>.	{
							str+=yytext;
						}

<SINGLELINE_COMMENT>\\{NEWLINE}	{
									str+=yytext;
									line_count++;
								}

<SINGLELINE_COMMENT>{NEWLINE}	{
									logout<<"Line# "<<strStart<<": Token <SINGLE LINE COMMENT> Lexeme "<<str<<" found"<<endl;
									line_count++;
									BEGIN INITIAL;
								}
																																				
<SINGLELINE_COMMENT><<EOF>>	{
								//line_count--;
								logout<<"Line# "<<strStart<<": Token <SINGLE LINE COMMENT> Lexeme "<<str<<" found"<<endl;
								symbolTable.printAll(logout);
								logout<<"Total lines: "<<line_count<<endl;
								logout<<"Total errors: "<<error_count<<endl;
								return 0;
							}


"/*"	{
			str=yytext;
			strStart=line_count;
			BEGIN MULTILINE_COMMENT;
		}


<MULTILINE_COMMENT>.	{
							str+=yytext;
						}

<MULTILINE_COMMENT>{NEWLINE}	{
									str+=yytext;
									line_count++;
								}

<MULTILINE_COMMENT>"*/"	{
								str+=yytext;
								logout<<"Line# "<<strStart<<": Token <MULTI LINE COMMENT> Lexeme "<<str<<" found"<<endl;
								BEGIN INITIAL;
							}
																																				
<MULTILINE_COMMENT><<EOF>>	{
								//line_count--;
								error_count++;
								logout<<"Error at line# "<<line_count<<": UNFINISHED_COMMENT "<<str<<endl;
								symbolTable.printAll(logout);
								logout<<"Total lines: "<<line_count<<endl;
								logout<<"Total errors: "<<error_count<<endl;
								return 0;
							}


{TOO_MANY_DECIMAL_POINTS}	{
								logout<<"Error at line# "<<line_count<<": TOO_MANY_DECIMAL_POINTS "<<yytext<<endl;
								error_count++;
							}

{ILLFORMED_NUMBER}	{
						logout<<"Error at line# "<<line_count<<": ILLFORMED_NUMBER "<<yytext<<endl;
						error_count++;
					}

{INVALID_ID_SUFFIX_NUM_PREFIX}	{
									logout<<"Error at line# "<<line_count<<": INVALID_ID_SUFFIX_NUM_PREFIX "<<yytext<<endl;
									error_count++;
								}

{MULTICHAR_CONST_CHAR}	{
							logout<<"Error at line# "<<line_count<<": MULTICHAR_CONST_CHAR "<<yytext<<endl;
							error_count++;
						}

{UNFINISHED_CONST_CHAR}	{
							logout<<"Error at line# "<<line_count<<": UNFINISHED_CONST_CHAR "<<yytext<<endl;
							error_count++;
						}

{EMPTY_CONST_CHAR}	{
							logout<<"Error at line# "<<line_count<<": EMPTY_CONST_CHAR "<<yytext<<endl;
							error_count++;
						}						


<<EOF>>	{
			symbolTable.printAll(logout);
			logout<<"Total lines: "<<line_count<<endl;
			logout<<"Total errors: "<<error_count<<endl;
			return 0;
		}

.	{
		logout<<"Error at line# "<<line_count<<": UNRECOGNIZED_CHAR "<<yytext<<endl;
		error_count++;
	}																

%%

int main(int argc, char** argv) {
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout.open("1905097_log.txt");
	tokenout.open("1905097_token.txt");

	scopeTableID++;
	symbolTable.enterScope(scopeTableID, bucketLength, logout);

	yyin= fin;
	yylex();
	//st.print();
	fclose(yyin);
	tokenout.close();
	logout.close();
	return 0;
}
