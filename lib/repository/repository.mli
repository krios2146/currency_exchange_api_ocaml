module type DB = Caqti_lwt.CONNECTION

type currency = { id : int; code : string; full_name : string; sign : string }

type exchange_rate = {
  id : int;
  base_currency : currency;
  target_currency : currency;
  rate : float;
}

type error = Constraint_violation | Unknown_error

val find_all_currencies : (module DB) -> (currency list, error) result Lwt.t

val find_currency_by_code :
  string -> (module DB) -> (currency option, error) result Lwt.t

val save_currency :
  string -> string -> string -> (module DB) -> (currency, error) result Lwt.t

val find_all_exchange_rates :
  (module DB) -> (exchange_rate list, error) result Lwt.t

val find_exchange_rate_by_codes :
  string -> string -> (module DB) -> (exchange_rate option, error) result Lwt.t

val save_exchange_rate :
  int -> int -> float -> (module DB) -> (exchange_rate, error) result Lwt.t
