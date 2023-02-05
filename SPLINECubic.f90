! ###########################################################################
!     RESUME : Interpolation with cubic spline function. Original           !
!     one-dimensional arrays x and y, both of length n. This                !
!     subroutine evaluates the 2nd derivatives and stores at y2 for         !
!     each abscissa point. The optional parameters yp1 and ypn are          !
!     border conditions of the edges. For 'natural' spline                  !
!     (recommended) and equal to scipy function, set these values to        !
!     1.0E+30 or greater.                                                   !
!                                                                           !
!     WARNING: the x array needs to be monotonically increasing             !
!                                                                           !
!     Input           arguments = 3                                         !
!     Output          arguments = 2                                         !
!     Optional        arguments = 3                                         !
!     Total number of arguments = 8                                         !
!                                                                           !
!     INPUT  : 01) x         -> Old x vector (abcissas)                     !
!              02) y         -> Old y vector (ordenadas)                    !
!              03) n         -> # of elements in vector x and y             !
!              02) yp1       -> Border condition at x(1)                    !
!              02) ypn       -> Border condition at x(n)                    !
!              04) verbosity -> Print & Check screen                        !
!                                                                           !
!     OUTPUT : 01) y2        -> Second derivative                           !
!              04) IsKeepOn  -> Flag, if == 0 then there's a problem        !
!                                                                           !
!     PYTHON : Python compatibility using f2py revised. Better usage        !
!              with numpy.                                                  !
!                                                                           !
!     Written: Jean Michel Gomes © Copyright ®                              !
!     Checked: Tue May  1 16:09:13 WEST 2012                                !
!              Fri Dec 28 14:55:10 WET  2012                                !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SPLINE_Diff( x,y,y2,n,IsKeepOn,yp1,ypn,verbosity )

    use ModDataType
    implicit none

    integer  (kind=IB), intent(in) :: n
    integer  (kind=IB), intent(out) :: IsKeepOn
    integer  (kind=IB), optional :: verbosity

    integer  (kind=IB) :: i,k,IsShowOn
    
    real     (kind=RP), dimension(0:n-1) :: u
    real     (kind=RP), dimension(0:n-3) :: sig_vec,dy__vec,dx1,dx2,dx3
    real     (kind=RP), intent(in), dimension(0:n-1) :: x,y
    real     (kind=RP), optional :: yp1,ypn
    real     (kind=RP) :: yp1_,ypn_

    real     (kind=RP), intent(out), dimension(0:n-1) :: y2
    real     (kind=RP) :: un,qn!,sig,p

    !f2py real     (kind=RP), intent(in)  :: x,y
    !f2py                     intent(hide), depend(x) :: n=shape(x,0)
    !f2py                     intent(hide), depend(y) :: n=shape(y,0)

    !f2py real     (kind=RP), intent(out)  :: y2
    !f2py                     intent(hide), depend(y2) :: n=shape(y2,0)
    
    !f2py integer  (kind=IB), intent(out) :: IsKeepOn

    !f2py real     (kind=RP), optional :: yp1=1.0e30
    !f2py real     (kind=RP), optional :: ypn=1.0e30
    !f2py integer  (kind=IB), optional :: verbosity=0

    IsKeepOn = 1_IB
    
    if ( present(verbosity) ) then
       IsShowOn = verbosity
    else
       IsShowOn = 0_IB
    end if

    if ( present(yp1) ) then
       yp1_ = yp1
    else
       yp1_ = 1.0e30_RP
    end if

    if ( present(ypn) ) then
       ypn_ = ypn
    else
       ypn_ = 1.0e30_RP
    end if

    if ( IsShowOn == 1_IB  ) then
       write (*,'(4x,a)') '[SPLINE_Diff]'
    end if
    
! *** yp1 >= 1e30 use 'natural' spline, otherwise estimate y2 at the ********
!     1st point => Border Condition                                         !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    if ( yp1_ >= 1.0e30_RP ) then
       y2(0) = 0.0_RP
       u(0)  = 0.0_RP
    else
       y2(0) = -0.5_RP
       u(0)  = (3.0_RP/(x(1)-x(0)))*((y(1)-y(0))/(x(1)-x(0))-yp1_)
    end if
    
