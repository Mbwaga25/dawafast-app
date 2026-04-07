import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/healthcare/data/models/doctor_model.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/healthcare/presentation/pages/telemedicine_page.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class MeetingPage extends ConsumerStatefulWidget {
  final Doctor? doctor; // Made optional for shared links
  final String appointmentId;

  const MeetingPage({super.key, this.doctor, required this.appointmentId});

  @override
  ConsumerState<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends ConsumerState<MeetingPage> {
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isVideoOff = false;
  Map<String, dynamic>? _session;
  Doctor? _doctor;
  bool _isLoading = true;
  String? _error;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _doctor = widget.doctor;
    _fetchSession();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        _cameras = await availableCameras();
        if (_cameras != null && _cameras!.isNotEmpty) {
          _cameraController = CameraController(_cameras![1], ResolutionPreset.medium, enableAudio: false);
          await _cameraController!.initialize();
          if (mounted) setState(() => _isCameraReady = true);
        }
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _fetchSession() async {
    try {
      final repo = ref.read(doctorsRepositoryProvider);
      
      // If doctor is missing (joined via link), fetch it
      if (_doctor == null) {
        try {
          final doc = await repo.fetchDoctorByAppointmentId(widget.appointmentId);
          if (mounted) setState(() => _doctor = doc);
        } catch (e) {
          debugPrint("Could not fetch doctor details: $e");
        }
      }

      // Initial fetch or wait loop for doctor to start session
      int attempts = 0;
      final user = ref.read(currentUserProvider).value;
      bool isDoctor = user?.role?.toUpperCase() == 'DOCTOR';

      if (isDoctor) {
        try {
           final started = await repo.startCallSession(widget.appointmentId);
           if (mounted) setState(() => _session = started);
        } catch (e) {
           debugPrint("Error starting session as doctor: $e");
        }
      }

      while (attempts < 10) {
        final session = await repo.getCallSession(widget.appointmentId);
        if (session != null && (session['status']?.toString().toUpperCase() == 'ACTIVE' || session['status']?.toString().toUpperCase() == 'CREATED')) {
          if (mounted) {
            setState(() {
              _session = session;
              _isLoading = false;
            });
            _startTimer();
          }
          return;
        }
        attempts++;
        await Future.delayed(const Duration(seconds: 3));
      }

      if (mounted) {
        setState(() {
          _error = "Waiting for practitioner to join the session...";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Connection error: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryTeal),
              const SizedBox(height: 24),
              Text(
                'Initializing Secure Connection...',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_session != null && _session!['mobileSupported'] == false) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.laptop_mac, color: Colors.amber, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Mobile Support Restricted',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'For your security, this specialized consultation session must be conducted on a desktop browser.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _session == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.05),
                child: const Icon(Icons.timer_outlined, color: Colors.blueAccent, size: 40),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final repo = ref.read(doctorsRepositoryProvider);
                    final success = await repo.rejectAppointment(widget.appointmentId, reason: "Patient cancelled from meeting screen");
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Request Cancelled' : 'Failed to cancel request'))
                      );
                    }
                  } catch (e) {
                    if (mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                child: const Text('Cancel Request'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Video Area
          Positioned.fill(
            child: Container(
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.blueAccent.withOpacity(0.05),
                      child: const Icon(Icons.person, color: Colors.blueAccent, size: 60),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _doctor != null ? 'Dr. ${_doctor!.fullName}' : 'Practitioner',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _doctor?.specialty ?? 'Medical Consultation',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // User Preview (Floating Overlay)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 110,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isCameraReady && _cameraController != null && !_isVideoOff)
                      CameraPreview(_cameraController!)
                    else
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Icon(_isVideoOff ? Icons.videocam_off : Icons.person, color: Colors.white24, size: 40),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                        child: Text('You', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                      ),
                    ),
                    if (_isMuted)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.mic_off, color: Colors.redAccent, size: 14),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Top Info Bar
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                   _BlinkingDot(),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_seconds),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Courier'),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls (Glassmorphism)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    isActive: !_isMuted,
                    activeColor: Colors.white12,
                    inactiveColor: Colors.redAccent.withOpacity(0.8),
                  ),
                  _buildControlButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icons.call_end,
                    isActive: true,
                    activeColor: Colors.redAccent,
                    size: 64,
                  ),
                  _buildControlButton(
                    onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    isActive: !_isVideoOff,
                    activeColor: Colors.white12,
                    inactiveColor: Colors.redAccent.withOpacity(0.8),
                  ),
                  _buildControlButton(
                    onPressed: _shareMeetingLink,
                    icon: Icons.ios_share,
                    isActive: true,
                    activeColor: Colors.white12,
                    size: 52,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareMeetingLink() {
    final String url = "https://dawafast.app/meeting/${widget.appointmentId}";
    
    Clipboard.setData(ClipboardData(text: url)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting link copied to clipboard!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    });
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    Color? inactiveColor,
    double size = 52,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? activeColor : (inactiveColor ?? Colors.redAccent),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  const _PulseAnimation({required this.child});
  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)), child: widget.child);
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)));
  }
}
