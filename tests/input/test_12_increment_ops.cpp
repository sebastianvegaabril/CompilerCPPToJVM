int main()
{
    int x = 5;
    int pre_inc = ++x;  // Pre-increment
    int post_inc = x++; // Post-increment
    int pre_dec = --x;  // Pre-decrement
    int post_dec = x--; // Post-decrement
    return x + pre_inc + post_inc + pre_dec + post_dec;
}