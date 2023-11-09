#include<iostream>
#include<string>
#include<cstdlib>
#include<fstream>

using namespace std;

class SymbolInfo{

    string name;
    string type;
    SymbolInfo* next;

public:

    SymbolInfo(){

    }

    SymbolInfo(string name, string type){
        this->name=name;
        this->type=type;
        next=NULL;
    }

    ~SymbolInfo(){

    }

    string getName(){
        return name;
    }

    string getType(){
        return type;
    }

    void setNext(SymbolInfo* next){
        this->next=next;
    }

    SymbolInfo* getNext(){
        return next;
    }
};

class ScopeTable{

    int id;
    int bucketLength;
    SymbolInfo** bucketList;
    ScopeTable* parentScope;

    long long sdbmHash(string str){
        long long hashValue=0;

        for (int i=0;i<str.length();i++){
		    hashValue = (str[i]) + (hashValue << 6) + (hashValue << 16) - hashValue;
	    }

	    return (hashValue%bucketLength);
    }

public:

    ScopeTable(){

    }

    ScopeTable(int id, int bucketLength, ScopeTable* parentScope){

        this->id=id;
        this->bucketLength=bucketLength;
        this->parentScope=parentScope;

        this->bucketList=new SymbolInfo*[bucketLength];
        for(int i=0;i<bucketLength;i++){
            bucketList[i]=NULL;
        }
    }

    ~ScopeTable(){
        for(int i = 0; i < bucketLength; i++){
            SymbolInfo* symbol = bucketList[i];
            if(symbol != NULL){
                SymbolInfo* tmp = symbol;
                symbol = symbol->getNext();
                delete tmp;
            }
        }
        delete[] bucketList;
    }

    void setId(int id){
        this->id=id;
    }

    int getId(){
        return id;
    }

    void setBucketLength(int bucketLength){
        this->bucketLength=bucketLength;
    }

    int getBucketLength(){
        return bucketLength;
    }

    ScopeTable* getParentScope(){
        return parentScope;
    }

    SymbolInfo* lookUp(string str,ofstream& out){
        int ind=sdbmHash(str);

        SymbolInfo* tmp=bucketList[ind];
        int pos=1;

        while(tmp!=NULL){
            if(tmp->getName()==str){
                out<<"\t'"<<str<<"' found in ScopeTable# "<<id<<" at position "<<ind+1<<", "<<pos<<endl;
                return tmp;
            }
            tmp=tmp->getNext();
            pos++;
        }
        //cout<<"Not found"<<endl;
        return NULL;
    }

    bool insertKey(SymbolInfo& symbol,ofstream& out){
        int ind=sdbmHash(symbol.getName());

        SymbolInfo* tmp=bucketList[ind];

        while(tmp!=NULL){
            if(tmp->getName()==symbol.getName()){
                out<<"\t"<<symbol.getName()<<" already exisits in the current ScopeTable"<<endl;
                return false;
            }
            tmp=tmp->getNext();
        }

        tmp=bucketList[ind];
        //out<<"\tInserted in ScopeTable# "<<id<<" at position "<<ind+1<<", ";
        int pos=1;

        if(tmp==NULL){
            bucketList[ind]=&symbol;
            symbol.setNext(NULL);
            //out<<pos<<endl;
            return true;
        }

        while(tmp->getNext()!=NULL){
            tmp=tmp->getNext();
            pos++;
        }

        pos++;
        tmp->setNext(&symbol);
        symbol.setNext(NULL);
        //out<<pos<<endl;
        return true;
    }

    bool deleteKey(string str,ofstream& out){

        int ind=sdbmHash(str);
        SymbolInfo* tmp=bucketList[ind];
        SymbolInfo* prev=NULL;
        bool flag=false;
        int pos=1;

        while(tmp!=NULL){
            if(tmp->getName()==str){
               flag=true;
               break;
            }
            prev=tmp;
            tmp=tmp->getNext();
            pos++;
        }

        if(!flag){
           out<<"\tNot found in the current ScopeTable"<<endl;
           return false;
        }

        if(prev==NULL){
            bucketList[ind]=tmp->getNext();
        }
        else{
            prev->setNext(tmp->getNext());
        }

        delete tmp;
        out<<"\tDeleted '"<<str<<"' from ScopeTable# "<<id<<" at position "<<ind+1<<", "<<pos<<endl;
        return true;
    }

    void print(ofstream& out){
        out<<"\tScopeTable# "<<id<<endl;

        for (int i = 0; i < bucketLength; i++)
        {
            SymbolInfo *tmp = bucketList[i];

            if (tmp != NULL){
               out << "\t" << i + 1 << "--> ";
               while (tmp != NULL)
               {
                   out << "<" << tmp->getName() << "," << tmp->getType() << "> ";
                   tmp = tmp->getNext();
               }
               out << endl;
            }
        }
    }

};

class SymbolTable{

    ScopeTable* cur;

public:

    SymbolTable(){
        cur=NULL;
    }

    ~SymbolTable(){

        ScopeTable *tmp = cur;
        while (tmp != NULL){
            cur = cur->getParentScope();
            delete tmp;
            tmp = cur;
        }
    }

    void enterScope(int id,int bucketLength,ofstream& out){
        ScopeTable* tmp=new ScopeTable(id,bucketLength,cur);
        //out<<"\tScopeTable# "<<id<<" created"<<endl;
        cur=tmp;
    }

