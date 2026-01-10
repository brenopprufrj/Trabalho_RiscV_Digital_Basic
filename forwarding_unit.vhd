-- =============================================================================
-- Forwarding Unit para CPU RISC-V de 32 bits
-- Implementa data forwarding (bypass) para evitar hazards de dados
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity forwarding_unit is
    port (
        -- Endereços dos registradores no estágio EX
        rs1_ex_i        : in  std_logic_vector(4 downto 0);
        rs2_ex_i        : in  std_logic_vector(4 downto 0);
        -- Informações do estágio MEM
        rd_mem_i        : in  std_logic_vector(4 downto 0);
        reg_write_mem_i : in  std_logic;
        -- Informações do estágio WB
        rd_wb_i         : in  std_logic_vector(4 downto 0);
        reg_write_wb_i  : in  std_logic;
        -- Sinais de forwarding para operando A
        -- 00 = Usa valor do banco de registradores (ID)
        -- 01 = Forward do estágio MEM
        -- 10 = Forward do estágio WB
        forward_a_o     : out std_logic_vector(1 downto 0);
        -- Sinais de forwarding para operando B
        forward_b_o     : out std_logic_vector(1 downto 0)
    );
end entity forwarding_unit;

architecture rtl of forwarding_unit is
begin

    -- Lógica de Forwarding para Operando A (rs1)
    P_FORWARD_A : process(rs1_ex_i, rd_mem_i, reg_write_mem_i, rd_wb_i, reg_write_wb_i)
    begin
        -- Prioridade: MEM > WB (dados mais recentes têm prioridade)
        if (reg_write_mem_i = '1') and (rd_mem_i /= "00000") and (rd_mem_i = rs1_ex_i) then
            -- Forward do estágio MEM
            forward_a_o <= "01";
        elsif (reg_write_wb_i = '1') and (rd_wb_i /= "00000") and (rd_wb_i = rs1_ex_i) then
            -- Forward do estágio WB
            forward_a_o <= "10";
        else
            -- Sem forwarding, usa valor original
            forward_a_o <= "00";
        end if;
    end process P_FORWARD_A;

    -- Lógica de Forwarding para Operando B (rs2)
    P_FORWARD_B : process(rs2_ex_i, rd_mem_i, reg_write_mem_i, rd_wb_i, reg_write_wb_i)
    begin
        if (reg_write_mem_i = '1') and (rd_mem_i /= "00000") and (rd_mem_i = rs2_ex_i) then
            forward_b_o <= "01";
        elsif (reg_write_wb_i = '1') and (rd_wb_i /= "00000") and (rd_wb_i = rs2_ex_i) then
            forward_b_o <= "10";
        else
            forward_b_o <= "00";
        end if;
    end process P_FORWARD_B;

end architecture rtl;
