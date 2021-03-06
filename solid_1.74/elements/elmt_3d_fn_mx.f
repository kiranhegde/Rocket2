subroutine nl_3d_fn_mx(action,iter,pro_type,reg_num,ele_num,ul,xl,tl,tl0,s,p,str_out,ndf,ndm,nst,nel,nquad,n_out)

! Coded by Jeeho Lee (June 2015)

!   3D large deformation element routine - Mixed formulation
!     - Dynamic/Static procedures
!     - 1X1X1 or 2X2X2 Integration

!     pro_type: 3D problems = 3

use element_specification

! Global variables from module 'elements' & 'element_specification':
!
!  - Geometry: thickness, body(3), gr_accl(3), density, consistent_ratio
!  - Time related: dt, ctan(3)


implicit none

integer, intent(inout) :: action
integer, intent(in) :: pro_type, reg_num, ele_num, ndf, ndm, nst, nel, nquad, iter, n_out
real, intent(in) :: xl(ndm,nel), ul(ndf,5*nel), tl(nel), tl0
real, intent(out) :: s(nst,nst), p(nst), str_out(nquad,n_out)

integer, parameter :: ndim = 6, max_lint = 8, max_nel = 8
integer ::  mat_num, material_model, point_address

integer :: i, i1, j, jj, j1, k, k1, l, lint, nea
integer :: npm
real :: xsj
real :: dsigtr, mpress, dpress, dtheta, fac, bdb, bd3
real :: sg(4,max_lint), xx(ndm,max_lint), shp(4,27,max_lint), dvol0(max_lint), dvol(max_lint)
real :: bbd(3,7), bbar(2,16,max_lint), ad(6,6,max_lint), dd(7,7), sigm(10), sigl(6,max_lint)
real :: detf(2,max_lint), df(9,max_lint), fi(9,2,max_lint), finv(9,max_lint)

real :: phi(4,max_lint), theta(2,max_lint), hh(4,4), vl(3)
real :: press(max_lint), pbar(max_lint), shpbar(3,27,max_lint)
real :: ta(max_lint)
real :: xr(ndm,max_lint), ur(ndm,max_lint), xu(ndm,max_lint), r(ndf,nel), ru(ndf,nel)

real :: b1, b2, b3, thick
real :: str_data(n_out)

real :: mass(nel,nel), al(3), accl(ndf,nel), infv(3), lfac, cfac, rr, m(nst,nst)
real :: aj0, ct1, ct3
real, parameter :: one3 = 1.0/3.0

logical :: flgrm = .FALSE., dyna = .FALSE.
logical :: ther, hexa, geo_flag



if (pro_type /= 3) STOP 'nl_3d_fn_mx: pro_type is not for 3D!'
if (nel > max_nel) STOP 'nl_3d_fn_mx: # of nodes per element exceeds maximum!'
if (ndf /= 3) STOP 'nl_3d_fn_mx: nodal dof is not 3!'

if (nel == 8) then
  hexa = .TRUE.
else
  STOP 'nl_3d_fn_mx: hexahedron only presently!'
  hexa = .FALSE.
endif

if (action == 2) then
	dyna = .TRUE.
else
	dyna = .FALSE.
endif

ther = .FALSE.
geo_flag = .TRUE.

! Set element quadrature order
npm = 1
l   = 2
nea = 4*nel
         
s = 0.0
p = 0.0
r = 0.0

! Read data from module 'element_specification'
thick = 1.0   ! 3D
b1 = body(1)
b2 = body(2)
b3 = body(3)
rr = density

accl = 0.0
infv = 0.0	  

if (dyna) then  ! dynamic case	

	cfac = consistent_ratio
	accl = ul(1:ndf,nea+1:nea+nel)

  lfac = 1.d0 - cfac

	mass = 0.0

	ct1 = thick*ctan(1)
	ct3 = thick*ctan(3)
	
	
! Ground motion part (default: off)
	flgrm = .TRUE.
  if (flgrm) then
		infv(1) = gr_accl(1)
		infv(2) = gr_accl(2)
    infv(3) = gr_accl(3)
	else
		infv = 0.0
	endif

else
	ct1 = thick
	ct3 = 0.0

endif


! Compute current geometry (not used presently)
forall (i=1:ndm, j=1:nel) xu(i,j) = xl(i,j) + ul(i,j)

call element_material(reg_num, ele_num, mat_num, material_model, .TRUE.)

if (hexa) then
	if (nquad == 8) then
		l = 2
	elseif (nquad == 1) then
		l = 1
	else
		STOP 'nl_3d_fn_mx: invalid nquad!'
	endif	
		
  call int3d(l,lint,sg,nel)
endif


if (lint > max_lint) then
  write(*,*) 'nl_3d_fn_mx: too many quadrature points!: lint =', lint
	STOP
endif

phi = 0.0

do l = 1, lint

! Shape functions and derivatives

  call shp3d(sg(1,l),xl,shp(1,1,l),xsj,ndm,nel)
  dvol0(l) = xsj*sg(4,l)

