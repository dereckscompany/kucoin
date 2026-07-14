# Paginate a KuCoin API Endpoint

Iteratively fetches pages from a paginated KuCoin endpoint. Aggregates
the items from each page into a list.

## Usage

``` r
kucoin_paginate(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  body = NULL,
  keys = NULL,
  sign = NULL,
  parse_envelope = parse_kucoin_response,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  page_size = 50,
  max_pages = Inf,
  items_field = "items",
  timeout = 30,
  .get_timestamp_ms = NULL,
  max_tries = 1L
)
```

## Arguments

- base_url:

  (scalar\<character\>) the API base URL.

- endpoint:

  (scalar\<character\>) the API path.

- method:

  (scalar\<character\>) HTTP method. Default `"GET"`.

- query:

  (list) initial query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- body:

  (list \| NULL) request body. Default `NULL`.

- keys:

  (list \| NULL) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/kucoin/reference/get_api_keys.md),
  or `NULL`:

  - api_key (character) the API key.

  - api_secret (character) the API secret.

  - api_passphrase (character) the API passphrase.

  - key_version (character) the API key version.

- sign:

  (function \| NULL) the `.sign()` seam forwarded to
  [`connectcore::build_request()`](https://dereckscompany.github.io/connectcore/reference/build_request.html).
  Default `NULL` (use KuCoin's own `kucoin_sign_req()` signer).

- parse_envelope:

  (function) the `.parse_envelope()` seam forwarded to
  [`connectcore::build_request()`](https://dereckscompany.github.io/connectcore/reference/build_request.html).
  Default `parse_kucoin_response()`.

- .perform:

  (function) the httr2 perform function.

- .parser:

  (function) post-processing for the final accumulated result. Default
  `identity`.

- is_async:

  (scalar\<logical\>) whether in async mode. Default `FALSE`.

- page_size:

  (scalar\<count in \[1, Inf\]\>) results per page. Default `50`.

- max_pages:

  (scalar\<numeric in \[1, Inf\]\>) maximum pages to fetch. Default
  `Inf`.

- items_field:

  (scalar\<character\>) name of the items field. Default `"items"`.

- timeout:

  (scalar\<numeric in \]0, Inf\[\>) request timeout in seconds. Default
  `30`.

- .get_timestamp_ms:

  (function \| NULL) custom timestamp provider for request signing. If
  `NULL`, uses the default internal timestamp function.

- max_tries:

  (scalar\<integer in \[1, 10\]\>) retry each page request up to this
  many times on a transient failure. Paginated endpoints are GETs, so
  [`connectcore::build_request()`](https://dereckscompany.github.io/connectcore/reference/build_request.html)
  applies the retry to every page. Default `1` (no retry).

## Value

(any \| promise\<any\>) parsed and post-processed result, or a promise
thereof.
