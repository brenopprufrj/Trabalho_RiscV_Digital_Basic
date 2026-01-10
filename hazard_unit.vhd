-- =============================================================================
-- Hazard Detection Unit para CPU RISC-V de 32 bits
-- Detecta hazards de dados (load-use) e controle (branches/jumps)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity hazard_unit is
    port (
        -- Do estágio ID (instrução sendo decodificada)
        rs1_id_i       : in  std_logic_vector(4 downto 0);
        rs2_id_i       : in  std_logic_vector(4 downto 0);
        -- Do estágio EX
        rd_ex_i        : in  std_logic_vector(4 downto 0);
        mem_read_ex_i  : in  std_logic;                     -- Load está no EX
        -- Sinais de branch/jump resolvidos
        branch_taken_i : in  std_logic;                     -- Branch foi tomado
        jump_i         : in  std_logic;                     -- Jump está sendo executado
        -- Saídas de controle de hazard
        stall_if_o     : out std_logic;                     -- Stall no estágio IF
        stall_id_o     : out std_logic;                     -- Stall no estágio ID
        flush_id_o     : out std_logic;                     -- Flush IF/ID register
        flush_ex_o     : out std_logic;                     -- Flush ID/EX register
        -- Debug
        hazard_type_o  : out std_logic_vector(1 downto 0)   -- 00=none, 01=load-use, 10=control
    );
end entity hazard_unit;

architecture rtl of hazard_unit is

    signal load_use_hazard  : std_logic;
    signal control_hazard   : std_logic;

begin

    -- Detecção de Load-Use Hazard
    -- Ocorre quando uma instrução de load está no EX e a instrução no ID
    -- precisa do resultado desse load (dependência de dados)
    load_use_hazard <= '1' when (mem_read_ex_i = '1') and (rd_ex_i /= "00000") and
                                ((rd_ex_i = rs1_id_i) or (rd_ex_i = rs2_id_i))
                       else '0';

    -- Detecção de Control Hazard
    -- Ocorre quando um branch é tomado ou um jump é executado
    control_hazard <= branch_taken_i or jump_i;

    -- Geração dos sinais de stall e flush
    P_HAZARD_CONTROL : process(load_use_hazard, control_hazard, branch_taken_i, jump_i)
    begin
        -- Valores padrão
        stall_if_o    <= '0';
        stall_id_o    <= '0';
        flush_id_o    <= '0';
        flush_ex_o    <= '0';
        hazard_type_o <= "00";

        if load_use_hazard = '1' then
            -- Load-Use Hazard: inserir bolha (stall IF e ID, flush EX)
            stall_if_o    <= '1';
            stall_id_o    <= '1';
            flush_ex_o    <= '1';  -- Insere NOP no estágio EX
            hazard_type_o <= "01";
        end if;

        if control_hazard = '1' then
            -- Control Hazard: flush as instruções incorretas
            flush_id_o    <= '1';  -- Descarta instrução no IF/ID
            flush_ex_o    <= '1';  -- Descarta instrução no ID/EX
            hazard_type_o <= "10";
        end if;

        -- Nota: Se ambos hazards ocorrerem, control tem prioridade
        -- pois o branch está sendo resolvido e o pipeline será redirecionado
    end process P_HAZARD_CONTROL;

end architecture rtl;
