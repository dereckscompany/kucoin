# KucoinBase: Abstract Base Class for KuCoin API Clients

KucoinBase: Abstract Base Class for KuCoin API Clients

KucoinBase: Abstract Base Class for KuCoin API Clients

## Details

Provides shared infrastructure for all KuCoin R6 classes, including API
credential management, sync/async execution mode, timestamp source
configuration, and a standardised method for calling implementation
functions.

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

- `"local"` (default): uses
  [`lubridate::now()`](https://lubridate.tidyverse.org/reference/now.html)
  from the local machine.

- `"server"`: fetches the KuCoin server time via `GET /api/v1/timestamp`
  before each authenticated request. This is slower (one extra HTTP
  round trip) but ensures signing works even when the local clock is out
  of sync.

### Design

This class is not meant to be instantiated directly. Subclasses (e.g.,
[KucoinMarketData](https://dereckmezquita.github.io/kucoin/reference/KucoinMarketData.md),
[KucoinTrading](https://dereckmezquita.github.io/kucoin/reference/KucoinTrading.md))
inherit from it and define their own public methods that delegate to
`private$.request()` and `private$.paginate()`.

## Fields

All fields are private:

- `.keys`: List; API credentials from
  [`get_api_keys()`](https://dereckmezquita.github.io/kucoin/reference/get_api_keys.md).

- `.base_url`: Character; API base URL from
  [`get_base_url()`](https://dereckmezquita.github.io/kucoin/reference/get_base_url.md).

- `.perform`: Function; either
  [httr2::req_perform](https://httr2.r-lib.org/reference/req_perform.html)
  or
  [httr2::req_perform_promise](https://httr2.r-lib.org/reference/req_perform_promise.html).

- `.is_async`: Logical; whether the instance is in async mode.

- `.time_source`: Character; `"local"` or `"server"`.

- `.get_timestamp_ms`: Function; returns epoch milliseconds for HMAC
  signing.

## Active bindings

- `is_async`:

  Logical; read-only flag indicating whether this instance operates in
  async mode.

- `time_source`:

  Character; read-only flag indicating the timestamp source used for
  HMAC signing (`"local"` or `"server"`).

## Methods

### Public methods

- [`KucoinBase$new()`](#method-KucoinBase-new)

- [`KucoinBase$clone()`](#method-KucoinBase-clone)

------------------------------------------------------------------------

### Method `new()`

Initialise a KucoinBase Object

#### Usage

    KucoinBase$new(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    )

#### Arguments

- `keys`:

  List; API credentials from
  [`get_api_keys()`](https://dereckmezquita.github.io/kucoin/reference/get_api_keys.md).
  Defaults to
  [`get_api_keys()`](https://dereckmezquita.github.io/kucoin/reference/get_api_keys.md).

- `base_url`:

  Character; API base URL. Defaults to
  [`get_base_url()`](https://dereckmezquita.github.io/kucoin/reference/get_base_url.md).

- `async`:

  Logical; if `TRUE`, methods return promises. Default `FALSE`.

- `time_source`:

  Character; clock source for HMAC request signing. `"local"` (default)
  uses
  [`lubridate::now()`](https://lubridate.tidyverse.org/reference/now.html).
  `"server"` fetches the KuCoin server time before each authenticated
  request, which adds latency but avoids clock-drift issues.

#### Returns

Invisible self.

------------------------------------------------------------------------

### Method `clone()`

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