! *** Evaluate intermediate terms in the expansion series *******************
    dx1(0:n-3) = ( x(1:n-2)-x(0:n-3) )
    dx2(0:n-3) = ( x(2:n-1)-x(0:n-3) )
    dx3(0:n-3) = ( y(2:n-1)-y(1:n-2) ) / ( x(2:n-1)-x(1:n-2) ) / dx2(0:n-3)
    dx3(0:n-3) = 6.0_RP * dx3(0:n-3)
    
    sig_vec(0:n-3) = dx1(0:n-3) / dx2(0:n-3) !( x(1:n-2)-x(0:n-3) ) / ( x(2:n-1)-x(0:n-3) )

    dx1(0:n-3) = (y(1:n-2)-y(0:n-3)) / dx1(0:n-3) / dx2(0:n-3)
    dx1(0:n-3) = 6.0_RP * dx1(0:n-3)

    !dy__vec(0:n-3) = ( 6.0_RP * ( (y(2:n-1)-y(1:n-2)) / (x(2:n-1)-x(1:n-2)) &
    !               - (y(1:n-2)-y(0:n-3)) / (x(1:n-2)-x(0:n-3)) ) / (x(2:n-1)-x(0:n-3)) )

    !dy__vec(0:n-3) = ( 6.0_RP * ( (y(2:n-1)-y(1:n-2)) / dx3(0:n-3) / dx2(0:n-3) - (y(1:n-2)-y(0:n-3)) / dx1(0:n-3) / dx2(0:n-3) ) )
    dy__vec(0:n-3) = ( dx3(0:n-3) - dx1(0:n-3) )

    ! OLD iterations
    ! -- > do i=1,n-2
    ! -- >    !sig   = ( x(i)-x(i-1) ) / ( x(i+1)-x(i-1) )
    ! -- >    !p     = sig * y2(i-1) + 2.0_RP
    ! -- >    p     = sig_vec(i-1) * y2(i-1) + 2.0_RP
    ! -- >    !y2(i) = ( sig-1.00_RP ) / p
    ! -- >    y2(i) = ( sig_vec(i-1)-1.00_RP ) / p
    ! -- >    !u(i)  = ( 6.0_RP * ( (y(i+1)-y(i)) / (x(i+1)-x(i)) - (y(i)-y(i-1))   &
    ! -- >    !      / (x(i)-x(i-1)) ) / (x(i+1)-x(i-1)) - sig * u(i-1)) / p
    ! -- >    !u(i)  = ( 6.0_RP * ( (y(i+1)-y(i)) / (x(i+1)-x(i)) - (y(i)-y(i-1))   &
    ! -- >    !      / (x(i)-x(i-1)) ) / (x(i+1)-x(i-1)) - sig_vec(i-1) * u(i-1) ) / p
    ! -- >    u(i) = ( dy__vec(i-1) - sig_vec(i-1) * u(i-1) ) / p
    ! -- > end do

    i = 1
    call INT_TERMS( i )
! *** Evaluate intermediate terms in the expansion series *******************
    
! *** ypn >= 1e30 use 'natural' spline, otherwise estimate y2 at the ********
!     last point => Border Condition                                        !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    if ( ypn_ >= 1.0e30_RP ) then
       qn = 0.0_RP
       un = 0.0_RP
    else
       qn = 0.5_RP
       un = ( 3.0_RP / (x(n-1)-x(n-2)) )                                    &
          * ( ypn_ - (y(n-1)-y(n-2)) / (x(n-1)-x(n-2)) )
    end if
    y2(n-1) = ( un - qn*u(n-2) ) / ( qn*y2(n-2) + 1.0_RP )
! *** ypn >= 1e30 use 'natural' spline, otherwise estimate y2 at the ********
!     last point => Border Condition                                        !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
! *** Evaluate 2nd derivatives y2 from the expansion series *****************
    do k=n-2,0,-1
       y2(k) = y2(k) * y2(k+1) + u(k)
    end do
    !y2(n-2:0) = y2(n-2:0) * y2(n-1:1) + u(n-2:0)
