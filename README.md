# Tutorial: ciclo básico de um projeto Python com Docker + `uv`

Este tutorial mostra como criar e executar um projeto Python usando:

* Docker;
* Python 3.13;
* `uv` como gerenciador de projeto, ambiente virtual e dependências;
* `pytest` para testes automatizados;
* `ruff` para lint de código.

---

## 1. Estrutura inicial

Crie uma pasta para o laboratório:

```bash
mkdir laboratorio-uv
cd laboratorio-uv
```

Crie um arquivo chamado `Dockerfile`:

```dockerfile
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_LINK_MODE=copy

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /workspace

CMD ["/bin/bash"]
```

Esse Dockerfile usa Python 3.13 como base e depois adiciona o `uv`.

---

## 2. Build da imagem Docker

No mesmo diretório onde está o `Dockerfile`, execute:

```bash
docker build -t python-uv-lab .
```

Esse comando cria uma imagem Docker chamada `python-uv-lab`.

Para conferir se a imagem foi criada:

```bash
docker images
```

---

## 3. Execução do container

Execute o container:

```bash
docker run --rm -it \
  --name uv-lab \
  python-uv-lab
```

No Windows PowerShell, use:

```powershell
docker run --rm -it `
  --name uv-lab `
  python-uv-lab
```

Depois de entrar no container, confira as versões:

```bash
python --version
uv --version
```

Saída esperada aproximada:

```text
Python 3.13.x
uv x.y.z
```

Observação: como este exemplo não monta uma pasta do computador dentro do container, os arquivos criados serão perdidos quando o container for encerrado. Para uma aula rápida isso é aceitável. Para preservar os arquivos, use volume com Docker.

---

## 4. Criando um projeto com `uv init`

Dentro do container, crie um projeto:

```bash
uv init meu-projeto
cd meu-projeto
```

O `uv` cria uma estrutura parecida com esta:

```text
meu-projeto/
├── .python-version
├── README.md
├── main.py
└── pyproject.toml
```

Execute o projeto inicial:

```bash
uv run main.py
```

Saída esperada:

```text
Hello from meu-projeto!
```

---

## 5. Criando um arquivo Python com dependência não instalada

Agora vamos criar um arquivo Python que depende de `pandas`, mas ainda não vamos instalar essa dependência.

Crie um arquivo chamado `analise.py`:

```bash
cat > analise.py <<'EOF'
import os
import pandas as pd


def main():
    dados = {
        "nome": ["Ana", "Bruno", "Carla"],
        "nota": [8.5, 7.0, 9.2],
    }

    df = pd.DataFrame(dados)

    print("Tabela de notas:")
    print(df)

    print()
    print("Média da turma:")
    print(df["nota"].mean())


if __name__ == "__main__":
    main()
EOF
```

Observe que o arquivo importa `pandas`, mas o projeto ainda não possui `pandas` instalado.

Também existe um `import os` que não está sendo usado. Vamos aproveitar isso depois para demonstrar lint de código.

---

## 6. Executando com `uv run` para dar erro

Agora execute:

```bash
uv run analise.py
```

Esse comando deve falhar, pois `pandas` ainda não está instalado.

Erro esperado aproximado:

```text
ModuleNotFoundError: No module named 'pandas'
```

Isso acontece porque o `uv` executa o script dentro do ambiente do projeto, respeitando as dependências registradas no `pyproject.toml`.

Como `pandas` ainda não está nas dependências, o Python não consegue importar o pacote.

---

## 7. Instalando dependências com `uv add`

Agora vamos instalar duas dependências:

* `pandas`, que será usada no projeto;
* `numpy`, que será instalada de propósito para depois demonstrarmos o `uv remove`.

Execute:

```bash
uv add pandas numpy
```

Esse comando atualiza o `pyproject.toml` e o `uv.lock`.

Agora execute novamente:

```bash
uv run analise.py
```

Saída esperada aproximada:

```text
Tabela de notas:
    nome  nota
0    Ana   8.5
1  Bruno   7.0
2  Carla   9.2

Média da turma:
8.233333333333333
```

Agora funcionou porque `pandas` foi adicionado às dependências do projeto.

---

