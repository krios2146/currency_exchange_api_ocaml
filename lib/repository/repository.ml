module type DB = Caqti_lwt.CONNECTION

type currency = { id : int; code : string; full_name : string; sign : string }

let currency_t =
  let encode c = Ok (c.id, c.code, c.full_name, c.sign) in
  let decode (id, code, full_name, sign) = Ok { id; code; full_name; sign } in
  Caqti_type.(t4 int string string string) |> Caqti_type.custom ~encode ~decode

let find_all_currencies =
  let query =
    let open Caqti_request.Infix in
    (Caqti_type.unit ->* currency_t)
      "SELECT id, code, full_name, sign FROM Currencies"
  in
  fun (module Db : DB) ->
    let%lwt currencies_or_error = Db.collect_list query () in
    Caqti_lwt.or_fail currencies_or_error
