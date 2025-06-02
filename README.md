

# joker

A gleam library for fetching jokes from the [JokeAPI] (https://sv443.net/jokeapi/v2) service.

This library provides a simple interface to retrieve jokes from the JokeAPI (v2.jokeapi.dev), with built-in error handling and type-safe JSON decoding. It supports fetching random jokes with detailed metadata including categories, content flags, and safety ratings.

## Features

- Fetch random jokes from any category
- Type-safe JSON decoding with comprehensive error handling
- Built-in content filtering flags (NSFW, political, religious, etc.)
- Proper HTTP client with user agent headers
- Structured error types for different failure scenarios

## Types

The library provides structured types for joke responses including:
- `JokeResponse`: Complete joke data with metadata
- `Flags`: Content filtering flags for safety and appropriateness
- `APIError`: Comprehensive error handling for network and parsing issues


[![Package Version](https://img.shields.io/hexpm/v/joker)](https://hex.pm/packages/joker)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/joker/)

```sh
gleam add joker@1
```
```gleam
import jokeapi/api

pub fn main() -> Nil {
  let joke = api.get_any()
  case joke {
    Ok(j) -> {
      api.display_joke(j)
    }
    Error(err) ->
      io.println(
        "Error fetching joke: "
        <> case err {
          api.DecodeError(reason) -> "Decode Error: " <> reason
          api.GenericError(reason) -> "Generic Error: " <> reason
          api.RequestError(reason) -> "Request Error: " <> reason
        },
      )
  }
}
```

Further documentation can be found at <https://hexdocs.pm/joker>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
