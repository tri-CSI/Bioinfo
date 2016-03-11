#include <string>
#define ERROR "ERROR"

// Function: Interpret repeating block 
// In: remaining regex expression when a '[' has been encountered
// Out: repeated block without metacharacters
// Return ERROR if metacharacters are used wrongly
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
            case '{':
            case '}':
                return ERROR;
            case '\\':
                current = *(*remaining)++;
                // a string cannot be terminated with a single '\'
                // Though '\\' is ok
                if (current == '\0') return ERROR;
                repeat_str += current;
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

// Function: Interpret regex expression by matching metacharacters
// In: the regex expression
// Out: literal string without metacharacters
// Return ERROR if metacharacters are used wrongly
std::string InterpretPattern( const unsigned char * pMatch )
{
    std::string result = "";
    std::string repBlock = "";

    // add all literal characters until a repeat block [xxx]{d} if found
    while ( *pMatch ) {
        unsigned char current = *pMatch++;
        switch (current) {
            case '[':
                repBlock = RepeatString( &pMatch );
                if (repBlock == ERROR) return ERROR;
                else result += repBlock;
                break;
            case ']':
            case '{':
            case '}':
                return ERROR;
            case '\\':
                current = *pMatch++;
                // a string cannot be terminated with a single '\'
                // Though '\\' is ok
                if (current == '\0') return ERROR;
                result += current;
                break;
            default:
                result += current; 
        }
    }
    return result;
}


// Function: Determine if string starts with pattern
// In: string to match and pattern
// Out: true if string contains pattern at position 0, false otherwise
bool ExactMatch( const unsigned char * pStr, const unsigned char * pMatch )
{
    if ( ! *pMatch ) return true;
    return ( *pStr == *pMatch ) ? ExactMatch( ++pStr, ++pMatch) : false;
}

// Function: Search for literal pattern in string
// In: string to search for and pattern
// Out: true if string contains pattern, false otherwise
bool LiteralSearch( const unsigned char * pStr, const unsigned char * pMatch )
{
    while ( *pStr ) {
        if ( ExactMatch( pStr++, pMatch) )
            return true;
    }
    return false;
}

// Our main function with given signatures
std::string PatternSearch( const unsigned char * pStr, const unsigned char * pMatch )
{
    std::string answer = "";
    std::string match_str = "";
    unsigned char * match_arr;
    
    // Interpret the pattern into a literal characters only 
    match_str = InterpretPattern( pMatch );
    
    if (match_str == ERROR) 
        return ERROR;

    // Search the input string to find matched pattern
    match_arr = new unsigned char [ match_str.length() + 1 ];
    
    for ( int i = 0; i < match_str.length(); i++ ) 
        match_arr[i] = match_str[i];
    match_arr[match_str.length()] = '\0';

    if ( LiteralSearch( pStr, match_arr ) ) 
        answer = match_str;

    delete[] match_arr;
    
    return answer;
}
