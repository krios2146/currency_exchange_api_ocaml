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

let is_possibly_valid_combined_codes codes =
  let regexp = Str.regexp "^[A-Z][A-Z][A-Z][A-Z][A-Z][A-Z]$" in
  Str.string_match regexp codes 0

let is_possibly_valid_codes code_1 code_2 =
  is_possibly_valid_code code_1 && is_possibly_valid_code code_2

let parse_rate rate = try Some (Float.of_string rate) with Failure _ -> None

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
  | Some codes when not (is_possibly_valid_combined_codes codes) ->
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

(* Skill issues here *)
let add_exchange_rate req =
  let%lwt form = Dream.form ~csrf:false req in
  match form with
  | `Ok
      [
        ("baseCurrencyCode", base_currency_code);
        ("rate", _);
        ("targetCurrencyCode", target_currency_code);
      ]
    when not (is_possibly_valid_codes base_currency_code target_currency_code)
    ->
      respond_bad_request
        "One of currency codes is invalid; Use ISO-4217 format"
  | `Ok
      [
        ("baseCurrencyCode", base_currency_code);
        ("rate", rate);
        ("targetCurrencyCode", target_currency_code);
      ] -> (
      let rate = parse_rate rate in
      match rate with
      | None -> respond_bad_request "Rate is invalid"
      | Some rate -> (
          let%lwt base_currency_result =
            Dream.sql req (Repository.find_currency_by_code base_currency_code)
          in
          let%lwt target_currency_result =
            Dream.sql req
              (Repository.find_currency_by_code target_currency_code)
          in
          match (base_currency_result, target_currency_result) with
          | Ok (Some _), Ok None ->
              respond_not_found
                (Printf.sprintf "Currency with code: '%s' is not found"
                   target_currency_code)
          | Ok None, Ok (Some _) ->
              respond_not_found
                (Printf.sprintf "Currency with code: '%s' is not found"
                   base_currency_code)
          | Ok None, Ok None ->
              respond_not_found
                (Printf.sprintf "Currencies with codes: '%s', '%s' is not found"
                   base_currency_code target_currency_code)
          | Error _, _ ->
              respond_server_error "Server unable to process request"
          | _, Error _ ->
              respond_server_error "Server unable to process request"
          | Ok (Some base_currency), Ok (Some target_currency) -> (
              let%lwt result =
                Dream.sql req
                  (Repository.save_exchange_rate base_currency.id
                     target_currency.id rate)
              in
              match result with
              | Ok er ->
                  let exchange_rate =
                    er |> to_response_exchange_rate |> yojson_of_exchange_rate
                    |> to_string
                  in
                  Dream.respond ~status:`Created ~headers:[ json_header ]
                    exchange_rate
              | Error Constraint_violation ->
                  respond_conflict "This exchange rate already exists"
              | Error _ ->
                  respond_server_error "Server unable to process request")))
  | _ -> respond_bad_request "Unexpected / missing form values"

let update_exchange_rate req =
  let codes = get_path_param_opt req "codes" in
  match codes with
  | None -> respond_bad_request "Parameter code is missing"
  | Some codes when not (is_possibly_valid_combined_codes codes) ->
      respond_bad_request "Parameter codes is invalid; Use ISO-4217 format"
  | Some codes -> (
      let%lwt form = Dream.form ~csrf:false req in
      match form with
      | `Ok [ ("rate", rate) ] -> (
          let rate = parse_rate rate in
          match rate with
          | None -> respond_bad_request "Rate is invalid"
          | Some rate -> (
              let base_currency_code = String.sub codes 0 3 in
              let target_currency_code = String.sub codes 3 3 in
              let%lwt result =
                Dream.sql req
                  (Repository.update_exchange_rate base_currency_code
                     target_currency_code rate)
              in
              match result with
              | Error _ ->
                  respond_server_error "Server unable to process request"
              | Ok er ->
                  let exchange_rate =
                    er |> to_response_exchange_rate |> yojson_of_exchange_rate
                    |> to_string
                  in
                  Dream.respond ~status:`OK ~headers:[ json_header ]
                    exchange_rate))
      | _ -> respond_bad_request "Request body field `rate` is missing")
