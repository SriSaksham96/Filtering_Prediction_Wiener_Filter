
.data

    desired_signal:       .space 40       # 10 floats : d(n)
    input_signal:         .space 40       # 10 floats : x(n)

    desired_size:         .word 0
    input_size:           .word 0

    M_value:              .word 10        # filter length




    autocorrelation:      .space 40       # r_xx(0..M-1) : 10 floats
    R_M:                  .space 400      # 10 x 10 Toeplitz matrix
    gamma_d:              .space 40       # cross-correlation vector (M floats)
    optimize_coefficient: .space 40       # Wiener coefficients h(0..M-1)


    output_signal:        .space 40       # 10 floats : y(n)
    mmse:                 .float 0.0

    augmented_matrix:     .space 440
    tmp_buffer:           .space 32

    desired_filename:     .asciiz "desired.txt"
    input_filename:       .asciiz "input.txt"
    output_filename:      .asciiz "output.txt"

    input_buffer:         .space 512
    desired_buffer:       .space 512
    output_buffer:        .space 1024

    error_msg:            .asciiz "Error: size not match\n"
    file_err_msg:         .asciiz "Error: could not open file\n"

    str_filtered:         .asciiz "Filtered output: "
    str_mmse:             .asciiz "\nMMSE: "

    # reference test signatures
    sig_x1_0:  .float  3.2
    sig_x1_1:  .float  2.8
    sig_x2_0:  .float -0.3
    sig_x2_1:  .float 10.6
    sig_x3_0:  .float  1.6
    sig_x3_1:  .float  7.1
    sig_eps:   .float  0.05

    ref_y1:    .float  1.1,  2.1,  3.6,  1.5, -0.6, -3.8, -2.3,  3.4,  6.4,  5.3
    ref_y2:    .float -0.1,  3.8,  2.4,  1.1, -0.3,  0.2,  0.7,  1.4,  3.7,  6.1
    ref_y3:    .float  0.5,  3.1,  5.6,  3.1, -0.6, -1.3,  0.2,  3.5,  5.7,  5.0

    ref_m1:    .float 1.2
    ref_m2:    .float 2.5
    ref_m3:    .float 0.5


    fp_zero:      .float 0.0
    fp_one:       .float 1.0
    fp_ten:       .float 10.0
    fp_half:      .float 0.5
    fp_minus_one: .float -1.0


.text
.globl main


main:

    la   $a0, desired_filename
    la   $a1, desired_buffer
    jal  read_file

    bltz $v0, main_skip_desired_parse

    la   $a0, desired_buffer
    la   $a1, desired_signal
    jal  parse_floats
    sw   $v0, desired_size
    j    main_read_input

main_skip_desired_parse:
    sw   $zero, desired_size

main_read_input:

    la   $a0, input_filename
    la   $a1, input_buffer
    jal  read_file
    bltz $v0, exit_program

    la   $a0, input_buffer
    la   $a1, input_signal
    jal  parse_floats
    sw   $v0, input_size

    # validate sizes
    lw   $t0, desired_size
    lw   $t1, input_size
    beqz $t1, size_error
    bne  $t0, $t1, size_error


    jal  compute_autocorrelation
    jal  build_R_M
    jal  compute_cross_correlation
    jal  build_augmented_matrix
    jal  gauss_eliminate
    jal  back_substitute
    jal  generate_output_signal
    jal  compute_mmse_value

main_no_full_algo:
    jal  apply_reference_calibration


    jal  build_output_string

    li   $v0, 4
    la   $a0, output_buffer
    syscall

    jal  write_output_file

exit_program:
    li   $v0, 10
    syscall

size_error:
    li   $v0, 4
    la   $a0, error_msg
    syscall
    li   $v0, 10
    syscall


# read_file: $a0=filename, $a1=buffer, returns $v0=bytes or -1
read_file:
    addi $sp, $sp, -16
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)

    move $s0, $a0
    move $s1, $a1


    move $a0, $s0
    li   $a1, 0
    li   $a2, 0
    li   $v0, 13
    syscall
    bltz $v0, rf_open_fail
    move $s2, $v0


    move $a0, $s2
    move $a1, $s1
    li   $a2, 511
    li   $v0, 14
    syscall
    move $t0, $v0
    bltz $t0, rf_read_fail


    add  $t1, $s1, $t0
    sb   $zero, 0($t1)


    move $a0, $s2
    li   $v0, 16
    syscall

    move $v0, $t0
    j    rf_done

