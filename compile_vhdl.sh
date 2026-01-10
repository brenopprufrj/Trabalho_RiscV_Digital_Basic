#!/bin/bash
# Script para compilar os componentes VHDL na biblioteca work
# Execute este script na pasta onde estao os arquivos VHDL
# GHDL deve estar no PATH do sistema

# Muda para o diretorio onde o script esta localizado
cd "$(dirname "$0")"

echo "Verificando GHDL..."
if ! command -v ghdl &> /dev/null; then
    echo "ERRO: GHDL nao encontrado no PATH do sistema!"
    echo "Instale o GHDL e adicione ao PATH."
    exit 1
fi

echo "Limpando biblioteca anterior..."
rm -f work-obj08.cf

echo "Compilando componentes VHDL..."
ghdl -a --std=08 --ieee=synopsys alu.vhd || exit 1
ghdl -a --std=08 --ieee=synopsys register_file.vhd || exit 1
ghdl -a --std=08 --ieee=synopsys instruction_decoder.vhd || exit 1
ghdl -a --std=08 --ieee=synopsys control_unit.vhd || exit 1
ghdl -a --std=08 --ieee=synopsys pipeline_regs.vhd || exit 1
ghdl -a --std=08 --ieee=synopsys hazard_unit.vhd || exit 1
ghdl -a --std=08 --ieee=synopsys forwarding_unit.vhd || exit 1
ghdl -a --std=08 --ieee=synopsys branch_comparator.vhd || exit 1
ghdl -a --std=08 --ieee=synopsys program_counter.vhd || exit 1

echo ""
echo "========================================"
echo "Compilacao concluida com sucesso!"
echo "Componentes prontos na biblioteca work."
echo "No Digital, use riscv_cpu.vhd como Code File."
echo "========================================"
