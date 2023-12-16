#pragma once

#include <optional>
#include <string>
#include <utility>
#include <vector>

class MesonOption {
public:
  std::string name;
  std::optional<std::string> description;
  bool deprecated = false;
  std::string type;

protected:
  MesonOption(std::string name, std::optional<std::string> description,
              bool deprecated, std::string type)
      : name(std::move(name)), description(std::move(description)),
        deprecated(deprecated), type(std::move(type)) {}
};

class StringOption : public MesonOption {
public:
  StringOption(std::string name,
               std::optional<std::string> description = std::nullopt,
               bool deprecated = false)
      : MesonOption(std::move(name), std::move(description), deprecated,
                    "string") {}
};

class IntOption : public MesonOption {
public:
  IntOption(std::string name,
            std::optional<std::string> description = std::nullopt,
            bool deprecated = false)
      : MesonOption(std::move(name), std::move(description), deprecated,
                    "integer") {}
};

class BoolOption : public MesonOption {
public:
  BoolOption(std::string name,
             std::optional<std::string> description = std::nullopt,
             bool deprecated = false)
      : MesonOption(std::move(name), std::move(description), deprecated,
                    "boolean") {}
};

class FeatureOption : public MesonOption {
public:
  FeatureOption(std::string name,
                std::optional<std::string> description = std::nullopt,
                bool deprecated = false)
      : MesonOption(std::move(name), std::move(description), deprecated,
                    "feature") {}
};

class ComboOption : public MesonOption {
public:
  std::vector<std::string> values;

  ComboOption(std::string name, std::vector<std::string> values,
              std::optional<std::string> description = std::nullopt,
              bool deprecated = false)
      : MesonOption(std::move(name), std::move(description), deprecated,
                    "combo"),
        values(std::move(values)) {}
};

class ArrayOption : public MesonOption {
public:
  std::vector<std::string> choices;

  ArrayOption(std::string name, std::vector<std::string> values,
              std::optional<std::string> description = std::nullopt,
              bool deprecated = false)
      : MesonOption(std::move(name), std::move(description), deprecated,
                    "array"),
        choices(std::move(values)) {}
};
