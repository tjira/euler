program main
    implicit none

    integer :: sum, fib0, fib1, tmp

    sum = 2; fib0 = 1; fib1 = 2

    do while (fib1 < 4000000)
        tmp = fib0; fib0 = fib1

        fib1 = fib1 + tmp

        if (mod(fib1, 2) == 0) then
            sum = sum + fib1
        end if
    end do

    print "(I0)", sum
end program main
