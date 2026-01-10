-- =============================================================================
-- Pipeline Registers para CPU RISC-V de 32 bits (5 estágios)
-- Contém: IF/ID, ID/EX, EX/MEM, MEM/WB
-- Cada registrador suporta stall e flush
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

-- =============================================================================
-- IF/ID Pipeline Register
-- =============================================================================
entity if_id_reg is
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        stall_i       : in  std_logic;                     -- Mantém valor atual
        flush_i       : in  std_logic;                     -- Limpa registrador (NOP)
        load_enable_i : in  std_logic;                     -- Carga de memória em andamento
        -- Entradas do estágio IF
        pc_i          : in  std_logic_vector(31 downto 0);
        pc_plus4_i    : in  std_logic_vector(31 downto 0);
        instruction_i : in  std_logic_vector(31 downto 0);
        -- Saídas para estágio ID
        pc_o          : out std_logic_vector(31 downto 0);
        pc_plus4_o    : out std_logic_vector(31 downto 0);
        instruction_o : out std_logic_vector(31 downto 0)
    );
end entity if_id_reg;

architecture rtl of if_id_reg is
    signal pc_reg          : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_plus4_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal instruction_reg : std_logic_vector(31 downto 0) := (others => '0');
begin
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            pc_reg          <= (others => '0');
            pc_plus4_reg    <= (others => '0');
            instruction_reg <= (others => '0');
        elsif rising_edge(clk_i) then
            if load_enable_i = '0' then  -- CPU ativa apenas quando não carregando memória
                if flush_i = '1' then
                    -- Flush: insere NOP (addi x0, x0, 0 = 0x00000013)
                    pc_reg          <= (others => '0');
                    pc_plus4_reg    <= (others => '0');
                    instruction_reg <= x"00000013";
                elsif stall_i = '0' then
                    pc_reg          <= pc_i;
                    pc_plus4_reg    <= pc_plus4_i;
                    instruction_reg <= instruction_i;
                end if;
                -- Se stall='1' e flush='0', mantém valores atuais
            end if;
        end if;
    end process;

    pc_o          <= pc_reg;
    pc_plus4_o    <= pc_plus4_reg;
    instruction_o <= instruction_reg;
end architecture rtl;

-- =============================================================================
-- ID/EX Pipeline Register
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity id_ex_reg is
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        stall_i       : in  std_logic;
        flush_i       : in  std_logic;
        load_enable_i : in  std_logic;
        -- Entradas do estágio ID
        pc_i          : in  std_logic_vector(31 downto 0);
        pc_plus4_i    : in  std_logic_vector(31 downto 0);
        rs1_data_i    : in  std_logic_vector(31 downto 0);
        rs2_data_i    : in  std_logic_vector(31 downto 0);
        imm_i         : in  std_logic_vector(31 downto 0);
        rs1_addr_i    : in  std_logic_vector(4 downto 0);
        rs2_addr_i    : in  std_logic_vector(4 downto 0);
        rd_addr_i     : in  std_logic_vector(4 downto 0);
        funct3_i      : in  std_logic_vector(2 downto 0);
        -- Sinais de controle
        reg_write_i   : in  std_logic;
        mem_to_reg_i  : in  std_logic;
        mem_write_i   : in  std_logic;
        mem_read_i    : in  std_logic;
        alu_src_i     : in  std_logic;
        alu_ctrl_i    : in  std_logic_vector(3 downto 0);
        branch_i      : in  std_logic;
        jump_i        : in  std_logic;
        auipc_i       : in  std_logic;
        jalr_i        : in  std_logic;
        lui_i         : in  std_logic;
        -- Saídas para estágio EX
        pc_o          : out std_logic_vector(31 downto 0);
        pc_plus4_o    : out std_logic_vector(31 downto 0);
        rs1_data_o    : out std_logic_vector(31 downto 0);
        rs2_data_o    : out std_logic_vector(31 downto 0);
        imm_o         : out std_logic_vector(31 downto 0);
        rs1_addr_o    : out std_logic_vector(4 downto 0);
        rs2_addr_o    : out std_logic_vector(4 downto 0);
        rd_addr_o     : out std_logic_vector(4 downto 0);
        funct3_o      : out std_logic_vector(2 downto 0);
        reg_write_o   : out std_logic;
        mem_to_reg_o  : out std_logic;
        mem_write_o   : out std_logic;
        mem_read_o    : out std_logic;
        alu_src_o     : out std_logic;
        alu_ctrl_o    : out std_logic_vector(3 downto 0);
        branch_o      : out std_logic;
        jump_o        : out std_logic;
        auipc_o       : out std_logic;
        jalr_o        : out std_logic;
        lui_o         : out std_logic
    );
