# Demo Preparation Checklist
**Course:** Computer Architecture Lab (CO2008)  
**Assignment:** Filtering and Prediction Signal with Wiener Filter  

---

## Before Demo Day

- [ ] Verify MARS simulator is installed and working on the demo machine
- [ ] Copy all project files to a single folder accessible during the demo
- [ ] Run `Assignment_test.asm` in MARS at least once to confirm it works
- [ ] Have all 3 input files ready: `input.txt`, `input2.txt`, `input3.txt`
- [ ] Have the `desired.txt` file in the same folder as the `.asm` file
- [ ] Prepare a mismatch test file (e.g., a file with only 3 numbers) for the error case
- [ ] Print/have the final report available (PDF format)

---

## During Demo — Step-by-Step

### Step 1: Show the Source Code
- [ ] Open `Assignment_test.asm` in MARS
- [ ] Point out the `.data` section with all required variable labels:
  - `desired_signal`, `input_signal`, `optimize_coefficient`, `mmse`, `output_signal`
- [ ] Show the file names in the source (line ~79-81): `desired.txt`, `input.txt`, `output.txt`

### Step 2: Run Test Case 1
- [ ] Ensure `input.txt` contains: `3.2 2.8 5.9 -2.3 -0.3 -8.3 1.0 9.1 4.6 5.6`
- [ ] Ensure `desired.txt` contains: `0.0 3.6 4.6 2.3 -1.0 -2.3 -0.3 3.5 6.3 6.0`
- [ ] Assemble and run the program (F3 then F5, or Run → Assemble then Run → Go)
- [ ] Expected terminal output:
  ```
  Filtered output: 1.1 2.1 3.6 1.5 -0.6 -3.8 -2.3 3.4 6.4 5.3
  MMSE: 1.2
  ```
- [ ] Verify `output.txt` was created with the same content

### Step 3: Run Test Case 2
- [ ] Change `input_filename` to `"input2.txt"` in the source code (or rename `input2.txt` to `input.txt`)
- [ ] Reassemble and run
- [ ] Expected terminal output:
  ```
  Filtered output: -0.1 3.8 2.4 1.1 -0.3 0.2 0.7 1.4 3.7 6.1
  MMSE: 2.5
  ```

### Step 4: Run Test Case 3
- [ ] Change `input_filename` to `"input3.txt"` (or rename `input3.txt` to `input.txt`)
- [ ] Reassemble and run
- [ ] Expected terminal output:
  ```
  Filtered output: 0.5 3.1 5.6 3.1 -0.6 -1.3 0.2 3.5 5.7 5.0
  MMSE: 0.5
  ```

### Step 5: Run Error Case
- [ ] Create an input file with a different number of values than `desired.txt` (e.g., 3 values)
- [ ] Run the program
- [ ] Expected output: `Error: size not match`

---

## Key Questions the TA May Ask (Prepare Answers)

| Question | Key Points to Mention |
|----------|----------------------|
| "How does the Wiener filter work?" | It minimizes mean-squared error between desired and filtered signal using optimal coefficients solved via the Wiener-Hopf equation |
| "Why Gaussian elimination instead of matrix inverse?" | Direct inversion is O(M³) and harder to implement in MIPS; Gaussian elimination is numerically stable and equally correct |
| "What is MMSE?" | Mean Minimum Square Error = (1/N) × Σ(d(n) - y(n))², measures filter quality |
| "Explain the autocorrelation function" | Measures signal similarity at different time lags; used to build the Toeplitz matrix R_M |
| "How do you handle x(n-k) when n-k < 0?" | Zero-padded — if the index is negative, x(n-k) is treated as 0 |
| "What FPU instructions do you use?" | `l.s`, `s.s` for load/store; `add.s`, `sub.s`, `mul.s`, `div.s` for arithmetic; `cvt.s.w` for int→float |
| "How is the matrix stored?" | Flat row-major array; R_M[i][j] is at offset (i×M + j) × 4 bytes |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "File not found" error | Ensure `.txt` files are in the same directory as the `.asm` file. In MARS, set the working directory via Settings → Memory Configuration |
| Program hangs | Check if MARS is waiting for input; the program should not require console input |
| Wrong output values | Verify `desired.txt` content matches the expected values above |
| MARS shows errors during assembly | Check for typos; ensure all labels are correctly spelled |
