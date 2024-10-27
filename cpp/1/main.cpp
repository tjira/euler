#include <iostream>

int main() {
    // define the sum
    int sum = 0;

    // sum the multiples of 3 and 5
    for (int i = 1; i < 1000; i++) {
        if (i % 3 == 0 || i % 5 == 0) sum += i;
    }

    // print the result
    std::cout << sum << std::endl;
}
