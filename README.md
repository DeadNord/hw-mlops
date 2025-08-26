## Usage

1. **Export model**

   ```bash
   python export_model.py
   ```

2. **Run inference**

   ```bash
   python inference.py db/test-img.jpg
   ```

3. **Build images**

   ```bash
   docker build -t mobilenet-fat -f Dockerfile.fat .
   docker build -t mobilenet-slim -f Dockerfile.slim .
   ```

4. **Run container**

   ```bash
   docker run --rm mobilenet-fat db/test-img.jpg
   docker run --rm mobilenet-slim db/test-img.jpg
   ```

5. **Check model**

   ```bash
   docker images mobilenet-fat mobilenet-slim
   docker history mobilenet-fat
   docker history mobilenet-slim
   ```
