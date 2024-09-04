let () =
  Dream.run @@ Dream.logger
  @@ Dream.sql_pool "sqlite3:database.sqlite"
  @@ Dream.router
       [
         Dream.get "/currencies" Handlers.get_currencies;
         Dream.get "/currency/:code" Handlers.get_currency_by_code;
         Dream.post "/currencies" Handlers.add_currency;
         Dream.get "/exchangeRates" Handlers.get_exchange_rates;
         Dream.get "/exchangeRate/:codes" Handlers.get_exchange_rate_by_codes;
         Dream.post "/exchangeRates" Handlers.add_exchange_rate;
         Dream.patch "/exchangeRate/:codes" Handlers.update_exchange_rate;
         Dream.get "/exchange" Handlers.not_implemented;
       ]
