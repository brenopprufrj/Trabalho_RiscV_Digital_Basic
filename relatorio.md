# Relatório Técnico - CPU RISC-V 32-bit Pipeline

## 1. Resumo

Este relatório descreve a implementação de uma CPU RISC-V de 32 bits (RV32I) com arquitetura de pipeline de 5 estágios, desenvolvida em VHDL para uso no simulador Digital.

---

## 2. Atendimento aos Requisitos

### 2.1. Arquitetura Pipeline de 5 Estágios

**Requisito:** CPU com pipeline de ao menos 5 estágios.

**Implementação:** Pipeline clássico com os estágios:

| Estágio | Sigla | Função |
|---------|-------|--------|
| Instruction Fetch | IF | Busca instrução da memória ROM |
| Instruction Decode | ID | Decodifica instrução e lê registradores |
| Execute | EX | Executa operação na ALU |
| Memory Access | MEM | Acessa memória de dados |
| Write Back | WB | Escreve resultado no banco de registradores |

**Registradores de Pipeline:**
- `IF/ID` - Armazena PC, PC+4 e instrução
- `ID/EX` - Armazena dados dos registradores, imediato e sinais de controle
- `EX/MEM` - Armazena resultado da ALU e sinais de controle de memória
- `MEM/WB` - Armazena dados para escrita no banco de registradores

---

### 2.2. Memórias Distintas

**Requisito:** Memórias de instruções e dados separadas, cada uma entregando uma palavra por ciclo.

**Implementação:** Arquitetura Harvard com interfaces separadas:

```
Memória de Instruções (ROM):
  - imem_addr_o  : Endereço (32 bits)
  - imem_data_i  : Dados lidos (32 bits)

Memória de Dados (RAM):
  - dmem_addr_o  : Endereço (32 bits)
  - dmem_wdata_o : Dados para escrita (32 bits)
  - dmem_rdata_i : Dados lidos (32 bits)
  - dmem_we_o    : Write Enable (1 bit)
```

Ambas as memórias operam em um ciclo, sem latência adicional.

---

### 2.3. Carga Assíncrona de Memória

**Requisito:** Memórias com carga assíncrona; CPU não opera durante carga.

**Implementação:** Sinal `load_enable_i` controla o estado da CPU:

- `load_enable_i = 1`: CPU pausada, permite carga de memória
- `load_enable_i = 0`: CPU operando normalmente

Todos os registradores de pipeline verificam este sinal:
```vhdl
if load_enable_i = '0' then
    -- CPU ativa, atualiza registradores
else
    -- CPU pausada, mantém estado
end if;
```

A escrita na memória de dados também é bloqueada durante carga:
```vhdl
dmem_we_o <= mem_mem_write and (not load_enable_i);
```

---

### 2.4. Sinal de Reset

**Requisito:** CPU deve possuir sinal de reset.

**Implementação:** Reset síncrono ativo em nível alto (`reset_i = 1`):
- Zera o Program Counter (PC = 0x00000000)
- Limpa todos os registradores de pipeline
- Insere NOPs em todos os estágios

---

### 2.5. Instruções Implementadas

**Requisito:** Suporte às instruções RV32I especificadas.

| Tipo | Instruções | Implementação |
|------|------------|---------------|
| Aritméticas | add, addi, auipc, sub | ALU com operações ADD/SUB |
| Lógicas | and, andi, or, ori, xor, xori | ALU com operações AND/OR/XOR |
| Deslocamento | sll, slli, srl, srli | ALU com shift left/right |
| Memória | lw, lui, sw | Load/Store word, Load Upper Immediate |
| Controle | jal, jalr, beq, bne | Jumps e branches condicionais |

**Total: 20 instruções implementadas** conforme especificação.

---

## 3. Escolhas de Projeto

### 3.1. Tratamento de Hazards

**Data Hazards (RAW):**
- **Forwarding Unit**: Encaminha dados dos estágios MEM e WB para EX
- **Stall para Load-Use**: Insere bolha quando há dependência imediata de LW

