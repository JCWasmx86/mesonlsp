#include "task.hpp"

#include "log.hpp"

#include <exception>
#include <format>

const static Logger LOG("Task"); // NOLINT

void Task::run() {
  try {
    LOG.info("Running task " + this->uuid);
    this->state = TaskState::Running;
    this->taskFunction();
    if (this->cancelled) {
      LOG.info(std::format("Task {} was cancelled", this->uuid));
    } else {
      LOG.info(std::format("Task {} finished", this->uuid));
    }
  } catch (...) {
    auto currentException = std::current_exception();
    LOG.error(std::format("Caught exception in task {}", this->uuid));
  }
  this->state = TaskState::Ended;
}
