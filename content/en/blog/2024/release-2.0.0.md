---
title: Release 2.0.0
date: 2024-04-23
description: This is the first version after enter ASF incubator, thanks everyone for making it happen!
---

## Upgrade from 1.x.x to 2.0.0
The transition from CeresDB to Apache HoraeDB introduces several breaking changes. To facilitate upgrading from older versions to v2.0.0, specific alterations are necessary.

#### Upgrade Steps
1. Setup required envs
```
export HORAEDB_DEFAULT_CATALOG=ceresdb
```

2. Update config

Etcd's root should be configured both in horaedb and horaemeta

For horaedb

```
[cluster_deployment.etcd_client]
server_addrs = ['127.0.0.1:2379']
root_path = "/rootPath"
```

For horaemeta

```
storage-root-path = "/rootPath"
```

3. Upgrade horaemeta

Horaedb will throw following errors, which is expected

```
2024-01-23 14:37:57.726 ERRO [src/cluster/src/cluster_impl.rs:136] Send heartbeat to meta failed, err:Failed to send heartbeat, cluster:defaultCluster, err:status: Unimplemented, message: "unknown service meta_service.MetaRpcService", details: [], metadata: MetadataMap { headers: {"content-type": "application/grpc"} }
```

4. Upgrade horaedb

After all server upgraded, the cluster should be ready for read/write, and old data could be queried like before.

## What's Changed

### Breaking Changes
* refactor!: refactor shard version logic by @ZuLiangWang in https://github.com/apache/horaedb/pull/1286

### Features
* feat: support re-acquire shard lock in a fast way by @ShiKaiWi in https://github.com/apache/horaedb/pull/1251
* feat: support alter partition table by @chunshao90 in https://github.com/apache/horaedb/pull/1244
* feat: support access etcd with tls by @ShiKaiWi in https://github.com/apache/horaedb/pull/1254
* feat: support schema validate in remote write by @ShiKaiWi in https://github.com/apache/horaedb/pull/1256
* feat: avoid flush when drop table by @jiacai2050 in https://github.com/apache/horaedb/pull/1257
* feat: opentsdb api support gzip body by @tanruixiang in https://github.com/apache/horaedb/pull/1261
* feat: infer timestamp constraint for single-timestamp column by @Dennis40816 in https://github.com/apache/horaedb/pull/1266
* feat: primary keys support sample by @jiacai2050 in https://github.com/apache/horaedb/pull/1243
* feat: cache space total memory by @jiacai2050 in https://github.com/apache/horaedb/pull/1278
* feat: skip record column values for level0 sst by @jiacai2050 in https://github.com/apache/horaedb/pull/1282
* feat: support write wal logs in columnar format by @ShiKaiWi in https://github.com/apache/horaedb/pull/1179
* feat: support stack size of read threads configurable by @ShiKaiWi in https://github.com/apache/horaedb/pull/1305
* feat: impl DoNothing wal by @jiacai2050 in https://github.com/apache/horaedb/pull/1311
* feat: slow log include remote query by @jiacai2050 in https://github.com/apache/horaedb/pull/1316
* feat: use string for request id by @jiacai2050 in https://github.com/apache/horaedb/pull/1349
* feat: support metrics for number of bytes fetched from object storage by @ShiKaiWi in https://github.com/apache/horaedb/pull/1363
* feat: avoid building dictionary for massive unique column values by @ShiKaiWi in https://github.com/apache/horaedb/pull/1365
* feat: utilize the column cardinality for deciding whether to do dict by @ShiKaiWi in https://github.com/apache/horaedb/pull/1372
* feat: avoid pulling unnecessary columns when querying append mode table by @Rachelint in https://github.com/apache/horaedb/pull/1307
* feat: dist sql analyze by @baojinri in https://github.com/apache/horaedb/pull/1260
* feat: impl priority runtime for read by @jiacai2050 in https://github.com/apache/horaedb/pull/1303
* feat: upgrade horaedbproto by @chunshao90 in https://github.com/apache/horaedb/pull/1408
* feat: block rules support query by @jiacai2050 in https://github.com/apache/horaedb/pull/1420
* feat: try load page indexes by @jiacai2050 in https://github.com/apache/horaedb/pull/1425
* feat: support setting meta_addr&etcd_addrs by env by @chunshao90 in https://github.com/apache/horaedb/pull/1427
* feat: add table status check by @ZuLiangWang in https://github.com/apache/horaedb/pull/1418
* feat: support docker-compose and update README by @chunshao90 in https://github.com/apache/horaedb/pull/1429
* feat: impl layered memtable to reduce duplicated encode during scan by @Rachelint in https://github.com/apache/horaedb/pull/1271
* feat: update disk cache in another thread to avoid blocking normal query process by @jiacai2050 in https://github.com/apache/horaedb/pull/1431
* feat: update pgwire to 0.19 by @sunng87 in https://github.com/apache/horaedb/pull/1436
* feat: filter out MySQL federated components' emitted statements by @chunshao90 in https://github.com/apache/horaedb/pull/1439
* feat: add system_stats lib to collect system stats by @ShiKaiWi in https://github.com/apache/horaedb/pull/1442
* feat(horaectl): initial commit by @chunshao90 in https://github.com/apache/horaedb/pull/1450
* feat: support collect statistics about the engine by @ShiKaiWi in https://github.com/apache/horaedb/pull/1451
* feat: persist sst meta size by @jiacai2050 in https://github.com/apache/horaedb/pull/1440
* feat: add sst level config for benchmark by @zealchen in https://github.com/apache/horaedb/pull/1482
* feat: add exponential backoff when retry by @zealchen in https://github.com/apache/horaedb/pull/1486

