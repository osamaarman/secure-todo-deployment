# Stage 1: Build stage - install dependencies
FROM python:3.13.3-alpine AS builder

RUN apk add --no-cache gcc musl-dev libpq-dev

WORKDIR /app

COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

COPY . .

# Stage 2: Final stage - minimal runtime image
FROM python:3.13.3-alpine

RUN apk add --no-cache libpq curl

WORKDIR /app

COPY --from=builder /install /usr/local
COPY --from=builder /app /app

RUN chmod +x /app/entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/app/entrypoint.sh"]
