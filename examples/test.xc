#include <stdlib.h>

int foo(int * nonnull p)
{
    return *p;
}


int main(void)
{
    int * nonnull p;
    return foo(p);
}