    void exitScope(bool flag,ofstream& out){
        if(cur==NULL){
           out<<"\tNo Scopetable"<<endl;
           return;
        }

        ScopeTable* tmp=cur;
        if(tmp->getId()==1&&!flag){
           //out<<"\tScopeTable# "<<tmp->getId()<<" cannot be removed"<<endl;
           return;
        }
        cur=cur->getParentScope();

        //out<<"\tScopeTable# "<<tmp->getId()<<" removed"<<endl;
        delete tmp;
        return;
    }

    bool insertKey(SymbolInfo& symbol,ofstream& out){
        if(cur==NULL){
           out<<"\tInsertion not possible"<<endl;
           return false;
        }

        return cur->insertKey(symbol,out);
    }

    bool deleteKey(string str,ofstream& out){

        if(cur==NULL){
           out<<"\tDeletion not possible"<<endl;
           return false;
        }

        return cur->deleteKey(str,out);
    }

    SymbolInfo* lookUp(string str,ofstream& out){

        if(cur==NULL){
           out<<"\tLookup is not posssible"<<endl;
           return NULL;
        }

        ScopeTable* tmp=cur;
        SymbolInfo* ans=NULL;

        while(tmp!=NULL){
            ans=tmp->lookUp(str,out);

            if(ans!=NULL){
                break;
            }

            tmp=tmp->getParentScope();
        }

        if(ans==NULL){
           out<<"\t'"<<str<<"' not found in any of the ScopeTables"<<endl;
        }

        return ans;
    }

    void printCur(ofstream& out){

        if(cur==NULL){
           out<<"\tNo scope Table"<<endl;
           return;
        }

        cur->print(out);
    }

    void printAll(ofstream& out){

        if(cur==NULL){
           out<<"\tNo scope Table"<<endl;
           return;
        }

        ScopeTable* tmp=cur;

        while(tmp!=NULL){
            tmp->print(out);
            tmp=tmp->getParentScope();
        }
    }

};

/*
int main()
{

    ifstream in("input.txt");
    ofstream out("output.txt");

    if(!in.is_open()){
       exit(1);
    }

    if(!out.is_open()){
       exit(1);
    }

    int bucketLength,scopeNum=0,totalScope=0;
    //cin>>bucketLength;
    in>>bucketLength;

    SymbolTable symbolTable;
    scopeNum++;
    symbolTable.enterScope(scopeNum,bucketLength,out);
    totalScope++;
    int cmdNo=0;
    string line;
    getline(in,line);

    //string name,type,op;
    while(getline(in,line)){
        //cin>>op;
        //getline(cin,line);
        //cout<<cmdNo<<endl;
        cmdNo++;
        out<<"Cmd "<<cmdNo<<": "<<line<<endl;
        string command[4];
        int start=0,l=0,t=0;

        for(int i=0;i<line.size();i++){

            if(line[i]==' '&&l>0){
               command[t]=line.substr(start,l);
               t++;
               start=i+1;
               l=0;
               if(t>3){
                  break;
               }
            }

            else if(line[i]==' '){
                start++;
            }

            else{
                l++;
            }
        }

        if(l>0){
           command[t]=line.substr(start,l);
           t++;
        }

        if(command[0]=="I"){
           //cin>>name>>type;
           //cout<<"Cmd "<<cmdNo<<": "<<op<<" "<<name<<" "<<type<<endl;
           if(t!=3){
              out<<"\tNumber of parameters mismatch for the command I"<<endl;
              continue;
           }

           SymbolInfo* symbol=new SymbolInfo(command[1],command[2]);
           symbolTable.insertKey(*symbol,out);
        }

        else if(command[0]=="L"){
            //cin>>name;
            //cout<<"Cmd "<<cmdNo<<": "<<op<<" "<<name<<endl;
            if(t!=2){
               out<<"\tNumber of parameters mismatch for the command L"<<endl;
               continue;
            }

            symbolTable.lookUp(command[1],out);
        }

        else if(command[0]=="D"){
            //cin>>name;
            //cout<<"Cmd "<<cmdNo<<": "<<op<<" "<<name<<endl;
            if(t!=2){
               out<<"\tNumber of parameters mismatch for the  command D"<<endl;
               continue;
            }

            symbolTable.deleteKey(command[1],out);
        }

        else if(command[0]=="S"){
            //cout<<"Cmd "<<cmdNo<<": "<<op<<endl;
            if(t!=1){
               out<<"\tNumber of parameters mismatch for the command S"<<endl;
               continue;
            }

            scopeNum++;
            symbolTable.enterScope(scopeNum,bucketLength,out);
            totalScope++;
        }

        else if(command[0]=="E"){
            //cout<<"Cmd "<<cmdNo<<": "<<op<<endl;
            if(t!=1){
               out<<"\tNumber of parameters mismatch for the command E"<<endl;
               continue;
            }

            symbolTable.exitScope(false,out);
            if(totalScope>1){
               totalScope--;
            }
        }

        else if(command[0]=="P"){
            //cin>>name;
            //cout<<"Cmd "<<cmdNo<<": "<<op<<" "<<name<<endl;
            if(t!=2){
               out<<"\tNumber of parameters mismatch for the command P"<<endl;
               continue;
            }

            if(command[1]=="A"){
               symbolTable.printAll(out);
            }
            else if(command[1]=="C"){
                symbolTable.printCur(out);
            }

        }

        else{
            //cout<<"Cmd "<<cmdNo<<": "<<op<<endl;
            break;
        }

    }

    //cout<<totalScope<<endl;
    for(int i=0;i<totalScope;i++){
        symbolTable.exitScope(true,out);
    }

    in.close();
    out.close();
    return 0;

}
*/