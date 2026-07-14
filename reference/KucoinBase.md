# KucoinBase: Abstract Base Class for KuCoin API Clients

Provides shared infrastructure for all KuCoin R6 classes, including API
credential management, sync/async execution mode, timestamp source
configuration, and a standardised method for calling implementation
functions.

### Transport

This class is a thin KuCoin specialisation of
[connectcore::RestClient](https://dereckscompany.github.io/connectcore/reference/RestClient.html),
the shared transport base. Credential storage, the sync/async mode flag,
the server-time clock source, and the `is_async` / `time_source` active
bindings all live in `connectcore`; `KucoinBase` supplies the two
venue-specific seams — how KuCoin authenticates a request (`.sign()`,
which adds the header-based HMAC signature, encrypted passphrase, and
`KC-API-*` headers) and how it reports an error (`.parse_envelope()`,
which honours KuCoin's `code`/`data` envelope).

Unlike most connectors, KuCoin signs the *exact compact JSON request
body* and must send that same byte sequence on the wire. It still owns
no transport: the body is pre-serialised to compact JSON and routed
through the connectcore funnel via `body_format = "raw"` (byte-verbatim
— no NULL-pruning, no pretty-printing), and the `.sign()` seam reads
those exact bytes back off the request to compute the `KC-API-*` HMAC.

### Sync vs Async

The `async` parameter controls execution mode for all API methods:

- `async = FALSE` (default): methods return results directly
  (`data.table`, character, etc.).

- `async = TRUE`: methods return
  [promises::promise](https://rstudio.github.io/promises/reference/promise.html)
  objects that resolve to the same types.

When async, use
[`coro::async()`](https://coro.r-lib.org/reference/async.html) and
`await()` or
[`promises::then()`](https://rstudio.github.io/promises/reference/then.html)
to consume results. The `promises` package must be installed for async
mode (`Suggests` dependency).

### Timestamp Source

The `time_source` parameter controls which clock is used for HMAC
request signing:

- `"local"` (default): uses the local UTC clock.

- `"server"`: fetches the KuCoin server time via `GET /api/v1/timestamp`
  before each authenticated request. This is slower (one extra HTTP
  round trip) but ensures signing works even when the local clock is out
  of sync.

### Retries

`max_tries > 1` opts every GET this client makes — single requests and
paginated reads alike — into automatic retry on a transient failure
(HTTP 408/429/5xx or a dropped connection) with jittered backoff,
delegated to
[`connectcore::build_request()`](https://dereckscompany.github.io/connectcore/reference/build_request.html).
Retry is a hard **GET-only** carve-out: a non-idempotent verb (an order
`POST`, a cancel `DELETE`) is never auto-retried, so a resend can never
double-submit an order. Leave it at the default `1` for live trading —
there the trader layer is the single retry authority (it routes by typed
error class and manages cooldowns); raise it only for research and
backfill reads.

### Design

This class is not meant to be instantiated directly. Subclasses (e.g.,
[KucoinMarketData](https://dereckscompany.github.io/kucoin/reference/KucoinMarketData.md),
[KucoinTrading](https://dereckscompany.github.io/kucoin/reference/KucoinTrading.md))
inherit from it and define their own public methods that delegate to
`private$.request()` and `private$.paginate()`.

## Super class

[`connectcore::RestClient`](https://dereckscompany.github.io/connectcore/reference/RestClient.html)
-\> `KucoinBase`

## Methods

### Public methods

- [`KucoinBase$new()`](#method-KucoinBase-initialize)

- [`KucoinBase$clone()`](#method-KucoinBase-clone)

------------------------------------------------------------------------

### `KucoinBase$new()`

Initialise a KucoinBase Object

#### Usage

    KucoinBase$new(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE,
      time_source = c("local", "server"),
      max_tries = 1L
    )

#### Arguments

- `keys`:

  (list) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/kucoin/reference/get_api_keys.md).
  Defaults to
  [`get_api_keys()`](https://dereckscompany.github.io/kucoin/reference/get_api_keys.md).

- `base_url`:

  (scalar\<character\>) API base URL. Defaults to
  [`get_base_url()`](https://dereckscompany.github.io/kucoin/reference/get_base_url.md).

- `async`:

  (scalar\<logical\>) if `TRUE`, methods return promises. Default
  `FALSE`.

- `time_source`:

  (scalar\<character\>) clock source for HMAC request signing. `"local"`
  (default) uses the local UTC clock. `"server"` fetches the KuCoin
  server time before each authenticated request, which adds latency but
  avoids clock-drift issues.

- `max_tries`:

  (scalar\<integer in \[1, 10\]\>) for idempotent GET requests only,
  retry up to this many times on a transient failure. Default `1` (no
  retry). See the class **Retries** section for the write-safety
  carve-out and why live trading should leave this at `1`.

#### Returns

(class\<KucoinBase\>) invisibly, the new instance.

------------------------------------------------------------------------

### `KucoinBase$clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinBase$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Not instantiated directly; use subclasses:
market <- KucoinMarketData$new()          # sync
market_async <- KucoinMarketData$new(async = TRUE)  # async

# Use server time for HMAC signing (avoids clock-drift issues):
trading <- KucoinTrading$new(time_source = "server")
} # }
```
