type currency = { id : int; code : string; full_name : string; sign : string }

val find_all_currencies : (module Caqti_lwt.CONNECTION) -> currency list Lwt.t
