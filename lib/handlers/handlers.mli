val not_implemented : Dream.request -> Dream.response Lwt.t
val get_currencies : Dream.request -> Dream.response Lwt.t
val get_currency_by_code : Dream.request -> Dream.response Lwt.t
val add_currency : Dream.request -> Dream.response Lwt.t
val get_exchange_rates : Dream.request -> Dream.response Lwt.t
val get_exchange_rate_by_codes : Dream.request -> Dream.response Lwt.t
val add_exchange_rate : Dream.request -> Dream.response Lwt.t
