#include <lang/fmt.h>
#include <stdio.h>

bool muon_fmt(struct source *src, FILE *out, const char *cfg_path, bool check_only, bool editorconfig)
{
  return fmt(src, out, cfg_path, check_only, editorconfig);
}
