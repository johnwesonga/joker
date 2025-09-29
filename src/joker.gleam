import gleam/io
import jokeapi/api

fn print_joke(
  result: Result(api.JokeResponse, api.APIError),
  error_prefix: String,
) {
  case result {
    Ok(j) -> api.display_joke(j)
    Error(err) -> {
      let error_message = case err {
        api.DecodeError(reason) -> "Decode Error: " <> reason
        api.GenericError(reason) -> "Generic Error: " <> reason
        api.RequestError(reason) -> "Request Error: " <> reason
      }
      io.println(error_prefix <> error_message)
    }
  }
}

pub fn main() {
  io.println("Hello from JokeAPI!")
  let joke = api.get_any()
  print_joke(joke, "Error fetching joke: ")

  io.println("Category Dark Joke:")
  let category_joke = api.get_joke_from_category("Dark")
  print_joke(category_joke, "Error fetching category joke: ")

  io.println("Goodbye from joker!")
}
