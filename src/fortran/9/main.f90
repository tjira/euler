program main
    use iso_fortran_env, only: int64

    implicit none

    integer(int64) :: a, b, c, prod

    outer: do a = 1, 1000
        do b = 1, 1000
            do c = 1, 1000
                if (a**2 + b**2 == c**2 .and. a + b + c == 1000) then
                    prod = a*b*c

                    exit outer
                end if
            end do
        end do
    end do outer

    print "(I0)", prod
end program main
