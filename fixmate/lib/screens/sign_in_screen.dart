// lib/screens/sign_in_screen.dart
// FIXED VERSION - Properly handles 'both' account type
// Now correctly navigates workers to Worker Dashboard

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_account_screen.dart';
import 'account_type_screen.dart';
import 'worker_registration_flow.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';
import 'customer_dashboard.dart';
import 'forgot_password_screen.dart';
import '../services/google_auth_service.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      _showSuccessSnackBar('Welcome back!');

      // Navigate based on PRIMARY account (first created)
      await _navigateBasedOnRole(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential =
          await _googleAuthService.signInWithGoogle();

      if (userCredential == null) {
        setState(() => _isLoading = false);
        return;
      }

      _showSuccessSnackBar(
          'Welcome ${userCredential.user?.displayName ?? ""}!');

      await _navigateBasedOnRole(userCredential.user!);
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // In your lib/screens/sign_in_screen.dart file
// Find the existing _navigateBasedOnRole method
// Replace ONLY this method with the code below
// DO NOT change anything else in the file

  /// DUAL ACCOUNT NAVIGATION LOGIC
  /// Navigate based on PRIMARY account (first created account)
  Future<void> _navigateBasedOnRole(User user) async {
    try {
      print('🔍 Starting navigation for user: ${user.uid}');

      // Get user document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print(
            '❌ User document does not exist - redirecting to account type selection');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccountTypeScreen()),
        );
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? role = userData['role'];
      String? accountType = userData['accountType'];

      print('📋 User data: role=$role, accountType=$accountType');

      // Priority 1: Check if user is admin
      if (role == 'admin') {
        print('✅ Admin role detected - navigating to Admin Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
        );
        return;
      }

      // Priority 2: Handle single account types
      if (accountType == 'customer') {
        print('✅ Customer account - navigating to Customer Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
        return;
      } else if (accountType == 'service_provider') {
        print('✅ Worker account - navigating to Worker Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WorkerDashboardScreen()),
        );
        return;
      }

      // Priority 3: Handle 'both' account type - navigate to PRIMARY account
      if (accountType == 'both') {
        print('⚠️  User has BOTH accounts - checking which was created first');

        // Check both customer and worker documents
        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();
        DocumentSnapshot workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (customerDoc.exists && workerDoc.exists) {
          Map<String, dynamic>? customerData =
              customerDoc.data() as Map<String, dynamic>?;
          Map<String, dynamic>? workerData =
              workerDoc.data() as Map<String, dynamic>?;

          if (customerData != null && workerData != null) {
            Timestamp? customerCreated = customerData['created_at'];
            Timestamp? workerCreated = workerData['created_at'];

            if (customerCreated != null && workerCreated != null) {
              // Navigate to PRIMARY account (created first)
              if (customerCreated.compareTo(workerCreated) < 0) {
                print(
                    '✅ Customer was PRIMARY (created first) - navigating to Customer Dashboard');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerDashboard()),
                );
              } else {
                print(
                    '✅ Worker was PRIMARY (created first) - navigating to Worker Dashboard');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WorkerDashboardScreen()),
                );
              }
              return;
            }
          }
        }

        // Fallback: navigate to customer if exists
        print('📍 Fallback: Navigating to Customer Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
        return;
      }

      // Priority 4: No specific account type - check what exists
      bool hasCustomer = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get()
          .then((doc) => doc.exists);
      bool hasWorker = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get()
          .then((doc) => doc.exists);

      if (hasCustomer) {
        print('✅ Customer account found - navigating to Customer Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
        return;
      }

      if (hasWorker) {
        print('✅ Worker account found - navigating to Worker Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WorkerDashboardScreen()),
        );
        return;
      }

      // Priority 5: No account exists - redirect to account type selection
      print('❌ No account found - redirecting to account type selection');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccountTypeScreen()),
      );
    } catch (e) {
      print('❌ Error in navigation: $e');
      _showErrorSnackBar('Navigation error: ${e.toString()}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccountTypeScreen()),
      );
    }
  }

  void _resetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.build,
                          size: 64,
                          color: Color(0xFF2196F3),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            Text('Remember me'),
                            Spacer(),
                            TextButton(
                              onPressed: _resetPassword,
                              child: Text('Forgot Password?'),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2196F3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.g_mobiledata, size: 24);
                              },
                            ),
                            label: Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateAccountScreen(),
                                  ),
                                );
                              },
                              child: Text('Sign Up'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
