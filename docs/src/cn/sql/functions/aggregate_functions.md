# 聚合函数

CeresDB SQL 基于 [DataFusion](https://github.com/CeresDB/arrow-datafusion) 实现，支持的聚合函数如下。更多详情请参考： [Datafusion](https://github.com/CeresDB/arrow-datafusion/blob/master/docs/source/user-guide/sql/aggregate_functions.md)

## 常用

| 函数      | 描述               |
| --------- | ------------------ |
| min       | 最小值             |
| max       | 最大值             |
| count     | 求行数             |
| avg       | 平均值             |
| sum       | 求和               |
| array_agg | 把数据放到一个数组 |

## 统计

| 函数                 | 描述                   |
| -------------------- | ---------------------- |
| var / var_samp       | 返回给定列的样本方差   |
| var_pop              | 返回给定列的总体方差   |
| stddev / stddev_samp | 返回给定列的样本标准差 |
| stddev_pop           | 返回给定列的总体标准差 |
| covar / covar_samp   | 返回给定列的样本协方差 |
| covar_pop            | 返回给定列的总体协方差 |
| corr                 | 返回给定列的相关系数   |

## 估值函数

| 函数                               | 描述                                                                                                                            |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| approx_distinct                    | 返回输入值的近似去重数量（HyperLogLog）                                                                                         |
| approx_median                      | 返回输入值的近似中位数，它是 approx_percentile_cont(x, 0.5) 的简单写法                                                          |
| approx_percentile_cont             | 返回输入值的近似百分位数（TDigest），其中 p 是 0 和 1（包括）之间的 float64，等同于 approx_percentile_cont_with_weight(x, 1, p) |
| approx_percentile_cont_with_weight | 返回输入值带权重的近似百分位数（TDigest），其中 w 是权重列表达式，p 是 0 和 1（包括）之间的 float64                             |
