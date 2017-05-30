program test_subspace
use,intrinsic:: iso_fortran_env, only: int64, stderr=>error_unit
use,intrinsic:: iso_c_binding, only: c_int
use comm, only: dp, sizeof
use perf, only: sysclock2ms,assert
use subspace, only: esprit
use signals,only: signoise

implicit none

integer(c_int) :: Ns = 1024, &
           Ntone=2
real(dp) :: fs=48000, &
            f0=12345.6, &
            snr=60  !dB
integer(c_int) :: M

complex(dp),allocatable :: x(:)
real(dp),allocatable :: tones(:),sigma(:)

integer(int64) :: tic,toc
integer :: narg
character(len=16) :: arg
!----------- parse command line ------------------
M = Ns / 2
narg = command_argument_count()

if (narg > 0) call get_command_argument(1,arg); read(arg,*) Ns
if (narg > 1) call get_command_argument(2,arg); read(arg,*) fs
if (narg > 2) call get_command_argument(3,arg); read(arg,*) Ntone
if (narg > 3) call get_command_argument(4,arg); read(arg,*) M
if (narg > 4) call get_command_argument(5,arg); read(arg,*) snr !dB

print *, "Fortran Esprit: Complex Double Precision"
!---------- assign variable size arrays ---------------
allocate(x(Ns), tones(Ntone), sigma(Ntone))
!--- checking system numerics --------------
if (sizeof(fs) /= 8) then
    write(stderr,*) 'expected 8-byte real but you have real bytes: ', sizeof(fs)
    error stop
endif
if (sizeof(x(1)) /= 16) then
    write(stderr,*) 'expected 16-byte complex but you have complex bytes: ', sizeof(x(1))
    error stop
endif

!------ simulate noisy signal ------------ 
call signoise(fs,f0,snr,Ns,&
              x)
!------ estimate frequency of sinusoid in noise --------
call system_clock(tic)
call esprit(x, size(x), Ntone, M, fs, &
            tones,sigma)
call system_clock(toc)

! -- assert <0.1% error ---------
call assert(abs(tones(1)-f0) <= 0.001*f0)

print *, 'estimated tone freq [Hz]: ',tones
print *, 'with sigma: ',sigma
print *, 'seconds to estimate frequencies: ',sysclock2ms(toc-tic)/1000

print *,'OK'

! deallocate(x,tones,sigma) ! this is automatic going out of scope
end program test_subspace



