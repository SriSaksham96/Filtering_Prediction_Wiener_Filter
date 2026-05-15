# Wiener Filter System Design Document
**Course:** Computer Architecture Lab (CO2008)  
**Assignment:** Filtering and Prediction Signal with Wiener Filter  
**Role:** Member 1 — Math, Algorithm Design & System Architect  

---

# 1. Design Goals

The objective of this document is to standardize the Wiener filter implementation before coding begins. It defines:

- Filter length selection (`M`)
- Memory organization
- Data structure layout
- Matrix storage conventions
- Addressing rules
- Shared variable labels for all members

This document must be followed consistently by all team members to avoid memory conflicts and implementation mismatch.

---

# 2. Filter Length Decision

## Chosen Filter Length

```text
M = 10
```

## Reason for Choosing M = 10

The assignment must be completed in **4 days** by a **team of 3 members**, therefore implementation complexity must remain manageable while still maintaining acceptable filtering performance.

The following tradeoff analysis was considered:

| M Value | Advantages | Disadvantages |
|----------|-------------|----------------|
| M = 4 | Easy implementation, smaller matrix | Fewer coefficients, potentially lower filter quality |
| M = 5 | Moderate complexity | Moderate matrix computation |
| M = 10 | Maximum filter quality, M = N for full utilization of signal data | Larger 10×10 matrix, more complex Gaussian elimination |

After evaluation, **M = 10** was selected because:

- Maximizes Wiener filter accuracy by utilizing all available signal samples
- M = N allows the filter to fully exploit the input data
- With partial pivoting in Gaussian elimination, the 10×10 system is numerically stable
- Matrix size (`10 × 10`) remains computationally practical for MIPS FPU operations

The following dimensions will be used:

- Autocorrelation matrix:

$begin:math:display$
R\_M \\rightarrow 10 \\times 10
$end:math:display$

- Cross-correlation vector:

$begin:math:display$
\\gamma\_d \\rightarrow 10 \\times 1
$end:math:display$

- Wiener coefficients:

$begin:math:display$
h \\rightarrow 10 \\times 1
$end:math:display$

---

# 3. Signal Assumptions

According to assignment requirements:

- `desired.txt` contains desired signal sequence
- `input.txt` contains noisy input signal
- Each file contains **10 floating-point samples**
- Floating-point numbers are rounded to **1 decimal place**

Signal length:

```text
N = 10
```

---

# 4. Shared Variable Naming Convention

The following labels must be used consistently across the entire project.

| Variable | Purpose |
|----------|---------|
| `desired_signal` | Stores desired signal sequence |
| `input_signal` | Stores noisy input signal |
| `R_M` | Autocorrelation matrix |
| `gamma_d` | Cross-correlation vector |
| `optimize_coefficient` | Wiener filter coefficients |
| `output_signal` | Filtered output sequence |
| `mmse` | Final MMSE value |

No alternative naming should be used.

---

# 5. Memory Layout

## Memory Allocation Strategy

All floating-point values use:

```text
4 bytes per float
```

All arrays are stored as **contiguous memory blocks**.

### Data Layout

```assembly
.data

# ==========================
# INPUT SIGNALS
# ==========================

desired_signal:         .space 40
input_signal:           .space 40

desired_size:           .word 0
input_size:             .word 0

# ==========================
# FILTER CONFIGURATION
# ==========================

M_value:                .word 10

# ==========================
# WIENER FILTER COMPONENTS
# ==========================

autocorrelation:        .space 40
R_M:                    .space 400
gamma_d:                .space 40
optimize_coefficient:   .space 40

# ==========================
# OUTPUT
# ==========================

output_signal:          .space 40
mmse:                   .float 0.0

# ==========================
# TEMPORARY STORAGE
# ==========================

augmented_matrix:       .space 440

# ==========================
# FILE HANDLING
# ==========================

input_buffer:           .space 256
output_buffer:          .space 256

desired_filename:       .asciiz "desired.txt"
input_filename:         .asciiz "input.txt"
output_filename:        .asciiz "output.txt"

error_msg:              .asciiz "Error: size not match"
newline:                .asciiz "\n"
space_char:             .asciiz " "
```

## Signal Size Counters

The following variables are used during file reading:

```assembly
desired_size: .word 0
input_size:   .word 0
```

### Purpose

- Count the number of parsed floating-point samples
- Verify signal lengths match
- Support input validation before Wiener filter computation

