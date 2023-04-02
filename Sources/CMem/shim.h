#include <malloc.h>
#include <stdint.h>
#pragma once

static uint64_t
meminfo(void)
{
#if __GLIBC_MINOR__ >= 33
  struct mallinfo2 info = mallinfo2();
  return info.arena;
#else
  return 0;
#endif
}