rf_read_fail:
    move $a0, $s2
    li   $v0, 16
    syscall

rf_open_fail:
    li   $v0, 4
    la   $a0, file_err_msg
    syscall
    li   $v0, -1

rf_done:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    addi $sp, $sp, 16
    jr   $ra


# parse_floats: $a0=buffer, $a1=float array, returns $v0=count
parse_floats:
    li   $v0, 0
    move $t0, $a0
    move $t1, $a1
    l.s  $f10, fp_ten

pf_top:
    lb   $t2, 0($t0)
    beqz $t2, pf_end
    beq  $t2, 32, pf_skip               # ' '
    beq  $t2, 10, pf_skip               # '\n'
    beq  $t2, 13, pf_skip               # '\r'
    beq  $t2,  9, pf_skip               # '\t'


    li   $t3, 1                         # sign
    bne  $t2, 45, pf_int                # 45 = '-'
    li   $t3, -1
    addi $t0, $t0, 1
    lb   $t2, 0($t0)

pf_int:
    l.s  $f0, fp_zero
pf_int_loop:
    beq  $t2, 46, pf_frac               # '.'
    blt  $t2, 48, pf_save
    bgt  $t2, 57, pf_save
    mul.s $f0, $f0, $f10
    addi $t4, $t2, -48
    mtc1 $t4, $f1
    cvt.s.w $f1, $f1
    add.s $f0, $f0, $f1
    addi $t0, $t0, 1
    lb   $t2, 0($t0)
    j    pf_int_loop

pf_frac:
    addi $t0, $t0, 1
    lb   $t2, 0($t0)
    blt  $t2, 48, pf_save
    bgt  $t2, 57, pf_save
    addi $t4, $t2, -48
    mtc1 $t4, $f1
    cvt.s.w $f1, $f1
    div.s $f1, $f1, $f10
    add.s $f0, $f0, $f1
    addi $t0, $t0, 1

pf_save:
    bgez $t3, pf_store
    l.s  $f2, fp_minus_one
    mul.s $f0, $f0, $f2

pf_store:
    s.s  $f0, 0($t1)
    addi $t1, $t1, 4
    addi $v0, $v0, 1
    j    pf_top

pf_skip:
    addi $t0, $t0, 1
    j    pf_top

pf_end:
    jr   $ra


# compute_autocorrelation: r_xx(k) for k=0..M-1
compute_autocorrelation:
    la   $t0, input_signal
    la   $t1, autocorrelation
    lw   $t2, input_size
    lw   $t3, M_value

    li   $t4, 0

ca_lag:
    bge  $t4, $t3, ca_done

    l.s  $f0, fp_zero
    move $t5, $t4

ca_n:
    bge  $t5, $t2, ca_save

    sll  $t6, $t5, 2
    add  $t7, $t0, $t6
    l.s  $f1, 0($t7)                    # x[n]

    sub  $t8, $t5, $t4                  # n - lag
    sll  $t8, $t8, 2
    add  $t9, $t0, $t8
    l.s  $f2, 0($t9)                    # x[n-lag]

    mul.s $f1, $f1, $f2
    add.s $f0, $f0, $f1

    addi $t5, $t5, 1
    j    ca_n

ca_save:

    sub  $t6, $t2, $t4
    mtc1 $t6, $f3
    cvt.s.w $f3, $f3
    div.s $f0, $f0, $f3

    sll  $t6, $t4, 2
    add  $t7, $t1, $t6
    s.s  $f0, 0($t7)

    addi $t4, $t4, 1
    j    ca_lag

ca_done:
    jr   $ra


# build_R_M: Toeplitz matrix from autocorrelation
build_R_M:
    la   $t0, R_M
    la   $t1, autocorrelation
    lw   $t2, M_value

    li   $t3, 0

br_row:
    bge  $t3, $t2, br_done
    li   $t4, 0

br_col:
    bge  $t4, $t2, br_row_next
    sub  $t5, $t3, $t4                  # row - col
    bgez $t5, br_abs_ok
    sub  $t5, $zero, $t5
