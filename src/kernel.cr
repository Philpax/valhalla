require "./terminal"
require "./multiboot"
require "./vfs"
require "./gdt"
require "./cpuid"
require "./idt"

struct Kernel
	@vfs :: VirtualFilesystem | Nil

	def initialize(multiboot : Multiboot::Information*)
		@gdt = GDT.new

		@gdt.load
		$idt.load

		$terminal.clear

		$kernel_panic_handler = ->panic(String)

		$terminal.write "Valhalla", fg: Terminal::Color::Magenta
		$terminal.write ": a "
		$terminal.write "Crystal", fg: Terminal::Color::White
		$terminal.writeln "-based OS"

		self.write_cpuid
		self.load_multiboot multiboot

		if vfs = @vfs
			$terminal.writeln "VFS:", fg: Terminal::Color::DarkGrey
			vfs.each_file do |file, contents|
				$terminal.write " "
				$terminal.write file
				$terminal.write ": "
				$terminal.writeln StringView.new(contents)
			end
		end

		CPU.syscall(42, nil)
	end

	def write_cpuid
		$terminal.write "CPU brand:    ", fg: Terminal::Color::DarkGrey

		name_array = StaticArray(UInt8, 12).new 0_u8
		name_view = StringView.new name_array.to_slice
		CPUID.get_vendor_id_string name_view
		$terminal.writeln name_view

		features = CPUID.get_feature_information

		$terminal.write "CPU features: ", fg: Terminal::Color::DarkGrey
		$terminal.write "SSE" if features.includes? CPUID::Features::SSE
		$terminal.write ", SSE2" if features.includes? CPUID::Features::SSE2
		$terminal.writeln
	end

	def load_multiboot(multiboot : Multiboot::Information*)
		info = multiboot.value
		if info.flags.bootloader_name?
			$terminal.write "Bootloader:   ", fg: Terminal::Color::DarkGrey
			$terminal.writeln StringView.new(info.bootloader_name)
		end

		if info.flags.memory?
			$terminal.write "Lower memory: ", fg: Terminal::Color::DarkGrey
			$terminal.write info.mem_lower
			$terminal.writeln " kilobytes"

			$terminal.write "Upper memory: ", fg: Terminal::Color::DarkGrey
			$terminal.write info.mem_upper
			$terminal.write " kilobytes"
			if info.mem_upper > 1024
				$terminal.write " ("
				$terminal.write info.mem_upper / 1024
				$terminal.write " megabytes)"
			end
			$terminal.writeln
		end

		if info.flags.modules?
			$terminal.write "Modules: ", fg: Terminal::Color::DarkGrey
			info.mods_count.times do |i|
				mod = info.mods_addr[i]
				$terminal.write ", " unless i == 0
				$terminal.write StringView.new(mod.str)
				$terminal.write " ("
				$terminal.write (mod.mod_end - mod.mod_start).to_u32()
				$terminal.write " bytes"

				if VirtualFilesystem.valid? mod.mod_start
					$terminal.write ", "
					$terminal.write "vfs", fg: Terminal::Color::Green

					@vfs = VirtualFilesystem.new(mod.mod_start as UInt8*, mod.mod_end as UInt8*)
				end

				$terminal.write ")"
			end
			$terminal.writeln
		end
	end

	def panic(msg)
		header_color = Terminal::Color::Red

		$terminal.clear
		$terminal.fill_rect 0, 0, 80, 1, header_color
		$terminal.puts 0, 0, "Kernel Panic!", header_color, Terminal::Color::White
		$terminal.puts 0, 1, msg

		CPU.halt()
	end
end