package ysyx

import chisel3._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.system.DefaultConfig
import freechips.rocketchip.diplomacy.LazyModule

class ysyxSoCTop extends Module {
  implicit val config: Parameters = new DefaultConfig

  val io = IO(new Bundle { })
  val dut = LazyModule(new ChipLinkSlave)
  val mdut = Module(dut.module)
  mdut.dontTouchPorts()
  dut.slave.map(_ := DontCare)
  dut.master_mmio.map(_ := DontCare)
  dut.master_mem.map(_ := DontCare)
  mdut.fpga_io.b2c := DontCare
}

object Elaborate extends App {
  circt.stage.ChiselStage.emitSystemVerilogFile(new ysyxSoCTop, args)
}