end entity id_ex_reg;

architecture rtl of id_ex_reg is
    signal pc_reg          : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_plus4_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal rs1_data_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal rs2_data_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal imm_reg         : std_logic_vector(31 downto 0) := (others => '0');
    signal rs1_addr_reg    : std_logic_vector(4 downto 0)  := (others => '0');
    signal rs2_addr_reg    : std_logic_vector(4 downto 0)  := (others => '0');
    signal rd_addr_reg     : std_logic_vector(4 downto 0)  := (others => '0');
    signal funct3_reg      : std_logic_vector(2 downto 0)  := (others => '0');
    signal reg_write_reg   : std_logic := '0';
    signal mem_to_reg_reg  : std_logic := '0';
    signal mem_write_reg   : std_logic := '0';
    signal mem_read_reg    : std_logic := '0';
    signal alu_src_reg     : std_logic := '0';
    signal alu_ctrl_reg    : std_logic_vector(3 downto 0) := (others => '0');
    signal branch_reg      : std_logic := '0';
    signal jump_reg        : std_logic := '0';
    signal auipc_reg       : std_logic := '0';
    signal jalr_reg        : std_logic := '0';
    signal lui_reg         : std_logic := '0';
begin
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            pc_reg         <= (others => '0');
            pc_plus4_reg   <= (others => '0');
            rs1_data_reg   <= (others => '0');
            rs2_data_reg   <= (others => '0');
            imm_reg        <= (others => '0');
            rs1_addr_reg   <= (others => '0');
            rs2_addr_reg   <= (others => '0');
            rd_addr_reg    <= (others => '0');
            funct3_reg     <= (others => '0');
            reg_write_reg  <= '0';
            mem_to_reg_reg <= '0';
            mem_write_reg  <= '0';
            mem_read_reg   <= '0';
            alu_src_reg    <= '0';
            alu_ctrl_reg   <= (others => '0');
            branch_reg     <= '0';
            jump_reg       <= '0';
            auipc_reg      <= '0';
            jalr_reg       <= '0';
            lui_reg        <= '0';
        elsif rising_edge(clk_i) then
            if load_enable_i = '0' then
                if flush_i = '1' then
                    -- Flush: todos os controles para zero (NOP)
                    pc_reg         <= (others => '0');
                    pc_plus4_reg   <= (others => '0');
                    rs1_data_reg   <= (others => '0');
                    rs2_data_reg   <= (others => '0');
                    imm_reg        <= (others => '0');
                    rs1_addr_reg   <= (others => '0');
                    rs2_addr_reg   <= (others => '0');
                    rd_addr_reg    <= (others => '0');
                    funct3_reg     <= (others => '0');
                    reg_write_reg  <= '0';
                    mem_to_reg_reg <= '0';
                    mem_write_reg  <= '0';
                    mem_read_reg   <= '0';
                    alu_src_reg    <= '0';
                    alu_ctrl_reg   <= (others => '0');
                    branch_reg     <= '0';
                    jump_reg       <= '0';
                    auipc_reg      <= '0';
                    jalr_reg       <= '0';
                    lui_reg        <= '0';
                elsif stall_i = '0' then
                    pc_reg         <= pc_i;
                    pc_plus4_reg   <= pc_plus4_i;
                    rs1_data_reg   <= rs1_data_i;
                    rs2_data_reg   <= rs2_data_i;
                    imm_reg        <= imm_i;
                    rs1_addr_reg   <= rs1_addr_i;
                    rs2_addr_reg   <= rs2_addr_i;
                    rd_addr_reg    <= rd_addr_i;
                    funct3_reg     <= funct3_i;
                    reg_write_reg  <= reg_write_i;
                    mem_to_reg_reg <= mem_to_reg_i;
                    mem_write_reg  <= mem_write_i;
                    mem_read_reg   <= mem_read_i;
                    alu_src_reg    <= alu_src_i;
                    alu_ctrl_reg   <= alu_ctrl_i;
                    branch_reg     <= branch_i;
                    jump_reg       <= jump_i;
                    auipc_reg      <= auipc_i;
                    jalr_reg       <= jalr_i;
                    lui_reg        <= lui_i;
                end if;
            end if;
        end if;
    end process;

    pc_o         <= pc_reg;
    pc_plus4_o   <= pc_plus4_reg;
    rs1_data_o   <= rs1_data_reg;
    rs2_data_o   <= rs2_data_reg;
    imm_o        <= imm_reg;
    rs1_addr_o   <= rs1_addr_reg;
    rs2_addr_o   <= rs2_addr_reg;
    rd_addr_o    <= rd_addr_reg;
    funct3_o     <= funct3_reg;
    reg_write_o  <= reg_write_reg;
    mem_to_reg_o <= mem_to_reg_reg;
    mem_write_o  <= mem_write_reg;
    mem_read_o   <= mem_read_reg;
    alu_src_o    <= alu_src_reg;
    alu_ctrl_o   <= alu_ctrl_reg;
    branch_o     <= branch_reg;
    jump_o       <= jump_reg;
    auipc_o      <= auipc_reg;
    jalr_o       <= jalr_reg;
    lui_o        <= lui_reg;
