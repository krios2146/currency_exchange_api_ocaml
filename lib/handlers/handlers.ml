open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Yojson.Safe

type message = { message : string } [@@deriving yojson]

type currency = { id : int; code : string; name : string; sign : string }
[@@deriving yojson]

type exchange_rate = {
  id : int;
  baseCurrency : currency;
  targetCurrency : currency;
  rate : float;
}
[@@deriving yojson]

let to_response_currency (c : Repository.currency) =
  { id = c.id; code = c.code; name = c.full_name; sign = c.sign }

let to_response_exchange_rate (er : Repository.exchange_rate) =
  {
    id = er.id;
    baseCurrency = to_response_currency er.base_currency;
    targetCurrency = to_response_currency er.target_currency;
    rate = er.rate;
  }

let json_header = ("Content-Type", "application/json")

let build_message_response message =
  { message } |> yojson_of_message |> to_string

let get_path_param_opt req param =
  try Some (Dream.param req param) with Not_found -> None

let is_possibly_valid_code code =
  let regexp = Str.regexp "^[A-Z][A-Z][A-Z]$" in
  Str.string_match regexp code 0

let is_possibly_valid_codes codes =
  let regexp = Str.regexp "^[A-Z][A-Z][A-Z][A-Z][A-Z][A-Z]$" in
  Str.string_match regexp codes 0

let respond_bad_request message =
  let message = build_message_response message in
  Dream.respond ~status:`Bad_Request ~headers:[ json_header ] message

let respond_not_found message =
  let message = build_message_response message in
  Dream.respond ~status:`Not_Found ~headers:[ json_header ] message

let respond_conflict message =
  let message = build_message_response message in
  Dream.respond ~status:`Conflict ~headers:[ json_header ] message

let respond_server_error message =
  let message = build_message_response message in
  Dream.respond ~status:`Internal_Server_Error ~headers:[ json_header ] message

let not_implemented _ =
  let message = build_message_response "This endpoint is not implemented yet" in
  Dream.respond ~status:`Not_Implemented ~headers:[ json_header ] message

let get_currencies req =
  let%lwt result = Dream.sql req Repository.find_all_currencies in
  match result with
  | Error _ -> respond_server_error "Server unable to process request"
  | Ok currencies ->
      currencies
      |> List.map to_response_currency
      |> List.map yojson_of_currency
      |> (fun currencies -> `List currencies)
      |> to_string
      |> fun currencies ->
      Dream.respond ~status:`OK ~headers:[ json_header ] currencies

let get_currency_by_code req =
  let code = get_path_param_opt req "code" in
  match code with
  | None -> respond_bad_request "Parameter code is missing"
  | Some code when not (is_possibly_valid_code code) ->
      respond_bad_request "Parameter code is invalid; Use ISO-4217 format"
  | Some code -> (
      let%lwt result = Dream.sql req (Repository.find_currency_by_code code) in
      match result with
      | Ok (Some currency) ->
          let currency =
            currency |> to_response_currency |> yojson_of_currency |> to_string
          in
          Dream.respond ~status:`OK ~headers:[ json_header ] currency
      | Ok None ->
          respond_not_found
            (Printf.sprintf "Currency with code: '%s' is not found" code)
      | Error _ -> respond_server_error "Server unable to process request")

let add_currency req =
  let%lwt form = Dream.form ~csrf:false req in
  match form with
  | `Ok [ ("code", code); ("name", _); ("sign", _) ]
    when not (is_possibly_valid_code code) ->
      respond_bad_request "Parameter code is invalid; Use ISO-4217 format"
  | `Ok [ ("code", code); ("name", name); ("sign", sign) ] -> (
      let%lwt result =
        Dream.sql req (Repository.save_currency code name sign)
      in
      match result with
      | Ok currency ->
          let saved_currency =
            currency |> to_response_currency |> yojson_of_currency |> to_string
          in
          Dream.respond ~status:`Created ~headers:[ json_header ] saved_currency
      | Error Constraint_violation ->
          respond_conflict "This currency already exists"
      | Error Unknown_error ->
          respond_server_error "Server unable to process request")
  | _ -> respond_bad_request "Unexpected / missing form values"

let get_exchange_rates req =
  let%lwt result = Dream.sql req Repository.find_all_exchange_rates in
  match result with
  | Error _ -> respond_server_error "Server unable to process request"
  | Ok exchange_rates ->
      exchange_rates
      |> List.map to_response_exchange_rate
      |> List.map yojson_of_exchange_rate
      |> (fun currencies -> `List currencies)
      |> to_string
      |> fun currencies ->
      Dream.respond ~status:`OK ~headers:[ json_header ] currencies

let get_exchange_rate_by_codes req =
  let codes = get_path_param_opt req "codes" in
  match codes with
  | None -> respond_bad_request "Parameter code is missing"
  | Some codes when not (is_possibly_valid_codes codes) ->
      respond_bad_request "Parameter codes is invalid; Use ISO-4217 format"
  | Some codes -> (
      let base_currency_code = String.sub codes 0 3 in
      let target_currency_code = String.sub codes 3 3 in
      let%lwt result =
        Dream.sql req
          (Repository.find_exchange_rate_by_codes base_currency_code
             target_currency_code)
      in
      match result with
      | Ok (Some exchange_rate) ->
          let currency =
            exchange_rate |> to_response_exchange_rate
            |> yojson_of_exchange_rate |> to_string
          in
          Dream.respond ~status:`OK ~headers:[ json_header ] currency
      | Ok None ->
          respond_not_found
            (Printf.sprintf
               "Exchange rate with codes: '%s' -> '%s' is not found"
               base_currency_code target_currency_code)
      | Error _ -> respond_server_error "Server unable to process request")
