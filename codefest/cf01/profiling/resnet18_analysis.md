# ResNet-18 MAC Analysis


## Top 5 MAC-Intensive Layers

| Rank | Layer Name    |          MACs | Parameters |
|:----:|:-------------|:-------------:|:----------:|
| 1    | Conv2d: 1-1  | 118,013,952   | 9,408      |
| 2    | Conv2d: 3-1  | 115,605,504   | 36,864     |
| 3    | Conv2d: 3-4  | 115,605,504   | 36,864     |
| 4    | Conv2d: 3-7  | 115,605,504   | 36,864     |
| 5    | Conv2d: 3-10 | 115,605,504   | 36,864     |

## Arithmetic Intensity Analysis

**Selected layer: Conv2d: 1-1** — highest MAC count (118,013,952) among all layers.

### Memory Breakdown

#### Weight Memory

$$\text{Weight Memory} = 9{,}408 \times 4 \text{ bytes} = 37{,}632 \text{ bytes}$$

#### Activation Memory

| Tensor  | Shape              | Elements  |
|:--------|:-------------------|----------:|
| Input   | 3 × 224 × 224      | 150,528   |
| Output  | 64 × 112 × 112     | 802,816   |
| **Total** | —                | **953,344** |

$$\text{Activation Memory} = 953{,}344 \times 4 \text{ bytes} = 3{,}813{,}376 \text{ bytes}$$

#### Total Memory

$$\text{Total Memory} = 37{,}632 + 3{,}813{,}376 = 3{,}851{,}008 \text{ bytes}$$

---

### Arithmetic Intensity Calculation

Arithmetic Intensity (AI) is defined as the ratio of floating-point operations to memory bytes accessed:

$$AI = \frac{\text{FLOPs}}{\text{Memory (bytes)}}$$

Substituting values (each MAC = 2 FLOPs):

$$AI = \frac{2 \times 118{,}013{,}952}{3{,}851{,}008} = \frac{236{,}027{,}904}{3{,}851{,}008}$$

$$\boxed{AI \approx 61.29 \ \text{FLOP/byte}}$$