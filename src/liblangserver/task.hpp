#include <array>
#include <atomic>
#include <format>
#include <functional>
#include <mutex>
#include <string>
#include <utility>
#include <uuid/uuid.h>

enum class TaskState {
  PENDING,
  RUNNING,
  ENDED,
};

class Task {
private:
  std::string uuid;
  bool cancelled;
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
    cancelled = false;
    this->state = TaskState::PENDING;
  }

  [[nodiscard]] std::string getUUID() const { return uuid; }

  void cancel() {
    std::lock_guard<std::mutex> const lock(mtx);
    cancelled = true;
  }

  [[nodiscard]] bool isCancelled() {
    std::lock_guard<std::mutex> const lock(mtx);
    return cancelled;
  }

  void run();
};
