# Currency Exchange API

[![OCaml](https://img.shields.io/badge/OCaml-black?style=for-the-badge&logo=ocaml)](https://ocaml.org/)
[![Dune](https://img.shields.io/badge/dune-black?style=for-the-badge)](https://github.com/ocaml/dune)
[![Dream](https://img.shields.io/badge/dream-black?style=for-the-badge)](https://aantron.github.io/dream/)
[![SQLite](https://img.shields.io/badge/sqlite-black?style=for-the-badge&logo=sqlite)](https://www.sqlite.org/)
[![Caqti](https://img.shields.io/badge/caqti-black?style=for-the-badge)](https://github.com/paurkedal/ocaml-caqti)

![GitHub License](https://img.shields.io/github/license/krios2146/currency_exchange_api_ocaml?style=flat-square&labelColor=black&color=black)

Simple REST API with currencies and exchange rates as resources and exchange of the currency as the main functionality

Created according to the technical specifications presented in [this course](https://zhukovsd.github.io/java-backend-learning-course/projects/currency-exchange)
## Run Locally

> [!IMPORTANT]  
> [OCaml](https://ocaml.org/install) and [Opam](https://opam.ocaml.org/) should be installed to run this project

Clone the project

```bash
git clone git@github.com:krios2146/currency_exchange_api_ocaml.git
```

Go to the project directory

```bash
cd currency_exchange_api_ocaml
```

Create opam switch for the project

```bash
opam switch create currency_exchange_api 5.2.0
```

Set the switch

```bash
opam switch set currency_exchange_api
```

Install dependencies

```bash
opam install . --deps-only --yes
```

Build and execute with dune

```bash
dune build && dune exec currency_exchange_api
```

## API Reference
> [!NOTE]  
> [Postman workspace](https://www.postman.com/krios2185/workspace/currency-exchange-workspace) for this project with reuqests examples

### Currencies

#### Get all currencies

```http
GET /currencies
```

#### Get currency by code

```http
GET /currency/:code
```

| Parameter | Type     | Description                                                                                  |
|:----------|:---------|:---------------------------------------------------------------------------------------------|
| `code`    | `string` | **Required**. Currency code in the [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217) format |

#### Add new currency

```http
POST /currencies
Content-Type: x-www-form-urlencoded
```

| Request | Type     | Description                                                                                  |
|:--------|:---------|:---------------------------------------------------------------------------------------------|
| `code`  | `string` | **Required**. Currency code in the [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217) format |
| `name`  | `string` | **Required**. Currency name                                                                  |
| `sign`  | `string` | **Required**. Currency sign                                                                  |

### Exchange Rates

#### Get all exchange rates

```http
GET /exchangeRates
```

#### Get exchange rate for currencies

```http
GET /exchangeRate/:codes
```

| Parameter | Type     | Description                                                                                                                                                                |
|:----------|:---------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `codes`   | `string` | **Required**. Currency codes in the [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217) format. E.g. for `USDEUR` parameter API will response with USD => EUR exchange rate |

#### Add new exchange rate

```http
POST /exchangeRates
Content-Type: x-www-form-urlencoded
```

| Request              | Type     | Description                                                                                         |
|:---------------------|:---------|:----------------------------------------------------------------------------------------------------|
| `baseCurrencyCode`   | `string` | **Required**. Base currency code in the [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217) format   |
| `targetCurrencyCode` | `string` | **Required**. Target currency code in the [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217) format |
| `rate`               | `float`  | **Required**. Exchange rate                                                                         |

#### Update exchange rate for currencies

```http
PATCH /exchangeRate/:codes
Content-Type: x-www-form-urlencoded
```

| Parameter/Request | Type     | Description                                                                                                                                                         |
|:------------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `codes`           | `string` | **Required**. Currency codes in the [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217) format. E.g. for `USDEUR` parameter API will update USD => EUR exchange rate |
| `rate`            | `float`  | **Required**. New exchange rate for currency pair                                                                                                                   |

### Currency exchange

```http
GET /exchange
```

| Query    | Type     | Description                                                                           |
|:---------|:---------|:--------------------------------------------------------------------------------------|
| `from`   | `string` | **Required**. Currency code in the [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217) |
| `to`     | `string` | **Required**. Currency code in the [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217) |
| `amount` | `float`  | **Required**. Amount to exchange                                                      |
