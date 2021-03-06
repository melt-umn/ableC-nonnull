struct complex_t {
    double re, im;
};

double foo(const struct complex_t * nonnull c)
{
    return c->re;
}

int main(void)
{
    struct complex_t c1;
    /* nonnull is inferred when using the addressOf operator */
    struct complex_t * nonnull c = &c1;
    double re = foo(c);
    return 0;
}