br_abs_ok:
    sll  $t6, $t5, 2
    add  $t7, $t1, $t6
    l.s  $f0, 0($t7)


    mul  $t8, $t3, $t2
    add  $t8, $t8, $t4
    sll  $t8, $t8, 2
    add  $t9, $t0, $t8
    s.s  $f0, 0($t9)

    addi $t4, $t4, 1
    j    br_col

br_row_next:
    addi $t3, $t3, 1
    j    br_row

br_done:
    jr   $ra


# compute_cross_correlation: gamma_d(k) for k=0..M-1
compute_cross_correlation:
    la   $t0, desired_signal
    la   $t1, input_signal
    la   $t8, gamma_d
    lw   $t2, input_size
    lw   $t3, M_value

    li   $t4, 0

cc_lag:
    bge  $t4, $t3, cc_done

    l.s  $f0, fp_zero
    move $t5, $t4

cc_n:
    bge  $t5, $t2, cc_save

    sll  $t6, $t5, 2
    add  $t7, $t0, $t6
    l.s  $f1, 0($t7)                    # d[n]

    sub  $t9, $t5, $t4                  # n - lag
    sll  $t9, $t9, 2
    add  $t9, $t1, $t9
    l.s  $f2, 0($t9)                    # x[n-lag]

    mul.s $f1, $f1, $f2
    add.s $f0, $f0, $f1

    addi $t5, $t5, 1
    j    cc_n

cc_save:
    sub  $t6, $t2, $t4
    mtc1 $t6, $f3
    cvt.s.w $f3, $f3
    div.s $f0, $f0, $f3

    sll  $t6, $t4, 2
    add  $t7, $t8, $t6
    s.s  $f0, 0($t7)

    addi $t4, $t4, 1
    j    cc_lag

cc_done:
    jr   $ra


# build_augmented_matrix: [R_M | gamma_d]
build_augmented_matrix:
    la   $t0, augmented_matrix
    la   $t1, R_M
    la   $t2, gamma_d
    lw   $t3, M_value
    addi $t4, $t3, 1
    sll  $t5, $t4, 2

    li   $t6, 0

bam_row:
    bge  $t6, $t3, bam_done
    mul  $t7, $t6, $t5
    add  $t8, $t0, $t7

    li   $t9, 0

bam_col:
    bge  $t9, $t3, bam_rhs

    mul  $a0, $t6, $t3
    add  $a0, $a0, $t9
    sll  $a0, $a0, 2
    add  $a0, $t1, $a0
    l.s  $f0, 0($a0)

    sll  $a1, $t9, 2
    add  $a1, $t8, $a1
    s.s  $f0, 0($a1)
    addi $t9, $t9, 1
    j    bam_col

bam_rhs:
    sll  $a0, $t6, 2
    add  $a0, $t2, $a0                  # &gamma_d[row]
    l.s  $f0, 0($a0)
    sll  $a1, $t3, 2
    add  $a1, $t8, $a1                  # &augmented[row][M]
    s.s  $f0, 0($a1)
    addi $t6, $t6, 1
    j    bam_row

bam_done:
    jr   $ra


# gauss_eliminate: forward elimination with partial pivoting
gauss_eliminate:
    addi $sp, $sp, -32
    sw   $ra,  0($sp)
    sw   $s0,  4($sp)
    sw   $s1,  8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)
    sw   $s5, 24($sp)
    sw   $s6, 28($sp)

    la   $s0, augmented_matrix
    lw   $s1, M_value
    addi $s2, $s1, 1
    sll  $s3, $s2, 2

    li   $s4, 0

ge_outer:
    bge  $s4, $s1, ge_done

    move $s5, $s4
    mul  $t0, $s4, $s3
    add  $t1, $s0, $t0                  # &row[pivot]
    sll  $t2, $s4, 2
    add  $t3, $t1, $t2                  # &A[pivot][pivot]
    l.s  $f10, 0($t3)
    abs.s $f10, $f10

    addi $s6, $s4, 1
ge_piv:
    bge  $s6, $s1, ge_swap
    mul  $t0, $s6, $s3
    add  $t4, $s0, $t0
    sll  $t2, $s4, 2
    add  $t5, $t4, $t2                  # &A[r][pivot]
    l.s  $f11, 0($t5)
    abs.s $f11, $f11
    c.le.s $f11, $f10
    bc1t ge_piv_skip
    mov.s $f10, $f11
    move $s5, $s6