end architecture rtl;

-- =============================================================================
-- EX/MEM Pipeline Register
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity ex_mem_reg is
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        flush_i       : in  std_logic;
        load_enable_i : in  std_logic;
        -- Entradas do estágio EX
        pc_plus4_i    : in  std_logic_vector(31 downto 0);
        alu_result_i  : in  std_logic_vector(31 downto 0);
        rs2_data_i    : in  std_logic_vector(31 downto 0);  -- Dado para store
        rd_addr_i     : in  std_logic_vector(4 downto 0);
        zero_i        : in  std_logic;                      -- Flag zero da ALU
        -- Sinais de controle
        reg_write_i   : in  std_logic;
        mem_to_reg_i  : in  std_logic;
        mem_write_i   : in  std_logic;
        mem_read_i    : in  std_logic;
        branch_i      : in  std_logic;
        jump_i        : in  std_logic;
        -- Saídas para estágio MEM
        pc_plus4_o    : out std_logic_vector(31 downto 0);
        alu_result_o  : out std_logic_vector(31 downto 0);
        rs2_data_o    : out std_logic_vector(31 downto 0);
        rd_addr_o     : out std_logic_vector(4 downto 0);
        zero_o        : out std_logic;
        reg_write_o   : out std_logic;
        mem_to_reg_o  : out std_logic;
        mem_write_o   : out std_logic;
        mem_read_o    : out std_logic;
        branch_o      : out std_logic;
        jump_o        : out std_logic
    );
end entity ex_mem_reg;

architecture rtl of ex_mem_reg is
    signal pc_plus4_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_result_reg  : std_logic_vector(31 downto 0) := (others => '0');
    signal rs2_data_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal rd_addr_reg     : std_logic_vector(4 downto 0)  := (others => '0');
    signal zero_reg        : std_logic := '0';
    signal reg_write_reg   : std_logic := '0';
    signal mem_to_reg_reg  : std_logic := '0';
    signal mem_write_reg   : std_logic := '0';
    signal mem_read_reg    : std_logic := '0';
    signal branch_reg      : std_logic := '0';
    signal jump_reg        : std_logic := '0';
