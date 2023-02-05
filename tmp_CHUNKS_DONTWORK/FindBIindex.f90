! ###########################################################################
!     RESUME : Eval 'floating point index' into a table using a kind        !
!              of binary search. The output array can't be used with        !
!              some type of interpolation method.                           !
!                                                                           !
!              Resampling of an one dimensional array with or without       !
!              an irregular grid.                                           !
!                                                                           !
!              OBS.: This code is based on idl findex.pro but               !
!              re-adapted to Fortran 2008 syntax.                           !
!                                                                           !
!     INPUT  : 01) inpvecxx  -> Monitically increasing array (Abscissa)     !
!              02) inpvecyy  -> Array of values (Ordinate)                  !
!              03) verbosity -> Optional variable to print & check          !
!                                                                           !
!     OUTPUT : 01) outwwbin ->  Final floating point index result           !
!              02) IsKeepOn ->  Flag, if == 0 then there's a problem        !
!                                                                           !
!              'Floating point index' has the following structure:          !
!                                                                           !
!              *** The integer part of the output w array gives an          !
!                  index into the original inpvecxx array, such that        !
!                  inpvecyy(i) is between inpvecxx(outwwbin(i)) and         !
!                  inpvecxx(outwwbin(i)+1) and the decimal part is the      !
!                  weighting factor given by:                               !
!                                                                           !
!                         inpvecyy(i)-inpvecxx(outwwbin(i))                 !
!                        -----------------------------------                !
!                   inpvecxx(outwwbin(i)+1)-inpvecxx(outwwbin(i))           !
!                                                                           !
!        LOG : Sat Oct 22 14:52:03 WEST 2016                                !
!              Modification of indexes due to boundary problems.            !
!              Modification in m_search variable to m_search+1 in Binary    !
!              search has failed. Added intrinsic functions.                !
!                                                                           !
!     Written: Jean Michel Gomes                                            !
!     Checked: Sat Dec  8 12:09:19 WET 2012                                 !
!     Checked: Fri Dec 28 13:01:58 WET 2012                                 !
!     Checked: Thu Oct 20 22:11:12 WEST 2016                                !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE FindBIindex(  inpvecxx,Narrayxx,inpvecyy,outwwbin,Narrayyy,      &
                         IsKeepOn,verbosity )

    use ModDataType

    implicit none
    integer  (kind=IB), intent(in) :: Narrayxx,Narrayyy
    integer  (kind=IB), optional :: verbosity
    integer  (kind=IB), intent(in out) :: IsKeepOn

    integer  (kind=IB) :: increase,iterativ,j_differ,contagem,ind_aux1,     &
                          IsShowOn

    real     (kind=RP), dimension(Narrayxx), intent(in) :: inpvecxx

    real     (kind=RP), dimension(Narrayyy), intent(in) :: inpvecyy
    real     (kind=RP), dimension(Narrayyy), intent(out) :: outwwbin
    
    real     (kind=RP), allocatable, dimension(:) :: auxvecxx

    integer  (kind=IB), allocatable, dimension(:) :: auxvecii,auxvecjj,     &
                                                     Findices
    integer  (kind=IB), allocatable, dimension(:,:) :: j_limits

    real     (kind=RP) :: minvecxx,maxvecxx,m_search

    !f2py real     (kind=RP), intent(in out) :: IsKeepOn
    !f2py real     (kind=RP), intent(in) :: inpvecxx
    !f2py                     intent(hide), depend(inpvecxx) :: Narrayxx=shape(inpvecxx,0)

    !f2py real     (kind=RP), intent(in) :: inpvecyy
    !f2py real     (kind=RP), intent(out) :: outwwbin
    !f2py                     intent(hide), depend(inpvecyy) :: Narrayyy=shape(inpvecyy,0)
    !f2py                     intent(hide), depend(outwwbin) :: Narrayyy=shape(outwwbin,0)
    !f2py                     intent(in), optional :: verbosity=0
    
    intrinsic adjustl, count, cshift, float, int, log, maxval, minval,      &
              size, trim

    if ( present(verbosity) ) then
       IsShowOn = verbosity
    else
       IsShowOn = 0_IB
    end if

    !Narrayxx = size(inpvecxx)
    !Narrayyy = size(inpvecyy)

    !write(*,*) Narrayxx,Narrayyy

    outwwbin(:) = 0.0_RP
    
    allocate( auxvecxx(Narrayxx) )
    auxvecxx(1:Narrayxx) = inpvecxx(1:Narrayxx) - cshift(inpvecxx,shift=1)
    maxvecxx = maxval( auxvecxx )
    minvecxx = minval( auxvecxx )
    deallocate( auxvecxx )

    if ( count( (inpvecxx(2:Narrayxx)-inpvecxx(1:Narrayxx-1)) <= 0.0_RP ) > 0_IB ) then
        write (*,'(4x,a)')  '[PROBLEM_FIT] @@@@@@@@@@@@@@@@@@@@@@@@'
        write (*,'(4x,a)')  '[FindBIindex] inpvecxx not monotonic @'

        IsKeepOn = 0_IB
        return
    end if

    if ( maxvecxx > 0.0_RP ) then
        increase = 1
    else
        increase = 0
    end if

