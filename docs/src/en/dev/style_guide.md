# Rationale and Goals

As every Rust programmer knows, the language has many powerful features, and there are often
several patterns which can express the same idea. Also, as every professional programmer comes to
discover, code is almost always read far more than it is written.

Thus, we choose to use a consistent set of idioms throughout our code so that it is easier to read
and understand for both existing and new contributors.

## Unsafe and Platform-Dependent conditional compilation

### Avoid `unsafe` Rust

One of the main reasons to use Rust as an implementation language is its strong memory safety
guarantees; Almost all of these guarantees are voided by the use of `unsafe`. Thus, unless there is
an excellent reason and the use is discussed beforehand, it is unlikely CeresDB will accept patches
with `unsafe` code.

We may consider taking unsafe code given:

- performance benchmarks showing a _very_ compelling improvement
- a compelling explanation of why the same performance can not be achieved using `safe` code
- tests showing how it works safely across threads

### Avoid platform-specific conditional compilation `cfg`

We hope that CeresDB is usable across many different platforms and Operating systems, which means we
put a high value on standard Rust.

While some performance critical code may require architecture specific instructions, (e.g.
`AVX512`) most of the code should not.

## Errors

### All errors should follow the [SNAFU crate philosophy](https://docs.rs/snafu/0.6.10/snafu/guide/philosophy/index.html) and use SNAFU functionality

_Good_:

- Derives `Snafu` and `Debug` functionality
- Has a useful, end-user-friendly display message

```rust
#[derive(Snafu, Debug)]
pub enum Error {
    #[snafu(display(r#"Conversion needs at least one line of data"#))]
    NeedsAtLeastOneLine,
    // ...
}
```

_Bad_:

```rust
pub enum Error {
    NeedsAtLeastOneLine,
    // ...
```

### Use the `ensure!` macro to check a condition and return an error

_Good_:

- Reads more like an `assert!`
- Is more concise

```rust
ensure!(!self.schema_sample.is_empty(), NeedsAtLeastOneLine);
```

_Bad_:

```rust
if self.schema_sample.is_empty() {
    return Err(Error::NeedsAtLeastOneLine {});
}
```

### Errors should be defined in the module they are instantiated

_Good_:

- Groups related error conditions together most closely with the code that produces them
- Reduces the need to `match` on unrelated errors that would never happen

```rust
#[derive(Debug, Snafu)]
pub enum Error {
    #[snafu(display("Not implemented: {}", operation_name))]
    NotImplemented { operation_name: String }
}
// ...
ensure!(foo.is_implemented(), NotImplemented {
    operation_name: "foo",
}
```

_Bad_:

```rust
use crate::errors::NotImplemented;
// ...
ensure!(foo.is_implemented(), NotImplemented {
    operation_name: "foo",
}
```

### The `Result` type alias should be defined in each module

_Good_:

- Reduces repetition

```rust
pub type Result<T, E = Error> = std::result::Result<T, E>;
...
fn foo() -> Result<bool> { true }
```

_Bad_:

```rust
...
fn foo() -> Result<bool, Error> { true }
```

### `Err` variants should be returned with `fail()`

_Good_:

```rust
return NotImplemented {
    operation_name: "Parquet format conversion",
}.fail();
```

_Bad_:

```rust
return Err(Error::NotImplemented {
    operation_name: String::from("Parquet format conversion"),
});
```

### Use `context` to wrap underlying errors into module specific errors

_Good_:

- Reduces boilerplate

```rust
input_reader
    .read_to_string(&mut buf)
    .context(UnableToReadInput {
        input_filename,
    })?;
```

_Bad_:

```rust
input_reader
    .read_to_string(&mut buf)
    .map_err(|e| Error::UnableToReadInput {
        name: String::from(input_filename),
        source: e,
    })?;
```

_Hint for `Box<dyn::std::error::Error>` in Snafu_:

If your error contains a trait object (e.g. `Box<dyn std::error::Error + Send + Sync>`), in order
to use `context()` you need to wrap the error in a `Box`, and there is an `box_err` function to do this:

```rust
#[derive(Debug, Snafu)]
pub enum Error {

    #[snafu(display("gRPC planner got error listing partition keys: {}", source))]
    ListingPartitions {
        source: Box<dyn std::error::Error + Send + Sync>,
    },
}

...

use use common_util::error::BoxError;

  // Wrap error in a box prior to calling context()
database
  .partition_keys()
  .await
  .box_err()
  .context(ListingPartitions)?;
```

### Each error cause in a module should have a distinct `Error` enum variant

Specific error types are preferred over a generic error with a `message` or `kind` field.

_Good_:

- Makes it easier to track down the offending code based on a specific failure
- Reduces the size of the error enum (`String` is 3x 64-bit vs no space)
- Makes it easier to remove vestigial errors
- Is more concise

```rust
#[derive(Debug, Snafu)]
pub enum Error {
    #[snafu(display("Error writing remaining lines {}", source))]
    UnableToWriteGoodLines { source: IngestError },

    #[snafu(display("Error while closing the table writer {}", source))]
    UnableToCloseTableWriter { source: IngestError },
}

// ...

write_lines.context(UnableToWriteGoodLines)?;
close_writer.context(UnableToCloseTableWriter))?;
```

_Bad_:

```rust
pub enum Error {
    #[snafu(display("Error {}: {}", message, source))]
    WritingError {
        source: IngestError,
        message: String,
    },
}

write_lines.context(WritingError {
    message: String::from("Error while writing remaining lines"),
})?;
close_writer.context(WritingError {
    message: String::from("Error while closing the table writer"),
})?;
```

### Leaf error should contains backtrace

In order to make debugging easier, leaf errors in error chain should contains a backtrace.

```rust
// Error in module A
pub enum Error {
    #[snafu(display("This is a leaf error, source:{}.\nBacktrace:\n{}", source, backtrace))]
    LeftError {
        source: ErrorFromDependency,
        backtrace: Backtrace
    },
}

// Error in module B
pub enum Error {
    #[snafu(display("Another error, source:{}.\nBacktrace:\n{}", source, backtrace))]
    AnotherError {
        source: crate::A:Error,
    },
}
```

## Tests

### Don't return `Result` from test functions

At the time of this writing, if you return `Result` from test functions to use `?` in the test
function body and an `Err` value is returned, the test failure message is not particularly helpful.
Therefore, prefer not having a return type for test functions and instead using `expect` or
`unwrap` in test function bodies.

_Good_:

```rust
#[test]
fn google_cloud() {
    let config = Config::new();
    let integration = ObjectStore::new_google_cloud_storage(GoogleCloudStorage::new(
        config.service_account,
        config.bucket,
    ));

    put_get_delete_list(&integration).unwrap();
    list_with_delimiter(&integration).unwrap();
}
```

_Bad_:

```rust
type TestError = Box<dyn std::error::Error + Send + Sync + 'static>;
type Result<T, E = TestError> = std::result::Result<T, E>;

#[test]
fn google_cloud() -> Result<()> {
    let config = Config::new();
    let integration = ObjectStore::new_google_cloud_storage(GoogleCloudStorage::new(
        config.service_account,
        config.bucket,
    ));

    put_get_delete_list(&integration)?;
    list_with_delimiter(&integration)?;
    Ok(())
}
```

## Thanks

Initial version of this doc is forked from [influxdb_iox](https://github.com/influxdata/influxdb_iox/blob/main/docs/style_guide.md), thanks for their hard work.
