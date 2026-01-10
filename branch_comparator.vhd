-- =============================================================================
-- Branch Comparator para CPU RISC-V de 32 bits
-- Compara operandos para instruções de branch (beq, bne)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_comparator is
    port (
        a_i            : in  std_logic_vector(31 downto 0);
        b_i            : in  std_logic_vector(31 downto 0);
        funct3_i       : in  std_logic_vector(2 downto 0);
        branch_i       : in  std_logic;  -- Sinal que indica instrução de branch
        branch_taken_o : out std_logic;
        -- Debug outputs
        eq_o           : out std_logic;  -- a == b
        ne_o           : out std_logic   -- a != b
    );
end entity branch_comparator;

architecture rtl of branch_comparator is

    -- funct3 codes para branches
    constant FUNCT3_BEQ : std_logic_vector(2 downto 0) := "000";
    constant FUNCT3_BNE : std_logic_vector(2 downto 0) := "001";
    
    -- Sinais internos de comparação
    signal is_equal     : std_logic;
    signal is_not_equal : std_logic;

begin

    -- Comparações básicas
    is_equal     <= '1' when a_i = b_i else '0';
    is_not_equal <= not is_equal;

    -- Saídas de debug
    eq_o <= is_equal;
    ne_o <= is_not_equal;

    -- Decisão de branch
    P_BRANCH_DECISION : process(branch_i, funct3_i, is_equal, is_not_equal)
    begin
        branch_taken_o <= '0';
        
        if branch_i = '1' then
            case funct3_i is
                when FUNCT3_BEQ =>
                    branch_taken_o <= is_equal;
                when FUNCT3_BNE =>
                    branch_taken_o <= is_not_equal;
                when others =>
                    branch_taken_o <= '0';
            end case;
        end if;
    end process P_BRANCH_DECISION;

end architecture rtl;
