import 'package:flutter/material.dart';

import 'login_screen.dart';

class CompleteRegistrationScreen
    extends StatelessWidget {
  const CompleteRegistrationScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 28,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 64,
                  color:
                      Color(0xFFF59E0B),
                ),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'Registration Updated',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Text(
                  'The old email-link registration flow is no longer used.\n\n'
                  'Please return to Log In and use the new verified email/password flow.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white.withValues(
                      alpha: 0.72,
                    ),
                    fontSize:
                        15,
                    height:
                        1.5,
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height:
                      52,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginScreen(),
                        ),
                        (route) =>
                            false,
                      );
                    },
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFF59E0B,
                      ),
                      foregroundColor:
                          Colors.black,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'Back to Log In',
                      style:
                          TextStyle(
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}