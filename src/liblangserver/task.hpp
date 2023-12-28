#include <format>
#include <functional>
#include <mutex>
#include <string>
#include <utility>
#include <uuid/uuid.h>

enum TaskState {
  Pending,
  Running,
  Ended,
};

class Task {
private:
  std::string uuid;
  bool cancelled;
  std::mutex mtx;

  std::function<void()> taskFunction;

public:
  TaskState state;

  Task(std::function<void()> func) : taskFunction(std::move(func)) {
    uuid_t filename;
    uuid_generate(filename);
    char out[UUID_STR_LEN + 1] = {0};
    uuid_unparse(filename, out);
    this->uuid = std::format("{}", out);
    cancelled = false;
    this->state = TaskState::Pending;
  }

  std::string getUUID() const { return uuid; }

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
