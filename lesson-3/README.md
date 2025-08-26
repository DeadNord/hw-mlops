## Usage

0. **CD**

   ```bash
   cd lesson-3
   ```

1. **Install dev tools**

   ```bash
   bash install_dev_tools.sh
   ```

   This idempotent script checks for Docker, Python, and required ML libraries.

2. **Export model**

   ```bash
   python export_model.py
   ```

3. **Run inference**

   ```bash
   python inference.py db/test-img.jpg
   ```

4. **Build images**

   ```bash
   docker build -t mobilenet-fat -f Dockerfile.fat .
   docker build -t mobilenet-slim -f Dockerfile.slim .
   ```

5. **Run container**

   ```bash
   docker run --rm mobilenet-fat
   docker run --rm mobilenet-slim
   ```

6. **Check model**

   ```bash
   docker images mobilenet-fat
   docker images mobilenet-slim
   docker history mobilenet-fat  --format '{{.ID}}' | wc -l
   docker history mobilenet-slim --format '{{.ID}}' | wc -l
   ```
