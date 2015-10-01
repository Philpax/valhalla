require "./tss"

lib CPU
	fun load_gdt(gdt : Void*, size : Int32) : Void
	fun reload_segments() : Void
end

struct GDT
	alias Entry = StaticArray(UInt8, 8)
	@tss = CPU::TSS.new

	def initialize()
		# Flat, untranslated addresses
		@gdt = StaticArray(GDT::Entry, 4).new { GDT::Entry.new 0_u8 }
		# Null selector
		@gdt[0] = self.encode 0_u32, 0, 0_u8
		# Code selector
		@gdt[1] = self.encode 0_u32, 0xFFFFFFFF, 0x9A_u8
		# Data selector
		@gdt[2] = self.encode 0_u32, 0xFFFFFFFF, 0x92_u8
		# TSS selector
		@gdt[3] = self.encode pointerof(@tss).address.to_u32, sizeof(CPU::TSS), 0x89_u8

		CPU.load_gdt @gdt.to_unsafe as Void*, sizeof(typeof(@gdt))-1
		CPU.reload_segments
	end

	def encode(base : UInt32, limit : Int, access : U8)
		target = GDT::Entry.new 0_u8

		if limit > 65536
			limit >>= 12
			target[6] = 0xC0_u8
		else
			target[6] = 0x40_u8
		end

		# Encode limit
		target[0] = (limit & 0xFF).to_u8()
		target[1] = ((limit >> 8) & 0xFF).to_u8()
		target[6] |= ((limit >> 16) & 0xF).to_u8()

		# Encode base
		target[2] = (base & 0xFF).to_u8()
		target[3] = ((base >> 8) & 0xFF).to_u8()
		target[4] = ((base >> 16) & 0xFF).to_u8()
		target[7] = ((base >> 24) & 0xFF).to_u8()

		# Encode access
		target[5] = access

		target
	end
end