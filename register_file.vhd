-- =============================================================================
-- Register File para CPU RISC-V de 32 bits
-- 32 registradores de 32 bits cada (x0 sempre = 0)
-- 2 portas de leitura, 1 porta de escrita
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        we_i         : in  std_logic;                      -- Write Enable
        -- Endereços
        rs1_addr_i   : in  std_logic_vector(4 downto 0);   -- Endereço fonte 1
        rs2_addr_i   : in  std_logic_vector(4 downto 0);   -- Endereço fonte 2
        rd_addr_i    : in  std_logic_vector(4 downto 0);   -- Endereço destino
        -- Dados
        rd_data_i    : in  std_logic_vector(31 downto 0);  -- Dados para escrita
        rs1_data_o   : out std_logic_vector(31 downto 0);  -- Dados lidos de rs1
        rs2_data_o   : out std_logic_vector(31 downto 0);  -- Dados lidos de rs2
        -- Debug outputs (para aferir estados internos)
        reg_debug_o  : out std_logic_vector(31 downto 0);  -- Registrador selecionado para debug
        reg_sel_i    : in  std_logic_vector(4 downto 0)    -- Seleção de registrador para debug
    );
end entity register_file;

architecture rtl of register_file is

    -- Tipo para o banco de registradores
    type reg_array_t is array (0 to 31) of std_logic_vector(31 downto 0);
    
    -- Banco de registradores
    signal registers : reg_array_t := (others => (others => '0'));

begin

    -- Processo de escrita (síncrono)
    P_WRITE : process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            -- Reset: todos os registradores para zero
            registers <= (others => (others => '0'));
        elsif rising_edge(clk_i) then
            if we_i = '1' and rd_addr_i /= "00000" then
                -- Escreve no registrador destino (exceto x0)
                registers(to_integer(unsigned(rd_addr_i))) <= rd_data_i;
            end if;
        end if;
    end process P_WRITE;

    -- Leitura assíncrona de rs1 (x0 sempre retorna 0)
    rs1_data_o <= (others => '0') when rs1_addr_i = "00000" else
                  registers(to_integer(unsigned(rs1_addr_i)));

    -- Leitura assíncrona de rs2 (x0 sempre retorna 0)
    rs2_data_o <= (others => '0') when rs2_addr_i = "00000" else
                  registers(to_integer(unsigned(rs2_addr_i)));

    -- Saída de debug: permite ler qualquer registrador para depuração
    reg_debug_o <= (others => '0') when reg_sel_i = "00000" else
                   registers(to_integer(unsigned(reg_sel_i)));

end architecture rtl;