! *** Evaluate 2nd derivatives y2 from the expansion series *****************
    
    if ( IsShowOn == 1_IB  ) then
       write (*,'(4x,a,10(e12.5))') '... y2 = ',(y2(i),i=1,min(10,n))
       write (*,'(4x,a)') '[SPLINE_DIFF]'
    end if
    
    return

  contains

    RECURSIVE SUBROUTINE INT_TERMS( i )
      use ModDataType
      implicit none

      integer  (kind=IB), intent(in) :: i!,n
    
      !real     (kind=RP), dimension(0:n-1), intent(in out) :: u
      !real     (kind=RP), dimension(0:n-3), intent(in) :: sig_vec,dy__vec
      !real     (kind=RP), dimension(0:n-1), intent(in out) :: y2
      real     (kind=RP) :: p

      p     = ( sig_vec(i-1) * y2(i-1) + 2.0_RP )
      y2(i) = ( sig_vec(i-1) - 1.00_RP ) / p
      u(i)  = ( dy__vec(i-1) - sig_vec(i-1) * u(i-1) ) / p

      if ( i+1 <= n-2 ) then 
         call INT_TERMS( i+1 ) !,sig_vec,dy__vec,y2,u,n )
      end if
    END SUBROUTINE INT_TERMS
    
END SUBROUTINE SPLINE_Diff
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!     RESUME : Interpolation with cubic spline function. Original           !
!     one-dimensional arrays xa, ya, and derivatives y2a, all of            !
!     dimension n. This subroutine evaluates the cubic spline               !
!     interpolation, returning the new interpolated values of x at y.       !
!                                                                           !
!     WARNING: the x array needs to be monotonically increasing             !
!                                                                           !
!                                                                           !
!     Input           arguments = 5                                         !
!     Output          arguments = 2                                         !
!     Optional        arguments = 1                                         !
!     Total number of arguments = 8                                         !
!                                                                           !
!     INPUT  : 01) x         -> New x vector (abcissas)                     !
!              02) xa        -> Old x vector (abcissas)                     !
!              03) ya        -> Old y vector (ordenadas)                    !
!              03) y2a       -> Old 2nd derivative                          !
!              04) n         -> # of elements in vector xa, ya and y2a      !
!              05) verbosity -> Print & Check screen                        !
!                                                                           !
!     OUTPUT : 01) y         -> New y vector (ordenadas) interpolated       !
!              02) IsKeepOn  -> Flag, if == 0 then there's a problem        !
!                                                                           !
!     PYTHON : Python compatibility using f2py revised. Better usage        !
!              with numpy.                                                  !
!                                                                           !
!     Written: Jean Michel Gomes © Copyright ®                              !
!     Checked: Tue May  1 16:09:13 WEST 2012                                !
!              Fri Dec 28 14:55:10 WET  2012                                !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SPLINE__int( x,y,xa,ya,y2a,n,ilastval,IskeepOn,verbosity )

    use ModDataType
    implicit none

    integer  (kind=IB), intent(in) :: n,ilastval
    integer  (kind=IB), intent(out) :: IsKeepOn
    integer  (kind=IB), optional :: verbosity
    
    integer  (kind=IB) :: k,klo,khi,ilastnum,IsShowOn
    
    real     (kind=RP), intent(in), dimension(0:n-1) :: xa,ya,y2a

    real     (kind=RP), intent(in) :: x
    real     (kind=RP), intent(out) :: y
             
    real     (kind=RP) :: h,a,b

    character (len=CH) :: w,z
    
    !f2py real     (kind=RP), intent(in)  :: x
    !f2py real     (kind=RP), intent(out)  :: y
    
    !f2py real     (kind=RP), intent(in)  :: xa,ya,y2a
    !f2py                     intent(hide), depend(xa) :: n=shape(xa,0)
    !f2py                     intent(hide), depend(xa) :: n=shape(ya,0)
    !f2py                     intent(hide), depend(xa) :: n=shape(y2a,0)

    !f2py integer  (kind=IB), intent(in) :: ilastval
    !f2py integer  (kind=IB), intent(out) :: IsKeepOn
    !f2py integer  (kind=IB), optional :: verbosity=0

    save ilastnum
    data ilastnum/0/

    IsKeepOn = 1_IB
    
    if ( present(verbosity) ) then
       IsShowOn = verbosity
    else
       IsShowOn = 0_IB
    end if

    if ( IsShowOn == 1_IB  ) then
       write (*,'(4x,a)') '[SPLINE__int]'
    end if

    if ( ilastval <= 0_IB ) then
        ilastnum = 0_IB
        klo = 0
        khi = n-1
     else
        klo = ilastnum
        khi = n-1
     end if

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! *** Find the indices of array xa where xa(klo) <= x <= x(khi)             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     if ( x > xa(0) .AND. x < xa(n-1)  ) then
        !klo = 0
        !khi = n
        do while (khi > klo+1)
           k = (klo+khi)/2
           if (x < xa(k)) then
              khi=k
           else
              klo=k
           end if
        end do
        !write (*,*) 'klo',klo,'khi',khi
     end if

     !1   if ( khi-klo > 1 ) then
    !j = 0
    !if ( x > xa(0) .AND. x < xa(n-1)  ) then
    !   do while ( khi-klo > 1 ) !.AND. j < 2*n )
    !      k = (khi+klo) / 2
    !      
    !      if ( xa(k) > x ) then
    !         khi = k
    !      else
    !         klo = k
    !      end if
    !      !j = j + 1
    !   end do
    !   write (*,*) 'klo',klo,'khi',khi
    !   go to 1
    !end if

    if ( x <= xa(0) ) then
       klo = 0
       khi = 1
    end if
    if ( x >= xa(n-1) ) then
       klo = n-2
       khi = n-1
    end if

    if ( ilastval > 0_IB ) then
       ilastnum = klo
    end if
    
