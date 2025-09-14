package com.yeboverify.yebo_verify

import android.app.Activity
import android.content.Intent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Bundle
import android.util.Log

/**
 * Activity to handle USB device attachment events for Bio ID fingerprint scanners
 */
class UsbDeviceActivity : Activity() {
    companion object {
        private const val TAG = "UsbDeviceActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "UsbDeviceActivity created")
        
        handleUsbDeviceIntent(intent)
        finish() // Close this activity immediately
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { handleUsbDeviceIntent(it) }
    }

    private fun handleUsbDeviceIntent(intent: Intent) {
        when (intent.action) {
            UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                device?.let {
                    Log.d(TAG, "USB device attached: ${it.deviceName}")
                    Log.d(TAG, "Vendor ID: ${String.format("0x%04X", it.vendorId)}")
                    Log.d(TAG, "Product ID: ${String.format("0x%04X", it.productId)}")
                    Log.d(TAG, "Device Class: ${it.deviceClass}")
                    
                    // Check if this looks like a Bio ID device
                    if (isBioIdDevice(it)) {
                        Log.d(TAG, "Bio ID fingerprint scanner detected!")
                        // The FingerprintPlugin will handle device discovery and connection
                    }
                }
            }
        }
    }

    private fun isBioIdDevice(device: UsbDevice): Boolean {
        // Common Bio ID vendor IDs
        val bioIdVendorIds = listOf(0x2808, 0x1491, 0x27C6)
        
        // Check vendor ID
        if (bioIdVendorIds.contains(device.vendorId)) {
            return true
        }
        
        // Check if it's a HID device (common for fingerprint scanners)
        if (device.deviceClass == 3) { // USB HID class
            Log.d(TAG, "HID device detected, might be fingerprint scanner")
            return true
        }
        
        // Check device name/manufacturer if available
        val deviceName = device.deviceName?.lowercase() ?: ""
        val manufacturerName = device.manufacturerName?.lowercase() ?: ""
        val productName = device.productName?.lowercase() ?: ""
        
        return deviceName.contains("bioid") || 
               deviceName.contains("fingerprint") ||
               manufacturerName.contains("bioid") ||
               productName.contains("fingerprint")
    }
}