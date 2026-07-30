import gleam/io
import zed_pkg_test_gleam_lib

/// The zed-sourced dependency resolves through an ordinary gleam.toml path
/// entry; zed's contribution is putting the source there and recording what it
/// is in .zed/paths.json.
pub fn main() {
  let msg = zed_pkg_test_gleam_lib.greet("gleam-app")
  io.println(msg)
  case zed_pkg_test_gleam_lib.language {
    "gleam" -> io.println("OK: zed-sourced dep resolved alongside Hex")
    other -> {
      io.println("FAIL: expected the gleam slice, got " <> other)
      panic as "zed-sourced dependency did not resolve"
    }
  }
}
