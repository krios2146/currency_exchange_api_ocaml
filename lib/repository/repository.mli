module type DB = Caqti_lwt.CONNECTION

type currency = { id : int; code : string; full_name : string; sign : string }
type error = Constraint_violation | Unknown_error

val find_all_currencies : (module DB) -> currency list Lwt.t
val find_currency_by_code : string -> (module DB) -> currency option Lwt.t

val save_currency :
  string -> string -> string -> (module DB) -> (currency, error) result Lwt.t
