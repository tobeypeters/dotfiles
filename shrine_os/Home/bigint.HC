#define BIGINT_BASE 1000000000000000000
#define DIGITS_PER_BLOCK 18
#define INITIAL_CAPACITY 12

class BIGI64
{
  I64 *items;
  I64 count;
  I64 capacity;
};

U0 BigI64_init(BIGI64 *a)
{
  a->items=NULL;
  a->count=0;
  a->capacity=0;
}

ADocClear;
I64 ras=1;
I64 *I64ReMAlloc(I64 *a,I64 size=1)
{
  ras=size;
  I64 *res[ras];

  return res;
}

/*
// Helper functions for dynamic array operations
U0 da_append(Bigint *a, I64_titem) {
   if (a->count >= a->capacity) {
        a->capacity = a->capacity ? a->capacity * 2 : INITIAL_CAPACITY;
        a->items = realloc(a->items, a->capacity * sizeof(uint64_t));
       if (!a->items) {
            fprintf(stderr, "Memory allocation failed\n");
            exit(1);
        }
    }
    a->items[a->count++] =item;
}

U0 da_free(Bigint *a) {
    free(a->items);
    a->items = NULL;
    a->count = 0;
    a->capacity = 0;
}


U0 BigI64_from_uint64(Bigint *a, uint64_t n) {
    BigI64_init(a);
   if (n == 0) {
        da_append(a, 0);
    } else {
        da_append(a, n);
    }
}

U0 BigI64_print(const Bigint *a) {
   if (a->count == 0) {
        printf("0\n");
        return;
    }
    
    // Print most significant block without leading zeros
    printf("%"PRIu64, a->items[a->count - 1]);
    
    // Print remaining blocks with leading zeros
    for (i = a->count - 1;i-- > 0; ) {
        printf("%0*"PRIu64, DIGITS_PER_BLOCK, a->items[i]);
    }
    printf("\n");
}

U0 BigI64_add(Bigint *a, const Bigint *b) {
    uint64_t carry = 0;
     min_count = a->count < b->count ? a->count : b->count;
    
    // Add overlapping blocks
    for (i = 0;i < min_count; ++i) {
        uint64_t sum = a->items[i] + b->items[i] + carry;
        a->items[i] = sum % BIGINT_BASE;
        carry = sum / BIGINT_BASE;
    }
    
    // Handle remaining blocks from b (if bis longer)
   if (a->count < b->count) {
        for (i = a->count;i < b->count; ++i) {
            uint64_t sum = b->items[i] + carry;
            da_append(a, sum % BIGINT_BASE);
            carry = sum / BIGINT_BASE;
        }
    } 
    // Handle remaining blocks from a (if ais longer and carry propagates)
    elseif (a->count > b->count && carry) {
        for (i = min_count;i < a->count && carry; ++i) {
            uint64_t sum = a->items[i] + carry;
            a->items[i] = sum % BIGINT_BASE;
            carry = sum / BIGINT_BASE;
        }
    }
    
    // Add final carryif needed
   if (carry) {
        da_append(a, carry);
    }
}

U0 BigI64_copy(Bigint *dest, const Bigint *src) {
    dest->count = 0;
    for (i = 0;i < src->count; ++i) {
        da_append(dest, src->items[i]);
    }
}

U0 BigI64_free(Bigint *a) {
    da_free(a);
}

// Example usage
int main() {
    Bigint a, b;
    
    BigI64_init(&a);
    BigI64_init(&b);
    
    // Example: Add 123456789 to 987654321
    BigI64_from_uint64(&a, 123456789);
    BigI64_from_uint64(&b, 987654321);
    
    printf("a = ");
    BigI64_print(&a);
    printf("b = ");
    BigI64_print(&b);
    
    BigI64_add(&a, &b);
    printf("a + b = ");
    BigI64_print(&a);
    
    BigI64_free(&a);
    BigI64_free(&b);
    
    return 0;
}
*/







/*#define BIGINT_BASE 1000000000000000000
#define DIGITS_PER_BLOCK 18
#define INITIAL_CAPACITY 4

typedef struct {
    uint64_t *items;
    size_t count;
    size_t capacity;
} Bigint;

// Helper functions for dynamic array operations
static void da_append(Bigint *a, uint64_t item) {
    if (a->count >= a->capacity) {
        a->capacity = a->capacity ? a->capacity * 2 : INITIAL_CAPACITY;
        a->items = realloc(a->items, a->capacity * sizeof(uint64_t));
        if (!a->items) {
            fprintf(stderr, "Memory allocation failed\n");
            exit(1);
        }
    }
    a->items[a->count++] = item;
}

static void da_free(Bigint *a) {
    free(a->items);
    a->items = NULL;
    a->count = 0;
    a->capacity = 0;
}

void bigint_init(Bigint *a) {
    a->items = NULL;
    a->count = 0;
    a->capacity = 0;
}

void bigint_from_uint64(Bigint *a, uint64_t n) {
    bigint_init(a);
    if (n == 0) {
        da_append(a, 0);
    } else {
        da_append(a, n);
    }
}

void bigint_print(const Bigint *a) {
    if (a->count == 0) {
        printf("0\n");
        return;
    }
    
    // Print most significant block without leading zeros
    printf("%"PRIu64, a->items[a->count - 1]);
    
    // Print remaining blocks with leading zeros
    for (size_t i = a->count - 1; i-- > 0; ) {
        printf("%0*"PRIu64, DIGITS_PER_BLOCK, a->items[i]);
    }
    printf("\n");
}

void bigint_add(Bigint *a, const Bigint *b) {
    uint64_t carry = 0;
    size_t min_count = a->count < b->count ? a->count : b->count;
    
    // Add overlapping blocks
    for (size_t i = 0; i < min_count; ++i) {
        uint64_t sum = a->items[i] + b->items[i] + carry;
        a->items[i] = sum % BIGINT_BASE;
        carry = sum / BIGINT_BASE;
    }
    
    // Handle remaining blocks from b (if b is longer)
    if (a->count < b->count) {
        for (size_t i = a->count; i < b->count; ++i) {
            uint64_t sum = b->items[i] + carry;
            da_append(a, sum % BIGINT_BASE);
            carry = sum / BIGINT_BASE;
        }
    } 
    // Handle remaining blocks from a (if a is longer and carry propagates)
    else if (a->count > b->count && carry) {
        for (size_t i = min_count; i < a->count && carry; ++i) {
            uint64_t sum = a->items[i] + carry;
            a->items[i] = sum % BIGINT_BASE;
            carry = sum / BIGINT_BASE;
        }
    }
    
    // Add final carry if needed
    if (carry) {
        da_append(a, carry);
    }
}

void bigint_copy(Bigint *dest, const Bigint *src) {
    dest->count = 0;
    for (size_t i = 0; i < src->count; ++i) {
        da_append(dest, src->items[i]);
    }
}

void bigint_free(Bigint *a) {
    da_free(a);
}

// Example usage
int main() {
    Bigint a, b;
    
    bigint_init(&a);
    bigint_init(&b);
    
    // Example: Add 123456789 to 987654321
    bigint_from_uint64(&a, 123456789);
    bigint_from_uint64(&b, 987654321);
    
    printf("a = ");
    bigint_print(&a);
    printf("b = ");
    bigint_print(&b);
    
    bigint_add(&a, &b);
    printf("a + b = ");
    bigint_print(&a);
    
    bigint_free(&a);
    bigint_free(&b);
    
    return 0;
}
*/