## 8. Removendo dependência com `uv remove`

A dependência `numpy` foi instalada, mas nosso código não importa `numpy` diretamente.

Para remover:

```bash
uv remove numpy
```

Depois disso, o `uv` atualiza novamente o `pyproject.toml` e o `uv.lock`.

Execute de novo:

```bash
uv run analise.py
```

O script deve continuar funcionando, porque a dependência usada diretamente pelo código é `pandas`.

---

## 9. Sincronizando o ambiente com `uv sync`

O comando `uv sync` sincroniza o ambiente virtual com o que está declarado no `pyproject.toml` e no `uv.lock`.

Execute:

```bash
uv sync
```

Esse comando é muito usado quando:

* você acabou de clonar um projeto;
* alguém alterou o `pyproject.toml`;
* alguém alterou o `uv.lock`;
* você apagou o ambiente virtual `.venv`;
* você quer garantir que o ambiente está exatamente igual ao projeto.

Para simular isso, remova o ambiente virtual:

```bash
rm -rf .venv
```

Agora recrie tudo com:

```bash
uv sync
```

Depois execute:

```bash
uv run analise.py
```

O projeto deve continuar funcionando.

---

## 10. Dependência de desenvolvimento com `pytest`

Além das dependências necessárias para executar a aplicação, um projeto normalmente também possui dependências usadas apenas durante o desenvolvimento.

Exemplos:

* `pytest`, para testes automatizados;
* `ruff`, para lint e formatação;
* `mypy`, para checagem de tipos.

Essas dependências não fazem parte da aplicação em si. Elas são ferramentas usadas por quem desenvolve o projeto.

---

### Instalando o `pytest` como dependência de desenvolvimento

Para adicionar o `pytest` ao projeto:

```bash
uv add --dev pytest
```

Esse comando adiciona o `pytest` ao grupo de desenvolvimento no `pyproject.toml`.

O arquivo ficará parecido com isto:

```toml
[dependency-groups]
dev = [
    "pytest>=...",
]
```

---

### Criando um teste simples

Crie uma pasta chamada `tests`:

```bash
mkdir tests
```

Agora crie o arquivo `tests/test_analise.py`:

```bash
cat > tests/test_analise.py <<'EOF'
def test_media_simples():
    notas = [8.5, 7.0, 9.2]
    media = sum(notas) / len(notas)

    assert round(media, 2) == 8.23
EOF
```

---

### Executando os testes com `uv run`

Para rodar os testes:

```bash
uv run pytest
```

Saída esperada aproximada:

```text
============================= test session starts =============================
collected 1 item

tests/test_analise.py .                                             [100%]

============================== 1 passed in ... ==============================
```

---

### Executando os testes com mais detalhes

```bash
uv run pytest -v
```

---

### Executando apenas um arquivo de teste

```bash
uv run pytest tests/test_analise.py
```

---

### Executando apenas um teste específico

```bash
uv run pytest tests/test_analise.py::test_media_simples
```

---

### Diferença entre dependência normal e dependência de desenvolvimento

Uma dependência normal é necessária para o programa funcionar.

Exemplo:

```bash
uv add pandas
```

Nesse caso, `pandas` é usado pelo arquivo `analise.py`.

Uma dependência de desenvolvimento é necessária apenas para desenvolver, testar ou validar o projeto.

Exemplo:

```bash
uv add --dev pytest
```

Nesse caso, `pytest` é usado para testar o projeto, mas não faz parte da lógica principal da aplicação.

---

### Sincronizando sem dependências de desenvolvimento

Em alguns cenários, como produção, você pode querer instalar apenas as dependências principais do projeto, sem ferramentas de desenvolvimento.

Para isso:

```bash
uv sync --no-dev
```

Nesse caso, o `pytest` não será instalado.

Para voltar ao ambiente completo de desenvolvimento:

```bash
uv sync
```

Como o grupo `dev` é sincronizado por padrão, o `pytest` volta a estar disponível.

---

## 11. Visualizando dependências com `uv tree`

Para visualizar a árvore de dependências do projeto:

```bash
uv tree
```

A saída mostra as dependências diretas e transitivas.

Exemplo aproximado:

