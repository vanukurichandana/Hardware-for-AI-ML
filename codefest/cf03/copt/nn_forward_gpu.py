import sys
import torch
import torch.nn as nn

# 1. Detect device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

if device.type == "cuda":
    print(f"CUDA GPU detected: {torch.cuda.get_device_name(0)}")
    print(f"CUDA version     : {torch.version.cuda}")
    print(f"PyTorch version  : {torch.__version__}")
else:
    print("ERROR: No CUDA-capable GPU found.")
    sys.exit(1)

# 2. Define network: Linear(4->5) -> ReLU -> Linear(5->1)
model = nn.Sequential(
    nn.Linear(4, 5),
    nn.ReLU(),
    nn.Linear(5, 1),
)
model.to(device)
print(f"\nModel architecture:\n{model}")
print(f"Model is on device: {next(model.parameters()).device}")

# 3. Random input batch [16, 4], run forward pass
x = torch.randn(16, 4).to(device)
print(f"\nInput tensor shape : {list(x.shape)}")
print(f"Input tensor device: {x.device}")

with torch.no_grad():
    output = model(x)

print(f"\nOutput tensor shape : {list(output.shape)}")
print(f"Output tensor device: {output.device}")

# 4. Verify
assert output.shape == (16, 1)
assert str(output.device).startswith("cuda")
print("\n✓ Output shape confirmed: [16, 1]")
print(f"✓ Output confirmed on GPU: {output.device}")
