fn main() {
    // define the sum
    let mut sum = 0;

    // calculate the sum
    for i in 1..1000 {
        if i % 3 == 0 || i % 5 == 0 {
            sum += i;
        }
    }

    // print the result
    println!("{}", sum);
}