```text
meu-projeto v0.1.0
├── pandas v...
│   ├── numpy v...
│   ├── python-dateutil v...
│   ├── pytz v...
│   └── tzdata v...
└── pytest v...
    ├── iniconfig v...
    ├── packaging v...
    ├── pluggy v...
    └── pygments v...
```

Mesmo depois de remover `numpy` como dependência direta, ele pode continuar aparecendo na árvore porque `pandas` depende de `numpy`.

Essa é uma boa diferença para explicar em aula:

* dependência direta: você adicionou explicitamente com `uv add`;
* dependência transitiva: outro pacote precisa dela para funcionar;
* dependência de desenvolvimento: ferramenta usada no desenvolvimento, como `pytest` ou `ruff`.

---

## 12. Criando ambiente virtual com `uv venv`

O `uv` normalmente cria e gerencia o `.venv` automaticamente quando usamos comandos como:

```bash
uv run analise.py
uv sync
```

Mas também podemos criar o ambiente virtual manualmente.

Remova o ambiente atual:

```bash
rm -rf .venv
```

Crie um novo ambiente virtual com Python 3.13:

```bash
uv venv --python 3.13
```

Ative o ambiente, se quiser usar comandos diretamente sem `uv run`:

```bash
source .venv/bin/activate
```

Agora confira o Python usado:

```bash
python --version
which python
```

Mesmo com o ambiente ativado, o fluxo recomendado no projeto continua sendo:

```bash
uv sync
uv run analise.py
```

---

## 13. Listando versões de Python com `uv python list`

O `uv` também consegue localizar e gerenciar versões de Python.

Para listar versões disponíveis e instaladas:

```bash
uv python list
```

A saída pode mostrar versões instaladas localmente e versões que o `uv` consegue baixar.

Exemplo aproximado:

```text
cpython-3.14.0-linux-x86_64-gnu
cpython-3.13.5-linux-x86_64-gnu
cpython-3.12.11-linux-x86_64-gnu
cpython-3.11.13-linux-x86_64-gnu
```

Dentro do nosso container, a versão principal esperada é Python 3.13, porque a imagem base é `python:3.13-slim`.

---

## 14. Encontrando o interpretador com `uv python find`

Para encontrar o caminho do Python que será usado:

```bash
uv python find
```

Exemplo de saída:

```text
/workspace/meu-projeto/.venv/bin/python
```

Para procurar uma versão específica:

```bash
uv python find 3.13
```

Exemplo de saída:

```text
/usr/local/bin/python3.13
```

Esse comando é útil para entender qual interpretador Python está sendo usado pelo projeto.

---

## 15. Usando lint de código com Ruff

Agora vamos usar lint para encontrar problemas no código.

Instale o `ruff` como dependência de desenvolvimento:

```bash
uv add --dev ruff
```

Execute o lint:

```bash
uv run ruff check .
```

O Ruff deve encontrar um problema no arquivo `analise.py`, porque importamos `os`, mas não usamos esse pacote.

Erro esperado aproximado:

```text
F401 `os` imported but unused
```

Corrija automaticamente o que for seguro:

```bash
uv run ruff check . --fix
```

Agora rode novamente:

```bash
uv run ruff check .
```

Saída esperada:

```text
All checks passed!
```

Também é possível formatar o código com Ruff:

```bash
uv run ruff format .
```

---

## 16. Executando ferramentas temporárias com `uvx`

O `uvx` permite executar ferramentas Python em ambientes temporários e isolados.

Isso é útil quando você quer usar uma ferramenta uma vez, sem adicioná-la como dependência do projeto.

Exemplo:

```bash
uvx pycowsay "Olá, turma!"
```

Outro exemplo com `ruff`:

```bash
uvx ruff check .
```

Diferença importante:

```bash
uvx ruff check .
```

Executa o `ruff` temporariamente, sem registrar a ferramenta no projeto.

```bash
uv add --dev ruff
uv run ruff check .
```

Registra o `ruff` como dependência de desenvolvimento do projeto.

Em projetos reais, prefira `uv add --dev ruff` quando a ferramenta fizer parte do fluxo oficial do projeto.

Use `uvx` quando quiser apenas testar ou executar uma ferramenta pontualmente.

