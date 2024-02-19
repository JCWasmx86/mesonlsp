#include "polyfill.hpp"

#include <array>
#include <atomic>
#include <functional>
#include <mutex>
#include <string>
#include <utility>
#include <uuid/uuid.h>

// See https://github.com/netdata/netdata/pull/10313
#ifndef UUID_STR_LEN
#define UUID_STR_LEN 37
#endif

enum class TaskState {
  PENDING,
  RUNNING,
  ENDED,
};

class Task {
private:
  std::string uuid;
  bool cancelled = false;
  std::mutex mtx;

  std::function<void()> taskFunction;

public:
  std::atomic<TaskState> state;

  explicit Task(std::function<void()> func) : taskFunction(std::move(func)) {
    uuid_t filename;
    uuid_generate(filename);
    std::array<char, UUID_STR_LEN + 1> out;
    uuid_unparse(filename, out.data());
    this->uuid = std::format("{}", out.data());
    this->state = TaskState::PENDING;
  }

  [[nodiscard]] std::string getUUID() const { return uuid; }

  void cancel() {
    std::scoped_lock const lock(mtx);
    cancelled = true;
  }

  [[nodiscard]] bool isCancelled() {
    std::scoped_lock const lock(mtx);
    return cancelled;
  }

  void run();
};
