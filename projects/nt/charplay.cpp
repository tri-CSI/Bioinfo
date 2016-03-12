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
        getline( is, answer, '\r');
        
        int lstr = str.length(), lmch = mch.length();
        pstr = new unsigned char [lstr + 1];
        strcpy( (char *)pstr, str.c_str() );
        match = new unsigned char [lmch + 1];
        strcpy( (char *)match, mch.c_str() );
        
        if (answer == "None") answer = "";
        myans = PatternSearch( pstr, match ); //(const unsigned char* pStr, const unsigned char* pMatch)
        if ( myans == answer ) 
            cout << "PASS: " << myans << " " << myans.length() << ", " << answer  << " " << answer.length() << endl;
        else
            cout << "FAIL: " << myans << " " << myans.length() << ", " << answer  << " " << answer.length() << endl;
        delete [] pstr;
        delete [] match;
    }
}
