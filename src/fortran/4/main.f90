module functions
    use iso_fortran_env, only: int64, real64

    implicit none
contains
    logical function is_palindrome(n)
        integer(int64), intent(in) :: n
        integer(int64) :: i

        do i = 1_int64, number_length(n) / 2_int64
            if (digit(n, i) /= digit(n, number_length(n) - i + 1_int64)) then
                is_palindrome = .false.
                return
            end if
        end do

        is_palindrome = .true.
    end function is_palindrome

    function digit(n, k) result(d)
        integer(int64), intent(in) :: n, k
        integer(int64) :: d

        d = mod(n / 10_int64**(k - 1_int64), 10_int64)
    end function digit

    function number_length(n) result(len)
        integer(int64), intent(in) :: n
        integer(int64) :: len
        real(real64) :: val

        val = abs(real(n, kind=real64))

        len = int(log10(val)) + 1_int64
    end function number_length
end module functions

program main
    use functions

    use iso_fortran_env, only: int64

    implicit none

    integer(int64) :: i, j, n

    n = 0_int64

    do i = 100_int64, 999_int64
        do j = 100_int64, 999_int64
            if (is_palindrome(i * j)) then
                if (i * j > n) then
                    n = i * j
                end if
            end if
        end do
    end do
    
    print "(I0)", n
end program main
