# Seus primeiros vídeos com LongCat

Seu fork: https://github.com/cyllio/LongCat-Video

## Começar gratuitamente, sem contratar GPU

Para os primeiros testes, use a demonstração comunitária no navegador:
https://huggingface.co/spaces/sleepydoug1992/longcat-video

1. Abra o link. Se a demonstração estiver em repouso, use a opção de despertar
   exibida pela página e aguarde. A disponibilidade depende do mantenedor.
2. Entre com uma conta gratuita do Hugging Face se a página solicitar.
3. Descreva sua cena, deixe a imagem vazia e comece com `320x576 (fastest)`,
   `Frames: 21` e `Fast mode (distilled 16 steps)` ativado.
4. Gere um vídeo curto e baixe o resultado quando estiver pronto.

O serviço ZeroGPU tem fila e cota diária. A documentação consultada em
18/11/2026 informa 5 minutos de GPU por dia para contas gratuitas; a quantidade
de vídeos depende do tempo de processamento. Não é preciso contratar Runpod.
Fonte: https://huggingface.co/docs/hub/spaces-zerogpu

Esse fluxo foi verificado com uma geração de dois lutadores de kung fu na praia
ao entardecer: 21 quadros a 15 fps (1,4 segundo), 576 × 320, seed 42. A interface
informou 30 segundos de geração. O MP4 foi salvo em `../outputs/` no computador
local. A demonstração anterior de aiboostJP foi substituída por apresentar o erro
`ZeroGPU illegal duration` no modo texto; o código do servidor de terceiros não
foi alterado.

Para vídeos de uma pessoa falando a partir de foto e áudio, esta alternativa
estava ativa na consulta inicial:
https://huggingface.co/spaces/victor/LongCat-Video-Avatar-1.5

Essas demonstrações rodam no ambiente dos responsáveis pelos Spaces. Elas não
executam o seu fork do GitHub. As instruções abaixo são uma opção futura para
usar sua própria instalação com GPU dedicada.

## O que já está preparado

O código foi clonado e este roteiro instala o modelo original para criar vídeos
a partir de texto, imagens e continuação de vídeo. O computador local, com vídeo
integrado Intel e aproximadamente 8 GB de RAM, será usado para acessar a interface
no navegador. A geração precisa acontecer em uma máquina Linux com GPU NVIDIA.

Os scripts estão preparados, mas a instalação e a geração na GPU ainda precisam
ser executadas e verificadas no servidor. Nenhum servidor pago foi contratado.

## Máquina sugerida para começar

- Runpod Pod com **1 GPU A100 de 80 GB**, preferencialmente com pelo menos 64 GB de RAM.
- Imagem com Conda, compilador CUDA 12.4 e PyTorch; uma opção é
  `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`.
- Reserve **150 GB de volume persistente**, montado em `/workspace`, com pelo menos
  100 GiB livres antes de instalar. Isso é uma margem de planejamento, não o
  tamanho exato do modelo.
- Configure SSH por TCP; copie o usuário, endereço e porta fornecidos pelo painel.
  O computador local já possui Git e GitHub CLI.

Os mantenedores informam que 80 GB de VRAM são suficientes para todas as funções
das demonstrações: https://github.com/meituan-longcat/LongCat-Video/issues/19

Preços consultados em 18/11/2026: A100 PCIe a partir de US$ 1,19/h no Community
Cloud ou US$ 2,09/h no Secure Cloud. A disponibilidade e o total devem ser
confirmados no painel. Armazenamento e eventuais impostos são adicionais.
Fonte: https://www.runpod.io/pricing

## Instalação no servidor

Execute no terminal **do Pod**, dentro de uma sessão persistente SSH ou tmux:

```bash
cd /workspace
git clone https://github.com/cyllio/LongCat-Video.git
cd LongCat-Video
bash scripts/setup-cloud.sh
```

O instalador cria Python 3.10 isolado em `.venv`, instala PyTorch 2.6/CUDA 12.4,
FlashAttention 2 e as dependências, verifica a GPU e baixa os pesos oficiais.
O download e a compilação podem demorar; esse tempo também consome horas do Pod.
Se houver interrupção, execute o instalador novamente para aproveitar o cache.
Não são instalados os modelos Avatar, que têm dependências e pesos adicionais.

Se já houver uma pasta `LongCat-Video` no servidor, entre nela e execute `git pull`
em vez de clonar novamente, depois rode o instalador.

## Abrir a interface no seu computador

No servidor, execute:

```bash
bash scripts/start-cloud.sh
```

No PowerShell do seu computador, abra outro terminal e adapte o comando com os
dados SSH do Pod. A conexão precisa oferecer encaminhamento de portas por TCP:

```powershell
ssh -p PORTA_SSH -L 8501:127.0.0.1:8501 USUARIO@ENDERECO_DO_POD
```

Se o provedor exigir uma chave, acrescente `-i CAMINHO_DA_CHAVE` ao comando.
Mantenha a conexão aberta e acesse http://localhost:8501 no navegador.
A interface fica acessível por esse túnel SSH, sem publicar uma porta web aberta.
Documentação: https://docs.runpod.io/pods/connect-to-a-pod

## Primeiro teste

1. Aguarde o carregamento do modelo e mantenha `Model Dir` em `./weights/LongCat-Video`.
2. Selecione `T2V (Text-to-Video)` e marque `Enable Distill Mode`.
3. Comece com 480 × 832, seed 42 e sem super-resolução.
4. Cole o exemplo abaixo e clique em `Generate`.
5. Baixe o MP4 pela interface. Salve os vídeos no computador antes de encerrar o Pod.

```text
A cinematic shot of a small wooden boat floating slowly on a calm lake at
sunrise. Soft golden light reflects on the water. Mist rises gently near the
forest in the background. The camera moves forward smoothly. Realistic natural
colors, detailed water reflections, peaceful atmosphere, no text or logos.
```

A interface original usa 93 quadros, cerca de 6 segundos a 15 fps. Para animar
uma foto, selecione `I2V` e envie sua imagem. Descrições detalhadas em inglês são
um ponto de partida para os primeiros testes; ajuste uma variável por vez.

## Encerrar e retomar

Interrompa o aplicativo com Ctrl+C. Isso **não encerra a cobrança da GPU**:
pare o Pod no painel quando terminar. O volume pode continuar sendo cobrado.
Antes de excluir o Pod ou volume, baixe seus vídeos e confira quais arquivos
persistirão. Ao retomar, inicie o Pod, reconecte o SSH e execute
`bash scripts/start-cloud.sh` na pasta do projeto.

## Se a instalação falhar

- `Falta nvcc` ou CUDA diferente de 12.4: escolha a imagem **devel** indicada.
- GPU ausente: confira se o Pod tem uma NVIDIA alocada e se `nvidia-smi` funciona.
- Erro de memória na compilação: tente `MAX_JOBS=2 bash scripts/setup-cloud.sh`.
- Erro durante o download: execute o instalador novamente; o download usa cache.
- Falta de espaço: aumente o volume persistente, sem apagar a pasta de pesos.

Não coloque senhas, chaves SSH, tokens ou arquivos pessoais no repositório público.
O arquivo README.md original permanece como referência técnica do projeto.