---

## 17. Dependências inline em scripts Python

Nem todo código Python precisa virar um projeto completo.

O `uv` também permite declarar dependências diretamente dentro de um único arquivo Python.

Esse recurso é útil para:

* automações pequenas;
* scripts de demonstração;
* exemplos isolados;
* tarefas rápidas.

Volte para o diretório anterior:

```bash
cd ..
```

Crie um script simples:

```bash
cat > script_inline.py <<'EOF'
import rich

rich.print("[bold green]Olá usando dependência inline com uv![/bold green]")
EOF
```

Se você executar diretamente, pode dar erro porque `rich` ainda não está instalado nesse script:

```bash
uv run --no-project script_inline.py
```

Erro esperado aproximado:

```text
ModuleNotFoundError: No module named 'rich'
```

Agora adicione a dependência diretamente ao script:

```bash
uv add --script script_inline.py rich
```

O `uv` vai alterar o próprio arquivo `script_inline.py`, adicionando metadados no topo.

O arquivo ficará parecido com isto:

```python
# /// script
# dependencies = [
#   "rich",
# ]
# ///

import rich

rich.print("[bold green]Olá usando dependência inline com uv![/bold green]")
```

Agora execute:

```bash
uv run script_inline.py
```

Dessa vez o `uv` lê os metadados do próprio script, cria um ambiente temporário adequado e instala a dependência necessária.

Também é possível fixar uma versão:

```bash
uv add --script script_inline.py "rich>=13,<14"
```

Quando usar esse recurso:

* use dependências inline para scripts pequenos e independentes;
* use `uv init` quando o código virar um projeto;
* use `pyproject.toml` quando houver vários arquivos, testes, lint, build ou colaboração com outras pessoas.

Volte para o projeto principal:

```bash
cd meu-projeto
```

---

## 18. Exportando dependências para `requirements.txt`

Mesmo usando `uv`, você pode encontrar ferramentas legadas que esperam um arquivo `requirements.txt`.

Para exportar as dependências do projeto:

```bash
uv export --format requirements.txt --output-file requirements.txt
```

Confira o arquivo gerado:

```bash
cat requirements.txt
```

O arquivo `requirements.txt` gerado pode ser usado por ferramentas que ainda trabalham com `pip`.

Exemplo:

```bash
pip install -r requirements.txt
```

Atenção: em projetos que usam `uv`, o arquivo principal de controle de dependências deve continuar sendo o `pyproject.toml` junto com o `uv.lock`.

O `requirements.txt` deve ser visto como uma exportação para compatibilidade.

Em geral, evite manter `uv.lock` e `requirements.txt` como duas fontes manuais de verdade. Se precisar de `requirements.txt`, gere-o novamente a partir do `uv`.

---

## 19. Build de pacote Python com `uv build`

Até aqui, criamos um projeto com:

```bash
uv init meu-projeto
```

Esse formato é adequado para aplicações simples, scripts, APIs e experimentos.

Para demonstrar build de pacote, vamos criar um segundo projeto, próprio para empacotamento.

Volte para o diretório anterior:

```bash
cd ..
```

Crie uma aplicação empacotável:

```bash
uv init --package meu-pacote
cd meu-pacote
```

A estrutura será parecida com esta:

```text
meu-pacote/
├── .python-version
├── README.md
├── pyproject.toml
└── src/
    └── meu_pacote/
        └── __init__.py
```

Execute o comando criado pelo projeto:

```bash
uv run meu-pacote
```

Saída esperada aproximada:

```text
Hello from meu-pacote!
```

Agora gere os artefatos de distribuição:

```bash
uv build
```

O resultado será criado na pasta `dist/`.

Confira:

```bash
ls -la dist
```

Saída esperada aproximada:

```text
meu_pacote-0.1.0-py3-none-any.whl
meu_pacote-0.1.0.tar.gz
```

Esses arquivos são:

* `.whl`: pacote binário Python, usado para instalação mais rápida;
* `.tar.gz`: distribuição fonte do projeto.

Antes de gerar um build em um projeto real, rode:

```bash
uv sync
uv run pytest
uv run ruff check .
uv build
```

