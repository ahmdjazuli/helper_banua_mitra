import 'package:flutter/material.dart';

class StatusOnlineSwitch extends StatefulWidget {
  final bool initialStatus;
  final ValueChanged<bool>? onChanged;

  const StatusOnlineSwitch({
    super.key,
    this.initialStatus = false,
    this.onChanged,
  });

  @override
  State<StatusOnlineSwitch> createState() => _StatusOnlineSwitchState();
}

class _StatusOnlineSwitchState extends State<StatusOnlineSwitch> {
  late bool _isOnline;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        // Latar hitam saat Online, abu-abu muda saat Offline
        color: _isOnline ? Colors.black : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Teks Status Dinamis (Online / Offline)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Text(
              _isOnline ? 'Online' : 'Offline',
              key: ValueKey<bool>(_isOnline),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                // Warna teks kuning saat Online, hitam saat Offline
                color: _isOnline ? const Color(0xFFFFCB05) : Colors.black,
              ),
            ),
          ),

          // Custom Switch Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _isOnline = !_isOnline;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(_isOnline);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                // Track switch berwarna kuning saat Online, abu-abu sedang saat Offline
                color: _isOnline ? const Color(0xFFFFCB05) : Colors.grey.shade400,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: _isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}