! *** Evaluate finite difference in the abscissa ****************************
    h = xa(khi) - xa(klo)
! *** Evaluate finite difference in the abscissa ****************************
    
    if ( h == 0.0_RP ) then
       IsKeepOn = 0_IB
       if ( IsShowOn == 1_IB  ) then
          write (*,'(4x,a)')  '[PROBLEM_FIT] @@@@@@@@@@@@@@@@@@@@@@@@'
          write (*,'(4x,a)')   '... xa array is wrong for SPLINE__int'
       end if
       y = -999.0_RP
       return
    end if
    
! *** Interpolation *********************************************************
    a = ( xa(khi)-x ) / h
    b = ( x-xa(klo) ) / h

    y = a * ya(klo) + b * ya(khi)                                           &
      + ( (a*a*a-a) * y2a(klo) + (b*b*b-b) * y2a(khi) ) * (h*h) / 6.0_RP
! *** Interpolation *********************************************************
    
    if ( IsShowOn == 1_IB ) then
       write (w,'(e15.8)') x
       write (z,'(e15.8)') y
       write (*,'(4x,a,a,a)') '... x: ',trim(adjustl(w))//' ==> y: ',       &
            trim(adjustl(z))
       write (*,'(4x,a)') '[SPLINE__int]'
    end if
    
    return
