# 04 analysis
Run 2026-11-20 16:05:17 UTC
Entrants: base 1628756; arbitrum 1228511
A. Base entrants 2024-03-08..2024-03-21: 1169350; in campaign bursts 800751; funded by bursting funders 545793
## A. By entry day (Base): concentration of first recipient, method and funder
           day      N to_top1 to_top10 sel_top1 funder_top1 funder_top10 no_funder_seen campaign bursting_funder months_active months_active_noncampaign N_noncampaign
 1: 2024-03-08  24390 0.25125   0.5519   0.2513     0.12083       0.4367        0.09528  0.25125         0.13883       0.57273                    0.6094         18262
 2: 2024-03-09  20230 0.11127   0.5070   0.2949     0.09259       0.3897        0.11607  0.11127         0.00000       0.56817                    0.5897         17979
 3: 2024-03-10  19109 0.12298   0.4539   0.3229     0.12261       0.4067        0.08729  0.00000         0.00000       0.62860                    0.6286         19109
 4: 2024-03-11  18496 0.10013   0.4572   0.3146     0.12462       0.3995        0.08018  0.00000         0.00000       0.62403                    0.6240         18496
 5: 2024-03-12  19303 0.09693   0.4776   0.3112     0.11392       0.3909        0.07134  0.06906         0.00000       0.56722                    0.5506         17970
 6: 2024-03-13  16491 0.10491   0.4345   0.3022     0.09126       0.3712        0.08180  0.00000         0.00000       0.56188                    0.5619         16491
 7: 2024-03-14  33980 0.20026   0.5601   0.2361     0.07481       0.2872        0.03590  0.23849         0.07481       0.57793                    0.5579         25876
 8: 2024-03-15  74579 0.30698   0.7409   0.3099     0.33475       0.5026        0.03178  0.59576         0.40641       0.40692                    0.6607         30148
 9: 2024-03-16 636254 0.93656   0.9639   0.9571     0.45933       0.6317        0.05877  0.95112         0.71155       0.06153                    0.4567         31102
10: 2024-03-17  48708 0.14897   0.6052   0.3502     0.10148       0.3151        0.21881  0.42075         0.12634       0.41180                    0.4972         28214
11: 2024-03-18  41398 0.14131   0.4941   0.2607     0.09609       0.3094        0.19274  0.28108         0.09609       0.42703                    0.5274         29762
12: 2024-03-19  36463 0.07473   0.4254   0.2775     0.15918       0.4839        0.03579  0.16208         0.26180       0.48282                    0.5388         30553
13: 2024-03-20 114436 0.43907   0.6637   0.5950     0.06187       0.2320        0.23153  0.63027         0.24069       0.36813                    0.5457         42310
14: 2024-03-21  65513 0.24032   0.5077   0.5018     0.06648       0.2552        0.19526  0.35391         0.14667       0.40537                    0.5012         42327
## C. Median fee per tx and dollar stakes of each cut
                                              event    short   p_pre   p_post   dlp q_nonburst stake_individual m_burst ids_per_entity_day_acct_weighted stake_operator_acct_weighted
1:          Base, March 2024 (L1 cost pass-through) Base Mar 0.58880 0.007875 4.314          2          1.16186       1                          28447.8                     16526.13
2:           Arbitrum step 1 (L1 cost pass-through)    Arb 1 0.55016 0.082512 1.897          1          0.46765       3                             49.3                        69.17
3:  Arbitrum step 2 (fee floor cut by the platform)    Arb 2 0.08251 0.009072 2.208          1          0.07344       3                            157.8                        34.77
4: Base, May 2024 (capacity raised by the platform) Base May 0.03396 0.002240 2.719          2          0.06345       2                          25011.2                      1586.88
## C. Table 1: the fee cuts
      short                              time_utc                                                          origin            set_by median_fee_pre median_fee_post dlog_fee stake_individual stake_operator_acct_weighted
1: Base Mar                      2024-03-14 00:00 Ethereum Dencun (EIP-4844) passed through: Base Ecotone upgrade cost pass-through        0.58880        0.007875   -4.314          1.16186                     16526.13
2:    Arb 1                      2024-03-14 15:00               Ethereum Dencun passed through: Arbitrum ArbOS 20 cost pass-through        0.55016        0.082512   -1.897          0.46765                        69.17
3:    Arb 2                      2024-03-19 08:00       Arbitrum governance: minimum L2 base fee 0.1 to 0.01 gwei          platform        0.08251        0.009072   -2.208          0.07344                        34.77
4: Base May 2024-05-28 19:00 and 2024-05-30 20:00    Base raised the block gas limit 60M to 75M to 90M (capacity)          platform        0.03396        0.002240   -2.719          0.06345                      1586.88
## C. Platform economics of the four cuts (US$ per day)
      short            set_by fees_pre fees_post rent_pre rent_post profit_pre profit_post dlog_fees dlog_rent dlog_profit margin_pre margin_post
1: Base Mar cost pass-through   404630    434754 279948.3    1518.1     124682      433236   0.07181   -5.2171      1.2455     0.3081      0.9965
2:    Arb 1 cost pass-through   653136    167507 555994.2    7127.9      97142      160380  -1.36076   -4.3567      0.5014     0.1487      0.9574
3:    Arb 2          platform   167507     30581   7127.9    7964.1     160380       22616  -1.70066    0.1109     -1.9589     0.9574      0.7396
4: Base May          platform   327807    121149    620.2     996.7     327187      120152  -0.99541    0.4745     -1.0018     0.9981      0.9918
## D. Composition under leave-one-out variants (Base)
    event                               metric       all size-only rule without largest burst day without largest burst target without largest component
 1: march                    burst entry ratio 50.883763      73.757139                 13.601473                    11.468235                69.1390937
 2: march                non-burst entry ratio  1.758999       2.130809                  1.771825                     1.756369                 1.6448784
 3: march                    all-entrant ratio  6.471928       6.471928                  2.920215                     2.702906                 6.3347298
 4: march              wedge (all / non-burst)  3.679324       3.037310                  1.648140                     1.538917                 3.8511842
 5: march     burst share of post-cut entrants  0.751158       0.687865                  0.444997                     0.405382                 0.7560248
 6: march  largest 10 entities' share of burst  0.498608       0.516134                  0.554047                     0.560524                 0.4159768
 7: march largest 100 entities' share of burst  0.841556       0.878686                  0.737358                     0.728239                 0.8117736
 8: march            burst in components >= 20  0.934673       0.968811                  0.796067                     0.777860                 0.9218696
 9: march        non-burst in components >= 20  0.308222       0.360726                  0.298990                     0.307331                 0.1542809
10: march                   burst synchronized  0.674075       0.735195                  0.152928                     0.138392                 0.7055396
11: march               non-burst synchronized  0.067238       0.055438                  0.066295                     0.067049                 0.0747756
12: march             burst months active of 3  0.027976       0.019929                  0.097180                     0.104502                 0.0261424
13: march         non-burst months active of 3  0.177774       0.164960                  0.181540                     0.177984                 0.1792410
14: march              burst on LayerZero list  0.001252       0.001056                  0.004088                     0.004281                 0.0007466
15: march          non-burst on LayerZero list  0.036572       0.029750                  0.037828                     0.036628                 0.0436076
16: march    burst first action plain transfer  0.861598       0.937115                  0.459000                     0.385921                 0.8775447
17:   may                    burst entry ratio  4.476763             NA                  4.177069                     3.247099                 2.0770348
18:   may                non-burst entry ratio  1.043263             NA                  1.046117                     1.064812                 0.9584086
19:   may                    all-entrant ratio  1.769428             NA                  1.709746                     1.550407                 1.2121465
20:   may              wedge (all / non-burst)  1.696052             NA                  1.634374                     1.456038                 1.2647492
21:   may     burst share of post-cut entrants  0.529260             NA                  0.511067                     0.458190                 0.3845073
22:   may  largest 10 entities' share of burst  0.818117             NA                  0.834524                     0.813050                 0.5554602
23:   may largest 100 entities' share of burst  0.908876             NA                  0.922874                     0.897820                 0.7661854
24:   may            burst in components >= 20  0.915068             NA                  0.929998                     0.905354                 0.7819580
25:   may        non-burst in components >= 20  0.461175             NA                  0.461214                     0.463746                 0.2372616
26:   may                   burst synchronized        NA             NA                        NA                           NA                        NA
27:   may               non-burst synchronized        NA             NA                        NA                           NA                        NA
28:   may             burst months active of 3  0.037304             NA                  0.043761                     0.045070                 0.0912479
29:   may         non-burst months active of 3  0.135523             NA                  0.138060                     0.134884                 0.1606405
30:   may              burst on LayerZero list        NA             NA                        NA                           NA                        NA
31:   may          non-burst on LayerZero list        NA             NA                        NA                           NA                        NA
32:   may    burst first action plain transfer  0.128874             NA                  0.138965                     0.177678                 0.0164215
    event                               metric       all size-only rule without largest burst day without largest burst target without largest component
## E. The 20 largest post-cut burst groups, March and May (Base)
                                      first_to event rank  first_sel accounts share_of_burst days   peak_day peak_day_share peak_hour_accounts single_tx_wk1 synchronized on_layerzero_list months_active_of3 in_components_ge20 entities
 1: 0xfb10c144539af9a7b905a28f8ad07fb0cf85ae50 march    1         0x   611729       0.774619    3 2024-03-16         0.9737              63362     0.8587005     0.829936        0.00037108        0.00571004           0.980298     6287
 2: 0x5a1aa778dbbab6f7fe646248d591c401cf01f9f2 march    2         0x    65968       0.083534    2 2024-03-20         0.7614               7204     0.8489268     0.331449        0.00113691        0.07126182           0.936257     2585
 3: 0x273ca93a52b817294830ed7572aa591ccfa647fd march    3 0x1249c58b    36018       0.045609    7 2024-03-15         0.6353               7344     0.8469099     0.017519        0.00349825        0.15456161           0.819257     4802
 4: 0xafb89a09d82fbde58f18ac6437b3fc81724e4df6 march    4 0xa9059cbb    17891       0.022655    3 2024-03-15         0.6113               1880     0.4507853     0.084344        0.02375496        0.12313454           0.789112     1278
 5: 0x3f433f14e6ace35bd11c6a8c6d8875daa68c6a80 march    5 0xa0712d68    11825       0.014974    3 2024-03-18         0.4947               3684     0.7042706     0.003975        0.00245243        0.09902748           0.901480     1080
 6: 0x18dd5b087bca9920562aff7a0199b96b9230438b march    6 0x095ea7b3    11190       0.014170    7 2024-03-16         0.2284                302     0.0025022     0.000000        0.00008937        0.05960679           0.128686     9285
 7: 0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad march    7 0x3593564c     8172       0.010348    2 2024-03-20         0.5855                436     0.0835781     0.000000        0.00379344        0.18489966           0.383138     4880
 8: 0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24 march    8 0xb6f9de95     6971       0.008827    5 2024-03-20         0.2816                194     0.0000000     0.000000        0.00000000        0.00114761           0.983360      124
 9: 0xc534bb3640a66faf5eae8699fece511e1c331cad march    9 0xe7a79057     4498       0.005696    1 2024-03-17         1.0000               3383     0.0589151     0.030013        0.00622499        0.12094264           0.706314      770
10: 0xecb03b9a0e7f7b5e261d3ef752865af6621a54fe march   10 0x09c182c3     3886       0.004921    2 2024-03-20         0.7064                420     0.0025733     0.114514        0.00000000        0.09392692           0.657488     1169
11: 0x26bbea7803dcac346d5f5f135b57cf2c752a02be march   11 0x26c858a4     2873       0.003638    1 2024-03-20         1.0000                777     0.3658197     0.000000        0.00522102        0.19735468           0.368952     1736
12: 0x26bbea7803dcac346d5f5f135b57cf2c752a02be march   12 0xfa2b068f     2002       0.002535    1 2024-03-20         1.0000                409     0.6058941     0.000000        0.01348651        0.18331668           0.237762     1370
13: 0x4869892c8088d9057ad7d0e5189ae8c3278f8877 march   13 0x8f1fda56     1584       0.002006    1 2024-03-20         1.0000                105     0.0006313     0.000000        0.00000000        0.10606061           0.655303      552
14: 0xc32d8100756ff66cb2a9121463183c2bb18ad9a4 march   14         0x     1432       0.001813    1 2024-03-18         1.0000                408     0.4252793     0.000000        0.00209497        0.16410615           0.745810      249
15: 0x28e43bb3ee202e1da587c88b0a8398309e8d4c2d march   15 0xba41b0c6     1303       0.001650    1 2024-03-19         1.0000                799     0.9178818     0.000000        0.00000000        0.05448964           0.927859       91
16: 0x3304e22ddaa22bcdc5fca2269b418046ae7b566a march   16         0x     1289       0.001632    1 2024-03-20         1.0000                194     0.7354538     0.000000        0.00000000        0.21101629           0.131109     1124
17: 0x6b2c0c7be2048daa9b5527982c29f48062b34d58 march   17 0xb80c2f09     1085       0.001374    1 2024-03-20         1.0000                372     0.0451613     0.000000        0.00184332        0.16866359           0.204608      845
18: 0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24   may    1 0x7ff36ab5    74959       0.210482    7 2024-06-04         0.1882               1850     0.0022946           NA                NA        0.00072039           0.994891      320
19: 0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad   may    2 0x24856bc3    72226       0.202807    4 2024-05-30         0.3897               5833     0.0001661           NA                NA        0.00002769           0.999875       10
20: 0x1349a9ddee26fe16d0d44e35b3cb9b0ca18213a4   may    3 0x2f52ebb7    52757       0.148139    2 2024-06-02         0.5022               6360     0.0323938           NA                NA        0.00250204           0.999583       24
21: 0x394273231a8726af7f2cdb687977f513a28eb2a5   may    4         0x    43587       0.122390    7 2024-05-31         0.1862               1857     1.0000000           NA                NA        0.00000000           1.000000        1
22: 0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad   may    5 0x3593564c    25595       0.071870    3 2024-06-04         0.4274               2579     0.3001758           NA                NA        0.06411408           0.773784     5693
23: 0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24   may    6 0xb6f9de95    21645       0.060778    2 2024-06-04         0.5938                872     0.0011088           NA                NA        0.00023100           0.998475       37
24: 0x683ba8d993614f36c67babd39712de338375d135   may    7 0x84bb1e42    11005       0.030902    2 2024-06-01         0.7694               1879     0.0002726           NA                NA        0.00081781           0.998455       19
25: 0x6bded42c6da8fbf0d2ba55b2fa120c5e0c8d7891   may    8 0x7ff36ab5     9742       0.027355    1 2024-06-03         1.0000               1153     0.7814617           NA                NA        0.00000000           1.000000      269
26: 0xd5005423bf4c937e6ca046b3c2a512229aa1589d   may    9 0xa6ec2245     5314       0.014921    3 2024-06-04         0.4603                702     0.0186300           NA                NA        0.03838916           0.989838       22
27: 0xd1253afc33386d9f0d546f1e5b105b328ba1557a   may   10 0x31318c19     5128       0.014399    2 2024-06-03         0.5107                603     0.2195788           NA                NA        0.00273011           0.000000     5128
28: 0xcde172dc5ffc46d228838446c57c1227e0b82049   may   11 0xa9059cbb     4969       0.013953    2 2024-05-30         0.6766               1051     0.5129805           NA                NA        0.40189173           0.675991     1611
29: 0xb4a8d45647445ea9fc3e1058096142390683dbc2   may   12 0xe0db3fcf     4778       0.013416    3 2024-06-02         0.3817                581     0.8294265           NA                NA        0.08120553           0.016534     4697
30: 0xdef1c0ded9bec7f1a1670819833240f027b25eff   may   13 0x415565b0     3838       0.010777    1 2024-06-04         1.0000                336     0.9379885           NA                NA        0.02162585           0.007035     3815
31: 0x1d6b183bd47f914f9f1d3208edcf8befd7f84e63   may   14 0x57bc3d78     3142       0.008823    1 2024-05-30         1.0000                362     0.0022279           NA                NA        1.00031827           0.989815       35
32: 0xc649989246faa59bbefa7c65551cc4461e823320   may   15 0x6a627842     3004       0.008435    1 2024-05-30         1.0000                357     0.0003329           NA                NA        0.99900133           0.999001        5
33: 0xf4c9fc64ed902b08c3397c48dca0342bdfd49a32   may   16 0x2e7ba6ef     2468       0.006930    1 2024-05-29         1.0000                764     0.2414911           NA                NA        0.45016207           0.165721     1342
34: 0x6e02b8a641d7b43c2334d6df5db9fb2e51100de8   may   17 0x521da65d     1979       0.005557    1 2024-06-03         1.0000               1439     0.0000000           NA                NA        0.00000000           1.000000        1
35: 0x338c686291c616797727518028905b526973f8a2   may   18 0xefb6b11f     1723       0.004838    1 2024-05-31         1.0000               1205     0.2013929           NA                NA        0.28090540           0.220546      748
36: 0x1f75d83c2541995e4488c2bf5e47764308b81196   may   19 0x8f0bc152     1538       0.004319    1 2024-05-31         1.0000                200     0.0617685           NA                NA        0.37971391           0.509753      347
37: 0x840637292aa7969c3df9d8d0d04c2b2fdd142f82   may   20         0x     1292       0.003628    1 2024-05-29         1.0000                373     1.0000000           NA                NA        0.00000000           0.068885     1204
                                      first_to event rank  first_sel accounts share_of_burst days   peak_day peak_day_share peak_hour_accounts single_tx_wk1 synchronized on_layerzero_list months_active_of3 in_components_ge20 entities
    largest_entity_share funded_internal funded_top_level target_contract target_logs_721 target_logs_20 accounts_f funded  eth_mean eth_unswept_mean   swept initiators top_level_funders
 1:             0.162371       0.6412169         0.357438               0               0              0     611729 0.9985 0.0003070      0.000024095 0.10490        261             28573
 2:             0.336451       0.5071398         0.488206               0               0              0      65968 0.9945 0.0309382      0.000138729 0.10833        103              6081
 3:             0.277639       0.8125937         0.144261               1          941636              0      36018 0.9481 0.0094592      0.000700448 0.13271         51              2932
 4:             0.294003       0.0460008         0.952043               1               0         961541      17891 0.9977 0.0005205      0.000007404 0.52250         13              6961
 5:             0.649218       0.8872727         0.096575               1               0              0      11825 0.9798 0.0019671      0.000120565 0.08592         31               419
 6:             0.047006       0.0029491         0.987310               1               0         135750      11190 0.9895 0.0036202      0.000257397 0.90545       3137              1239
 7:             0.308248       0.1335047         0.862212               0               0              0       8172 0.9940 0.3419239      0.000000000 1.00000        253              1032
 8:             0.602066       0.0167838         0.983216               0               0              0       6971 1.0000 0.1022385      0.000000000 1.00000         13               616
 9:             0.584927       0.2040907         0.793686               1               0              0       4498 0.9971 0.1555710      0.000000000 1.00000         68               853
