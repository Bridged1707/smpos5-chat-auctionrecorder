package com.smpos5.auctionrecorder

import net.fabricmc.api.ModInitializer
import org.slf4j.LoggerFactory

object SMPOnlineS5AuctionRecorder : ModInitializer {
	private val logger = LoggerFactory.getLogger("smp-online-s5-auction-recorder")

	override fun onInitialize() {
		logger.info("Hello Fabric world!")
		PlayerInfoSender.register()
	}
}
