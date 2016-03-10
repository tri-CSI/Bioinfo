#include <string>

std::string RepeatString( const unsigned char ** remaining )
{
    std::string result;
    return result;
}

std::string PatternSearch( const unsigned char * pStr, const unsigned char * pMatch )
{
    const std::string error = "ERROR";
    std::string answer = "";
    std::string expandedMatch = "";
    int i = 0;       
    
    while ( pMatch[i] ) {
        unsigned char current = pMatch[i++];
        switch (current) {
            case '[':
            case ']':
            case '{':
            case '}':
                return error;
            default:
                expandedMatch += current; 
        }
    }
    answer = expandedMatch;
    
    return answer;
}
