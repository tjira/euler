program main
   implicit none

   integer :: sum, i

   sum = 0

   do i = 1, 999
      if (mod(i, 3) == 0 .or. mod(i, 5) == 0) then
         sum = sum + i
      end if
   end do

   print "(I0)", sum
end program main
