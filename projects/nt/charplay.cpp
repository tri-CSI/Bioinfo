#include <iostream>
#include <sstream>
#include <string>
#include <cstring>
#include "simpleRegex.h"

using namespace std;

int main() {
    std::string one_line, str, mch, answer, myans;
    unsigned char * pstr;
    unsigned char * match;
    
    while ( getline( cin, one_line ) )
    {
        istringstream is( one_line );
        
        getline( is, str, '\t');
        getline( is, mch, '\t');
        getline( is, answer);
        
        int lstr = str.length(), lmch = mch.length();
        pstr = new unsigned char [lstr + 1];
        strcpy( (char *)pstr, str.c_str() );
        pstr[lstr] = '\0';
        match = new unsigned char [lmch + 1];
        strcpy( (char *)match, mch.c_str() );
        match[lmch] = '\0';
        
        if (answer == "None") answer = "";
        myans = PatternSearch( pstr, match ); //(const unsigned char* pStr, const unsigned char* pMatch)
        if ( myans == answer ) 
            cout << "PASS: " << myans << endl;
        else
            cout << "FAIL: " << myans << endl;
        delete [] pstr;
        delete [] match;
    }
}
