# gleam-app

Consumes `zed-pkg-test/gleam-lib` via zed while Hex owns the rest of
`gleam.toml`.

Gleam has **no zed adapter** (the list is node/java/go/python/rust/dart), so
this is the universal path: `adapter = "none"`, the package lands in
`zed_modules/`, and the only machine-readable description of it is
`.zed/paths.json`. There is no `GLEAMPATH`-style override, so the `gleam.toml`
path dependency is written by hand.

Verified end to end with `zed 0.1.0`, `gleam 1.17.0`, OTP 29.

## License

MIT
