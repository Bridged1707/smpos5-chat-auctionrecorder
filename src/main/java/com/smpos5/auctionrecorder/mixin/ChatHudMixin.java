package com.smpos5.auctionrecorder.mixin;

import com.smpos5.auctionrecorder.ChatLoggerClient;
import net.minecraft.client.gui.hud.ChatHud;
import net.minecraft.text.Text;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

@Mixin(ChatHud.class)
public class ChatHudMixin {
    private static String lastAuctionListing = null;
    private static Instant lastAuctionListingTime = null;

    private static final DateTimeFormatter timestampFormatter = DateTimeFormatter
            .ofPattern("yyyy-MM-dd HH:mm:ss")
            .withZone(ZoneOffset.UTC);

    @Inject(method = "addMessage(Lnet/minecraft/text/Text;)V", at = @At("HEAD"))
    private void onAddMessage(Text message, CallbackInfo ci) {
        boolean hasItalic = containsItalic(message);

        String rawText = message.getString();
        if (hasItalic) {
            rawText += " - RENAMED ITEM";
        }

        String lowercase = rawText.toLowerCase();
        Instant now = Instant.now();
        String timestamp = timestampFormatter.format(now);

        if (lowercase.contains("auctioning") && rawText.contains("[Auction]")) {
            lastAuctionListing = "[" + timestamp + "] " + rawText;
            lastAuctionListingTime = now;
            System.out.println("[ChatHudMixin] Cached auction listing: " + lastAuctionListing);
            return;
        }

        if (lowercase.contains("won the auction") && rawText.contains("[Auction]")) {
            String wonMessage = "[" + timestamp + "] " + rawText;

            if (lastAuctionListing != null) {
                String combined = lastAuctionListing + "\n" + wonMessage;
                System.out.println("[ChatHudMixin] Sending combined auction listing and win:\n" + combined);
                ChatLoggerClient.INSTANCE.sendEncryptedAuctionMessage(combined);
                lastAuctionListing = null;
                lastAuctionListingTime = null;
            } else {
                System.out.println("[ChatHudMixin] Sending auction won message: " + wonMessage);
                ChatLoggerClient.INSTANCE.sendEncryptedAuctionMessage(wonMessage);
            }
            return;
        }

        if (lowercase.contains("auction ended") &&
                (lowercase.contains("no one bid") || lowercase.contains("no bids") || lowercase.contains("didn't sell"))) {
            lastAuctionListing = null;
            lastAuctionListingTime = null;
            return;
        }

        if (lastAuctionListingTime != null && Instant.now().minusSeconds(60).isAfter(lastAuctionListingTime)) {
            System.out.println("[ChatHudMixin] Clearing stale auction listing cache");
            lastAuctionListing = null;
            lastAuctionListingTime = null;
        }
    }

    private boolean containsItalic(Text text) {
        if (text.getStyle().isItalic()) return true;
        for (Text child : text.getSiblings()) {
            if (containsItalic(child)) return true;
        }
        return false;
    }
}
