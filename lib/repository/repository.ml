open Caqti_request.Infix

module type DB = Caqti_lwt.CONNECTION

type currency = { id : int; code : string; full_name : string; sign : string }
type error = Constraint_violation | Unknown_error

let currency_t =
  let encode c = Ok (c.id, c.code, c.full_name, c.sign) in
  let decode (id, code, full_name, sign) = Ok { id; code; full_name; sign } in
  Caqti_type.(t4 int string string string) |> Caqti_type.custom ~encode ~decode

let find_all_currencies =
  let query =
    (Caqti_type.unit ->* currency_t)
      "SELECT id, code, full_name, sign FROM Currencies"
  in
  fun (module Db : DB) ->
    let%lwt currencies = Db.collect_list query () in
    Lwt_result.lift (Result.map_error (fun _ -> Unknown_error) currencies)

let find_currency_by_code code =
  let query =
    (Caqti_type.string ->? currency_t)
      "SELECT id, code, full_name, sign FROM Currencies WHERE code = ?"
  in
  fun (module Db : DB) ->
    let%lwt optional_currency = Db.find_opt query code in
    Lwt_result.lift
      (Result.map_error (fun _ -> Unknown_error) optional_currency)

let save_currency code name sign =
  let query =
    (Caqti_type.(t3 string string string) ->! currency_t)
      "INSERT INTO Currencies (code, full_name, sign) VALUES (?, ?, ?) \
       RETURNING id, code, full_name, sign"
  in
  fun (module Db : DB) ->
    Dream.log "Code to insert: %s" code;
    let%lwt result = Db.find query (code, name, sign) in
    match result with
    | Ok currency -> Lwt_result.return currency
    (* Clearly skill issues with pattern matching here *)
    | Error (`Response_failed e) -> (
        match Caqti_error.cause (`Response_failed e) with
        | #Caqti_error.integrity_constraint_violation ->
            Lwt_result.fail Constraint_violation
        | _ -> Lwt_result.fail Unknown_error)
    | Error _ -> Lwt_result.fail Unknown_error