10:             0.628667       0.0388574         0.960628               1               0              0       3886 0.9969 0.2529791      0.000000000 1.00000        423              1499
11:             0.250261       0.2387748         0.754960               1               0              0       2873 0.9913 0.1557235      0.000000000 1.00000         36               414
12:             0.176324       0.1078921         0.872627               1               0              0       2002 0.9745 0.0268652      0.000000000 1.00000         29               326
13:             0.650884       0.0164141         0.983586               0               0              0       1584 1.0000 0.3196700      0.000000000 1.00000         15              1431
14:             0.613128       0.3065642         0.680866               0               0              0       1432 0.9839 0.0004198      0.000055938 0.25489         12               383
15:             0.767460       0.8488104         0.150422               1           67915              0       1303 0.9992 0.0006403      0.000458152 0.05065          8                57
16:             0.121800       0.0000000         1.000000               0               0              0       1289 1.0000 1.6408852      0.000000000 1.00000          0              1235
17:             0.201843       0.0967742         0.901382               1               0              0       1085 0.9982 0.4325792      0.000000000 1.00000         13                89
18:             0.958124       0.9108179         0.085820               0               0              0         NA     NA        NA               NA      NA         NA                NA
19:             0.999875       0.0024783         0.997522               0               0              0         NA     NA        NA               NA      NA         NA                NA
20:             0.402354       0.4023542         0.597646              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
21:             1.000000       1.0000000         0.000000              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
22:             0.241024       0.5696034         0.425513               0               0              0         NA     NA        NA               NA      NA         NA                NA
23:             0.766320       0.0017094         0.998291               0               0              0         NA     NA        NA               NA      NA         NA                NA
24:             0.917401       0.9176738         0.082054              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
25:             0.781462       0.0000000         1.000000              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
26:             0.843244       0.0000000         0.999812              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
27:             0.000195       0.0000000         0.998440              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
28:             0.675991       0.9985913         0.001409              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
29:             0.012976       0.3838426         0.608623              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
30:             0.003648       0.9213132         0.074257              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
31:             0.988861       0.0015913         0.994908              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
32:             0.998668       0.0003329         0.999667              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
33:             0.081442       0.0267423         0.957050              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
34:             1.000000       1.0000000         0.000000              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
35:             0.077771       0.0499129         0.890888              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
36:             0.100780       0.1436931         0.820546              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
37:             0.068885       1.0000000         0.000000              NA              NA             NA         NA     NA        NA               NA      NA         NA                NA
    largest_entity_share funded_internal funded_top_level target_contract target_logs_721 target_logs_20 accounts_f funded  eth_mean eth_unswept_mean   swept initiators top_level_funders
## G1. Event study: log entry outside waves, Base minus Ethereum L1, relative to the week before the cut (band: 5th-95th percentile, pre-cut placebo dates)
      k         e placebo_K      lo     hi
 1: -14  0.232449        44 -0.3431 0.2943
 2: -13 -0.068484        44 -0.3361 0.2725
 3: -12 -0.128186        44 -0.3187 0.2638
 4: -11 -0.126246        44 -0.3326 0.2629
 5: -10 -0.339550        44 -0.3180 0.2234
 6:  -9 -0.258928        44 -0.3094 0.2195
 7:  -8 -0.056844        44 -0.2827 0.1903
 8:  -7  0.090952        44 -0.2592 0.1529
 9:  -6 -0.021341        44 -0.2462 0.1568
10:  -5 -0.033862        44 -0.2724 0.1599
11:  -4  0.077100        44 -0.2314 0.1793
12:  -3 -0.080734        44 -0.2048 0.2026
13:  -2 -0.027472        44 -0.1726 0.2208
14:  -1 -0.004643        44 -0.1511 0.2422
15:   0  0.268950        44 -0.1609 0.2744
16:   1  0.281125        44 -0.1654 0.3265
17:   2  0.402136        44 -0.1702 0.3594
18:   3  0.493429        44 -0.1472 0.3856
19:   4  0.507380        44 -0.1815 0.3387
20:   5  0.668553        44 -0.2078 0.2908
21:   6  0.845336        44 -0.2088 0.3544
22:   7  0.842303        44 -0.2080 0.3671
23:   8  0.697587        44 -0.2019 0.3745
24:   9  0.758079        44 -0.1878 0.3927
25:  10  0.765684        44 -0.1843 0.3770
26:  11  0.744966        44 -0.1527 0.3828
27:  12  0.858232        44 -0.1769 0.3757
28:  13  0.852376        44 -0.1705 0.3708
29:  14  0.987654        44 -0.1701 0.4548
      k         e placebo_K      lo     hi
## G2. Entry outside waves after vs before the Base cut (ratio), against placebo dates
    window_days                 series            placebo ratio placebo_K placebo_pct p_one_sided  p_floor placebo_p95
 1:           6                   Base          all dates 1.684       139      0.9856    0.021429 0.007143       1.425
 2:           6                   Base pre-cut dates only 1.684        61      1.0000    0.016129 0.016129       1.385
 3:           6 Base minus Ethereum L1          all dates 1.572       139      0.9856    0.021429 0.007143       1.365
 4:           6 Base minus Ethereum L1 pre-cut dates only 1.572        61      1.0000    0.016129 0.016129       1.293
 5:           7                   Base          all dates 1.742       133      0.9925    0.014925 0.007463       1.476
 6:           7                   Base pre-cut dates only 1.742        59      1.0000    0.016667 0.016667       1.342
 7:           7 Base minus Ethereum L1          all dates 1.641       133      1.0000    0.007463 0.007463       1.409
 8:           7 Base minus Ethereum L1 pre-cut dates only 1.641        59      1.0000    0.016667 0.016667       1.242
 9:          14                   Base          all dates 2.144        91      1.0000    0.010870 0.010870       1.414
10:          14                   Base pre-cut dates only 2.144        45      1.0000    0.021739 0.021739       1.316
11:          14 Base minus Ethereum L1          all dates 2.004        91      1.0000    0.010870 0.010870       1.402
12:          14 Base minus Ethereum L1 pre-cut dates only 2.004        45      1.0000    0.021739 0.021739       1.265
13:          28                   Base          all dates 2.930        31      1.0000    0.031250 0.031250       1.264
14:          28                   Base pre-cut dates only 2.930        17      1.0000    0.055556 0.055556       1.267
15:          28 Base minus Ethereum L1          all dates 2.610        31      1.0000    0.031250 0.031250       1.298
16:          28 Base minus Ethereum L1 pre-cut dates only 2.610        17      1.0000    0.055556 0.055556       1.304
## G3. Delay or new entry: Base minus L1, run-up (dip), after, and the 28 days together (net), relative to days c-42..c-15
   statistic            placebo    value placebo_K placebo_pct   p_low  p_high p_floor
1:       dip          all dates -0.05214        31      0.2581 0.28125 0.75000 0.03125
2:       dip pre-cut dates only -0.05214        17      0.0000 0.05556 1.00000 0.05556
3:     after          all dates  0.64300        31      1.0000 1.00000 0.03125 0.03125
4:     after pre-cut dates only  0.64300        17      1.0000 1.00000 0.05556 0.05556
5:       net          all dates  0.29543        31      1.0000 1.00000 0.03125 0.03125
6:       net pre-cut dates only  0.29543        17      1.0000 1.00000 0.05556 0.05556
## G4. Non-burst window entrants active later (Sep 2024, Dec 2024 or Mar 2025, days 1-10): 6 days before vs 6 days after the chain's first cut hour
      chain entrants_before entrants_after active_before active_after  ratio     lo     hi
1:     base          107754         173565       0.14724      0.13181 0.8952 0.8223 0.9695
2: arbitrum          186248         227849       0.06985      0.07666 1.0975 0.9448 1.2782
## H1. Non-burst window entrants per day by source of their first ETH, 6 days before vs 6 days after the chain's first cut hour
                           source  before   after    chain  ratio share_before share_after share_of_increase
 1:   individual, direct transfer 10992.3 13781.0 arbitrum 1.2537     0.354119    0.362898          0.402202
 2:              untagged service 11587.5 13465.0 arbitrum 1.1620     0.373293    0.354577          0.270787
 3:               no funder found  2743.7  4069.0 arbitrum 1.4831     0.088388    0.107150          0.191149
 4:           exchange withdrawal  3329.8  3827.0 arbitrum 1.1493     0.107271    0.100777          0.071705
 5:      exchange deposit address   665.5   919.0 arbitrum 1.3809     0.021439    0.024200          0.036562
 6:             token funder only   881.7  1054.7 arbitrum 1.1962     0.028403    0.027773          0.024951
 7:             bridge or relayer   840.8   859.2 arbitrum 1.0218     0.027088    0.022625          0.002644
 8:   individual, direct transfer  6114.5 12079.3     base 1.9755     0.340470    0.417573          0.543815
 9:             bridge or relayer  2807.8  4677.3     base 1.6658     0.156347    0.161692          0.170443
10:           exchange withdrawal  4885.5  6536.3     base 1.3379     0.272036    0.225956          0.150507
11: individual, contract transfer   347.3  1376.5     base 3.9631     0.019340    0.047584          0.093829
12:               no funder found  1171.5  1634.0     base 1.3948     0.065232    0.056486          0.042166
13:              untagged service  1124.7  1322.3     base 1.1758     0.062624    0.045712          0.018021
14:             token funder only   131.3   103.7     base 0.7893     0.007313    0.003584         -0.002522
15:      exchange deposit address  1376.3  1198.0     base 0.8704     0.076638    0.041414         -0.016259
## H2. Non-burst window entrants per day by funding cluster, and the funding entities behind them, 6 days before vs 6 days after the chain's first cut hour
                                  measure before after    chain ratio
 1:            addresses, cluster of 2-19   3992  5909     base 1.480
 2:             addresses, cluster of 20+   3390  8788     base 2.593
 3:                      addresses, alone  10577 14230     base 1.345
 4:                        addresses, all  17959 28928     base 1.611
 5:                 funding entities, all  13063 18027     base 1.380
 6: funding entities, components below 20  12964 17822     base 1.375
 7:             addresses, cluster of 20+   3537  6738 arbitrum 1.905
 8:            addresses, cluster of 2-19   8056  8334 arbitrum 1.035
 9:                      addresses, alone  19448 22903 arbitrum 1.178
