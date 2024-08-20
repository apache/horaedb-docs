---
title: "Aggregate Functions"
weight: 80
---
HoraeDB SQL is implemented with [DataFusion](https://github.com/apache/arrow-datafusion), Here is the list of aggregate functions. See more detail, Refer to [Datafusion](https://github.com/apache/arrow-datafusion/blob/master/docs/source/user-guide/sql/aggregate_functions.md)

## General

| Function  | Description                                     |
| --------- | ----------------------------------------------- |
| min       | Returns the minimum value in a numerical column |
| max       | Returns the maximum value in a numerical column |
| count     | Returns the number of rows                      |
| avg       | Returns the average of a numerical column       |
| sum       | Sums a numerical column                         |
| array_agg | Puts values into an array                       |

## Statistical

| Function             | Description                                                 |
| -------------------- | ----------------------------------------------------------- |
| var / var_samp       | Returns the variance of a given column                      |
| var_pop              | Returns the population variance of a given column           |
| stddev / stddev_samp | Returns the standard deviation of a given column            |
| stddev_pop           | Returns the population standard deviation of a given column |
| covar / covar_samp   | Returns the covariance of a given column                    |
| covar_pop            | Returns the population covariance of a given column         |
| corr                 | Returns the correlation coefficient of a given column       |

## Approximate

| Function                           | Description                                                                                                                                                                                                                                                                                                                                                                                |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| approx_distinct                    | Returns the approximate number (HyperLogLog) of distinct input values                                                                                                                                                                                                                                                                                                                      |
| approx_median                      | Returns the approximate median of input values. It is an alias of approx_percentile_cont(x, 0.5).                                                                                                                                                                                                                                                                                          |
| approx_percentile_cont             | Returns the approximate percentile (TDigest) of input values, where p is a float64 between 0 and 1 (inclusive). It supports raw data as input and build Tdigest sketches during query time, and is approximately equal to approx_percentile_cont_with_weight(x, 1, p).                                                                                                                     |
| approx_percentile_cont_with_weight | Returns the approximate percentile (TDigest) of input values with weight, where w is weight column expression and p is a float64 between 0 and 1 (inclusive). It supports raw data as input or pre-aggregated TDigest sketches, then builds or merges Tdigest sketches during query time. TDigest sketches are a list of centroid (x, w), where x stands for mean and w stands for weight. |
