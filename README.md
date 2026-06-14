# 🚀 AstroPod-Chiaki (v2.0)
> **PlayStation Remote Play em Docker** — Aceleração de Vídeo, Áudio Síncrono e Controles Físicos com Latência Zero.

Esta é a especificação de implantação da cápsula **AstroPod-Chiaki**, configurada para compilar e executar o **Chiaki v2.2.0** de forma isolada, limpa e resiliente em sistemas Linux modernos (testado com sucesso no **Ubuntu 26.04 LTS**).

---

## 🗺️ Fluxo de Arquitetura e Conectividade

O diagrama abaixo ilustra como o container Docker interage diretamente com o hardware do seu notebook host e com a sua rede local para transmitir a jogabilidade do PS5:

```mermaid
graph TD
    subgraph Host [Notebook Host - Ubuntu 26.04]
        C[Controle DualSense via USB-C] -- /dev/input & hidraw --> OS[Regras Udev/steam-devices]
        A[Áudio - PipeWire/PulseAudio] -- native socket --> PW[/run/user/1000/pulse/native]
        G[Vídeo - Mesa Drivers] -- DRI render nodes --> GPU[/dev/dri]
        D[Exibição - XWayland/X11] -- unix socket --> X11[/tmp/.X11-unix]
    end

    subgraph Container [Cápsula AstroPod - Privilegiada]
        Chiaki[Executável Chiaki v2.2.0]
        Chiaki -- SDL2 / SDL_JOYSTICK_DISABLE_UDEV --> C
        Chiaki -- Áudio Redirecionado --> PW
        Chiaki -- Aceleração por Hardware --> GPU
        Chiaki -- Renderização GUI --> X11
    end

    subgraph Rede Local [Rede de Casa]
        Chiaki -- host network/UDP 987 --> PS5[PlayStation 5]
    end
```

---

## ⚡ Tabela de Recursos Suportados

| Recurso | Método de Integração | Status | Benefício Principal |
| :--- | :--- | :---: | :--- |
| **Interface Gráfica** | X11/XWayland Socket (`/tmp/.X11-unix`) |  | Exibição nativa na sua área de trabalho sem necessidade de VNC/noVNC. |
| **Áudio Sincronizado** | Pipewire-Pulse Socket Mount |  | Som estéreo de alta fidelidade sem atrasos ou distorções. |
| **Conexão PS5** | Rede de Host (`network_mode: host`) |  | Descoberta automática de console na rede local via UDP Broadcast. |
| **Controles de Jogo** | Passagem de `/dev` + Modo Privilegiado |  | Suporte completo a vibração, botões e analógicos do DualSense via cabo. |
| **Aceleração 3D** | Montagem de Dispositivos (`/dev/dri`) |  | Decodificação de vídeo eficiente (VA-API com fallback para CPU). |
| **Persistência** | Bind Mount local (`./data:/home/chiaki`) |  | Mantém o login, pareamento e chaves de segurança salvos no host. |

---

## 📋 Requisitos Prévios no Sistema Host

Para que todos os periféricos (especialmente o controle) funcionem no Docker, seu computador precisa ter as seguintes dependências instaladas:

1.  **Docker & Docker Compose** (versões estáveis recentes instaladas).
2.  **Aceleração de Hardware:** Drivers gráficos de GPU ativos (Mesa para Intel/AMD).
3.  **Regras de Controle (Udev):** Pacote `steam-devices` instalado para conceder permissão de leitura sobre a porta USB-C do controle:
    ```bash
    sudo apt update && sudo apt install -y steam-devices
    ```
    *Nota: Após instalar este pacote, remova o controle da porta USB e conecte-o novamente.*

---

## 🛠️ Guia de Configuração e Pareamento Inicial

### Passo 1: Preparar o PlayStation 5
1.  Na sua TV, vá em **Configurações** ➡ **Sistema** ➡ **Uso Remoto** e ative **Habilitar uso remoto**.
2.  (Recomendado) Vá em **Configurações** ➡ **Sistema** ➡ **Economia de energia** ➡ **Recursos disponíveis no modo de repouso** e ative **Continuar conectado à Internet** e **Habilitar ligar o PS5 a partir da rede**.
3.  Vá em **Configurações** ➡ **Sistema** ➡ **Uso Remoto** ➡ **Vincular dispositivo**. Guarde o PIN de 8 dígitos gerado (ele expira em 300 segundos).

