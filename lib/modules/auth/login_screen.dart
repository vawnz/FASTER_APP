import 'package:flutter/material.dart';
import '../../supabase_service.dart';
import '../../core/constants.dart';
import '../../models/student_profile.dart';
import '../../widgets/resq_logo.dart';
import '../home/home_screen.dart';
import '../admin/admin_main_screen.dart';

class AuthSplashScreen extends StatefulWidget {
  final bool skipSplash;
  const AuthSplashScreen({super.key, this.skipSplash = false});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _morphProgress;
  late Animation<double> _contentFadeIn;

  bool _isSignUp = false;
  int _signUpPhase = 1; // 1: Student Details, 2: Phone Number
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  // LOG IN 
  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // SIGN UP 
  final _signUpStudentIDController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _signUpUsernameController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _otherYearLevelController = TextEditingController();
  final _otherSectionController = TextEditingController();

  // SIGN UP - Phone Number
  final _phoneController = TextEditingController();

  // SIGN UP -- Can be Null
  String? _selectedProgram;
  String? _selectedYearLevel;
  String? _selectedSection;

  // Error Validation Message
  String? _loginIdentifierError;
  String? _loginPasswordError;
  String? _signUpStudentIDError;
  String? _firstNameError;
  String? _middleInitialError;
  String? _lastNameError;
  String? _programError;
  String? _yearLevelError;
  String? _otherYearLevelError;
  String? _sectionError;
  String? _otherSectionError;
  String? _signUpUsernameError;
  String? _signUpPasswordError;
  String? _phoneError;

