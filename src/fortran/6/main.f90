program main
    use iso_fortran_env, only: int64

    implicit none

    integer(int64) :: sum_of_squares, square_of_sum, n

    do n = 1, 100
        sum_of_squares = sum_of_squares + n**2

        square_of_sum = square_of_sum + n
    end do

    square_of_sum = square_of_sum**2

    print "(I0)", square_of_sum - sum_of_squares
end program main
