# Rotorflight BW Dashboard

Projeto Lua de telemetria para radios FrSky monocromaticos com OpenTX/EdgeTX, inspirado no Rotorflight Suite, mas adaptado para telas preto e branco e hardware mais limitado.

## Status

MVP inicial:

- Estrutura de projeto separada por responsabilidades
- Uma unica tela de telemetria
- Fallback seguro para sensores ausentes
- Suporte a dados simulados para desenvolvimento inicial
- Avisos simples na area inferior

Ainda nao implementado nesta primeira versao:

- Auto-deteccao avancada de sensores
- Multiplas telas
- Graficos
- Integracao ajustada para todas as variacoes de telemetria Rotorflight

## Estrutura

```text
/SCRIPTS/TELEMETRY/RFMONO.lua
/SCRIPTS/TELEMETRY/lib/config.lua
/SCRIPTS/TELEMETRY/lib/sensors.lua
/SCRIPTS/TELEMETRY/lib/layout.lua
/SCRIPTS/TELEMETRY/lib/alerts.lua
```

## Instalacao no SD card

Copie os arquivos para o cartao SD do radio com esta estrutura:

```text
/SCRIPTS/TELEMETRY/RFMONO.lua
/SCRIPTS/TELEMETRY/lib/config.lua
/SCRIPTS/TELEMETRY/lib/sensors.lua
/SCRIPTS/TELEMETRY/lib/layout.lua
/SCRIPTS/TELEMETRY/lib/alerts.lua
```

Se a pasta `lib` ainda nao existir dentro de `SCRIPTS/TELEMETRY`, crie-a manualmente.

## Deploy rapido para o simulador no VS Code

O projeto inclui uma task do VS Code para copiar os arquivos direto para o SD do simulador EdgeTX.

Arquivo de configuracao:

[settings.json](C:/Users/vhuza/Documents/Rotorflight%20BW%20Dashboard/.vscode/settings.json)

Campo configuravel:

```json
{
  "rfmono.simulatorSdRoot": "C:\\Users\\vhuza\\Documents\\EdgeTX\\Taranis X9D 2019 SE"
}
```

Task disponivel:

- `RFMONO: Deploy to EdgeTX simulator SD`

Como usar no VS Code:

1. Abra `Terminal > Run Task`
2. Escolha `RFMONO: Deploy to EdgeTX simulator SD`

O deploy copia estes arquivos para `${rfmono.simulatorSdRoot}\\SCRIPTS\\TELEMETRY\\`:

- `RFMONO.lua`
- `lib/config.lua`
- `lib/layout.lua`
- `lib/sensors.lua`
- `lib/alerts.lua`

## Como selecionar a tela de telemetria

No OpenTX/EdgeTX, va para a configuracao do modelo e selecione uma tela de telemetria do tipo `Script`.

Depois escolha o script:

`RFMONO`

O nome exibido pode variar um pouco conforme a versao do firmware, mas o arquivo a selecionar sera `RFMONO.lua`.

## Como configurar nomes de sensores

Os nomes esperados ficam em:

[config.lua](C:/Users/vhuza/Documents/Rotorflight%20BW%20Dashboard/SCRIPTS/TELEMETRY/lib/config.lua)

Voce pode ajustar os nomes usados pelo seu radio nesta tabela:

- `battery`
- `cell`
- `fuel`
- `rpm`
- `current`
- `temp`
- `rssi`
- `link`
- `governor`
- `profile`
- `armAlert`

Exemplo: se o seu sensor de RPM aparece como `RPM1` em vez de `RPM`, altere:

```lua
sensors = {
  rpm = { "RPM1", "RPM" }
}
```

O script tenta encontrar o primeiro nome disponivel da lista.

## Sensores esperados do Rotorflight

O MVP foi preparado para trabalhar com estes tipos de dados:

- Tensao total da bateria
- Tensao por celula
- Fuel % ou SmartFuel
- RPM do rotor
- Temperatura
- RSSI
- Link Quality
- Status do governor
- Perfil/bank
- Alertas de arm/disarm quando disponiveis

## Audio de bateria baixa

Quando `Bat%` chega em `lowFuelPercent`, o script toca o arquivo configurado em `config.lua`:

```lua
audio = {
  lowBatteryEnabled = true,
  lowBatteryFile = "/SOUNDS/en/lowbat.wav",
  lowBatteryRepeatSeconds = 30,
  lowBatteryResetMargin = 5
}
```

O arquivo padrao usa o audio existente no SD do EdgeTX. Se o seu pacote de sons usar outro nome, ajuste `lowBatteryFile`.

Dependendo de como a telemetria estiver configurada no Rotorflight, os nomes exatos podem variar. Por isso os aliases ficam centralizados em `config.lua`.

## Comportamento quando faltam sensores

Se um sensor nao existir:

- o script nao quebra
- o campo mostra `--`
- avisos simples podem aparecer na linha inferior, como `SENSOR?`

## Modo simulacao

O projeto suporta simulacao para testes, mas no estado atual o padrao esta configurado para telemetria real.

Para ativar a simulacao, altere em `config.lua`:

```lua
simulation = true
```

Quando `simulation = true`, o script usa valores de exemplo. Quando `false`, ele tenta ler a telemetria real do radio.

## Observacoes de compatibilidade

O projeto foi pensado para radios monocromaticos e mais antigos, como:

- FrSky Taranis X9D / X9D+ / X9D 2019
- FrSky Taranis QX7 / QX7S

O foco e manter:

- baixo consumo de CPU
- layout simples
- boa legibilidade em voo
- degradacao segura quando faltar telemetria

## Proximos passos sugeridos

- Ligar a camada de sensores a nomes reais do Rotorflight
- Adicionar deteccao melhor entre RSSI e LQ
- Refinar os avisos de bateria e RPM
- Ajustar layout para 128x64 apos teste em radio real ou simulador