! Mixed volume effect and temperature projection

  ta(l) = 0.0

! Compute coordinates at gauss points

	xr(:,l) = 0.0
	ur(:,l) = 0.0
  do i = 1, nel
    xr(1:3,l) = xr(1:3,l) + xl(1:3,i)*shp(4,i,l)
    ur(1:3,l) = ur(1:3,l) + ul(1:3,i)*shp(4,i,l)

    ta(l)   = ta(l) + shp(4,i,l)*tl(i)
  end do


! Compute volumetric strain from displacements
!         Set the pressure functions

  phi(1,l) = 1.0
  
end do ! l

vl(3) = 0.0


! Mixed model for volumetric and temperature response
! Compute f, finv, df, detf and shp at conf t-n+1

call kine3m(shp,ul,fi,finv,df,detf,ndf,nel,lint)

!		- Bad deformation exit signal
if (MINVAL(detf(1,1:lint)) < Numerical_Zero) then
  action = -1
  write(*,'(A,I3,I9/,A/,2(4ES13.5/))') '* Bad Jacobian: region, element =', reg_num, ele_num, '  Jacobian at quadrature points:', (detf(1,l), l=1,lint)
  write(*,'(A/,8(3ES13.5/))') ' xu =', ((xu(i,j), i=1,3), j=1,8)
  write(*,'(A/,8(3ES13.5/))') ' ul =', ((ul(i,j), i=1,3), j=1,8)

  RETURN  !-------------------------------------------------------------------->>>>>
endif

! Compute volume at current state

do l = 1, lint
  dvol(l) = dvol0(l)*detf(1,l)
end do

! Mixed model for volumetric response

call bbar3m(phi,shp,dvol,detf,lint,nel,npm,hh,theta,shpbar)


! Compute mixed model deformation gradient

call fbar(fi,detf,theta,lint)

! Compute Cauchy stresses and spatial tangent tensor at t-n+1

do l = 1, lint
! Compute coordinates in reference and current configuration

!  Get the address in history db using the subrountine in 'physical_domain'
  call find_point_number(reg_num,ele_num,l,point_address)

  call str_tang_fn(action,iter,reg_num,ele_num,point_address,mat_num,material_model,ndm,ndf,nel &
                  ,ta(l),tl0,dt,xl,ul,fi(1,1,l),finv(1,l),theta(1,l),sigl(1,l),ad(1,1,l),ndim,str_data,n_out)
  str_out(l,:) = str_data
end do ! l

press(1) = 0.0
do l = 1, lint
! Modify volume element and integrate pressure over reference volume
  press(1) = press(1) + one3*dvol0(l)*(sigl(1,l) + sigl(2,l) + sigl(3,l))
  dvol(l)  = dvol0(l)*theta(1,l)
end do ! l

! Divide pressure by reference volume


press(1) = press(1) * hh(1,1)
do l = 2, lint
  press(l) = press(1)
end do ! l


! Compute mixed pressure


do l = 1, lint

! Compute mixed stress and multiply by volume element

  dsigtr  = press(l)*detf(1,l)/theta(1,l) - one3*(sigl(1,l)+sigl(2,l)+sigl(3,l))
  sigm(1) =  sigl(1,l) + dsigtr
  sigm(2) =  sigl(2,l) + dsigtr
  sigm(3) =  sigl(3,l) + dsigtr
  sigm(4) =  sigl(4,l)
  sigm(5) =  sigl(5,l)
  sigm(6) =  sigl(6,l)

! Store time history plot data for element

  do i = 1, ndim
    sigm(i) = sigm(i)*dvol(l)
  end do
              
	if (dyna) then			
		al = 0.0
			        
		do j = 1, nel
			do k = 1, 3
				al(k) = al(k) + shp(4,j,l)*(accl(k,j) + infv(k))
			enddo		
		enddo
		al = cfac*rr*al		
		aj0 = lfac*rr				
	else
		aj0 = 0.0
		al = 0.0
	endif
							
! Compute residual

  do i = 1, nel

    ru(1,i) = shp(1,i,l)*sigm(1) + shp(2,i,l)*sigm(4) + shp(3,i,l)*sigm(6)
    ru(2,i) = shp(1,i,l)*sigm(4) + shp(2,i,l)*sigm(2) + shp(3,i,l)*sigm(5)
    ru(3,i) = shp(1,i,l)*sigm(6) + shp(2,i,l)*sigm(5) + shp(3,i,l)*sigm(3)

    r(1,i)  = r(1,i) - ru(1,i) + (b1 -al(1) - aj0*(infv(1)+accl(1,i)))*dvol0(l)*shp(4,i,l)
    r(2,i)  = r(2,i) - ru(2,i) + (b2 -al(2) - aj0*(infv(2)+accl(2,i)))*dvol0(l)*shp(4,i,l)
    r(3,i)  = r(3,i) - ru(3,i) + (b3 -al(3) - aj0*(infv(3)+accl(3,i)))*dvol0(l)*shp(4,i,l)
  end do

