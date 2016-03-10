#include <iostream>
#include <string>
#include "simpleRegex.h"

using namespace std;

int main() {
    unsigned char string[] = "Amplicon DS";
    unsigned char match[] = "licon";
    
    std::string myans;
    std::string answer ="licon";
    
    myans = PatternSearch( string, match ); //(const unsigned char* pStr, const unsigned char* pMatch)
        
    if (myans == answer) 
        cout << "PASS: " << myans << endl;
    else 
        cout << "FAIL: " << myans << endl;
}
