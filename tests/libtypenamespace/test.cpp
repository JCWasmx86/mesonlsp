#include "typenamespace.hpp"

#include <gtest/gtest.h>

TEST(TypeNamespaceTest, testLookupFunction) {
  auto tns = TypeNamespace();
  auto mustExist = tns.lookupFunction("shared_library");
  ASSERT_TRUE(mustExist.has_value());
  auto doesNotExist = tns.lookupFunction("sharedlibrary");
  ASSERT_FALSE(doesNotExist.has_value());
}

TEST(TypeNamespaceTest, testLookupMethod) {
  auto tns = TypeNamespace();
  auto mesonType = tns.types["meson"];
  auto mustExist = tns.lookupMethod("project_version", mesonType);
  ASSERT_TRUE(mustExist.has_value());
  auto doesNotExist = tns.lookupMethod("projectversion", mesonType);
  ASSERT_FALSE(doesNotExist.has_value());
}

TEST(TypeNamespaceTest, testLookupMethodWithInheritance) {
  auto tns = TypeNamespace();
  auto type = tns.types["target_machine"];
  auto mustExist = tns.lookupMethod("cpu", type);
  ASSERT_TRUE(mustExist.has_value());
  auto doesNotExist = tns.lookupMethod("cpu2", type);
  ASSERT_FALSE(doesNotExist.has_value());
}

TEST(TypeNamespaceTest, testLookupMethodByName) {
  auto tns = TypeNamespace();
  auto mustExist = tns.lookupMethod("get_linker_id");
  ASSERT_TRUE(mustExist.has_value());
  ASSERT_EQ("compiler.get_linker_id", mustExist->get()->id());
  auto doesNotExist = tns.lookupMethod("cpu2");
  ASSERT_FALSE(doesNotExist.has_value());
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
