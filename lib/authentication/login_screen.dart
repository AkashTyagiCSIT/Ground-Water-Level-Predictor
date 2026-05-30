import 'dart:convert';
import 'package:flutter_map/authentication/otp_screen.dart';
import 'package:flutter_map/common_widgets/custom_bg.dart';
import 'package:flutter_map/const/urls.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common_widgets/custom_button.dart';
import '../common_widgets/custom_text_form.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      // Check if API endpoints are configured. If empty, proceed in Demo Mode.
      if (AppConstants.loginUrl.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logged in successfully (Demo Mode)")),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
        setState(() {
          isLoading = false;
        });
        return;
      }

      final body = jsonEncode({
        'phone_number': phoneNumberController.text,
        'password': passwordController.text,
      });

      try {
        final url = Uri.parse(AppConstants.loginUrl);
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(Duration(seconds: AppConstants.defaultTimeout));

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful!")),
          );
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OtpScreen()),
            );
          }
        } else {
          final responseData = jsonDecode(response.body);
          final errorMessage = responseData['error'] ?? "Login Failed!";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (error) {
        // Fail-safe fallback to demo mode on network or connection errors
        print('Error occurred: $error. Falling back to Demo Mode.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection failed. Entering Demo Mode...")),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          custom_bg(),
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.only(top: 300, left: 10, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Log in",
                      style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 34),

                    CustomTextFormField(
                      controller: phoneNumberController,
                      labelText: "Phone No.",
                      onChanged: (value){},
                      keyboardType: TextInputType.number,
                      textStyle: const TextStyle(
                        color: Color(0xFFFFFFFF),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter 10 digit Phone Number";
                        }
                        return null;
                      },

                    ),
                    const SizedBox(height: 25),
                    CustomTextFormField(
                      controller: passwordController,
                      labelText: "Password",
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a password";
                        } else if (value.length < 8) {
                          return "Password must be at least 8 characters long";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 50),
                    isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Custombutton(
                            text: 'Log in',
                            onPressed: login,
                          ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed((context), '/signUp');
                        },
                        child: const Text(
                          "Don't have an account? Sign Up",
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 18
                          )),
                        ),
                      ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}