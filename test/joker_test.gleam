import gleeunit
import gleeunit/should

import jokeapi/api

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`

/// Tests the decoding of a JokeResponse from a JSON string.
/// This function provides a well-formed JSON string representing a joke,
/// decodes it using the `api.api_decoder` function, and asserts that the
/// decoded values match the expected values.
pub fn decode_test() {
  let json =
    "
      {
        \"id\": 123,
        \"category\": \"Programming\",
        \"flags\": {
          \"nsfw\": false,
          \"religious\": false,
          \"political\": false,
          \"racist\": false,
          \"sexist\": false,
          \"explicit\": false
        },
        \"safe\": true,
        \"lang\": \"en\",
        \"type\": \"single\",
        \"setup\": \"Why do programmers prefer dark mode?\",
        \"delivery\": \"Because light attracts bugs.\",
        \"error\": false
      }
      "
  let result = api.api_decoder(json)
  case result {
    Ok(joke) -> {
      should.equal(joke.id, 123)
      should.equal(joke.category, "Programming")
      should.equal(joke.flags.nsfw, False)
      should.equal(joke.flags.religious, False)
      should.equal(joke.flags.political, False)
      should.equal(joke.flags.racist, False)
      should.equal(joke.flags.sexist, False)
      should.equal(joke.flags.explicit, False)
      should.equal(joke.safe, True)
      should.equal(joke.lang, "en")
      should.equal(joke.type_, "single")
      //should.equal(joke.setup, "Why do programmers prefer dark mode?")
      // should.equal(joke.delivery, "Because light attracts bugs.")
      should.equal(joke.error, False)
    }
    Error(err) -> {
      should.fail()
      // This should not happen in a well-formed test
      should.equal(err, api.DecodeError("Unexpected end of input"))
    }
  }
}
