## Descrição:

	Projetar e implementar uma CPU RISC-V de 32 Bits (RV32I) cuja microarquitetura seja baseada em um pipeline com ao menos 5 estágios, a implementação deve ser realizada usando blocos VHDL/Verilog no simulador Digital. As memórias de instruções e dados são distintas e entregam cada uma palavra por ciclo, além disso essas memórias devem ser modificadas para permitir carga de dados assíncrona (pode usar as memórias ROM e RAM do Digital). A CPU deve ser adaptada para não operar durante essa carga de dados (manter seu estado interno corrente), além de possuir um sinal de **reset**. Para esta tarefa apenas o *pipeline* de inteiros será implementado, sem modo supervisor (S Mode), especificamente as instruções a seguir devem ser suportadas:

* add, addi, auipc e sub  
* and, andi, or, ori, xor e xori  
* sll, slli, srl e srli  
* lw, lui e sw  
* jal, jalr, beq e bne

## Critérios de Avaliação:

	Serão avaliadas a corretude, aderência aos requisitos solicitados e qualidade do relatório descritivo. Os módulos VHDL/Verilog devem ser projetados para permitir que seus estados internos sejam aferidos, por exemplo, um somador pode exportar o seu cálculo de carry para depuração do circuito. Cada trio deve entregar um relatório descritivo do seu projeto, destacando as premissas adotadas e o projeto do circuito.

## Observações:

	Desaconselho fortemente o uso de blocos combinacionais de múltiplos bits do Digital, em especial os de ALU.