### Refactor
* refactor: move wal structs and traits to wal crate by @tisonkun in https://github.com/apache/horaedb/pull/1263
* refactor: improve error readability by @jiacai2050 in https://github.com/apache/horaedb/pull/1265
* refactor: move wal crate to under src folder by @tisonkun in https://github.com/apache/horaedb/pull/1270
* refactor: use `notifier::RequestNotifiers` instead of `dedup_requests::RequestNotifiers` by @baojinri in https://github.com/apache/horaedb/pull/1249
* refactor: conditionally compile wal impls  by @tisonkun in https://github.com/apache/horaedb/pull/1272
* refactor: remove unused min/max timestamp in the RowGroup by @ShiKaiWi in https://github.com/apache/horaedb/pull/1297
* refactor: avoid duplicate codes by @ShiKaiWi in https://github.com/apache/horaedb/pull/1371
* refactor: avoid returning metrics in non-analyze sql by @baojinri in https://github.com/apache/horaedb/pull/1410
* refactor: move sub crates to the src directory by @chunshao90 in https://github.com/apache/horaedb/pull/1443
* refactor: adjust cpu's stats by @ShiKaiWi in https://github.com/apache/horaedb/pull/1457
* refactor: refactor compaction process for remote compaction by @Rachelint in https://github.com/apache/horaedb/pull/1476

