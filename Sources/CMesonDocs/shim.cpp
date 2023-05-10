__attribute__((visibility("default")))
extern "C"
const char *meson_docs_get_as_str(void)
{
	const char *s =
	#include "docs.json"
	;
	return s;
}