begin
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            pc_plus4_reg   <= (others => '0');
            alu_result_reg <= (others => '0');
            rs2_data_reg   <= (others => '0');
            rd_addr_reg    <= (others => '0');
            zero_reg       <= '0';
            reg_write_reg  <= '0';
            mem_to_reg_reg <= '0';
            mem_write_reg  <= '0';
            mem_read_reg   <= '0';
            branch_reg     <= '0';
            jump_reg       <= '0';
        elsif rising_edge(clk_i) then
            if load_enable_i = '0' then
                if flush_i = '1' then
                    pc_plus4_reg   <= (others => '0');
                    alu_result_reg <= (others => '0');
                    rs2_data_reg   <= (others => '0');
                    rd_addr_reg    <= (others => '0');
                    zero_reg       <= '0';
                    reg_write_reg  <= '0';
                    mem_to_reg_reg <= '0';
                    mem_write_reg  <= '0';
                    mem_read_reg   <= '0';
                    branch_reg     <= '0';
                    jump_reg       <= '0';
                else
                    pc_plus4_reg   <= pc_plus4_i;
                    alu_result_reg <= alu_result_i;
                    rs2_data_reg   <= rs2_data_i;
                    rd_addr_reg    <= rd_addr_i;
                    zero_reg       <= zero_i;
                    reg_write_reg  <= reg_write_i;
                    mem_to_reg_reg <= mem_to_reg_i;
                    mem_write_reg  <= mem_write_i;
                    mem_read_reg   <= mem_read_i;
                    branch_reg     <= branch_i;
                    jump_reg       <= jump_i;
                end if;
            end if;
        end if;
    end process;

    pc_plus4_o   <= pc_plus4_reg;
    alu_result_o <= alu_result_reg;
    rs2_data_o   <= rs2_data_reg;
    rd_addr_o    <= rd_addr_reg;
    zero_o       <= zero_reg;
    reg_write_o  <= reg_write_reg;
    mem_to_reg_o <= mem_to_reg_reg;
    mem_write_o  <= mem_write_reg;
    mem_read_o   <= mem_read_reg;
    branch_o     <= branch_reg;
    jump_o       <= jump_reg;
end architecture rtl;

-- =============================================================================
-- MEM/WB Pipeline Register
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity mem_wb_reg is
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        load_enable_i : in  std_logic;
        -- Entradas do estágio MEM
        pc_plus4_i    : in  std_logic_vector(31 downto 0);
        alu_result_i  : in  std_logic_vector(31 downto 0);
        mem_data_i    : in  std_logic_vector(31 downto 0);  -- Dado lido da memória
        rd_addr_i     : in  std_logic_vector(4 downto 0);
        -- Sinais de controle
        reg_write_i   : in  std_logic;
        mem_to_reg_i  : in  std_logic;
        jump_i        : in  std_logic;
        -- Saídas para estágio WB
        pc_plus4_o    : out std_logic_vector(31 downto 0);
        alu_result_o  : out std_logic_vector(31 downto 0);
        mem_data_o    : out std_logic_vector(31 downto 0);
        rd_addr_o     : out std_logic_vector(4 downto 0);
        reg_write_o   : out std_logic;
        mem_to_reg_o  : out std_logic;
        jump_o        : out std_logic
    );
end entity mem_wb_reg;

architecture rtl of mem_wb_reg is
    signal pc_plus4_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_result_reg  : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_data_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal rd_addr_reg     : std_logic_vector(4 downto 0)  := (others => '0');
    signal reg_write_reg   : std_logic := '0';
    signal mem_to_reg_reg  : std_logic := '0';
    signal jump_reg        : std_logic := '0';
begin
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            pc_plus4_reg   <= (others => '0');
            alu_result_reg <= (others => '0');
            mem_data_reg   <= (others => '0');
            rd_addr_reg    <= (others => '0');
            reg_write_reg  <= '0';
            mem_to_reg_reg <= '0';
            jump_reg       <= '0';
        elsif rising_edge(clk_i) then
            if load_enable_i = '0' then
                pc_plus4_reg   <= pc_plus4_i;
                alu_result_reg <= alu_result_i;
                mem_data_reg   <= mem_data_i;
                rd_addr_reg    <= rd_addr_i;
                reg_write_reg  <= reg_write_i;
                mem_to_reg_reg <= mem_to_reg_i;
                jump_reg       <= jump_i;
            end if;
        end if;
    end process;

    pc_plus4_o   <= pc_plus4_reg;
    alu_result_o <= alu_result_reg;
    mem_data_o   <= mem_data_reg;
    rd_addr_o    <= rd_addr_reg;
    reg_write_o  <= reg_write_reg;
    mem_to_reg_o <= mem_to_reg_reg;
    jump_o       <= jump_reg;
end architecture rtl;
