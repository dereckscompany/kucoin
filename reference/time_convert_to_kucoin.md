# Convert POSIXct to KuCoin Timestamp

Converts a POSIXct object into a UNIX timestamp in the specified unit.

## Usage

``` r
time_convert_to_kucoin(datetime, unit = c("ms", "ns", "s"))
```

## Arguments

- datetime:

  POSIXct object to convert.

- unit:

  Character; output unit: `"ms"` (milliseconds, default), `"ns"`
  (nanoseconds), or `"s"` (seconds).

## Value

Numeric UNIX timestamp in the specified unit.

## Examples

``` r
if (FALSE) { # \dontrun{
dt <- lubridate::as_datetime("2023-10-31 16:00:00", tz = "UTC")
time_convert_to_kucoin(dt, unit = "ms")  # 1698777600000
time_convert_to_kucoin(dt, unit = "s")   # 1698777600
} # }
```
