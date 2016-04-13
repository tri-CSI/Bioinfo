#include <iostream>
#include <array>

using namespace std;

int main() {

int array1[4][4] = {12,22,34,45,33,1,2,5,4,98,21,13,3,21,45,11};

for (int row = 0; row < 4; row++)
{
    for (int column = 0; column <= 4; column++)
    {
        if (row == column || row==3-column)
        {
            cout << array1[row][column] << " ";
        }
    }
}

std::array<int,3> array2 = {};

for (int row = 0; row < array2.size(); row++)
{
    cout << array2[row] << " ";
}
char me[] = " hsk" "jsh ";
cout << endl << "This" << me << "is"           " me" <<endl;

}
