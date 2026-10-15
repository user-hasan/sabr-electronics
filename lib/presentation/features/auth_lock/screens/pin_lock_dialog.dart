import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository_impl.dart';
import '../../../../domain/entities/user_entity.dart';

class PinLockDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool managerOnly;
  final Function(UserEntity user) onSuccess;

  const PinLockDialog({
    super.key,
    this.title = 'التحقق السريع من رمز PIN',
    this.subtitle = 'أدخل الرمز للمتابعة وتوثيق العملية في سجل التدقيق',
    this.managerOnly = false,
    required this.onSuccess,
  });

  static Future<bool> show({
    required BuildContext context,
    String title = 'التحقق السريع من رمز PIN',
    String subtitle = 'أدخل الرمز للمتابعة وتوثيق العملية في سجل التدقيق',
    bool managerOnly = false,
    required Function(UserEntity user) onSuccess,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PinLockDialog(
        title: title,
        subtitle: subtitle,
        managerOnly: managerOnly,
        onSuccess: onSuccess,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinLockDialog> createState() => _PinLockDialogState();
}

class _PinLockDialogState extends State<PinLockDialog> {
  final AuthRepositoryImpl _authRepo = AuthRepositoryImpl();
  String _enteredPin = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length >= 4) {
        _verifyCurrentPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyCurrentPin() async {
    setState(() => _isLoading = true);

    try {
      if (widget.managerOnly) {
        final isManager = await _authRepo.verifyManagerPin(_enteredPin);
        if (isManager) {
          final currentUser = await _authRepo.getCurrentUser();
          if (mounted && currentUser != null) {
            widget.onSuccess(currentUser);
            Navigator.of(context).pop(true);
            return;
          }
        }
      } else {
        final user = await _authRepo.verifyPin(_enteredPin);
        if (user != null) {
          if (mounted) {
            widget.onSuccess(user);
            Navigator.of(context).pop(true);
            return;
          }
        }
      }

      if (mounted) {
        setState(() {
          _errorMessage = 'رمز PIN غير صحيح، يرجى المحاولة ثانية';
          _enteredPin = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء التحقق: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.managerOnly
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.managerOnly ? Icons.admin_panel_settings_rounded : Icons.lock_person_rounded,
                  size: 32,
                  color: widget.managerOnly ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 20),

              // نقاط الـ PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? AppColors.primary : AppColors.borderDark,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold),
                ),
              ],

              const SizedBox(height: 20),

              // لوحة مفاتيح الأرقام المريحة والسريعة
              _buildNumpad(),

              if (_isLoading) ...[
                const SizedBox(height: 12),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((d) => _buildNumpadButton(d)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildNumpadButton(d)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildNumpadButton(d)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            _buildNumpadButton('0'),
            IconButton(
              icon: const Icon(Icons.backspace_rounded, color: AppColors.textSecondaryDark),
              onPressed: _onBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadButton(String digit) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceDarkElevated,
          border: Border.all(color: AppColors.borderDark),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }
}