  void _triggerLogoAnimation() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 0.85 -> 1.0: Animation Red
    _morphProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // 0.88 -> 1.0: Form elements smoothly fade & slide in
    _contentFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.88, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.skipSplash) {
      _animController.value = 1.0;
    } else {
      _animController.value = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.skipSplash) {
          _animController.forward(from: 0.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _signUpStudentIDController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _signUpUsernameController.dispose();
    _signUpPasswordController.dispose();
    _otherYearLevelController.dispose();
    _otherSectionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _skipSplash() {
    if (_animController.value < 0.95) {
      _animController.animateTo(1.0, duration: const Duration(milliseconds: 300));
    }
  }

  bool _validateInputs() {
    setState(() {
      _loginIdentifierError = null;
      _loginPasswordError = null;
      _signUpStudentIDError = null;
      _firstNameError = null;
      _middleInitialError = null;
      _lastNameError = null;
      _programError = null;
      _yearLevelError = null;
      _otherYearLevelError = null;
      _sectionError = null;
      _otherSectionError = null;
      _signUpUsernameError = null;
      _signUpPasswordError = null;
      _phoneError = null;
    });

    bool isValid = true;

    if (!_isSignUp) {
      // LOG IN Validation:
      // 1. Student ID or Username
      final idOrUser = _loginIdentifierController.text.trim();
      if (idOrUser.isEmpty) {
        _loginIdentifierError = 'Please enter your Student ID or Username.';
        isValid = false;
      } else if (idOrUser.length < 3) {
        _loginIdentifierError = 'Must be at least 3 characters.';
        isValid = false;
      }

      // 2. Password
      final pwd = _loginPasswordController.text;
      if (pwd.isEmpty) {
        _loginPasswordError = 'Please enter your password.';
        isValid = false;
      } else if (pwd.length < 8) {
        _loginPasswordError = 'Password must be at least 8 characters.';
        isValid = false;
      }
    } else {
      // SIGN UP Validation:
      // 1. Student ID
      final studentId = _signUpStudentIDController.text.trim();
      if (studentId.isEmpty) {
        _signUpStudentIDError = 'Please enter your Student ID.';
        isValid = false;
      } else if (studentId.length < 5) {
        _signUpStudentIDError = 'Enter a valid Student ID.';
        isValid = false;
      }

      // 2. Student Program
      if (_selectedProgram == null || _selectedProgram!.isEmpty) {
        _programError = 'Please select your degree program.';
        isValid = false;
      }

      // 3. First Name
      final firstName = _firstNameController.text.trim();
      if (firstName.isEmpty) {
        _firstNameError = 'First name is required.';
        isValid = false;
      }

      // 4. Middle Initial (or N/A)
      final mi = _middleInitialController.text.trim();
      if (mi.isEmpty) {
        _middleInitialError = 'M.I. required (or N/A).';
        isValid = false;
      }

      // 5. Last Name
      final lastName = _lastNameController.text.trim();
      if (lastName.isEmpty) {
        _lastNameError = 'Last name is required.';
        isValid = false;
      }

      // 6. Year Level
      if (_selectedYearLevel == null || _selectedYearLevel!.isEmpty) {
        _yearLevelError = 'Select year level.';
        isValid = false;
      } else if (_selectedYearLevel == 'Other') {
        final otherYr = _otherYearLevelController.text.trim();
        if (otherYr.isEmpty) {
          _otherYearLevelError = 'Enter 1 character.';
          isValid = false;
        } else if (otherYr.length > 1) {
          _otherYearLevelError = '1 character only.';
          isValid = false;
        }
      }

      // 7. Section
      if (_selectedSection == null || _selectedSection!.isEmpty) {
        _sectionError = 'Select section.';
        isValid = false;
      } else if (_selectedSection == 'Other') {
        final otherSec = _otherSectionController.text.trim();
        if (otherSec.isEmpty) {
          _otherSectionError = 'Enter 1 character.';
          isValid = false;
        } else if (otherSec.length > 1) {
          _otherSectionError = '1 character only.';
          isValid = false;
        }
      }

      // 8. Username
      final userText = _signUpUsernameController.text.trim();
      if (userText.isEmpty) {
        _signUpUsernameError = 'Please enter a username.';
        isValid = false;
      } else if (userText.length < 3) {
        _signUpUsernameError = 'Username must be at least 3 characters.';
        isValid = false;
      } else if (userText.contains(' ')) {
        _signUpUsernameError = 'Username must not include spaces.';
        isValid = false;
      }

      // 9. Password
      final pwdText = _signUpPasswordController.text;
      if (pwdText.isEmpty) {
        _signUpPasswordError = 'Please enter your password.';
        isValid = false;
      } else if (pwdText.length < 8) {
        _signUpPasswordError = 'Password must be at least 8 characters.';
        isValid = false;
      } else if (pwdText.contains(' ')) {
        _signUpPasswordError = 'Password must not include spaces.';
        isValid = false;
      }
    }

    return isValid;
  }

  bool _validatePhone() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Please enter your phone number.');
      return false;
    }
    if (!phone.startsWith('09')) {
      setState(() => _phoneError = 'Must start with 09 (Philippine mobile standard).');
      return false;
    }
    if (phone.length != 11 || !RegExp(r'^\d{11}$').hasMatch(phone)) {
      setState(() => _phoneError = 'Must contain 11 digits ONLY.');
      return false;
    }
    setState(() => _phoneError = null);
    return true;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (!_isSignUp) {
      // LOG IN FLOW:
      // Validates login credentials and sync to db fast_user_info
      if (_validateInputs()) {
        setState(() => _isSubmitting = true);
        try {
          final idOrUser = _loginIdentifierController.text.trim();
          final pwd = _loginPasswordController.text;

          final result = await SupabaseService.login(
            identifier: idOrUser,
            password: pwd,
          );

          if (!result.isSuccess) {
            if (mounted) {
              setState(() {
                _loginPasswordError = result.errorMessage;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFFC62828),
                  content: Text(
                    result.errorMessage ?? 'Login failed. Please check credentials.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }
            return;
          }
          //Admin Account (Temporary)
          currentStudent = result.student!;
          final bool isAdmin = (idOrUser == 'admin00' && pwd == 'admin1234') ||
              currentStudent.userRole == 'ADMIN' ||
              currentStudent.userRole == 'OFFICER';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: isAdmin ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32),
                content: Text(
                  isAdmin
                      ? 'FAST Officer verified! Welcome to HQ Monitoring.'
                      : 'Sign in successful! Welcome back, ${currentStudent.firstName}!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                duration: const Duration(milliseconds: 1000),
              ),
            );

            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) => isAdmin ? const AdminMainScreen() : const HomePage(),
                    transitionsBuilder: (_, anim, _, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              }
            });
          }
        } finally {
          if (mounted) {
            setState(() => _isSubmitting = false);
          }
        }
      }
    } else {
      // SIGN UP FLOW:
      if (_signUpPhase == 1) {
        // Phase 1: Validate Student Info & advance to Phase 2 (Phone Number)
        if (_validateInputs()) {
          setState(() {
            _signUpPhase = 2;
            _phoneError = null;
          });
        }
      } else if (_signUpPhase == 2) {
        // Phase 2: Validate phone number & syncs to fast_stud_info
        if (_validatePhone()) {
          setState(() => _isSubmitting = true);
          try {
            final year = _selectedYearLevel == 'Other'
                ? _otherYearLevelController.text.trim()
                : (_selectedYearLevel ?? '1st Year');
            final sec = _selectedSection == 'Other'
                ? _otherSectionController.text.trim().toUpperCase()
                : (_selectedSection ?? 'Section A');

            final result = await SupabaseService.signUp(
              studentId: _signUpStudentIDController.text.trim(),
              firstName: _firstNameController.text.trim(),
              middleInitial: _middleInitialController.text.trim(),
              lastName: _lastNameController.text.trim(),
              program: _selectedProgram ?? '(BSCS) Bachelor of Science in Computer Science',
              yearLevel: year,
              section: sec,
              username: _signUpUsernameController.text.trim(),
              password: _signUpPasswordController.text,
              phoneNumber: _phoneController.text.trim(),
            );

            if (!result.isSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFC62828),
                    content: Text(
                      result.errorMessage ?? 'Sign up failed.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              return;
            }

            currentStudent = result.student!;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF2E7D32),
                  content: Text(
                    'Account Created! Welcome to FASTER, ${currentStudent.firstName}!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  duration: const Duration(milliseconds: 1000),
                ),
              );

              Future.delayed(const Duration(milliseconds: 250), () {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, _, _) => const HomePage(),
                      transitionsBuilder: (_, anim, _, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                }
              });
            }
          } finally {
            if (mounted) {
              setState(() => _isSubmitting = false);
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skipSplash,
      child: Scaffold(
        backgroundColor: isGlassDark(context) ? const Color(0xFF0A0B0E) : Colors.white,
        body: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            final animVal = _animController.value;
            final morphVal = _morphProgress.value;

            return Stack(
              children: [
                // 1. Red background
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RedCurvedHeaderPainter(
                      progress: morphVal,
                      color: kGoogleRed,
                    ),
                  ),
                ),

                // 2. Splash into animation ( 3000 ms)
                if (animVal < 0.98)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Opacity(
                          opacity: ((1.0 - animVal) / 0.15).clamp(0.0, 1.0),
                          child: ResQLogo(
                            height: 72,
                            animate: true,
                            autoPlay: false,
                            progress: (animVal / 0.85).clamp(0.0, 1.0),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Header Text
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                      child: Opacity(
                        opacity: _contentFadeIn.value.clamp(0.0, 1.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Column(
                            key: ValueKey<String>(_isSignUp ? 'signup_$_signUpPhase' : 'login'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isSignUp ? 'SIGN UP' : 'LOG IN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isSignUp
                                    ? (_signUpPhase == 1
                                        ? 'Create an Account'
                                        : 'Phone Number (Step 2 of 2)')
                                    : 'Log In to Existing Account',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Login / Sign-up Display
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _contentFadeIn.value < 0.9,
                    child: Opacity(
                      opacity: _contentFadeIn.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1.0 - _contentFadeIn.value)),
                        child: SafeArea(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.17),

                                // FASTER Logo
                                const ResQLogo(
                                  height: 48,
                                  animate: false,
                                ),
                                const SizedBox(height: 24),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  switchInCurve: Curves.easeInOut,
                                  switchOutCurve: Curves.easeInOut,
                                  layoutBuilder: (currentChild, previousChildren) {
                                    return Stack(
                                      alignment: Alignment.topCenter,
                                      children: <Widget>[
                                        ...previousChildren,
                                        ?currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(opacity: animation, child: child),
                                  child: SizedBox(
                                    key: ValueKey<bool>(_isSignUp),
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!_isSignUp) ...[
                                  // ==================== LOG IN MODULE ====================
                                  // Student ID or Username
                                  _buildTextField(
                                    controller: _loginIdentifierController,
                                    hintText: 'Enter Student ID or Username',
                                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFDF0D18), size: 20),
                                    keyboardType: TextInputType.text,
                                    errorText: _loginIdentifierError,
                                  ),

                                  const SizedBox(height: 14),

                                  // Password
                                  _buildTextField(
                                    controller: _loginPasswordController,
                                    hintText: 'Enter Password',
                                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFDF0D18), size: 20),
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFFDF0D18),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    errorText: _loginPasswordError,
                                  ),

                                  // Constraints
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '• Sign in using your Student ID or Username',
                                            style: TextStyle(
                                              color: Color(0xFF7D6B6B),
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            '• Password must be at least 8 characters',
                                            style: TextStyle(
                                              color: Color(0xFF7D6B6B),
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Options: Remember me & Forgot Password
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _rememberMe = !_rememberMe);
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                activeColor: const Color(0xFFDF0D18),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                onChanged: (v) {
                                                  setState(() => _rememberMe = v ?? true);
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Remember me',
                                              style: TextStyle(
                                                color: Color(0xFFF45C5C),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Password reset instructions sent.'),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Color(0xFFF45C5C),
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (_signUpPhase == 1) ...[
                                  // ==================== SIGN UP: STUDENT INFO ====================
                                  // 1. Student ID
                                  _buildTextField(
                                    controller: _signUpStudentIDController,
                                    hintText: 'Enter Student ID (e.g. 202601234)',
                                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFDF0D18), size: 20),
                                    keyboardType: TextInputType.number,
                                    errorText: _signUpStudentIDError,
                                  ),

                                  const SizedBox(height: 12),

                                  // 2. Student Program (Dropdown)
                                  _buildDropdownField<String>(
                                    value: _selectedProgram,
                                    hintText: 'Select Degree Program',
                                    prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFFDF0D18), size: 20),
                                    errorText: _programError,
                                    items: kStudentPrograms.map((prog) => DropdownMenuItem(
                                      value: prog,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: Text(
                                          prog,
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    )).toList(),
                                    onChanged: (val) => setState(() => _selectedProgram = val),
                                  ),

                                  const SizedBox(height: 12),

                                  // 3. First Name & Middle Initial
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _buildTextField(
                                          controller: _firstNameController,
                                          hintText: 'First Name',
                                          prefixIcon: const Icon(Icons.person, color: Color(0xFFDF0D18), size: 18),
                                          keyboardType: TextInputType.name,
                                          textCapitalization: TextCapitalization.words,
                                          errorText: _firstNameError,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildTextField(
                                              controller: _middleInitialController,
                                              hintText: 'M.I. / N/A',
                                              keyboardType: TextInputType.text,
                                              maxLength: 3,
                                              textCapitalization: TextCapitalization.characters,
                                              errorText: _middleInitialError,
                                            ),
                                            const SizedBox(height: 2),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    if (_middleInitialController.text.toUpperCase() == 'N/A') {
                                                      _middleInitialController.clear();
                                                    } else {
                                                      _middleInitialController.text = 'N/A';
                                                    }
                                                    _middleInitialError = null;
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _middleInitialController.text.toUpperCase() == 'N/A'
                                                        ? const Color(0xFFDF0D18)
                                                        : const Color(0xFFEEEEEE),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'N/A',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _middleInitialController.text.toUpperCase() == 'N/A'
                                                          ? Colors.white
                                                          : const Color(0xFF616161),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // 4. Last Name
                                  _buildTextField(
                                    controller: _lastNameController,
                                    hintText: 'Last Name',
                                    prefixIcon: const Icon(Icons.family_restroom, color: Color(0xFFDF0D18), size: 18),
                                    keyboardType: TextInputType.name,
                                    textCapitalization: TextCapitalization.words,
                                    errorText: _lastNameError,
                                  ),

                                  const SizedBox(height: 12),

                                  // 5. Year Level & Section (1 char constraint)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildDropdownField<String>(
                                              value: _selectedYearLevel,
                                              hintText: 'Year Level',
                                              prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFFDF0D18), size: 18),
                                              errorText: _yearLevelError,
                                              items: kYearLevels.map((yr) => DropdownMenuItem(
                                                value: yr,
                                                child: Text(
                                                  yr,
                                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              )).toList(),
                                              onChanged: (val) {
                                                setState(() {
                                                  _selectedYearLevel = val;
                                                  _yearLevelError = null;
                                                });
                                              },
                                            ),
                                            if (_selectedYearLevel == 'Other') ...[
                                              const SizedBox(height: 6),
                                              _buildTextField(
                                                controller: _otherYearLevelController,
                                                hintText: 'Year (1 char)',
                                                prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFFDF0D18), size: 16),
                                                keyboardType: TextInputType.text,
                                                maxLength: 1,
                                                errorText: _otherYearLevelError,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildDropdownField<String>(
                                              value: _selectedSection,
                                              hintText: 'Section',
                                              prefixIcon: const Icon(Icons.group_outlined, color: Color(0xFFDF0D18), size: 18),
                                              errorText: _sectionError,
                                              items: kSections.map((sec) => DropdownMenuItem(
                                                value: sec,
                                                child: Text(
                                                  sec,
                                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              )).toList(),
                                              onChanged: (val) {
                                                setState(() {
                                                  _selectedSection = val;
                                                  _sectionError = null;
                                                });
                                              },
                                            ),
                                            if (_selectedSection == 'Other') ...[
                                              const SizedBox(height: 6),
                                              _buildTextField(
                                                controller: _otherSectionController,
                                                hintText: 'Section (1 char)',
                                                prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFFDF0D18), size: 16),
                                                keyboardType: TextInputType.text,
                                                maxLength: 1,
                                                textCapitalization: TextCapitalization.characters,
                                                errorText: _otherSectionError,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // 6. Username
                                  _buildTextField(
                                    controller: _signUpUsernameController,
                                    hintText: 'Student Username',
                                    prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFFDF0D18), size: 18),
                                    keyboardType: TextInputType.text,
                                    errorText: _signUpUsernameError,
                                  ),

                                  const SizedBox(height: 12),

                                  // 7. Password
                                  _buildTextField(
                                    controller: _signUpPasswordController,
                                    hintText: 'Student Password',
                                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFDF0D18), size: 18),
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFFDF0D18),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    errorText: _signUpPasswordError,
                                  ),

                                  // Constraintss
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '• Required fields MUST be filled to enter the application',
                                            style: TextStyle(
                                              color: Color(0xFF7D6B6B),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            '• Password must be at least 8 characters (no spaces)',
                                            style: TextStyle(
                                              color: Color(0xFF7D6B6B),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else if (_signUpPhase == 2) ...[
                                  // ==================== SIGN UP PHASE 2: PHONE NUMBER ====================
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Enter your mobile number to complete registration.',
                                      style: TextStyle(
                                        color: Color(0xFF555555),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  _buildTextField(
                                    controller: _phoneController,
                                    hintText: '09XXXXXXXXX',
                                    prefixIcon: const Icon(Icons.phone_android, color: Color(0xFFDF0D18), size: 20),
                                    keyboardType: TextInputType.phone,
                                    maxLength: 11,
                                    errorText: _phoneError,
                                  ),

                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '• Must start with 09 (Philippine mobile standard)',
                                            style: TextStyle(
                                              color: Color(0xFF7D6B6B),
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            '• Must contain 11 digits ONLY',
                                            style: TextStyle(
                                              color: Color(0xFF7D6B6B),
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _signUpPhase = 1;
                                          _phoneError = null;
                                        });
                                        _triggerLogoAnimation();
                                      },
                                      icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFFDF0D18)),
                                      label: const Text(
                                        'Back to Student Details',
                                        style: TextStyle(
                                          color: Color(0xFFDF0D18),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ),
],

                                const SizedBox(height: 24),

                                // Submit 
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _handleSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDF0D18),
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            !_isSignUp
                                                ? 'LOG IN'
                                                : _signUpPhase == 1
                                                    ? 'CONTINUE TO VERIFICATION'
                                                    : 'COMPLETE SIGN UP',
                                            style: const TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Switch between Log In/ Sign up
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isSignUp = !_isSignUp;
                                      _signUpPhase = 1;
                                      _loginIdentifierError = null;
                                      _loginPasswordError = null;
                                      _signUpStudentIDError = null;
                                      _firstNameError = null;
                                      _middleInitialError = null;
                                      _lastNameError = null;
                                      _programError = null;
                                      _yearLevelError = null;
                                      _otherYearLevelError = null;
                                      _sectionError = null;
                                      _otherSectionError = null;
                                      _signUpUsernameError = null;
                                      _signUpPasswordError = null;
                                      _phoneError = null;
                                    });
                                    _triggerLogoAnimation();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Or ',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF202124),
                                          ),
                                        ),
                                        Text(
                                          _isSignUp
                                              ? 'Log into Existing Account?'
                                              : 'Create an Account?',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF5739FE),
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    Widget? prefixIcon,
    String? errorText,
  }) {
    final dark = isGlassDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: dark ? const Color(0xCC1A1C28) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: errorText != null
                  ? Colors.red.shade700
                  : (dark ? const Color(0xFFE50914).withValues(alpha: 0.50) : const Color(0xFFF02626)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                prefixIcon,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    menuMaxHeight: 340,
                    hint: Text(
                      hintText,
                      style: TextStyle(
                        color: dark ? Colors.white60 : const Color(0xFF202124).withValues(alpha: 0.6),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFDF0D18)),
                    dropdownColor: dark ? const Color(0xFF1E202B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    selectedItemBuilder: (BuildContext context) {
                      return items.map<Widget>((DropdownMenuItem<T> item) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              item.value?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: dark ? Colors.white : const Color(0xFF202124),
                              ),
                            ),
                          ),
                        );
                      }).toList();
                    },
                    items: items,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final dark = isGlassDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xCC1A1C28) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            buildCounter: maxLength != null
                ? (_, {required currentLength, required isFocused, maxLength}) => null
                : null,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: dark ? Colors.white : const Color(0xFF202124),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: dark ? Colors.white60 : const Color(0xFF202124).withValues(alpha: 0.6),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: dark ? const Color(0xFFE50914).withValues(alpha: 0.50) : const Color(0xFFF02626),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red.shade700
                      : (dark ? const Color(0xFFE50914).withValues(alpha: 0.40) : const Color(0xFFF02626)),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Color(0xFFDF0D18), width: 2.0),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// Red Design Element -- From Figma
class _RedCurvedHeaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RedCurvedHeaderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (progress <= 0.0) return;

    final double w = size.width;
    final double h = size.height;

    // Animation emerut from Figma
    final double leftY = progress * (h * 0.22);
    final double rightY = progress * (h * 0.035);
    final double cpX = w * (0.50 - 0.06 * progress);
    final double cpY = progress * (h * 0.215);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, rightY)
      ..quadraticBezierTo(cpX, cpY, 0, leftY)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RedCurvedHeaderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

