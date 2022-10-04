BEGIN_PROVIDER [ double precision, mo_v_ki_bi_ortho_erf_rk_cst_mu, ( mo_num, mo_num,n_points_final_grid)]
 implicit none
 BEGIN_DOC
! mo_v_ki_bi_ortho_erf_rk_cst_mu(k,i,ip) = int dr chi_k(r) phi_i(r) (erf(mu |r - R_ip|) - 1 )/(2|r - R_ip|) on the BI-ORTHO MO basis 
! 
! where phi_k(r) is a LEFT MOs and phi_i(r) is a RIGHT MO
!
! R_ip = the "ip"-th point of the DFT Grid
 END_DOC
 integer :: ipoint
 !$OMP PARALLEL                  &
 !$OMP DEFAULT (NONE)            &
 !$OMP PRIVATE (ipoint) & 
 !$OMP SHARED (n_points_final_grid,v_ij_erf_rk_cst_mu,mo_v_ki_bi_ortho_erf_rk_cst_mu)
 !$OMP DO SCHEDULE (dynamic)
! TODO :: optimization : transform into a DGEMM
 do ipoint = 1, n_points_final_grid
   call ao_to_mo_bi_ortho(v_ij_erf_rk_cst_mu(1,1,ipoint),size(v_ij_erf_rk_cst_mu,1),mo_v_ki_bi_ortho_erf_rk_cst_mu(1,1,ipoint),size(mo_v_ki_bi_ortho_erf_rk_cst_mu,1))
 enddo
 !$OMP END DO
 !$OMP END PARALLEL
 mo_v_ki_bi_ortho_erf_rk_cst_mu = mo_v_ki_bi_ortho_erf_rk_cst_mu * 0.5d0
END_PROVIDER 


BEGIN_PROVIDER [ double precision, mo_v_ki_bi_ortho_erf_rk_cst_mu_transp, ( n_points_final_grid,mo_num, mo_num)]
 implicit none
 BEGIN_DOC
! int dr phi_i(r) phi_j(r) (erf(mu(R) |r - R|) - 1)/(2|r - R|) on the BI-ORTHO MO basis
 END_DOC
 integer :: ipoint,i,j
 do i = 1, mo_num
  do j = 1, mo_num
   do ipoint = 1, n_points_final_grid
    mo_v_ki_bi_ortho_erf_rk_cst_mu_transp(ipoint,j,i) = mo_v_ki_bi_ortho_erf_rk_cst_mu(j,i,ipoint)
   enddo
  enddo
 enddo
! FREE mo_v_ki_bi_ortho_erf_rk_cst_mu
END_PROVIDER 

BEGIN_PROVIDER [ double precision, mo_x_v_ki_bi_ortho_erf_rk_cst_mu, ( mo_num, mo_num,3,n_points_final_grid)]
 implicit none
 BEGIN_DOC
! mo_x_v_ki_bi_ortho_erf_rk_cst_mu(k,i,m,ip) = int dr x(m) * chi_k(r) phi_i(r) (erf(mu |r - R_ip|) - 1)/2|r - R_ip| on the BI-ORTHO MO basis 
!
! where chi_k(r)/phi_i(r) are left/right MOs, m=1 => x(m) = x, m=2 => x(m) = y, m=3 => x(m) = z,
!
! R_ip = the "ip"-th point of the DFT Grid
 END_DOC
 integer :: ipoint,m
 !$OMP PARALLEL                  &
 !$OMP DEFAULT (NONE)            &
 !$OMP PRIVATE (ipoint,m) & 
 !$OMP SHARED (n_points_final_grid,x_v_ij_erf_rk_cst_mu_transp,mo_x_v_ki_bi_ortho_erf_rk_cst_mu)
 !$OMP DO SCHEDULE (dynamic)
! TODO :: optimization : transform into a DGEMM
 do ipoint = 1, n_points_final_grid
  do m = 1, 3
   call ao_to_mo_bi_ortho(x_v_ij_erf_rk_cst_mu_transp(1,1,m,ipoint),size(x_v_ij_erf_rk_cst_mu_transp,1),mo_x_v_ki_bi_ortho_erf_rk_cst_mu(1,1,m,ipoint),size(mo_x_v_ki_bi_ortho_erf_rk_cst_mu,1))
  enddo
 enddo
 !$OMP END DO
 !$OMP END PARALLEL
 mo_x_v_ki_bi_ortho_erf_rk_cst_mu = 0.5d0 * mo_x_v_ki_bi_ortho_erf_rk_cst_mu

END_PROVIDER 

! ---
BEGIN_PROVIDER [ double precision, mo_x_v_ki_bi_ortho_erf_rk_cst_mu_transp, (n_points_final_grid, 3, mo_num, mo_num)]
  implicit none
  integer :: i, j, m, ipoint
  do i = 1, mo_num
    do j = 1, mo_num
      do m = 1, 3
        do ipoint = 1, n_points_final_grid
          mo_x_v_ki_bi_ortho_erf_rk_cst_mu_transp(ipoint,m,j,i) = mo_x_v_ki_bi_ortho_erf_rk_cst_mu(j,i,m,ipoint)
        enddo
      enddo
    enddo
  enddo