END SUBROUTINE SPLINE__int
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!     RESUME : The same as SPLINE__int but for an array of                  !
!     vectors. The orginal data is given by [xa,ya] for the abscissa        !
!     and ordinate points. The new array x for the abscissas is used        !
!     to spline interpolate the data to y. The border condition can be      !
!     given at the end points yp1 and ypn. For a 'natural' spline           !
!     interpolation similar to scipy function give yp1 and ypn >=           !
!     1.0e30.                                                               !
!                                                                           !
!     WARNING: the xa array needs to be monotonically increasing            !
!                                                                           !
!     Input           arguments = 5                                         !
!     Output          arguments = 2                                         !
!     Optional        arguments = 3                                         !
!     Total number of arguments = 10                                        !
!                                                                           !
!     INPUT  : 01) x         -> New x vector (abcissas)                     !
!              02) m         -> # of elements in new vector x and y         !
!              03) xa        -> Old x vector (abcissas)                     !
!              04) ya        -> Old y vector (ordenadas)                    !
!              05) n         -> # of elements in vector xa, ya and y2a      !
!              06) yp1       -> Border condition at xa(0)                   !
!              07) yp2       -> Border condition at xa(n-1)                 !
!              08) verbosity -> Print & Check screen                        !
!                                                                           !
!     OUTPUT : 01) y         -> New y vector (ordenadas) interpolated       !
!              02) IsKeepOn  -> Flag, if == 0 then there's a problem        !
!                                                                           !
!     PYTHON : Python compatibility using f2py revised. Better usage        !
!              with numpy.                                                  !
!                                                                           !
!     Written: Jean Michel Gomes © Copyright ®                              !
!     Checked: Tue May  1 16:09:13 WEST 2012                                !
!              Fri Dec 28 14:55:10 WET  2012                                !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SPLINECubic( x,y,m,xa,ya,n,IskeepOn,yp1,ypn,verbosity )

    use ModDataType
    implicit none

    integer  (kind=IB), intent(in) :: n,m

    integer  (kind=IB), intent(out) :: IsKeepOn
    integer  (kind=IB), optional :: verbosity
    
    integer  (kind=IB) :: i,ilastval,IsShowOn
    
    real     (kind=RP), intent(in) , dimension(0:n-1) :: xa,ya
    real     (kind=RP), dimension(0:n-1) :: y2a
    real     (kind=RP), optional :: yp1,ypn
    real     (kind=RP) :: yp1_,ypn_

    real     (kind=RP), intent(in) , dimension(0:m-1) :: x
    real     (kind=RP), intent(out), dimension(0:m-1) :: y

    character (len=CH) :: w,z
    
    !f2py real     (kind=RP), intent(in)  :: x
    !f2py                     intent(hide), depend(x) :: m=shape(x,0)
    !f2py real     (kind=RP), intent(out)  :: y
    !f2py                     intent(hide), depend(y) :: m=shape(y,0)
    
    !f2py real     (kind=RP), intent(in)  :: xa,ya
    !f2py                     intent(hide), depend(xa) :: n=shape(xa,0)
    !f2py                     intent(hide), depend(xa) :: n=shape(ya,0)


    !f2py integer  (kind=IB), intent(out) :: IsKeepOn

    !f2py real     (kind=RP), optional :: yp1=1.0e30
    !f2py real     (kind=RP), optional :: ypn=1.0e30
    !f2py integer  (kind=IB), optional :: verbosity=0

    interface
       subroutine SPLINE_Diff( x,y,y2,n,IsKeepOn,yp1,ypn,verbosity )
         use ModDataType
         integer  (kind=IB), intent(in) :: n
         integer  (kind=IB), intent(out) :: IsKeepOn
         integer  (kind=IB), optional :: verbosity
         real     (kind=RP), intent(in), dimension(0:n-1) :: x,y
         real     (kind=RP), optional :: yp1,ypn  
         real     (kind=RP), intent(out), dimension(0:n-1) :: y2
       end subroutine SPLINE_Diff
       subroutine SPLINE__int( x,y,xa,ya,y2a,n,ilastval,IskeepOn,verbosity )
         use ModDataType
         integer  (kind=IB), intent(in) :: n,ilastval
         integer  (kind=IB), intent(out) :: IsKeepOn
         integer  (kind=IB), optional :: verbosity
         real     (kind=RP), intent(in), dimension(0:n-1) :: xa,ya,y2a
         real     (kind=RP), intent(in) :: x
         real     (kind=RP), intent(out) :: y
       end subroutine SPLINE__int
    end interface
    
    IsKeepOn = 1_IB
    
    if ( present(verbosity) ) then
       IsShowOn = verbosity
    else
       IsShowOn = 0_IB
    end if

    if ( present(yp1) ) then
       yp1_ = yp1
    else
       yp1_ = 1.0e30_RP
    end if
    
    if ( present(ypn) ) then
       ypn_ = ypn
    else
       ypn_ = 1.0e30_RP
    end if
    
    if ( IsShowOn == 1_IB  ) then
       write (*,'(4x,a)') '[SPLINECubic]'
    end if

    call SPLINE_Diff( xa,ya,y2a,n,IsKeepOn,yp1_,ypn_,0_IB )

    if ( IsKeepOn == 1_IB ) then
       ilastval = -1_IB
       do i=0,m-1
          call SPLINE__int( x(i),y(i),xa,ya,y2a,n,ilastval,IskeepOn,0_IB )
          if ( i == 0 ) then
             ilastval = 1_IB
          end if

          if ( IsShowOn == 1_IB ) then
             write (w,'(e15.8)') x(i)
             write (z,'(e15.8)') y(i)
             write (*,'(4x,a,a,a)') '... x(i): ',trim(adjustl(w))//' ==> y: ',&
                  trim(adjustl(z))
             if ( i == m-1 ) then
                write (*,'(4x,a)') '[SPLINECubic]'
             end if
          end if
       end do
    else
       y = -999.0_RP
    end if
    
    return
END SUBROUTINE SPLINECubic
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE author_SPLINECubic( a )
  use ModDataType

  implicit none
  
  character (len=21), intent(out) :: a

  !f2py intent(out) :: a

  a = 'Written by Jean Gomes'
  
END SUBROUTINE author_SPLINECubic
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

! Jean@Porto - Tue Sep 27 18:38:40 AZOST 2011 +++++++++++++++++++++++++++++++

! *** Test ******************************************************************
!PROGRAM Test
!END PROGRAM Test
! *** Test ******************************************************************

! *** Number : 004                                                          !
!
! 1) SPLINE_Diff
! 2) SPLINE__int
! 3) SPLINECubic
! 4) author_SPLINECubic
