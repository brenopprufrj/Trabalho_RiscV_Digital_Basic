# CPU RISC-V 32-bit Pipeline (RV32I)

## Descrição do Projeto

Implementação de uma CPU RISC-V de 32 bits com arquitetura de pipeline de 5 estágios, desenvolvida em VHDL para uso com o simulador Digital.

### Características

- **Arquitetura**: RISC-V RV32I (subset de inteiros)
- **Pipeline**: 5 estágios (IF, ID, EX, MEM, WB)
- **Hazard Handling**: Detecção de hazards + data forwarding
- **Memórias**: Interfaces separadas para instruções (ROM) e dados (RAM)
- **Debug**: Múltiplas saídas para aferição de estados internos

### Instruções Suportadas

| Tipo | Instruções |
|------|------------|
| **Aritméticas** | `add`, `addi`, `auipc`, `sub` |
| **Lógicas** | `and`, `andi`, `or`, `ori`, `xor`, `xori` |
| **Deslocamento** | `sll`, `slli`, `srl`, `srli` |
| **Memória** | `lw`, `lui`, `sw` |
| **Controle** | `jal`, `jalr`, `beq`, `bne` |

---

## Estrutura do Pipeline

```
┌────┐    ┌────┐    ┌────┐    ┌─────┐    ┌────┐
│ IF │───►│ ID │───►│ EX │───►│ MEM │───►│ WB │
└────┘    └────┘    └────┘    └─────┘    └────┘
   │         │         │          │         │
   ▼         ▼         ▼          ▼         ▼
 Fetch   Decode   Execute    Memory    Write
  PC     RegFile    ALU       R/W      Back
```

- **IF (Instruction Fetch)**: Busca instrução da memória ROM
- **ID (Instruction Decode)**: Decodifica instrução, lê registradores
- **EX (Execute)**: Executa operação na ALU
- **MEM (Memory Access)**: Acessa memória de dados
- **WB (Write Back)**: Escreve resultado no banco de registradores

---

## Arquivos do Projeto

| Arquivo | Descrição |
|---------|-----------|
| `alu.vhd` | Unidade Lógico-Aritmética (ADD, SUB, AND, OR, XOR, SLL, SRL) |
| `register_file.vhd` | Banco de 32 registradores de 32 bits |
| `instruction_decoder.vhd` | Decodificador de instruções + gerador de imediatos |
| `control_unit.vhd` | Unidade de controle principal |
| `pipeline_regs.vhd` | Registradores de pipeline (IF/ID, ID/EX, EX/MEM, MEM/WB) |
| `hazard_unit.vhd` | Detecção de hazards de dados e controle |
| `forwarding_unit.vhd` | Data forwarding (bypass) |
| `branch_comparator.vhd` | Comparador para instruções de branch |
| `program_counter.vhd` | Contador de programa |
| `riscv_cpu.vhd` | Módulo top-level (integra todos os componentes) |
| `instruções.md` | Instruções de configuração e uso no simulador Digital |

---

## Interface da CPU (Top-Level)

### Entradas

| Sinal | Bits | Descrição |
|-------|------|-----------|
| `clk_i` | 1 | Clock do sistema |
| `reset_i` | 1 | Reset síncrono (ativo alto) |
| `load_enable_i` | 1 | Pausa a CPU durante carga de memória |
| `imem_data_i` | 32 | Dados da memória de instruções |
| `dmem_rdata_i` | 32 | Dados lidos da memória de dados |
| `reg_sel_i` | 5 | Seleção de registrador para debug |

### Saídas

| Sinal | Bits | Descrição |
|-------|------|-----------|
| `imem_addr_o` | 32 | Endereço para memória de instruções |
| `dmem_addr_o` | 32 | Endereço para memória de dados |
| `dmem_wdata_o` | 32 | Dados para escrita na memória |
| `dmem_we_o` | 1 | Write enable da memória de dados |
| `pc_debug_o` | 32 | Valor atual do PC |
| `instr_debug_o` | 32 | Instrução atual (estágio ID) |
| `alu_result_debug_o` | 32 | Resultado da ALU |
| `reg_debug_o` | 32 | Valor do registrador selecionado |
| `hazard_stall_o` | 1 | Indicador de stall |
| `hazard_flush_o` | 1 | Indicador de flush |

---

## Tratamento de Hazards

### Data Hazards (RAW)

1. **Forwarding**: Dados são encaminhados dos estágios MEM e WB para EX
2. **Stall**: Para load-use hazards, insere uma bolha no pipeline

### Control Hazards

- Branches são resolvidos no estágio EX
- Quando branch é tomado, instruções em IF e ID são descartadas (flush)

---

## Como Usar

Consulte o arquivo [instruções.md](instruções.md) para instruções detalhadas sobre:

1. Configuração do ambiente (GHDL + Digital)
2. Adição de componentes VHDL no Digital
3. Criação do circuito de teste
4. Carregamento de programas
5. Uso dos sinais de debug

---

## Exemplo de Programa de Teste

```assembly
# Programa simples de teste
        addi x1, x0, 5      # x1 = 5
        addi x2, x0, 3      # x2 = 3
        add  x3, x1, x2     # x3 = 8
        sub  x4, x1, x2     # x4 = 2
        beq  x3, x3, skip   # Sempre pula
        addi x5, x0, 99     # Não executa
skip:   addi x6, x0, 1      # x6 = 1
```

Código hexadecimal correspondente:
```
00500093
00300113
002081B3
40208233
00318463
06300293
00100313
```

---

## Requisitos do Sistema

- Simulador Digital (v0.30 ou superior)
- GHDL (qualquer versão recente)
- Sistema operacional: Windows, Linux ou macOS

---

## Referências

- [RISC-V ISA Specification](https://riscv.org/specifications/)
- [Digital Simulator](https://github.com/hneemann/Digital)
- [GHDL](https://github.com/ghdl/ghdl)

---

## Autores

Desenvolvido para a disciplina de Arquitetura de Computadores.
