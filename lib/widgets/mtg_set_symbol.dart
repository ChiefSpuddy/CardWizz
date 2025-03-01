import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// Widget to display an MTG set icon
class MtgSetIcon extends StatefulWidget {
  final String setCode;
  final double size;
  final Color? color;

  const MtgSetIcon({
    super.key,
    required this.setCode,
    this.size = 24,
    this.color,
  });

  @override
  State<MtgSetIcon> createState() => _MtgSetIconState();
}

class _MtgSetIconState extends State<MtgSetIcon> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _svgData;

  @override
  void initState() {
    super.initState();
    _loadSvgData();
  }

  @override
  void didUpdateWidget(MtgSetIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setCode != widget.setCode) {
      _loadSvgData();
    }
  }

  Future<void> _loadSvgData() async {
    if (widget.setCode.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      // Try to load from Keyrune SVG CDN
      final url = 'https://cdn.jsdelivr.net/npm/@keyrune/svg/svg/${widget.setCode.toLowerCase()}.svg';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        setState(() {
          _svgData = response.body;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        throw Exception('Failed to load SVG');
      }
    } catch (e) {
      print('Error loading SVG for set ${widget.setCode}: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }
    
    if (_hasError || _svgData == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark 
            ? Colors.grey.shade800
            : Colors.grey.shade200,
          border: Border.all(
            color: isDark 
              ? Colors.grey.shade700 
              : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            widget.setCode.length > 3 ? widget.setCode.substring(0, 3).toUpperCase() : widget.setCode.toUpperCase(),
            style: TextStyle(
              fontSize: widget.size * 0.4,
              fontWeight: FontWeight.bold,
              color: isDark
                ? Colors.white70
                : Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: SvgPicture.string(
        _svgData!,
        color: widget.color,
        fit: BoxFit.contain,
      ),
    );
  }
}
