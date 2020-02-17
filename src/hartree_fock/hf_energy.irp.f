BEGIN_PROVIDER [double precision, extra_e_contrib_density]
 implicit none
 BEGIN_DOC
! Extra contribution to the SCF energy coming from the density.
!
! For a Hartree-Fock calculation: extra_e_contrib_density = 0
!
! For a Kohn-Sham or Range-separated Kohn-Sham: the exchange/correlation - trace of the V_xc potential
 END_DOC
 extra_e_contrib_density = 0.D0

END_PROVIDER

 BEGIN_PROVIDER [ double precision, hf_energy]
&BEGIN_PROVIDER [ double precision, hf_two_electron_energy]
&BEGIN_PROVIDER [ double precision, hf_one_electron_energy]
 implicit none
 BEGIN_DOC
 ! Hartree-Fock energy containing the nuclear repulsion, and its one- and two-body components.
 END_DOC
 integer :: i,j
 hf_energy = nuclear_repulsion
 hf_two_electron_energy = 0.d0
 hf_one_electron_energy = 0.d0
  if (is_complex) then
    complex*16 :: hf_1e_tmp, hf_2e_tmp
    hf_1e_tmp = (0.d0,0.d0)
    hf_2e_tmp = (0.d0,0.d0)
    do j=1,ao_num
      do i=1,ao_num
        hf_2e_tmp += 0.5d0 * ( ao_two_e_integral_alpha_complex(i,j) * scf_density_matrix_ao_alpha_complex(j,i) &
                              +ao_two_e_integral_beta_complex(i,j)  * scf_density_matrix_ao_beta_complex(j,i) )
        hf_1e_tmp += ao_one_e_integrals_complex(i,j) * (scf_density_matrix_ao_alpha_complex(j,i) &
                                                      + scf_density_matrix_ao_beta_complex (j,i) )
      enddo
    enddo
    if (dabs(dimag(hf_2e_tmp)).gt.1.d-10) then
      print*,'HF_2e energy should be real:',irp_here
      stop -1
    else
      hf_two_electron_energy = dble(hf_2e_tmp)
    endif
    if (dabs(dimag(hf_1e_tmp)).gt.1.d-10) then
      print*,'HF_1e energy should be real:',irp_here
      stop -1
    else
      hf_one_electron_energy = dble(hf_1e_tmp)
    endif
  else
    do j=1,ao_num
      do i=1,ao_num
        hf_two_electron_energy += 0.5d0 * ( ao_two_e_integral_alpha(i,j) * scf_density_matrix_ao_alpha(i,j) &
                                           +ao_two_e_integral_beta(i,j)  * scf_density_matrix_ao_beta(i,j) )
        hf_one_electron_energy += ao_one_e_integrals(i,j) * (scf_density_matrix_ao_alpha(i,j) + scf_density_matrix_ao_beta (i,j) )
      enddo
    enddo
  endif
 hf_energy += hf_two_electron_energy + hf_one_electron_energy
END_PROVIDER

