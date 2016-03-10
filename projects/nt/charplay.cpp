#include <iostream>
#include <string>
#include <cstring>
#include "simpleRegex.h"

using namespace std;

int main() {
    std::string str_to_search, regex, answer, myans;
    unsigned char pstr[1000], match[1000];
    
    while (true) {
        cin >> str_to_search;
        cin >> regex;
        cin >> answer;
        std::strcpy( (char*) pstr, str_to_search.c_str() );
        std::strcpy( (char*) match, regex.c_str() );
        myans = PatternSearch( pstr, match ); //(const unsigned char* pStr, const unsigned char* pMatch)
            
        if (myans == answer) 
            cout << "PASS: " << myans << endl;
        else 
            cout << "FAIL: " << myans << endl;
        break;
    }
}
