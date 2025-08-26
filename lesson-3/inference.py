import argparse
import torch
from PIL import Image
from torchvision.models import MobileNet_V2_Weights


def load_model(path: str):
    model = torch.jit.load(path)
    model.eval()
    return model


def preprocess(image_path: str, weights: MobileNet_V2_Weights):
    preprocess = weights.transforms()
    img = Image.open(image_path).convert("RGB")
    return preprocess(img).unsqueeze(0)


def main():
    parser = argparse.ArgumentParser(description="Run inference with a TorchScript MobileNetV2 model")
    parser.add_argument("image", help="Path to input image")
    parser.add_argument("--model", default="model.pt", help="Path to TorchScript model")
    args = parser.parse_args()

    weights = MobileNet_V2_Weights.DEFAULT
    model = load_model(args.model)
    img = preprocess(args.image, weights)

    with torch.no_grad():
        output = model(img)[0]
        probabilities = torch.nn.functional.softmax(output, dim=0)
        top3 = probabilities.topk(3)

    categories = weights.meta["categories"]
    for score, idx in zip(top3.values, top3.indices):
        print(f"{categories[idx]}: {score.item():.4f}")


if __name__ == "__main__":
    main()