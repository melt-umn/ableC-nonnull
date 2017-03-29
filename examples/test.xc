#include <stdlib.h>
#include <stdio.h>

void * nonnull safe_malloc(size_t size)
{
    void *ret = malloc(size);
    if (ret == NULL) {
        fprintf(stderr, "malloc returned NULL\n");
        exit(255);
    }
    return (void * nonnull) ret;
}

int foo(int * nonnull p)
{
    return *p;
}

int main(void)
{
    int * nonnull p = safe_malloc(sizeof(int));
    return foo(p);
}