### Passo 2: Obter o seu PSN Account ID (Base64)
A Sony exige o ID interno da sua conta criptografado para o pareamento.
1.  Execute o script Python auxiliar incluído na pasta do projeto:
    ```bash
    python3 psn-account-id.py
    ```
2.  Abra o link longo exibido no seu navegador, faça login na sua conta da PlayStation Network.
3.  Quando a página redirecionar e ficar em branco, copie a URL da barra de endereços do seu navegador.
4.  Cole a URL de volta no terminal onde o script está rodando e pressione **Enter** para obter o seu **AccountID (Base64)**.

---

## 🚀 Como Executar o Container

Abra o terminal no diretório `/home/nauakavlis/DockerApps/astropod-chiaki` e siga a sequência:

### 1. Permitir Conexão de Tela Local
Libere o Docker para renderizar a interface na sua área de trabalho:
```bash
xhost +local:docker
```

### 2. Compilar e Iniciar a Cápsula
Suba o container em segundo plano:
```bash
docker compose -f docker_compose.yaml up -d --build
```
*A janela do Chiaki se abrirá automaticamente na tela do seu computador.*

### 3. Parear o Console
1.  Dê um duplo clique no PS5 detectado na interface do Chiaki.
2.  Preencha as informações:
    *   **PSN Online-ID:** Seu apelido da PSN (ex: `Nauak_Avlis_`).
    *   **PSN Account-ID:** O ID Base64 gerado pelo script no Passo 2.
    *   **PIN:** O código de 8 dígitos exibido na TV.
3.  Clique em **Register**. Uma mensagem de pareamento bem-sucedido será exibida.

### 4. Jogar!
Conecte o controle via cabo USB-C ao seu notebook, dê dois cliques rápidos no ícone do PS5 no Chiaki e aproveite!

---

## ⚠️ Solução de Problemas (Troubleshooting)

> [!WARNING]
> **Erro `Failed to create hwdevice context` (VA-API):**
> Se a transmissão fechar ou travar ao iniciar o jogo exibindo essa mensagem, abra as configurações do Chiaki (ícone de engrenagem) e mude o campo **Hardware decode method** para **`none`**. Isso fará o processador do notebook decodificar o vídeo via software de forma extremamente estável e sem perda de desempenho perceptível (a CPU lida facilmente com o fluxo de 1080p 60fps).

> [!IMPORTANT]
> **Controle não responde aos comandos (Touchpad funciona como mouse):**
> *   Verifique se instalou o pacote `steam-devices` no host e reconectou o cabo USB-C.
> *   Nas configurações do Chiaki (engrenagem) ➡ aba **Controller**, certifique-se de escolher o DualSense no menu de seleção superior e aplicar a configuração.
> *   O controle **só responderá quando a tela de transmissão do jogo estiver aberta**. Ele não funciona nos menus iniciais de lista de consoles do Chiaki.

> [!TIP]
> **Configurações Recomendadas de Performance:**
> Para obter a melhor qualidade de imagem e som no Linux, aplique os seguintes valores nas configurações do Chiaki:
> *   **Audio Buffer Size:** `19200` (evita chiados e estalos no som do jogo).
> *   **Bitrate:** `30000` (melhora a nitidez visual significativamente se a rede for estável).
> *   **Codec:** `H265 (PS5 only)` (decodificação mais leve e eficiente).

---

## 💾 Persistência de Dados e Reinicializações

> [!NOTE]
> **Segurança de Pareamento:** Graças ao bind mount mapeado no diretório `./data`, todas as suas credenciais, chaves de pareamento e configurações são salvas localmente e protegidas no seu computador host.
>
> Você pode parar o container (`docker compose down`), reiniciar o computador ou recriar a imagem a qualquer momento. Você **não perderá o pareamento**. Da próxima vez, basta ligar o PS5, abrir o Chiaki no PC e dar duplo clique para começar a jogar!