10:                        addresses, all  31041 37975 arbitrum 1.223
11:                 funding entities, all  24200 27766 arbitrum 1.147
12: funding entities, components below 20  24053 27580 arbitrum 1.147
## I. Both Base cuts, one estimator: shift on Base minus the comparison chain, against placebo dates (May: step days 05-28..30 left out)
            cut window_days comparison                              outcome                                    placebo shift_base shift_comparison    diff placebo_K disjoint_K pct_diff p_one_sided  p_floor pct_base_alone
  1: Base March           6   ethereum      log(1 + new addresses in waves)                                  all dates    3.90723         1.285073  2.6222       139         13  0.92086    0.085714 0.007143         0.9568
  2: Base March           6   ethereum      log(1 + new addresses in waves)                              pre-cut dates    3.90723         1.285073  2.6222        61          6  0.81967    0.193548 0.016129         0.9016
  3: Base March           6   ethereum same, without the largest wave group                                  all dates    3.23335         1.171743  2.0616       139         13  0.87050    0.135714 0.007143         0.9424
  4: Base March           6   ethereum same, without the largest wave group                              pre-cut dates    3.23335         1.171743  2.0616        61          6  0.73770    0.274194 0.016129         0.8689
  5: Base March           6   ethereum                        waves per day                                  all dates    5.83333         4.833333  1.0000       139         13  0.66906    0.335714 0.007143         0.9784
  6: Base March           6   ethereum                        waves per day                              pre-cut dates    5.83333         4.833333  1.0000        61          6  0.55738    0.451613 0.016129         1.0000
  7: Base March           6   ethereum      log new addresses outside waves                                  all dates    0.52137         0.069279  0.4521       139         13  0.98561    0.021429 0.007143         0.9856
  8: Base March           6   ethereum      log new addresses outside waves                              pre-cut dates    0.52137         0.069279  0.4521        61          6  1.00000    0.016129 0.016129         1.0000
  9: Base March           6   arbitrum      log(1 + new addresses in waves)                                  all dates    3.90723         1.026272  2.8810       139         13  0.82014    0.185714 0.007143         0.9568
 10: Base March           6   arbitrum      log(1 + new addresses in waves)                              pre-cut dates    3.90723         1.026272  2.8810        61          6  0.60656    0.403226 0.016129         0.9016
 11: Base March           6   arbitrum same, without the largest wave group                                  all dates    3.23335         2.596413  0.6369       139         13  0.63309    0.371429 0.007143         0.9424
 12: Base March           6   arbitrum same, without the largest wave group                              pre-cut dates    3.23335         2.596413  0.6369        61          6  0.50820    0.500000 0.016129         0.8689
 13: Base March           6   arbitrum                        waves per day                                  all dates    5.83333         0.833333  5.0000       139         13  0.99281    0.014286 0.007143         0.9784
 14: Base March           6   arbitrum                        waves per day                              pre-cut dates    5.83333         0.833333  5.0000        61          6  1.00000    0.016129 0.016129         1.0000
 15: Base March           6   arbitrum      log new addresses outside waves                                  all dates    0.52137         0.245770  0.2756       139         13  0.89209    0.114286 0.007143         0.9856
 16: Base March           6   arbitrum      log new addresses outside waves                              pre-cut dates    0.52137         0.245770  0.2756        61          6  0.95082    0.064516 0.016129         1.0000
 17: Base March           7   ethereum      log(1 + new addresses in waves)                                  all dates    3.70429         1.379680  2.3246       133         11  0.88722    0.119403 0.007463         0.9699
 18: Base March           7   ethereum      log(1 + new addresses in waves)                              pre-cut dates    3.70429         1.379680  2.3246        59          5  0.74576    0.266667 0.016667         0.9322
 19: Base March           7   ethereum same, without the largest wave group                                  all dates    3.12668         1.255146  1.8715       133         11  0.84962    0.156716 0.007463         0.9398
 20: Base March           7   ethereum same, without the largest wave group                              pre-cut dates    3.12668         1.255146  1.8715        59          5  0.67797    0.333333 0.016667         0.8644
 21: Base March           7   ethereum                        waves per day                                  all dates    6.28571         4.857143  1.4286       133         11  0.70677    0.298507 0.007463         0.9925
 22: Base March           7   ethereum                        waves per day                              pre-cut dates    6.28571         4.857143  1.4286        59          5  0.55932    0.450000 0.016667         1.0000
 23: Base March           7   ethereum      log new addresses outside waves                                  all dates    0.55492         0.059648  0.4953       133         11  1.00000    0.007463 0.007463         0.9925
 24: Base March           7   ethereum      log new addresses outside waves                              pre-cut dates    0.55492         0.059648  0.4953        59          5  1.00000    0.016667 0.016667         1.0000
 25: Base March           7   arbitrum      log(1 + new addresses in waves)                                  all dates    3.70429         2.263334  1.4410       133         11  0.74436    0.261194 0.007463         0.9699
 26: Base March           7   arbitrum      log(1 + new addresses in waves)                              pre-cut dates    3.70429         2.263334  1.4410        59          5  0.52542    0.483333 0.016667         0.9322
 27: Base March           7   arbitrum same, without the largest wave group                                  all dates    3.12668         3.609169 -0.4825       133         11  0.30075    0.701493 0.007463         0.9398
 28: Base March           7   arbitrum same, without the largest wave group                              pre-cut dates    3.12668         3.609169 -0.4825        59          5  0.33898    0.666667 0.016667         0.8644
 29: Base March           7   arbitrum                        waves per day                                  all dates    6.28571         1.428571  4.8571       133         11  0.98496    0.022388 0.007463         0.9925
 30: Base March           7   arbitrum                        waves per day                              pre-cut dates    6.28571         1.428571  4.8571        59          5  0.98305    0.033333 0.016667         1.0000
 31: Base March           7   arbitrum      log new addresses outside waves                                  all dates    0.55492         0.262160  0.2928       133         11  0.90977    0.097015 0.007463         0.9925
 32: Base March           7   arbitrum      log new addresses outside waves                              pre-cut dates    0.55492         0.262160  0.2928        59          5  0.98305    0.033333 0.016667         1.0000
 33: Base March          14   ethereum      log(1 + new addresses in waves)                                  all dates    2.61920         1.122035  1.4972        91          5  0.74725    0.260870 0.010870         0.8352
 34: Base March          14   ethereum      log(1 + new addresses in waves)                              pre-cut dates    2.61920         1.122035  1.4972        45          2  0.48889    0.521739 0.021739         0.6667
 35: Base March          14   ethereum same, without the largest wave group                                  all dates    2.33040         0.853788  1.4766        91          5  0.73626    0.271739 0.010870         0.7912
 36: Base March          14   ethereum same, without the largest wave group                              pre-cut dates    2.33040         0.853788  1.4766        45          2  0.46667    0.543478 0.021739         0.5778
 37: Base March          14   ethereum                        waves per day                                  all dates    4.71429         5.214286 -0.5000        91          5  0.40659    0.597826 0.010870         1.0000
 38: Base March          14   ethereum                        waves per day                              pre-cut dates    4.71429         5.214286 -0.5000        45          2  0.24444    0.760870 0.021739         1.0000
 39: Base March          14   ethereum      log new addresses outside waves                                  all dates    0.76265         0.067512  0.6951        91          5  1.00000    0.010870 0.010870         1.0000
 40: Base March          14   ethereum      log new addresses outside waves                              pre-cut dates    0.76265         0.067512  0.6951        45          2  1.00000    0.021739 0.021739         1.0000
 41: Base March          14   arbitrum      log(1 + new addresses in waves)                                  all dates    2.61920         4.343438 -1.7242        91          5  0.00000    1.000000 0.010870         0.8352
 42: Base March          14   arbitrum      log(1 + new addresses in waves)                              pre-cut dates    2.61920         4.343438 -1.7242        45          2  0.00000    1.000000 0.021739         0.6667
 43: Base March          14   arbitrum same, without the largest wave group                                  all dates    2.33040         3.891149 -1.5607        91          5  0.10989    0.891304 0.010870         0.7912
 44: Base March          14   arbitrum same, without the largest wave group                              pre-cut dates    2.33040         3.891149 -1.5607        45          2  0.22222    0.782609 0.021739         0.5778
 45: Base March          14   arbitrum                        waves per day                                  all dates    4.71429         3.642857  1.0714        91          5  0.83516    0.173913 0.010870         1.0000
 46: Base March          14   arbitrum                        waves per day                              pre-cut dates    4.71429         3.642857  1.0714        45          2  0.88889    0.130435 0.021739         1.0000
 47: Base March          14   arbitrum      log new addresses outside waves                                  all dates    0.76265         0.337156  0.4255        91          5  0.97802    0.032609 0.010870         1.0000
 48: Base March          14   arbitrum      log new addresses outside waves                              pre-cut dates    0.76265         0.337156  0.4255        45          2  1.00000    0.021739 0.021739         1.0000
 49: Base March          28   ethereum      log(1 + new addresses in waves)                                  all dates    2.26430         0.367355  1.8969        31          2  0.45161    0.562500 0.031250         0.4516
 50: Base March          28   ethereum      log(1 + new addresses in waves)                              pre-cut dates    2.26430         0.367355  1.8969        17          1  0.00000    1.000000 0.055556         0.0000
 51: Base March          28   ethereum same, without the largest wave group                                  all dates    2.11990         0.590061  1.5298        31          2  0.58065    0.437500 0.031250         0.7097
 52: Base March          28   ethereum same, without the largest wave group                              pre-cut dates    2.11990         0.590061  1.5298        17          1  0.23529    0.777778 0.055556         0.4706
 53: Base March          28   ethereum                        waves per day                                  all dates    6.07143         1.428571  4.6429        31          2  1.00000    0.031250 0.031250         1.0000
 54: Base March          28   ethereum                        waves per day                              pre-cut dates    6.07143         1.428571  4.6429        17          1  1.00000    0.055556 0.055556         1.0000
 55: Base March          28   ethereum      log new addresses outside waves                                  all dates    1.07510         0.115881  0.9592        31          2  1.00000    0.031250 0.031250         1.0000
 56: Base March          28   ethereum      log new addresses outside waves                              pre-cut dates    1.07510         0.115881  0.9592        17          1  1.00000    0.055556 0.055556         1.0000
 57: Base March          28   arbitrum      log(1 + new addresses in waves)                                  all dates    2.26430         3.235122 -0.9708        31          2  0.29032    0.718750 0.031250         0.4516
 58: Base March          28   arbitrum      log(1 + new addresses in waves)                              pre-cut dates    2.26430         3.235122 -0.9708        17          1  0.00000    1.000000 0.055556         0.0000
 59: Base March          28   arbitrum same, without the largest wave group                                  all dates    2.11990         2.993576 -0.8737        31          2  0.00000    1.000000 0.031250         0.7097
 60: Base March          28   arbitrum same, without the largest wave group                              pre-cut dates    2.11990         2.993576 -0.8737        17          1  0.00000    1.000000 0.055556         0.4706
 61: Base March          28   arbitrum                        waves per day                                  all dates    6.07143         3.785714  2.2857        31          2  1.00000    0.031250 0.031250         1.0000
 62: Base March          28   arbitrum                        waves per day                              pre-cut dates    6.07143         3.785714  2.2857        17          1  1.00000    0.055556 0.055556         1.0000
 63: Base March          28   arbitrum      log new addresses outside waves                                  all dates    1.07510         0.397111  0.6780        31          2  1.00000    0.031250 0.031250         1.0000
 64: Base March          28   arbitrum      log new addresses outside waves                              pre-cut dates    1.07510         0.397111  0.6780        17          1  1.00000    0.055556 0.055556         1.0000
 65:   Base May           6   ethereum      log(1 + new addresses in waves)                                  all dates    1.53609        -1.347430  2.8835       130         10  0.90769    0.099237 0.007634         0.7923
 66:   Base May           6   ethereum      log(1 + new addresses in waves)                              pre-cut dates    1.53609        -1.347430  2.8835        55          4  1.00000    0.017857 0.017857         1.0000
 67:   Base May           6   ethereum      log(1 + new addresses in waves)                 cents regime (after 03-19)    1.53609        -1.347430  2.8835        72          6  1.00000    0.013699 0.013699         1.0000
 68:   Base May           6   ethereum      log(1 + new addresses in waves) cents regime without Base gas-target steps    1.53609        -1.347430  2.8835        59          5  1.00000    0.016667 0.016667         1.0000
 69:   Base May           6   ethereum same, without the largest wave group                                  all dates    1.53472        -1.172933  2.7077       130         10  0.90000    0.106870 0.007634         0.8846
 70:   Base May           6   ethereum same, without the largest wave group                              pre-cut dates    1.53472        -1.172933  2.7077        55          4  1.00000    0.017857 0.017857         1.0000
 71:   Base May           6   ethereum same, without the largest wave group                 cents regime (after 03-19)    1.53472        -1.172933  2.7077        72          6  1.00000    0.013699 0.013699         1.0000
 72:   Base May           6   ethereum same, without the largest wave group cents regime without Base gas-target steps    1.53472        -1.172933  2.7077        59          5  1.00000    0.016667 0.016667         1.0000
 73:   Base May           6   ethereum                        waves per day                                  all dates    4.83333        -3.666667  8.5000       130         10  0.98462    0.022901 0.007634         0.9846
 74:   Base May           6   ethereum                        waves per day                              pre-cut dates    4.83333        -3.666667  8.5000        55          4  0.96364    0.053571 0.017857         0.9636
 75:   Base May           6   ethereum                        waves per day                 cents regime (after 03-19)    4.83333        -3.666667  8.5000        72          6  0.97222    0.041096 0.013699         0.9722
 76:   Base May           6   ethereum                        waves per day cents regime without Base gas-target steps    4.83333        -3.666667  8.5000        59          5  1.00000    0.016667 0.016667         1.0000
 77:   Base May           6   ethereum      log new addresses outside waves                                  all dates    0.05561        -0.087954  0.1436       130         10  0.66154    0.343511 0.007634         0.5769
 78:   Base May           6   ethereum      log new addresses outside waves                              pre-cut dates    0.05561        -0.087954  0.1436        55          4  0.81818    0.196429 0.017857         0.8000
 79:   Base May           6   ethereum      log new addresses outside waves                 cents regime (after 03-19)    0.05561        -0.087954  0.1436        72          6  0.62500    0.383562 0.013699         0.6111
 80:   Base May           6   ethereum      log new addresses outside waves cents regime without Base gas-target steps    0.05561        -0.087954  0.1436        59          5  0.71186    0.300000 0.016667         0.7119
 81:   Base May           6   arbitrum      log(1 + new addresses in waves)                                  all dates    1.53609         0.719985  0.8161       130         10  0.59231    0.412214 0.007634         0.7923
 82:   Base May           6   arbitrum      log(1 + new addresses in waves)                              pre-cut dates    1.53609         0.719985  0.8161        55          4  0.83636    0.178571 0.017857         1.0000
 83:   Base May           6   arbitrum      log(1 + new addresses in waves)                 cents regime (after 03-19)    1.53609         0.719985  0.8161        72          6  0.76389    0.246575 0.013699         1.0000
 84:   Base May           6   arbitrum      log(1 + new addresses in waves) cents regime without Base gas-target steps    1.53609         0.719985  0.8161        59          5  0.71186    0.300000 0.016667         1.0000
 85:   Base May           6   arbitrum same, without the largest wave group                                  all dates    1.53472         0.423503  1.1112       130         10  0.72308    0.282443 0.007634         0.8846
 86:   Base May           6   arbitrum same, without the largest wave group                              pre-cut dates    1.53472         0.423503  1.1112        55          4  0.89091    0.125000 0.017857         1.0000
 87:   Base May           6   arbitrum same, without the largest wave group                 cents regime (after 03-19)    1.53472         0.423503  1.1112        72          6  0.86111    0.150685 0.013699         1.0000
 88:   Base May           6   arbitrum same, without the largest wave group cents regime without Base gas-target steps    1.53472         0.423503  1.1112        59          5  0.83051    0.183333 0.016667         1.0000
 89:   Base May           6   arbitrum                        waves per day                                  all dates    4.83333         1.333333  3.5000       130         10  0.84615    0.160305 0.007634         0.9846
 90:   Base May           6   arbitrum                        waves per day                              pre-cut dates    4.83333         1.333333  3.5000        55          4  0.76364    0.250000 0.017857         0.9636
 91:   Base May           6   arbitrum                        waves per day                 cents regime (after 03-19)    4.83333         1.333333  3.5000        72          6  0.79167    0.219178 0.013699         0.9722
 92:   Base May           6   arbitrum                        waves per day cents regime without Base gas-target steps    4.83333         1.333333  3.5000        59          5  0.81356    0.200000 0.016667         1.0000
 93:   Base May           6   arbitrum      log new addresses outside waves                                  all dates    0.05561         0.433708 -0.3781       130         10  0.01538    0.984733 0.007634         0.5769
 94:   Base May           6   arbitrum      log new addresses outside waves                              pre-cut dates    0.05561         0.433708 -0.3781        55          4  0.03636    0.964286 0.017857         0.8000
 95:   Base May           6   arbitrum      log new addresses outside waves                 cents regime (after 03-19)    0.05561         0.433708 -0.3781        72          6  0.02778    0.972603 0.013699         0.6111
 96:   Base May           6   arbitrum      log new addresses outside waves cents regime without Base gas-target steps    0.05561         0.433708 -0.3781        59          5  0.03390    0.966667 0.016667         0.7119
 97:   Base May           7   ethereum      log(1 + new addresses in waves)                                  all dates    1.76139        -1.293632  3.0550       124          9  0.91129    0.096000 0.008000         0.8145
 98:   Base May           7   ethereum      log(1 + new addresses in waves)                              pre-cut dates    1.76139        -1.293632  3.0550        53          4  1.00000    0.018519 0.018519         1.0000
 99:   Base May           7   ethereum      log(1 + new addresses in waves)                 cents regime (after 03-19)    1.76139        -1.293632  3.0550        68          5  1.00000    0.014493 0.014493         1.0000
