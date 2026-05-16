// Force-included compat shim: provides C++26 std::string + std::string_view
// concatenation (P2591) which libstdc++ 14 (Void Linux) does not yet ship.
#pragma once
#ifdef __cplusplus
#include <string>
#include <string_view>

[[maybe_unused]] inline std::string operator+(const std::string& a, std::string_view b) {
    std::string r;
    r.reserve(a.size() + b.size());
    r.append(a);
    r.append(b);
    return r;
}
[[maybe_unused]] inline std::string operator+(std::string_view a, const std::string& b) {
    std::string r;
    r.reserve(a.size() + b.size());
    r.append(a);
    r.append(b);
    return r;
}
#endif
