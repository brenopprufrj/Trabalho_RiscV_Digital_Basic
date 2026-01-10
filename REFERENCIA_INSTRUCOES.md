# Referência de Instruções - CPU RISC-V RV32I

Documentação completa de opcodes, formatos de instrução e instruções suportadas pela CPU RISC-V de 32 bits.

---

## 1. Opcodes RV32I

| Opcode (Binário) | Opcode (Hex) | Tipo | Instruções |
|------------------|--------------|------|------------|
| `0110011` | 0x33 | R | add, sub, and, or, xor, sll, srl |
| `0010011` | 0x13 | I | addi, andi, ori, xori, slli, srli |
| `0000011` | 0x03 | I | lw |
| `0100011` | 0x23 | S | sw |
| `1100011` | 0x63 | B | beq, bne |
| `1101111` | 0x6F | J | jal |
| `1100111` | 0x67 | I | jalr |
| `0110111` | 0x37 | U | lui |
| `0010111` | 0x17 | U | auipc |

---

## 2. Formatos de Instrução

### Tipo R (Register)
```
31      25 24    20 19    15 14  12 11     7 6      0
┌─────────┬────────┬────────┬──────┬────────┬────────┐
│ funct7  │  rs2   │  rs1   │funct3│   rd   │ opcode │
│  7 bits │ 5 bits │ 5 bits │3 bits│ 5 bits │ 7 bits │
└─────────┴────────┴────────┴──────┴────────┴────────┘
```

### Tipo I (Immediate)
```
31              20 19    15 14  12 11     7 6      0
┌─────────────────┬────────┬──────┬────────┬────────┐
│    imm[11:0]    │  rs1   │funct3│   rd   │ opcode │
│     12 bits     │ 5 bits │3 bits│ 5 bits │ 7 bits │
└─────────────────┴────────┴──────┴────────┴────────┘
```

### Tipo S (Store)
```
31      25 24    20 19    15 14  12 11     7 6      0
┌─────────┬────────┬────────┬──────┬────────┬────────┐
│imm[11:5]│  rs2   │  rs1   │funct3│imm[4:0]│ opcode │
│  7 bits │ 5 bits │ 5 bits │3 bits│ 5 bits │ 7 bits │
└─────────┴────────┴────────┴──────┴────────┴────────┘
```

### Tipo B (Branch)
```
31   30    25 24   20 19   15 14  12 11    8 7  6      0
┌───┬────────┬──────┬───────┬──────┬───────┬──┬────────┐
│[12]│[10:5] │ rs2  │  rs1  │funct3│ [4:1] │[11]│opcode│
│1bit│ 6bits │5 bits│5 bits │3 bits│4 bits │1bit│7 bits│
└───┴────────┴──────┴───────┴──────┴───────┴──┴────────┘
```

### Tipo U (Upper Immediate)
```
31                        12 11     7 6      0
┌────────────────────────────┬────────┬────────┐
│        imm[31:12]          │   rd   │ opcode │
│          20 bits           │ 5 bits │ 7 bits │
└────────────────────────────┴────────┴────────┘
```

### Tipo J (Jump)
```
31   30     21 20  19        12 11     7 6      0
┌───┬─────────┬───┬────────────┬────────┬────────┐
│[20]│ [10:1] │[11]│  [19:12]  │   rd   │ opcode │
│1bit│ 10bits │1bit│   8 bits  │ 5 bits │ 7 bits │
└───┴─────────┴───┴────────────┴────────┴────────┘
```

---

## 3. Instruções Suportadas

### 3.1 Instruções Aritméticas

| Instrução | Formato | Opcode | funct3 | funct7 | Operação |
|-----------|---------|--------|--------|--------|----------|
| **add** | R | 0110011 | 000 | 0000000 | rd = rs1 + rs2 |
| **sub** | R | 0110011 | 000 | 0100000 | rd = rs1 - rs2 |
| **addi** | I | 0010011 | 000 | - | rd = rs1 + imm |
| **auipc** | U | 0010111 | - | - | rd = PC + (imm << 12) |

### 3.2 Instruções Lógicas