100:   Base May           7   ethereum      log(1 + new addresses in waves) cents regime without Base gas-target steps    1.76139        -1.293632  3.0550        55          4  1.00000    0.017857 0.017857         1.0000
101:   Base May           7   ethereum same, without the largest wave group                                  all dates    1.73985        -1.144063  2.8839       124          9  0.92742    0.080000 0.008000         0.8871
102:   Base May           7   ethereum same, without the largest wave group                              pre-cut dates    1.73985        -1.144063  2.8839        53          4  1.00000    0.018519 0.018519         1.0000
103:   Base May           7   ethereum same, without the largest wave group                 cents regime (after 03-19)    1.73985        -1.144063  2.8839        68          5  1.00000    0.014493 0.014493         1.0000
104:   Base May           7   ethereum same, without the largest wave group cents regime without Base gas-target steps    1.73985        -1.144063  2.8839        55          4  1.00000    0.017857 0.017857         1.0000
105:   Base May           7   ethereum                        waves per day                                  all dates    5.14286        -3.714286  8.8571       124          9  0.99194    0.016000 0.008000         1.0000
106:   Base May           7   ethereum                        waves per day                              pre-cut dates    5.14286        -3.714286  8.8571        53          4  0.98113    0.037037 0.018519         1.0000
107:   Base May           7   ethereum                        waves per day                 cents regime (after 03-19)    5.14286        -3.714286  8.8571        68          5  0.98529    0.028986 0.014493         1.0000
108:   Base May           7   ethereum                        waves per day cents regime without Base gas-target steps    5.14286        -3.714286  8.8571        55          4  1.00000    0.017857 0.017857         1.0000
109:   Base May           7   ethereum      log new addresses outside waves                                  all dates    0.08835        -0.106501  0.1948       124          9  0.79032    0.216000 0.008000         0.6048
110:   Base May           7   ethereum      log new addresses outside waves                              pre-cut dates    0.08835        -0.106501  0.1948        53          4  0.83019    0.185185 0.018519         0.8113
111:   Base May           7   ethereum      log new addresses outside waves                 cents regime (after 03-19)    0.08835        -0.106501  0.1948        68          5  0.70588    0.304348 0.014493         0.6324
112:   Base May           7   ethereum      log new addresses outside waves cents regime without Base gas-target steps    0.08835        -0.106501  0.1948        55          4  0.80000    0.214286 0.017857         0.7273
113:   Base May           7   arbitrum      log(1 + new addresses in waves)                                  all dates    1.76139         0.697169  1.0642       124          9  0.59677    0.408000 0.008000         0.8145
114:   Base May           7   arbitrum      log(1 + new addresses in waves)                              pre-cut dates    1.76139         0.697169  1.0642        53          4  0.86792    0.148148 0.018519         1.0000
115:   Base May           7   arbitrum      log(1 + new addresses in waves)                 cents regime (after 03-19)    1.76139         0.697169  1.0642        68          5  0.82353    0.188406 0.014493         1.0000
116:   Base May           7   arbitrum      log(1 + new addresses in waves) cents regime without Base gas-target steps    1.76139         0.697169  1.0642        55          4  0.78182    0.232143 0.017857         1.0000
117:   Base May           7   arbitrum same, without the largest wave group                                  all dates    1.73985         0.443042  1.2968       124          9  0.72581    0.280000 0.008000         0.8871
118:   Base May           7   arbitrum same, without the largest wave group                              pre-cut dates    1.73985         0.443042  1.2968        53          4  0.88679    0.129630 0.018519         1.0000
119:   Base May           7   arbitrum same, without the largest wave group                 cents regime (after 03-19)    1.73985         0.443042  1.2968        68          5  0.83824    0.173913 0.014493         1.0000
120:   Base May           7   arbitrum same, without the largest wave group cents regime without Base gas-target steps    1.73985         0.443042  1.2968        55          4  0.80000    0.214286 0.017857         1.0000
121:   Base May           7   arbitrum                        waves per day                                  all dates    5.14286         1.000000  4.1429       124          9  0.94355    0.064000 0.008000         1.0000
122:   Base May           7   arbitrum                        waves per day                              pre-cut dates    5.14286         1.000000  4.1429        53          4  0.90566    0.111111 0.018519         1.0000
123:   Base May           7   arbitrum                        waves per day                 cents regime (after 03-19)    5.14286         1.000000  4.1429        68          5  0.91176    0.101449 0.014493         1.0000
124:   Base May           7   arbitrum                        waves per day cents regime without Base gas-target steps    5.14286         1.000000  4.1429        55          4  0.92727    0.089286 0.017857         1.0000
125:   Base May           7   arbitrum      log new addresses outside waves                                  all dates    0.08835         0.495276 -0.4069       124          9  0.02419    0.976000 0.008000         0.6048
126:   Base May           7   arbitrum      log new addresses outside waves                              pre-cut dates    0.08835         0.495276 -0.4069        53          4  0.05660    0.944444 0.018519         0.8113
127:   Base May           7   arbitrum      log new addresses outside waves                 cents regime (after 03-19)    0.08835         0.495276 -0.4069        68          5  0.04412    0.956522 0.014493         0.6324
128:   Base May           7   arbitrum      log new addresses outside waves cents regime without Base gas-target steps    0.08835         0.495276 -0.4069        55          4  0.05455    0.946429 0.017857         0.7273
129:   Base May          14   ethereum      log(1 + new addresses in waves)                                  all dates    1.87907        -0.741507  2.6206        82          5  0.79268    0.216867 0.012048         0.7073
130:   Base May          14   ethereum      log(1 + new addresses in waves)                              pre-cut dates    1.87907        -0.741507  2.6206        39          2  1.00000    0.025000 0.025000         1.0000
131:   Base May          14   ethereum      log(1 + new addresses in waves)                 cents regime (after 03-19)    1.87907        -0.741507  2.6206        40          3  1.00000    0.024390 0.024390         1.0000
132:   Base May          14   ethereum      log(1 + new addresses in waves) cents regime without Base gas-target steps    1.87907        -0.741507  2.6206        27          2  1.00000    0.035714 0.035714         1.0000
133:   Base May          14   ethereum same, without the largest wave group                                  all dates    1.67127        -0.666722  2.3380        82          5  0.79268    0.216867 0.012048         0.7683
134:   Base May          14   ethereum same, without the largest wave group                              pre-cut dates    1.67127        -0.666722  2.3380        39          2  1.00000    0.025000 0.025000         1.0000
135:   Base May          14   ethereum same, without the largest wave group                 cents regime (after 03-19)    1.67127        -0.666722  2.3380        40          3  1.00000    0.024390 0.024390         1.0000
136:   Base May          14   ethereum same, without the largest wave group cents regime without Base gas-target steps    1.67127        -0.666722  2.3380        27          2  1.00000    0.035714 0.035714         1.0000
137:   Base May          14   ethereum                        waves per day                                  all dates    5.42857        -2.214286  7.6429        82          5  1.00000    0.012048 0.012048         1.0000
138:   Base May          14   ethereum                        waves per day                              pre-cut dates    5.42857        -2.214286  7.6429        39          2  1.00000    0.025000 0.025000         1.0000
139:   Base May          14   ethereum                        waves per day                 cents regime (after 03-19)    5.42857        -2.214286  7.6429        40          3  1.00000    0.024390 0.024390         1.0000
140:   Base May          14   ethereum                        waves per day cents regime without Base gas-target steps    5.42857        -2.214286  7.6429        27          2  1.00000    0.035714 0.035714         1.0000
141:   Base May          14   ethereum      log new addresses outside waves                                  all dates    0.20941        -0.091602  0.3010        82          5  0.96341    0.048193 0.012048         0.7317
142:   Base May          14   ethereum      log new addresses outside waves                              pre-cut dates    0.20941        -0.091602  0.3010        39          2  0.94872    0.075000 0.025000         0.9487
143:   Base May          14   ethereum      log new addresses outside waves                 cents regime (after 03-19)    0.20941        -0.091602  0.3010        40          3  0.92500    0.097561 0.024390         0.9250
144:   Base May          14   ethereum      log new addresses outside waves cents regime without Base gas-target steps    0.20941        -0.091602  0.3010        27          2  0.96296    0.071429 0.035714         0.9630
145:   Base May          14   arbitrum      log(1 + new addresses in waves)                                  all dates    1.87907        -0.583085  2.4622        82          5  0.82927    0.180723 0.012048         0.7073
146:   Base May          14   arbitrum      log(1 + new addresses in waves)                              pre-cut dates    1.87907        -0.583085  2.4622        39          2  1.00000    0.025000 0.025000         1.0000
147:   Base May          14   arbitrum      log(1 + new addresses in waves)                 cents regime (after 03-19)    1.87907        -0.583085  2.4622        40          3  1.00000    0.024390 0.024390         1.0000
148:   Base May          14   arbitrum      log(1 + new addresses in waves) cents regime without Base gas-target steps    1.87907        -0.583085  2.4622        27          2  1.00000    0.035714 0.035714         1.0000
149:   Base May          14   arbitrum same, without the largest wave group                                  all dates    1.67127         0.404982  1.2663        82          5  0.71951    0.289157 0.012048         0.7683
150:   Base May          14   arbitrum same, without the largest wave group                              pre-cut dates    1.67127         0.404982  1.2663        39          2  1.00000    0.025000 0.025000         1.0000
151:   Base May          14   arbitrum same, without the largest wave group                 cents regime (after 03-19)    1.67127         0.404982  1.2663        40          3  1.00000    0.024390 0.024390         1.0000
152:   Base May          14   arbitrum same, without the largest wave group cents regime without Base gas-target steps    1.67127         0.404982  1.2663        27          2  1.00000    0.035714 0.035714         1.0000
153:   Base May          14   arbitrum                        waves per day                                  all dates    5.42857         0.785714  4.6429        82          5  1.00000    0.012048 0.012048         1.0000
154:   Base May          14   arbitrum                        waves per day                              pre-cut dates    5.42857         0.785714  4.6429        39          2  1.00000    0.025000 0.025000         1.0000
155:   Base May          14   arbitrum                        waves per day                 cents regime (after 03-19)    5.42857         0.785714  4.6429        40          3  1.00000    0.024390 0.024390         1.0000
156:   Base May          14   arbitrum                        waves per day cents regime without Base gas-target steps    5.42857         0.785714  4.6429        27          2  1.00000    0.035714 0.035714         1.0000
157:   Base May          14   arbitrum      log new addresses outside waves                                  all dates    0.20941         0.626619 -0.4172        82          5  0.03659    0.963855 0.012048         0.7317
158:   Base May          14   arbitrum      log new addresses outside waves                              pre-cut dates    0.20941         0.626619 -0.4172        39          2  0.07692    0.925000 0.025000         0.9487
159:   Base May          14   arbitrum      log new addresses outside waves                 cents regime (after 03-19)    0.20941         0.626619 -0.4172        40          3  0.07500    0.926829 0.024390         0.9250
160:   Base May          14   arbitrum      log new addresses outside waves cents regime without Base gas-target steps    0.20941         0.626619 -0.4172        27          2  0.11111    0.892857 0.035714         0.9630
161:   Base May          28   ethereum      log(1 + new addresses in waves)                                  all dates    1.68215        -0.504934  2.1871        25          2  0.44000    0.576923 0.038462         0.4400
162:   Base May          28   ethereum      log(1 + new addresses in waves)                              pre-cut dates    1.68215        -0.504934  2.1871        11          1  1.00000    0.083333 0.083333         1.0000
163:   Base May          28   ethereum      log(1 + new addresses in waves)                 cents regime (after 03-19)    1.68215        -0.504934  2.1871        11          1  1.00000    0.083333 0.083333         1.0000
164:   Base May          28   ethereum      log(1 + new addresses in waves) cents regime without Base gas-target steps    1.68215        -0.504934  2.1871         0          0      NaN    1.000000 1.000000            NaN
165:   Base May          28   ethereum same, without the largest wave group                                  all dates    1.49864        -0.146729  1.6454        25          2  0.44000    0.576923 0.038462         0.4400
166:   Base May          28   ethereum same, without the largest wave group                              pre-cut dates    1.49864        -0.146729  1.6454        11          1  1.00000    0.083333 0.083333         1.0000
167:   Base May          28   ethereum same, without the largest wave group                 cents regime (after 03-19)    1.49864        -0.146729  1.6454        11          1  1.00000    0.083333 0.083333         1.0000
168:   Base May          28   ethereum same, without the largest wave group cents regime without Base gas-target steps    1.49864        -0.146729  1.6454         0          0      NaN    1.000000 1.000000            NaN
169:   Base May          28   ethereum                        waves per day                                  all dates    5.25000        -0.392857  5.6429        25          2  1.00000    0.038462 0.038462         1.0000
170:   Base May          28   ethereum                        waves per day                              pre-cut dates    5.25000        -0.392857  5.6429        11          1  1.00000    0.083333 0.083333         1.0000
171:   Base May          28   ethereum                        waves per day                 cents regime (after 03-19)    5.25000        -0.392857  5.6429        11          1  1.00000    0.083333 0.083333         1.0000
172:   Base May          28   ethereum                        waves per day cents regime without Base gas-target steps    5.25000        -0.392857  5.6429         0          0      NaN    1.000000 1.000000            NaN
173:   Base May          28   ethereum      log new addresses outside waves                                  all dates    0.39779         0.003407  0.3944        25          2  1.00000    0.038462 0.038462         1.0000
174:   Base May          28   ethereum      log new addresses outside waves                              pre-cut dates    0.39779         0.003407  0.3944        11          1  1.00000    0.083333 0.083333         1.0000
175:   Base May          28   ethereum      log new addresses outside waves                 cents regime (after 03-19)    0.39779         0.003407  0.3944        11          1  1.00000    0.083333 0.083333         1.0000
176:   Base May          28   ethereum      log new addresses outside waves cents regime without Base gas-target steps    0.39779         0.003407  0.3944         0          0      NaN    1.000000 1.000000            NaN
177:   Base May          28   arbitrum      log(1 + new addresses in waves)                                  all dates    1.68215        -0.892930  2.5751        25          2  0.44000    0.576923 0.038462         0.4400
178:   Base May          28   arbitrum      log(1 + new addresses in waves)                              pre-cut dates    1.68215        -0.892930  2.5751        11          1  1.00000    0.083333 0.083333         1.0000
179:   Base May          28   arbitrum      log(1 + new addresses in waves)                 cents regime (after 03-19)    1.68215        -0.892930  2.5751        11          1  1.00000    0.083333 0.083333         1.0000
180:   Base May          28   arbitrum      log(1 + new addresses in waves) cents regime without Base gas-target steps    1.68215        -0.892930  2.5751         0          0      NaN    1.000000 1.000000            NaN
181:   Base May          28   arbitrum same, without the largest wave group                                  all dates    1.49864         0.112673  1.3860        25          2  0.44000    0.576923 0.038462         0.4400
182:   Base May          28   arbitrum same, without the largest wave group                              pre-cut dates    1.49864         0.112673  1.3860        11          1  1.00000    0.083333 0.083333         1.0000
183:   Base May          28   arbitrum same, without the largest wave group                 cents regime (after 03-19)    1.49864         0.112673  1.3860        11          1  1.00000    0.083333 0.083333         1.0000
184:   Base May          28   arbitrum same, without the largest wave group cents regime without Base gas-target steps    1.49864         0.112673  1.3860         0          0      NaN    1.000000 1.000000            NaN
185:   Base May          28   arbitrum                        waves per day                                  all dates    5.25000        -0.107143  5.3571        25          2  1.00000    0.038462 0.038462         1.0000
186:   Base May          28   arbitrum                        waves per day                              pre-cut dates    5.25000        -0.107143  5.3571        11          1  1.00000    0.083333 0.083333         1.0000
187:   Base May          28   arbitrum                        waves per day                 cents regime (after 03-19)    5.25000        -0.107143  5.3571        11          1  1.00000    0.083333 0.083333         1.0000
188:   Base May          28   arbitrum                        waves per day cents regime without Base gas-target steps    5.25000        -0.107143  5.3571         0          0      NaN    1.000000 1.000000            NaN
189:   Base May          28   arbitrum      log new addresses outside waves                                  all dates    0.39779         0.908569 -0.5108        25          2  0.00000    1.000000 0.038462         1.0000
190:   Base May          28   arbitrum      log new addresses outside waves                              pre-cut dates    0.39779         0.908569 -0.5108        11          1  0.00000    1.000000 0.083333         1.0000
191:   Base May          28   arbitrum      log new addresses outside waves                 cents regime (after 03-19)    0.39779         0.908569 -0.5108        11          1  0.00000    1.000000 0.083333         1.0000
192:   Base May          28   arbitrum      log new addresses outside waves cents regime without Base gas-target steps    0.39779         0.908569 -0.5108         0          0      NaN    1.000000 1.000000            NaN
            cut window_days comparison                              outcome                                    placebo shift_base shift_comparison    diff placebo_K disjoint_K pct_diff p_one_sided  p_floor pct_base_alone
## J. Base May: waves per day relative to the reference days (Base alone, minus L1, minus Arbitrum), with a band from cents-regime placebo dates
     reference comparison   k      e placebo_K     lo    hi
  1: c-14..c-1   arbitrum -14 3.2143        34 -5.696 4.646
  2: c-14..c-1   arbitrum -14 3.2143        34 -5.696 4.646
  3: c-14..c-1   arbitrum -13 0.2143        34 -5.411 5.146
  4: c-14..c-1   arbitrum -13 0.2143        34 -5.411 5.146
  5: c-14..c-1   arbitrum -12 1.2143        34 -5.239 5.043
 ---                                                       
428: c-28..c-8       none  19 2.0952        20 -3.683 1.767
429: c-28..c-8       none  20 4.0952        20 -4.274 1.581
430: c-28..c-8       none  20 4.0952        20 -4.274 1.581
431: c-28..c-8       none  21 6.0952        20 -4.283 1.393
432: c-28..c-8       none  21 6.0952        20 -4.283 1.393
## J. Waves per day on the three chains, 05-14..06-11 (step days 05-28 and 05-30)
           day arbitrum base ethereum
 1: 2024-05-14        4    7        3
 2: 2024-05-15        5    5        4
 3: 2024-05-16        3    4        4
 4: 2024-05-17        6    5        5
 5: 2024-05-18        7    6       12
 6: 2024-05-19        4    4        9
 7: 2024-05-20        2    5        8
 8: 2024-05-21        4    2        7
 9: 2024-05-22        5    7        5
10: 2024-05-23        3    7        5
11: 2024-05-24        3    5        6
12: 2024-05-25        6    2       13
13: 2024-05-26        6    1       10
14: 2024-05-27        8    3        8
15: 2024-05-28        8    7        4
16: 2024-05-29        8   10        8
17: 2024-05-30        5    8        3
18: 2024-05-31        8    7        7
19: 2024-06-01        9    6        3
20: 2024-06-02        6    5        4
21: 2024-06-03        5   10        4
22: 2024-06-04        6   11        3
23: 2024-06-05        5   15        4
24: 2024-06-06        3    9        3
25: 2024-06-07        3    7        4
26: 2024-06-08        3    8        6
27: 2024-06-09        6    8        6
28: 2024-06-10        5   11        6
29: 2024-06-11        7   12        3
           day arbitrum base ethereum
