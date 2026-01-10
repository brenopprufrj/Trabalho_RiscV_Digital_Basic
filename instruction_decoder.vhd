-- =============================================================================
-- Instruction Decoder + Immediate Generator para CPU RISC-V de 32 bits
-- Decodifica campos da instrução e gera imediato sign-extended
-- Suporta formatos: R, I, S, B, U, J
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_decoder is
    port (
        instruction_i : in  std_logic_vector(31 downto 0);
        -- Campos extraídos
        opcode_o      : out std_logic_vector(6 downto 0);
        rd_o          : out std_logic_vector(4 downto 0);
        funct3_o      : out std_logic_vector(2 downto 0);
        rs1_o         : out std_logic_vector(4 downto 0);
        rs2_o         : out std_logic_vector(4 downto 0);
        funct7_o      : out std_logic_vector(6 downto 0);
        -- Imediato gerado (sign-extended para 32 bits)
        imm_o         : out std_logic_vector(31 downto 0);
        -- Tipo de instrução (para debug)
        -- 000=R, 001=I, 010=S, 011=B, 100=U, 101=J
        instr_type_o  : out std_logic_vector(2 downto 0)
    );
end entity instruction_decoder;

architecture rtl of instruction_decoder is

    -- Constantes de opcode (RV32I)
    constant OP_R_TYPE   : std_logic_vector(6 downto 0) := "0110011";  -- add, sub, and, or, xor, sll, srl
    constant OP_I_TYPE   : std_logic_vector(6 downto 0) := "0010011";  -- addi, andi, ori, xori, slli, srli
    constant OP_LOAD     : std_logic_vector(6 downto 0) := "0000011";  -- lw
    constant OP_STORE    : std_logic_vector(6 downto 0) := "0100011";  -- sw
    constant OP_BRANCH   : std_logic_vector(6 downto 0) := "1100011";  -- beq, bne
    constant OP_JAL      : std_logic_vector(6 downto 0) := "1101111";  -- jal
    constant OP_JALR     : std_logic_vector(6 downto 0) := "1100111";  -- jalr
    constant OP_LUI      : std_logic_vector(6 downto 0) := "0110111";  -- lui
    constant OP_AUIPC    : std_logic_vector(6 downto 0) := "0010111";  -- auipc

    -- Tipos de instrução
    constant TYPE_R : std_logic_vector(2 downto 0) := "000";
    constant TYPE_I : std_logic_vector(2 downto 0) := "001";
    constant TYPE_S : std_logic_vector(2 downto 0) := "010";
    constant TYPE_B : std_logic_vector(2 downto 0) := "011";
    constant TYPE_U : std_logic_vector(2 downto 0) := "100";
    constant TYPE_J : std_logic_vector(2 downto 0) := "101";

    -- Sinais internos
    signal opcode_internal : std_logic_vector(6 downto 0);
    signal imm_i_type      : std_logic_vector(31 downto 0);
    signal imm_s_type      : std_logic_vector(31 downto 0);
    signal imm_b_type      : std_logic_vector(31 downto 0);
    signal imm_u_type      : std_logic_vector(31 downto 0);
    signal imm_j_type      : std_logic_vector(31 downto 0);

begin

    -- Extração de campos (comum a todos os formatos)
    opcode_internal <= instruction_i(6 downto 0);
    opcode_o        <= opcode_internal;
    rd_o            <= instruction_i(11 downto 7);
    funct3_o        <= instruction_i(14 downto 12);
    rs1_o           <= instruction_i(19 downto 15);
    rs2_o           <= instruction_i(24 downto 20);
    funct7_o        <= instruction_i(31 downto 25);

    -- Geração de imediato I-type: imm[11:0] = inst[31:20]
    -- Sign-extended de 12 para 32 bits
    imm_i_type <= (31 downto 12 => instruction_i(31)) & instruction_i(31 downto 20);

    -- Geração de imediato S-type: imm[11:5|4:0] = inst[31:25|11:7]
    imm_s_type <= (31 downto 12 => instruction_i(31)) & 
                  instruction_i(31 downto 25) & instruction_i(11 downto 7);

    -- Geração de imediato B-type: imm[12|10:5|4:1|11] = inst[31|30:25|11:8|7]
    -- Nota: bit 0 é sempre 0 (instruções alinhadas em 2 bytes)
    imm_b_type <= (31 downto 13 => instruction_i(31)) &
                  instruction_i(31) & instruction_i(7) &
                  instruction_i(30 downto 25) & instruction_i(11 downto 8) & '0';

    -- Geração de imediato U-type: imm[31:12] = inst[31:12], resto é zero
    imm_u_type <= instruction_i(31 downto 12) & (11 downto 0 => '0');

    -- Geração de imediato J-type: imm[20|10:1|11|19:12] = inst[31|30:21|20|19:12]
    -- Nota: bit 0 é sempre 0
    imm_j_type <= (31 downto 21 => instruction_i(31)) &
                  instruction_i(31) & instruction_i(19 downto 12) &
                  instruction_i(20) & instruction_i(30 downto 21) & '0';

    -- Seleção do imediato baseado no opcode
    P_IMM_SELECT : process(opcode_internal, imm_i_type, imm_s_type, imm_b_type, 
                           imm_u_type, imm_j_type)
    begin
        case opcode_internal is
            when OP_R_TYPE =>
                imm_o <= (others => '0');  -- R-type não usa imediato
                instr_type_o <= TYPE_R;
                
            when OP_I_TYPE | OP_LOAD | OP_JALR =>
                imm_o <= imm_i_type;
                instr_type_o <= TYPE_I;
                
            when OP_STORE =>
                imm_o <= imm_s_type;
                instr_type_o <= TYPE_S;
                
            when OP_BRANCH =>
                imm_o <= imm_b_type;
                instr_type_o <= TYPE_B;
                
            when OP_LUI | OP_AUIPC =>
                imm_o <= imm_u_type;
                instr_type_o <= TYPE_U;
                
            when OP_JAL =>
                imm_o <= imm_j_type;
                instr_type_o <= TYPE_J;
                
            when others =>
                imm_o <= (others => '0');
                instr_type_o <= "111";  -- Unknown
        end case;
    end process P_IMM_SELECT;

end architecture rtl;