### Fixed
* fix: dist query dedup by @Rachelint in https://github.com/apache/horaedb/pull/1269
* fix: log third party crates by @jiacai2050 in https://github.com/apache/horaedb/pull/1289
* fix: ensure primary key order by @jiacai2050 in https://github.com/apache/horaedb/pull/1292
* fix: use flag in preflush to indicate whether reorder is required by @jiacai2050 in https://github.com/apache/horaedb/pull/1298
* fix: alter partition table tag column by @chunshao90 in https://github.com/apache/horaedb/pull/1304
* fix: increase wait duration for flush by @jiacai2050 in https://github.com/apache/horaedb/pull/1315
* fix: add license to workspace members by @jiacai2050 in https://github.com/apache/horaedb/pull/1317
* fix: ensure channel size non zero by @jiacai2050 in https://github.com/apache/horaedb/pull/1345
* fix: fix create table result by @ZuLiangWang in https://github.com/apache/horaedb/pull/1354
* Revert "fix: fix create table result" by @ZuLiangWang in https://github.com/apache/horaedb/pull/1355
* fix: fix test create table result by @ZuLiangWang in https://github.com/apache/horaedb/pull/1357
* fix: no write stall by @ShiKaiWi in https://github.com/apache/horaedb/pull/1388
* fix: collect metrics for `get_ranges` by @ShiKaiWi in https://github.com/apache/horaedb/pull/1364
* fix: ignore collecting fetched bytes stats when sst file is read only once by @ShiKaiWi in https://github.com/apache/horaedb/pull/1369
* fix: publich nightly image by @chunshao90 in https://github.com/apache/horaedb/pull/1396
* fix: missing and verbose logs by @ShiKaiWi in https://github.com/apache/horaedb/pull/1398
* fix: fix broken link by @caicancai in https://github.com/apache/horaedb/pull/1399
* fix: the broken link about the issue status by @ShiKaiWi in https://github.com/apache/horaedb/pull/1402
* fix: skip wal encoding when data wal is disabled by @jiacai2050 in https://github.com/apache/horaedb/pull/1401
* fix: disable percentile for distributed tables by @jiacai2050 in https://github.com/apache/horaedb/pull/1406
* fix: compatible for old table options by @Rachelint in https://github.com/apache/horaedb/pull/1432
* fix: get_ranges is not spawned in io-runtime by @ShiKaiWi in https://github.com/apache/horaedb/pull/1426
* fix: table name is normalized when find timestamp column by @jiacai2050 in https://github.com/apache/horaedb/pull/1446
* fix: changes required for migrate dev to main by @jiacai2050 in https://github.com/apache/horaedb/pull/1455
* fix: missing filter index over the primary keys by @ShiKaiWi in https://github.com/apache/horaedb/pull/1456
* fix: random failure of test_collect_system_stats by @ShiKaiWi in https://github.com/apache/horaedb/pull/1459
* fix(ci): refactor ci trigger conditions by @jiacai2050 in https://github.com/apache/horaedb/pull/1474

### Docs
* chore(docs): rename CeresDB to HoraeDB by @caicancai in https://github.com/apache/horaedb/pull/1337
* chore/docs: remove broken link by @caicancai in https://github.com/apache/horaedb/pull/1341
* docs: update CONTRIBUTING.md by @suyanhanx in https://github.com/apache/horaedb/pull/1382
* doc: fix broken link by @caicancai in https://github.com/apache/horaedb/pull/1358
* chore/doc: rename ceresdb to horaedb by @caicancai in https://github.com/apache/horaedb/pull/1332
* doc: add MySQL-Client in README by @jackwener in https://github.com/apache/horaedb/pull/1331
* doc: fix link in illegal markdown format by @jackwener in https://github.com/apache/horaedb/pull/1334
* style: normalize comments/doc in rustfmt by @jackwener in https://github.com/apache/horaedb/pull/1335
* docs: add sudo for install commands by @caicancai in https://github.com/apache/horaedb/pull/1347
* docs: sync GH activities to commits only by @tisonkun in https://github.com/apache/horaedb/pull/1385
* chore(docs): fix invalid repo links by @SYaoJun in https://github.com/apache/horaedb/pull/1452
* chore(docs): fix invalid repo links by @Apricity001 in https://github.com/apache/horaedb/pull/1472

