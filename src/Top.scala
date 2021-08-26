package ysyx

import chisel3._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.system.DefaultConfig
import freechips.rocketchip.diplomacy.LazyModule

class ysyxSoCTop extends Module {
  implicit val config: Parameters = new DefaultConfig

  val io = IO(new Bundle { })
  val dut = LazyModule(new ysyxSoCASIC)
  val mdut = Module(dut.module)
  mdut.dontTouchPorts()
  mdut.cpu_mem := DontCare
  mdut.cpu_mmio.foreach(_ := DontCare)
  mdut.cpu_dma := DontCare
  mdut.spi.foreach(_ := DontCare)
  mdut.uart.foreach(_ := DontCare)
  mdut.fpga_io.b2c := DontCare
}

object Elaborate extends App {
  circt.stage.ChiselStage.emitSystemVerilogFile(new ysyxSoCTop, args)
}
