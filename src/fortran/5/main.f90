program main
    use iso_fortran_env, only: int64

    implicit none

    integer(int64) :: n, i, d
    logical :: this_is_it

    n = 1_int64

    do while (.true.)
        this_is_it = .true.

        do d = 1_int64, 20_int64
            if (mod(n, d) /= 0_int64) then
                this_is_it = .false.

                exit
            end if
        end do

        if (this_is_it) then
            exit
        end if

        n = n + 1_int64
    end do

    print "(I0)", n
end program main
