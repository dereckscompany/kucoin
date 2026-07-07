# Convert POSIXct to KuCoin Timestamp

Converts a POSIXct object into a UNIX timestamp in the specified unit.

## Usage

``` r
time_convert_to_kucoin(datetime, unit = c("ms", "ns", "s"))
```

## Arguments

- datetime:

  (class\<POSIXct\>) the object to convert.

- unit:

  (scalar\<character in c("ms", "ns", "s")\>) output unit: `"ms"`
  (milliseconds, default), `"ns"` (nanoseconds), or `"s"` (seconds).

## Value

(scalar\<numeric\> \| scalar\<integer\>) UNIX timestamp in the specified
unit (`numeric` for `"ms"`/`"ns"`, `integer` for `"s"`).

## Examples

``` r
if (FALSE) { # \dontrun{
dt <- lubridate::as_datetime("2023-10-31 16:00:00", tz = "UTC")
time_convert_to_kucoin(dt, unit = "ms")  # 1698777600000
time_convert_to_kucoin(dt, unit = "s")   # 1698777600
} # }
```
