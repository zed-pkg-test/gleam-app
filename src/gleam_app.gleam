import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/string
import mist.{type Connection, type ResponseData}
import rx
import rx/eager
import rx/flow
import rx/future
import rx/runtime

pub type PipelineEvent {
  Value(Int)
  Failed(String)
  Completed
}

pub fn main() -> Nil {
  let assert Ok(_) =
    handle_request
    |> mist.new
    |> mist.bind("127.0.0.1")
    |> mist.port(4100)
    |> mist.start

  process.sleep_forever()
}

fn handle_request(request: Request(Connection)) -> Response(ResponseData) {
  case request.path_segments(request) {
    ["health"] -> text_response(200, "ok")
    ["eager"] -> text_response(200, run_eager_pipeline())
    ["rx"] ->
      case run_pipeline() {
        Ok(body) -> text_response(200, body)
        Error(reason) -> text_response(500, reason)
      }
    _ -> text_response(404, "not found")
  }
}

fn run_eager_pipeline() -> String {
  let result: Result(List(Int), String) =
    eager.from_list([1, 2, 3, 4, 5])
    |> eager.map(fn(value) { value * 3 })
    |> eager.filter(fn(value) { value > 6 })
    |> eager.take(2)
    |> eager.to_result

  case result {
    Error(reason) -> "error:" <> reason
    Ok(values) -> values |> list.map(int.to_string) |> string.join(",")
  }
}

fn run_pipeline() -> Result(String, String) {
  let assert Ok(runtime_) = runtime.start()
  let events = process.new_subject()

  let stream =
    rx.from_list([1, 2, 3])
    |> flow.map_ordered(fn(value) { future.pure(value * 10) }, 2)

  case
    rx.subscribe(
      stream,
      runtime_,
      rx.observer(
        fn(value) { process.send(events, Value(value)) },
        fn(reason) { process.send(events, Failed(reason)) },
        fn() { process.send(events, Completed) },
      ),
    )
  {
    Error(_) -> {
      runtime.stop(runtime_)
      Error("subscription failed")
    }
    Ok(_) -> {
      let result = collect(events, [])
      runtime.stop(runtime_)
      result
    }
  }
}

fn collect(
  events: process.Subject(PipelineEvent),
  reversed: List(Int),
) -> Result(String, String) {
  case process.receive(from: events, within: 2000) {
    Error(Nil) -> Error("pipeline timeout")
    Ok(Failed(reason)) -> Error(reason)
    Ok(Value(value)) -> collect(events, [value, ..reversed])
    Ok(Completed) ->
      reversed
      |> list.reverse
      |> list.map(int.to_string)
      |> string.join(",")
      |> Ok
  }
}

fn text_response(status: Int, body: String) -> Response(ResponseData) {
  response.new(status)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}
