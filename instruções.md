# Instruções de Configuração - CPU RISC-V no Digital

> **CIRCUITO PRÉ-MONTADO**: O arquivo `Circuito.dig` já contém o circuito completo montado com CPU, memórias e conexões. Para utilizá-lo:
> 1. Execute `compile_vhdl.bat` (Windows) ou `compile_vhdl.sh` (Linux/macOS) para compilar os módulos VHDL (veja as **Seções 2 e 3** deste documento para mais informações)
> 2. Configure o Digital conforme a **Seção 3** (GHDL Options com o caminho da pasta)
> 3. Abra `Circuito.dig` no Digital
> 4. Clique duas vezes no componente `riscv_cpu` e altere o **Code file** para o caminho absoluto do `riscv_cpu.vhd` no seu computador
>
> As instruções abaixo são para quem deseja reconstruir o circuito do zero.

---

## 1. Pré-requisitos

- **Digital Simulator**: https://github.com/hneemann/Digital
- **GHDL**: https://github.com/ghdl/ghdl/releases

> **IMPORTANTE**: O GHDL deve estar nas variáveis de ambiente (PATH) do sistema.

---

## 2. Compilar Componentes

Os componentes VHDL devem ser pré-compilados antes de usar no Digital.

**Windows:**
```cmd
compile_vhdl.bat
```

**Linux/macOS:**
```bash
chmod +x compile_vhdl.sh
./compile_vhdl.sh
```

---

## 3. Configurar o Digital

1. Abra o Digital → **Edit → Settings**
2. Na aba **External**, configure:
   - **GHDL**: Caminho do executável (ou deixe vazio se GHDL estiver no PATH)
   - **GHDL Options**: 
     ```
     --std=08 --ieee=synopsys --workdir="CAMINHO_DA_PASTA_DO_PROJETO"
     ```

Substitua `CAMINHO_DA_PASTA_DO_PROJETO` pelo caminho completo onde estão os arquivos VHDL.

---

## 4. Adicionar a CPU no Circuito

1. **Components → Misc. → External File**
2. Configure:
   - **Application type**: `GHDL`
   - **Label**: `riscv_cpu`
   - **Code file**: Selecione `riscv_cpu.vhd`
   - **Inputs**: `clk_i,reset_i,load_enable_i,imem_data_i:32,dmem_rdata_i:32,reg_sel_i:5`
   - **Outputs**: `imem_addr_o:32,dmem_addr_o:32,dmem_wdata_o:32,dmem_we_o,pc_debug_o:32,instr_debug_o:32,alu_result_debug_o:32,reg_debug_o:32,stage_if_pc_o:32,stage_id_pc_o:32,stage_ex_pc_o:32,hazard_stall_o,hazard_flush_o`

---

## 5. Conectar Memórias

O RISC-V usa **endereçamento de bytes**, mas as memórias do Digital usam **endereçamento de palavras**. É necessário usar um **Splitter** para converter os endereços.

### Configurando o Splitter

1. **Components → Wires → Splitter**
2. Configure:
   - **Input Bits**: 32
   - **Output Splitting**: Separe em 3 partes

### Exemplo para memória de 256 palavras (8 bits de endereço):

```
Splitter: 32 bits → [2, 8, 22]
  - Saída 0: bits 0-1 (descartar - alinhamento de bytes)
  - Saída 1: bits 2-9 (usar como endereço da memória)
  - Saída 2: bits 10-31 (descartar - não usado)
```

### Memória de Instruções (ROM)
```
imem_addr_o (32 bits) → Splitter → Saída 1 (8 bits) → ROM Address
ROM Data → imem_data_i
```

### Memória de Dados (RAM)
```
dmem_addr_o (32 bits) → Splitter → Saída 1 (8 bits) → RAM Address
dmem_wdata_o → RAM Data In
dmem_we_o → RAM Write Enable
RAM Data Out → dmem_rdata_i
```

### Tabela de Bits por Tamanho de Memória

| Palavras | Bits de Endereço | Splitter Config |
|----------|------------------|-----------------|
| 64       | 6                | [2, 6, 24]      |
| 256      | 8                | [2, 8, 22]      |
| 1024     | 10               | [2, 10, 20]     |
| 4096     | 12               | [2, 12, 18]     |

---

## 6. Procedimento de Execução

1. Ative `load_enable_i = 1`
2. Carregue o programa na ROM
3. Aplique `reset_i = 1` por alguns ciclos
4. Desative `reset_i = 0`
5. Desative `load_enable_i = 0`
6. A CPU executará a partir do endereço 0x00000000

---

## 7. Exemplo de Programa para a ROM

O programa abaixo já está carregado no `Circuito.dig`. Para reconstruir do zero, carregue na ROM em formato hexadecimal:

```hex
00500093   # addi x1, x0, 5     (x1 = 5)
00300113   # addi x2, x0, 3     (x2 = 3)
002081B3   # add  x3, x1, x2    (x3 = 8)
40208233   # sub  x4, x1, x2    (x4 = 2)
```

**Para carregar no Digital:**
1. Clique com o botão direito na ROM
2. Selecione **Edit content**
3. Cole os valores hexadecimais (um por linha, sem os comentários)

---

## 8. Sinais de Debug

| Sinal | Descrição |
|-------|-----------|
| `pc_debug_o` | Valor atual do PC |
| `instr_debug_o` | Instrução no estágio ID |
| `alu_result_debug_o` | Resultado da ALU |
| `reg_debug_o` | Valor do registrador selecionado |
| `stage_if/id/ex_pc_o` | PC em cada estágio |
| `hazard_stall_o` | Indica stall |
| `hazard_flush_o` | Indica flush |

Use `reg_sel_i` (0-31) para selecionar qual registrador observar em `reg_debug_o`.

---

## 9. Usando Módulos Individuais

Para testar componentes isoladamente (ex: apenas a ALU):

1. **Components → Misc. → External**
2. Configure conforme a entidade desejada

### Exemplo: Testando a ALU

| Campo | Valor |
|-------|-------|
| Application type | GHDL |
| Label | alu |
| Code file | `alu.vhd` |
| Inputs | `a_i:32,b_i:32,alu_ctrl_i:4` |
| Outputs | `result_o:32,zero_o,carry_o,overflow_o` |

### Operações da ALU

| alu_ctrl_i | Operação |
|------------|----------|
| 0000 | ADD |
| 0001 | SUB |
| 0010 | AND |
| 0011 | OR |
| 0100 | XOR |
| 0101 | SLL |
| 0110 | SRL |
| 0111 | PASS_B |

---

## 10. Gerando Programas

Use um assembler RISC-V para gerar código hexadecimal:

- **Venus** (online): https://venus.cs61c.org/
- **RARS** (desktop): RISC-V Assembler and Runtime Simulator

---

## 11. Solução de Problemas

### Erro: "GHDL not found"
- Verifique se o GHDL está instalado e no PATH
- Reinicie o Digital após instalar o GHDL

### Erro: Entidades não encontradas
- Certifique-se de que todos os arquivos VHDL foram compilados
- Execute `compile_vhdl.bat` ou `compile_vhdl.sh` novamente

### Saídas não mudam
- Verifique se o clock está funcionando
- Verifique se `load_enable_i = 0` e `reset_i = 0`
- Verifique se a memória de instruções está carregada

---

## 12. Referências

- [RISC-V ISA Specification](https://riscv.org/specifications/)
- [Digital Simulator](https://github.com/hneemann/Digital)
- [GHDL](https://github.com/ghdl/ghdl)
