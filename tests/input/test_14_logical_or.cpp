int main()
{
    bool a = true;
    bool b = false;
    bool result = a || b; // Should be true
    if (result)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}