open Caqti_request.Infix
open Lwt.Infix

module type DB = Caqti_lwt.CONNECTION

type currency = { id : int; code : string; full_name : string; sign : string }

type exchange_rate = {
  id : int;
  base_currency : currency;
  target_currency : currency;
  rate : float;
}

type error = Constraint_violation | Unknown_error

let currency_t =
  let encode (c : currency) = Ok (c.id, c.code, c.full_name, c.sign) in
  let decode (id, code, full_name, sign) = Ok { id; code; full_name; sign } in
  Caqti_type.(t4 int string string string) |> Caqti_type.custom ~encode ~decode

let exchange_rate_t =
  let encode (er : exchange_rate) =
    Ok
      ( er.id,
        ( er.base_currency.id,
          er.base_currency.code,
          er.base_currency.full_name,
          er.base_currency.sign ),
        ( er.target_currency.id,
          er.target_currency.code,
          er.target_currency.full_name,
          er.target_currency.sign ),
        er.rate )
  in
  let decode
      ( id,
        (b_id, b_code, b_full_name, b_sign),
        (t_id, t_code, t_full_name, t_sign),
        rate ) =
    let base_currency =
      { id = b_id; code = b_code; full_name = b_full_name; sign = b_sign }
    in
    let target_currency =
      { id = t_id; code = t_code; full_name = t_full_name; sign = t_sign }
    in
    Ok { id; base_currency; target_currency; rate }
  in
  Caqti_type.(
    t4 int (t4 int string string string) (t4 int string string string) float)
  |> Caqti_type.custom ~encode ~decode

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

let find_all_exchange_rates =
  let query =
    (Caqti_type.unit ->* exchange_rate_t)
      "SELECT 
         e.id AS id, \
         b.id as b_id, b.code as b_code, b.full_name as b_full_name, b.sign as b_sign, \
         t.id as t_id, t.code as t_code, t.full_name as t_full_name, t.sign as t_sign, \
         e.rate as rate \
       FROM Exchange_rates e \
         JOIN Currencies b ON e.base_currency_id = b.id \
         JOIN Currencies t ON e.target_currency_id = t.id" [@ocamlformat "disable"]
  in
  fun (module Db : DB) ->
    let%lwt result = Db.collect_list query () in
    match result with
    | Ok currency -> Lwt_result.return currency
    | Error e ->
        Dream.log "Error: %s" (Caqti_error.show e);
        Lwt_result.fail Unknown_error

let find_exchange_rate_by_codes base_code target_code =
  let query =
    (Caqti_type.(t2 string string) ->? exchange_rate_t)
      "SELECT 
         e.id AS id, \
         b.id as b_id, b.code as b_code, b.full_name as b_full_name, b.sign as b_sign, \
         t.id as t_id, t.code as t_code, t.full_name as t_full_name, t.sign as t_sign, \
         e.rate as rate \
       FROM Exchange_rates e \
         JOIN Currencies b ON e.base_currency_id = b.id \
         JOIN Currencies t ON e.target_currency_id = t.id \
       WHERE \
         b.code = ? AND t.code = ?" [@ocamlformat "disable"]
  in
  fun (module Db : DB) ->
    let%lwt optional_exchange_rate =
      Db.find_opt query (base_code, target_code)
    in
    Lwt_result.lift
      (Result.map_error (fun _ -> Unknown_error) optional_exchange_rate)

let save_exchange_rate base_currency_id target_currency_id rate =
  let insert_query =
    (Caqti_type.(t3 int int float) ->! Caqti_type.int)
      "INSERT INTO Exchange_rates (base_currency_id, target_currency_id, rate) \
       VALUES (?, ?, ?) \
       RETURNING id" [@ocamlformat "disable"]
  in
  let select_query =
    (Caqti_type.int ->! exchange_rate_t)
      "SELECT 
         e.id AS id, \
         b.id as b_id, b.code as b_code, b.full_name as b_full_name, b.sign as b_sign, \
         t.id as t_id, t.code as t_code, t.full_name as t_full_name, t.sign as t_sign, \
         e.rate as rate \
       FROM Exchange_rates e \
         JOIN Currencies b ON e.base_currency_id = b.id \
         JOIN Currencies t ON e.target_currency_id = t.id \
       WHERE \
         e.id = ?" [@ocamlformat "disable"]
  in
  fun (module Db : DB) ->
    Db.start () >>= fun _ ->
    let insert_result =
      Db.find insert_query (base_currency_id, target_currency_id, rate)
    in
    let%lwt select_result =
      Lwt_result.bind insert_result (fun id -> Db.find select_query id)
    in
    match select_result with
    | Ok exchange_rate -> Lwt_result.return exchange_rate
    (* Clearly skill issues with pattern matching here *)
    | Error (`Response_failed e) -> (
        match Caqti_error.cause (`Response_failed e) with
        | #Caqti_error.integrity_constraint_violation ->
            Lwt_result.fail Constraint_violation
        | _ -> Lwt_result.fail Unknown_error)
    | Error _ -> Db.rollback () >>= fun _ -> Lwt_result.fail Unknown_error