END_PROVIDER 

! ---


BEGIN_PROVIDER [ double precision, x_W_ki_bi_ortho_erf_rk, (n_points_final_grid, 3, mo_num, mo_num)]
  BEGIN_DOC
  ! x_W_ki_bi_ortho_erf_rk(ip,m,k,i) = \int dr chi_k(r) (1 - erf(mu |r-R_ip|)) (x(m)-X(m)_ip) phi_i(r) ON THE BI-ORTHO MO BASIS 
!
! where chi_k(r)/phi_i(r) are left/right MOs, m=1 => X(m) = x, m=2 => X(m) = y, m=3 => X(m) = z,
!
! R_ip = the "ip"-th point of the DFT Grid
  END_DOC
 
  implicit none
  include 'constants.include.F'
 
  integer          :: ipoint, m, i, k
  double precision :: xyz
  double precision :: wall0, wall1
 
  print*,'providing x_W_ki_bi_ortho_erf_rk ...'
  call wall_time(wall0)

 !$OMP PARALLEL                   &
 !$OMP DEFAULT (NONE)             &
 !$OMP PRIVATE (ipoint,m,i,k,xyz) & 
 !$OMP SHARED (x_W_ki_bi_ortho_erf_rk,n_points_final_grid,mo_x_v_ki_bi_ortho_erf_rk_cst_mu_transp,mo_v_ki_bi_ortho_erf_rk_cst_mu_transp,mo_num,final_grid_points) 
 !$OMP DO SCHEDULE (dynamic)
  do i = 1, mo_num
    do k = 1, mo_num
      do m = 1, 3
        do ipoint = 1, n_points_final_grid
          xyz = final_grid_points(m,ipoint)
          x_W_ki_bi_ortho_erf_rk(ipoint,m,k,i) = mo_x_v_ki_bi_ortho_erf_rk_cst_mu_transp(ipoint,m,k,i) - xyz * mo_v_ki_bi_ortho_erf_rk_cst_mu_transp(ipoint,k,i)
        enddo
      enddo
    enddo
  enddo

 !$OMP END DO
 !$OMP END PARALLEL

 ! FREE mo_v_ki_bi_ortho_erf_rk_cst_mu_transp 
 ! FREE mo_x_v_ki_bi_ortho_erf_rk_cst_mu_transp

  call wall_time(wall1)
  print*,'time to provide x_W_ki_bi_ortho_erf_rk = ',wall1 - wall0

END_PROVIDER 

! ---

BEGIN_PROVIDER [ double precision, x_W_ki_bi_ortho_erf_rk_diag, (n_points_final_grid, 3, mo_num)]
  BEGIN_DOC
  ! x_W_ki_bi_ortho_erf_rk_diag(ip,m,i) = \int dr chi_i(r) (1 - erf(mu |r-R_ip|)) (x(m)-X(m)_ip) phi_i(r) ON THE BI-ORTHO MO BASIS 
!
! where chi_k(r)/phi_i(r) are left/right MOs, m=1 => X(m) = x, m=2 => X(m) = y, m=3 => X(m) = z,
!
! R_ip = the "ip"-th point of the DFT Grid
  END_DOC

  implicit none
  include 'constants.include.F'
 
  integer          :: ipoint, m, i
  double precision :: xyz
  double precision :: wall0, wall1
 
  print*,'providing x_W_ki_bi_ortho_erf_rk_diag ...'
  call wall_time(wall0)

 !$OMP PARALLEL                 &
 !$OMP DEFAULT (NONE)           &
 !$OMP PRIVATE (ipoint,m,i,xyz) & 
 !$OMP SHARED (x_W_ki_bi_ortho_erf_rk_diag,n_points_final_grid,mo_x_v_ki_bi_ortho_erf_rk_cst_mu_transp,mo_v_ki_bi_ortho_erf_rk_cst_mu_transp,mo_num,final_grid_points) 
 !$OMP DO SCHEDULE (dynamic)
  do i = 1, mo_num
    do m = 1, 3
      do ipoint = 1, n_points_final_grid
        xyz = final_grid_points(m,ipoint)
        x_W_ki_bi_ortho_erf_rk_diag(ipoint,m,i) = mo_x_v_ki_bi_ortho_erf_rk_cst_mu_transp(ipoint,m,i,i) - xyz * mo_v_ki_bi_ortho_erf_rk_cst_mu_transp(ipoint,i,i)
      enddo
    enddo
  enddo

 !$OMP END DO
 !$OMP END PARALLEL

  call wall_time(wall1)
  print*,'time to provide x_W_ki_bi_ortho_erf_rk_diag = ',wall1 - wall0

END_PROVIDER 

! ---

