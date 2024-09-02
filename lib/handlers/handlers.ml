open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Lwt.Infix
open Yojson.Safe

type message = { message : string } [@@deriving yojson]

type currency = { id : int; code : string; name : string; sign : string }
[@@deriving yojson]

let to_response_currency (c : Repository.currency) =
  { id = c.id; code = c.code; name = c.full_name; sign = c.sign }

let json_header = ("Content-Type", "application/json")

let build_message_response message =
  { message } |> yojson_of_message |> to_string

let get_path_param_opt req param =
  try Some (Dream.param req param) with Not_found -> None

let not_implemented _ =
  let message = build_message_response "This endpoint is not implemented yet" in
  Dream.respond ~status:`Not_Implemented ~headers:[ json_header ] message

let get_currencies req =
  Dream.sql req Repository.find_all_currencies
  >|= List.map to_response_currency
  >|= List.map yojson_of_currency
  >|= (fun currencies -> `List currencies)
  >|= to_string
  >>= fun currencies ->
  Dream.respond ~status:`OK ~headers:[ json_header ] currencies

let is_possibly_valid_code code =
  let regexp = Str.regexp "^[A-Z]{3}$" in
  Str.string_match regexp code 0

let get_currency_by_code req =
  let code = get_path_param_opt req "code" in
  match code with
  | None ->
      let message = build_message_response "Parameter code is missing" in
      Dream.respond ~status:`Bad_Request ~headers:[ json_header ] message
  | Some code when not (is_possibly_valid_code code) ->
      let message =
        build_message_response "Parameter code is invalid; Use ISO-4217 format"
      in
      Dream.respond ~status:`Bad_Request ~headers:[ json_header ] message
  | Some code -> (
      let%lwt currency =
        Dream.sql req (Repository.find_currency_by_code code)
      in
      match currency with
      | Some currency ->
          let currency =
            currency |> to_response_currency |> yojson_of_currency |> to_string
          in
          Dream.respond ~status:`OK ~headers:[ json_header ] currency
      | None ->
          let message =
            build_message_response
              (Printf.sprintf "Currency with code: '%s' is not found" code)
          in
          Dream.respond ~status:`Not_Found ~headers:[ json_header ] message)
