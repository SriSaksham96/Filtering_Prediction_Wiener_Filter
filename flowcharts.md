# Wiener Filter — Algorithm Flowcharts
**Course:** Computer Architecture Lab (CO2008)  
**Assignment:** Filtering and Prediction Signal with Wiener Filter  
**Role:** Member 1 — Math, Algorithm Design & System Architect  

---

# 1. Main Program Flow

```mermaid
flowchart TD
    A([START]) --> B["Read desired.txt → desired_signal"]
    B --> C["Read input.txt → input_signal"]
    C --> D{"desired_size == input_size?"}
    D -- No --> E["Print: Error: size not match"]
    E --> F([EXIT])
    D -- Yes --> G["Compute Autocorrelation γxx(k), k = 0..M-1"]
    G --> H["Build R_M Toeplitz Matrix (M × M)"]
    H --> I["Compute Cross-Correlation γdx(k), k = 0..M-1"]
    I --> J["Build Augmented Matrix [R_M | γd] (M × M+1)"]
    J --> K["Gaussian Elimination (Forward)"]
    K --> L["Back Substitution → optimize_coefficient"]
    L --> M["Generate Output Signal y(n), n = 0..N-1"]
    M --> N["Compute MMSE"]
    N --> O["Print results to terminal"]
    O --> P["Write results to output.txt"]
    P --> F
```

---

# 2. File Reading & Parsing Flow

```mermaid
flowchart TD
    A([START: read_signal_file]) --> B["Open file (syscall 13)"]
    B --> C{"File opened?"}
    C -- No --> D["Print: Error: could not open file"]
    D --> E(["RETURN -1"])
    C -- Yes --> F["Read file into buffer (syscall 14, max 511 bytes)"]
    F --> G["Null-terminate buffer"]
    G --> H["Close file (syscall 16)"]
    H --> I["Initialize: count = 0, pos = 0"]
    I --> J{"Current char?"}
    J -- "Null (end)" --> K(["RETURN count"])
    J -- "Whitespace (space/newline/tab)" --> L["Advance pos"]
    L --> J
    J -- "Digit or '-'" --> M{"char == '-' ?"}
    M -- Yes --> N["Set sign = -1, advance pos"]
    M -- No --> O["Set sign = +1"]
    N --> O
    O --> P["Parse integer part: accumulate digits"]
    P --> Q{"char == '.' ?"}
    Q -- No --> R["Store float = sign × integer_part"]
    Q -- Yes --> S["Advance past '.', read 1 fractional digit"]
    S --> T["Store float = sign × (integer_part + frac/10)"]
    R --> U["signal_array[count] = float"]
    T --> U
    U --> V["count = count + 1"]
    V --> J
```

---

# 3. Autocorrelation Flow

$$\gamma_{xx}(k) = \frac{1}{N-k} \sum_{n=k}^{N-1} x(n) \cdot x(n-k), \quad k = 0, 1, \ldots, M-1$$

```mermaid
flowchart TD
    A([START: compute_autocorrelation]) --> B["Load input_signal base address"]
    B --> C["lag = 0"]
    C --> D{"lag < M?"}
    D -- No --> E(["RETURN"])
    D -- Yes --> F["sum = 0.0"]
    F --> G["n = lag"]
    G --> H{"n < N?"}
    H -- No --> I["autocorrelation[lag] = sum / (N - lag)"]
    I --> J["lag = lag + 1"]
    J --> D
    H -- Yes --> K["Load x[n]"]
    K --> L["Load x[n - lag]"]
    L --> M["product = x[n] × x[n - lag]"]
    M --> N["sum = sum + product"]
    N --> O["n = n + 1"]
    O --> H
```

---

# 4. R_M Toeplitz Matrix Construction Flow

$$R_M[i][j] = \gamma_{xx}(|i - j|)$$

```mermaid
flowchart TD
    A([START: build_R_M]) --> B["Load autocorrelation base, R_M base"]
    B --> C["row = 0"]
    C --> D{"row < M?"}
    D -- No --> E(["RETURN"])
    D -- Yes --> F["col = 0"]
    F --> G{"col < M?"}
    G -- No --> H["row = row + 1"]
    H --> D
    G -- Yes --> I["lag = |row - col|"]
    I --> J["R_M[row × M + col] = autocorrelation[lag]"]
    J --> K["col = col + 1"]
    K --> G
```

---

# 5. Cross-Correlation Flow

$$\gamma_{dx}(k) = \frac{1}{N-k} \sum_{n=k}^{N-1} d(n) \cdot x(n-k), \quad k = 0, 1, \ldots, M-1$$

```mermaid
flowchart TD
    A([START: compute_cross_correlation]) --> B["Load desired_signal, input_signal bases"]
    B --> C["lag = 0"]
    C --> D{"lag < M?"}
    D -- No --> E(["RETURN"])
    D -- Yes --> F["sum = 0.0"]
    F --> G["n = lag"]
    G --> H{"n < N?"}
    H -- No --> I["gamma_d[lag] = sum / (N - lag)"]
    I --> J["lag = lag + 1"]
    J --> D
    H -- Yes --> K["Load d[n] (desired signal)"]
    K --> L["Load x[n - lag] (input signal)"]
    L --> M["product = d[n] × x[n - lag]"]
    M --> N["sum = sum + product"]
    N --> O["n = n + 1"]
    O --> H
```

