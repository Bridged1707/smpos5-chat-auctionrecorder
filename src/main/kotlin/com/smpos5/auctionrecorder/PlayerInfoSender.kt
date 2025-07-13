package com.smpos5.auctionrecorder

import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents
import net.minecraft.client.MinecraftClient
import org.slf4j.LoggerFactory

object PlayerInfoSender {
    private val logger = LoggerFactory.getLogger("smp-online-s5-auction-recorder")
    private var sent = false

    fun register() {
        ClientTickEvents.END_CLIENT_TICK.register(ClientTickEvents.EndTick { client ->
            if (!sent && client.player != null) {
                val player = client.player!!
                val username = player.name.string
                val uuid = player.uuidAsString

                logger.info("Sending player info: $username / $uuid")

                // Use your existing ChatLoggerClient to send this info
                val message = "PLAYER_INFO: $username | $uuid"
                ChatLoggerClient.sendEncryptedAuctionMessage(message)

                sent = true
            }
        })
    }
}