**Control Hazards:**
- Branches resolvidos no estágio EX
- Flush de instruções em IF e ID quando branch é tomado

### 3.2. Geração de Imediatos

O Instruction Decoder gera imediatos sign-extended para todos os formatos:
- I-type: 12 bits → 32 bits
- S-type: 12 bits (separados) → 32 bits
- B-type: 13 bits (bit 0 = 0) → 32 bits
- U-type: 20 bits → 32 bits (bits inferiores = 0)
- J-type: 21 bits (bit 0 = 0) → 32 bits

### 3.3. Sinais de Debug

Para aferição de estados internos:

| Sinal | Descrição |
|-------|-----------|
| pc_debug_o | Valor atual do PC |
| instr_debug_o | Instrução no estágio ID |
| alu_result_debug_o | Resultado da ALU |
| reg_debug_o | Valor de registrador selecionado |
| stage_if/id/ex_pc_o | PC em cada estágio |
| hazard_stall_o | Indicador de stall |
| hazard_flush_o | Indicador de flush |

Módulos individuais também exportam sinais internos:
- ALU: carry_o, overflow_o
- Branch Comparator: eq_o, ne_o
- Hazard Unit: hazard_type_o

---

## 4. Estrutura de Arquivos

| Arquivo | Descrição |
|---------|-----------|
| riscv_cpu.vhd | Módulo top-level |
| program_counter.vhd | Contador de programa |
| instruction_decoder.vhd | Decodificador + gerador de imediatos |
| control_unit.vhd | Unidade de controle |
| register_file.vhd | Banco de 32 registradores |
| alu.vhd | Unidade lógico-aritmética |
| pipeline_regs.vhd | Registradores IF/ID, ID/EX, EX/MEM, MEM/WB |
| hazard_unit.vhd | Detecção de hazards |
| forwarding_unit.vhd | Data forwarding |
| branch_comparator.vhd | Comparador para branches |

---

## 5. Diagrama do Pipeline

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              RISC-V CPU Pipeline                           │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌────┐   ┌───────┐   ┌────┐   ┌───────┐   ┌────┐   ┌────────┐   ┌────┐  │
│  │ PC │──►│ IF/ID │──►│ ID │──►│ ID/EX │──►│ EX │──►│ EX/MEM │──►│MEM │  │
│  └────┘   └───────┘   └────┘   └───────┘   └────┘   └────────┘   └────┘  │
│     │                    │         │          │                     │      │
│     ▼                    ▼         ▼          ▼                     ▼      │
│  ┌─────┐            ┌────────┐ ┌──────┐   ┌─────┐               ┌────────┐│
│  │IMEM │            │DECODER │ │REGFILE│  │ ALU │               │  DMEM  ││
│  └─────┘            │CONTROL │ └──────┘   └─────┘               └────────┘│
│                     └────────┘     ▲                                 │     │
│                                    │         ┌────────┐              ▼     │
│                                    └─────────│MEM/WB  │◄─────────────┘     │
│                                              └────────┘                     │
│                                                  │                          │
│                                                  ▼                          │
│                                              ┌────┐                         │
│                                              │ WB │                         │
│                                              └────┘                         │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  HAZARD UNIT ◄──► FORWARDING UNIT                                    │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Conclusão

A implementação atende a todos os requisitos especificados:

- ✅ Pipeline de 5 estágios (IF, ID, EX, MEM, WB)
- ✅ Memórias de instruções e dados separadas
- ✅ Uma palavra por ciclo em cada memória
- ✅ Carga assíncrona de memória
- ✅ CPU pausa durante carga (load_enable_i)
- ✅ Sinal de reset funcional
- ✅ Todas as 20 instruções RV32I implementadas
- ✅ Apenas pipeline de inteiros (sem modo S)
- ✅ Sinais de debug para aferição de estados internos
