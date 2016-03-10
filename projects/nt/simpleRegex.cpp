#include <string>
#define ERROR "ERROR"

std::string RepeatString( const unsigned char ** remaining )
{
    std::string result = "";
    std::string repeat_str = "";
    std::string nestedRep;
    bool endRepeat = false;
    int repeat_num = 0;

    while ( **remaining && not endRepeat ) {
        unsigned char current = *(*remaining)++;

        switch (current) {
            case '[':
                nestedRep = RepeatString( remaining );
                if (nestedRep == ERROR) return ERROR;
                else repeat_str += nestedRep;
                break;
            case ']':
                endRepeat = true;
                break;
            default:
                repeat_str += current; 
        }
    }

    // Next char must be '{'
    if (*(*remaining)++ != '{') return ERROR;

    // Parse digits of repeat count
    while ( **remaining != '}') {
        unsigned char current = *(*remaining)++;
        if ( current < '0' && current > '9' ) return ERROR;
        repeat_num = repeat_num * 10 + current - '0';
    }

    // Next char must be '}'
    // Should have been checked by previous step...
    // This step also does the increment before returning to previous function
    // Can just simply be
    // *(*remaining)++;
    if (*(*remaining)++ != '}') return ERROR;
    
    // Repeat the string 
    // This also accept 0 repeat, which is interesting
    // But why not!
    while (repeat_num--) result += repeat_str;
    
    return result;
}

std::string PatternSearch( const unsigned char * pStr, const unsigned char * pMatch )
{
    std::string answer = "";
    std::string repBlock;
    
    while ( *pMatch ) {
        unsigned char current = *pMatch++;
        switch (current) {
            case '[':
                repBlock = RepeatString( &pMatch );
                if (repBlock == ERROR) return ERROR;
                else answer += repBlock;
                break;
            case ']':
            case '{':
            case '}':
                return ERROR;
            default:
                answer += current; 
        }
    }
    
    return answer;
}
