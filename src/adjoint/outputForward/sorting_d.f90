!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
module sorting_d
  use utils_d, only : terminate
  implicit none
! ----------------------------------------------------------------------
!                                                                      |
!                    no tapenade routine below this line               |
!                                                                      |
! ----------------------------------------------------------------------

contains
  function faminlist(famid, famlist)
    use constants
    implicit none
    integer(kind=inttype), intent(in) :: famid, famlist(:)
    logical :: faminlist
    faminlist = .false.
    if (bsearchintegers(famid, famlist) .gt. 0) faminlist = .true.
  end function faminlist
  function bsearchintegers(key, base)
!
!       bsearchintegers returns the index in base where key is stored. 
!       a binary search algorithm is used here, so it is assumed that  
!       base is sorted in increasing order. in case key appears more   
!       than once in base, the result is arbitrary. if key is not      
!       found, a zero is returned.                                     
!
    use precision
    implicit none
!
!      function type
!
    integer(kind=inttype) :: bsearchintegers
!
!      function arguments.
!
    integer(kind=inttype), intent(in) :: key
    integer(kind=inttype), dimension(:), intent(in) :: base
    integer(kind=inttype) :: nn
!
!      local variables.
!
    integer(kind=inttype) :: ii, pos, start
    logical :: entryfound
    intrinsic size
! initialize some values.
    start = 1
    ii = size(base)
    entryfound = .false.
! binary search to find key.
    do 100 
! condition for breaking the loop
      if (ii .ne. 0) then
! determine the position in the array to compare.
        pos = start + ii/2
! in case this is the entry, break the search loop.
        if (base(pos) .eq. key) then
          entryfound = .true.
        else
! in case the search key is larger than the current position,
! only parts to the right must be searched. remember that base
! is sorted in increasing order. nothing needs to be done if the
! key is smaller than the current element.
          if (key .gt. base(pos)) then
            start = pos + 1
            ii = ii - 1
          end if
! modify ii for the next branch to search.
          ii = ii/2
          goto 100
        end if
      end if
! set bsearchintegers. this depends whether the key was found.
      if (entryfound) then
        bsearchintegers = pos
      else
        bsearchintegers = 0
      end if
      goto 110
 100 continue
 110 continue
  end function bsearchintegers
end module sorting_d
