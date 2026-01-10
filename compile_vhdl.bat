@echo off
REM Script para compilar os componentes VHDL na biblioteca work
REM Execute este script na pasta onde estao os arquivos VHDL
REM GHDL deve estar no PATH do sistema

REM Muda para o diretorio onde o script esta localizado
cd /d "%~dp0"

echo Verificando GHDL...
where ghdl >nul 2>&1
if errorlevel 1 (
    echo ERRO: GHDL nao encontrado no PATH do sistema!
    echo Instale o GHDL e adicione ao PATH.
    pause
    exit /b 1
)

echo Limpando biblioteca anterior...
del work-obj08.cf 2>nul

echo Compilando componentes VHDL...
ghdl -a --std=08 --ieee=synopsys alu.vhd
if errorlevel 1 goto error
ghdl -a --std=08 --ieee=synopsys register_file.vhd
if errorlevel 1 goto error
ghdl -a --std=08 --ieee=synopsys instruction_decoder.vhd
if errorlevel 1 goto error
ghdl -a --std=08 --ieee=synopsys control_unit.vhd
if errorlevel 1 goto error
ghdl -a --std=08 --ieee=synopsys pipeline_regs.vhd
if errorlevel 1 goto error
ghdl -a --std=08 --ieee=synopsys hazard_unit.vhd
if errorlevel 1 goto error
ghdl -a --std=08 --ieee=synopsys forwarding_unit.vhd
if errorlevel 1 goto error
ghdl -a --std=08 --ieee=synopsys branch_comparator.vhd
if errorlevel 1 goto error
ghdl -a --std=08 --ieee=synopsys program_counter.vhd
if errorlevel 1 goto error

echo.
echo ========================================
echo Compilacao concluida com sucesso!
echo Componentes prontos na biblioteca work.
echo No Digital, use riscv_cpu.vhd como Code File.
echo ========================================
pause
goto end

:error
echo.
echo ERRO: Falha na compilacao!
pause

:end