| Instrução | Formato | Opcode | funct3 | funct7 | Operação |
|-----------|---------|--------|--------|--------|----------|
| **and** | R | 0110011 | 111 | 0000000 | rd = rs1 & rs2 |
| **or** | R | 0110011 | 110 | 0000000 | rd = rs1 \| rs2 |
| **xor** | R | 0110011 | 100 | 0000000 | rd = rs1 ^ rs2 |
| **andi** | I | 0010011 | 111 | - | rd = rs1 & imm |
| **ori** | I | 0010011 | 110 | - | rd = rs1 \| imm |
| **xori** | I | 0010011 | 100 | - | rd = rs1 ^ imm |

### 3.3 Instruções de Deslocamento

| Instrução | Formato | Opcode | funct3 | funct7 | Operação |
|-----------|---------|--------|--------|--------|----------|
| **sll** | R | 0110011 | 001 | 0000000 | rd = rs1 << rs2[4:0] |
| **srl** | R | 0110011 | 101 | 0000000 | rd = rs1 >> rs2[4:0] (lógico) |
| **slli** | I | 0010011 | 001 | 0000000 | rd = rs1 << shamt |
| **srli** | I | 0010011 | 101 | 0000000 | rd = rs1 >> shamt (lógico) |

### 3.4 Instruções de Memória

| Instrução | Formato | Opcode | funct3 | Operação |
|-----------|---------|--------|--------|----------|
| **lw** | I | 0000011 | 010 | rd = MEM[rs1 + imm] |
| **sw** | S | 0100011 | 010 | MEM[rs1 + imm] = rs2 |
| **lui** | U | 0110111 | - | rd = imm << 12 |

### 3.5 Instruções de Controle de Fluxo

| Instrução | Formato | Opcode | funct3 | Operação |
|-----------|---------|--------|--------|----------|
| **beq** | B | 1100011 | 000 | if (rs1 == rs2) PC += imm |
| **bne** | B | 1100011 | 001 | if (rs1 != rs2) PC += imm |
| **jal** | J | 1101111 | - | rd = PC+4; PC += imm |
| **jalr** | I | 1100111 | 000 | rd = PC+4; PC = (rs1 + imm) & ~1 |

---

## 4. Códigos de Controle da ALU

| alu_ctrl | Binário | Operação | Descrição |
|----------|---------|----------|-----------|
| ALU_ADD | 0000 | A + B | Soma |
| ALU_SUB | 0001 | A - B | Subtração |
| ALU_AND | 0010 | A & B | AND bit-a-bit |
| ALU_OR | 0011 | A \| B | OR bit-a-bit |
| ALU_XOR | 0100 | A ^ B | XOR bit-a-bit |
| ALU_SLL | 0101 | A << B[4:0] | Shift left logical |
| ALU_SRL | 0110 | A >> B[4:0] | Shift right logical |
| ALU_PASS_B | 0111 | B | Passa operando B (usado para LUI) |

---

## 5. Exemplos de Codificação

### Exemplo 1: `addi x1, x0, 5`
Carrega o valor 5 no registrador x1.

```
imm[11:0] = 000000000101 (5)
rs1       = 00000 (x0)
funct3    = 000
rd        = 00001 (x1)
opcode    = 0010011

Binário: 00000000010100000000000010010011
Hex:     0x00500093
```

### Exemplo 2: `add x3, x1, x2`
Soma x1 + x2 e armazena em x3.

```
funct7    = 0000000
rs2       = 00010 (x2)
rs1       = 00001 (x1)
funct3    = 000
rd        = 00011 (x3)
opcode    = 0110011

Binário: 00000000001000001000000110110011
Hex:     0x002081B3
```

### Exemplo 3: `beq x1, x2, 8`
Salta 8 bytes se x1 == x2.

```
imm = 8 → [12:1] = 0000000001000 (bit 0 sempre 0)
imm[12]   = 0
imm[10:5] = 000000
rs2       = 00010 (x2)
rs1       = 00001 (x1)
funct3    = 000
imm[4:1]  = 0100
imm[11]   = 0
opcode    = 1100011

Binário: 00000000001000001000010001100011
Hex:     0x00208463
```

---

## 6. Referências

- [RISC-V ISA Specification](https://riscv.org/specifications/)
- [RISC-V Instruction Set Manual, Volume I](https://github.com/riscv/riscv-isa-manual)
