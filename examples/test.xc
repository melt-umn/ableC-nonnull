#include <stdlib.h>
#include <stdio.h>

int foo(int * nonnull p)
{
    /* if p were not qualified as nonnull then this would be a compile-time error */
    return *p;
}

int main(void)
{
    /* a runtime check will be inserted with this cast */
    int * nonnull p = (void * nonnull) malloc(sizeof(int));

//    while (true) {
//        foo(p);
//        p = NULL;
//    }

//    int **q = &p;
//    *q = NULL;

    return foo(p);
}

