FROM python:3.13-slim

# Evita prompts interativos durante instalações via apt
ENV DEBIAN_FRONTEND=noninteractive

# Configurações úteis para Python e uv
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_LINK_MODE=copy

# Instala dependências mínimas para baixar e instalar o uv
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    bash \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Instala o uv oficialmente via instalador da Astral
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# O instalador coloca o uv em /root/.local/bin
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /workspace

CMD ["/bin/bash"]