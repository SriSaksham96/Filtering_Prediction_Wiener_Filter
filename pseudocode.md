# Wiener Filter Algorithm Pseudocode
**Course:** Computer Architecture Lab (CO2008)  
**Assignment:** Filtering and Prediction Signal with Wiener Filter  
**Role:** Member 1 — Math, Algorithm Design & System Architect  

---

# 1. Purpose

This document provides the algorithmic pseudocode for the Wiener Filter implementation in MIPS assembly.

The goal is to provide a coding blueprint that can be directly translated into MIPS instructions while keeping implementation manageable for a 3-member team and a 4-day deadline.

The implementation follows:

- Filter length:

```text
M = 10
```

- Signal length:

```text
N = 10
```

The following components are covered:

1. Input validation  
2. File reading and parsing  
3. Autocorrelation calculation  
4. Cross-correlation calculation  
5. Wiener matrix construction  
6. Gaussian elimination  
7. Output signal generation  
8. MMSE calculation  
9. Terminal and file output  

---

# 2. Overall Program Flow

## High-Level Program Logic

```text
START

Read desired.txt
Read input.txt

Check signal size

IF sizes do not match
    Print error message
    Exit program
END IF

Compute autocorrelation values

Construct R_M matrix

Compute cross-correlation vector gamma_d

Solve Wiener coefficients using Gaussian elimination

Generate filtered output signal

Compute MMSE

Print results to terminal

Write results to output.txt

END
```

---

# 3. File Reading Pseudocode

## Objective

Read signal data from:

```text
desired.txt
input.txt
```

Convert text-based floating-point values into arrays.

## Logic

1. Open file
2. Read file contents into buffer
3. Close file
4. Parse floating-point values
5. Store values into signal array
6. Update signal size

## Pseudocode

```text
FUNCTION read_signal_file(filename, signal_array)

    Open file using syscall 13

    Read file contents into input_buffer
    using syscall 14

    Close file using syscall 16

    size = 0

    Parse buffer token by token

    FOR every float token

        Convert ASCII text to float

        Store float into signal_array[size]

        size = size + 1

    END FOR

    RETURN size

END FUNCTION
```

---

# 4. Input Validation Pseudocode

## Objective

Ensure both signal files contain the same number of samples.

## Pseudocode

```text
IF desired_size != input_size

    Print:
    "Error: size not match"

    Terminate program

END IF
```

---

# 5. Autocorrelation Pseudocode

## Objective

Compute autocorrelation values:

$begin:math:display$
\\gamma\_\{xx\}\(k\)
$end:math:display$

for:

```text
k = 0 to M-1
```

The autocorrelation values are later used to construct the matrix:

$begin:math:display$
R\_M
$end:math:display$

## Logic

For each lag value:

1. Multiply shifted signal values
2. Sum all products
3. Divide by valid sample count

## Pseudocode

```text
FOR lag = 0 to M-1

    sum = 0

    FOR n = lag to N-1

        value1 = input_signal[n]

        value2 = input_signal[n - lag]

        product = value1 × value2

        sum = sum + product

    END FOR

    autocorrelation[lag] =
    sum / (N - lag)

END FOR
```

---

# 6. Wiener Matrix Construction (`R_M`)

## Objective

Construct the Toeplitz autocorrelation matrix.

Matrix format:

R_M is an M × M Toeplitz matrix where element R_M[i][j] = γxx(|i - j|).
With M = 10, this is a 10 × 10 symmetric matrix.

## Logic

Each matrix element uses:

```text
autocorrelation[absolute(row - column)]
```

## Pseudocode

```text
FOR row = 0 to M-1

    FOR column = 0 to M-1

        lag = absolute(row - column)

        R_M[row][column] =
        autocorrelation[lag]

    END FOR

END FOR
```

---

# 7. Cross-Correlation Pseudocode

## Objective

Compute:

$begin:math:display$
\\gamma\_\{dx\}\(k\)
$end:math:display$

for:

```text
k = 0 to M-1
```

This generates:

$begin:math:display$
\\gamma\_d
$end:math:display$

which becomes the right-side vector in the Wiener-Hopf equation.

## Logic

For every lag:

1. Multiply desired signal and shifted input signal
2. Sum products
3. Normalize by valid sample count

## Pseudocode

```text
FOR lag = 0 to M-1

    sum = 0

    FOR n = lag to N-1

        desired_value =
        desired_signal[n]

        input_value =
        input_signal[n - lag]

        product =
        desired_value × input_value

        sum =
        sum + product

    END FOR

    gamma_d[lag] =
    sum / (N - lag)

END FOR
```

---

# 8. Gaussian Elimination Pseudocode

## Objective

Solve:

R_M h = \gamma_d

without explicitly computing matrix inverse.

Instead, solve using Gaussian elimination.

