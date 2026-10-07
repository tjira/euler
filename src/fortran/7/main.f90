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

    implicit none

    integer(int64) :: n, p, i

    n = 3
    i = 1

    do while (i < 10001)
        if (is_prime(n)) then
            p = n
            i = i + 1
        end if

        n = n + 2
    end do

    print "(I0)", p
end program main