! *** Maximum number of binary searches *************************************
    m_search = int( log(float(Narrayxx))/log(2.0_RP)+0.5_RP )
    !write (*,*) m_search
! *** Maximum number of binary searches *************************************

    allocate( j_limits(2,Narrayyy) )
    j_limits(1,:) = 1                                                       ! *** Array of lower limits
    j_limits(2,:) = Narrayxx-1                                              ! *** Array of upper limits

    iterativ = 1
    j_differ = 0
    allocate( auxvecii(Narrayyy) )
    allocate( auxvecjj(Narrayyy) )
    allocate( Findices(Narrayyy) )
    do ind_aux1=1,Narrayyy
        Findices(ind_aux1) = ind_aux1
    end do

    do while ( j_differ /= 1 .OR. iterativ <= m_search )
        auxvecjj = int( (j_limits(1,:)+j_limits(2,:)) / 2 )
        contagem = count( inpvecyy >= inpvecxx(auxvecjj+1) )

        !write (*,*) iterativ,size(auxvecjj),contagem

        if ( contagem > 0 ) then
            auxvecii = -999
            where ( inpvecyy >= inpvecxx(auxvecjj) )
                 auxvecii = Findices
            end where
            do ind_aux1=1,Narrayyy
                if ( auxvecii(ind_aux1) > 0 ) then
                    j_limits(2-increase,auxvecii(ind_aux1)) =               &
                                                 auxvecjj(auxvecii(ind_aux1))
                end if
            end do
        end if

        contagem = count( inpvecyy < inpvecxx(auxvecjj+1) )
        if ( contagem > 0 ) then
            auxvecii = -999
            where ( inpvecyy < inpvecxx(auxvecjj+1) )
                auxvecii = Findices
            end where
            do ind_aux1=1,Narrayyy
                if ( auxvecii(ind_aux1) > 0 ) then
                    j_limits(increase+1,auxvecii(ind_aux1)) =               &
                                                 auxvecjj(auxvecii(ind_aux1))
                end if
            end do
        end if

        j_differ = maxval(j_limits(2,:)-j_limits(1,:))
        if ( iterativ > m_search+1 ) then
            write (*,'(4x,a)')  'Binary search failed'
            write (*,'(4x,a)')  '[PROBLEM_FIT] @@@@@@@@@@@@@@@@@@@@@@@@'
            write (*,'(4x,a)')  '[FindBIindex] Binary search has failed'
            write (*,'(4x,a,i5)') 'iterativ: ',iterativ

            IsKeepOn = 0_IB
            return
        end if

        iterativ = iterativ + 1
    end do

! *** Export result *********************************************************
    outwwbin(:) = ( inpvecyy(:)-inpvecxx(j_limits(1,:)) )                   &
                / ( inpvecxx(j_limits(1,:)+1)-inpvecxx(j_limits(1,:)) )     &
                + j_limits(1,:)
    !write (*,*) outwwbin(1),outwwbin(2),outwwbin(3),outwwbin(4)
! *** Export result *********************************************************

! *** Deallocate from memory ************************************************
    deallocate( auxvecii )
    deallocate( auxvecjj )
    deallocate( Findices )
    deallocate( j_limits )
! *** Deallocate from memory ************************************************

END SUBROUTINE FindBIindex
! ###########################################################################

! ###########################################################################
!     RESUME : Interpolate linearly a vector array.                         !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE FInterpolar( v,m,u,w,n )

    use ModDataType

    implicit none
    integer  (kind=IB), intent(in) :: m,n
    integer  (kind=IB) :: i,j,o,s1,ix
    real     (kind=RP), dimension(m), intent(in) :: v
    real     (kind=RP), allocatable, dimension(:) :: x,r
    real     (kind=RP), dimension(n), intent(in) :: u
    real     (kind=RP), dimension(n), intent(out) :: w
    real     (kind=RP) :: d

    !f2py real     (kind=RP), intent(in)  :: v
    !f2py                     intent(hide), depend(v) :: m=shape(v,0)

    !f2py real     (kind=RP), intent(in)  :: u
    !f2py                     intent(hide), depend(u) :: n=shape(u,0)
    !f2py real     (kind=RP), intent(out) :: w
    !f2py                     intent(hide), depend(w) :: n=shape(w,0)
    
    intrinsic float, size

    !m = size(v)

    allocate( x(m) )

    do j=1,m
        x(j) = float(j)
    end do

    !n = size(u)
    o = m - 1!2

    allocate( r(n) )
    r = v(1)

    if ( x(2)-x(1) >= 0.0_RP ) then
        s1 = 1
    else
        s1 = -1
    end if
    ix = 1

    do i=1,n
        d = s1 * (u(i)-x(ix)) ! Difference

        if ( d <= 0.0_RP ) then
            r(i) = v(ix)
        !   write (*,*) d
        !end if
         else
            if ( d > 0.0_RP ) then
                do while ( s1*(u(i)-x(ix+1)) > 0.0_RP .AND. ix < o )
                    ix=ix+1
                end do
            else
                do while ( s1*(u(i)-x(ix)) < 0.0_RP .AND. ix > 0_IB )
                    ix=ix-1
                end do
            end if
            r(i) = v(ix) + (u(i)-x(ix))*(v(ix+1)-v(ix))/(x(ix+1)-x(ix))

        end if

    end do

    w(:) = r(:)
    deallocate( r )
    deallocate( x )

