(lang dune 3.16)

(name currency_exchange_api_ocaml)

(generate_opam_files true)

(source
 (github krios2146/currency_exchange_api_ocaml))

(authors "Vladimir Kidyaev")

(maintainers "Vladimir Kidyaev")

(license "Apache-2.0")

(documentation https://github.com/krios2146/currency_exchange_api_ocaml)

(package
 (name currency_exchange_api_ocaml)
 (synopsis "Currency exchanging REST API")
 (depends dune yojson dream ppx_yojson_conv caqti-driver-sqlite3))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
