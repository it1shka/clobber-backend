pub inline fn getNeighbors(
    pivot_row: usize,
    pivot_column: usize,
    rows: usize,
    columns: usize,
) [4]?usize {
    return [_]?usize{
        if (pivot_row < rows - 1)
            (pivot_row + 1) * columns + (pivot_column)
        else
            null,

        if (pivot_column < columns - 1)
            (pivot_row) * columns + (pivot_column + 1)
        else
            null,

        if (pivot_row > 0)
            (pivot_row - 1) * columns + (pivot_column)
        else
            null,

        if (pivot_column > 0)
            (pivot_row) * columns + (pivot_column - 1)
        else
            null,
    };
}