### Chore
* chore(deps): bump golang.org/x/net from 0.5.0 to 0.17.0 in /integration_tests/sdk/go by @dependabot in https://github.com/apache/horaedb/pull/1258
* chore: delete the configuration related to github cache by @tanruixiang in https://github.com/apache/horaedb/pull/1259
* chore: remove backtrace of blocked table by @chunshao90 in https://github.com/apache/horaedb/pull/1267
* ci: setup golang in CI by @tisonkun in https://github.com/apache/horaedb/pull/1275
* chore: remove default features in analytic_engine by @jiacai2050 in https://github.com/apache/horaedb/pull/1277
* chore(deps): bump google.golang.org/grpc from 1.53.0 to 1.56.3 in /integration_tests/sdk/go by @dependabot in https://github.com/apache/horaedb/pull/1280
* test: simplify ceresmeta-server installation by @tisonkun in https://github.com/apache/horaedb/pull/1287
* chore: enable blank issue by @ShiKaiWi in https://github.com/apache/horaedb/pull/1290
* chore: add metrics to inspect write path by @Rachelint in https://github.com/apache/horaedb/pull/1264
* chore: refactor build_meta.sh in integration-test by @chunshao90 in https://github.com/apache/horaedb/pull/1306
* chore: rename ceresdb to horaedb by @chunshao90 in https://github.com/apache/horaedb/pull/1310
* edit: add schema id, schema name, catalog name in TableData by @dust1 in https://github.com/apache/horaedb/pull/1294
* chore: ignore seq check for DoNothing wal by @jiacai2050 in https://github.com/apache/horaedb/pull/1314
* chore: remove community by @jiacai2050 in https://github.com/apache/horaedb/pull/1318
* chore: try to clear ceresdb stuff by @tisonkun in https://github.com/apache/horaedb/pull/1320
* chore: change copyright owner  by @tisonkun in https://github.com/apache/horaedb/pull/1321
* ci: stop release docker image before we finish the rename and transfer by @tisonkun in https://github.com/apache/horaedb/pull/1323
* chore: bump deps by @jiacai2050 in https://github.com/apache/horaedb/pull/1325
* chore: rename ceresmeta to horaemeta by @chunshao90 in https://github.com/apache/horaedb/pull/1327
* chore: rename binary to horaedb-server and more by @tisonkun in https://github.com/apache/horaedb/pull/1330
* chore(license): rename `license-header.txt`'s CeresDB to HoraeDB by @caicancai in https://github.com/apache/horaedb/pull/1336
* chore: replace ceresdb with horaedb by @jackwener in https://github.com/apache/horaedb/pull/1338
* chore: more rename to horaedb by @tisonkun in https://github.com/apache/horaedb/pull/1340
* chore: update create table integration test result by @ZuLiangWang in https://github.com/apache/horaedb/pull/1344
* chore: disable frequently failed tests by @jiacai2050 in https://github.com/apache/horaedb/pull/1352
* test: add integration test for alter table options by @caicancai in https://github.com/apache/horaedb/pull/1346
* chore: ignore flush failure when flush by @ShiKaiWi in https://github.com/apache/horaedb/pull/1362
* chore: disable timeout for http api by @jiacai2050 in https://github.com/apache/horaedb/pull/1367
* chore: disable block for http api by @jiacai2050 in https://github.com/apache/horaedb/pull/1368
* config: add .asf.yaml by @chunshao90 in https://github.com/apache/horaedb/pull/1377
* ci: remove missing Required status by @tisonkun in https://github.com/apache/horaedb/pull/1383
* chore: git repo link type fix by @fengmk2 in https://github.com/apache/horaedb/pull/1378
* chore: apply ASF license header by @tanruixiang in https://github.com/apache/horaedb/pull/1384
* chore: add dev mail list and rename ceresdb to horaedb by @tanruixiang in https://github.com/apache/horaedb/pull/1375
* chore: more rename to horaedb by @chunshao90 in https://github.com/apache/horaedb/pull/1387
* chore: add push-nightly-image in workflow by @chunshao90 in https://github.com/apache/horaedb/pull/1389
* chore: update README by @chunshao90 in https://github.com/apache/horaedb/pull/1390
* chore: refactor for better readability by @jiacai2050 in https://github.com/apache/horaedb/pull/1400
* chore: add error log for remote server by @jiacai2050 in https://github.com/apache/horaedb/pull/1407
* chore: update website url by @chunshao90 in https://github.com/apache/horaedb/pull/1404
* chore: upload horaedb logo by @chunshao90 in https://github.com/apache/horaedb/pull/1409
* chore: add slack link by @tanruixiang in https://github.com/apache/horaedb/pull/1395
* chore: update logo by @chunshao90 in https://github.com/apache/horaedb/pull/1414
* chore: update horaedb logo by @chunshao90 in https://github.com/apache/horaedb/pull/1415
* chore: rename ceresformat to logformat by @ZuLiangWang in https://github.com/apache/horaedb/pull/1417
* chore: fix logo link in readme by @chunshao90 in https://github.com/apache/horaedb/pull/1416
* chore: update github pages by @chunshao90 in https://github.com/apache/horaedb/pull/1421
* chore: more rename to horaedb by @chunshao90 in https://github.com/apache/horaedb/pull/1419
* chore: fix error message by @jiacai2050 in https://github.com/apache/horaedb/pull/1412
* chore: remove github pages in asf.yaml by @chunshao90 in https://github.com/apache/horaedb/pull/1428
* chore: skip wal seq check when wal is disabled by @jiacai2050 in https://github.com/apache/horaedb/pull/1430
* chore: enable merge on github by @ShiKaiWi in https://github.com/apache/horaedb/pull/1435
* chore: merge change sets on the dev branch by @ShiKaiWi in https://github.com/apache/horaedb/pull/1423
* chore: fix issue status of README-CN.md by @ShiKaiWi in https://github.com/apache/horaedb/pull/1437
* chore(deps): bump h2 from 0.3.17 to 0.3.24 by @dependabot in https://github.com/apache/horaedb/pull/1448
* chore(deps): bump shlex from 1.1.0 to 1.3.0 by @dependabot in https://github.com/apache/horaedb/pull/1458
* chore: update create tables result by @ZuLiangWang in https://github.com/apache/horaedb/pull/1454
* chore: merge HoraeMeta code into HoreaDB repository by @ZuLiangWang in https://github.com/apache/horaedb/pull/1460
* chore(deps): bump google.golang.org/grpc from 1.47.0 to 1.56.3 in /horaemeta by @dependabot in https://github.com/apache/horaedb/pull/1464
* chore(deps): bump golang.org/x/net from 0.16.0 to 0.17.0 in /horaemeta by @dependabot in https://github.com/apache/horaedb/pull/1465
* chore(deps): bump golang.org/x/crypto from 0.14.0 to 0.17.0 in /horaemeta by @dependabot in https://github.com/apache/horaedb/pull/1462
* chore: rename ci's prefix name by @tanruixiang in https://github.com/apache/horaedb/pull/1467
* chore: fix github issue template by @ZuLiangWang in https://github.com/apache/horaedb/pull/1470
* chore(horaemeta&horaectl): refactor clusters/diagnose response body by @chunshao90 in https://github.com/apache/horaedb/pull/1475
* chore: free disk for ci by @jiacai2050 in https://github.com/apache/horaedb/pull/1484
* deps: bump datafusion by @tanruixiang in https://github.com/apache/horaedb/pull/1445
* horaectl: remove go implementation of horaectl by @chunshao90 in https://github.com/apache/horaedb/pull/1490
* chore: update version to 2.0.0, prepare for releasing v2.0.0 by @chunshao90 in https://github.com/apache/horaedb/pull/1487

## New Contributors
* @Dennis40816 made their first contribution in https://github.com/apache/horaedb/pull/1266
* @caicancai made their first contribution in https://github.com/apache/horaedb/pull/1332
* @jackwener made their first contribution in https://github.com/apache/horaedb/pull/1331
* @suyanhanx made their first contribution in https://github.com/apache/horaedb/pull/1382
* @fengmk2 made their first contribution in https://github.com/apache/horaedb/pull/1378
* @sunng87 made their first contribution in https://github.com/apache/horaedb/pull/1436
* @SYaoJun made their first contribution in https://github.com/apache/horaedb/pull/1452
* @Apricity001 made their first contribution in https://github.com/apache/horaedb/pull/1472

**Full Changelog**: https://github.com/apache/horaedb/compare/v1.2.7...v2.0.0
