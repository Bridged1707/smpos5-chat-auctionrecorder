package com.smpos5.auctionrecorder

import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import java.security.SecureRandom
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread
import net.minecraft.client.MinecraftClient

object ChatLoggerClient {
    private const val AES_KEY_BASE64 = "12345..."
    private val keyBytes = Base64.getDecoder().decode(AES_KEY_BASE64)
    private val keySpec = SecretKeySpec(keyBytes, "AES")
    private val secureRandom = SecureRandom()

    fun sendEncryptedAuctionMessage(message: String) {
        thread {
            try {
                val player = MinecraftClient.getInstance().player
                if (player == null) {
                    System.err.println("⚠️ Player entity not ready. Aborting message send.")
                    return@thread
                }

                val username = player.name.string
                val uuid = player.uuidAsString

                val fullMessage = buildString {
                    appendLine("[$currentTimestamp] $username | $uuid")
                    append(message)
                }

                val payload = encrypt(fullMessage)
                val json = """
                    {
                        "nonce": "${payload["nonce"]}",
                        "data": "${payload["data"]}"
                    }
                """.trimIndent()

                val url = URL("https://smpos5-auctionrecorder.onrender.com/api/auction-log")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.doOutput = true

                conn.outputStream.use { os ->
                    os.write(json.toByteArray(Charsets.UTF_8))
                }

                val responseCode = conn.responseCode
                if (responseCode == 200) {
                    println("⚡️ Auction message sent successfully.")
                } else {
                    println("⚠️ Failed to send chat message: HTTP $responseCode")
                }

                conn.disconnect()
            } catch (e: Exception) {
                System.err.println("⚠️ Failed to send chat message: ${e.message}")
            }
        }
    }

    private fun encrypt(plainText: String): Map<String, String> {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val nonce = ByteArray(12)
        secureRandom.nextBytes(nonce)
        val spec = GCMParameterSpec(128, nonce)
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, spec)

        val encrypted = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))

        return mapOf(
            "nonce" to Base64.getEncoder().encodeToString(nonce),
            "data" to Base64.getEncoder().encodeToString(encrypted)
        )
    }

    private val currentTimestamp: String
        get() {
            val now = java.time.ZonedDateTime.now(java.time.ZoneOffset.UTC)
            val formatter = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
            return now.format(formatter)
        }
}
