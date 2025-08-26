import torch
from torchvision.models import mobilenet_v2, MobileNet_V2_Weights

def export_model(path: str = "model.pt"):
    """Export pretrained MobileNetV2 to TorchScript."""
    weights = MobileNet_V2_Weights.DEFAULT
    model = mobilenet_v2(weights=weights)
    model.eval()
    example = torch.rand(1, 3, 224, 224)
    traced = torch.jit.trace(model, example)
    traced.save(path)
    print(f"Saved TorchScript model to {path}")


if __name__ == "__main__":
    export_model()