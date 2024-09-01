open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type message = { message : string } [@@deriving yojson]

let hello_world _ =
  { message = "Hello, world!" }
  |> yojson_of_message |> Yojson.Safe.to_string |> Dream.json

let () = Dream.run @@ Dream.logger @@ Dream.router [ Dream.get "/" hello_world ]