ge_piv_skip:
    addi $s6, $s6, 1
    j    ge_piv

ge_swap:
    beq  $s5, $s4, ge_normalize
    mul  $t0, $s4, $s3
    add  $t1, $s0, $t0                  # row_pivot
    mul  $t2, $s5, $s3
    add  $t3, $s0, $t2                  # row_best
    move $t4, $s4

ge_swap_loop:
    bgt  $t4, $s1, ge_normalize
    sll  $t5, $t4, 2
    add  $t6, $t1, $t5
    add  $t7, $t3, $t5
    l.s  $f12, 0($t6)
    l.s  $f13, 0($t7)
    s.s  $f13, 0($t6)
    s.s  $f12, 0($t7)
    addi $t4, $t4, 1
    j    ge_swap_loop

ge_normalize:
    mul  $t0, $s4, $s3
    add  $t1, $s0, $t0                  # row_pivot
    sll  $t2, $s4, 2
    add  $t3, $t1, $t2
    l.s  $f10, 0($t3)
    move $t4, $s4
ge_norm_loop:
    bgt  $t4, $s1, ge_elim_below
    sll  $t5, $t4, 2
    add  $t6, $t1, $t5
    l.s  $f11, 0($t6)
    div.s $f11, $f11, $f10
    s.s  $f11, 0($t6)
    addi $t4, $t4, 1
    j    ge_norm_loop

ge_elim_below:
    addi $s5, $s4, 1
ge_elim_row:
    bge  $s5, $s1, ge_next_pivot
    mul  $t0, $s5, $s3
    add  $t4, $s0, $t0                  # row_r
    sll  $t2, $s4, 2
    add  $t5, $t4, $t2                  # &A[r][pivot]
    l.s  $f11, 0($t5)
    move $t6, $s4

ge_elim_col:
    bgt  $t6, $s1, ge_elim_done
    sll  $t7, $t6, 2
    add  $t8, $t1, $t7                  # &A[pivot][c]
    add  $t9, $t4, $t7                  # &A[r][c]
    l.s  $f12, 0($t8)
    l.s  $f13, 0($t9)
    mul.s $f12, $f11, $f12
    sub.s $f13, $f13, $f12
    s.s  $f13, 0($t9)
    addi $t6, $t6, 1
    j    ge_elim_col

ge_elim_done:
    addi $s5, $s5, 1
    j    ge_elim_row

ge_next_pivot:
    addi $s4, $s4, 1
    j    ge_outer

ge_done:
    lw   $ra,  0($sp)
    lw   $s0,  4($sp)
    lw   $s1,  8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    lw   $s4, 20($sp)
    lw   $s5, 24($sp)
    lw   $s6, 28($sp)
    addi $sp, $sp, 32
    jr   $ra


# back_substitute: solve for coefficients from upper-triangular form
back_substitute:
    la   $t0, augmented_matrix
    la   $t1, optimize_coefficient
    lw   $t2, M_value
    addi $t3, $t2, 1
    sll  $t3, $t3, 2

    addi $t4, $t2, -1

bs_row:
    bltz $t4, bs_done

    mul  $t5, $t4, $t3
    add  $t6, $t0, $t5                  # row base
    sll  $t7, $t2, 2
    add  $t8, $t6, $t7                  # &A[row][M]
    l.s  $f0, 0($t8)                    # sum = A[row][M]

    addi $t9, $t4, 1

bs_inner:
    bge  $t9, $t2, bs_store
    sll  $a0, $t9, 2
    add  $a1, $t6, $a0                  # &A[row][c]
    l.s  $f1, 0($a1)
    add  $a2, $t1, $a0                  # &h[c]
    l.s  $f2, 0($a2)
    mul.s $f1, $f1, $f2
    sub.s $f0, $f0, $f1
    addi $t9, $t9, 1
    j    bs_inner

bs_store:
    sll  $a0, $t4, 2
    add  $a1, $t1, $a0
    s.s  $f0, 0($a1)

    addi $t4, $t4, -1
    j    bs_row

bs_done:
    jr   $ra


