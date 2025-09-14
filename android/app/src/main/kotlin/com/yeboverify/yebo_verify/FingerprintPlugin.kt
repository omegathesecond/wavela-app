package com.yeboverify.yebo_verify

import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.app.PendingIntent
import android.hardware.usb.UsbManager
import android.hardware.usb.UsbDevice
import android.util.Log
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

// Bio ID SDK imports - from working demo (commented out temporarily)
// import com.fingerprint.driver.FingerApiFactory
// import com.fingerprint.driver.FingerApi  
// import com.fingerprint.driver.usb.FingerApiUsbWrapper  // Like working demo
// import com.fingerprint.bean.CaptureConfig
// import com.fingerprint.common.MxResult
// import com.fingerprint.common.MxImage

class FingerprintPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val CHANNEL = "bioid_fingerprint"
        private const val TAG = "FingerprintPlugin"
        private const val ACTION_USB_PERMISSION = "com.yeboverify.yebo_verify.USB_PERMISSION"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    // private var fingerApi: FingerApi? = null
    private var isDeviceOpen = false
    private var usbManager: UsbManager? = null
    private var usbReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
        registerUsbReceiver()
        Log.d(TAG, "FingerprintPlugin attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        unregisterUsbReceiver()
        // Close device if open
        if (isDeviceOpen) {
            // fingerApi?.let { (it as FingerApiUsbWrapper).closeDevice() }
            isDeviceOpen = false
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "discoverDevices" -> discoverDevices(result)
            "connectToDevice" -> {
                val deviceId = call.argument<String>("deviceId") ?: ""
                connectToDevice(deviceId, result)
            }
            "openDevice" -> openDevice(result)
            "closeDevice" -> closeDevice(result)
            "detectFinger" -> detectFinger(result)
            "captureFingerprint" -> {
                val finger = call.argument<String>("finger") ?: ""
                captureFingerprint(finger, result)
            }
            "getDeviceInfo" -> getDeviceInfo(result)
            "getDeviceSerialNumber" -> getDeviceSerialNumber(result)
            else -> result.notImplemented()
        }
    }

    private fun discoverDevices(result: Result) {
        Log.d(TAG, "Discovering Bio ID USB devices...")

        try {
            val devices = mutableListOf<Map<String, Any>>()
            
            // Check for Bio ID devices using the correct VID/PID from working sample
            usbManager?.let { manager ->
                val deviceList = manager.deviceList
                var fingerDevice: UsbDevice? = null
                
                for (device in deviceList.values) {
                    Log.d(TAG, "Found USB device: VID=${String.format("0x%04X", device.vendorId)}, PID=${String.format("0x%04X", device.productId)}")
                    
                    // Check for Bio ID devices using SDK constants (commented out)
                    // if ((device.vendorId == FingerApiFactory.VC_VID && device.productId == FingerApiFactory.VC_PID) ||
                    //     (device.vendorId == FingerApiFactory.MSC_VID && device.productId == FingerApiFactory.MSC_PID)) {
                    if (false) { // Temporarily disabled
                        fingerDevice = device
                        Log.d(TAG, "Found Bio ID fingerprint device!")
                        
                        devices.add(mapOf(
                            "id" to "bio-id-${device.deviceId}",
                            "name" to "Bio ID Fingerprint Scanner",
                            "manufacturer" to "Bio ID",
                            "model" to (device.productName ?: "USB Scanner"),
                            "isConnected" to false,
                            "signalStrength" to 100
                        ))
                        break
                    }
                }
                
                if (fingerDevice != null) {
                    // Initialize API first (like the working demo) - commented out
                    try {
                        // fingerApi = FingerApiFactory.getInstance(context, FingerApiFactory.USB)
                        Log.d(TAG, "Bio ID SM92MSVcApi initialization skipped (commented out)")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to initialize Bio ID API", e)
                    }
                    
                    // Auto-request permission and connect 
                    requestPermissionAndConnect(manager, fingerDevice)
                } else {
                    Log.w(TAG, "No Bio ID devices found in USB device list")
                    // Still return empty list so UI knows discovery completed
                }
            }

            result.success(devices)
            Log.d(TAG, "Discovery completed - found ${devices.size} Bio ID devices")

        } catch (e: Exception) {
            Log.e(TAG, "Error discovering devices", e)
            result.error("DISCOVERY_ERROR", e.message, null)
        }
    }

    private fun connectToDevice(deviceId: String, result: Result) {
        Log.d(TAG, "Connecting to device: $deviceId")

        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Always ensure API is initialized before connecting (like working demo) - commented out
                // if (fingerApi == null) {
                    Log.d(TAG, "Bio ID API initialization skipped (commented out)")
                //     try {
                //         fingerApi = FingerApiFactory.getInstance(context, FingerApiFactory.USB)
                //         Log.d(TAG, "Bio ID SM92MSVcApi initialized successfully")
                //     } catch (e: Exception) {
                //         Log.e(TAG, "Failed to initialize Bio ID API", e)
                //         throw Exception("Bio ID API initialization failed: ${e.message}")
                //     }
                // }
                
                Log.d(TAG, "Opening Bio ID device... (simulated)")
                // val openResult = (fingerApi as FingerApiUsbWrapper).openDevice()
                val openResult = 1 // Simulated success
                
                if (openResult >= 0) {
                    isDeviceOpen = true
                    Log.d(TAG, "Bio ID device opened successfully. Result code: $openResult")
                    
                    val response = mapOf(
                        "success" to true,
                        "deviceId" to deviceId,
                        "message" to "Connected to Bio ID device"
                    )

                    withContext(Dispatchers.Main) {
                        result.success(response)
                    }
                } else {
                    throw Exception("Failed to open Bio ID device. Error code: $openResult")
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error connecting to device", e)
                withContext(Dispatchers.Main) {
                    result.error("CONNECTION_ERROR", e.message, null)
                }
            }
        }
    }

    private fun openDevice(result: Result) {
        Log.d(TAG, "Opening Bio ID device for fingerprint capture...")

        try {
            // if (fingerApi == null) {
            //     result.error("DEVICE_NOT_INITIALIZED", "Bio ID API not initialized", null)
            //     return
            // }
            
            if (!isDeviceOpen) {
                Log.d(TAG, "Device not yet opened, opening now... (simulated)")
                // val openResult = (fingerApi as FingerApiUsbWrapper).openDevice()
                val openResult = 1 // Simulated success
                
                if (openResult >= 0) {
                    isDeviceOpen = true
                    Log.d(TAG, "Bio ID device opened and LED should now be active. Result code: $openResult")
                    result.success(openResult)
                } else {
                    Log.e(TAG, "Failed to open Bio ID device, code: $openResult")
                    result.error("OPEN_FAILED", "Failed to open device, code: $openResult", null)
                }
            } else {
                Log.d(TAG, "Bio ID device already open and ready")
                result.success(1)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error opening device", e)
            result.error("OPEN_ERROR", e.message, null)
        }
    }

    private fun closeDevice(result: Result) {
        Log.d(TAG, "Closing Bio ID device...")

        try {
            // if (fingerApi != null && isDeviceOpen) {
            if (isDeviceOpen) {
                // val closeResult = (fingerApi as FingerApiUsbWrapper).closeDevice()
                val closeResult = 0 // Simulated success
                isDeviceOpen = false
                Log.d(TAG, "Bio ID device closed, result code: $closeResult (simulated)")
                result.success(closeResult == 0)
            } else {
                Log.d(TAG, "Bio ID device already closed")
                result.success(true)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error closing device", e)
            result.error("CLOSE_ERROR", e.message, null)
        }
    }

    private fun detectFinger(result: Result) {
        try {
            // if (fingerApi == null) {
                Log.d(TAG, "Bio ID API initialization skipped (commented out)")
            //     try {
            //         fingerApi = FingerApiFactory.getInstance(context, FingerApiFactory.USB)
            //         Log.d(TAG, "Bio ID SM92MSVcApi initialized for finger detection")
            //     } catch (e: Exception) {
            //         Log.e(TAG, "Failed to initialize Bio ID API during finger detection", e)
            //         result.error("INITIALIZATION_ERROR", "Failed to initialize Bio ID API: ${e.message}", null)
            //         return
            //     }
            // }
            
            if (!isDeviceOpen) {
                result.error("DEVICE_NOT_OPEN", "Device not open", null)
                return
            }
            
            Log.d(TAG, "Checking for finger presence on Bio ID device... (simulated)")
            // val detectResult = (fingerApi as FingerApiUsbWrapper).detectFinger()
            
            // Simulate finger detection result
            val fingerPresent = false // Simulated result
            Log.d(TAG, "Finger detection result: $fingerPresent (simulated)")
            result.success(fingerPresent)
            
            // if (detectResult != null && detectResult.isSuccess()) {
            //     val fingerPresent = detectResult.data ?: false
            //     Log.d(TAG, "Finger detection result: $fingerPresent")
            //     result.success(fingerPresent)
            // } else {
            //     Log.w(TAG, "Finger detection failed, code: ${detectResult?.code}, msg: ${detectResult?.msg}")
            //     result.success(false)
            // }

        } catch (e: Exception) {
            Log.e(TAG, "Error detecting finger", e)
            result.error("DETECT_ERROR", e.message, null)
        }
    }

    private fun captureFingerprint(finger: String, result: Result) {
        Log.d(TAG, "Capturing fingerprint for: $finger using Bio ID device")

        CoroutineScope(Dispatchers.IO).launch {
            try {
                // if (fingerApi == null) {
                    Log.d(TAG, "Bio ID API initialization skipped (commented out)")
                //     try {
                //         fingerApi = FingerApiFactory.getInstance(context, FingerApiFactory.USB)
                //         Log.d(TAG, "Bio ID SM92MSVcApi initialized for fingerprint capture")
                //     } catch (e: Exception) {
                //         Log.e(TAG, "Failed to initialize Bio ID API during fingerprint capture", e)
                //         withContext(Dispatchers.Main) {
                //             result.error("INITIALIZATION_ERROR", "Failed to initialize Bio ID API: ${e.message}", null)
                //         }
                //         return@launch
                //     }
                // }
                
                if (!isDeviceOpen) {
                    withContext(Dispatchers.Main) {
                        result.error("DEVICE_NOT_OPEN", "Device not open", null)
                    }
                    return@launch
                }

                Log.d(TAG, "Setting up capture configuration... (simulated)")
                // Use exact config from QuickStart Guide - commented out
                // val config = CaptureConfig.Builder()
                //     .setLfdLevel(0)        // No live finger detection
                //     .setLatentLevel(0)     // No latent detection  
                //     .setTimeout(8000)      // 8 second timeout as in QuickStart Guide
                //     .setAreaScore(45)      // 45% minimum area as in QuickStart Guide
                //     .build()

                Log.d(TAG, "Capturing image from Bio ID device... (simulated)")
                // val imageResult = (fingerApi as FingerApiUsbWrapper).getImage(config)
                
                // Simulate successful capture
                Log.d(TAG, "Image captured successfully (simulated)")
                
                // Simulate response data
                val quality = 0.85 // Simulated quality
                val template = "simulated_template_data" // Simulated template
                
                val response = mapOf(
                    "success" to true,
                    "template" to template,
                    "quality" to quality
                )
                
                Log.d(TAG, "Fingerprint captured successfully with quality: $quality (simulated)")
                withContext(Dispatchers.Main) {
                    result.success(response)
                }
                
                // Original code commented out
                // if (imageResult != null && imageResult.isSuccess()) {
                //     Log.d(TAG, "Image captured successfully")
                //     
                //     val image = imageResult.data
                //     if (image != null && image.data != null) {
                //         // Calculate quality based on image properties
                //         val quality = calculateQuality(image)
                //         
                //         // Convert image data to base64 template (simplified approach)
                //         val template = android.util.Base64.encodeToString(image.data, android.util.Base64.DEFAULT)
                //         
                //         val response = mapOf(
                //             "success" to true,
                //             "template" to template,
                //             "quality" to quality
                //         )
                //         
                //         Log.d(TAG, "Fingerprint captured successfully with quality: $quality")
                //         withContext(Dispatchers.Main) {
                //             result.success(response)
                //         }
                //     } else {
                //         Log.e(TAG, "Image data is null")
                //         withContext(Dispatchers.Main) {
                //             result.error("CAPTURE_FAILED", "Image data is null", null)
                //         }
                //     }
                // } else {
                //     Log.e(TAG, "Failed to capture image, code: ${imageResult?.code}, msg: ${imageResult?.msg}")
                //     withContext(Dispatchers.Main) {
                //         result.error("CAPTURE_FAILED", "Failed to capture image: ${imageResult?.msg}", null)
                //     }
                // }

            } catch (e: Exception) {
                Log.e(TAG, "Error capturing fingerprint", e)
                withContext(Dispatchers.Main) {
                    result.error("CAPTURE_ERROR", e.message, null)
                }
            }
        }
    }
    
    // private fun calculateQuality(image: MxImage): Double {
    //     // Quality calculation based on image properties and Bio ID standards
    //     return if (image.width > 0 && image.height > 0) {
    //         val pixelCount = image.width * image.height
    //         val dataSize = image.data?.size ?: 0
    //         
    //         when {
    //             pixelCount > 200000 && dataSize > 100000 -> 0.9 + (Math.random() * 0.1)  // 90-100%
    //             pixelCount > 100000 && dataSize > 50000 -> 0.8 + (Math.random() * 0.1)   // 80-90%
    //             pixelCount > 50000 && dataSize > 25000 -> 0.7 + (Math.random() * 0.1)    // 70-80%
    //             else -> 0.6 + (Math.random() * 0.1)                                      // 60-70%
    //         }
    //     } else {
    //         0.5 // Default quality
    //     }
    // }

    private fun getDeviceInfo(result: Result) {
        try {
            // if (fingerApi == null) {
                Log.d(TAG, "Bio ID API initialization skipped (commented out)")
            //     try {
            //         fingerApi = FingerApiFactory.getInstance(context, FingerApiFactory.USB)
            //         Log.d(TAG, "Bio ID SM92MSVcApi initialized for device info")
            //     } catch (e: Exception) {
            //         Log.e(TAG, "Failed to initialize Bio ID API during device info", e)
            //         result.error("INITIALIZATION_ERROR", "Failed to initialize Bio ID API: ${e.message}", null)
            //         return
            //     }
            // }
            
            // val infoResult = (fingerApi as FingerApiUsbWrapper).deviceInfo
            // if (infoResult != null && infoResult.code == 0) {
            //     result.success(infoResult.data)
            // } else {
                result.success("Bio ID Device (Info unavailable - simulated)")
            // }

        } catch (e: Exception) {
            Log.e(TAG, "Error getting device info", e)
            result.error("INFO_ERROR", e.message, null)
        }
    }

    private fun getDeviceSerialNumber(result: Result) {
        try {
            // if (fingerApi == null) {
                Log.d(TAG, "Bio ID API initialization skipped (commented out)")
            //     try {
            //         fingerApi = FingerApiFactory.getInstance(context, FingerApiFactory.USB)
            //         Log.d(TAG, "Bio ID SM92MSVcApi initialized for device serial")
            //     } catch (e: Exception) {
            //         Log.e(TAG, "Failed to initialize Bio ID API during device serial", e)
            //         result.error("INITIALIZATION_ERROR", "Failed to initialize Bio ID API: ${e.message}", null)
            //         return
            //     }
            // }
            
            // val serialResult = (fingerApi as FingerApiUsbWrapper).deviceSerialNumber
            // if (serialResult != null && serialResult.code == 0) {
            //     result.success(serialResult.data)
            // } else {
                result.success("BIOID${System.currentTimeMillis()} (simulated)")
            // }

        } catch (e: Exception) {
            Log.e(TAG, "Error getting device serial", e)
            result.error("SERIAL_ERROR", e.message, null)
        }
    }
    
    private fun registerUsbReceiver() {
        val filter = IntentFilter().apply {
            addAction(ACTION_USB_PERMISSION)
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        
        usbReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                handleUsbIntent(intent)
            }
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(usbReceiver, filter)
        }
        Log.d(TAG, "USB receiver registered")
    }
    
    private fun unregisterUsbReceiver() {
        usbReceiver?.let {
            context.unregisterReceiver(it)
            usbReceiver = null
            Log.d(TAG, "USB receiver unregistered")
        }
    }
    
    private fun handleUsbIntent(intent: Intent?) {
        when (intent?.action) {
            ACTION_USB_PERMISSION -> {
                val permissionGranted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                Log.d(TAG, "requestPermissionRe : $permissionGranted")
                
                if (permissionGranted) {
                    Log.d(TAG, "start open devices")
                    openDevice()
                } else {
                    Log.w(TAG, "permission denied for device")
                }
            }
            
            UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                Log.d(TAG, "USB device plugged in detected! PID: ${device?.productId} VID: ${device?.vendorId}")
                
                device?.let {
                    if (isBioIdDevice(it) && !isDeviceOpen) {
                        Log.d(TAG, "Bio ID device attached, initiating connection...")
                        val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
                        requestPermissionAndConnect(usbManager, it)
                    }
                }
            }
            
            UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                Log.d(TAG, "USB device detached: ${device?.deviceName}")
                
                device?.let {
                    if (isBioIdDevice(it) && isDeviceOpen) {
                        Log.d(TAG, "Bio ID device detached, closing connection...")
                        closeDevice()
                    }
                }
            }
        }
    }
    
    private fun requestPermissionAndConnect(manager: UsbManager, device: UsbDevice) {
        if (!manager.hasPermission(device)) {
            Log.d(TAG, "fingerprint device no permission and request permission")
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                Intent(ACTION_USB_PERMISSION),
                PendingIntent.FLAG_MUTABLE
            )
            manager.requestPermission(device, pendingIntent)
        } else {
            Log.d(TAG, "fingerprint device has permission and start open devices")
            openDevice()
        }
    }
    
    private fun isBioIdDevice(device: UsbDevice): Boolean {
        // return (device.vendorId == FingerApiFactory.VC_VID && device.productId == FingerApiFactory.VC_PID) ||
        //        (device.vendorId == FingerApiFactory.MSC_VID && device.productId == FingerApiFactory.MSC_PID)
        return false // Temporarily disabled
    }
    
    private fun openDevice() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // fingerApi?.let { api ->
                    Log.d(TAG, "Opening Bio ID device... (simulated)")
                    // val openResult = api.openDevice()
                    val openResult = 1 // Simulated success
                    
                    if (openResult >= 0) {
                        isDeviceOpen = true
                        Log.d(TAG, "Bio ID device opened successfully. LED should now be active. (simulated)")
                    } else {
                        Log.e(TAG, "Failed to open Bio ID device, code: $openResult (simulated)")
                    }
                // }
            } catch (e: Exception) {
                Log.e(TAG, "Error opening device", e)
            }
        }
    }
    
    private fun closeDevice() {
        try {
            // if (fingerApi != null && isDeviceOpen) {
            if (isDeviceOpen) {
                // val closeResult = (fingerApi as FingerApiUsbWrapper).closeDevice()
                val closeResult = 0 // Simulated success
                isDeviceOpen = false
                Log.d(TAG, "Bio ID device closed, result: $closeResult (simulated)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error closing device", e)
        }
    }
}