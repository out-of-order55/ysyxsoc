package ysyx

import chisel3._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.system.DefaultConfig
import freechips.rocketchip.diplomacy.LazyModule

class ysyxSoCTop extends Module {
  implicit val config: Parameters = new DefaultConfig

  val io = IO(new Bundle { })
  val dut = LazyModule(new ysyxSoCFull)
  val mdut = Module(dut.module)
  mdut.dontTouchPorts()
  mdut.cpu_mem := DontCare
  mdut.cpu_mmio.foreach(_ := DontCare)
  mdut.cpu_dma := DontCare
  mdut.spi.foreach(_ := DontCare)
  mdut.uart.foreach(_ := DontCare)
}

object Elaborate extends App {
  val firtoolOptions = Array("--disable-annotation-unknown")
  circt.stage.ChiselStage.emitSystemVerilogFile(new ysyxSoCTop, args, firtoolOptions)
}