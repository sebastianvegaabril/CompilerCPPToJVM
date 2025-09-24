int main()
{
    int x = 5;
    {
        int y = 10;
        x = x + y;
    }
    return x; // Should be 15
}