let () =
  Dream.run @@ Dream.logger
  @@ Dream.sql_pool "sqlite3:database.sqlite"
  @@ Dream.router
       [
         Dream.get "/currencies" Handlers.get_currencies;
         Dream.get "/currency/:code" Handlers.get_currency_by_code;
         Dream.post "/currencies" Handlers.add_currency;
         Dream.get "/exchangeRates" Handlers.not_implemented;
         Dream.get "/exchnageRate/:codes" Handlers.not_implemented;
         Dream.post "/exchangeRates" Handlers.not_implemented;
         Dream.patch "/exchnageRate/:codes" Handlers.not_implemented;
         Dream.get "/exchnage" Handlers.not_implemented;
       ]