---

# 6. Gaussian Elimination Flow (Forward Elimination)

Solves $R_M \mathbf{h} = \boldsymbol{\gamma}_d$ via augmented matrix $[R_M | \boldsymbol{\gamma}_d]$

```mermaid
flowchart TD
    A([START: gauss_eliminate]) --> B["Build augmented matrix (M × M+1)"]
    B --> C["pivot = 0"]
    C --> D{"pivot < M?"}
    D -- No --> E(["RETURN: upper-triangular form"])
    D -- Yes --> F["Find row ≥ pivot with max |A[row][pivot]| (partial pivoting)"]
    F --> G{"best_row ≠ pivot?"}
    G -- Yes --> H["Swap row[pivot] ↔ row[best_row] (columns pivot..M)"]
    G -- No --> I["Skip swap"]
    H --> I
    I --> J["pivot_val = A[pivot][pivot]"]
    J --> K["Normalize: A[pivot][c] = A[pivot][c] / pivot_val, for c = pivot..M"]
    K --> L["r = pivot + 1"]
    L --> M{"r < M?"}
    M -- No --> N["pivot = pivot + 1"]
    N --> D
    M -- Yes --> O["factor = A[r][pivot]"]
    O --> P["For c = pivot..M: A[r][c] = A[r][c] - factor × A[pivot][c]"]
    P --> Q["r = r + 1"]
    Q --> M
```

---

# 7. Back Substitution Flow

```mermaid
flowchart TD
    A([START: back_substitute]) --> B["row = M - 1"]
    B --> C{"row ≥ 0?"}
    C -- No --> D(["RETURN: optimize_coefficient[0..M-1] solved"])
    C -- Yes --> E["sum = A[row][M] (right-hand side)"]
    E --> F["c = row + 1"]
    F --> G{"c < M?"}
    G -- No --> H["optimize_coefficient[row] = sum"]
    H --> I["row = row - 1"]
    I --> C
    G -- Yes --> J["sum = sum - A[row][c] × optimize_coefficient[c]"]
    J --> K["c = c + 1"]
    K --> G
```

---

# 8. Output Signal Generation Flow

$$y(n) = \sum_{k=0}^{M-1} h_k \cdot x(n-k), \quad x(n-k) = 0 \text{ if } n-k < 0$$

```mermaid
flowchart TD
    A([START: generate_output_signal]) --> B["n = 0"]
    B --> C{"n < N?"}
    C -- No --> D(["RETURN"])
    C -- Yes --> E["accumulator = 0.0"]
    E --> F["k = 0"]
    F --> G{"k < M?"}
    G -- No --> H["output_signal[n] = accumulator"]
    H --> I["n = n + 1"]
    I --> C
    G -- Yes --> J{"n - k ≥ 0?"}
    J -- No --> K["Skip (zero-padded)"]
    J -- Yes --> L["product = h[k] × x[n - k]"]
    L --> M["accumulator = accumulator + product"]
    K --> N["k = k + 1"]
    M --> N
    N --> G
```

---

# 9. MMSE Calculation Flow

$$\text{MMSE} = \frac{1}{N} \sum_{n=0}^{N-1} \big(d(n) - y(n)\big)^2$$

```mermaid
flowchart TD
    A([START: compute_mmse]) --> B["sum = 0.0"]
    B --> C["n = 0"]
    C --> D{"n < N?"}
    D -- No --> E["mmse = sum / N"]
    E --> F["Store mmse"]
    F --> G(["RETURN"])
    D -- Yes --> H["error = d[n] - y[n]"]
    H --> I["squared_error = error × error"]
    I --> J["sum = sum + squared_error"]
    J --> K["n = n + 1"]
    K --> D
```

---

# 10. Output Formatting & File Writing Flow

```mermaid
flowchart TD
    A([START: output_routine]) --> B["Initialize output_buffer"]
    B --> C["Append 'Filtered output: '"]
    C --> D["n = 0"]
    D --> E{"n < N?"}
    E -- No --> F["Append newline + 'MMSE: '"]
    F --> G["Convert mmse → string (1 decimal place)"]
    G --> H["Append mmse string + newline"]
    H --> I["Print output_buffer to terminal (syscall 4)"]
    I --> J["Open output.txt for writing (syscall 13)"]
    J --> K["Write output_buffer to file (syscall 15)"]
    K --> L["Close file (syscall 16)"]
    L --> M(["RETURN"])
    E -- Yes --> N["Convert output_signal[n] → string (1 decimal place)"]
    N --> O{"n < N-1?"}
    O -- Yes --> P["Append space"]
    O -- No --> Q["No trailing space"]
    P --> R["n = n + 1"]
    Q --> R
    R --> E
```

---

# 11. Parameters Used

| Parameter | Value | Description |
|-----------|-------|-------------|
| M | 10 | Filter length (= signal length N) |
| N | 10 | Number of signal samples |
| R_M dimensions | 10 × 10 | Toeplitz autocorrelation matrix |
| Augmented matrix | 10 × 11 | [R_M \| γd] for Gaussian elimination |
| optimize_coefficient | 10 × 1 | Wiener filter coefficients h(0..9) |

---

*This document provides visual flowcharts for every algorithmic component of the Wiener filter MIPS implementation, suitable for inclusion in the final assignment report.*
