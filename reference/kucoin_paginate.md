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
  .get_timestamp_ms = NULL
)
```

## Arguments

- base_url:

  Character; the API base URL.

- endpoint:

  Character; the API path.

- method:

  Character; HTTP method. Default `"GET"`.

- query:

  Named list; initial query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- body:

  Named list or NULL; request body. Default `NULL`.

- keys:

  List or NULL; API credentials. Default `NULL`.

- sign:

  Function or NULL; the `.sign()` seam forwarded to
  [`kucoin_build_request()`](https://dereckscompany.github.io/kucoin/reference/kucoin_build_request.md).
  Default `NULL` (use KuCoin's own signer).

- parse_envelope:

  Function; the `.parse_envelope()` seam forwarded to
  [`kucoin_build_request()`](https://dereckscompany.github.io/kucoin/reference/kucoin_build_request.md).
  Default `parse_kucoin_response()`.

- .perform:

  Function; the httr2 perform function.

- .parser:

  Function; post-processing for the final accumulated result. Default
  `identity`.

- is_async:

  Logical; whether in async mode. Default `FALSE`.

- page_size:

  Integer; results per page. Default `50`.

- max_pages:

  Numeric; maximum pages to fetch. Default `Inf`.

- items_field:

  Character; name of the items field. Default `"items"`.

- timeout:

  Numeric; request timeout in seconds. Default `30`.

- .get_timestamp_ms:

  Function or NULL; custom timestamp provider for request signing. If
  `NULL`, uses the default internal timestamp function.

## Value

Parsed and post-processed result, or a promise thereof.
