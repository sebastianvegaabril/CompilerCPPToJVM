int main()
{
    int a = 10;
    int b = 5;
    bool eq = (a == b);  // Equal
    bool neq = (a != b); // Not equal
    bool lt = (a < b);   // Less than
    bool lte = (a <= b); // Less than or equal
    bool gt = (a > b);   // Greater than
    bool gte = (a >= b); // Greater than or equal
    // Ternary operator (?:) not implemented (ECond)
    if (neq)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}