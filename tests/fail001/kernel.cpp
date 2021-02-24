#include "kernel.hpp"

void kernel(int a, int b, int* c) {
 //*c = a + b;
  *((int*)0) = a;
}
