-- =============================================================================
-- Program Counter para CPU RISC-V de 32 bits
-- Suporta reset, stall, jump e branch
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity program_counter is
    port (
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;
        stall_i        : in  std_logic;                     -- Mantém PC atual
        load_enable_i  : in  std_logic;                     -- Durante carga de memória
        -- Controle de próximo PC
        branch_taken_i : in  std_logic;
        jump_i         : in  std_logic;
        target_addr_i  : in  std_logic_vector(31 downto 0); -- Endereço de branch/jump
        -- Saídas
        pc_o           : out std_logic_vector(31 downto 0);
        pc_plus4_o     : out std_logic_vector(31 downto 0)
    );
end entity program_counter;

architecture rtl of program_counter is

    signal pc_reg      : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_next     : std_logic_vector(31 downto 0);
    signal pc_plus4    : std_logic_vector(31 downto 0);

begin

    -- PC + 4 (próxima instrução sequencial)
    pc_plus4 <= std_logic_vector(unsigned(pc_reg) + 4);

    -- Seleção do próximo PC
    P_PC_NEXT : process(pc_plus4, branch_taken_i, jump_i, target_addr_i)
    begin
        if (branch_taken_i = '1') or (jump_i = '1') then
            pc_next <= target_addr_i;
        else
            pc_next <= pc_plus4;
        end if;
    end process P_PC_NEXT;

    -- Registrador do PC
    P_PC_REG : process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            pc_reg <= (others => '0');  -- Inicia em 0x00000000
        elsif rising_edge(clk_i) then
            if load_enable_i = '0' then  -- CPU ativa apenas quando não carregando
                if stall_i = '0' then
                    pc_reg <= pc_next;
                end if;
                -- Se stall='1', mantém PC atual
            end if;
        end if;
    end process P_PC_REG;

    -- Saídas
    pc_o       <= pc_reg;
    pc_plus4_o <= pc_plus4;

end architecture rtl;
