# Build and Execute a KuCoin API Request

Constructs an
[httr2::request](https://httr2.r-lib.org/reference/request.html),
optionally signs it, performs it via the supplied `.perform` function,
and parses the KuCoin JSON response. This is the single point through
which all KuCoin API calls flow.

## Usage

``` r
kucoin_build_request(
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
  timeout = 10,
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

  Named list; query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- body:

  Named list or NULL; request body. Default `NULL`.

- keys:

  List or NULL; API credentials. Default `NULL`.

- sign:

  Function or NULL; `function(req, keys, ctx)` returning a signed
  request, where `ctx` carries `method`, `path`, `body`, and
  `get_timestamp_ms`. Default `sign_request()` (adapted to that
  signature).

- parse_envelope:

  Function; `function(resp)` turning a response into data and raising on
  a KuCoin API error. Default `parse_kucoin_response()`.

- .perform:

  Function; the httr2 perform function. Default
  [`httr2::req_perform`](https://httr2.r-lib.org/reference/req_perform.html).

- .parser:

  Function; post-processing function applied to parsed `$data`. Default
  `identity`.

- is_async:

  Logical; whether `.perform` returns promises. Default `FALSE`.

- timeout:

  Numeric; request timeout in seconds. Default `10`.

- .get_timestamp_ms:

  Function or NULL; zero-argument function returning epoch milliseconds
  for HMAC signing. When `NULL` (default), uses the local UTC clock.
  Pass a custom function (e.g. one that fetches KuCoin server time) to
  avoid clock-drift issues.

## Value

Parsed and post-processed API response data, or a promise thereof.

## Details

It is KuCoin's specialisation of the connectcore request funnel: signing
and error-envelope detection are injected as the `sign` and
`parse_envelope` functions (the seams
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
overrides), and the body is sent as the exact raw JSON string that was
signed, so the HMAC signature matches byte-for-byte.

### Sync vs Async

The `.perform` argument controls execution mode:

- [`httr2::req_perform`](https://httr2.r-lib.org/reference/req_perform.html)
  (default): synchronous, returns an
  [httr2::response](https://httr2.r-lib.org/reference/response.html).

- [`httr2::req_perform_promise`](https://httr2.r-lib.org/reference/req_perform_promise.html):
  asynchronous, returns a
  [promises::promise](https://rstudio.github.io/promises/reference/promise.html).