## L. Non-burst entry on Base, daily means after vs before each cut (equal windows), 95% day-bootstrap intervals; the last row is the composition deflator
           cut     days                                             measure days_before days_after before after    ratio      lo       hi
 1: Base March all days                                           addresses           6          6  17959 28928  1.61075  1.5120  1.69983
 2: Base March all days                                            entities           6          6  13063 18027  1.38000  1.2746  1.49136
 3: Base March all days                         entities_not_service_funded           6          6   4792  7084  1.47842  1.4013  1.56012
 4: Base March all days                               entities_active_later           6          6   2269  3002  1.32303  1.1949  1.47604
 5: Base March all days                                               alone           6          6  10577 14230  1.34535  1.2264  1.46646
 6: Base March all days deflator: log(entities / addresses), after - before           6          6     NA    NA -0.15462 -0.2021 -0.11057
 7: Base March weekdays                                           addresses           4          4  17710 28767  1.62436  1.4966  1.74312
 8: Base March weekdays                                            entities           4          4  12671 18327  1.44636  1.3124  1.61027
 9: Base March weekdays                         entities_not_service_funded           4          4   4642  7133  1.53646  1.4603  1.63719
10: Base March weekdays                               entities_active_later           4          4   2250  3112  1.38300  1.1967  1.60207
11: Base March weekdays                                               alone           4          4  10239 14425  1.40880  1.2552  1.58194
12: Base March weekdays deflator: log(entities / addresses), after - before           4          4     NA    NA -0.11606 -0.1564 -0.07373
13:   Base May all days                                           addresses           5          5  41935 42766  1.01982  0.9572  1.07782
14:   Base May all days                                            entities           5          5  22542 20584  0.91312  0.8268  1.00842
15:   Base May all days                         entities_not_service_funded           5          5   9470  7955  0.83994  0.7473  0.94598
16:   Base May all days                               entities_active_later           5          5   3598  2946  0.81859  0.7110  0.95907
17:   Base May all days                                               alone           5          5  16800 15675  0.93307  0.8164  1.05719
18:   Base May all days deflator: log(entities / addresses), after - before           5          5     NA    NA -0.11051 -0.1837 -0.03206
19:   Base May weekdays                                           addresses           3          3  42162 43290  1.02675  1.0013  1.05282
20:   Base May weekdays                                            entities           3          3  22513 21853  0.97067  0.9038  1.05076
21:   Base May weekdays                         entities_not_service_funded           3          3  10358  8244  0.79591  0.7404  0.85052
22:   Base May weekdays                               entities_active_later           3          3   3492  3152  0.90282  0.7401  1.10129
23:   Base May weekdays                                               alone           3          3  16458 16877  1.02544  0.9283  1.14358
24:   Base May weekdays deflator: log(entities / addresses), after - before           3          3     NA    NA -0.05617 -0.1191  0.03226
           cut     days                                             measure days_before days_after before after    ratio      lo       hi
## L. Implied entity effect = L1-differenced 6- or 7-day address effect outside waves x exp(deflator) (interval from the deflator only)
          cut deflator    d_lo     d_hi window_days address_effect address_pct_precut implied_entity_effect implied_lo implied_hi
1: Base March  -0.1546 -0.2021 -0.11057           6          1.572             1.0000                 1.346     1.2841      1.407
2: Base March  -0.1546 -0.2021 -0.11057           7          1.641             1.0000                 1.406     1.3407      1.469
3:   Base May  -0.1105 -0.1837 -0.03206           6          1.154             0.8182                 1.034     0.9607      1.118
4:   Base May  -0.1105 -0.1837 -0.03206           7          1.215             0.8302                 1.088     1.0112      1.177
## M1. Base March headline numbers from one sample at a time (counted new accounts, entry outside batches, batch share of the added accounts)
                                   sample       window                             rule all_before all_after all_ratio outside_ratio batch_share_of_added
1:     long series (60-day new addresses)   6 v 6 days       waves (recipient x method)      23387    162328     6.941         1.690               0.8979
2:     long series (60-day new addresses)   7 v 7 days       waves (recipient x method)      24239    157481     6.497         1.759               0.8812
3:     long series (60-day new addresses) 14 v 14 days       waves (recipient x method)      23687    111187     4.694         2.161               0.7365
4:     long series (60-day new addresses) 28 v 28 days       waves (recipient x method)      24625    110296     4.479         3.027               0.5566
5: window entrants (never active on Base)   6 v 6 days                  main burst rule      19670    145230     7.383         1.611               0.9098
6: window entrants (never active on Base)   6 v 6 days       size only (>= 5,000 a day)      19670    145230     7.383         1.900               0.8642
7: window entrants (never active on Base)   6 v 6 days burst funded by bursting funders      19670    145230     7.383         1.973               0.8534
8: window entrants (never active on Base)   6 v 6 days           same, pre-entry funder      19670    145230     7.383         1.930               0.8625
## M2. Inference for the primary statistic (shift outside waves, Base minus L1, over the 6 low-fee days), 7 days, the 4- and 5-day path, and without 03-19
                                                              statistic window window_days       placebo estimate ratio placebo_K   rank_p disjoint_K
 1:                  6 v 6 days, log entry outside waves, Base minus L1  6 v 6           6 pre-cut dates   0.4521 1.572        61 0.016129          6
 2:                  6 v 6 days, log entry outside waves, Base minus L1  6 v 6           6     all dates   0.4521 1.572       139 0.021429         13
 3:                  7 v 7 days, log entry outside waves, Base minus L1  7 v 7           7 pre-cut dates   0.4953 1.641        59 0.016667          5
 4:                  7 v 7 days, log entry outside waves, Base minus L1  7 v 7           7     all dates   0.4953 1.641       133 0.007463         11
 5:                  4 v 4 days, log entry outside waves, Base minus L1  4 v 4           4 pre-cut dates   0.3703 1.448        65 0.045455          9
 6:                  4 v 4 days, log entry outside waves, Base minus L1  4 v 4           4     all dates   0.3703 1.448       151 0.039474         20
 7:                  5 v 5 days, log entry outside waves, Base minus L1  5 v 5           5 pre-cut dates   0.4045 1.499        63 0.015625          7
 8:                  5 v 5 days, log entry outside waves, Base minus L1  5 v 5           5     all dates   0.4045 1.499       145 0.020548         16
 9: 6 v 5 days (03-19 left out), log entry outside waves, Base minus L1  6 v 5           5 pre-cut dates   0.4058 1.500        62 0.015873          6
10: 6 v 5 days (03-19 left out), log entry outside waves, Base minus L1  6 v 5           5     all dates   0.4058 1.500       142 0.027972         14
                                                                                                                  disjoint_values placebo_max placebo_mean placebo_sd z_placebo base_alone base_alone_rank_p
 1:                                                                                           0.13, 0.19, 0.26, -0.09, 0.16, 0.16      0.3120      0.02847     0.1351     3.136     0.5214          0.016129
 2:                                              0.13, 0.19, 0.26, -0.09, 0.16, 0.16, 0.21, 0.13, -0.02, -0.07, -0.22, 0.15, 0.16      0.4716      0.04062     0.1588     2.591     0.5214          0.021429
 3:                                                                                                 0.13, 0.23, 0.05, 0.12, -0.10      0.3172      0.02993     0.1277     3.645     0.5549          0.016667
 4:                                                          0.13, 0.23, 0.05, 0.12, -0.10, 0.27, -0.13, -0.01, -0.13, 0.14, 0.41      0.4748      0.04025     0.1662     2.738     0.5549          0.014925
 5:                                                                       0.09, 0.04, 0.36, 0.22, -0.12, -0.15, 0.04, -0.29, 0.05      0.3955      0.02547     0.1593     2.165     0.4849          0.015152
 6: 0.09, 0.04, 0.36, 0.22, -0.12, -0.15, 0.04, -0.29, 0.05, 0.02, 0.18, -0.04, 0.06, -0.05, -0.01, -0.11, 0.12, 0.17, 0.37, 0.30      0.4366      0.03472     0.1561     2.150     0.4849          0.006579
 7:                                                                                   0.16, -0.07, -0.10, 0.04, -0.05, 0.16, 0.20      0.3303      0.02784     0.1446     2.605     0.5091          0.015625
 8:                        0.16, -0.07, -0.10, 0.04, -0.05, 0.16, 0.20, 0.10, 0.17, -0.15, -0.03, -0.01, -0.17, 0.18, -0.01, 0.28      0.4217      0.03952     0.1533     2.382     0.5091          0.013699
 9:                                                                                        0.14, -0.08, -0.02, -0.09, 0.09, -0.30      0.3346      0.02775     0.1405     2.690     0.5049          0.015873
10:                                    0.14, -0.08, -0.02, -0.09, 0.09, -0.30, 0.17, 0.14, -0.04, -0.01, -0.23, 0.09, 0.16, -0.02      0.4685      0.04003     0.1567     2.334     0.5049          0.013986
## M2. The cut and the largest all-dates placebos: Base minus L1, Base alone, L1 alone, before-window slope, and the dated events inside their windows
    window_days      start   cut      d base_alone l1_alone slope_before
 1:           6 2024-03-14  TRUE 0.4521     0.5214  0.06928    -0.001576
 2:           6 2024-06-22 FALSE 0.4716     0.5542  0.08258     0.102538
 3:           6 2024-06-23 FALSE 0.4632     0.4210 -0.04216     0.123498
 4:           6 2024-06-21 FALSE 0.3925     0.5567  0.16417     0.046323
 5:           6 2024-06-24 FALSE 0.3688     0.2942 -0.07460     0.020055
 6:           6 2024-03-30 FALSE 0.3294     0.2156 -0.11381     0.049673
 7:           6 2024-03-29 FALSE 0.3155     0.2033 -0.11223     0.043463
 8:           7 2024-03-14  TRUE 0.4953     0.5549  0.05965    -0.012354
 9:           7 2024-06-24 FALSE 0.4748     0.4070 -0.06775     0.081514
