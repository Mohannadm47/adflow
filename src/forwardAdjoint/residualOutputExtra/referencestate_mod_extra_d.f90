   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
   !
   !  Differentiation of referencestate_mod in forward (tangent) mode:
   !   variations   of useful results: machcoef veldirfreestream mach
   !                rgas uinf muinf rhoinf timeref pinf
   !   with respect to varying inputs: machcoef veldirfreestream mach
   !                machini rhoini pini veldirini
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          referenceState.f90                              *
   !      * Author:        Edwin van der Weide, Seonghyeon Hahn            *
   !      * Starting date: 05-29-2003                                      *
   !      * Last modified: 04-22-2006                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE REFERENCESTATE_MOD_EXTRA_D()
   USE COUPLERPARAM
   USE COMMUNICATION
   USE INPUTTIMESPECTRAL
   USE FLOWVARREFSTATE
   USE BCTYPES
   USE INPUTPHYSICS
   USE BLOCKPOINTERS_D
   USE ITERATION
   USE CONSTANTS
   USE INPUTMOTION
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * referenceState computes the reference state values in case     *
   !      * these have not been specified. A distinction is made between   *
   !      * internal and external flows. In case nothing has been          *
   !      * specified for the former a dimensional computation will be     *
   !      * made. For the latter the reference state is set to an          *
   !      * arbitrary state for an inviscid computation and computed for a *
   !      * viscous computation. Furthermore for internal flows an average *
   !      * velocity direction is computed from the boundary conditions,   *
   !      * which is used for initialization.                              *
   !      *                                                                *
   !      ******************************************************************
   !
   !
   !      Local variables.
   !
   INTEGER :: ierr
   INTEGER(kind=inttype) :: sps, nn, mm
   REAL(kind=realtype) :: gm1, ratio, tmp
   REAL(kind=realtype) :: mx, my, mz, re, v, tinfdim
   REAL(kind=realtype) :: mxd, myd, mzd, vd
   REAL(kind=realtype), DIMENSION(3) :: dirloc, dirglob
   REAL(kind=realtype), DIMENSION(3) :: dirglobd
   REAL(kind=realtype), DIMENSION(5) :: valloc, valglob
   REAL(kind=realtype), DIMENSION(5) :: vallocd
   !REAL(kind=realtype) :: MAXVALUESUBFACE
   EXTERNAL MPI_ALLREDUCE
   EXTERNAL MPI_BARRIER
   REAL(kind=realtype) :: arg1
   REAL(kind=realtype) :: arg1d
   REAL(kind=realtype) :: pwy1
   REAL(kind=realtype) :: pwr1
   REAL(kind=realtype) :: result1
   REAL(kind=realtype) :: result1d
   INTRINSIC MAX
   INTRINSIC MIN
   INTRINSIC SQRT
   REAL(kind=realtype) :: max1
   REAL(kind=realtype) :: y1
   INTERFACE 
   SUBROUTINE VELMAGNANDDIRECTIONSUBFACE(vmag, dir, bcdata, mm)
   USE BLOCK
   INTEGER(kind=inttype), INTENT(IN) :: mm
   REAL(kind=realtype), INTENT(OUT) :: vmag
   REAL(kind=realtype), DIMENSION(3), INTENT(INOUT) :: dir
   TYPE(BCDATATYPE), DIMENSION(:), POINTER :: bcdata
   END SUBROUTINE VELMAGNANDDIRECTIONSUBFACE
   END INTERFACE
      !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Initialize the dimensional free stream temperature and pressure.
   ! From these values the density and viscosity is computed. For
   ! external viscous and internal computation this is corrected
   ! later on.
   pinfdim = pref
   IF (pref .LE. zero) pinfdim = 101325.0_realType
   tinfdim = tempfreestream
   rhoinfdim = pinfdim/(rgasdim*tinfdim)
   mudim = musuthdim*((tsuthdim+ssuthdim)/(tinfdim+ssuthdim))*(tinfdim/&
   &    tsuthdim)**1.5_realType
   ! Check the flow type we are having here.
   IF (flowtype .EQ. internalflow) THEN
   ! Internal flow computation. Initialize the array to store
   ! the local total temperature and pressure and the local static
   ! density pressure and velocity magnitude to -1. Also initialize
   ! the sum of the local flow direction to zero.
   valloc = -one
   dirloc = zero
   ! Loop over the number od spectral modes and local blocks
   ! to  determine the variables described above.
   DO sps=1,ntimeintervalsspectral
   DO nn=1,ndom
   ! Set the pointer for the boundary conditions to make the
   ! code more readable.
   !use blockPointers instead of block
   !BCData => flowDoms(nn,1,sps)%BCData
   CALL SETPOINTERS(nn, 1, sps)
   ! Loop over the number of boundary faces of the
   ! computational block.
   !use blockpointers instead of blockflowDoms(nn,1,sps)%nBocos
   DO mm=1,nbocos
   ! Determine the maximum value of the scalar quantities
   ! for this subface and store them if these are larger
   ! than the currently stored values.
   tmp = MAXVALUESUBFACE(bcdata(mm)%ptinlet)
   IF (valloc(1) .LT. tmp) THEN
   vallocd(1) = 0.0
   valloc(1) = tmp
   ELSE
   vallocd(1) = 0.0
   valloc(1) = valloc(1)
   END IF
   tmp = MAXVALUESUBFACE(bcdata(mm)%ttinlet)
   IF (valloc(2) .LT. tmp) THEN
   vallocd(2) = 0.0
   valloc(2) = tmp
   ELSE
   vallocd(2) = 0.0
   valloc(2) = valloc(2)
   END IF
   tmp = MAXVALUESUBFACE(bcdata(mm)%rho)
   IF (valloc(3) .LT. tmp) THEN
   vallocd(3) = 0.0
   valloc(3) = tmp
   ELSE
   vallocd(3) = 0.0
   valloc(3) = valloc(3)
   END IF
   tmp = MAXVALUESUBFACE(bcdata(mm)%ps)
   IF (valloc(4) .LT. tmp) THEN
   vallocd(4) = 0.0
   valloc(4) = tmp
   ELSE
   vallocd(4) = 0.0
   valloc(4) = valloc(4)
   END IF
   ! Determine the velocity magnitude and sum up the
   ! direction.
   CALL VELMAGNANDDIRECTIONSUBFACE(tmp, dirloc, bcdata, mm)
   IF (valloc(5) .LT. tmp) THEN
   vallocd(5) = 0.0
   valloc(5) = tmp
   ELSE
   vallocd(5) = 0.0
   valloc(5) = valloc(5)
   END IF
   END DO
   END DO
   END DO
   ! Determine the global maxima of valLoc and the sum
   ! of dirLoc.
   CALL MPI_ALLREDUCE(valloc, valglob, 5, sumb_real, mpi_max, &
   &                 sumb_comm_world, ierr)
   CALL MPI_ALLREDUCE(dirloc, dirglob, 3, sumb_real, mpi_sum, &
   &                 sumb_comm_world, ierr)
   arg1 = dirglob(1)**2 + dirglob(2)**2 + dirglob(3)**2
   y1 = SQRT(arg1)
   IF (eps .LT. y1) THEN
   max1 = y1
   ELSE
   max1 = eps
   END IF
   ! Create a unit vector for the global direction.
   tmp = one/max1
   dirglobd(1) = 0.0
   dirglob(1) = tmp*dirglob(1)
   dirglobd(2) = 0.0
   dirglob(2) = tmp*dirglob(2)
   dirglobd(3) = 0.0
   dirglob(3) = tmp*dirglob(3)
   ! Store this direction for the free stream; this will only be
   ! used for initialization.
   veldirfreestream = dirglob
   ! Determine the situation we are having here.
   IF (valglob(1) .GT. zero .AND. valglob(2) .GT. zero) THEN
   ! Total conditions are present.
   ! Compute the value of gamma, which is gammaInf.
   ! This is not entirely correct, because there may be
   ! a difference between the static and total temperature,
   ! but it is only used for an initialization.
   CALL COMPUTEGAMMA(valglob(2), gammainf, 1_intType)
   gm1 = gammainf - one
   ! Check if a static pressure is present. If so, estimate
   ! a much number. If not present, set Mach to 0.5.
   ! Limit the estimated Mach number to 0.5 for stability
   ! reasons.
   IF (valglob(4) .GT. zero) THEN
   IF (valglob(1)/valglob(4) .LT. 1.007017518_realType) THEN
   ratio = 1.007017518_realType
   ELSE
   ratio = valglob(1)/valglob(4)
   END IF
   !     ratio = max((valGlob(1)/valGlob(4)), 1.0000007_realType)
   pwy1 = gm1/gammainf
   tmp = ratio**pwy1
   arg1 = two*(tmp-one)/gm1
   mach = SQRT(arg1)
   IF (mach .GT. half) THEN
   mach = half
   ELSE
   mach = mach
   END IF
   ELSE
   mach = half
   END IF
   ! Set a value of pInfDim and TInfDim. This is just for
   ! initialization. The final solution is independent of it.
   tmp = one + half*gm1*mach*mach
   pwy1 = gammainf/gm1
   pwr1 = tmp**pwy1
   pinfdim = valglob(1)/pwr1
   tinfdim = valglob(2)/tmp
   ! Compute the density.
   rhoinfdim = pinfdim/(rgasdim*tinfdim)
   ELSE IF (valglob(3) .GT. zero .AND. valglob(4) .GT. zero .AND. &
   &        valglob(5) .GT. zero) THEN
   ! Density, pressure and velocity magnitude are present.
   ! Compute the dimensional temperature and the corresponding
   ! value of gamma.
   rhoinfdim = valglob(3)
   pinfdim = valglob(4)
   tinfdim = pinfdim/(rgasdim*rhoinfdim)
   CALL COMPUTEGAMMA(tinfdim, gammainf, 1_intType)
   ! Compute the Mach number.
   arg1 = gammainf*pinfdim/rhoinfdim
   result1 = SQRT(arg1)
   mach = valglob(5)/result1
   ELSE
   ! Not enough boundary data is present for initialization.
   ! This typically occurs when running the code in coupled
   ! mode with another CFD code from which it gets the data.
   ! If the code is run in stand alone mode, terminate.
   IF (standalonemode) THEN
   IF (myid .EQ. 0) CALL TERMINATE('referenceState', &
   &                               'Not enough boundary data is present to '&
   &                                     , &
   &                                   'define a well posed problem for an '&
   &                                     , 'internal flow computation')
   CALL MPI_BARRIER(sumb_comm_world, ierr)
   END IF
   ! Multi-disciplinary mode.
   ! Use rhoIni, pIni, MachIni and velDirIni for initialization.
   ! Processor 0 prints a warning message.
   rhoinfdim = rhoini
   pinfdim = pini
   tinfdim = pinfdim/(rgasdim*rhoinfdim)
   mach = machini
   veldirfreestream = veldirini
   ! Compute the corresponding value of gamma.
   CALL COMPUTEGAMMA(tinfdim, gammainf, 1_intType)
   IF (myid .EQ. 0) THEN
   PRINT'(a)', '#'
   PRINT'(a)', '#*==================== !!! Warning !!! ', &
   &        '======================'
   PRINT'(a)', '# Not enough boundary data is present to ', &
   &        'define a well posed problem for'
   PRINT'(a)', '# an internal flow computation'
   PRINT'(a)', '# It is assumed that the data is supplied ', &
   &        'from a different code'
   PRINT'(a)', '#*=====================================', &
   &        '======================'
   PRINT'(a)', '#'
   END IF
   END IF
   ! Set MachCoef to Mach. Seen the previous lines this is quite
   ! arbitrary, but for an internal flow the coefficients are not
   ! so important anyway.
   machcoef = mach
   ! Compute the value of the molecular viscosity corresponding
   ! to the computed TInfDim.
   mudim = musuthdim*((tsuthdim+ssuthdim)/(tinfdim+ssuthdim))*(tinfdim/&
   &      tsuthdim)**1.5_realType
   ! In case the reference pressure, density and temperature were
   ! not specified, set them to the 1.0, i.e. a dimensional
   ! computation is performed.
   IF (pref .LE. zero) pref = one
   IF (rhoref .LE. zero) rhoref = one
   IF (tref .LE. zero) THEN
   tref = one
   machcoefd = 0.0
   veldirfreestreamd = 0.0
   machd = 0.0
   rhorefd = 0.0
   prefd = 0.0
   pinfdimd = 0.0
   rhoinfdimd = 0.0
   ELSE
   machcoefd = 0.0
   veldirfreestreamd = 0.0
   machd = 0.0
   rhorefd = 0.0
   prefd = 0.0
   pinfdimd = 0.0
   rhoinfdimd = 0.0
   END IF
   ELSE
   ! External flow. Compute the value of gammaInf.
   CALL COMPUTEGAMMA(tempfreestream, gammainf, 1_intType)
   ! In case of a viscous problem, compute the
   ! dimensional free stream density and pressure.
   IF (equations .EQ. nsequations .OR. equations .EQ. ransequations) &
   &    THEN
   ! Compute the x, y, and z-components of the Mach number
   ! relative to the body; i.e. the mesh velocity must be
   ! taken into account here.
   mxd = machcoefd*veldirfreestream(1) + machcoef*veldirfreestreamd(1&
   &        )
   mx = machcoef*veldirfreestream(1)
   myd = machcoefd*veldirfreestream(2) + machcoef*veldirfreestreamd(2&
   &        )
   my = machcoef*veldirfreestream(2)
   mzd = machcoefd*veldirfreestream(3) + machcoef*veldirfreestreamd(3&
   &        )
   mz = machcoef*veldirfreestream(3)
   ! Reynolds number per meter, the viscosity using sutherland's
   ! law and the free stream velocity relative to the body.
   re = reynolds/reynoldslength
   mudim = musuthdim*((tsuthdim+ssuthdim)/(tempfreestream+ssuthdim))*&
   &        (tempfreestream/tsuthdim)**1.5
   arg1d = gammainf*rgasdim*tempfreestream*(mxd*mx+mx*mxd+myd*my+my*&
   &        myd+mzd*mz+mz*mzd)
   arg1 = (mx*mx+my*my+mz*mz)*gammainf*rgasdim*tempfreestream
   IF (arg1 .EQ. 0.0) THEN
   vd = 0.0
   ELSE
   vd = arg1d/(2.0*SQRT(arg1))
   END IF
   v = SQRT(arg1)
   ! Compute the free stream density and pressure.
   ! Set TInfDim to tempFreestream.
   rhoinfdimd = -(re*mudim*vd/v**2)
   rhoinfdim = re*mudim/v
   pinfdimd = rgasdim*tempfreestream*rhoinfdimd
   pinfdim = rhoinfdim*rgasdim*tempfreestream
   tinfdim = tempfreestream
   ELSE
   pinfdimd = 0.0
   rhoinfdimd = 0.0
   END IF
   ! In case the reference pressure, density and temperature were
   ! not specified, set them to the infinity values.
   IF (pref .LE. zero) THEN
   prefd = pinfdimd
   pref = pinfdim
   ELSE
   prefd = 0.0
   END IF
   IF (rhoref .LE. zero) THEN
   rhorefd = rhoinfdimd
   rhoref = rhoinfdim
   ELSE
   rhorefd = 0.0
   END IF
   IF (tref .LE. zero) tref = tinfdim
   END IF
   ! Compute the value of muRef, such that the nonDimensional
   ! equations are identical to the dimensional ones.
   ! Note that in the non-dimensionalization of muRef there is
   ! a reference length. However this reference length is 1.0
   ! in this code, because the coordinates are converted to
   ! meters.
   IF (pref*rhoref .EQ. 0.0) THEN
   murefd = 0.0
   ELSE
   murefd = (prefd*rhoref+pref*rhorefd)/(2.0*SQRT(pref*rhoref))
   END IF
   muref = SQRT(pref*rhoref)
   ! Compute timeRef for a correct nonDimensionalization of the
   ! unsteady equations. Some story as for the reference viscosity
   ! concerning the reference length.
   IF (rhoref/pref .EQ. 0.0) THEN
   timerefd = 0.0
   ELSE
   timerefd = (rhorefd*pref-rhoref*prefd)/(pref**2*2.0*SQRT(rhoref/pref&
   &      ))
   END IF
   timeref = SQRT(rhoref/pref)
   ! Compute the nonDimensional pressure, density, velocity,
   ! viscosity and gas constant.
   pinfd = (pinfdimd*pref-pinfdim*prefd)/pref**2
   pinf = pinfdim/pref
   rhoinfd = (rhoinfdimd*rhoref-rhoinfdim*rhorefd)/rhoref**2
   rhoinf = rhoinfdim/rhoref
   arg1d = (gammainf*pinfd*rhoinf-gammainf*pinf*rhoinfd)/rhoinf**2
   arg1 = gammainf*pinf/rhoinf
   IF (arg1 .EQ. 0.0) THEN
   result1d = 0.0
   ELSE
   result1d = arg1d/(2.0*SQRT(arg1))
   END IF
   result1 = SQRT(arg1)
   uinfd = machd*result1 + mach*result1d
   uinf = mach*result1
   !print *,'mach',mach,uinf,sqrt(gammaInf*pInf/rhoInf)
   !stop
   rgasd = (rgasdim*tref*rhorefd*pref-rgasdim*rhoref*tref*prefd)/pref**2
   rgas = rgasdim*rhoref*tref/pref
   muinfd = -(mudim*murefd/muref**2)
   muinf = mudim/muref
      CONTAINS
   !!$       print *,'pinf,rhoinf,uinf',pinf,rhoinf,uinf, gammainf,uinf/mach,timeref
   !!$       stop
   !=================================================================
   !===============================================================
   FUNCTION MAXVALUESUBFACE(var)
   IMPLICIT NONE
   !
   !        Function type
   !
   REAL(kind=realtype) :: maxvaluesubface
   !
   !        Function argument.
   !
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: var
   !
   !        Local variables.
   !
   INTEGER(kind=inttype) :: i, j
   LOGICAL :: result10
   INTRINSIC MAX
   INTRINSIC ASSOCIATED
   !
   !        ****************************************************************
   !        *                                                              *
   !        * Begin execution                                              *
   !        *                                                              *
   !        ****************************************************************
   !
   ! Initialize the function to -1 and return immediately if
   ! var is not associated with data.
   maxvaluesubface = -one
   result10 = ASSOCIATED(var)
   IF (.NOT.result10) THEN
   RETURN
   ELSE
   ! Loop over the owned faces of the subface. As the cell range
   ! may contain halo values, the nodal range is used.
   DO j=bcdata(mm)%jnbeg+1,bcdata(mm)%jnend
   DO i=bcdata(mm)%inbeg+1,bcdata(mm)%inend
   IF (maxvaluesubface .LT. var(i, j)) THEN
   maxvaluesubface = var(i, j)
   ELSE
   maxvaluesubface = maxvaluesubface
   END IF
   END DO
   END DO
   END IF
   END FUNCTION MAXVALUESUBFACE
   END SUBROUTINE REFERENCESTATE_MOD_EXTRA_D