#pragma once

#include "nix/util/error.hh"
#include "nix/util/forwarding-source-accessor.hh"

#include <cerrno>
#include <fcntl.h>
#include <mutex>
#include <nlohmann/json.hpp>
#include <unistd.h>
#include <unordered_set>

namespace nix {

// Trace successful evaluator accesses after the cache and before access control
// Use materialized sources (--no-lazy-trees) so every input has a physical path
struct InputTraceAccessor : ForwardingSourceAccessor {
    int output;
    std::mutex mutex;
    std::unordered_set<std::string> recorded;

    InputTraceAccessor(ref<SourceAccessor> next, const std::string &log)
        : ForwardingSourceAccessor(next),
          output(::open(log.c_str(), O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC,
                        0600)) {
        if (output == -1)
            throw SysError("opening input access trace '%s'", log);
        provenance = next->provenance;
    }

    ~InputTraceAccessor() override { ::close(output); }

    void record(const char *operation, const CanonPath &path) {
        auto physical = next->getPhysicalPath(path);
        std::string line =
            nlohmann::json{{"op", operation},
                           {"path", physical ? physical->string() : path.abs()},
                           {"virtual", !physical}}
                .dump() +
            "\n";
        std::lock_guard lock(mutex);
        if (!recorded.insert(line).second)
            return;
        size_t offset = 0;
        while (offset < line.size()) {
            auto count =
                ::write(output, line.data() + offset, line.size() - offset);
            if (count < 0) {
                if (errno == EINTR)
                    continue;
                throw SysError("writing input access trace");
            }
            if (count == 0)
                throw Error("input access trace write made no progress");
            offset += count;
        }
    }

    void readFile(const CanonPath &path, Sink &sink,
                  fun<void(uint64_t)> sizeCallback) override {
        next->readFile(path, sink, sizeCallback);
        record("read", path);
    }

    std::optional<Stat> maybeLstat(const CanonPath &path) override {
        auto result = next->maybeLstat(path);
        if (result)
            record("stat", path);
        return result;
    }

    DirEntries readDirectory(const CanonPath &path) override {
        auto result = next->readDirectory(path);
        record("list", path);
        return result;
    }

    std::string readLink(const CanonPath &path) override {
        auto result = next->readLink(path);
        record("link", path);
        return result;
    }

    std::shared_ptr<const Provenance>
    getProvenance(const CanonPath &path) override {
        return next->getProvenance(path);
    }
};

} // namespace nix