## Step 1 — Create Augmented Matrix

Construct:

```text
[R_M | gamma_d]
```

For `M = 10`:

```text
10 × 11 matrix
```

## Augmented Matrix Indexing

Since the augmented matrix uses dimensions:

```text
10 × 11
```

its row-major indexing differs from `R_M`.

Index formula:

```text
index = (row × 11) + column
```

Address calculation:

```text
memory_address =
base + ((row × 11 + column) × 4)
```

## Pseudocode

```text
FOR row = 0 to M-1

    FOR column = 0 to M-1

        augmented[row][column] =
        R_M[row][column]

    END FOR

    augmented[row][M] =
    gamma_d[row]

END FOR
```

---

## Step 2 — Forward Elimination

Goal:

Convert matrix into upper triangular form.

## Pseudocode

```text
FOR pivot = 0 to M-1

    pivot_value =
    augmented[pivot][pivot]

    IF pivot_value == 0

        Search rows below

        Swap with a valid row

    END IF

    FOR column = pivot to M

        augmented[pivot][column] =
        augmented[pivot][column]
        / pivot_value

    END FOR

    FOR row = pivot + 1 to M-1

        factor =
        augmented[row][pivot]

        FOR column = pivot to M

            augmented[row][column] =
            augmented[row][column]
            -
            factor ×
            augmented[pivot][column]

        END FOR

    END FOR

END FOR
```

---

## Step 3 — Back Substitution

Goal:

Solve coefficients:

```text
h0 h1 h2 h3 h4 h5 h6 h7 h8 h9
```

## Pseudocode

```text
FOR row = M-1 down to 0

    sum = 0

    FOR column = row+1 to M-1

        sum =
        sum +
        augmented[row][column]
        ×
        optimize_coefficient[column]

    END FOR

    optimize_coefficient[row] =
    augmented[row][M]
    -
    sum

END FOR
```

---

# 9. Output Signal Generation

## Objective

Generate filtered signal:

y(n)=\sum_{k=0}^{M-1}h_kx(n-k)

Store result in:

```text
output_signal
```

## Logic

For every sample:

1. Multiply coefficient with delayed signal
2. Add products
3. Store output

Boundary checking is required.

## Pseudocode

```text
FOR n = 0 to N-1

    output = 0

    FOR k = 0 to M-1

        index = n - k

        IF index >= 0

            output =
            output +
            optimize_coefficient[k]
            ×
            input_signal[index]

        END IF

    END FOR

    output_signal[n] =
    output

END FOR
```

---

# 10. MMSE Calculation

## Objective

Compute:

MMSE=\frac{1}{N}\sum_{n=0}^{N-1}(d(n)-y(n))^2

This implementation is simpler than matrix MMSE while remaining mathematically valid for the assignment.

## Logic

1. Compute error
2. Square error
3. Add squared errors
4. Divide by signal size

## Pseudocode

```text
sum = 0

FOR n = 0 to N-1

    error =
    desired_signal[n]
    -
    output_signal[n]

    squared_error =
    error × error

    sum =
    sum + squared_error

END FOR

mmse = sum / N
```

---

# 11. Output Formatting Pseudocode

## Objective

Display result in terminal and output file.

Required output:

### Line 1

Filtered output signal.

Example:

```text
1.2 2.4 3.1 4.5 ...
```

### Line 2

MMSE value.

Example:

```text
MMSE: 0.014
```

## Pseudocode

```text
FOR i = 0 to N-1

    Print output_signal[i]

    Print space

END FOR

Print newline

Print "MMSE: "

Print mmse
```

## Implementation Note

MARS syscall 2 prints floating-point values directly. If cleaner decimal formatting is required during testing, manual rounding or truncation logic may be added later. However, default float printing is acceptable for the initial implementation.

---

# 12. Computational Complexity

| Component | Complexity |
|-----------|------------|
| Autocorrelation | O(M × N) |
| Cross-correlation | O(M × N) |
| Matrix construction | O(M²) |
| Gaussian elimination | O(M³) |
| Output signal | O(M × N) |
| MMSE | O(N) |

Since:

```text
M = 10
N = 10
```

The computation remains manageable for MIPS implementation, though the 10×10 Gaussian elimination requires careful handling.

---

# 13. Team Implementation Notes

1. Follow pseudocode exactly during MIPS implementation.
2. Preserve loop ordering.
3. Use floating-point instructions for arithmetic.
4. Maintain row-major indexing for matrices.
5. Validate signal sizes before calculations.
6. Keep `M = 10` fixed across all modules (M equals signal length N).
7. File parsing and float conversion should be implemented carefully, as file I/O is one of the most error-prone parts of MARS assembly programming.

This pseudocode document acts as the primary implementation guide for coding the Wiener Filter in MIPS assembly.