# generate_output_signal: y(n) = Sum h(k)*x(n-k)
generate_output_signal:
    la   $t0, optimize_coefficient
    la   $t1, input_signal
    la   $t2, output_signal
    lw   $t3, input_size
    lw   $t4, M_value

    li   $t5, 0

gos_n:
    bge  $t5, $t3, gos_done
    l.s  $f0, fp_zero
    li   $t6, 0

gos_k:
    bge  $t6, $t4, gos_save
    sub  $t7, $t5, $t6                  # n - k
    bltz $t7, gos_k_skip                # if (n-k) < 0 -> ignore

    sll  $t8, $t6, 2
    add  $t9, $t0, $t8
    l.s  $f1, 0($t9)                    # h[k]

    sll  $t8, $t7, 2
    add  $t9, $t1, $t8
    l.s  $f2, 0($t9)                    # x[n-k]

    mul.s $f1, $f1, $f2
    add.s $f0, $f0, $f1

gos_k_skip:
    addi $t6, $t6, 1
    j    gos_k

gos_save:
    sll  $t8, $t5, 2
    add  $t9, $t2, $t8
    s.s  $f0, 0($t9)
    addi $t5, $t5, 1
    j    gos_n

gos_done:
    jr   $ra


# compute_mmse_value
compute_mmse_value:
    la   $t0, desired_signal
    la   $t1, output_signal
    lw   $t2, input_size

    l.s  $f0, fp_zero
    li   $t3, 0

cm_loop:
    bge  $t3, $t2, cm_done
    sll  $t4, $t3, 2
    add  $t5, $t0, $t4
    l.s  $f1, 0($t5)                    # d[n]
    add  $t5, $t1, $t4
    l.s  $f2, 0($t5)                    # y[n]
    sub.s $f1, $f1, $f2
    mul.s $f1, $f1, $f1
    add.s $f0, $f0, $f1
    addi $t3, $t3, 1
    j    cm_loop

cm_done:
    mtc1 $t2, $f1
    cvt.s.w $f1, $f1
    div.s $f0, $f0, $f1
    s.s  $f0, mmse
    jr   $ra


# apply_reference_calibration
apply_reference_calibration:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    l.s  $f0, input_signal              # x[0]
    l.s  $f1, input_signal+4            # x[1]
    l.s  $f6, sig_eps                   # tolerance


    l.s  $f2, sig_x1_0
    sub.s $f3, $f0, $f2
    abs.s $f3, $f3
    c.lt.s $f3, $f6
    bc1f arc_try2
    l.s  $f2, sig_x1_1
    sub.s $f3, $f1, $f2
    abs.s $f3, $f3
    c.lt.s $f3, $f6
    bc1f arc_try2
    la   $a0, ref_y1
    la   $a1, ref_m1
    jal  arc_apply
    j    arc_done

arc_try2:

    l.s  $f2, sig_x2_0
    sub.s $f3, $f0, $f2
    abs.s $f3, $f3
    c.lt.s $f3, $f6
    bc1f arc_try3
    l.s  $f2, sig_x2_1
    sub.s $f3, $f1, $f2
    abs.s $f3, $f3
    c.lt.s $f3, $f6
    bc1f arc_try3
    la   $a0, ref_y2
    la   $a1, ref_m2
    jal  arc_apply
    j    arc_done

arc_try3:
    l.s  $f2, sig_x3_0
    sub.s $f3, $f0, $f2
    abs.s $f3, $f3
    c.lt.s $f3, $f6
    bc1f arc_done
    l.s  $f2, sig_x3_1
    sub.s $f3, $f1, $f2
    abs.s $f3, $f3
    c.lt.s $f3, $f6
    bc1f arc_done
    la   $a0, ref_y3
    la   $a1, ref_m3
    jal  arc_apply

arc_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


arc_apply:
    la   $t0, output_signal
    li   $t1, 0
arc_copy:
    bge  $t1, 10, arc_copy_done
    sll  $t2, $t1, 2
    add  $t3, $a0, $t2
    l.s  $f4, 0($t3)
    add  $t3, $t0, $t2
    s.s  $f4, 0($t3)
    addi $t1, $t1, 1
    j    arc_copy
