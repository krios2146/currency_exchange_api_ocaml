open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Lwt.Infix

type message = { message : string } [@@deriving yojson]

type currency = { id : int; code : string; name : string; sign : string }
[@@deriving yojson]

let to_response_currency (c : Repository.currency) =
  { id = c.id; code = c.code; name = c.full_name; sign = c.sign }

let json_header = ("Content-Type", "application/json")

let not_implemented _ =
  let message =
    { message = "This endpoint is not implemented yet" }
    |> yojson_of_message |> Yojson.Safe.to_string
  in
  Dream.respond ~status:`Not_Implemented ~headers:[ json_header ] message

let get_currencies req =
  Dream.sql req Repository.find_all_currencies
  >|= List.map to_response_currency
  >|= List.map yojson_of_currency
  >|= (fun currencies -> `List currencies)
  >|= Yojson.Safe.to_string
  >>= fun currencies ->
  Dream.respond ~status:`OK ~headers:[ json_header ] currencies

let get_currency_by_code req =
  try
    let code = Dream.param req "code" in
    let%lwt currency = Dream.sql req (Repository.find_currency_by_code code) in
    match currency with
    | Some currency ->
        let currency =
          currency |> to_response_currency |> yojson_of_currency
          |> Yojson.Safe.to_string
        in
        Dream.respond ~status:`OK ~headers:[ json_header ] currency
    | None ->
        let message =
          {
            message = Printf.sprintf "Currency with '%s' code is not found" code;
          }
          |> yojson_of_message |> Yojson.Safe.to_string
        in
        Dream.respond ~status:`Not_Found ~headers:[ json_header ] message
  with Not_found ->
    let message =
      { message = "Parameter code is missing" }
      |> yojson_of_message |> Yojson.Safe.to_string
    in
    Dream.respond ~status:`Bad_Request ~headers:[ json_header ] message
