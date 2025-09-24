int main()
{
    bool a = true;
    bool b = false;
    bool and_result = a && b;
    bool or_result = a || b;
    // Negation operator (-) not implemented (ENeg)
    // Ternary operator (?:) not implemented (ECond)
    if (or_result)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}