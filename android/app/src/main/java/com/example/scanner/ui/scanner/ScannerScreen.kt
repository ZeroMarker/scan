package com.example.scanner.ui.scanner

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.widget.Toast
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.PermissionStatus
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.mlkit.vision.barcode.common.Barcode
import kotlinx.coroutines.launch

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun ScannerScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val cameraPermissionState = rememberPermissionState(Manifest.permission.CAMERA)
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        if (!cameraPermissionState.status.isGranted) {
            cameraPermissionState.launchPermissionRequest()
        }
    }

    if (cameraPermissionState.status.isGranted) {
        ScannerContent(
            onBack = onBack,
            modifier = modifier
        )
    } else {
        val shouldShowRationale = when (val status = cameraPermissionState.status) {
            is PermissionStatus.Denied -> status.shouldShowRationale
            else -> false
        }
        PermissionDeniedContent(
            shouldShowRationale = shouldShowRationale,
            onBack = onBack,
            onRequestPermission = { scope.launch { cameraPermissionState.launchPermissionRequest() } },
            onOpenSettings = { context.openAppSettings() },
            modifier = modifier
        )
    }
}

@Composable
private fun ScannerContent(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    var scannedBarcode by remember { mutableStateOf<String?>(null) }
    var barcodeType by remember { mutableStateOf<String?>(null) }
    val analyzer = remember {
        BarcodeAnalyzer { barcode ->
            scannedBarcode = barcode.rawValue
            barcodeType = getBarcodeType(barcode.format)
        }
    }
    // Holds the active camera provider so it can be released when the preview leaves composition.
    val cameraProviderRef = remember { arrayOfNulls<ProcessCameraProvider>(1) }

    val currentBarcode = scannedBarcode
    Box(modifier = modifier.fillMaxSize()) {
        if (currentBarcode == null) {
            AndroidView(
                factory = { ctx ->
                    val previewView = PreviewView(ctx)
                    val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)

                    cameraProviderFuture.addListener({
                        val cameraProvider = cameraProviderFuture.get()
                        // Only bind while the preview is still attached, to avoid a race when the
                        // screen is left before the camera provider becomes ready.
                        if (previewView.isAttachedToWindow) {
                            cameraProviderRef[0] = cameraProvider
                            val preview = Preview.Builder().build().also {
                                it.surfaceProvider = previewView.surfaceProvider
                            }

                            val imageAnalysis = ImageAnalysis.Builder()
                                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                                .build()
                                .also {
                                    it.setAnalyzer(ContextCompat.getMainExecutor(ctx), analyzer)
                                }

                            try {
                                cameraProvider.unbindAll()
                                cameraProvider.bindToLifecycle(
                                    lifecycleOwner,
                                    CameraSelector.DEFAULT_BACK_CAMERA,
                                    preview,
                                    imageAnalysis
                                )
                            } catch (e: Exception) {
                                Toast.makeText(ctx, "Camera error: ${e.message}", Toast.LENGTH_SHORT).show()
                            }
                        }
                    }, ContextCompat.getMainExecutor(ctx))

                    previewView
                },
                onRelease = {
                    // Release the camera when leaving the scan screen or switching to the result.
                    cameraProviderRef[0]?.unbindAll()
                    cameraProviderRef[0] = null
                },
                modifier = Modifier.fillMaxSize()
            )

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(250.dp)
                        .border(2.dp, Color.White, RoundedCornerShape(12.dp))
                )
            }

            IconButton(
                onClick = onBack,
                modifier = Modifier
                    .padding(16.dp)
                    .align(Alignment.TopStart)
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = Color.White
                )
            }

            Text(
                text = "Align barcode within the frame",
                color = Color.White,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 100.dp)
                    .background(Color.Black.copy(alpha = 0.6f), RoundedCornerShape(8.dp))
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            )
        } else {
            ResultContent(
                barcode = currentBarcode,
                type = barcodeType ?: "Unknown",
                onBack = onBack,
                onScanAgain = {
                    scannedBarcode = null
                    barcodeType = null
                    analyzer.resumeScanning()
                },
                onCopy = {
                    copyToClipboard(context, currentBarcode)
                    Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
                },
                modifier = modifier
            )
        }
    }
}

@Composable
private fun ResultContent(
    barcode: String,
    type: String,
    onBack: () -> Unit,
    onScanAgain: () -> Unit,
    onCopy: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "Scan Result",
            style = MaterialTheme.typography.headlineMedium
        )

        Spacer(modifier = Modifier.height(24.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "Type: $type",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = barcode,
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OutlinedButton(
                onClick = onCopy,
                modifier = Modifier.weight(1f)
            ) {
                Icon(
                    imageVector = Icons.Default.ContentCopy,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Copy")
            }

            Button(
                onClick = onScanAgain,
                modifier = Modifier.weight(1f)
            ) {
                Text("Scan Again")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        TextButton(onClick = onBack) {
            Text("Back to Home")
        }
    }
}

@Composable
private fun PermissionDeniedContent(
    shouldShowRationale: Boolean,
    onBack: () -> Unit,
    onRequestPermission: () -> Unit,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "Camera Permission Required",
            style = MaterialTheme.typography.headlineSmall
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = if (shouldShowRationale) {
                "This app needs camera access to scan barcodes. Please grant the permission to continue."
            } else {
                "Camera permission has been denied. Enable it in system settings to scan barcodes."
            },
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.bodyMedium
        )

        Spacer(modifier = Modifier.height(24.dp))

        Button(onClick = onRequestPermission) {
            Text("Grant Permission")
        }

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedButton(onClick = onOpenSettings) {
            Text("Open Settings")
        }

        Spacer(modifier = Modifier.height(12.dp))

        TextButton(onClick = onBack) {
            Text("Go Back")
        }
    }
}

private val BARCODE_TYPE_NAMES: Map<Int, String> = mapOf(
    Barcode.FORMAT_CODE_128 to "Code 128",
    Barcode.FORMAT_CODE_39 to "Code 39",
    Barcode.FORMAT_CODE_93 to "Code 93",
    Barcode.FORMAT_CODABAR to "Codabar",
    Barcode.FORMAT_DATA_MATRIX to "Data Matrix",
    Barcode.FORMAT_EAN_13 to "EAN-13",
    Barcode.FORMAT_EAN_8 to "EAN-8",
    Barcode.FORMAT_ITF to "ITF",
    Barcode.FORMAT_QR_CODE to "QR Code",
    Barcode.FORMAT_UPC_A to "UPC-A",
    Barcode.FORMAT_UPC_E to "UPC-E",
    Barcode.FORMAT_PDF417 to "PDF417",
    Barcode.FORMAT_AZTEC to "Aztec"
)

private fun getBarcodeType(format: Int): String =
    BARCODE_TYPE_NAMES[format] ?: "Unknown"

private fun Context.openAppSettings() {
    startActivity(
        Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null)
        )
    )
}

private fun copyToClipboard(context: Context, text: String) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = ClipData.newPlainText("Barcode", text)
    clipboard.setPrimaryClip(clip)
}
