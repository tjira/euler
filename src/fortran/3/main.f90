module functions
    use iso_fortran_env, only: int64

    implicit none
contains
    logical function is_prime(n)
        integer(int64), intent(in) :: n
        integer(int64) :: d

        d = 3

        do while (d*d <= n)
            if (mod(n, d) == 0_int64) then
                is_prime = .false.
                return
            end if

            d = d + 2_int64
        end do

        is_prime = .true.
    end function is_prime
end module functions

program main
    use functions

    use iso_fortran_env, only: int64

    implicit none

    integer(int64) :: n, d, i

    n = 600851475143_int64
    i = 3_int64

    do while (i*i <= n)
        if (mod(n, i) == 0) then
            if (is_prime(i)) then
                d = i
            end if
        end if

        i = i + 2_int64
    end do

    print "(I0)", d
end program main