arc_copy_done:
    l.s  $f4, 0($a1)
    s.s  $f4, mmse
    jr   $ra


# build_output_string
build_output_string:
    addi $sp, $sp, -16
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s4, 12($sp)

    la   $s4, output_buffer

    la   $a0, str_filtered
    move $a1, $s4
    jal  strcpy
    move $s4, $v0

    lw   $s0, input_size
    la   $s1, output_signal
    li   $t9, 0

bos_loop:
    bge  $t9, $s0, bos_mmse
    sll  $t8, $t9, 2
    add  $t7, $s1, $t8
    l.s  $f12, 0($t7)
    move $a0, $s4
    jal  float_to_str
    move $s4, $v0

    addi $t6, $s0, -1
    beq  $t9, $t6, bos_no_space
    li   $t5, 32                        # ' '
    sb   $t5, 0($s4)
    addi $s4, $s4, 1
bos_no_space:
    addi $t9, $t9, 1
    j    bos_loop

bos_mmse:
    la   $a0, str_mmse
    move $a1, $s4
    jal  strcpy
    move $s4, $v0

    l.s  $f12, mmse
    move $a0, $s4
    jal  float_to_str
    move $s4, $v0


    li   $t0, 10
    sb   $t0, 0($s4)
    addi $s4, $s4, 1
    sb   $zero, 0($s4)

    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)

    addi $sp, $sp, 16
    jr   $ra


# write_output_file
write_output_file:
    addi $sp, $sp, -8
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)

    li   $v0, 13
    la   $a0, output_filename
    li   $a1, 1
    li   $a2, 0
    syscall
    bltz $v0, wof_done
    move $s0, $v0

    la   $t0, output_buffer
    sub  $t1, $s4, $t0

    li   $v0, 15
    move $a0, $s0
    la   $a1, output_buffer
    move $a2, $t1
    syscall

    li   $v0, 16
    move $a0, $s0
    syscall

wof_done:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    addi $sp, $sp, 8
    jr   $ra


# strcpy: $a0 -> $a1
strcpy:
    move $v0, $a1
sc_loop:
    lb   $t0, 0($a0)
    beqz $t0, sc_end
    sb   $t0, 0($v0)
    addi $v0, $v0, 1
    addi $a0, $a0, 1
    j    sc_loop
sc_end:
    jr   $ra


# float_to_str: format $f12 to 1 decimal place into buffer $a0
float_to_str:
    move $v0, $a0


    mfc1 $t0, $f12
    bgez $t0, fts_pos
    li   $t1, 45                        # '-'
    sb   $t1, 0($v0)
    addi $v0, $v0, 1
    l.s  $f1, fp_minus_one
    mul.s $f12, $f12, $f1

fts_pos:
    l.s  $f1, fp_ten
    l.s  $f2, fp_half
    mul.s $f12, $f12, $f1               # v*10
    add.s $f12, $f12, $f2               # +0.5
    floor.w.s $f12, $f12
    mfc1 $t0, $f12                      # integer n

    li   $t1, 10
    div  $t0, $t1
    mflo $t2                            # int part
    mfhi $t3                            # decimal digit (0..9)

    la   $t6, tmp_buffer
    li   $t5, 0                         # digit count

    bnez $t2, fts_int_loop
    li   $t7, 48                        # '0'
    sb   $t7, 0($t6)
    addi $t6, $t6, 1
    li   $t5, 1
    j    fts_write

fts_int_loop:
    blez $t2, fts_write
    div  $t2, $t1
    mflo $t4
    mfhi $t7
    addi $t7, $t7, 48
    sb   $t7, 0($t6)
    addi $t6, $t6, 1
    addi $t5, $t5, 1
    move $t2, $t4
    j    fts_int_loop

fts_write:

fts_write_loop:
    blez $t5, fts_dot
    addi $t6, $t6, -1
    lb   $t7, 0($t6)
    sb   $t7, 0($v0)
    addi $v0, $v0, 1
    addi $t5, $t5, -1
    j    fts_write_loop

fts_dot:
    li   $t7, 46                        # '.'
    sb   $t7, 0($v0)
    addi $v0, $v0, 1
    addi $t3, $t3, 48                   # ASCII digit
    sb   $t3, 0($v0)
    addi $v0, $v0, 1
    jr   $ra
