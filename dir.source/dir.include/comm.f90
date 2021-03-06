module comm

use,intrinsic:: iso_fortran_env, only: stdout=>output_unit, stderr=>error_unit, wp=>real32, dp=>real64
implicit none
public

real(dp),parameter :: pi = 4._dp*atan(1._dp)
real(dp),parameter :: deg2rad = pi/180._dp
real(dp),parameter :: rad2deg = 180/pi

integer, parameter :: npt=500

logical :: debug=.false.


real :: tic,toc

character(512) :: data_path
integer :: lpath


contains


end module comm
