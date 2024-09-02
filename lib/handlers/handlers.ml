open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type message = { message : string } [@@deriving yojson]

let not_implemented _ =
  let message =
    { message = "This endpoint is not implemented yet" }
    |> yojson_of_message |> Yojson.Safe.to_string
  in
  Dream.respond ~status:`Not_Implemented
    ~headers:[ ("Content-Type", "application/json") ]
    message
