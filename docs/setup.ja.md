# FPGA Calculator — 導入と操作

[简体中文](setup.zh-CN.md) · [English](setup.en.md) · **日本語** · [概要](../README_JA.md)

<a id="open"></a>

## 工程の選択と読み込み

1. 主版は [project_3.xpr](../integer_calculator_buzzer/project_3.xpr) を開き、デバイス `xc7a35tftg256-1`、トップ `Caculator`、活動RTL `caculator.v` を確認します。
2. 活動ピン制約は [Con_Caculator.xdc](../integer_calculator_buzzer/project_3.srcs/constrs_1/new/Con_Caculator.xdc) です。`create_clock` はありません。実際の発振器と回路を確認してからクロック制約を追加する必要があります。
3. [cacu.xpr](../float_calculator_ieee754/cacu.xpr) のトップは `Top` で、未完成の浮動小数点実験です。XDCも空で、そのまま実機へ書き込める状態ではありません。
4. 74HC595側には独立 `.xpr` と完全なピン制約がありません。統合不足を解消して別工程を作成します。すべての `.v` を主版へ一括追加しないでください。

<a id="pins"></a>

## 主版のピン確認

| 信号 | 制約ピン。ベクトルのビット0から順に記載 |
| --- | --- |
| `clk` | D4 |
| `col[0:3]` | T10、R11、T12、R12。プルダウン |
| `row[0:3]` | K3、M6、P10、R10 |
| `seg[0:7]` | P11、N12、L14、K13、K12、P13、M14、L13 |
| `DIG[0:5]` | N11、N14、N13、M12、H13、G12 |
| `buzzer`、`sw1`、`sw2` | L2、F3、H4 |

リポジトリ制約の転記であり、任意のArtix-7基板に適合する配線ではありません。書き込み前に電圧、極性、クロック、実配線を確認してください。

<a id="validate"></a>

## 検証の順序

まず初期化・リセットを整備し、現在のトップと一致するテストベンチを使用します。キー、同一数字、クリア、四則演算、負の差、ゼロ除算、15を超える余り、オーバーフロー、異種の連続演算を確認し、その後に合成・タイミング制約・配置配線・実機試験を行います。

Icarus Verilog 13.0で実RTLをコンパイル・実行し、a=0–99、b=1–99の商・余り9900組、98/99の小数2桁、ゼロ除算、混合連続演算、負の減算、クリア、初期化・分周・ブザー境界が通過しました。calのキー配列を直接駆動し、分周端点は既知カウントを与えた検査で、物理キー・音程・周波数の測定ではありません。Vivado合成・実装・タイミング収束・再書込は未実施です。

<a id="next"></a>

## 再現条件と今後

発振器と主・生成クロック制約を確認してから合成・実機評価を行います。74HC595とIEEE754は未完成の実験であり、主版の完成機能へ混在させません。

[自己検査](../tests/tb_calculator.v)を主sim_1へ登録し、tb_calculatorを動作シミュレーションのトップにしました。旧単体テストと2実験版は保持し、通過結果へ含めません。

## 保守修正とRTL自己検査


```shell
iverilog -g2012 -s tb_calculator -o "$BUILD_DIR/calculator.vvp" integer_calculator_buzzer/project_3.srcs/sources_1/new/caculator.v tests/tb_calculator.v
vvp "$BUILD_DIR/calculator.vvp"
```

[Icarus](https://steveicarus.github.io/iverilog/usage/installation.html)を準備し、作成済み外部出力先をBUILD_DIRへ設定します。