END SUBROUTINE FInterpolar
! ###########################################################################

! ###########################################################################
!     RESUME : Interpolate linearly a vector array final result             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE IndexInterp( xx_value,yy_value,nxyvalue,xold_vec,yold_vec,       &
                        nold_vec,IsKeepOn,verbosity )

    use ModDataType
 
    implicit none
    integer  (kind=IB), intent(in out) :: IsKeepOn
    integer  (kind=IB), intent(in) :: nold_vec, nxyvalue
    integer  (kind=IB), optional :: verbosity
    integer  (kind=IB) :: IsShowOn
    real     (kind=RP), dimension(0:nold_vec-1), intent(in) :: xold_vec,yold_vec
    real     (kind=RP), dimension(0:nxyvalue-1), intent(in) :: xx_value
    real     (kind=RP), dimension(0:nxyvalue-1), intent(out) :: yy_value

    real     (kind=RP), dimension(0:nxyvalue-1) :: outwwbin

    !f2py real     (kind=RP), intent(in) :: xold_vec,yold_vec
    !f2py                     intent(hide), depend(xold_vec) :: nold_vec=shape(xold_vec,0)
    !f2py                     intent(hide), depend(yold_vec) :: nold_vec=shape(yold_vec,0)
    !f2py                     intent(in), optional :: verbosity=0

    !f2py real     (kind=RP), intent(in)  :: xx_value 
    !f2py real     (kind=RP), intent(out) :: yy_value 
    !f2py                     intent(hide), depend(xx_value) :: nxyvalue=shape(xx_value,0)
    !f2py                     intent(hide), depend(yy_value) :: nxyvalue=shape(yy_value,0)

    !f2py integer  (kind=IB), intent(in out) :: IsKeepOn

    interface
       subroutine FindBIindex( inpvecxx,Narrayxx,inpvecyy,outwwbin,Narrayyy,&
                               IsKeepOn,verbosity )
         use ModDataType
         integer  (kind=IB), intent(in) :: Narrayxx,Narrayyy
         integer  (kind=IB), optional :: verbosity
         integer  (kind=IB), intent(in out) :: IsKeepOn
         real     (kind=RP), dimension(Narrayxx), intent(in) :: inpvecxx
         real     (kind=RP), dimension(Narrayyy), intent(in) :: inpvecyy
         real     (kind=RP), dimension(Narrayyy), intent(out) :: outwwbin
       end subroutine FindBIindex
       subroutine FInterpolar( v,m,u,w,n )
         use ModDataType
         integer  (kind=IB), intent(in) :: m,n
         real     (kind=RP), dimension(m), intent(in) :: v
         real     (kind=RP), allocatable, dimension(:) :: x,r
         real     (kind=RP), dimension(n), intent(in) :: u
         real     (kind=RP), dimension(n), intent(out) :: w
       end subroutine FInterpolar
    end interface
    
    intrinsic present
    
    if ( present(verbosity) ) then
       IsShowOn = verbosity
    else
       IsShowOn = 0_IB
    end if

    call FindBIindex( xold_vec,nold_vec,xx_value,outwwbin,nxyvalue,         &
                      IsKeepOn,IsShowOn )
    call FInterpolar( yold_vec,nold_vec,outwwbin,yy_value,nxyvalue )
     
END SUBROUTINE IndexInterp
! ###########################################################################

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE author_IndexInterp( a )
  use ModDataType

  implicit none
  
  character (len=21), intent(out) :: a

  !f2py intent(out) :: a

  a = 'Written by Jean Gomes'
  
END SUBROUTINE author_IndexInterp
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

! Jean@Porto - Wed Dec  5 11:04:34 WET 2012 +++++++++++++++++++++++++++++++++

! *** Test ******************************************************************
!PROGRAM GeneralTest
!END PROGRAM GeneralTest
! *** Test ******************************************************************

! *** Number : 003                                                          !
