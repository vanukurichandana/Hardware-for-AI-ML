\# ECE 510 HW for AI and ML Codefest-4 CMAN  Manual INT8 symmetric quantization





Given 4x4 FP32 weight matrix



W = \[  0.85      -1.20       0.34      2.10 ]

&#x20;   \[ -0.07       0.91      -1.88      0.12 ]

&#x20;   \[  1.55       0.03      -0.44     -2.31 ]

&#x20;   \[ -0.18       1.03       0.77      0.55 ]



\## 1. Scale Factor

&#x20;  S = max |W| / 127



&#x20;  |W| = \[  0.85       1.20       0.34      2.10 ]

&#x20;        \[  0.07       0.91       1.88      0.12 ]

&#x20;        \[  1.55       0.03       0.44      2.31 ]

&#x20;        \[  0.18       1.03       0.77      0.55 ]



&#x20;  Max element from the given weighted matrix |W| = 2.31

&#x20;  S = max |W| / 127

&#x20;  S = 2.31 / 127

&#x20;  S = 0.0181889763779



\## 2. Quantize

&#x20;  W\_q = round(W / S)



&#x20;  Dividing every element of W with S from task 1 and rounding it.



&#x20;  W\_q = \[  0.85/S      -1.20/S       0.34/S      2.10/S ]

&#x20;        \[ -0.07/S       0.91/S      -1.88/S      0.12/S ]

&#x20;        \[  1.55/S       0.03/S      -0.44/S     -2.31/S ]

&#x20;        \[ -0.18/S       1.03/S       0.77/S      0.55/S ]



&#x20;

&#x20;  W\_q = \[  47      -66      19     115 ]

&#x20;        \[ -4        50     -103    7   ]

&#x20;        \[  85       2      -24    -127 ]

&#x20;        \[ -10       57      42     30  ]



\## 3. Dequantize

&#x20;  W\_deq = W\_q x S



&#x20;  Now for dequantizing multiplying every element of W\_q with S from task 1 and 2.



&#x20;  W\_q = \[  47xS      -66xS      19xS     115xS ]

&#x20;        \[ -4xS        50xS     -103xS    7xS   ]

&#x20;        \[  85xS       2xS      -24xS    -127xS ]

&#x20;        \[ -10xS       57xS      42xS     30xS  ]

&#x20;

&#x20;  W\_deq = \[  0.8548818897637      -1.2004724409448      0.3455905511811     2.0917322834645 ]

&#x20;          \[ -0.0727559055118       0.9094488188976     -1.8734645669291     0.1273228346456 ]

&#x20;          \[  1.5460629921259       0.0363779527559     -0.4365354330708    -2.31            ]

&#x20;          \[ -0.1818897637795       1.0367716535433      0.7639370078740     0.5456692913385 ]





\## 4. Error Analysis

&#x20;  |W - W\_deq|

&#x20;

&#x20;  Subtracting W\_deq from W.



&#x20;  |W - W\_deq| = \[  0.004881889763       0.0004724409448       0.005590551181      0.0082677165355 ]

&#x20;                \[  0.002755905118       0.0005511811024       0.006535433070      0.007322834645  ]

&#x20;                \[  0.0039370078741      0.006377952755        0.003464566929      0               ]

&#x20;                \[  0.001889763779       0.006779527559        0.006062992126      0.0043307086615 ]



&#x20;  Largest Error = 0.0082677165355



&#x20;  Mean Absolute Error(MAE) = Sum of all elements of |W - W\_deq| / 16

&#x20;                           = 0.0692204720433 / 16

&#x20;                           = 0.0043262795027

&#x20;

\## 5. Bad Scale Experiment

&#x20;     S\_bad = 0.01



&#x20;     Quantizing, W\_qbad = round (W/S\_bad)

&#x20;     

&#x20;     W\_qbad = \[  0.85/S\_bad      -1.20/S\_bad       0.34/S\_bad      2.10/S\_bad ]

&#x20;              \[ -0.07/S\_bad       0.91/S\_bad      -1.88/S\_bad      0.12/S\_bad ]

&#x20;              \[  1.55/S\_bad       0.03/S\_bad      -0.44/S\_bad     -2.31/S\_bad ]

&#x20;              \[ -0.18/S\_bad       1.03/S\_bad       0.77/S\_bad      0.55/S\_bad ]



&#x20;     W\_qbad = \[  85      -120     34     210 ]

&#x20;              \[ -7        91     -188    12  ]

&#x20;              \[  155      3      -44    -231 ]

&#x20;              \[ -18       103     77     55  ]



&#x20;     After clamping the values to \[-128,127] range, 
     

&#x20;     W\_qbad = \[  85      -120     34     127 ]

&#x20;              \[ -7        91     -128    12  ]

&#x20;              \[  127      3      -44    -128 ]

&#x20;              \[ -18       103     77     55  ]



&#x20;    Dequantizing, W\_deqbad = W\_qbad x S\_bad



&#x20;    W\_deqbad = \[  0.85      -1.20     0.34     1.27 ]

&#x20;               \[ -0.07       0.91    -1.28     0.12 ]

&#x20;               \[  1.27       0.03    -0.44    -1.28 ]

&#x20;               \[ -0.18       1.03     0.77     0.55 ]





&#x20;   Absolute error, |W - W\_deqbad|



&#x20;   |W - W\_deqbad| = \[  0        0     0     0.83 ]

&#x20;                    \[  0        0     0.6   0    ]

&#x20;                    \[  0.28     0     0     1.03 ]

&#x20;                    \[  0        0     0     0    ]



&#x20;   Mean Absolute Error(MAE\_bad) = Sum of all elements of |W - W\_deqbad| / 16

&#x20;                                = 2.74 / 16

&#x20;                                = 0.17125

&#x20;  

**Finally, when S is too small like 0.01 S\_bad, large weights in the matrix are exceeding the INT8 range and we are clamping it to \[-128,127] range which is causing saturation and much larger dequantization error.**

&#x20;

