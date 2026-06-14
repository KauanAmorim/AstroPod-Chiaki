# Chiaki v2.2.0 - PlayStation Remote Play no Docker

Este repositório contém a configuração completa para compilar e executar o **Chiaki (versão v2.2.0)** — o cliente de código aberto para Remote Play de PlayStation 4 e PlayStation 5 — isolado em um container Docker, mas integrado perfeitamente ao seu sistema host Linux (Ubuntu 26.04 LTS).

---

## Como Funciona (Sob o Capô)

Para que um aplicativo de streaming de jogos com interface gráfica pesada, áudio em tempo real e suporte a controles funcione dentro do Docker, os seguintes mecanismos foram implementados:

1.  **Interface Gráfica (X11/Wayland):**
    *   O socket do servidor gráfico do seu computador (`/tmp/.X11-unix`) e a autorização (`.Xauthority`) são compartilhados com o container.
    *   A aceleração gráfica por hardware (OpenGL/Vulkan) é habilitada mapeando os nós de renderização de GPU do host (`/dev/dri`).
2.  **Áudio em Tempo Real:**
    *   O container se conecta diretamente ao servidor de som do host (PulseAudio ou PipeWire) através do socket nativo `/run/user/1000/pulse/native`, garantindo som estéreo e sem atrasos (delay).
3.  **Rede em Modo Host (`network_mode: host`):**
    *   Ativa a pilha de rede do host diretamente no container. Isso é **seguro** (o Chiaki age estritamente como cliente e não abre portas sensíveis para a internet) e **necessário** para que o Chiaki consiga enviar e receber pacotes de descoberta UDP (porta 987) e encontrar o console na sua rede local automaticamente.
4.  **Suporte a Controles (USB / Bluetooth):**
    *   Mapeia o diretório de dispositivos de entrada do Linux (`/dev/input`) para que gamepads conectados por cabo ou sem fio apareçam no container.
    *   Executa o processo de forma sincronizada com o ID do grupo `input` do seu host (GID padrão `994`), permitindo que o container leia as entradas físicas do controle sem precisar rodar em modo privilegiado ou como root.
5.  **Persistência:**
    *   Uma pasta local chamada `./data` é montada como o diretório home `/home/chiaki` do container. Isso garante que seus logins, consoles cadastrados e chaves de pareamento fiquem salvos localmente na sua máquina de forma permanente.

---

## Requisitos do Sistema Host

*   **Sistema Operacional:** Ubuntu 26.04 LTS (ou qualquer distribuição Linux moderna).
*   **Docker Engine:** Versão `29.5.x` ou posterior.
*   **Docker Compose:** Versão v2 (plugin `docker-compose-plugin` `5.1.x` ou posterior).
*   **Aceleração Gráfica:** Drivers Mesa (Intel, AMD ou Nouveau) instalados.

---

## 🛠️ Passo a Passo para Configuração

### 1. Preparar o PS5
Antes de abrir o aplicativo, configure o seu console:
1.  Vá em **Configurações** -> **Sistema** -> **Uso Remoto** e ative **Habilitar uso remoto**.
2.  (Opcional, mas recomendado) Vá em **Configurações** -> **Sistema** -> **Economia de energia** -> **Recursos disponíveis no modo de repouso** e ative **Continuar conectado à Internet** e **Habilitar ligar o PS5 a partir da rede** para poder ligar o console em modo repouso via Chiaki.
3.  Vá em **Configurações** -> **Sistema** -> **Uso Remoto** e clique em **Vincular dispositivo**. Um código PIN de 8 dígitos será mostrado. Deixe essa tela aberta.

### 2. Obter o seu PSN Account ID (Base64)
A Sony exige o ID interno da sua conta para o vínculo.
1.  Acesse o site comunitário seguro: [https://psn.flipscreen.games/](https://psn.flipscreen.games/)
2.  Faça login no site oficial da PlayStation através do link fornecido.
3.  Após fazer login, você será redirecionado para uma página em branco. Copie a URL completa dessa página.
4.  Cole a URL de volta no site da flipscreen e ele gerará o seu **Account ID (Base64)**. Copie esse código.

---

## 🚀 Como Compilar e Rodar o Container

Abra um terminal no diretório deste repositório e execute os comandos abaixo:

### Passo A: Permitir conexões de display locais
Para permitir que o container exiba a interface gráfica na sua tela:
```bash
xhost +local:docker
```

### Passo B: Compilar a Imagem
Este comando irá baixar o código-fonte original do Chiaki na tag `v2.2.0`, instalar todas as dependências de build dentro do container e compilar o executável:
```bash
docker compose -f docker_compose.yaml build
```

### Passo C: Iniciar o Chiaki
Inicie o container em segundo plano:
```bash
docker compose -f docker_compose.yaml up -d
```
A janela gráfica do Chiaki se abrirá.

### Passo D: Registrar o Console no Aplicativo
1.  Dê um duplo clique no PS5 detectado na interface gráfica do Chiaki.
2.  Cole o seu **PSN Account ID (Base64)** no respectivo campo.
3.  Digite o **PIN de 8 dígitos** gerado na TV do seu PS5.
4.  Clique em **Register**. O console ficará cadastrado e pronto para jogar.

### Passo E: Parar a Execução
Para fechar o aplicativo e parar o container:
```bash
docker compose -f docker_compose.yaml down
```

---

## Solução de Problemas comuns

*   **Erro de tela preta ou "Cannot open display":**
    Certifique-se de executar `xhost +local:docker` na sua máquina host antes de subir o container.
*   **O som do jogo não funciona:**
    Verifique se o seu áudio do host está ativo e se o arquivo `/run/user/1000/pulse/native` existe. Caso o UID do seu usuário host seja diferente de 1000, você pode exportar a variável antes de rodar o comando:
    ```bash
    export UID=$(id -u)
    docker compose -f docker_compose.yaml up -d
    ```
*   **O controle não é detectado:**
    Verifique se o seu controle está pareado/conectado. Se o ID do grupo de entrada (`input`) do seu computador host for diferente de 994, você pode verificar o ID correto com `getent group input` e rodar a aplicação definindo esse GID:
    ```bash
    export INPUT_GID=$(getent group input | cut -d: -f3)
    docker compose -f docker_compose.yaml up -d
    ```
