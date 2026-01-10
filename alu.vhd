-- =============================================================================
-- ALU (Arithmetic Logic Unit) para CPU RISC-V de 32 bits
-- Suporta operações: ADD, SUB, AND, OR, XOR, SLL, SRL, PASS_B (LUI)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (
        a_i        : in  std_logic_vector(31 downto 0);  -- Operando A
        b_i        : in  std_logic_vector(31 downto 0);  -- Operando B
        alu_ctrl_i : in  std_logic_vector(3 downto 0);   -- Controle da operação
        result_o   : out std_logic_vector(31 downto 0);  -- Resultado
        zero_o     : out std_logic;                      -- Flag zero (para branches)
        -- Debug outputs
        carry_o    : out std_logic;                      -- Carry out (debug)
        overflow_o : out std_logic                       -- Overflow (debug)
    );
end entity alu;

architecture rtl of alu is

    -- Constantes para operações da ALU
    constant ALU_ADD    : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB    : std_logic_vector(3 downto 0) := "0001";
    constant ALU_AND    : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OR     : std_logic_vector(3 downto 0) := "0011";
    constant ALU_XOR    : std_logic_vector(3 downto 0) := "0100";
    constant ALU_SLL    : std_logic_vector(3 downto 0) := "0101";  -- Shift Left Logical
    constant ALU_SRL    : std_logic_vector(3 downto 0) := "0110";  -- Shift Right Logical
    constant ALU_PASS_B : std_logic_vector(3 downto 0) := "0111";  -- Pass B (para LUI)

    -- Sinais internos
    signal result_internal : std_logic_vector(31 downto 0);
    signal add_result      : std_logic_vector(32 downto 0);  -- 33 bits para carry
    signal sub_result      : std_logic_vector(32 downto 0);  -- 33 bits para borrow
    signal shamt           : natural range 0 to 31;          -- Shift amount

begin

    -- Quantidade de deslocamento (5 bits menos significativos de B)
    shamt <= to_integer(unsigned(b_i(4 downto 0)));

    -- Cálculo de soma e subtração com carry/borrow
    add_result <= std_logic_vector(unsigned('0' & a_i) + unsigned('0' & b_i));
    sub_result <= std_logic_vector(unsigned('0' & a_i) - unsigned('0' & b_i));

    -- Processo principal da ALU
    P_ALU : process(a_i, b_i, alu_ctrl_i, add_result, sub_result, shamt)
    begin
        case alu_ctrl_i is
            when ALU_ADD =>
                result_internal <= add_result(31 downto 0);
                
            when ALU_SUB =>
                result_internal <= sub_result(31 downto 0);
                
            when ALU_AND =>
                result_internal <= a_i and b_i;
                
            when ALU_OR =>
                result_internal <= a_i or b_i;
                
            when ALU_XOR =>
                result_internal <= a_i xor b_i;
                
            when ALU_SLL =>
                result_internal <= std_logic_vector(shift_left(unsigned(a_i), shamt));
                
            when ALU_SRL =>
                result_internal <= std_logic_vector(shift_right(unsigned(a_i), shamt));
                
            when ALU_PASS_B =>
                result_internal <= b_i;
                
            when others =>
                result_internal <= (others => '0');
        end case;
    end process P_ALU;

    -- Saídas
    result_o <= result_internal;
    
    -- Flag zero: '1' se resultado é zero
    zero_o <= '1' when result_internal = x"00000000" else '0';
    
    -- Debug: carry da soma
    carry_o <= add_result(32) when alu_ctrl_i = ALU_ADD else '0';
    
    -- Debug: overflow (simplificado - verifica mudança de sinal na soma)
    overflow_o <= (not a_i(31) and not b_i(31) and result_internal(31)) or
                  (a_i(31) and b_i(31) and not result_internal(31))
                  when alu_ctrl_i = ALU_ADD else '0';

end architecture rtl;