Observação: neste projeto `meu-pacote`, ainda não instalamos `pytest` nem `ruff`. Esses comandos representam o fluxo recomendado quando o projeto já possui testes e lint configurados.

Volte para o projeto principal, se quiser continuar o tutorial anterior:

```bash
cd ../meu-projeto
```

---

## 20. Conferindo os arquivos do projeto principal

Depois dos comandos anteriores, a estrutura do projeto principal deve estar parecida com esta:

```text
meu-projeto/
├── .python-version
├── .venv/
├── README.md
├── analise.py
├── main.py
├── pyproject.toml
├── requirements.txt
├── tests/
│   └── test_analise.py
└── uv.lock
```

O arquivo `pyproject.toml` deve conter algo parecido com:

```toml
[project]
name = "meu-projeto"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "pandas>=...",
]

[dependency-groups]
dev = [
    "pytest>=...",
    "ruff>=...",
]
```

O arquivo `uv.lock` registra as versões exatas resolvidas pelo `uv`.

---

## 21. Resumo dos comandos usados

| Etapa                                 | Comando                                                              |
| ------------------------------------- | -------------------------------------------------------------------- |
| Build da imagem Docker                | `docker build -t python-uv-lab .`                                    |
| Rodar container                       | `docker run --rm -it --name uv-lab python-uv-lab`                    |
| Criar projeto                         | `uv init meu-projeto`                                                |
| Executar script                       | `uv run analise.py`                                                  |
| Adicionar dependências                | `uv add pandas numpy`                                                |
| Remover dependência                   | `uv remove numpy`                                                    |
| Sincronizar ambiente                  | `uv sync`                                                            |
| Adicionar pytest como dependência dev | `uv add --dev pytest`                                                |
| Rodar testes                          | `uv run pytest`                                                      |
| Ver árvore de dependências            | `uv tree`                                                            |
| Criar ambiente virtual                | `uv venv --python 3.13`                                              |
| Listar versões de Python              | `uv python list`                                                     |
| Encontrar Python usado                | `uv python find`                                                     |
| Adicionar Ruff                        | `uv add --dev ruff`                                                  |
| Rodar lint                            | `uv run ruff check .`                                                |
| Corrigir lint automaticamente         | `uv run ruff check . --fix`                                          |
| Formatar código                       | `uv run ruff format .`                                               |
| Executar ferramenta temporária        | `uvx pycowsay "Olá, turma!"`                                         |
| Adicionar dependência inline          | `uv add --script script_inline.py rich`                              |
| Executar script inline                | `uv run script_inline.py`                                            |
| Exportar requirements                 | `uv export --format requirements.txt --output-file requirements.txt` |
| Criar projeto empacotável             | `uv init --package meu-pacote`                                       |
| Gerar build de pacote                 | `uv build`                                                           |

---

## 22. Fluxo final recomendado

Em um projeto real, o ciclo mais comum seria:

```bash
uv sync
uv run analise.py
uv run pytest
uv run ruff check .
uv run ruff format .
uv tree
```

Antes de enviar o projeto para outra pessoa:

```bash
uv sync
uv run pytest
uv run ruff check .
uv run ruff format .
uv run analise.py
```

Antes de gerar um pacote distribuível:

```bash
uv sync
uv run pytest
uv run ruff check .
uv build
```

Arquivos que devem ser versionados no Git:

```text
pyproject.toml
uv.lock
.python-version
README.md
main.py
analise.py
tests/
```

Arquivos que normalmente não devem ser versionados:

```text
.venv/
__pycache__/
.ruff_cache/
.pytest_cache/
dist/
*.egg-info/
.env
```

Exemplo de `.gitignore`:

```gitignore
.venv/
__pycache__/
.ruff_cache/
.pytest_cache/
dist/
*.egg-info/
.env
```

---

## 23. Próximos passos

Depois deste tutorial, os próximos temas interessantes são:

* usar Docker com volume para preservar os arquivos fora do container;
* abrir o container pelo VS Code com a extensão Dev Containers;
* criar um pipeline de CI com GitHub Actions;
* publicar um pacote em um repositório como PyPI;
* usar `uv lock --check` e `uv sync --frozen` em automações.

```
```
