import gleam/dynamic/decode
import gleam/hackney
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam/uri

const base_url = "https://v2.jokeapi.dev/joke/"

/// Represents a joke response from the JokeAPI.
pub type JokeResponse {
  JokeResponse(
    id: Int,
    category: String,
    flags: Flags,
    safe: Bool,
    lang: String,
    type_: String,
    error: Bool,
  )
}

/// Represents the flags associated with a joke, indicating various sensitivities.
pub type Flags {
  Flags(
    nsfw: Bool,
    religious: Bool,
    political: Bool,
    racist: Bool,
    sexist: Bool,
    explicit: Bool,
  )
}

/// Represents errors that can occur while interacting with the JokeAPI.
/// This type encapsulates different error scenarios that can arise during
/// decoding or making requests to the API.
pub type APIError {
  DecodeError(reason: String)
  GenericError(reason: String)
  RequestError(reason: String)
}

/// Decodes the flags associated with a joke from the JokeAPI.
/// This function creates a decoder for the Flags type, which includes fields
/// for various sensitivities such as NSFW, religious, political, racist,
/// sexist, and explicit content. Each field is decoded as a boolean value.
fn flags_decoder() -> decode.Decoder(Flags) {
  use nsfw <- decode.field("nsfw", decode.bool)
  use religious <- decode.field("religious", decode.bool)
  use political <- decode.field("political", decode.bool)
  use racist <- decode.field("racist", decode.bool)
  use sexist <- decode.field("sexist", decode.bool)
  use explicit <- decode.field("explicit", decode.bool)
  decode.success(Flags(
    nsfw: nsfw,
    religious: religious,
    political: political,
    racist: racist,
    sexist: sexist,
    explicit: explicit,
  ))
}

/// Decodes a JSON string into a JokeResponse, handling potential decoding errors.
///
/// This function attempts to parse a JSON string and convert it into a JokeResponse
/// using a predefined decoder. It maps any JSON decoding errors to APIError variants.
///
/// # Arguments
/// - in: A JSON string representing a joke response
///
/// # Returns
/// A Result containing either a successfully decoded JokeResponse or an APIError
/// if decoding fails
pub fn api_decoder(in: String) -> Result(JokeResponse, APIError) {
  let to_apierror = fn(in: json.DecodeError) -> APIError {
    case in {
      json.UnexpectedEndOfInput -> DecodeError("Unexpected end of input")
      json.UnexpectedByte(b) -> DecodeError("Unexpected byte: " <> b)
      json.UnexpectedSequence(s) -> DecodeError("Unexpected sequence: " <> s)
      json.UnableToDecode(_) -> DecodeError("Unable to decode")
    }
  }

  let main_decoder = {
    use id <- decode.field("id", decode.int)
    use category <- decode.field("category", decode.string)
    use flags <- decode.field("flags", flags_decoder())
    use safe <- decode.field("safe", decode.bool)
    use lang <- decode.field("lang", decode.string)
    use type_ <- decode.field("type", decode.string)
    use error <- decode.field("error", decode.bool)
    decode.success(JokeResponse(
      id: id,
      category: category,
      flags: flags,
      safe: safe,
      lang: lang,
      type_: type_,
      error: error,
    ))
  }
  json.parse(in, main_decoder)
  |> result.map_error(to_apierror)
}

/// Converts a Hackney error into an APIError.
/// This function maps specific Hackney error types to corresponding APIError variants,
/// allowing for more meaningful error handling in the context of the JokeAPI.
fn hackney_error_to_apierror(in: hackney.Error) -> APIError {
  case in {
    hackney.InvalidUtf8Response -> RequestError("Received incompatible data")
    hackney.Other(_) -> RequestError("Generic error from Hackney")
  }
}

/// Retrieves a joke from the JokeAPI using the provided URI.
/// This function constructs an HTTP request to the JokeAPI,
/// sends the request, and decodes the response into a JokeResponse.
/// If any step fails, it returns an APIError.
fn fetch_joke(in: uri.Uri) -> Result(JokeResponse, APIError) {
  use request <- result.try(
    request.from_uri(in)
    |> result.map(request.set_header(_, "User-Agent", "Joker"))
    |> result.map_error(fn(_) { RequestError("Could not create request") }),
  )

  use response.Response(_, _, data) <- result.try(
    hackney.send(request)
    |> result.map_error(hackney_error_to_apierror),
  )

  api_decoder(data)
}

/// Fetches a random joke from the JokeAPI.
/// This function constructs a URI for the "Any" endpoint of the JokeAPI,
/// sends a request to that endpoint, and returns a JokeResponse.
pub fn get_any() -> Result(JokeResponse, APIError) {
  use uri <- result.try(
    uri.parse(base_url <> "Any")
    |> result.map_error(fn(_) { RequestError("Could not build URI") }),
  )
  fetch_joke(uri)
}

/// Fetches a joke in a specific category from the JokeAPI.
/// This function constructs a URI for the "Programming" endpoint of the JokeAPI,
/// sends a request to that endpoint, and returns a JokeResponse.
pub fn get_joke_from_category(
  category: String,
) -> Result(JokeResponse, APIError) {
  use uri <- result.try(
    uri.parse(base_url <> category)
    |> result.map_error(fn(_) { RequestError("Could not build URI") }),
  )
  fetch_joke(uri)
}

/// Displays a joke in a formatted manner.
pub fn display_joke(joke: JokeResponse) -> Nil {
  let header =
    "🎯 "
    <> string.uppercase(joke.category)
    <> " JOKE #"
    <> int.to_string(joke.id)
  io.println(header)
  display_metadata(joke.flags, joke.lang, joke.safe)
}

/// Displays metadata about the joke, including language and safety status.
fn display_metadata(flags: Flags, lang: String, safe: Bool) -> Nil {
  let safe_status = case safe {
    True -> "✅ Safe"
    False -> "⚠️  Not Safe"
  }
  io.println("🏷️  Language: " <> string.uppercase(lang) <> " | " <> safe_status)
  let active_flags = get_active_flags(flags)
  case list.is_empty(active_flags) {
    False -> io.println("🚩 Flags: " <> string.join(active_flags, ", "))
    True -> Nil
  }
}

/// Retrieves the active flags from a Flags type.
fn get_active_flags(flags: Flags) -> List(String) {
  []
  |> add_flag_if_active("NSFW", flags.nsfw)
  |> add_flag_if_active("Religious", flags.religious)
  |> add_flag_if_active("Political", flags.political)
  |> add_flag_if_active("Racist", flags.racist)
  |> add_flag_if_active("Sexist", flags.sexist)
  |> add_flag_if_active("Explicit", flags.explicit)
}

/// Adds a flag to the list of flags if the corresponding condition is active.
fn add_flag_if_active(
  flags: List(String),
  flag_name: String,
  is_active: Bool,
) -> List(String) {
  case is_active {
    True -> [flag_name, ..flags]
    False -> flags
  }
}
