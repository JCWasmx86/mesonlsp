#include <malloc.h>
#include <stdint.h>
#pragma once

static uint64_t
meminfo(void)
{
  struct mallinfo2 info = mallinfo2();
  return info.arena;
}
