open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Lwt.Infix

type message = { message : string } [@@deriving yojson]

type currency = { id : int; code : string; name : string; sign : string }
[@@deriving yojson]

let to_response_currencies (c : Repository.currency) =
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
  >|= List.map to_response_currencies
  >|= List.map yojson_of_currency
  >|= (fun currencies -> `List currencies)
  >|= Yojson.Safe.to_string
  >>= fun currencies ->
  Dream.respond ~status:`OK ~headers:[ json_header ] currencies
