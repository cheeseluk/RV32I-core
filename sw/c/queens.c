// Recursive N-queens: count every solution for N = 1..8 and check the
// counts against the known answers. main returns 0 for PASS, or the N
// whose count was wrong.
//
// Exercises recursion on the stack, globals in .bss (zeroed by crt0.S),
// and a variable multiply: RV32I has no mul, so gcc calls __mulsi3 from libgcc.

#define N 8

static int col[N], diag1[2 * N - 1], diag2[2 * N - 1];
static int board[N];
static unsigned checksum;   // not checked here; the trace diff checks every step

static int solve(int row, int n) {
    if (row == n) {
        for (int r = 0; r < n; r++)
            checksum = checksum * (unsigned)(board[r] + r + 3) + board[r];
        return 1;
    }
    int count = 0;
    for (int c = 0; c < n; c++) {
        if (col[c] || diag1[row + c] || diag2[row - c + n - 1])
            continue;
        col[c] = diag1[row + c] = diag2[row - c + n - 1] = 1;
        board[row] = c;
        count += solve(row + 1, n);
        col[c] = diag1[row + c] = diag2[row - c + n - 1] = 0;
    }
    return count;
}

int main(void) {
    static const int expected[N + 1] = {1, 1, 0, 0, 2, 10, 4, 40, 92};
    for (int n = 1; n <= N; n++)
        if (solve(0, n) != expected[n])
            return n;
    return 0;
}
