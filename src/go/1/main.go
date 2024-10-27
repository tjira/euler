package main

import "fmt"

func main() {
    // define the sum
    sum := 0

    // calculate the sum
    for i := 1; i < 1000; i++ {
        if i % 3 == 0 || i % 5 == 0 {
            sum += i
        }
	}

    // print the result
	fmt.Println(sum)
}
