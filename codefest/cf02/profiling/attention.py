import numpy as np

def softmax(x):
    x = x - np.max(x, axis=-1, keepdims=True)
    exp_x = np.exp(x)
    return exp_x / np.sum(exp_x, axis=-1, keepdims=True)

def run_attention():
    B = 1    # batch size
    T = 64   # sequence length
    d = 64   # model dimension

    X = np.random.rand(B, T, d).astype(np.float32)

    Wq = np.random.rand(d, d).astype(np.float32)
    Wk = np.random.rand(d, d).astype(np.float32)
    Wv = np.random.rand(d, d).astype(np.float32)

    Q = np.matmul(X, Wq)
    K = np.matmul(X, Wk)
    V = np.matmul(X, Wv)

    scores = np.matmul(Q, K.transpose(0, 2, 1)) / np.sqrt(d)
    weights = softmax(scores)
    output = np.matmul(weights, V)

    return output

if __name__ == "__main__":
    for _ in range(10):
        run_attention()