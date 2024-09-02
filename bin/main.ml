let () =
  Dream.run @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/currencies" Handlers.not_implemented;
         Dream.get "/currency/:code" Handlers.not_implemented;
         Dream.post "/currencies" Handlers.not_implemented;
         Dream.get "/exchangeRates" Handlers.not_implemented;
         Dream.get "/exchnageRate/:codes" Handlers.not_implemented;
         Dream.post "/exchangeRates" Handlers.not_implemented;
         Dream.patch "/exchnageRate/:codes" Handlers.not_implemented;
         Dream.get "/exchnage" Handlers.not_implemented;
       ]
