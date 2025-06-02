import gleam/io
import jokeapi/api

pub fn main() -> Nil {
  io.println("Hello from JokeAPI!")
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
  io.println("Category Joke")
  let category_joke = api.get_joke_from_category("Dark")
  case category_joke {
    Ok(j) -> {
      api.display_joke(j)
    }
    Error(err) ->
      io.println(
        "Error fetching category joke: "
        <> case err {
          api.DecodeError(reason) -> "Decode Error: " <> reason
          api.GenericError(reason) -> "Generic Error: " <> reason
          api.RequestError(reason) -> "Request Error: " <> reason
        },
      )
  }
  io.println("Goodbye from joker!")
}
