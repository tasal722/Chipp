library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tt_um_morse_it is
    port (
        ui_in   : in  std_logic_vector(7 downto 0); -- bit 0 används till input från knapp
        uo_out  : out std_logic_vector(7 downto 0); -- ascii out
        uio_in  : in  std_logic_vector(7 downto 0);
        uio_out : out std_logic_vector(7 downto 0);
        uio_oe  : out std_logic_vector(7 downto 0);
        ena     : in  std_logic;
        clk     : in  std_logic;
        rst_n   : in  std_logic
    );
end tt_um_morse_it;

architecture Behavioral of tt_um_morse_it is
    signal press_counter: integer range 0 to 255 := 0;
    signal pause_counter: integer range 0 to 255 := 0;
    signal morse_buffer : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_count    : integer range 0 to 7 := 0;
    signal ascii_char   : std_logic_vector(7 downto 0) := (others => '0');
    signal sampling     : std_logic := '0'; 
    signal prev_input   : std_logic := '0';

    constant DOT_THERESHOLD     : integer := 10;    -- kort tryck är punkt, längre tryck är streck
    constant PAUSE_THERESHOLD     : integer := 50;  -- paus mellan tecknena


    function morse_to_ascii(morse : std_logic_vector(7 downto 0)) return std_logic_vector is
begin
    case morse is    
        when "00000110" => return x"41"; -- A (.-) --omvänd ordning på våra binära värden för bit count börja från vänster ej höger
        when "00010001" => return x"42"; -- B (-...)
        when "00010101" => return x"43"; -- C (-.-.)
        when "00001000" => return x"53"; -- S (...)
        when "00001111" => return x"4F"; -- O(---)
        when "00000011" => return x"54"; -- T (-)
        when "00000101" => return x"4E"; -- N(-.)
        when "00000100" => return x"49"; --I(..)
        when "00000111"=> return x"4D"; -- M(--)
        when "00010100" => return x"46"; -- F(..-.)
        when "00010000" => return x"48"; -- H(....)
        when others => return x"3F"; -- ?
    end case;
    end function;

begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then 
            press_counter    <= 0;
            pause_counter   <= 0;
            morse_buffer <= (others => '0');
            bit_count    <= 0;
            ascii_char   <= (others => '0');
            sampling     <= '0';
            prev_input   <= '0';
        
        elsif rising_edge(clk) then
            if ena = '1' then


            if ui_in(0) = '1' then              -- om knapp trycks ner
                if prev_input = '0' then

                    sampling <= '1';            -- här och nedan börjar ny tryckning
                    press_counter <= 1;
                    pause_counter <= 0;
                elsif sampling = '1' then

                  press_counter <= press_counter + 1;       -- räknr hur länge kanppen hålls
                end if;
          
            -- om knappen släpps
            elsif ui_in(0) = '0' then
                if sampling = '1' then
                 -- tryckning avslutad

                 --  tolka nu om det var punkt eller streck
                  if bit_count < 8 then
                     if press_counter < DOT_THERESHOLD then
                        morse_buffer(bit_count) <= '0'; -- punkt
                     else
                        morse_buffer(bit_count) <= '1'; -- streck
                     end if;
                     bit_count <= bit_count + 1;
                end if;
                press_counter <= 0;
                sampling <= '0';
            end if;

            pause_counter <= pause_counter + 1;     -- räkna pauslängden mellan tryck

            -- Om pausen är tillräckligt lång så tolka bufferten som ett färdigt tecken
            if pause_counter > PAUSE_THERESHOLD and bit_count > 0 then
                --ascii_char <=  morse_to_ascii(morse_buffer);
                --ascii_char <= morse_to_ascii(morse_buffer(morse_buffer'high downto bit_count+1) & "1" & morse_buffer(bit_count-1 downto 0));
                ascii_char <=  morse_to_ascii(morse_buffer or std_logic_vector(shift_left(to_unsigned(1, 8), bit_count)));
                bit_count <= 0;
                morse_buffer <= (others => '0');
                pause_counter <= 0;
            end if;
        end if;

            prev_input <= ui_in(0);         -- spara förra knappstatus
            end if;
        end if;
    end process;

    uo_out <= ascii_char;   -- skicka ut ascii värdet

    uio_out <= (others => '0');     -- de som inte används inaktiveras
    uio_oe <= (others => '0');      -- de som inte används inaktiveras
end Behavioral;

 