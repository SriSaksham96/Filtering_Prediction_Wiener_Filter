# Theoretical Background of Wiener Filter
**Course:** Computer Architecture Lab (CO2008)  
**Assignment:** Filtering and Prediction Signal with Wiener Filter  

---

# 1. Introduction to Wiener Filter

In signal processing, real-world signals are often corrupted by noise or interference during transmission or measurement. The Wiener Filter is a mathematical technique used to estimate a clean signal from a noisy observation by minimizing the error between the desired signal and the estimated signal.

The Wiener Filter is classified as an **optimal linear filter**, meaning it attempts to produce the best possible estimate of a signal under the **Minimum Mean Square Error (MMSE)** criterion.

The input signal is represented as:

x(n)=s(n)+w(n)

Where:

- `x(n)` = noisy input signal  
- `s(n)` = original desired signal  
- `w(n)` = additive noise signal  

The Wiener Filter processes the noisy signal and produces an estimated output signal:

y(n)=\sum_{k=0}^{M-1}h_kx(n-k)

Where:

- `y(n)` = filtered output signal  
- `h(k)` = filter coefficients  
- `M` = filter length  

The main objective of the Wiener Filter is to minimize the difference between the desired signal and the filtered output.

---

# 2. Wiener Filter Objective

The goal of Wiener filtering is to estimate a signal that is as close as possible to the desired output.

The estimation error is defined as:

e(n)=d(n)-y(n)

Where:

- `e(n)` = estimation error  
- `d(n)` = desired signal  
- `y(n)` = filtered signal  

To obtain the optimal filter, the mean square value of this error is minimized.

---

# 3. Minimum Mean Square Error (MMSE)

The Wiener Filter uses the **Minimum Mean Square Error (MMSE)** criterion to determine the best filter coefficients.

The mean square error is expressed as:

MMSE=\frac{1}{N}\sum_{n=0}^{N-1}(d(n)-y(n))^2

Where:

- `N` = number of signal samples  
- `d(n)` = desired signal  
- `y(n)` = filtered signal  

In this assignment, MMSE is used to measure how close the filtered output is to the desired signal. A smaller MMSE value indicates better filtering performance.

Although Wiener theory provides a matrix-based MMSE formula, the direct mean-square implementation was selected due to its simplicity and practical suitability for MIPS assembly programming.

---

# 4. Filter Length Selection

The Wiener filter length determines how many previous signal samples are used during filtering.

For this project:

```text
M = 4
```

The selection of `M = 4` was made after considering implementation complexity, debugging effort, and project timeline constraints.

Reasons for selecting `M = 4` include:

- Balanced tradeoff between performance and implementation difficulty
- Reduced complexity for Gaussian elimination
- Easier debugging in MIPS assembly
- Suitable for a 3-member team with a 4-day deadline

Thus, the Wiener filter coefficient vector becomes:

h=[h_0,h_1,h_2,h_3]

---

# 5. Autocorrelation

Autocorrelation measures the similarity between a signal and delayed versions of itself.

In Wiener filtering, autocorrelation is used to construct the autocorrelation matrix:

R_M

The autocorrelation function is defined as:

\gamma_{xx}(k)=\frac{1}{N-k}\sum_{n=k}^{N-1}x(n)x(n-k)

Where:

- `γxx(k)` = autocorrelation value at lag `k`
- `x(n)` = noisy input signal
- `N` = signal length

For this assignment:

```text
k = 0 to 3
```

The calculated autocorrelation values are used to construct a Toeplitz matrix.

---

# 6. Autocorrelation Matrix (Toeplitz Matrix)

The Wiener filter requires an autocorrelation matrix represented as:

R_M

For `M = 4`, the matrix structure becomes:

R_M=\begin{bmatrix}r(0)&r(1)&r(2)&r(3)\\r(1)&r(0)&r(1)&r(2)\\r(2)&r(1)&r(0)&r(1)\\r(3)&r(2)&r(1)&r(0)\end{bmatrix}

This matrix is called a **Toeplitz matrix**, meaning each diagonal contains identical values.

The matrix is constructed using autocorrelation values computed from the input signal.

---

# 7. Cross-Correlation

Cross-correlation measures the similarity between the desired signal and the input signal.

The cross-correlation vector is represented as:

\gamma_d

The equation is:

\gamma_{dx}(k)=\frac{1}{N-k}\sum_{n=k}^{N-1}d(n)x(n-k)

Where:

- `d(n)` = desired signal  
- `x(n)` = noisy signal  
- `γdx(k)` = cross-correlation value  

For `M = 4`, the vector becomes:

\gamma_d=\begin{bmatrix}\gamma(0)\\gamma(1)\\gamma(2)\\gamma(3)\end{bmatrix}

This vector represents the relationship between the desired signal and noisy input signal.

---

# 8. Wiener-Hopf Equation

The Wiener-Hopf equation is the mathematical foundation of the Wiener filter.

The equation is:

R_M h = \gamma_d

Where:

- `R_M` = autocorrelation matrix  
- `h` = Wiener filter coefficient vector  
- `γd` = cross-correlation vector  

The optimal filter coefficients are theoretically obtained by:

h_{opt}=R_M^{-1}\gamma_d

However, explicit matrix inversion is computationally expensive and difficult to implement in MIPS assembly.

Therefore, this project uses **Gaussian Elimination** to solve the system of equations.

---

# 9. Gaussian Elimination

Gaussian elimination is a mathematical method used to solve systems of linear equations.

Instead of calculating the inverse matrix, the system:

R_M h = \gamma_d

is transformed into an augmented matrix:

[R_M|\gamma_d]

The process consists of:

1. Pivot row normalization  
2. Row elimination  
3. Back substitution  

The final result is the optimized Wiener filter coefficients:

h=[h_0,h_1,h_2,h_3]

Gaussian elimination was selected because it is more feasible for MIPS implementation and avoids expensive matrix inversion operations.

---

# 10. Output Signal Generation

After obtaining the filter coefficients, the output signal is generated using:

y(n)=\sum_{k=0}^{M-1}h_kx(n-k)

The filter multiplies delayed input samples with optimized coefficients and sums the products to produce the filtered output.

Boundary checking is required when:

```text
n - k < 0
```

to avoid invalid memory access.

The resulting output sequence is stored in:

```text
output_signal
```

---

# 11. Implementation Overview

The overall Wiener filter implementation consists of the following stages:

1. Read input signal files  
2. Validate signal size  
3. Compute autocorrelation values  
4. Construct autocorrelation matrix `R_M`  
5. Compute cross-correlation vector `γd`  
6. Solve Wiener-Hopf equation using Gaussian elimination  
7. Generate output signal  
8. Compute MMSE  
9. Display result in terminal  
10. Write result to `output.txt`

---

# 12. Conclusion

The Wiener Filter is an effective signal estimation technique that minimizes the mean square error between a noisy input signal and the desired signal.

In this assignment, the Wiener filter is implemented using:

- Autocorrelation
- Cross-correlation
- Wiener-Hopf equation
- Gaussian elimination
- MMSE minimization

The implementation is optimized for MIPS assembly by using a manageable filter size (`M = 4`) and simplified MMSE computation while maintaining mathematical correctness.