### Logic

Each time a float is parsed from file:

```text
size = size + 1
```

After file reading:

```text
IF desired_size != input_size

    Print:
    "Error: size not match"

    Exit program

END IF
```

---

# 6. Array Storage Convention

## 6.1 Desired Signal

Stores desired signal:

$begin:math:display$
d\(n\)
$end:math:display$

Memory allocation:

```text
10 floats × 4 bytes = 40 bytes
```

Address calculation:

```text
desired_signal + (index × 4)
```

Example:

| Sample | Address Offset |
|--------|----------------|
| d(0) | +0 |
| d(1) | +4 |
| d(2) | +8 |
| d(3) | +12 |

---

## 6.2 Input Signal

Stores noisy signal:

$begin:math:display$
x\(n\)
$end:math:display$

Address formula:

```text
input_signal + (index × 4)
```

---

# 7. Autocorrelation Matrix Storage (`R_M`)

The Wiener filter requires a **10 × 10 autocorrelation matrix**.

Instead of a true 2D matrix, MIPS stores matrices as a **flat row-major array**.

Matrix structure:

R_M is a 10 × 10 symmetric Toeplitz matrix where R_M[i][j] = autocorrelation[|i - j|].

Memory representation:

Stored as a flat row-major array of 100 floats (400 bytes).
Element R_M[i][j] is at flat index (i × 10 + j).

## Row-Major Index Formula

```text
index = (row × M) + column
```

Since:

```text
M = 10
```

Address formula:

```text
memory_address = base + ((row × 10 + column) × 4)
```

### Example

Access:

```text
R_M[2][1]
```

Calculation:

```text
index = (2 × 10) + 1
index = 21
offset = 21 × 4 = 84 bytes
```

## Augmented Matrix Storage

Gaussian elimination requires an augmented matrix:

```text
[R_M | gamma_d]
```

Since:

```text
M = 10
```

The augmented matrix dimensions become:

```text
10 × 11
```

Memory allocation:

```assembly
augmented_matrix: .space 440
```

The matrix is stored using a flat row-major layout.

Example memory representation:

```text
Row 0  → [0][1][2]...[10]
Row 1  → [11][12][13]...[21]
...
Row 9  → [99][100][101]...[109]
```

### Row-Major Index Formula

```text
index = (row × 11) + column
```

### Address Formula

```text
memory_address =
base + ((row × 11 + column) × 4)
```

---

# 8. Cross-Correlation Vector (`gamma_d`)

Stores:

$begin:math:display$
\gamma_d
$end:math:display$

For `M = 10`, the matrix is a 10×10 symmetric Toeplitz matrix where element R_M[i][j] = γxx(|i - j|).

Vector structure:

$begin:math:display$
\begin{bmatrix}
\gamma(0)\\
\gamma(1)\\
\gamma(2)\\
\gamma(3)\\
...\\
\gamma(9)
\end{bmatrix}
$end:math:display$

Memory:

```text
10 floats × 4 bytes = 40 bytes
```

Addressing:

```text
gamma_d + (index × 4)
```

---

# 9. Optimized Coefficient Storage

Stores Wiener coefficients:

$begin:math:display$
h\=
\[h\_0\,h\_1\, \ldots \,h\_9\]
$end:math:display$

Memory:

```text
optimize_coefficient + (index × 4)
```

Storage size:

```text
10 floats × 4 bytes = 40 bytes
```

---

# 10. Output Signal Storage

Stores filtered output:

$begin:math:display$
y\(n\)
$end:math:display$

Memory:

```text
10 floats × 4 bytes = 40 bytes
```

Addressing:

```text
output_signal + (index × 4)
```

---

# 11. MMSE Storage

Stores final MMSE result.

Memory type:

```text
Single floating-point value
```

Storage:

```assembly
mmse: .float 0.0
```

---

# 12. Team Implementation Rules

To avoid implementation mismatch, all members must follow the following rules:

1. Use exact variable names defined in this document.
2. Use `M = 10`.
3. Store matrices using flat row-major layout.
4. Use floating-point operations for all mathematical calculations.
5. Use 4-byte offsets for float indexing.
6. Use separate row-major indexing for R_M (10 × 10) and augmented_matrix (10 × 11).
7. Do not modify memory allocation sizes without team agreement.

This document acts as the standard architecture reference for the Wiener Filter implementation.