10:           7 2024-06-22 FALSE 0.4551     0.5441  0.08907     0.050021
11:           7 2024-06-23 FALSE 0.4220     0.4115 -0.01047     0.089443
12:           7 2024-06-21 FALSE 0.4090     0.5570  0.14800     0.005454
13:           7 2024-03-30 FALSE 0.3555     0.2415 -0.11400     0.042285
14:           7 2024-06-20 FALSE 0.3545     0.5268  0.17234    -0.039254
                                                                                                                                                                                                                                                                                                                                          events_in_window
 1: 03-13 Dencun upgrade on Ethereum L1 (EIP-4844 blobs) | 03-14 Bitcoin all-time high (about US$73.7k) | 03-14 Ecotone upgrade on Base and OP Mainnet (L1 data fee priced f | 03-14 ArbOS 20 Atlas on Arbitrum One (blob pricing) | 03-19 Base fee revenue reaches a daily record of about US$1.67 mil | 03-19 Arbitrum minimum base fee 0.1 -> 0.01 gwei
 2:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
 3:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
 4:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
 5:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
 6:                                                                                                                                 03-26 Base gas target 2.5 -> 3.75 Mgas/s | 03-26 Base deposits near US$1 billion (about double the start of M | 03-26 Base memecoins (TOSHI; TYBG; NORMIE; BRETT) up as much as 13 | 04-01 Base gas target -> 5 Mgas/s
 7:                                                                                                                                 03-26 Base gas target 2.5 -> 3.75 Mgas/s | 03-26 Base deposits near US$1 billion (about double the start of M | 03-26 Base memecoins (TOSHI; TYBG; NORMIE; BRETT) up as much as 13 | 04-01 Base gas target -> 5 Mgas/s
 8: 03-13 Dencun upgrade on Ethereum L1 (EIP-4844 blobs) | 03-14 Bitcoin all-time high (about US$73.7k) | 03-14 Ecotone upgrade on Base and OP Mainnet (L1 data fee priced f | 03-14 ArbOS 20 Atlas on Arbitrum One (blob pricing) | 03-19 Base fee revenue reaches a daily record of about US$1.67 mil | 03-19 Arbitrum minimum base fee 0.1 -> 0.01 gwei
 9:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
10:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
11:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
12:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
13:                                                                                                                                 03-26 Base gas target 2.5 -> 3.75 Mgas/s | 03-26 Base deposits near US$1 billion (about double the start of M | 03-26 Base memecoins (TOSHI; TYBG; NORMIE; BRETT) up as much as 13 | 04-01 Base gas target -> 5 Mgas/s
14:                                                                                                                                                                                                                                                                                                    06-20 LayerZero ZRO airdrop claims open (7 a.m. ET)
## M2b. The primary statistic, the breakdown and the implied entity effect across wave and burst size floors (Base minus L1)
    wave_size_floor window_days       placebo estimate ratio placebo_K rank   rank_p placebo_max wave_share_of_added_6v6 nonburst_ratio_6v6 entity_ratio_6v6 deflator implied_entity_effect
 1:              50           6 pre-cut dates   0.3805 1.463        61    1 0.016129      0.2502                  0.9308              1.341            1.253 -0.06774                 1.367
 2:              50           6     all dates   0.3805 1.463       139    4 0.028571      0.5229                  0.9308              1.341            1.253 -0.06774                 1.367
 3:              50           7 pre-cut dates   0.4271 1.533        59    1 0.016667      0.2103                  0.9308              1.341            1.253 -0.06774                 1.432
 4:              50           7     all dates   0.4271 1.533       133    5 0.037313      0.5073                  0.9308              1.341            1.253 -0.06774                 1.432
 5:             100           6 pre-cut dates   0.4017 1.494        61    1 0.016129      0.2349                  0.9248              1.392            1.278 -0.08569                 1.372
 6:             100           6     all dates   0.4017 1.494       139    4 0.028571      0.5209                  0.9248              1.392            1.278 -0.08569                 1.372
 7:             100           7 pre-cut dates   0.4477 1.565        59    1 0.016667      0.2086                  0.9248              1.392            1.278 -0.08569                 1.436
 8:             100           7     all dates   0.4477 1.565       133    4 0.029851      0.5084                  0.9248              1.392            1.278 -0.08569                 1.436
 9:             250           6 pre-cut dates   0.4122 1.510        61    1 0.016129      0.2381                  0.9172              1.475            1.318 -0.11245                 1.350
10:             250           6     all dates   0.4122 1.510       139    3 0.021429      0.5030                  0.9172              1.475            1.318 -0.11245                 1.350
11:             250           7 pre-cut dates   0.4578 1.581        59    1 0.016667      0.2268                  0.9172              1.475            1.318 -0.11245                 1.413
12:             250           7     all dates   0.4578 1.581       133    3 0.022388      0.4969                  0.9172              1.475            1.318 -0.11245                 1.413
13:             500           6 pre-cut dates   0.4344 1.544        61    1 0.016129      0.2671                  0.9078              1.545            1.356 -0.13064                 1.355
14:             500           6     all dates   0.4344 1.544       139    3 0.021429      0.4835                  0.9078              1.545            1.356 -0.13064                 1.355
15:             500           7 pre-cut dates   0.4754 1.609        59    1 0.016667      0.2631                  0.9078              1.545            1.356 -0.13064                 1.412
16:             500           7     all dates   0.4754 1.609       133    2 0.014925      0.4777                  0.9078              1.545            1.356 -0.13064                 1.412
17:            1000           6 pre-cut dates   0.4521 1.572        61    1 0.016129      0.3120                  0.8979              1.611            1.380 -0.15462                 1.346
18:            1000           6     all dates   0.4521 1.572       139    3 0.021429      0.4716                  0.8979              1.611            1.380 -0.15462                 1.346
19:            1000           7 pre-cut dates   0.4953 1.641        59    1 0.016667      0.3172                  0.8979              1.611            1.380 -0.15462                 1.406
20:            1000           7     all dates   0.4953 1.641       133    1 0.007463      0.4748                  0.8979              1.611            1.380 -0.15462                 1.406
21:            2000           6 pre-cut dates   0.5276 1.695        61    1 0.016129      0.3566                  0.8665              1.741            1.449 -0.18413                 1.410
22:            2000           6     all dates   0.5276 1.695       139    1 0.007143      0.4357                  0.8665              1.741            1.449 -0.18413                 1.410
23:            2000           7 pre-cut dates   0.5694 1.767        59    1 0.016667      0.3572                  0.8665              1.741            1.449 -0.18413                 1.470
24:            2000           7     all dates   0.5694 1.767       133    1 0.007463      0.4217                  0.8665              1.741            1.449 -0.18413                 1.470
25:            5000           6 pre-cut dates   0.5773 1.781        61    1 0.016129      0.3290                  0.8371              1.900            1.520 -0.22264                 1.426
26:            5000           6     all dates   0.5773 1.781       139    1 0.007143      0.4403                  0.8371              1.900            1.520 -0.22264                 1.426
27:            5000           7 pre-cut dates   0.6382 1.893        59    1 0.016667      0.3249                  0.8371              1.900            1.520 -0.22264                 1.515
28:            5000           7     all dates   0.6382 1.893       133    1 0.007463      0.4281                  0.8371              1.900            1.520 -0.22264                 1.515
29:           10000           6 pre-cut dates   0.6589 1.933        61    1 0.016129      0.3716                  0.7812              2.037            1.529 -0.28649                 1.451
30:           10000           6     all dates   0.6589 1.933       139    1 0.007143      0.5558                  0.7812              2.037            1.529 -0.28649                 1.451
31:           10000           7 pre-cut dates   0.6989 2.011        59    1 0.016667      0.3161                  0.7812              2.037            1.529 -0.28649                 1.510
32:           10000           7     all dates   0.6989 2.011       133    1 0.007463      0.5684                  0.7812              2.037            1.529 -0.28649                 1.510
    wave_size_floor window_days       placebo estimate ratio placebo_K rank   rank_p placebo_max wave_share_of_added_6v6 nonburst_ratio_6v6 entity_ratio_6v6 deflator implied_entity_effect
## M3. Base window entrants by class, 6 days before vs 6 days after the cut (03-08..13 vs 03-14..19)
     class3 entities_before entities_after entrants_before entrants_after in_cluster_20 same_block_group months_active_of3 layerzero_list other_l2_address other_l2_funder tokens_after eth_after top10_share top100_share top_recipient_share
1:      bot           49.83          168.5           94.17          450.8        0.6362          0.03993           0.28244       0.003327         0.063216         0.05074       0.9116   0.58669      0.5597       0.6813             0.12126
2: campaign          240.67         3661.2         1616.67       115852.0        0.9531          0.73372           0.01973       0.001181         0.004727         0.02262       0.8845   0.02803      0.5232       0.8834             0.88004
3:  genuine        13062.83        18026.7        17959.00        28927.5        0.3038          0.06154           0.17857       0.041085         0.075361         0.05906       0.5509   0.27977      0.2144       0.2779             0.08295
   entrant_ratio entity_ratio share_after share_of_added
1:         4.788        3.381    0.003104       0.002841
2:        71.661       15.213    0.797712       0.909803
3:         1.611        1.380    0.199184       0.087356
## N1. The cut hour: RD with RI over fake hours before the cut only
                        event                        outcome estimate      se ri_p_precut n_fake  p_floor          fakes_from            fakes_to
 1:            Base (Ecotone)                    new senders  0.81715 0.15033     0.03960    100 0.009901 2024-02-16 12:00:00 2024-03-12 06:00:00
 2:            Base (Ecotone) entrants at never-burst groups  0.30927 0.10092     0.07692     12 0.076923 2024-03-09 12:00:00 2024-03-12 06:00:00
 3:            Base (Ecotone)   funding entities (non-burst)  0.32296 0.12783     0.07692     12 0.076923 2024-03-09 12:00:00 2024-03-12 06:00:00
 4:           Arbitrum step 1                    new senders  0.54135 0.10273     0.01980    100 0.009901 2024-02-16 12:00:00 2024-03-12 06:00:00
 5:           Arbitrum step 1 entrants at never-burst groups  0.54846 0.10486     0.07692     12 0.076923 2024-03-09 12:00:00 2024-03-12 06:00:00
 6:           Arbitrum step 1   funding entities (non-burst)  0.48008 0.07153     0.07692     12 0.076923 2024-03-09 12:00:00 2024-03-12 06:00:00
 7:           Arbitrum step 2                    new senders  0.04670 0.15766     0.79630    107 0.009259 2024-02-16 12:00:00 2024-03-17 18:00:00
 8:           Arbitrum step 2 entrants at never-burst groups  0.18131 0.09707     0.25000     19 0.050000 2024-03-09 12:00:00 2024-03-17 18:00:00
 9:           Arbitrum step 2   funding entities (non-burst)  0.11159 0.11322     0.20000     19 0.050000 2024-03-09 12:00:00 2024-03-17 18:00:00
10: Base gas limit 60M to 75M                    new senders  0.59734 0.25229     0.04082     48 0.020408 2024-05-15 12:00:00 2024-05-27 06:00:00
11: Base gas limit 60M to 75M entrants at never-burst groups  0.68447 0.23365     0.04762     20 0.047619 2024-05-22 12:00:00 2024-05-27 06:00:00
12: Base gas limit 60M to 75M   funding entities (non-burst)  0.40749 0.12435     0.04762     20 0.047619 2024-05-22 12:00:00 2024-05-27 06:00:00
13: Base gas limit 75M to 90M                    new senders -0.55292 0.16941     0.04082     48 0.020408 2024-05-15 12:00:00 2024-05-27 06:00:00
14: Base gas limit 75M to 90M entrants at never-burst groups  0.10258 0.04534     0.09524     20 0.047619 2024-05-22 12:00:00 2024-05-27 06:00:00
15: Base gas limit 75M to 90M   funding entities (non-burst)  0.02477 0.04962     0.85714     20 0.047619 2024-05-22 12:00:00 2024-05-27 06:00:00
## N2. The 50 most common first recipients of non-burst entrants after the cut (62% of them): entrants per day, 6 days before vs after
                                      first_to rank                              name_tag           category                                         first_call    before   after     ratio
 1: 0xfd92f4e91d54b9ef91cc3f97c011a6af0c2a7eda    1                                   OKX           exchange                                       ETH transfer 1842.3333 2399.50    1.3024
 2: 0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad    2             Uniswap: Universal Router         dex router                                            execute 1150.3333 1816.67    1.5793
 3: 0x833589fcd6edb6e08f4c7c32d4f71b54bda02913    3                    Circle: USDC Token stablecoin or WETH                                           transfer 1773.1667 1596.50    0.9004
 4: 0x50b6ebc2103bfec165949cc946d739d5650d7ae4    4                   Stargate: RouterETH             bridge                                            swapETH  924.0000 1590.00    1.7208
 5: 0xd9aaec86b65d86f6a7b5b1b0c42ffa531710b6ca    5                     Base: USDbC Token stablecoin or WETH                                            approve  418.6667  572.83    1.3682
 6: 0x0389879e0156033202c44bf784ac18fc02edee4f    6                Sushi: RouteProcessor4     dex aggregator                                       processRoute  494.5000  561.67    1.1358
 7: 0xf70da97812cb96acdf810712aa562db8dfa3dbef    7                         Relay: Solver             bridge                     ETH transfer with request data  170.1667  553.50    3.2527
 8: 0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24    8                 Uniswap: V2 Router 02         dex router swapExactETHForTokensSupportingFeeOnTransferTokens  447.3333  537.50    1.2016
 9: 0xafb89a09d82fbde58f18ac6437b3fc81724e4df6    9               The Doge NFT: DOG Token        other token                                            approve   63.8333  483.17    7.5692
10: 0xdef1c0ded9bec7f1a1670819833240f027b25eff   10                    0x: Exchange Proxy     dex aggregator                                     transformERC20  306.1667  446.67    1.4589
11: 0x3304e22ddaa22bcdc5fca2269b418046ae7b566a   11                            Binance 73           exchange                                       ETH transfer  310.1667  442.50    1.4267
12: 0x28e43bb3ee202e1da587c88b0a8398309e8d4c2d   12                      BLOBz Base (NFT)  nft mint or claim                                               mint    0.1667  380.50 2283.0000
13: 0xecb03b9a0e7f7b5e261d3ef752865af6621a54fe   13              Sigma trading bot router        trading bot                                           SigmaBuy   13.8333  320.00   23.1325
14: 0xbaed383ede0e5d9d72430661f3285daa77e9439f   14                   Bybit: Hot Wallet 6           exchange                                       ETH transfer  150.6667  300.83    1.9967
15: 0x18dd5b087bca9920562aff7a0199b96b9230438b   15                     Propy (PRO) Token        other token                                           transfer   35.6667  300.33    8.4206
16: 0xe4edb277e41dc89ab076a1f049f4a3efa700bce8   16             Orbiter Finance: Bridge 2             bridge                                       ETH transfer  127.5000  295.00    2.3137
17: 0x19ceead7105607cd444f5ad10dd51356436095a1   17                       Odos: Router V2     dex aggregator                                        swapCompact  189.0000  287.00    1.5185
18: 0x3a23f943181408eac424116af7b7790c94cb97a5   18                       Socket: Gateway             bridge                                 gateway route call  164.5000  265.17    1.6120
19: 0x1b1d2149d656f8ca33fb633e6f642b5a2426b53d   19                 ChangeNOW: Hot Wallet           exchange                                       ETH transfer  192.6667  256.50    1.3313
20: 0x80c67432656d59144ceff962e8faf8926599bcf8   20             Orbiter Finance: Bridge 1             bridge                                       ETH transfer  146.0000  243.00    1.6644
21: 0x4200000000000000000000000000000000000006   21                  Wrapped Ether (WETH) stablecoin or WETH                                            deposit  156.8333  233.17    1.4867
22: 0x1195cf65f83b3a5768f3c496d3a05ad6412c64b7   22       Layer3: CUBE (quest credential)  nft mint or claim                                          mint call   82.3333  213.00    2.5870
23: 0x739120ade7ed878fca5bbdb806263a8258fe2360   23                           Coinbase 22           exchange                                       ETH transfer   75.1667  210.83    2.8049
24: 0x3f433f14e6ace35bd11c6a8c6d8875daa68c6a80   24                             Box (NFT)  nft mint or claim                                               mint    0.1667  206.83 1241.0000
25: 0x2f59e9086ec8130e21bd052065a9e6b2497bb102   25      unverified proxy (depositNative)       unidentified                                      depositNative   98.8333  179.17    1.8128
26: 0xe3b53af74a4bf62ae5511055290838050bf764df   26                   Stargate: STG Token             bridge                                         sendTokens  109.0000  178.00    1.6330
27: 0x20fe51a9229eef2cf8ad9e89d91cab9312cf3b7a   27                           Coinbase 14           exchange                                       ETH transfer   64.0000  177.33    2.7708
28: 0x6131b5fae19ea4f9d964eac0408e4408b66337b5   28 KyberSwap: Meta Aggregation Router v2     dex aggregator                                               swap  167.3333  167.67    1.0020
29: 0x1d6b183bd47f914f9f1d3208edcf8befd7f84e63   29         COIN Earnings (thirdweb drop)  nft mint or claim                                              claim   98.1667  165.00    1.6808
30: 0x47fbe95e981c0df9737b6971b451fb15fdc989d9   30                 Dmail (messaging app)                app                                          send_mail   47.0000  156.67    3.3333
31: 0xb4807865a786e9e9e26e6a9610f2078e7fc507fb   31                           Coinbase 36           exchange                                       ETH transfer   76.0000  155.17    2.0417
32: 0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae   32                        LI.FI: Diamond             bridge                                bridge or swap call   77.1667  153.50    1.9892
33: 0x542ffb7d78d78f957895891b6798b3d60e979b64   33              unverified proxy (claim)  nft mint or claim                                              claim    0.0000  151.17       Inf
34: 0x6dcbce46a8b494c885d0e7b6817d2b519df64467   34                           Coinbase 25           exchange                                       ETH transfer   76.3333  142.00    1.8603
35: 0x1985ea6e9c68e1c272d8209f3b478ac2fdb25c87   35                           Coinbase 35           exchange                                       ETH transfer   74.0000  138.83    1.8761
36: 0xcf77a3ba9a5ca399b7c97c74d54e5b1beb874e43   36                     Aerodrome: Router         dex router                              swapExactETHForTokens  268.3333  130.67    0.4870
37: 0xc9df8c29336f9d5027187f5e56cc1689a40d54f1   37                      unverified proxy       unidentified                                     unknown method    1.6667  130.00   78.0000
38: 0xd34ea7278e6bd48defe656bbe263aef11101469c   38                           Coinbase 27           exchange                                       ETH transfer   81.8333  129.50    1.5825
39: 0x327df1e6de05895d2ab08513aadd9313fe505d86   39              PancakeSwap: Router (V2)         dex router                              swapExactETHForTokens   26.8333  126.33    4.7081
40: 0x26bbea7803dcac346d5f5f135b57cf2c752a02be   40  Manifold: ERC1155 Lazy Payable Claim  nft mint or claim                                          mintBatch    4.0000  125.67   31.4167
41: 0x1111111254eeb25477b68fb85ed929f73a960582   41          1inch: Aggregation Router V5     dex aggregator                                               swap   81.8333  123.50    1.5092
42: 0x68f216bde507f6ce6c66955d1b4216a402e94cf3   42               Pike it Up! (PIU) Token  nft mint or claim                                        claimTokens    0.0000  122.50       Inf
43: 0x4869892c8088d9057ad7d0e5189ae8c3278f8877   43                      unverified proxy       unidentified                                     unknown method   23.1667  120.67    5.2086
44: 0x69460570c93f9de5e2edbc3052bf10125f0ca22d   44                        Rango: Diamond             bridge                                     stargateBridge   19.0000   95.83    5.0439
45: 0x532f27101965dd16442e59d40670faf5ebb142e4   45                    Brett: BRETT Token        other token                                           transfer   52.0000   93.00    1.7885
46: 0x4e3ae00e8323558fa5cac04b152238924aa31b60   46                               MEXC 15           exchange                                       ETH transfer    0.0000   90.00       Inf
47: 0x678aa4bf4e210cf2166753e054d5b7c31cc7fa86   47             PancakeSwap: Smart Router         dex router                                          multicall  194.8333   88.67    0.4551
48: 0xb3da098a7251a647892203e0c256b4398d131a54   48                    Mint A Penny (NFT)  nft mint or claim                                               mint   53.0000   87.50    1.6509
49: 0x7ed613ab8b2b4c6a781ddc97ea98a666c6437511   49              All Your Base: AYB Token        other token                                           transfer    0.3333   84.67  254.0000
50: 0xc32d8100756ff66cb2a9121463183c2bb18ad9a4   50         untagged account without code       unidentified                                       ETH transfer    0.0000   82.00       Inf
                                      first_to rank                              name_tag           category                                         first_call    before   after     ratio
## N2. Non-burst entrants per day by the category of their first recipient (the 50 named; boom-type recipients together), 6 days before vs after
                                  category   before   after entities_before entities_after  ratio entity_ratio share_of_increase share_of_entity_increase single_tx_after
 1:                       other recipients  7029.17 11019.8         4864.83        5968.33  1.568       1.2268          0.363830                 0.222308          0.4027
 2:                                 bridge  1737.33  3374.0         1642.83        3189.50  1.942       1.9415          0.149215                 0.311587          0.5661
 3:                               exchange  2943.17  4443.0         2765.00        4032.33  1.510       1.4583          0.136740                 0.255313          0.9157
 4:                      nft mint or claim   237.83  1452.2          212.33         758.50  6.106       3.5722          0.110711                 0.110029          0.3719
 5:                            other token   151.83   961.2           97.00         357.00  6.330       3.6804          0.073787                 0.052379          0.1760
 6:                             dex router  2087.67  2699.8         1233.67        1335.00  1.293       1.0821          0.055811                 0.020414          0.1024
 7:                           unidentified   123.67   511.8          102.00         242.50  4.139       2.3775          0.035389                 0.028305          0.3478
 8:                         dex aggregator  1238.83  1586.5         1078.17        1393.00  1.281       1.2920          0.031697                 0.063425          0.2041
 9:                            trading bot    13.83   320.0            3.50          46.33 23.133      13.2381          0.027913                 0.008629          0.0000
10:                                    app    47.00   156.7           39.33         137.83  3.333       3.5042          0.009998                 0.019844          0.1426
11:                     stablecoin or WETH  2348.67  2402.5         2208.83        2155.17  1.023       0.9757          0.004908                -0.010812          0.4586
12:           all but boom-type recipients 17555.50 26194.2        12779.17       16983.17  1.492       1.3290          0.787589                 0.846926          0.4703
13: all but bridge and exchange recipients 13278.50 21110.5         9694.00       12116.50  1.590       1.2499          0.714045                 0.488030          0.3339
14:                   boom-type recipients   403.50  2733.3          311.50        1157.33  6.774       3.7154          0.212411                 0.170399          0.2595
## N3. Base minus OP Mainnet, 6 and 7 days, with Base's batch accounts removed and without 03-16 (pre-cut placebos)
   window_days                     base_count without_03_16 base_minus_op placebo_K placebo_pct  rank_p
1:           6           all active addresses         FALSE        0.7409        61      1.0000 0.01613
2:           6           all active addresses          TRUE        0.4898        61      1.0000 0.01613
3:           6 without new addresses in waves         FALSE        0.4401        61      0.9836 0.03226
4:           6 without new addresses in waves          TRUE        0.3924        61      0.9508 0.06452
5:           7           all active addresses         FALSE        0.7197        59      1.0000 0.01667
6:           7           all active addresses          TRUE        0.5082        59      1.0000 0.01667
7:           7 without new addresses in waves         FALSE        0.4276        59      0.9661 0.05000
8:           7 without new addresses in waves          TRUE        0.3861        59      0.9492 0.06667
## N4. Base minus L1 entry outside waves (relative to the week before the cut) and ETH/USD, 03-01..03-21
           day       gap eth_usd
 1: 2024-03-01 -0.068484    3436
 2: 2024-03-02 -0.128186    3424
 3: 2024-03-03 -0.126246    3490
 4: 2024-03-04 -0.339550    3633
 5: 2024-03-05 -0.258928    3557
 6: 2024-03-06 -0.056844    3822
 7: 2024-03-07  0.090952    3875
 8: 2024-03-08 -0.021341    3893
 9: 2024-03-09 -0.033862    3914
10: 2024-03-10  0.077100    3882
11: 2024-03-11 -0.080734    4066
12: 2024-03-12 -0.027472    3980
13: 2024-03-13 -0.004643    4008
14: 2024-03-14  0.268950    3880
15: 2024-03-15  0.281125    3743
16: 2024-03-16  0.402136    3520
17: 2024-03-17  0.493429    3641
18: 2024-03-18  0.507380    3521
19: 2024-03-19  0.668553    3157
20: 2024-03-20  0.845336    3517
21: 2024-03-21  0.842303    3492
           day       gap eth_usd
N4: ETH peak 2024-03-11 at 4066; mean entry gap on ETH's rise (03-01 to the peak) -0.086
## N4. Funding sources of the extra non-burst entrants (from H1): exchange withdrawals vs all
                        source ratio share_of_increase
1: individual, direct transfer 1.976            0.5438
2:           bridge or relayer 1.666            0.1704
3:         exchange withdrawal 1.338            0.1505
## N5. The cut day in blocks of hours: non-burst entrants and funding entities on 03-14 against the same hours of 03-08..13, and the hourly median fee
      chain   blk cut_day_entrants cut_day_entities pre_mean pre_min pre_max pre_mean_entities pre_max_entities log_change log_change_entities above_all_prior_days base_minus_arbitrum cut_day_fee_usd cut_day_fee_max_usd pre_fee_usd
1: arbitrum 00-05             6214             5047     6190    5020    8432              4914             7200    0.00387             0.02667                FALSE             0.05339        0.467414             0.62213      0.5306
2: arbitrum 06-11             9371             7224     9520    8049   11150              7437             8561   -0.01578            -0.02908                FALSE             0.33104        0.433744             0.47599      0.4647
3: arbitrum 12-14             5359             4506     4602    4376    4928              3700             4088    0.15232             0.19721                 TRUE             0.26068        0.462708             0.78985      0.4990
4: arbitrum 15-23            19305            14839    10605    8858   13246              8409            11186    0.59902             0.56800                 TRUE                  NA        0.049787             0.07264      0.5574
5:     base 00-05             4208             2976     3974    3145    4302              3046             3423    0.05726            -0.02325                FALSE             0.05339        0.001387             0.00297      0.4810
6:     base 06-11             6298             4306     4595    3577    5096              3501             3944    0.31526             0.20701                 TRUE             0.33104        0.002970             0.01688      0.4818
7:     base 12-14             3694             2446     2444    2218    2821              1820             2260    0.41301             0.29562                 TRUE             0.26068        0.055035             0.05761      0.5867
8:     base 15-23            11409             6956     6946    6477    7430              4908             5500    0.49624             0.34867                 TRUE                  NA        0.038505             0.30681      0.6343
## N5. Base minus Arbitrum in blocks of hours before Arbitrum's cut: the cut day against each pre-cut day (against the other five)
    measure   blk  cut_day placebo_days placebo_min placebo_max above_all_placebo_days
1: entrants 00-05  0.05339            6    -0.65908     0.28924                  FALSE
2: entrants 06-11  0.33104            6    -0.39899     0.20272                   TRUE
3: entrants 12-14  0.26068            6    -0.07959     0.09195                   TRUE
4: entities 00-05 -0.04992            6    -0.73573     0.32478                  FALSE
5: entities 06-11  0.23609            6    -0.44989     0.15731                   TRUE
6: entities 12-14  0.09841            6    -0.26576     0.14500                  FALSE
## N6. Base non-burst window entrants by first action, 6 days before vs after the cut
                                                                            type  before after entities_before entities_after ratio entity_ratio share_of_rise
1:                                                           other contract call  6126.0 10383            4891           7337 1.695        1.500       0.38813
2:                                                 native or zero-value transfer  5710.5  9739            3933           6017 1.705        1.530       0.36729
3:                                                                      DEX swap  2837.5  3620            1895           2158 1.276        1.139       0.07134
4:                                                                 mint or claim   416.7   787             337            535 1.889        1.588       0.03376
5:                                                    token transfer or approval  2868.3  4398            2510           2828 1.533        1.127       0.13948
6:                                                all but DEX-swap first actions 15121.5 25308           11286          16033 1.674        1.421       0.92866
7: swap-like: DEX-swap selector or a named DEX router, aggregator or trading bot  3783.5  4803            2689           2919 1.270        1.085       0.09298
8:                                               all but swap-like first actions 14175.5 24124           10523          15321 1.702        1.456       0.90702
9:                                                                           all 17959.0 28928           13063          18027 1.611        1.380       1.00000
## O. The four cuts: fee change over the comparison days, jump at the hour (RI over pre-cut fake hours), entry outside waves minus L1 up to the next cut
                          cut                     event       placebo window_days     pre_days    post_days median_fee_pre_usd median_fee_post_usd log_fee_change saving_first_week_usd jump_new_senders p_new_senders_precut_fakes
 1: Base Mar (6 low-fee days)            Base (Ecotone) pre-cut dates           6 03-08..03-13 03-14..03-19            0.58535            0.006312         -4.530               1.15808           0.8171                    0.03960
 2: Base Mar (6 low-fee days)            Base (Ecotone)     all dates           6 03-08..03-13 03-14..03-19            0.58535            0.006312         -4.530               1.15808           0.8171                    0.03960
 3:                  Base Mar            Base (Ecotone) pre-cut dates           7 03-07..03-13 03-14..03-20            0.58880            0.007073         -4.422               1.16346           0.8171                    0.03960
 4:                  Base Mar            Base (Ecotone)     all dates           7 03-07..03-13 03-14..03-20            0.58880            0.007073         -4.422               1.16346           0.8171                    0.03960
 5:                     Arb 1           Arbitrum step 1 pre-cut dates           4 03-10..03-13 03-15..03-18            0.55016            0.082512         -1.897               0.46765           0.5414                    0.01980
 6:                     Arb 1           Arbitrum step 1     all dates           4 03-10..03-13 03-15..03-18            0.55016            0.082512         -1.897               0.46765           0.5414                    0.01980
 7:                     Arb 2           Arbitrum step 2 pre-cut dates           4 03-15..03-18 03-20..03-23            0.08251            0.008719         -2.247               0.07379           0.0467                    0.79630
 8:                     Arb 2           Arbitrum step 2     all dates           4 03-15..03-18 03-20..03-23            0.08251            0.008719         -2.247               0.07379           0.0467                    0.79630
 9:                  Base May Base gas limit 60M to 75M pre-cut dates           7 05-21..05-27 05-31..06-06            0.03396            0.002240         -2.719               0.06345           0.5973                    0.04082
10:                  Base May Base gas limit 60M to 75M     all dates           7 05-21..05-27 05-31..06-06            0.03396            0.002240         -2.719               0.06345           0.5973                    0.04082
    jump_never_burst_groups p_never_burst_precut_fakes jump_entities p_entities_precut_fakes fakes_entrant_outcomes shift_outside_waves_own shift_outside_waves_l1 shift_minus_l1 ratio_minus_l1 placebo_K disjoint_K placebo_pct p_one_sided  p_floor
 1:                  0.3093                    0.07692        0.3230                 0.07692                     12                 0.52137                0.06928         0.4521          1.572        61          6      1.0000    0.016129 0.016129
 2:                  0.3093                    0.07692        0.3230                 0.07692                     12                 0.52137                0.06928         0.4521          1.572       139         13      0.9856    0.021429 0.007143
 3:                  0.3093                    0.07692        0.3230                 0.07692                     12                 0.55492                0.05965         0.4953          1.641        59          5      1.0000    0.016667 0.016667
 4:                  0.3093                    0.07692        0.3230                 0.07692                     12                 0.55492                0.05965         0.4953          1.641       133         11      1.0000    0.007463 0.007463
 5:                  0.5485                    0.07692        0.4801                 0.07692                     12                 0.23856                0.10527         0.1333          1.143        64          8      0.9375    0.076923 0.015385
 6:                  0.5485                    0.07692        0.4801                 0.07692                     12                 0.23856                0.10527         0.1333          1.143       148         18      0.7905    0.214765 0.006711
 7:                  0.1813                    0.25000        0.1116                 0.20000                     19                 0.14597               -0.04622         0.1922          1.212        64          8      1.0000    0.015385 0.015385
 8:                  0.1813                    0.25000        0.1116                 0.20000                     19                 0.14597               -0.04622         0.1922          1.212       148         18      0.8851    0.120805 0.006711
 9:                  0.6845                    0.04762        0.4075                 0.04762                     20                 0.08835               -0.10650         0.1948          1.215        53          4      0.8302    0.185185 0.018519
10:                  0.6845                    0.04762        0.4075                 0.04762                     20                 0.08835               -0.10650         0.1948          1.215       124          9      0.7903    0.216000 0.008000
## P1. Daily median fee per tx (US$), 03-01..04-07
          date arbitrum     base ethereum optimism
 1: 2024-03-01 0.439658 0.425626    8.038 0.409185
 2: 2024-03-02 0.431582 0.399371    7.523 0.362148
 3: 2024-03-03 0.433282 0.423220    7.791 0.384193
 4: 2024-03-04 0.646451 0.681749   11.943 0.621146
 5: 2024-03-05 0.731939 0.835124   13.385 0.767204
 6: 2024-03-06 0.610471 0.721422   12.079 0.590120
 7: 2024-03-07 0.626908 0.678765   11.321 0.547768
 8: 2024-03-08 0.569810 0.598464   10.229 0.512677
 9: 2024-03-09 0.499220 0.530740    9.517 0.438540
10: 2024-03-10 0.528872 0.581897   10.688 0.446754
11: 2024-03-11 0.607204 0.639197   11.253 0.564699
12: 2024-03-12 0.553052 0.588803   10.585 0.535270
13: 2024-03-13 0.547271 0.493627   10.610 0.497521
14: 2024-03-14 0.268332 0.018602    9.266 0.012803
15: 2024-03-15 0.090528 0.003761    7.024 0.008790
16: 2024-03-16 0.086017 0.008677    5.497 0.007089
17: 2024-03-17 0.079007 0.004808    4.561 0.008661
18: 2024-03-18 0.076117 0.005552    5.908 0.007529
19: 2024-03-19 0.017110 0.007073    6.355 0.009918
20: 2024-03-20 0.009184 0.218185    4.832 0.008478
21: 2024-03-21 0.008960 0.111836    4.816 0.007613
22: 2024-03-22 0.008479 0.055414    3.831 0.008048
23: 2024-03-23 0.007420 0.032104    2.790 0.006094
24: 2024-03-24 0.007874 0.100619    2.853 0.006073
25: 2024-03-25 0.008718 0.276243    3.733 0.011916
26: 2024-03-26 0.008685 0.316768    4.771 0.014178
27: 2024-03-27 0.012995 0.280988    5.481 0.014497
28: 2024-03-28 0.018584 0.054191    5.118 0.032353
29: 2024-03-29 0.015746 0.056350    4.099 0.025529
30: 2024-03-30 0.015915 0.105779    3.552 0.027302
31: 2024-03-31 0.028398 0.092136    3.330 0.063945
32: 2024-04-01 0.030047 0.091682    3.978 0.067433
33: 2024-04-02 0.033722 0.044602    5.822 0.078992
34: 2024-04-03 0.022883 0.035272    4.784 0.047556
35: 2024-04-04 0.006940 0.005105    4.052 0.016427
36: 2024-04-05 0.006410 0.006706    2.995 0.014328
37: 2024-04-06 0.004721 0.009387    2.153 0.007205
38: 2024-04-07 0.004892 0.018308    2.579 0.005986
          date arbitrum     base ethereum optimism
## P1. Median fee per tx by period (median of daily medians, US$) and the log change from the 6 days before the cut
       chain                    period median_fee_usd log_change_from_before
 1: arbitrum before, 6 days: 03-08..13       0.550162               0.000000
 2:     base before, 6 days: 03-08..13       0.585350               0.000000
 3: ethereum before, 6 days: 03-08..13      10.597730               0.000000
 4: optimism before, 6 days: 03-08..13       0.505099               0.000000
 5: arbitrum before, 7 days: 03-07..13       0.553052               0.005241
 6:     base before, 7 days: 03-07..13       0.588803               0.005882
 7: ethereum before, 7 days: 03-07..13      10.610261               0.001182
 8: optimism before, 7 days: 03-07..13       0.512677               0.014891
 9: arbitrum       days 0-5: 03-14..19       0.082512              -1.897267
10:     base       days 0-5: 03-14..19       0.006312              -4.529705
11: ethereum       days 0-5: 03-14..19       6.131207              -0.547248
12: optimism       days 0-5: 03-14..19       0.008725              -4.058529
13: arbitrum      days 6-13: 03-20..27       0.008702              -4.146680
14:     base      days 6-13: 03-20..27       0.165011              -1.266200
15: ethereum      days 6-13: 03-20..27       4.301140              -0.901760
16: optimism      days 6-13: 03-20..27       0.008263              -4.112968
17: arbitrum Table 1 before: 03-08..12       0.553052               0.005241
18:     base Table 1 before: 03-08..12       0.588803               0.005882
19: ethereum Table 1 before: 03-08..12      10.585200              -0.001183
20: optimism Table 1 before: 03-08..12       0.512677               0.014891
21: arbitrum  Table 1 after: 03-14..21       0.077562              -1.959130
22:     base  Table 1 after: 03-14..21       0.007875              -4.308498
23: ethereum  Table 1 after: 03-14..21       5.702414              -0.619750
24: optimism  Table 1 after: 03-14..21       0.008569              -4.076600
       chain                    period median_fee_usd log_change_from_before
## P2. The March cut on OP Mainnet: shifts of growthepie series, OP Mainnet minus L1, Base minus L1, Base minus OP Mainnet, against placebo dates
                            pair window_days               outcome       placebo   shift placebo_K placebo_pct   p_high    p_low  p_floor
 1: OP Mainnet minus Ethereum L1           7  log active addresses pre-cut dates  0.1555        59      0.7797 0.233333 0.783333 0.016667
 2: OP Mainnet minus Ethereum L1           7  log active addresses     all dates  0.1555       133      0.8647 0.141791 0.865672 0.007463
 3: OP Mainnet minus Ethereum L1           7      log transactions pre-cut dates  0.5333        59      1.0000 0.016667 1.000000 0.016667
 4: OP Mainnet minus Ethereum L1           7      log transactions     all dates  0.5333       133      1.0000 0.007463 1.000000 0.007463
 5: OP Mainnet minus Ethereum L1           7 log median fee per tx pre-cut dates -3.4786        59      0.0000 1.000000 0.016667 0.016667
 6: OP Mainnet minus Ethereum L1           7 log median fee per tx     all dates -3.4786       133      0.0000 1.000000 0.007463 0.007463
 7: OP Mainnet minus Ethereum L1           6  log active addresses pre-cut dates  0.1366        61      0.7541 0.258065 0.758065 0.016129
 8: OP Mainnet minus Ethereum L1           6  log active addresses     all dates  0.1366       139      0.8058 0.200000 0.807143 0.007143
 9: OP Mainnet minus Ethereum L1           6      log transactions pre-cut dates  0.5275        61      1.0000 0.016129 1.000000 0.016129
10: OP Mainnet minus Ethereum L1           6      log transactions     all dates  0.5275       139      1.0000 0.007143 1.000000 0.007143
11: OP Mainnet minus Ethereum L1           6 log median fee per tx pre-cut dates -3.5056        61      0.0000 1.000000 0.016129 0.016129
12: OP Mainnet minus Ethereum L1           6 log median fee per tx     all dates -3.5056       139      0.0000 1.000000 0.007143 0.007143
13:       Base minus Ethereum L1           7  log active addresses pre-cut dates  0.8751        59      1.0000 0.016667 1.000000 0.016667
14:       Base minus Ethereum L1           7  log active addresses     all dates  0.8751       133      1.0000 0.007463 1.000000 0.007463
15:       Base minus Ethereum L1           7      log transactions pre-cut dates  1.0646        59      1.0000 0.016667 1.000000 0.016667
16:       Base minus Ethereum L1           7      log transactions     all dates  1.0646       133      1.0000 0.007463 1.000000 0.007463
17:       Base minus Ethereum L1           7 log median fee per tx pre-cut dates -3.3775        59      0.0000 1.000000 0.016667 0.016667
18:       Base minus Ethereum L1           7 log median fee per tx     all dates -3.3775       133      0.0000 1.000000 0.007463 0.007463
19:       Base minus Ethereum L1           6  log active addresses pre-cut dates  0.8775        61      1.0000 0.016129 1.000000 0.016129
20:       Base minus Ethereum L1           6  log active addresses     all dates  0.8775       139      1.0000 0.007143 1.000000 0.007143
21:       Base minus Ethereum L1           6      log transactions pre-cut dates  1.0542        61      1.0000 0.016129 1.000000 0.016129
22:       Base minus Ethereum L1           6      log transactions     all dates  1.0542       139      1.0000 0.007143 1.000000 0.007143
23:       Base minus Ethereum L1           6 log median fee per tx pre-cut dates -3.8932        61      0.0000 1.000000 0.016129 0.016129
24:       Base minus Ethereum L1           6 log median fee per tx     all dates -3.8932       139      0.0000 1.000000 0.007143 0.007143
25:        Base minus OP Mainnet           7  log active addresses pre-cut dates  0.7197        59      1.0000 0.016667 1.000000 0.016667
26:        Base minus OP Mainnet           7  log active addresses     all dates  0.7197       133      1.0000 0.007463 1.000000 0.007463
27:        Base minus OP Mainnet           7      log transactions pre-cut dates  0.5313        59      1.0000 0.016667 1.000000 0.016667
28:        Base minus OP Mainnet           7      log transactions     all dates  0.5313       133      0.9774 0.029851 0.977612 0.007463
29:        Base minus OP Mainnet           7 log median fee per tx pre-cut dates  0.1011        59      0.6949 0.316667 0.700000 0.016667
30:        Base minus OP Mainnet           7 log median fee per tx     all dates  0.1011       133      0.6241 0.380597 0.626866 0.007463
31:        Base minus OP Mainnet           6  log active addresses pre-cut dates  0.7409        61      1.0000 0.016129 1.000000 0.016129
32:        Base minus OP Mainnet           6  log active addresses     all dates  0.7409       139      1.0000 0.007143 1.000000 0.007143
33:        Base minus OP Mainnet           6      log transactions pre-cut dates  0.5267        61      1.0000 0.016129 1.000000 0.016129
34:        Base minus OP Mainnet           6      log transactions     all dates  0.5267       139      0.9784 0.028571 0.978571 0.007143
35:        Base minus OP Mainnet           6 log median fee per tx pre-cut dates -0.3876        61      0.0000 1.000000 0.016129 0.016129
36:        Base minus OP Mainnet           6 log median fee per tx     all dates -0.3876       139      0.2518 0.750000 0.257143 0.007143
                            pair window_days               outcome       placebo   shift placebo_K placebo_pct   p_high    p_low  p_floor
## P2. Event study: log active addresses for the three pairs, relative to the week before the cut (band: 5th-95th percentile, pre-cut placebo dates)
      k e_Base minus Ethereum L1 e_Base minus OP Mainnet e_OP Mainnet minus Ethereum L1 lo_Base minus Ethereum L1 lo_Base minus OP Mainnet lo_OP Mainnet minus Ethereum L1 hi_Base minus Ethereum L1 hi_Base minus OP Mainnet
 1: -14                 0.216232                0.033936                        0.18230                   -0.4546                  -0.4910                         -0.4839                    0.2374                   0.4121
 2: -13                -0.047546               -0.113284                        0.06574                   -0.4322                  -0.4944                         -0.5504                    0.2094                   0.4200
 3: -12                -0.067739               -0.088701                        0.02096                   -0.4163                  -0.5012                         -0.5419                    0.1624                   0.4125
 4: -11                -0.099289               -0.195758                        0.09647                   -0.4089                  -0.4940                         -0.5162                    0.2218                   0.3891
 5: -10                -0.259695               -0.106187                       -0.15351                   -0.3986                  -0.4421                         -0.4987                    0.2096                   0.3966
 6:  -9                -0.192392               -0.001183                       -0.19121                   -0.3877                  -0.4238                         -0.4530                    0.4129                   0.4301
 7:  -8                -0.020957               -0.005386                       -0.01557                   -0.3818                  -0.3866                         -0.4007                    0.3797                   0.4251
 8:  -7                 0.025278                0.046039                       -0.02076                   -0.3167                  -0.3156                         -0.3496                    0.3231                   0.3523
 9:  -6                 0.006759               -0.049885                        0.05664                   -0.3063                  -0.2191                         -0.2591                    0.2588                   0.3236
10:  -5                 0.024969               -0.326484                        0.35145                   -0.2962                  -0.2299                         -0.2149                    0.1987                   0.3190
11:  -4                 0.109265               -0.050199                        0.15946                   -0.2134                  -0.2350                         -0.1828                    0.2260                   0.2720
12:  -3                -0.061736                0.062484                       -0.12422                   -0.2472                  -0.2485                         -0.1629                    0.2720                   0.2869
13:  -2                 0.010212                0.155285                       -0.14507                   -0.2226                  -0.2705                         -0.1652                    0.2413                   0.3057
14:  -1                -0.114746                0.162760                       -0.27751                   -0.2425                  -0.3179                         -0.1954                    0.2427                   0.3122
15:   0                 0.681727                0.529618                        0.15211                   -0.2794                  -0.4099                         -0.2027                    0.2996                   0.3529
16:   1                 0.773970                0.644671                        0.12930                   -0.2417                  -0.4524                         -0.2168                    0.3983                   0.3619
17:   2                 2.001280                1.988589                        0.01269                   -0.2929                  -0.5111                         -0.2463                    0.4255                   0.3875
18:   3                 0.744102                0.569018                        0.17508                   -0.3375                  -0.5303                         -0.2768                    0.4110                   0.4245
19:   4                 0.615567                0.478860                        0.13671                   -0.3673                  -0.5119                         -0.2815                    0.3958                   0.5260
20:   5                 0.422873                0.188598                        0.23427                   -0.3450                  -0.4680                         -0.3134                    0.4396                   0.5835
21:   6                 0.886517                0.638276                        0.24824                   -0.3368                  -0.4766                         -0.3295                    0.4607                   0.5824
22:   7                 0.717817                0.517690                        0.20013                   -0.3697                  -0.4914                         -0.3839                    0.4958                   0.5294
23:   8                 0.592935                0.536334                        0.05660                   -0.3893                  -0.4925                         -0.3308                    0.5178                   0.5837
24:   9                 0.529020                0.459726                        0.06929                   -0.3879                  -0.4589                         -0.3110                    0.5627                   0.5835
25:  10                 0.714564                0.572038                        0.14253                   -0.4035                  -0.3899                         -0.2644                    0.5748                   0.5828
26:  11                 0.655379                0.364514                        0.29086                   -0.3539                  -0.3561                         -0.2869                    0.6058                   0.5598
27:  12                 0.921430                0.451446                        0.46998                   -0.3801                  -0.3725                         -0.2933                    0.6214                   0.5216
28:  13                 1.010259                0.510653                        0.49961                   -0.3743                  -0.3823                         -0.2839                    0.5905                   0.4765
29:  14                 1.136565                0.698227                        0.43834                   -0.3212                  -0.3584                         -0.2913                    0.6038                   0.3978
      k e_Base minus Ethereum L1 e_Base minus OP Mainnet e_OP Mainnet minus Ethereum L1 lo_Base minus Ethereum L1 lo_Base minus OP Mainnet lo_OP Mainnet minus Ethereum L1 hi_Base minus Ethereum L1 hi_Base minus OP Mainnet
    hi_OP Mainnet minus Ethereum L1
 1:                          0.3692
 2:                          0.4009
 3:                          0.3924
 4:                          0.3682
 5:                          0.3432
 6:                          0.3383
 7:                          0.3011
 8:                          0.2414
 9:                          0.1799
10:                          0.1692
11:                          0.1837
12:                          0.2133
13:                          0.2347
14:                          0.3088
15:                          0.3749
16:                          0.4727
17:                          0.5760
18:                          0.6122
19:                          0.6138
20:                          0.6231
21:                          0.6151
22:                          0.5790
23:                          0.5602
24:                          0.5377
25:                          0.5067
26:                          0.4656
27:                          0.4241
28:                          0.3993
29:                          0.3946
    hi_OP Mainnet minus Ethereum L1
## P3. Donor chains (fee fell less than 1 log over the low-fee days): celo, linea, metis, polygon_pos, ronin, scroll
            chain  full     dfee
 1:          mode FALSE -6.29863
 2:          base  TRUE -4.52971
 3:      starknet  TRUE -4.14633
 4:         manta  TRUE -4.06969
 5:      optimism  TRUE -4.05853
 6:        mantle  TRUE -3.08199
 7:      arbitrum  TRUE -1.89727
 8:      ethereum  TRUE -0.54725
 9:        scroll  TRUE -0.49511
10:   polygon_pos  TRUE -0.35873
11:          celo  TRUE -0.01300
12:         ronin  TRUE  0.04756
13:         metis  TRUE  0.05735
14:         linea  TRUE  0.15006
15: arbitrum_nova FALSE       NA
16:       fraxtal FALSE       NA
17:       gravity FALSE       NA
18:          lisk FALSE       NA
19:         taiko FALSE       NA
20:    zksync_era FALSE       NA
## P3. Log active addresses, 6-day shift at the cut: Base minus each donor, the donor mean and L1; L1 minus the donor mean; each chain alone
                    series       placebo shift_6d placebo_K rank placebo_pct
 1:    base minus ethereum pre-cut dates  0.87747        61    1     1.00000
 2:    base minus ethereum     all dates  0.87747       139    1     1.00000
 3:  base minus donor_mean pre-cut dates  1.04295        61    1     1.00000
 4:  base minus donor_mean     all dates  1.04295       139    1     1.00000
 5:        base minus celo pre-cut dates  1.18562        61    1     1.00000
 6:        base minus celo     all dates  1.18562       139    1     1.00000
 7:       base minus linea pre-cut dates  0.97563        61    1     1.00000
 8:       base minus linea     all dates  0.97563       139    3     0.98561
 9:       base minus metis pre-cut dates  1.49660        61    1     1.00000
10:       base minus metis     all dates  1.49660       139    1     1.00000
11: base minus polygon_pos pre-cut dates  1.10332        61    1     1.00000
12: base minus polygon_pos     all dates  1.10332       139    1     1.00000
13:       base minus ronin pre-cut dates  0.78146        61    1     1.00000
14:       base minus ronin     all dates  0.78146       139    1     1.00000
15:      base minus scroll pre-cut dates  0.71505        61    1     1.00000
16:      base minus scroll     all dates  0.71505       139    1     1.00000
17:    L1 minus donor_mean pre-cut dates  0.16548        61    7     0.90164
18:    L1 minus donor_mean     all dates  0.16548       139   11     0.92806
19:                   base pre-cut dates  1.02683        61    1     1.00000
20:                   base     all dates  1.02683       139    1     1.00000
21:               ethereum pre-cut dates  0.14936        61    2     0.98361
22:               ethereum     all dates  0.14936       139    3     0.98561
23:                   celo pre-cut dates -0.15879        61   53     0.14754
24:                   celo     all dates -0.15879       139  126     0.10072
25:                  linea pre-cut dates  0.05119        61   32     0.49180
26:                  linea     all dates  0.05119       139   57     0.59712
27:                  metis pre-cut dates -0.46978        61   52     0.16393
28:                  metis     all dates -0.46978       139  121     0.13669
29:            polygon_pos pre-cut dates -0.07649        61   56     0.09836
30:            polygon_pos     all dates -0.07649       139  128     0.08633
31:                  ronin pre-cut dates  0.24536        61    1     1.00000
32:                  ronin     all dates  0.24536       139    1     1.00000
33:                 scroll pre-cut dates  0.31178        61   14     0.78689
34:                 scroll     all dates  0.31178       139   16     0.89209
                    series       placebo shift_6d placebo_K rank placebo_pct
## Q. The primary statistic under alternative counterfactuals (panel A) and outcome definitions (panel B), Base minus L1, 6 low-fee days
                panel                                                                         variant estimate placebo_K rank ratio
 1: A. counterfactual                                     mean over the 6 days 2024-03-08..2024-03-13   0.4521        61    1 1.572
 2: A. counterfactual                                    mean over the 12 days 2024-03-02..2024-03-13   0.5127        55    1 1.670
 3: A. counterfactual                                    mean over the 18 days 2024-02-25..2024-03-13   0.4490        49    1 1.567
 4: A. counterfactual                                    mean over the 24 days 2024-02-19..2024-03-13   0.4466        43    1 1.563
 5: A. counterfactual                                    mean over the 30 days 2024-02-13..2024-03-13   0.4650        37    1 1.592
 6: A. counterfactual                                     mean over the 6 days 2024-03-01..2024-03-06   0.6000        54    1 1.822
 7: A. counterfactual                                    mean over the 12 days 2024-02-24..2024-03-06   0.4465        48    1 1.563
 8: A. counterfactual                                    mean over the 24 days 2024-02-12..2024-03-06   0.4719        36    1 1.603
 9: A. counterfactual                            linear trend over the 12 days 2024-03-02..2024-03-13   0.3335        55    4 1.396
10: A. counterfactual                            linear trend over the 21 days 2024-02-22..2024-03-13   0.5274        46    1 1.695
11: A. counterfactual                            linear trend over the 28 days 2024-02-15..2024-03-13   0.4642        39    1 1.591
12: A. counterfactual                            linear trend over the 42 days 2024-02-01..2024-03-13   0.4711        25    1 1.602
13: A. counterfactual                            linear trend over the 73 days 2024-01-01..2024-03-13   0.3357         0   NA 1.399
14:        B. outcome                  wave threshold six times the group's baseline instead of three   0.4225        61    1 1.526
15:        B. outcome               entry outside waves (primary), established-action placebo origins   0.4521        32    1 1.572
16:        B. outcome                                      established first actions, daily wave rule   0.3132        32    1 1.368
17:        B. outcome                                         established first actions, no wave rule   0.4477        32    6 1.565
18:        B. outcome established first actions, excluding groups with a wave in the reference period   0.2226        32    8 1.249
## Q. The pre-cut reference set
   placebo_K gap_max gap_sd base_alone_sd                largest_three_start pooled_base_on_largest_after_day pooled_base pooled_base_day_before pooled_ratio
1:        61   0.312 0.1351        0.1464 2024-01-24, 2024-01-23, 2024-01-22                       2024-01-24       44315                   2902        15.27

## sessionInfo
```
R version 4.6.1 (2026-06-24)
Platform: aarch64-apple-darwin23
Running under: macOS Golden Gate 27.2.1

Matrix products: default
BLAS:   /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRblas.0.dylib 
LAPACK: /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1

locale:
[1] en_US/en_US/en_US/C/en_US/en_US

time zone: UTC
tzcode source: internal

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] jsonlite_2.0.0      ggplot2_4.0.3       fixest_0.14.2       data.table_1.18.6.1 here_1.0.2         

loaded via a namespace (and not attached):
 [1] sandwich_3.1-3      generics_0.1.4      dreamerr_1.5.0      lattice_0.23-1      magrittr_2.0.5      grid_4.6.1          estimability_2.0.0  timechange_0.4.0    RColorBrewer_1.1-3  mvtnorm_1.4-2       rprojroot_2.1.1     Matrix_1.7-6       
[13] DBI_1.3.0           Formula_1.2-6       survival_3.8-12     multcomp_1.4-32     gridExtra_2.3.1     scales_1.4.0        TH.data_1.1-5       stringmagic_1.3.0   textshaping_1.0.5   codetools_0.2-20    numDeriv_2016.8-1.1 duckdb_1.5.6       
[25] cli_3.6.6           rlang_1.3.0         splines_4.6.1       withr_3.0.3         yaml_2.3.12         otel_0.2.0          tools_4.6.1         coda_0.19-4.1       dplyr_1.2.1         vctrs_0.7.3         R6_2.6.1            zoo_1.9-1          
[37] lifecycle_1.0.5     emmeans_2.0.4       lubridate_1.9.5     MASS_7.3-66         ragg_1.5.2          pkgconfig_2.0.3     pillar_1.11.1       gtable_0.3.6        glue_1.8.1          Rcpp_1.1.2          systemfonts_1.3.2   nanoparquet_0.5.2  
[49] tibble_3.3.1        tidyselect_1.2.1    farver_2.1.2        xtable_1.8-8        igraph_2.3.4        nlme_3.1-171        labeling_0.4.3      compiler_4.6.1      S7_0.2.2           
```
