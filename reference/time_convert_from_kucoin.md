# Convert KuCoin Timestamp to POSIXct

Converts a UNIX timestamp from KuCoin's API into a POSIXct object in
UTC.

## Usage

``` r
time_convert_from_kucoin(time_value, unit = c("ms", "ns", "s"))
```

## Arguments

- time_value:

  (vector\<numeric, 1..\>) the UNIX timestamp(s).

- unit:

  (scalar\<character in c("ms", "ns", "s")\>) input unit: `"ms"`
  (milliseconds, default), `"ns"` (nanoseconds), or `"s"` (seconds).

## Value

(class\<POSIXct\>) POSIXct in UTC.

## Examples

``` r
if (FALSE) { # \dontrun{
time_convert_from_kucoin(1698777600000, unit = "ms")
time_convert_from_kucoin(1698777600000000000, unit = "ns")
time_convert_from_kucoin(1698777600, unit = "s")
} # }
```