! Multiply tangent moduli by volume element
  
! Part 1: Geometric tangent matrix
  if (geo_flag) then
  
    i1 = 0
    do i = 1, nel
      j1 = 0
      do j = 1, nel
        bdb = ru(1,j)*shp(1,i,l) + ru(2,j)*shp(2,i,l) + ru(3,j)*shp(3,i,l)  ! i,j are symmetric
        s(i1+1,j1+1) = s(i1+1,j1+1) + bdb
        s(i1+2,j1+2) = s(i1+2,j1+2) + bdb
        s(i1+3,j1+3) = s(i1+3,j1+3) + bdb
        j1 = j1 + ndf
      end do ! j

      i1 = i1 + ndf
    end do ! i
  endif
  
! Part 2: Material tangent matrix

!  Modify tangent moduli for stress factors

  mpress = press(l)*detf(1,l)/theta(1,l)
  dpress = one3*(sigl(1,l) + sigl(2,l) + sigl(3,l))
  

  call dmatmx(ad(1,1,l),dd)

  call dmatdx(dd,sigl(1,l),dpress,mpress)

!  Multiply tangent moduli by volume element

  dd = dvol(l)*dd

 !  Compute row terms

  i1    = 0
  do i = 1, nel
!                 Compute bmat-t * dd * dvol
    do jj = 1, 7

      bbd(1,jj) =    shp(1,i,l)*dd(1,jj)  &
                +    shp(2,i,l)*dd(4,jj)  &
                +    shp(3,i,l)*dd(6,jj)  &
                + shpbar(1,i,l)*dd(7,jj)

      bbd(2,jj) =    shp(2,i,l)*dd(2,jj)  &
                +    shp(1,i,l)*dd(4,jj)  &
                +    shp(3,i,l)*dd(5,jj)  &
                + shpbar(2,i,l)*dd(7,jj)

      bbd(3,jj) =    shp(3,i,l)*dd(3,jj)  &
                +    shp(2,i,l)*dd(5,jj)  &
                +    shp(1,i,l)*dd(6,jj)  &
                + shpbar(3,i,l)*dd(7,jj)
    end do ! jj

    j1 = 0
    do j = 1, nel  ! can use 'i' instead of 'nel', if s(:,:) is definitely symmetric

      do jj = 1, 3
        s(i1+jj,j1+1) = s(i1+jj,j1+1) + bbd(jj,1)*shp(1,j,l)  &
                                      + bbd(jj,4)*shp(2,j,l)  &
                                      + bbd(jj,6)*shp(3,j,l)  &
                                      + bbd(jj,7)*shpbar(1,j,l)

        s(i1+jj,j1+2) = s(i1+jj,j1+2) + bbd(jj,2)*shp(2,j,l)  &
                                      + bbd(jj,4)*shp(1,j,l)  &
                                      + bbd(jj,5)*shp(3,j,l)  &
                                      + bbd(jj,7)*shpbar(2,j,l)

        s(i1+jj,j1+3) = s(i1+jj,j1+3) + bbd(jj,3)*shp(3,j,l)  &
                                      + bbd(jj,5)*shp(2,j,l)  &
                                      + bbd(jj,6)*shp(1,j,l)  &
                                      + bbd(jj,7)*shpbar(3,j,l)
      end do ! jj

      j1 = j1 + ndf
    end do ! j
    i1 = i1 + ndf
  end do ! i

	if (dyna) then

		do i = 1, nel
			aj0 = shp(4,i,l)*dvol0(l)*rr
		
!		Compute lumped mass matrix
			mass(i,i) = mass(i,i) + lfac*aj0
			                          
!		Compute consistent mass matrix
			do j = 1, nel
				mass(i,j) = mass(i,j) + cfac*aj0*shp(4,j,l)
			end do ! j
		end do ! i		

	endif  ! dyna
	
end do ! l


if (dyna) then
!  Expand 'mass' matrix (scalar mass: no directional mass) to the general m(nst,nst) matrix

	m = 0.0
	j1 = 1
	do j = 1, ndf*nel, ndf
      k1 = 1
      do k = 1, ndf*nel, ndf
        m(j,k)     = mass(j1,k1)
        m(j+1,k+1) = mass(j1,k1)
        m(j+2,k+2) = mass(j1,k1)
        k1 = k1 + 1
      end do
      j1 = j1 + 1
	end do
	
!  Add mass matrix(mass) & damping matrix(damp) to stiffness matrix(s)
      
	s = ct1*s + ct3*m

else
	s = ct1*s   ! thickness
endif  ! dyna


j = 1
do i = 1, nel
  p(j)   = r(1,i)*thick
  p(j+1) = r(2,i)*thick
  p(j+2) = r(3,i)*thick
  j = j + 3
enddo


! write(*,*) 'p: ', p
! write(*,*) 's: ', s

end subroutine nl_3d_fn_mx
